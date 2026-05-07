---
title: "CORRIENTAZO — Backend Architecture (Prod)"
version: "1.0"
last_updated: "2026-05-07"
stack: "NestJS, PostgreSQL, Prisma, Socket.io, JWT, Redis(BullMQ), Docker, VPS Ubuntu"
---

## Visión general
CORRIENTAZO es un marketplace hiperlocal donde:
- Los clientes compran “corrientazos” y requieren **tracking en vivo**.
- Los cocineros gestionan disponibilidad, aceptan y actualizan estados.
- La plataforma debe garantizar **consistencia** (evitar sobreventa), **cumplimiento sanitario**, reputación y un sistema de reportes.

El backend está diseñado para operación real:
- **Miles de usuarios** concurrentes.
- **Eventos en tiempo real** (Socket.io) con tolerancia a reconexiones.
- **Notificaciones** (push + realtime) con retries y observabilidad.
- **Pagos listos para Nequi/Daviplata** mediante adapters + webhooks + reconciliación.
- **Escalabilidad horizontal** (multi-instancia) lista desde el diseño.

## Principios de diseño
1. **Fuente de verdad en PostgreSQL**.
2. **Socket.io como canal de entrega**, no como almacén: el cliente puede reconsultar REST para consistencia.
3. **Transacciones + idempotencia** en operaciones críticas (creación de pedido, reserva de stock, cobros).
4. **Event-driven** para notificaciones, reconciliación y sincronización hacia realtime.
5. **Multi-instancia** desde el inicio: Socket.io con Redis adapter y workers con BullMQ sobre Redis.
6. **Auditabilidad**: toda transición de estado queda registrada (timeline) para tracking, soporte y disputas.

## Diagrama de alto nivel
```mermaid
flowchart TD
  App[Flutter App] -->|REST /api| Nginx[Nginx (TLS)]
  Nginx -->|JWT| Api[NestJS API (stateless)]
  Api -->|Prisma| DB[(PostgreSQL)]
  Api -->|Emit events| Outbox[Transactional Outbox]
  Outbox -->|BullMQ| Worker[Worker NestJS]
  Worker -->|Push| PushSvc[FCM/APNS]
  Worker -->|Realtime updates| Socket[Socket.io Gateway]
  Socket -->|rooms| UserRooms[Clientes/Cocineros por pedido]
  Api -->|Tracking events| Socket
```

## Arquitectura modular (NestJS)
El backend se organiza por **módulos de dominio**:
- `auth`
- `users`
- `cooks` (onboarding/verificación)
- `sanitary` (niveles, checklist, reportes, suspensiones)
- `meals` (catálogo y publicación)
- `orders` (máquina de estados, transacciones)
- `payments` (adapters, webhooks, reconciliación)
- `reviews`
- `addresses`
- `notifications` (historial y plantillas)
- `realtime` (Socket.io gateways + mapping de eventos)
- `queues` (BullMQ processors/handlers)
- `admin` (backoffice, moderación, acciones)
- `common` (shared: logging, interceptors, guards base, error handling)

Cada módulo sigue la separación:
- **Controller**: HTTP layer (DTOs, validación, orquestación ligera).
- **Service**: lógica de negocio y orquestación de caso de uso.
- **Repository**: acceso Prisma con queries especializadas y performance.
- **Gateway/Queue Processor**: delivery de eventos (socket/colas).

## Estructura del proyecto (carpetas)
Repositorio en `backend/` (ver también `backend/docs/nest-structure.md` para convenciones):

```text
backend/
  src/
    app.module.ts
    main.ts
    config/
    common/
      authz/
      decorators/
      filters/
      interceptors/
      guards/
      logging/
      validation/
    database/
      prisma/
      transactions/
    auth/
      auth.controller.ts
      auth.service.ts
      jwt/
      guards/
    users/
    cooks/
    sanitary/
    meals/
    orders/
    payments/
    reviews/
    addresses/
    notifications/
    realtime/
    queues/
    admin/
  prisma/
    schema.prisma
    seed.ts
  docs/
    BackendArchitectureProd.md
    (otros documentos de módulos)
  docker/
    nginx/
      nginx.conf
  Dockerfile.api
  Dockerfile.worker
  docker-compose.yml
  .env.example
```

## Componentes NestJS: controllers, services, repositories y real-time
### Controllers
- Reciben request, aplican DTOs (validación con `class-validator`/`zod`), auth guard y roles.
- No contienen lógica compleja; delegan a `Service`.

### Services
- Implementan casos de uso: `createOrder`, `confirmOrder`, `updateOrderStatus`, `submitSanitaryChecklist`, `startPaymentAttempt`, etc.
- Emite eventos de dominio (internos) y registra timeline/audits.

