import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";

import { envSchema, loadEnv } from "./config/env";
import { QueuesModule } from "./queues/queues.module";

/**
 * WorkerModule:
 * - Carga ConfigModule.forRoot (env validation)
 * - Importa QueuesModule para BullMQ wiring
 *
 * Importante: el worker NO debe depender de AppModule para evitar traer
 * HTTP stack y módulos no necesarios.
 */
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      load: [loadEnv],
      validate: (config: Record<string, unknown>) => envSchema.parse(config),
    }),
    QueuesModule,
  ],
})
export class WorkerModule {}

