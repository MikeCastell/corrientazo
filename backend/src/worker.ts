import "reflect-metadata";

import "dotenv/config";

import { NestFactory } from "@nestjs/core";

import { WorkerModule } from "./worker.module";

/**
 * Worker bootstrap:
 * - Levanta contexto Nest para processors BullMQ (y futuros consumers).
 * - No expone HTTP.
 */
async function bootstrapWorker() {
  await NestFactory.createApplicationContext(WorkerModule, {
    logger: ["log", "error", "warn"],
  });
}

void bootstrapWorker();

