import { Injectable, ServiceUnavailableException } from "@nestjs/common";
import { Prisma } from "@prisma/client";

import { PrismaService } from "../../database/prisma/prisma.service";
import { DomainError } from "../../common/errors/domain-errors";
import { ErrorCodes } from "../../common/errors/error-codes";
import {
  CreateMealDto,
  PublishMealDto,
  UpdateMealDto,
  UpdateMealPublicationDto,
} from "./meals.dto";

@Injectable()
export class MealsService {
  constructor(private readonly prisma: PrismaService) {}

  async listPublished() {
    // Foundation: lista simple de publicaciones disponibles (sin geo ni ranking)
    const now = new Date();
    const rows = await this.prisma.meal_publications.findMany({
      where: {
        available_from: { lte: now },
        available_to: { gte: now },
        stock_available: { gt: 0 },
        status: "PUBLISHED",
      },
      orderBy: { created_at: "desc" },
      take: 50,
      select: {
        id: true,
        meal_id: true,
        cook_profile_id: true,
        price_cop: true,
        stock_available: true,
        available_from: true,
        available_to: true,
        pickup_from: true,
        pickup_to: true,
        delivery_enabled: true,
        pickup_enabled: true,
        photo_url: true,
        title_override: true,
        description_override: true,
        meal: {
          select: {
            title: true,
            description: true,
            photo_url: true,
            tags: true,
          },
        },
        cook_profile: {
          select: {
            bio: true,
            user: { select: { name: true, avatar_url: true } },
          },
        },
      },
    });

    // Flatten enriched fields for the mobile app.
    return rows.map((r) => ({
      id: r.id,
      meal_id: r.meal_id,
      cook_profile_id: r.cook_profile_id,
      price_cop: r.price_cop,
      stock_available: r.stock_available,
      available_from: r.available_from,
      available_to: r.available_to,
      pickup_from: r.pickup_from,
      pickup_to: r.pickup_to,
      delivery_enabled: r.delivery_enabled,
      pickup_enabled: r.pickup_enabled,
      title: r.title_override ?? r.meal?.title ?? null,
      description: r.description_override ?? r.meal?.description ?? null,
      tags: r.meal?.tags ?? null,
      photo_url: r.photo_url ?? r.meal?.photo_url ?? null,
      cook_name: r.cook_profile?.user?.name ?? null,
      cook_avatar_url: r.cook_profile?.user?.avatar_url ?? null,
      cook_bio: r.cook_profile?.bio ?? null,
    }));
  }

  async listCookMeals(cookUserId: string) {
    const cook = await this.ensureCookProfile(cookUserId);
    return this.prisma.meals.findMany({
      where: { cook_profile_id: cook.id, is_active: true },
      orderBy: { created_at: "desc" },
      select: {
        id: true,
        title: true,
        description: true,
        base_price_cop: true,
        photo_url: true,
        tags: true,
        is_active: true,
        created_at: true,
        updated_at: true,
        publications: {
          // Use updated_at so the UI reflects the last pause/activate action.
          orderBy: { updated_at: "desc" },
          take: 1,
          select: {
            id: true,
            price_cop: true,
            stock_total: true,
            stock_available: true,
            status: true,
            available_from: true,
            available_to: true,
            pickup_from: true,
            pickup_to: true,
            delivery_enabled: true,
            pickup_enabled: true,
            created_at: true,
            updated_at: true,
          },
        },
      },
    });
  }

  async createMealTemplate(cookUserId: string, dto: CreateMealDto) {
    const cook = await this.ensureCookProfile(cookUserId);
    return this.prisma.meals.create({
      data: {
        cook_profile_id: cook.id,
        title: dto.title,
        description: dto.description ?? null,
        base_price_cop: dto.basePriceCop,
        photo_url: dto.photoUrl ?? null,
        tags: dto.tags,
      },
      select: {
        id: true,
        title: true,
        description: true,
        base_price_cop: true,
        photo_url: true,
        tags: true,
        is_active: true,
        created_at: true,
        updated_at: true,
        publications: {
          orderBy: { created_at: "desc" },
          take: 1,
          select: {
            id: true,
            price_cop: true,
            stock_total: true,
            stock_available: true,
            status: true,
            available_from: true,
            available_to: true,
            pickup_from: true,
            pickup_to: true,
            created_at: true,
          },
        },
      },
    });
  }

