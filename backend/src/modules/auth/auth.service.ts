import { Injectable } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { ConfigService } from "@nestjs/config";
import { createHmac, randomUUID } from "crypto";
import bcrypt from "bcryptjs";

import { PrismaService } from "../../database/prisma/prisma.service";
import { Env } from "../../config/env";
import { DomainError } from "../../common/errors/domain-errors";
import { ErrorCodes } from "../../common/errors/error-codes";
import { RegisterDto } from "./dto";

type JwtPayload = { sub: string; role: string };

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService<Env, true>
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.users.findUnique({
      where: { phone: dto.phone },
      select: { id: true },
    });
    if (existing) {
      throw new DomainError({
        code: ErrorCodes.AUTH_USER_EXISTS,
        message: "User already exists",
        statusCode: 409,
      });
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const role = dto.role ?? "CUSTOMER";

    const user = await this.prisma.users.create({
      data: {
        phone: dto.phone,
        name: dto.name ?? null,
        role,
      },
      select: { id: true, role: true, phone: true, name: true },
    });

    // Nota: en fase OTP, el password se elimina y se reemplaza por OTP.
    // Para foundation guardamos el hash en un store separado (evita tocar schema de users).
    await this.prisma.auth_passwords.create({
      data: { user_id: user.id, password_hash: passwordHash },
    });

    if (role === "COOK") {
      await this.prisma.cook_profiles.create({
        data: {
          user_id: user.id,
          is_active: true,
          pickup_enabled: true,
          delivery_enabled: false,
        },
      });
    }

    return this.issueTokenPair({ userId: user.id, role: user.role });
  }

  async login(args: { phone: string; password: string }) {
    const user = await this.prisma.users.findUnique({
      where: { phone: args.phone },
      select: { id: true, role: true, status: true },
    });
    if (!user || user.status !== "ACTIVE") {
      throw new DomainError({
        code: ErrorCodes.AUTH_INVALID_TOKEN,
        message: "Invalid credentials",
        statusCode: 401,
      });
    }

    const authPwd = await this.prisma.auth_passwords.findUnique({
      where: { user_id: user.id },
      select: { password_hash: true },
    });
    if (!authPwd) {
      throw new DomainError({
        code: ErrorCodes.AUTH_INVALID_TOKEN,
        message: "Invalid credentials",
        statusCode: 401,
      });
    }

    const ok = await bcrypt.compare(args.password, authPwd.password_hash);
    if (!ok) {
      throw new DomainError({
        code: ErrorCodes.AUTH_INVALID_TOKEN,
        message: "Invalid credentials",
        statusCode: 401,
      });
    }

    return this.issueTokenPair({ userId: user.id, role: user.role });
  }

  async refresh(refreshToken: string) {
    const hashed = this.hashRefreshToken(refreshToken);
    const tokenRow = await this.prisma.refresh_tokens.findFirst({
      where: { token_hash: hashed, revoked_at: null, expires_at: { gt: new Date() } },
      select: { id: true, user_id: true },
    });
    if (!tokenRow) {
      throw new DomainError({
        code: ErrorCodes.AUTH_INVALID_TOKEN,
        message: "Invalid refresh token",
        statusCode: 401,
      });
    }

    const user = await this.prisma.users.findUnique({
      where: { id: tokenRow.user_id },
      select: { id: true, role: true, status: true },
    });
    if (!user || user.status !== "ACTIVE") {
      throw new DomainError({
        code: ErrorCodes.AUTH_INVALID_TOKEN,
        message: "Invalid refresh token",
        statusCode: 401,
      });
    }

    // Rotación: revocamos el anterior y emitimos uno nuevo enlazado
    const { refreshToken: newRefreshToken, refreshTokenHash, refreshExpiresAt } =
      this.createRefreshToken();

    await this.prisma.$transaction([
      this.prisma.refresh_tokens.update({
        where: { id: tokenRow.id },
        data: { revoked_at: new Date() },
      }),
      this.prisma.refresh_tokens.create({
        data: {
          user_id: user.id,
          token_hash: refreshTokenHash,
          expires_at: refreshExpiresAt,
          rotated_from_id: tokenRow.id,
        },
      }),
    ]);

    const accessToken = await this.signAccessToken({ userId: user.id, role: user.role });
    return { accessToken, refreshToken: newRefreshToken };
  }

  async logout(refreshToken: string) {
    const hashed = this.hashRefreshToken(refreshToken);
    await this.prisma.refresh_tokens.updateMany({
      where: { token_hash: hashed, revoked_at: null },
      data: { revoked_at: new Date() },
    });
    return { ok: true };
  }

  private async issueTokenPair(args: { userId: string; role: string }) {
    const accessToken = await this.signAccessToken(args);
    const { refreshToken, refreshTokenHash, refreshExpiresAt } = this.createRefreshToken();

    await this.prisma.refresh_tokens.create({
      data: {
        user_id: args.userId,
        token_hash: refreshTokenHash,
        expires_at: refreshExpiresAt,
      },
    });

    return { accessToken, refreshToken };
  }

  private async signAccessToken(args: { userId: string; role: string }) {
    const payload: JwtPayload = { sub: args.userId, role: args.role };
    return this.jwt.signAsync(payload);
  }

  private createRefreshToken() {
    const refreshToken = randomUUID();
    const refreshTokenHash = this.hashRefreshToken(refreshToken);
    const ttl = this.config.get("JWT_REFRESH_TTL_SECONDS", { infer: true });
    const refreshExpiresAt = new Date(Date.now() + ttl * 1000);
    return { refreshToken, refreshTokenHash, refreshExpiresAt };
  }

  private hashRefreshToken(token: string) {
    // Determinista para lookup. Usamos el refresh secret como key (pepper).
    const key = this.config.get("JWT_REFRESH_SECRET", { infer: true });
    return createHmac("sha256", key).update(token).digest("hex");
  }
}

