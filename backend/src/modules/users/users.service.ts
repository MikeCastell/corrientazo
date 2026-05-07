import { Injectable } from "@nestjs/common";

import { PrismaService } from "../../database/prisma/prisma.service";

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    return this.prisma.users.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        phone: true,
        email: true,
        name: true,
        role: true,
        status: true,
        created_at: true,
      },
    });
  }
}