  async updateMealTemplate(cookUserId: string, mealId: string, dto: UpdateMealDto) {
    const cook = await this.ensureCookProfile(cookUserId);
    const exists = await this.prisma.meals.findFirst({
      where: { id: mealId, cook_profile_id: cook.id },
      select: { id: true },
    });
    if (!exists) {
      throw new DomainError({
        code: ErrorCodes.ORDER_NOT_FOUND,
        message: "Meal not found",
        statusCode: 404,
      });
    }

    return this.prisma.meals.update({
      where: { id: mealId },
      data: {
        ...(dto.title !== undefined ? { title: dto.title } : {}),
        ...(dto.description !== undefined ? { description: dto.description } : {}),
        ...(dto.basePriceCop !== undefined ? { base_price_cop: dto.basePriceCop } : {}),
        ...(dto.photoUrl !== undefined ? { photo_url: dto.photoUrl } : {}),
        ...(dto.tags !== undefined ? { tags: dto.tags } : {}),
      },
      select: {
        id: true,
        title: true,
        description: true,
        base_price_cop: true,
        photo_url: true,
        tags: true,
        is_active: true,
        updated_at: true,
      },
    });
  }

  async deleteMealTemplate(cookUserId: string, mealId: string) {
    const cook = await this.ensureCookProfile(cookUserId);
    const exists = await this.prisma.meals.findFirst({
      where: { id: mealId, cook_profile_id: cook.id },
      select: { id: true, title: true },
    });
    if (!exists) {
      throw new DomainError({
        code: ErrorCodes.ORDER_NOT_FOUND,
        message: "Meal not found",
        statusCode: 404,
      });
    }

    // Hard delete can fail if there are orders referencing a publication:
    // orders.meal_publication_id has ON DELETE RESTRICT.
    // In that case, we do a safe "archive": deactivate the template and archive publications.
    const pubIds = await this.prisma.meal_publications.findMany({
      where: { meal_id: mealId },
      select: { id: true },
    });
    const ids = pubIds.map((p) => p.id);

    const refs =
      ids.length === 0
        ? 0
        : await this.prisma.orders.count({
            where: { meal_publication_id: { in: ids } },
          });

    if (refs > 0) {
      await this.prisma.meals.update({
        where: { id: mealId },
        data: { is_active: false },
      });
      if (ids.length > 0) {
        await this.prisma.meal_publications.updateMany({
          where: { id: { in: ids } },
          data: { status: "ARCHIVED" },
        });
      }
      return { ok: true, id: mealId, archived: true, orders: refs };
    }

    await this.prisma.meals.delete({ where: { id: mealId } });
    return { ok: true, id: mealId, archived: false };
  }

