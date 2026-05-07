import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { BullModule } from "@nestjs/bullmq";

import { Env } from "../config/env";
import { NotificationsSendProcessor } from "./notifications.processor";

@Module({
  imports: [
    ConfigModule,
    BullModule.forRootAsync({
      imports: [ConfigModule],
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
    BullModule.registerQueue({
      name: "notifications.send",
    }),
  ],
  providers: [NotificationsSendProcessor],
})
export class QueuesModule {}

