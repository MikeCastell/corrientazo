import { Injectable } from "@nestjs/common";
import { Prisma } from "@prisma/client";

import { PrismaService } from "../../database/prisma/prisma.service";
import { SoldOutError, DomainError } from "../../common/errors/domain-errors";
import { ErrorCodes } from "../../common/errors/error-codes";
import { CancelOrderDto, CookCancelReasonCode, CreateOrderDto } from "./orders.dto";
import { OrderStateMachine } from "../../orders/domain/order-state-machine";
import { OrderAction } from "../../orders/domain/order-state-machine";
import { OrderStatus } from "../../orders/domain/order-status";

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  async createOrder(customerId: string, dto: CreateOrderDto) {
    const publicationId = dto.mealPublicationId;
    const qty = dto.quantity;

    return this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const pub = await tx.meal_publications.findUnique({
        where: { id: publicationId },
        select: {
          id: true,
          cook_profile_id: true,
          price_cop: true,
          stock_available: true,
          available_from: true,
          available_to: true,
          status: true,
          delivery_enabled: true,
          pickup_enabled: true,
        },
      });
      if (!pub) {
        throw new DomainError({
          code: ErrorCodes.ORDER_NOT_FOUND,
          message: "Publication not found",
          statusCode: 404,
        });
      }

      const now = new Date();
      if (now < pub.available_from || now > pub.available_to) {
        throw new DomainError({
          code: ErrorCodes.ORDER_INVALID_STATE_TRANSITION,
          message: "Publication not available",
          statusCode: 409,
        });
      }
      if (pub.status !== "PUBLISHED") {
        throw new DomainError({
          code: ErrorCodes.ORDER_INVALID_STATE_TRANSITION,
          message: "Publication not published",
          statusCode: 409,
        });
      }

      const wantDelivery = dto.fulfillmentType === "DELIVERY";
      if (wantDelivery && !pub.delivery_enabled) {
        throw new DomainError({
          code: ErrorCodes.ORDER_INVALID_STATE_TRANSITION,
          message: "Este plato no está disponible para domicilio; solo recogida.",
          statusCode: 409,
        });
      }
      if (!wantDelivery && !pub.pickup_enabled) {
        throw new DomainError({
          code: ErrorCodes.ORDER_INVALID_STATE_TRANSITION,
          message: "Este plato solo está disponible para domicilio.",
          statusCode: 409,
        });
      }

      // Reserva stock atómica (evita sobreventa) con UPDATE ... WHERE ... RETURNING.
      // Esto también bloquea la fila de la publicación en Postgres.
      const rows = await tx.$queryRaw<
        Array<{ stock_available: number }>
      >(Prisma.sql`
        UPDATE meal_publications
        SET stock_available = stock_available - ${qty},
            updated_at = NOW()
        WHERE id = ${publicationId}
          AND stock_available >= ${qty}
          AND status = 'PUBLISHED'
        RETURNING stock_available
      `);

      if (rows.length !== 1) {
        throw new SoldOutError({ publicationId, qty });
      }

      const remaining = rows[0]!.stock_available;
      if (remaining <= 0) {
        await tx.meal_publications.update({
          where: { id: publicationId },
          data: { status: "SOLD_OUT" },
          select: { id: true },
        });
      }

      const subtotal = pub.price_cop * qty;
      const platformFee = 0;
      const deliveryFee = dto.fulfillmentType === "DELIVERY" ? 0 : null;
      const total = subtotal + platformFee + (deliveryFee ?? 0);

      const order = await tx.orders.create({
        data: {
          customer_id: customerId,
          cook_profile_id: pub.cook_profile_id,
          meal_publication_id: pub.id,
          fulfillment_type: dto.fulfillmentType,
          delivery_address_id: dto.deliveryAddressId ?? null,
          quantity: qty,
          subtotal_cop: subtotal,
          platform_fee_cop: platformFee,
          delivery_fee_cop: deliveryFee,
          total_cop: total,
          status: "INIT",
          order_items: {
            create: {
              meal_publication_id: pub.id,
              quantity: qty,
              title_snapshot: "Corrientazo",
              unit_price_cop: pub.price_cop,
              subtotal_cop: subtotal,
            },
          },
          payment: {
            create: {
              method: "CASH",
              status: "PENDING",
              amount_cop: total,
            },
          },
          order_status_events: {
            create: {
              from_status: null,
              to_status: "INIT",
              actor_user_id: customerId,
              meta_json: { source: "api" },
            },
          },
        },
        select: { id: true, status: true, total_cop: true, created_at: true },
      });

      await tx.domain_event_outbox.create({
        data: {
          event_type: "order.created",
          aggregate_type: "order",
          aggregate_id: order.id,
          payload_json: { orderId: order.id },
        },
      });

      return order;
    });
  }

  async getOrder(requesterUserId: string, orderId: string) {
    const order = await this.prisma.orders.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        customer_id: true,
        cook_profile_id: true,
        meal_publication_id: true,
        fulfillment_type: true,
        quantity: true,
        status: true,
        created_at: true,
        total_cop: true,
        notes: true,
        cancel_reason: true,
        order_status_events: {
          orderBy: { occurred_at: "asc" },
          select: { from_status: true, to_status: true, occurred_at: true, actor_user_id: true },
        },
        customer: { select: { name: true, phone: true, avatar_url: true } },
        meal_publication: {
          select: {
            id: true,
            stock_available: true,
            status: true,
            photo_url: true,
            title_override: true,
            meal: { select: { title: true, photo_url: true } },
            cook_profile: {
              select: {
                bio: true,
                user: { select: { name: true, avatar_url: true, phone: true } },
              },
            },
          },
        },
      },
    });
    if (!order) {
      throw new DomainError({
        code: ErrorCodes.ORDER_NOT_FOUND,
        message: "Order not found",
        statusCode: 404,
      });
    }

    // MVP access rule: customer o cook dueño del cook_profile
    const isCustomer = order.customer_id === requesterUserId;

    const cookProfileId = await this.getCookProfileIdIfCook(requesterUserId);
    const isCookOwner = !!cookProfileId && order.cook_profile_id === cookProfileId;
    if (!isCustomer && !isCookOwner) {
      throw new DomainError({
        code: ErrorCodes.ORDER_ACCESS_DENIED,
        message: "Access denied",
        statusCode: 403,
      });
    }

    const mp = order.meal_publication;
    const cookUser = mp?.cook_profile?.user;
    return {
      id: order.id,
      status: order.status,
      created_at: order.created_at,
      total_cop: order.total_cop,
      quantity: order.quantity,
      fulfillment_type: order.fulfillment_type,
      meal_publication_id: order.meal_publication_id,
      notes: order.notes,
      cancel_reason: order.cancel_reason,
      timeline: order.order_status_events.map((e) => ({
        from_status: e.from_status,
        to_status: e.to_status,
        occurred_at: e.occurred_at,
        actor_user_id: e.actor_user_id,
      })),
      meal_title: mp?.title_override ?? mp?.meal?.title ?? null,
      meal_photo_url: mp?.photo_url ?? mp?.meal?.photo_url ?? null,
      cook_name: cookUser?.name ?? null,
      cook_avatar_url: cookUser?.avatar_url ?? null,
      cook_phone: cookUser?.phone ?? null,
      cook_bio: mp?.cook_profile?.bio ?? null,
      publication_status: mp?.status ?? null,
      stock_available: mp?.stock_available ?? null,
      customer_name: isCookOwner ? order.customer?.name ?? null : null,
      customer_phone: isCookOwner ? order.customer?.phone ?? null : null,
      customer_avatar_url: isCookOwner ? order.customer?.avatar_url ?? null : null,
    };
  }

  async listOrders(requesterUserId: string) {
    const role = await this.getUserRole(requesterUserId);
    if (role === "COOK") {
      const cookProfileId = await this.ensureCookProfile(requesterUserId);
      const rows = await this.prisma.orders.findMany({
        where: { cook_profile_id: cookProfileId },
        orderBy: { created_at: "desc" },
        take: 100,
        select: {
          id: true,
          status: true,
          created_at: true,
          updated_at: true,
          total_cop: true,
          quantity: true,
          fulfillment_type: true,
          meal_publication_id: true,
          customer: { select: { name: true, phone: true, avatar_url: true } },
          meal_publication: {
            select: {
              id: true,
              photo_url: true,
              title_override: true,
              meal: { select: { title: true, photo_url: true } },
            },
          },
        },
      });

      return rows.map((o) => ({
        id: o.id,
        status: o.status,
        created_at: o.created_at,
        updated_at: o.updated_at,
        total_cop: o.total_cop,
        quantity: o.quantity,
        fulfillment_type: o.fulfillment_type,
        meal_publication_id: o.meal_publication_id,
        customer_name: o.customer.name,
        customer_phone: o.customer.phone,
        customer_avatar_url: o.customer.avatar_url,
        meal_title: o.meal_publication.title_override ?? o.meal_publication.meal.title,
        meal_photo_url: o.meal_publication.photo_url ?? o.meal_publication.meal.photo_url,
      }));
    }

    const rows = await this.prisma.orders.findMany({
      where: { customer_id: requesterUserId },
      orderBy: { created_at: "desc" },
      take: 100,
      select: {
        id: true,
        status: true,
        created_at: true,
        total_cop: true,
        quantity: true,
        fulfillment_type: true,
        meal_publication_id: true,
        cook_profile_id: true,
        meal_publication: {
          select: {
            id: true,
            photo_url: true,
            title_override: true,
            meal: { select: { title: true, photo_url: true } },
          },
        },
      },
    });

    return rows.map((o) => ({
      id: o.id,
      status: o.status,
      total_cop: o.total_cop,
      created_at: o.created_at,
      quantity: o.quantity,
      fulfillment_type: o.fulfillment_type,
      meal_publication_id: o.meal_publication_id,
      cook_profile_id: o.cook_profile_id,
      meal_title: o.meal_publication.title_override ?? o.meal_publication.meal.title,
      meal_photo_url: o.meal_publication.photo_url ?? o.meal_publication.meal.photo_url,
    }));
  }

  async updateStatusAsCook(cookUserId: string, orderId: string, action: OrderAction) {
    const cookProfileId = await this.ensureCookProfile(cookUserId);

    if (action === "CANCEL_BY_CLIENT" || action === "CANCEL_BY_ADMIN") {
      throw new DomainError({
        code: ErrorCodes.ORDER_ACCESS_DENIED,
        message: "Usa el endpoint de cancelación para anular pedidos.",
        statusCode: 403,
      });
    }

    return this.prisma.$transaction(async (tx) => {
      const order = await tx.orders.findUnique({
        where: { id: orderId },
        select: {
          id: true,
          status: true,
          cook_profile_id: true,
          meal_publication_id: true,
          quantity: true,
        },
      });
      if (!order) {
        throw new DomainError({
          code: ErrorCodes.ORDER_NOT_FOUND,
          message: "Order not found",
          statusCode: 404,
        });
      }
      if (order.cook_profile_id !== cookProfileId) {
        throw new DomainError({
          code: ErrorCodes.ORDER_ACCESS_DENIED,
          message: "Access denied",
          statusCode: 403,
        });
      }

      const from = order.status as OrderStatus;
      if (!OrderStateMachine.canTransition(from, action)) {
        throw new DomainError({
          code: ErrorCodes.ORDER_INVALID_STATE_TRANSITION,
          message: `Invalid transition: ${from} + ${action}`,
          statusCode: 409,
        });
      }
      const to = OrderStateMachine.getTransition(from, action);

      if (this.isCancelledTerminalStatus(to)) {
        await this.releaseReservedStock(tx, order.meal_publication_id, order.quantity);
      }

      const updated = await tx.orders.update({
        where: { id: orderId },
        data: {
          status: to,
          ...(action === "CANCEL_BY_COOK"
            ? {
                cancel_reason:
                  "Cancelado por el cocinero (usa cancelar con motivo para más detalle).",
              }
            : {}),
          order_status_events: {
            create: {
              from_status: from,
              to_status: to,
              actor_user_id: cookUserId,
              meta_json: { source: "api", action },
            },
          },
        },
        select: { id: true, status: true, updated_at: true },
      });

      await tx.domain_event_outbox.create({
        data: {
          event_type: "order.status.updated",
          aggregate_type: "order",
          aggregate_id: updated.id,
          payload_json: { orderId: updated.id, from, to, action },
        },
      });

      return updated;
    });
  }

  /**
   * Cancelación unificada: valida rol, transición, restaura stock en la misma transacción.
   */
  async cancelOrder(requesterUserId: string, orderId: string, dto: CancelOrderDto) {
    const order = await this.prisma.orders.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        status: true,
        customer_id: true,
        cook_profile_id: true,
        meal_publication_id: true,
        quantity: true,
      },
    });
    if (!order) {
      throw new DomainError({
        code: ErrorCodes.ORDER_NOT_FOUND,
        message: "Order not found",
        statusCode: 404,
      });
    }

    const isCustomer = order.customer_id === requesterUserId;
    const cookProfileId = await this.getCookProfileIdIfCook(requesterUserId);
    const isCookOwner = !!cookProfileId && order.cook_profile_id === cookProfileId;

    if (!isCustomer && !isCookOwner) {
      throw new DomainError({
        code: ErrorCodes.ORDER_ACCESS_DENIED,
        message: "Access denied",
        statusCode: 403,
      });
    }

    if (isCustomer) {
      const from = order.status as OrderStatus;
      if (from !== OrderStatus.INIT && from !== OrderStatus.CONFIRMED) {
        throw new DomainError({
          code: ErrorCodes.ORDER_CANCEL_NOT_ALLOWED,
          message: "Tu corrientazo ya comenzó a prepararse.",
          statusCode: 409,
        });
      }
      if (!OrderStateMachine.canTransition(from, "CANCEL_BY_CLIENT")) {
        throw new DomainError({
          code: ErrorCodes.ORDER_CANCEL_NOT_ALLOWED,
          message: "No se puede cancelar este pedido ahora.",
          statusCode: 409,
        });
      }
      const to = OrderStateMachine.getTransition(from, "CANCEL_BY_CLIENT");
      const reason = "Lo cancelaste antes de que empezara la preparación en cocina.";
      return this.applyCancellation({
        actorUserId: requesterUserId,
        order,
        from,
        to,
        action: "CANCEL_BY_CLIENT",
        cancelReason: reason,
        meta: { cancelledBy: "CLIENT" },
      });
    }

    await this.ensureCookProfile(requesterUserId);
    const from = order.status as OrderStatus;
    if (!OrderStateMachine.canTransition(from, "CANCEL_BY_COOK")) {
      throw new DomainError({
        code: ErrorCodes.ORDER_CANCEL_NOT_ALLOWED,
        message: "Este pedido ya no se puede cancelar desde cocina.",
        statusCode: 409,
      });
    }
    const to = OrderStateMachine.getTransition(from, "CANCEL_BY_COOK");
    const reason = this.formatCookCancelReason(dto);
    return this.applyCancellation({
      actorUserId: requesterUserId,
      order,
      from,
      to,
      action: "CANCEL_BY_COOK",
      cancelReason: reason,
      meta: {
        cancelledBy: "COOK",
        reasonCode: dto.reasonCode ?? "OTHER",
        note: dto.note?.trim() || undefined,
      },
    });
  }

  private formatCookCancelReason(dto: CancelOrderDto): string {
    const labels: Record<CookCancelReasonCode, string> = {
      NO_INGREDIENTS: "Sin ingredientes disponibles",
      KITCHEN_ISSUE: "Problema en cocina",
      CANNOT_PREPARE: "Ya no puedo preparar este plato",
      UNEXPECTED_CLOSE: "Cierre inesperado",
      OTHER: "Motivo operativo",
    };
    const code = dto.reasonCode ?? "OTHER";
    const base = labels[code] ?? labels.OTHER;
    const note = dto.note?.trim();
    if (note) {
      return `${base}: ${note}`;
    }
    return base;
  }

  private isCancelledTerminalStatus(status: OrderStatus): boolean {
    return (
      status === OrderStatus.CANCELLED_BY_CLIENT ||
      status === OrderStatus.CANCELLED_BY_COOK ||
      status === OrderStatus.CANCELLED_BY_ADMIN
    );
  }

  /**
   * Devuelve al inventario la cantidad reservada al crear el pedido.
   */
  private async releaseReservedStock(tx: Prisma.TransactionClient, publicationId: string, qty: number) {
    await tx.$executeRaw(Prisma.sql`
      UPDATE meal_publications
      SET stock_available = stock_available + ${qty},
          updated_at = NOW()
      WHERE id = ${publicationId}
    `);

    const row = await tx.meal_publications.findUnique({
      where: { id: publicationId },
      select: { stock_available: true, status: true },
    });
    if (row && row.stock_available > 0 && row.status === "SOLD_OUT") {
      await tx.meal_publications.update({
        where: { id: publicationId },
        data: { status: "PUBLISHED" },
      });
    }
  }

  private applyCancellation(params: {
    actorUserId: string;
    order: {
      id: string;
      meal_publication_id: string;
      quantity: number;
      status: string;
    };
    from: OrderStatus;
    to: OrderStatus;
    action: OrderAction;
    cancelReason: string | null;
    meta: Record<string, unknown>;
  }) {
    const run = async (tx: Prisma.TransactionClient) => {
      const current = await tx.orders.findUnique({
        where: { id: params.order.id },
        select: { status: true },
      });
      if (!current || current.status !== params.from) {
        throw new DomainError({
          code: ErrorCodes.ORDER_CANCEL_NOT_ALLOWED,
          message: "El pedido cambió. Actualiza e intenta de nuevo.",
          statusCode: 409,
        });
      }

      await this.releaseReservedStock(tx, params.order.meal_publication_id, params.order.quantity);

      const updated = await tx.orders.update({
        where: { id: params.order.id },
        data: {
          status: params.to,
          cancel_reason: params.cancelReason,
          order_status_events: {
            create: {
              from_status: params.from,
              to_status: params.to,
              actor_user_id: params.actorUserId,
              meta_json: { source: "api", action: params.action, ...params.meta },
            },
          },
        },
        select: { id: true, status: true, updated_at: true },
      });

      await tx.domain_event_outbox.create({
        data: {
          event_type: "order.cancelled",
          aggregate_type: "order",
          aggregate_id: updated.id,
          payload_json: {
            orderId: updated.id,
            from: params.from,
            to: params.to,
            action: params.action,
          },
        },
      });

      return updated;
    };

    return this.prisma.$transaction(run);
  }

  private async getUserRole(userId: string) {
    const user = await this.prisma.users.findUnique({
      where: { id: userId },
      select: { role: true, status: true },
    });
    if (!user || user.status !== "ACTIVE") {
      throw new DomainError({
        code: ErrorCodes.ORDER_ACCESS_DENIED,
        message: "Access denied",
        statusCode: 403,
      });
    }
    return user.role;
  }

  private async getCookProfileIdIfCook(userId: string) {
    const user = await this.prisma.users.findUnique({
      where: { id: userId },
      select: { role: true, status: true },
    });
    if (!user || user.status !== "ACTIVE" || user.role !== "COOK") return null;
    const cook = await this.prisma.cook_profiles.findUnique({
      where: { user_id: userId },
      select: { id: true },
    });
    return cook?.id ?? null;
  }

  private async ensureCookProfile(userId: string) {
    const user = await this.prisma.users.findUnique({
      where: { id: userId },
      select: { id: true, role: true, status: true },
    });
    if (!user || user.status !== "ACTIVE" || user.role !== "COOK") {
      throw new DomainError({
        code: ErrorCodes.ORDER_ACCESS_DENIED,
        message: "Cook access denied",
        statusCode: 403,
      });
    }

    const cook = await this.prisma.cook_profiles.upsert({
      where: { user_id: userId },
      update: {},
      create: {
        user_id: userId,
        is_active: true,
        pickup_enabled: true,
        delivery_enabled: false,
      },
      select: { id: true },
    });
    return cook.id;
  }
}

