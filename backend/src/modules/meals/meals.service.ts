import { Injectable } from "@nestjs/common";

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
    return this.prisma.meal_publications.findMany({
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
        photo_url: true,
        title_override: true,
        meal: {
          select: {
            title: true,
            photo_url: true,
          },
        },
        cook_profile: {
          select: {
            user: { select: { name: true, avatar_url: true } },
          },
        },
      },
    });
  }

  async listCookMeals(cookUserId: string) {
    const cook = await this.ensureCookProfile(cookUserId);
    return this.prisma.meals.findMany({
      where: { cook_profile_id: cook.id },
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

    await this.prisma.meals.delete({
      where: { id: mealId },
    });

    return { ok: true, id: mealId };
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

    return this.prisma.meal_publications.create({
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
        delivery_enabled: dto.deliveryEnabled ?? false,
        delivery_zone_id: dto.deliveryZoneId ?? null,
        status: "PUBLISHED",
      },
      select: {
        id: true,
        meal_id: true,
        cook_profile_id: true,
        price_cop: true,
        stock_total: true,
        stock_available: true,
        created_at: true,
      },
    });
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
      select: { id: true, stock_total: true, stock_available: true },
    });
    if (!pub) {
      throw new DomainError({
        code: ErrorCodes.ORDER_NOT_FOUND,
        message: "Publication not found",
        statusCode: 404,
      });
    }

    const nextStockTotal = dto.stockTotal ?? pub.stock_total;
    const nextStockAvailable = dto.stockAvailable ?? pub.stock_available;

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

    return this.prisma.meal_publications.update({
      where: { id: publicationId },
      data: {
        ...(dto.priceCop !== undefined ? { price_cop: dto.priceCop } : {}),
        ...(dto.status !== undefined ? { status: dto.status } : {}),
        ...(dto.stockTotal !== undefined ? { stock_total: nextStockTotal } : {}),
        ...(dto.stockAvailable !== undefined ? { stock_available: nextStockAvailable } : {}),
        ...(dto.stockTotal !== undefined && dto.stockAvailable === undefined
          ? { stock_available: Math.min(pub.stock_available, nextStockTotal) }
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

