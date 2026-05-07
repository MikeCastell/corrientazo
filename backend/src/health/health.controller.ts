import { Controller, Get } from "@nestjs/common";
import { PrismaService } from "../database/prisma/prisma.service";
import { ConfigService } from "@nestjs/config";
import { Env } from "../config/env";
import { Redis } from "ioredis";

@Controller()
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>
  ) {}

  @Get("healthz")
  healthz() {
    return { ok: true };
  }

  @Get("readyz")
  async readyz() {
    // DB readiness
    await this.prisma.$queryRaw`SELECT 1`;

    // Redis readiness (simple ping)
    const redisUrl = this.config.get("REDIS_URL", { infer: true });
    const redis = new Redis(redisUrl, { maxRetriesPerRequest: 0 });
    try {
      const pong = await redis.ping();
      return { ok: true, redis: pong === "PONG" };
    } finally {
      redis.disconnect();
    }
  }
}

