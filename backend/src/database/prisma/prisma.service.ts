import { INestApplication, Injectable, OnModuleInit } from "@nestjs/common";
import { PrismaClient } from "@prisma/client";

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect();
  }

  async enableShutdownHooks(app: INestApplication) {
    // Prisma v6+ tipa $on de forma distinta dependiendo del engine; para mantener
    // foundation estable, usamos signals del proceso para cerrar el app.
    const shutdown = async () => {
      await app.close();
    };
    process.on("SIGINT", shutdown);
    process.on("SIGTERM", shutdown);
  }
}