### Repositories
- Usan Prisma y encapsulan queries intensivas o con condiciones complejas.
- Ejemplos:
  - `OrdersRepository.reserveStockAndCreateOrder(...)`
  - `MealsRepository.getPublicationAvailability(...)`

### Gateways (Socket.io)
- `OrdersTrackingGateway`:
  - Emite `order.status.updated` y `order.eta.updated` al `room` `order:{orderId}`.
- `UserNotificationGateway` (opcional):
  - Emite `notification.new` al `room` `user:{userId}`.

### Guards
- `JwtAuthGuard`: valida acceso JWT.
- `RolesGuard`: autoriza por rol.
- `SanitaryEnabledGuard` / `CookActiveGuard`: restringe acciones (ej. publicar) a cocineros habilitados.

### Interceptors & Middlewares
- `CorrelationIdInterceptor`: genera/propaga `x-correlation-id`.
- `TimingInterceptor`: métricas de latencia.
- `LoggingInterceptor` (o middleware): request/response logs estructurados.
- `HttpExceptionFilter`: mapea errores de dominio a códigos y mensajes consistentes.

## 1) Sistema de autenticación
### JWT: access + refresh tokens
- **Access token**: TTL corto (ej. 15 min).
- **Refresh token**: TTL largo (ej. 30 días) y rotación.

### Refresh token rotativo
- Se guarda en DB (tabla `refresh_tokens`) con:
  - hash del token,
  - expiración,
  - `revokedAt`,
  - `rotatedFromId` para rastrear replay.
- Endpoint:
  - `POST /auth/refresh` valida refresh token y emite nuevos tokens.

### Roles y permisos (RBAC)
- Roles:
  - `ADMIN`
  - `COOK`
  - `CUSTOMER`
- Permisos:
  - Se recomienda comenzar con RBAC por rol y evolucionar a permissions granulares si se necesita.

### Seguridad recomendada
- HTTPS obligatorio detrás de Nginx.
- Rate limiting en `/auth/*`.
- Revocación y rotación de refresh tokens.

## 2) Modelo de base de datos (Prisma) — blueprint
Ver documento detallado: `backend/docs/prisma-schema-design.md`.
Resumen por dominio:
- `users`, `addresses`
- `meals` (plantillas + publicaciones/lotes del día)
- `orders` + `order_items` + `order_status_events` (audit timeline)
- `payments` + `payment_attempts` + `payment_webhooks`
- `reviews`
- `notifications` (historial) y `notification_events` (opcional)
- `sanitary_checks` + `sanitary_levels` + `reports` + `suspensions`
- `delivery_zones`
- `idempotency_keys` para prevenir duplicados por reintentos
- tablas de soporte para outbox y auditabilidad

## 3) Sistema de pedidos
### Flujo de creación y cumplimiento
1. `POST /orders` (cliente)
   - Aplica idempotencia: `Idempotency-Key` por `customer`.
   - Valida:
     - publicación disponible,
     - stock/cupos,
     - cobertura si es `DELIVERY`,
     - reglas de cancelación.
   - Registra orden en estado `INIT`.
2. **Reserva de stock atómica**
   - Transacción:
     - selecciona publicación,
     - asegura `stock_available >= qty`,
     - decrementa stock.
3. Crea `payment` (estado según método).
4. Envia evento hacia notificaciones/realtime vía outbox.
5. Cocinero acepta y transiciona a:
   - `CONFIRMED` → `PREPARING` → `READY_FOR_PICKUP` o `READY_FOR_DISPATCH`
6. Cliente/cocinero marcan entrega/recogida:
   - `DELIVERED` / `PICKED_UP`
7. Al finalizar, habilita calificación.

### Máquina de estados (reglas)
- Solo transiciones válidas:
  - evita cambios arbitrarios desde endpoints.
- Cada transición crea un registro en `order_status_events`.

### Prevención de sobreventa
- Stock/cupos en `meal_publications` o entidad equivalente.
- Operación de reserva con estrategia:
  - Condicional update (ideal) o
  - `SELECT ... FOR UPDATE` por fila publication.
- Ante conflicto:
  - el endpoint responde con error de “sold out” o “cupos agotados”.

## 4) Tiempo real (Socket.io)
### Tracking en vivo
- Room `order:{orderId}`:
  - Cliente y cocinero se suscriben a este room.
- Eventos:
  - `order.status.updated` con payload mínimo + timestamps.
  - `order.eta.updated` (si la ETA se recalcula).

### Consistencia
- El cliente:
  - escucha eventos,
  - pero si pierde conexión, hace `GET /orders/:id` para re-sincronizar.

### Multi-instancia
- Socket.io Redis adapter:
  - se comparte emisión entre nodos.
