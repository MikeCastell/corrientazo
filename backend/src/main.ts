import "reflect-metadata";

import "dotenv/config";

import cookieParser from "cookie-parser";
import helmet from "helmet";
import { ValidationPipe } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";

import { AppModule } from "./app.module";
import { HttpExceptionFilter } from "./common/filters/http-exception.filter";
import { CorrelationIdInterceptor } from "./common/interceptors/correlation-id.interceptor";

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,
  });

  app.use(helmet());
  app.use(cookieParser());

  app.setGlobalPrefix("api");

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    })
  );

  app.useGlobalInterceptors(new CorrelationIdInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());

  app.enableShutdownHooks();

  const port = process.env.PORT ? Number(process.env.PORT) : 3000;
  await app.listen(port, "0.0.0.0");
  // eslint-disable-next-line no-console
  console.log(`[api] listening on 0.0.0.0:${port}`);
}

bootstrap().catch((err) => {
  // eslint-disable-next-line no-console
  console.error("[api] bootstrap failed", err);
  process.exit(1);
});