  async publishMeal(cookUserId: string, mealId: string, dto: PublishMealDto) {
    const cook = await this.ensureCookProfile(cookUserId);

    const meal = await this.prisma.meals.findFirst({
      where: { id: mealId, cook_profile_id: cook.id, is_active: true },
      select: { id: true, title: true, description: true, photo_url: true },
    });
    if (!meal) {
      throw new DomainError({
        code: ErrorCodes.ORDER_NOT_FOUND,
        message: "Meal not found",
        statusCode: 404,
      });
    }

    const deliveryEnabled = dto.deliveryEnabled ?? false;
    const pickupEnabled = dto.pickupEnabled ?? true;
    if (!deliveryEnabled && !pickupEnabled) {
      throw new DomainError({
        code: ErrorCodes.ORDER_INVALID_STATE_TRANSITION,
        message: "Publication must allow pickup and/or delivery",
        statusCode: 400,
      });
    }

    try {
      return await this.prisma.meal_publications.create({
        data: {
          meal_id: meal.id,
          cook_profile_id: cook.id,
          price_cop: dto.priceCop,
          stock_total: dto.stockTotal,
          stock_available: dto.stockTotal,
          available_from: new Date(dto.availableFrom),
          available_to: new Date(dto.availableTo),
          pickup_from: new Date(dto.pickupFrom),
          pickup_to: new Date(dto.pickupTo),
          delivery_enabled: deliveryEnabled,
          pickup_enabled: pickupEnabled,
          delivery_zone_id: dto.deliveryZoneId ?? null,
          status: dto.status ?? "PUBLISHED",
        },
        select: {
          id: true,
          meal_id: true,
          cook_profile_id: true,
          price_cop: true,
          stock_total: true,
          stock_available: true,
          delivery_enabled: true,
          pickup_enabled: true,
          status: true,
          created_at: true,
        },
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      // Postgres sin migración 20260510120000 / columna pickup_enabled
      if (/pickup_enabled/i.test(msg)) {
        throw new ServiceUnavailableException(
          "La base de datos necesita migraciones: en el servidor ejecuta `npx prisma migrate deploy` (columna pickup_enabled en meal_publications).",
        );
      }
      throw e;
    }
  }

  async listCookPublications(cookUserId: string) {
    const cook = await this.ensureCookProfile(cookUserId);
    return this.prisma.meal_publications.findMany({
      where: { cook_profile_id: cook.id },
      orderBy: { created_at: "desc" },
      take: 100,
      select: {
        id: true,
        cook_profile_id: true,
        meal_id: true,
        price_cop: true,
        stock_total: true,
        stock_available: true,
        status: true,
        available_from: true,
        available_to: true,
        pickup_from: true,
        pickup_to: true,
        created_at: true,
        updated_at: true,
      },
    });
  }

  async updatePublication(cookUserId: string, publicationId: string, dto: UpdateMealPublicationDto) {
    const cook = await this.ensureCookProfile(cookUserId);
    const pub = await this.prisma.meal_publications.findFirst({
      where: { id: publicationId, cook_profile_id: cook.id },
      select: {
        id: true,
        meal_id: true,
        stock_total: true,
        stock_available: true,
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

    let nextStockTotal = dto.stockTotal ?? pub.stock_total;
    let nextStockAvailable = dto.stockAvailable ?? pub.stock_available;
    const nextDeliveryEnabled =
      dto.deliveryEnabled !== undefined && dto.deliveryEnabled !== null
        ? dto.deliveryEnabled
        : pub.delivery_enabled;
    const nextPickupEnabled =
      dto.pickupEnabled !== undefined && dto.pickupEnabled !== null
        ? dto.pickupEnabled
        : pub.pickup_enabled;

    if (!nextDeliveryEnabled && !nextPickupEnabled) {
      throw new DomainError({
        code: ErrorCodes.ORDER_INVALID_STATE_TRANSITION,
        message:
          "Publication must allow pickup and/or delivery",
        statusCode: 400,
      });
    }

    // Si solo suben cupos disponibles, ampliar stock_total para no violar stockAvailable > stockTotal.
    if (dto.stockAvailable !== undefined && dto.stockAvailable !== null) {
      nextStockAvailable = dto.stockAvailable;
      if (dto.stockTotal === undefined || dto.stockTotal === null) {
        nextStockTotal = Math.max(pub.stock_total, dto.stockAvailable);
      } else {
        nextStockTotal = dto.stockTotal;
      }
    } else if (dto.stockTotal !== undefined && dto.stockTotal !== null) {
      nextStockTotal = dto.stockTotal;
    }

    if (nextStockTotal < 0 || nextStockAvailable < 0) {
      throw new DomainError({
        code: ErrorCodes.ORDER_INVALID_STATE_TRANSITION,
        message: "Invalid stock",
        statusCode: 400,
      });
    }
    if (nextStockAvailable > nextStockTotal) {
      throw new DomainError({
        code: ErrorCodes.ORDER_INVALID_STATE_TRANSITION,
        message: "stockAvailable cannot exceed stockTotal",
        statusCode: 400,
      });
    }

    return this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      // Guarantee: only one PUBLISHED publication per meal for the cook.
      if (dto.status === "PUBLISHED" || dto.status === "PAUSED") {
        // Pause all siblings (not only those currently PUBLISHED) to avoid
        // races/legacy duplicates causing the UI to "bounce" after refresh.
        await tx.meal_publications.updateMany({
          where: {
            cook_profile_id: cook.id,
            meal_id: pub.meal_id,
            id: { not: publicationId },
          },
          data: { status: "PAUSED" },
        });
      }

      return tx.meal_publications.update({
        where: { id: publicationId },
        data: {
          ...(dto.priceCop !== undefined && dto.priceCop !== null ? { price_cop: dto.priceCop } : {}),
          ...(dto.status !== undefined && dto.status !== null ? { status: dto.status } : {}),
          ...(dto.stockTotal !== undefined && dto.stockTotal !== null ? { stock_total: nextStockTotal } : {}),
          ...(dto.stockAvailable !== undefined && dto.stockAvailable !== null
            ? { stock_available: nextStockAvailable }
            : {}),
          ...(dto.stockTotal !== undefined &&
                  dto.stockTotal !== null &&
                  (dto.stockAvailable === undefined || dto.stockAvailable === null)
            ? { stock_available: Math.min(pub.stock_available, nextStockTotal) }
            : {}),
          ...(dto.deliveryEnabled !== undefined && dto.deliveryEnabled !== null
            ? { delivery_enabled: nextDeliveryEnabled }
            : {}),
          ...(dto.pickupEnabled !== undefined && dto.pickupEnabled !== null
            ? { pickup_enabled: nextPickupEnabled }
            : {}),
        },
        select: {
          id: true,
          price_cop: true,
          stock_total: true,
          stock_available: true,
          status: true,
          updated_at: true,
        },
      });
    });
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
    return cook;
  }
}

