---
title: "CORRIENTAZO — Logging, Monitoring y Manejo de Errores"
version: "1.0"
last_updated: "2026-05-07"
---

## Objetivo
Garantizar en producción:
- diagnósticos rápidos (logs estructurados),
- trazabilidad por request (correlationId),
- errores consistentes (códigos y mensajes),
- visibilidad operativa (healthchecks, métricas y alertas).

## Logging estructurado (JSON)
### Recomendación de logger
- usar Pino o Winston con salida JSON.
- logs con campos consistentes.

Campos mínimos:
- `timestamp`
- `level`
- `service` (ej. `api` / `worker`)
- `requestId` o `correlationId`
- `userId` (si existe)
- `orderId` / `paymentId` (si existe)
- `route` / `method`
- `statusCode`
- `durationMs`
- `error` (solo en error): `name`, `message`, `stack` opcional según entorno.

## Correlation ID
### Qué es
Un identificador único por request que se propaga a:
- logs,
- eventos de outbox,
- jobs de BullMQ,
- respuestas de error.

### Estrategia
- `CorrelationIdInterceptor`:
  - si existe `x-correlation-id`, usarlo,
  - si no, generar uno.
- se agrega a response header.

## Manejo de excepciones
### Taxonomía
Se recomienda separar:
1. `DomainError` (fallas esperadas del dominio)
   - sold out, invalid state transition, unauthorized cook action.
2. `AuthError` (invalid/expired token)
3. `ValidationError` (DTO / schema invalid)
4. `SystemError` (fallas inesperadas)

### Contrato de respuesta de error (estándar)
Formato sugerido:
```json
{
  "error": {
    "code": "ORDER_SOLD_OUT",
    "message": "No hay cupos disponibles para este corrientazo",
    "details": { "...": "..." },
    "correlationId": "..."
  }
}
```

### Exception filter global
- Un `HttpExceptionFilter` mapea exceptions a:
  - `statusCode`,
  - `error.code`.

## Error handling en tiempo real y colas
### Socket.io
- Si un usuario intenta subscribirse a un pedido que no le pertenece:
  - emitir un evento de error (`order:subscribe.failed`)
  - y opcionalmente negar `join`.

### BullMQ
- Cada job:
  - registra `jobId`, intento y duración,
  - usa idempotencia (no duplicar efectos),
  - reintentos con backoff.

## Monitoring y alertas (mínimo viable)
### Health checks
Endpoints recomendados:
- `GET /healthz` (liveness): responde OK sin dependencias.
- `GET /readyz` (readiness): requiere Postgres y Redis.

### Métricas
Métricas mínimas:
- latencia p95/p99 de endpoints críticos (`/orders`, `/payments/webhooks`)
- número de errores por código (`ORDER_SOLD_OUT`, `PAYMENT_WEBHOOK_DUPLICATE`, etc.)
- estado de colas:
  - jobs en espera
  - tasa de fallos
  - edad del job más antiguo

Integración sugerida:
- Prometheus + Grafana (siempre que el equipo lo use).

### Trazas y alertas
- opción: Sentry o similar para stack traces con correlationId.

---
Fin del documento.

