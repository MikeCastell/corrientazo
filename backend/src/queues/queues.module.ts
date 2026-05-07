import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { BullModule } from "@nestjs/bullmq";

import { Env } from "../config/env";

@Module({
  imports: [
    ConfigModule,
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => {
        const redisUrl = config.get("REDIS_URL", { infer: true });
        return {
          connection: {
            url: redisUrl,
          },
        };
      },
    }),
  ],
})
export class QueuesModule {}

