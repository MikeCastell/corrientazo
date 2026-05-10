import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from "@nestjs/swagger";
import type { Express } from "express";
import multer from "multer";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { CookAiService } from "./cook-ai.service";
import { CookService } from "./cook.service";
import { UpdateCookProfileDto } from "./cook.dto";

@ApiTags("cook")
@Controller("cook")
export class CookController {
  constructor(
    private readonly cooks: CookService,
    private readonly cookAi: CookAiService,
  ) {}

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Get cook profile (MVP)" })
  @ApiResponse({ status: 200 })
  @Get("profile")
  getProfile(@CurrentUserDecorator() user: { userId: string }) {
    return this.cooks.getProfile(user.userId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Update cook profile (MVP)" })
  @ApiBody({ type: UpdateCookProfileDto })
  @ApiResponse({ status: 200 })
  @Patch("profile")
  updateProfile(@CurrentUserDecorator() user: { userId: string }, @Body() dto: UpdateCookProfileDto) {
    return this.cooks.updateProfile(user.userId, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({
    summary: "Sugerir descripción del plato a partir de una foto (IA)",
    description:
      "Requiere GEMINI_API_KEY en el servidor. La imagen no se guarda; solo se envía al modelo para generar texto.",
  })
  @ApiConsumes("multipart/form-data")
  @ApiBody({
    schema: {
      type: "object",
      properties: {
        file: { type: "string", format: "binary" },
      },
      required: ["file"],
    },
  })
  @ApiResponse({ status: 200, description: "{ description: string }" })
  @ApiResponse({ status: 503, description: "GEMINI_API_KEY no configurada" })
  @Post("meals/describe-photo")
  @UseInterceptors(
    FileInterceptor("file", {
      storage: multer.memoryStorage(),
      limits: { fileSize: 6 * 1024 * 1024 },
      fileFilter: (
        _req: unknown,
        file: Express.Multer.File,
        cb: (error: Error | null, acceptFile: boolean) => void
      ) => {
        const ok = /^image\/(jpeg|png|webp|gif|heic|heif)$/i.test(file.mimetype || "");
        if (!ok) {
          cb(
            new BadRequestException("Usa una imagen (JPEG, PNG, WebP o GIF)."),
            false
          );
          return;
        }
        cb(null, true);
      },
    })
  )
  async describeMealPhoto(@UploadedFile() file: Express.Multer.File) {
    if (!file?.buffer?.length) {
      throw new BadRequestException("Adjunta una imagen.");
    }
    const mime = file.mimetype || "image/jpeg";
    const description = await this.cookAi.describeMealImage(file.buffer, mime);
    return { description };
  }
}

