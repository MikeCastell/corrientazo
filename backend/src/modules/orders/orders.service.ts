import { Injectable } from "@nestjs/common";
import { PrismaClient, Prisma } from "@prisma/client";

import { PrismaService } from "../../database/prisma/prisma.service";
import { SoldOutError, DomainError } from "../../common/errors/domain-errors";
import { ErrorCodes } from "../../common/errors/error-codes";
import { CreateOrderDto } from "./orders.dto";

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

    // Foundation access rule: solo customer ve su orden (cook se añade luego)
    if (order.customer_id !== requesterUserId) {
      throw new DomainError({
        code: ErrorCodes.ORDER_ACCESS_DENIED,
        message: "Access denied",
        statusCode: 403,
      });
    }

    return order;
  }
}

