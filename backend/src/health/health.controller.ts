import { readFileSync } from "fs";
import { join } from "path";

import { Controller, Get } from "@nestjs/common";
import { PrismaService } from "../database/prisma/prisma.service";
import { ConfigService } from "@nestjs/config";
import { Env } from "../config/env";
import { Redis } from "ioredis";

function readPackageVersion(): string {
  try {
    const raw = readFileSync(join(process.cwd(), "package.json"), "utf8");
    const pkg = JSON.parse(raw) as { version?: string };
    return typeof pkg.version === "string" ? pkg.version : "0.0.0";
  } catch {
    return "0.0.0";
  }
}

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

  /** Metadatos de build: usalos para comprobar que el contenedor no quedó con un `dist` viejo. */
  @Get("version")
  version() {
    return {
      ok: true,
      service: "corrientazo-api",
      version: readPackageVersion(),
      git: process.env.APP_GIT_COMMIT ?? "unknown",
      builtAt: process.env.APP_BUILD_TIME ?? "unknown",
      node: process.version,
    };
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

