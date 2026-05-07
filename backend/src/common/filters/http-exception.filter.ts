import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import { Response } from "express";

import { DomainError } from "../errors/domain-errors";
import { ErrorCode } from "../errors/error-codes";

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<any>();

    const correlationId = req?.correlationId ?? req?.headers?.["x-correlation-id"];

    // Domain error: controlado por el dominio
    if (exception instanceof DomainError) {
      const errCode: ErrorCode = exception.code;
      res.status(exception.statusCode).json({
        error: {
          code: errCode,
          message: exception.message,
          details: exception.details ?? undefined,
          correlationId,
        },
      });
      return;
    }

    // Nest HttpException: validaciones / auth / etc.
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      res.status(status).json({
        error: {
          code: "HTTP_ERROR",
          message: (exception.getResponse() as any)?.message ?? exception.message,
          correlationId,
        },
      });
      return;
    }

    // Error inesperado
    res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      error: {
        code: "INTERNAL_ERROR",
        message: "Unexpected error",
        correlationId,
      },
    });
  }
}

