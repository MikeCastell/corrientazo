import "reflect-metadata";

import { NestFactory } from "@nestjs/core";

import { QueuesModule } from "./queues/queues.module";

/**
 * Worker bootstrap:
 * - Levanta contexto Nest para processors BullMQ (y futuros consumers).
 * - No expone HTTP.
 */
async function bootstrapWorker() {
  await NestFactory.createApplicationContext(QueuesModule, {
    logger: ["log", "error", "warn"],
  });
}

void bootstrapWorker();