- Nginx balancea instancias (sticky session opcional, pero rooms se reparten por adapter).

## 5) Sistema de pagos (Nequi/Daviplata + futuro)
### Diseño por adapters
- `PaymentProvider` interface:
  - `createPaymentIntent(...)`
  - `verifyWebhookSignature(...)`
  - `mapWebhookToPaymentStatus(...)`
  - `parseProviderMetadata(...)`

### Webhooks y reconciliación
- Tabla `payment_webhooks` para idempotencia de webhooks.
- Worker:
  - reintenta si hay fallos temporales,
  - concilia estado final y actualiza timeline.

### Estrategia de integridad
- Cada attempt tiene:
  - `status` (PENDING/PAID/FAILED/REFUNDED),
  - `provider_ref`,
  - `idempotency_key` interna.

## 6) Sistema sanitario
### Verificación por niveles
- Cocinero inicia con checklist básico.
- Niveles incrementan cuando completa evidencias.
- Se usa reputación y reportes para autorizar o restringir domicilio.

### Reportes y suspensiones
- `reports` ligan:
  - pedido,
  - cocinero,
  - evidencia (opcional),
  - severidad.
- Admin aplica:
  - advertencia,
  - suspensión temporal,
  - re-verificación obligatoria.

### Impacto en marketplace
- Badges sanitarios afectan ranking y habilitación de modalidades.

## 7) Notificaciones (push + realtime + historial)
### Historial
- `notifications` registra:
  - tipo,
  - payload resumido,
  - estado leída.

### Push y realtime
- Realtime:
  - evento `notification.new` al room `user:{userId}`.
- Push:
  - BullMQ queue `notifications.send`.
  - Workers con retries e idempotencia.

### Idempotencia
- Evita duplicados por reintentos de jobs o fallos de proveedor.

## 8) Logs y errores
### Logging estructurado
- Formato JSON.
- Campos mínimos:
  - `timestamp`, `level`, `service`, `requestId`, `correlationId`, `userId`, `orderId`.

### Correlation ID
- Se genera si no existe en headers.
- Se propaga a:
  - logs,
  - eventos de outbox,
  - payloads de jobs en colas.

### Exception filters
- Mapeo:
  - errores de validación → 400,
  - auth → 401/403,
  - sold out/stock → 409,
  - payment errors → 502/424 según caso.

### Observabilidad
- Health check endpoints:
  - `GET /healthz`
  - `GET /readyz` (deps: DB/Redis)

## 9) Docker y despliegue
Ver documento: `backend/docs/docker-deploy.md`.
Resumen:
- Servicios:
  - `api` (NestJS)
  - `worker` (BullMQ processors)
  - `postgres`
  - `redis`
  - `nginx`
- Nginx maneja TLS y websockets.

## 10) Escalabilidad
### Plan para miles de pedidos concurrentes
- API stateless.
- Workers independientes para:
  - notificaciones,
  - reconciliación de pagos,
  - envío de eventos.
- Socket.io Redis adapter.

### Hot paths
- endpoints de feed de “hoy cerca de ti”:
  - cache read-heavy (opcional) y/o materialización de búsquedas por zona.

### Zonas múltiples
- `delivery_zones` permite habilitar cobertura por región.
- Precalcular “eligibilidad” por dirección (futuro) o validar con geohash a demanda.

## Definiciones de enums (resumen)
Estos enums se implementan en Prisma + código:
- `OrderStatus`:
  - `INIT`
  - `CONFIRMED`
  - `PREPARING`
  - `READY_FOR_PICKUP`
  - `READY_FOR_DISPATCH`
  - `OUT_FOR_DELIVERY`
  - `DELIVERED`
  - `PICKED_UP`
  - `CANCELLED_BY_CLIENT`
  - `CANCELLED_BY_COOK`
  - `CANCELLED_BY_ADMIN`
  - `REFUNDED`
- `PaymentMethod`:
  - `CASH`, `NEQUI`, `DAVIPLATA`, `FUTURE_GATEWAY`
- `PaymentStatus`:
  - `PENDING`, `PAID`, `FAILED`, `REFUNDED`
- `SanitaryLevel`:
  - `LEVEL_0` ... `LEVEL_N` (materializable)

## Contratos de eventos internos (para sockets/colas)
Eventos de ejemplo:
- `order.status.updated`
  - payload: `{ orderId, status, occurredAt, eta?: { minutes, updatedAt } }`
- `order.eta.updated`
  - payload: `{ orderId, etaMinutes, updatedAt }`
- `notification.new`
  - payload: `{ notificationId, userId, type }`

Nota: el cliente siempre puede reconsultar `GET /orders/:id` si necesita consistencia total.

---
Fin del documento maestro.

