import { Module } from "@nestjs/common";

import { CookAiService } from "./cook-ai.service";
import { CookController } from "./cook.controller";
import { CookService } from "./cook.service";

@Module({
  controllers: [CookController],
  providers: [CookService, CookAiService],
})
export class CookModule {}

