---
title: "CORRIENTAZO — Notifications (Push + Realtime + Historial) con BullMQ"
version: "1.0"
last_updated: "2026-05-07"
---

## Objetivo
Garantizar notificaciones confiables:
- push (FCM/APNS) cuando el pedido cambia,
- realtime en app vía Socket.io,
- historial in-app desde PostgreSQL.

Características de producción:
- idempotencia (evitar duplicados),
- retries con backoff,
- observabilidad por job (tiempo, fallos, reintentos),
- compatibilidad multi-instancia (BullMQ + Redis).

## Modelo de datos (Prisma)
Basado en:
- `notifications`: historial por usuario (read/unread, timestamps).
- `notifications.type`: enum de tipo de notificación.

Recomendación:
- Para payloads complejos, usar `payload_json` en `notifications`.

## Contrato de entrega
### Realtime
- Evento: `notification.new`
- Emisión: room `user:{userId}`

### Push
- Encolar job `notifications.send`
- Worker envía al proveedor (FCM/APNS)
- Actualiza estado y registra resultado

## Flujo de creación de notificación (event-driven)
1. Un servicio de dominio crea una notificación en DB:
   - inserta `notifications` con `is_read=false`
2. En el mismo caso de uso se registra un evento outbox:
   - (opción preferida) `domain_event_outbox` para “notification.created”
3. Worker consume outbox y ejecuta:
   - emitir realtime `notification.new`
   - encolar push job si el usuario tiene dispositivos registrados (futuro)

## BullMQ: jobs, colas y reintentos
### Cola principal
- Queue: `notifications.send`
- Job payload mínimo:
  - `notificationId`
  - `userId`
  - `correlationId`
  - `attempt` (opcional)

### Retry policy
- backoff exponencial
- máximo reintentos (ej. 5)
- idempotencia:
  - el worker valida que la notificación exista y que no haya sido procesada “finalmente” (puede agregarse un campo futuro `push_status` si quieres granularidad).

### Rate limiting (protección)
En producción:
- limitar envíos por usuario/segundo (para evitar spam y bloqueos del proveedor).

## Observabilidad (imprescindible)
Registrar por job:
- `jobId`, `queueName`, `notificationId`
- `startedAt`, `endedAt`, `durationMs`
- resultado: success/failure
- error normalizado y categoría (e.g. provider down vs invalid token)

Métricas sugeridas:
- `notifications_jobs_total{status=...}`
- `notifications_delivery_latency_seconds`
- `notifications_retry_rate`

## In-App history
Endpoints:
- `GET /notifications` (paginado, orden por created_at desc)
- `POST /notifications/:id/read`
- `POST /notifications/read-all`

## Importante: consistencia UX
- Si el push llega tarde:
  - el usuario igual verá la notificación en historial.
- Si Socket.io se corta:
  - la pantalla de “Pedidos” o “Estado del pedido” debe ofrecer refresco REST o reconexión.

---
Fin del documento.

