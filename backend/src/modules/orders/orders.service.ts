import { Injectable } from "@nestjs/common";
import { PrismaClient, Prisma } from "@prisma/client";

import { PrismaService } from "../../database/prisma/prisma.service";
import { SoldOutError, DomainError } from "../../common/errors/domain-errors";
import { ErrorCodes } from "../../common/errors/error-codes";
import { CreateOrderDto } from "./orders.dto";
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

      // Reserva stock atómica (evita sobreventa) con updateMany condicional.
      const dec = await tx.meal_publications.updateMany({
        where: { id: publicationId, stock_available: { gte: qty } },
        data: { stock_available: { decrement: qty } },
      });
      if (dec.count !== 1) {
        throw new SoldOutError({ publicationId, qty });
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
        status: true,
        created_at: true,
        total_cop: true,
        order_status_events: {
          orderBy: { occurred_at: "asc" },
          select: { from_status: true, to_status: true, occurred_at: true, actor_user_id: true },
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
    if (order.customer_id === requesterUserId) return order;

    const cookProfileId = await this.getCookProfileIdIfCook(requesterUserId);
    if (!cookProfileId || order.cook_profile_id !== cookProfileId) {
      throw new DomainError({
        code: ErrorCodes.ORDER_ACCESS_DENIED,
        message: "Access denied",
        statusCode: 403,
      });
    }

    return order;
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
        total_cop: o.total_cop,
        created_at: o.created_at,
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

    return this.prisma.$transaction(async (tx) => {
      const order = await tx.orders.findUnique({
        where: { id: orderId },
        select: { id: true, status: true, cook_profile_id: true },
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

      const updated = await tx.orders.update({
        where: { id: orderId },
        data: {
          status: to,
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

