import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from "@nestjs/common";
import { Observable } from "rxjs";
import type { Request } from "express";

/**
 * CorrelationIdInterceptor:
 * - toma x-correlation-id si existe,
 * - si no, genera uno,
 * - lo agrega en response header y lo registra en el contexto de ejecución.
 *
 * Implementación real:
 * - usa uuid,
 * - usa AsyncLocalStorage para propagación a logs/colas.
 */
@Injectable()
export class CorrelationIdInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const http = context.switchToHttp();
    const req = http.getRequest<Request & { correlationId?: string }>();
    const res = http.getResponse<any>();

    const correlationId =
      (req as any)?.headers?.["x-correlation-id"] ?? `corr_${Date.now()}`;

    (req as any).correlationId = correlationId;
    if (res?.setHeader) res.setHeader("x-correlation-id", correlationId);

    return next.handle();
  }
}

