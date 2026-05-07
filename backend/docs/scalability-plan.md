---
title: "CORRIENTAZO — Escalabilidad (Producción)"
version: "1.0"
last_updated: "2026-05-07"
---

## Objetivo
Preparar CORRIENTAZO para:
- miles de usuarios concurrentes,
- miles de pedidos por día con picos en hora pico,
- tracking en vivo con baja latencia,
- notificaciones confiables,
- crecimiento por zonas/ciudad,
- expansión horizontal sin degradación operacional.

## Diagrama: ejes de escalado
```mermaid
flowchart TD
  Client[App Flutter] -->|REST| LB[Nginx Load Balancer]
  LB --> API[API NestJS (N instancias)]
  API --> DB[PostgreSQL]
  API -->|outbox read| Outbox[Outbox table]
  Outbox --> Queue[Redis + BullMQ]
  Queue --> Workers[Workers (N)]

  API -->|Socket.io| RT[Realtime Gateway (N instancias)]
  RT -->|Redis adapter| Redis[Redis (shared)]
```

## 1) API: escalado horizontal
### Stateless y JWT
- Todas las instancias de NestJS deben ser **stateless**.
- Autenticación por `JWT access/refresh`:
  - el access token viaja en cada request,
  - el refresh token se valida en DB.

### Balanceo
- Nginx balancea requests hacia `api`:
  - se recomienda sticky sessions solo si se decide mantener estado en memoria,
  - en este diseño no es necesario: tracking usa rooms + adapter.

### Idempotencia (anti-reintentos)
- `POST /orders` usa `Idempotency-Key` (persistido en `idempotency_keys`).
- Esto evita:
  - creación duplicada de órdenes por reintentos de red,
  - condiciones raras cuando el móvil reenvía requests.

## 2) Socket.io realtime: escalado y consistencia
### Multi-instancia con Redis adapter
- Socket.io se escala con Redis adapter.
- Cada instancia emite eventos a rooms; Redis propaga el mensaje al nodo correcto.

### Rooms como contrato
- `order:{orderId}`:
  - el cliente y el cocinero se unen,
  - los eventos de tracking solo se emiten a esa room.
- `user:{userId}`:
  - notificaciones (en tiempo real).

### Orden de eventos y reconexión
- Cada transición registra `occurred_at` en timeline.
- En payloads de socket:
  - incluir `occurredAt` y/o `eventId`,
  - el cliente ignora eventos “viejos”.
- Endpoint REST de re-sincronización:
  - el cliente usa `GET /orders/:id` si la app detecta inconsistencia.

## 3) Colas y workers (BullMQ): resiliencia + escalado
### Separación de responsabilidades
Queues recomendadas (por lo menos):
- `notifications.send`
- `payments.reconciliation`
- `outbox.dispatch` (si se usa patrón outbox con worker central)

### Escalado por concurrencia
- Ajustar `concurrency` por cola:
  - notificaciones: cuidado con rate limit del proveedor,
  - pagos: limitar a lo que el provider aguante,
  - outbox: throughput alto.

### Retry policy
- Reintentos con backoff exponencial.
- Cada job debe ser idempotente:
  - verificar estado en DB antes de ejecutar efecto secundario.

## 4) PostgreSQL: performance y consistencia
### Pool de conexiones
- Configurar el pool (en Prisma y/o con pgbouncer).
- Recomendación: usar pgbouncer en producción si hay muchos pods/instancias.

### Índices (estratégicos)
Basado en consultas de alto uso (feed “hoy cerca de ti”, tracking, historial):
- `orders(customer_id, created_at)`
- `orders(cook_profile_id, status)`
- `meal_publications(cook_profile_id, available_from, available_to)`
- `notifications(user_id, created_at)`
- `order_status_events(order_id, occurred_at)`
- `payment_attempts(payment_id, status, created_at)`

### Transacciones para evitar sobreventa
- Reserva stock se hace dentro de una transacción con condición:
  - `stock_available >= qty`.
- Esto evita que dos pedidos “ganen” stock simultáneamente.

## 5) Geografía / zonas: partición lógica
### delivery_zones como habilitador
- `delivery_zones` define bounding boxes.
- Regla de elegibilidad:
  - dirección del cliente cae en bounding box,
  - cook tiene esa zona habilitada en `cook_delivery_zones`.

### Futuro: precálculo por índice geográfico
Cuando el volumen suba:
- precomputar asociaciones por geohash / celda,
- o materializar elegibilidad “por zona y hora”.

## 6) Caché (opcional pero recomendado)
### Qué cachear
- feed de “hoy cerca de ti”:
  - lista de `meal_publications` para una zona,
  - con TTL corto (ej. 30-120s) por cambios de stock.

### Qué NO cachear
- disponibilidad de stock para crear pedidos:
  - esa validación debe ser transaccional en DB para prevenir sobreventa.

## 7) Límites y anti-abuso (operación real)
### Rate limiting
- `POST /auth/*`:
  - limitar OTP requests.
- `POST /orders`:
  - limitar creación de órdenes por:
    - usuario,
    - IP,
    - ventana temporal.

### Límites por cook
- límite de publicaciones activas por cook
- límite de cancelaciones (y cooldown) para evitar abuso.

## 8) SLOs y pruebas de carga
### Objetivos (guía)
- latencia p95 REST:
  - lectura (feeds): < 250ms (cache) / < 400ms (sin cache),
  - creación de pedido: < 800ms (incluye transacción).
- realtime tracking:
  - tiempo de entrega de evento: < 1s en redes normales.

### Load testing
- herramienta: k6
- escenarios:
  - usuarios creando pedidos simultáneos (validar sold-out correcto),
  - reconexión y re-suscripción al socket,
  - spike de webhooks (pagos) y colas de notificaciones.

## 9) Observabilidad operativa
### Dashboards mínimas
- API:
  - p95/p99 por endpoint,
  - tasa de errores por código.
- Realtime:
  - conexiones activas,
  - latencia de delivery (si se mide en cliente).
- Colas:
  - jobs en espera,
  - retries,
  - edad del job más antiguo.
- DB:
  - conexiones activas,
  - locks/tiempos de transacción.

### Tracing y correlationId
- correlationId viaja de REST hacia:
  - logs,
  - outbox jobs,
  - workers.

---
Fin del documento.

