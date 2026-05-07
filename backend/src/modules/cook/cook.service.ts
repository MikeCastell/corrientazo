import { Injectable } from "@nestjs/common";

import { PrismaService } from "../../database/prisma/prisma.service";
import { DomainError } from "../../common/errors/domain-errors";
import { ErrorCodes } from "../../common/errors/error-codes";
import { UpdateCookProfileDto } from "./cook.dto";

@Injectable()
export class CookService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    const cook = await this.ensureCookProfile(userId);
    return this.prisma.cook_profiles.findUniqueOrThrow({
      where: { id: cook.id },
      select: {
        id: true,
        user_id: true,
        bio: true,
        kitchen_address_id: true,
        is_active: true,
        delivery_enabled: true,
        pickup_enabled: true,
        operational_policy_json: true,
        created_at: true,
        updated_at: true,
        user: { select: { name: true, avatar_url: true, phone: true } },
      },
    });
  }

  async updateProfile(userId: string, dto: UpdateCookProfileDto) {
    const cook = await this.ensureCookProfile(userId);

    if (dto.businessName !== undefined) {
      await this.prisma.users.update({
        where: { id: userId },
        data: { name: dto.businessName },
      });
    }
    if (dto.avatarUrl !== undefined) {
      await this.prisma.users.update({
        where: { id: userId },
        data: { avatar_url: dto.avatarUrl },
      });
    }

    return this.prisma.cook_profiles.update({
      where: { id: cook.id },
      data: {
        ...(dto.bio !== undefined ? { bio: dto.bio } : {}),
        ...(dto.kitchenAddressId !== undefined ? { kitchen_address_id: dto.kitchenAddressId } : {}),
        ...(dto.pickupEnabled !== undefined ? { pickup_enabled: dto.pickupEnabled } : {}),
        ...(dto.deliveryEnabled !== undefined ? { delivery_enabled: dto.deliveryEnabled } : {}),
        ...(dto.operationalPolicyJson !== undefined
          ? { operational_policy_json: dto.operationalPolicyJson as any }
          : {}),
      },
      select: {
        id: true,
        user_id: true,
        bio: true,
        kitchen_address_id: true,
        is_active: true,
        delivery_enabled: true,
        pickup_enabled: true,
        operational_policy_json: true,
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
      update: { is_active: true },
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

