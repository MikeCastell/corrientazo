import { Injectable } from "@nestjs/common";

import { PrismaService } from "../../database/prisma/prisma.service";
import { DomainError } from "../../common/errors/domain-errors";
import { ErrorCodes } from "../../common/errors/error-codes";
import { CreateMealDto, PublishMealDto } from "./meals.dto";

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
        base_price_cop: true,
        cook_profile_id: true,
        created_at: true,
      },
    });
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

