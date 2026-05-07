---
title: "CORRIENTAZO — Socket.io Realtime Tracking"
version: "1.0"
last_updated: "2026-05-07"
---

## Objetivo
Permitir tracking en vivo y notificaciones inmediatas con Socket.io:
- El estado del pedido debe reflejarse en tiempo real en el móvil.
- Debe resistir reconexiones, reordenamiento de eventos y escalabilidad horizontal.
- La consistencia se mantiene con REST + audit timeline en PostgreSQL.

## Diseño base: Socket.io + NestJS gateway
### Configuración del servidor
- Socket.io se sirve en la misma API NestJS (misma instancia de Node) o como proceso dedicado (recomendado cuando crezca).
- Se habilita CORS controlado por el frontend.
- Se usa Redis adapter para soportar múltiples instancias.

### Autenticación del socket (JWT)
Regla: ningún usuario puede escuchar un `room` sin estar autenticado.
- El cliente incluye `Authorization: Bearer <accessToken>` en la handshake (o en `auth`).
- El server valida el JWT y extrae `userId`.
- Al autenticarse:
  - se une automáticamente a `user:{userId}`.

## Rooms (estrategia de suscripción)
1. `user:{userId}`
   - notificaciones generales
   - mensajes de soporte (si aplica)
2. `order:{orderId}`
   - tracking del pedido (cliente + cocinero)

Opcional para operaciones:
3. `cook:{cookProfileId}`
   - dashboard en vivo del cocinero (pendiente de pedidos hoy, etc.)

## Eventos (contratos y payloads)
### 1) Suscripción / sincronización
- `order:subscribe`
  - payload: `{ orderId }`
  - server valida:
    - que `userId` sea customer o cook del pedido,
    - que el pedido exista y no esté en estado borrado.
  - server join room: `order:{orderId}`
  - server emite ack:
    - `order:subscribed` con `{ orderId }`

- `order:sync`
  - payload: `{ orderId, clientLastEventAt? }`
  - server responde con:
    - `order.status.updated` (si el cliente está atrasado)
  - fallback: si la sincronización falla, el cliente hace `GET /orders/:id`.

### 2) Tracking (estado y ETA)
- `order.status.updated`
  - payload mínimo:
    - `{ orderId, status, occurredAt, fromStatus, toStatus, actorUserId? }`
  - regla de idempotencia:
    - el cliente aplica el update solo si `occurredAt` es mayor al último recibido.

- `order.eta.updated`
  - payload:
    - `{ orderId, etaMinutes?, updatedAt }`

### 3) Notificaciones
- `notification.new`
  - payload: `{ notificationId, type, title?, body?, payload? }`
  - emit a `user:{userId}`

## Emisión realtime: consistencia REST vs realtime
Regla de producción:
- **REST es fuente de verdad**.
- Socketio es “canal de entrega”.

Para evitar pérdida de eventos:
1. En cada transición crítica:
   - el service escribe `order_status_events` y el `domain_event_outbox`.
2. Un worker consume outbox:
   - valida estado actual en DB (para idempotencia),
   - emite a Socket.io al room correcto.

Así:
- si el proceso Nest cae justo después de la transacción DB,
- el outbox sigue y el worker emite al recuperar.

## Reconexión y re-subscription
Socket.io puede desconectarse por móvil:
- el cliente al reconectar:
  1) re-autentica,
  2) vuelve a `order:subscribe` para todos los pedidos activos visibles,
  3) opcionalmente llama `order:sync`.

## Multi-instancia (horizontal scaling)
- Socket.io Redis adapter comparte emisiones entre nodos.
- Debe existir un Redis único accesible por todos los contenedores.
- Nginx hace balance entre instancias; el adapter asegura que el room reciba la emisión aunque el cliente esté en otro nodo.

## Eventos y versionado
Recomendación:
- incluir `eventVersion` o mantener payload estable.
- cuando se evolucione:
  - se agregan campos opcionales sin romper el consumidor.

---
Fin del documento.

