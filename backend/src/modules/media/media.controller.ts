import { Controller, Post, UploadedFile, UseGuards, UseInterceptors, Req } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";
import { FileInterceptor } from "@nestjs/platform-express";
import { diskStorage } from "multer";
import { extname, join } from "path";
import { randomUUID } from "crypto";
import type { Request } from "express";
import type { Express } from "express";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";

@ApiTags("media")
@Controller("media")
export class MediaController {
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Upload media file (MVP: disk storage)" })
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
  @ApiResponse({ status: 201 })
  @UseInterceptors(
    FileInterceptor("file", {
      storage: diskStorage({
        destination: (
          _req: Request,
          _file: Express.Multer.File,
          cb: (error: Error | null, destination: string) => void
        ) => cb(null, join(process.cwd(), "uploads")),
        filename: (
          _req: Request,
          file: Express.Multer.File,
          cb: (error: Error | null, filename: string) => void
        ) => {
          const safeExt = extname(file.originalname || "").slice(0, 10) || ".bin";
          cb(null, `${randomUUID()}${safeExt}`);
        },
      }),
      limits: { fileSize: 6 * 1024 * 1024 }, // 6MB
    })
  )
  upload(@UploadedFile() file: Express.Multer.File, @Req() req: Request) {
    const host = req.get("host");
    const proto = req.protocol;
    const url = `${proto}://${host}/uploads/${file.filename}`;
    return { url };
  }
}

