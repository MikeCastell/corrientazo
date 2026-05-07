import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";

import { envSchema, loadEnv } from "./config/env";
import { PrismaModule } from "./database/prisma/prisma.module";
import { HealthModule } from "./health/health.module";
import { AuthModule } from "./modules/auth/auth.module";
import { UsersModule } from "./modules/users/users.module";
import { MealsModule } from "./modules/meals/meals.module";
import { OrdersModule } from "./modules/orders/orders.module";
import { CookModule } from "./modules/cook/cook.module";
import { MediaModule } from "./modules/media/media.module";
import { RealtimeModule } from "./realtime/realtime.module";
import { QueuesModule } from "./queues/queues.module";

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      load: [loadEnv],
      validate: (config: Record<string, unknown>) => envSchema.parse(config),
    }),
    PrismaModule,
    QueuesModule,
    RealtimeModule,
    HealthModule,
    AuthModule,
    UsersModule,
    CookModule,
    MealsModule,
    OrdersModule,
    MediaModule,
  ],
})
export class AppModule {}

