---
title: "CORRIENTAZO — Orders Domain (State Machine + Consistency)"
version: "1.0"
last_updated: "2026-05-07"
---

## Objetivo del dominio
Asegurar que el lifecycle del pedido:
- elimine estados inválidos,
- prevenga sobreventa (agotado real),
- mantenga auditabilidad para soporte y disputas,
- habilite tracking en vivo por Socket.io,
- sea resistente a reintentos de red (idempotencia).

## Definiciones clave
### Fulfillment
- `PICKUP`: el cliente recoge en el rango de recogida acordado.
- `DELIVERY`: el pedido requiere dirección y cobertura por zona.

### Pedido como agregada
`orders` es el agregado raíz:
- su `status` es la “verdad” actual,
- las transiciones se registran en `order_status_events` (timeline),
- las reservas de stock quedan ligadas a `meal_publications.stock_available`.

## Máquina de estados
### Estados (enum)
Basado en `OrderStatus` de Prisma:
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

### Transiciones válidas (alto nivel)
La siguiente tabla define acciones de transición por rol:

| Desde | Acción | To | Actor |
|---|---|---|---|
| INIT | confirmar | CONFIRMED | COOK |
| CONFIRMED | comenzar preparación | PREPARING | COOK |
| PREPARING | listo recogida | READY_FOR_PICKUP | COOK |
| PREPARING | listo despacho | READY_FOR_DISPATCH | COOK |
| READY_FOR_DISPATCH | despachado | OUT_FOR_DELIVERY | PLATFORM/COOK |
| OUT_FOR_DELIVERY | entregado | DELIVERED | COURIER/CLIENT/PLATFORM |
| READY_FOR_PICKUP | recogido | PICKED_UP | COURIER/CLIENT/COOK |
| INIT | cancelar | CANCELLED_BY_CLIENT | CLIENT |
| INIT | cancelar | CANCELLED_BY_COOK | COOK |
| cualquier_no_final | cancelar | CANCELLED_BY_ADMIN | ADMIN |

Estados finales (terminales para tracking y reseña):
- `DELIVERED`, `PICKED_UP`, `CANCELLED_*`, `REFUNDED`

### Validaciones por transición (reglas)
1. `INIT -> CONFIRMED`
   - La publicación sigue vigente en ventana `available_from..available_to`.
   - El cocinero está activo y habilitado (sanitario OK y `pickup_enabled`/`delivery_enabled` según fulfillment).
   - Stock reservado ya existe (el decremento debió ocurrir en creación).
2. `CONFIRMED -> PREPARING`
   - Debe ocurrir dentro de un margen razonable (opcional con tolerancia).
3. `PREPARING -> READY_FOR_PICKUP` o `READY_FOR_DISPATCH`
   - Debe respetar la ventana de pickup (`pickup_from..pickup_to`).
   - Para DELIVERY: la dirección del cliente debe estar en cobertura (`delivery_zones`) y el cocinero debe tener esa zona habilitada.
4. `READY_FOR_DISPATCH -> OUT_FOR_DELIVERY`
   - Solo para delivery.
   - Requiere que se haya habilitado un mecanismo de despacho (en MVP puede ser “se marca como en camino” sin courier).
5. `OUT_FOR_DELIVERY -> DELIVERED`
   - Requiere confirmación operativa (podrá ser manual al inicio) + registro de timestamp.
6. `READY_FOR_PICKUP -> PICKED_UP`
   - Puede ser confirmación por cliente en app o por cocinero con reglas anti-abuso.

## Consistencia y prevención de sobreventa
### Estrategia
La sobreventa se evita en la fase 2 del flujo de creación:
1. Obtener `meal_publications` por ID y verificar:
   - vigencia de la publicación,
   - `stock_available >= qty`.
2. Ejecutar una reserva **atómica** sobre la fila:
   - opción A (preferida): `UPDATE ... SET stock_available = stock_available - :qty WHERE stock_available >= :qty`.
   - opción B: `SELECT ... FOR UPDATE` dentro de una transacción.
3. Si no hay stock suficiente → error `SOLD_OUT`/`OUT_OF_CUPOS`.

### Invariantes (para QA)
- Si `orders.status` se mueve a un estado “confirmable”, debe existir una reserva válida del stock en `meal_publications`.
- `orders.total_cop` y el `unit_price_cop` deben coincidir con el precio snapshot de `meal_publications` al momento de creación.

## Idempotencia (antiduplicados)
### En creación de pedido
El endpoint `POST /orders` debe aceptar `Idempotency-Key`.

Regla:
- Si se repite la misma clave (por mismo usuario y acción), el backend retorna la respuesta anterior.
- Esto cubre reintentos de app móvil y retries del cliente.

### Al grabar eventos/timeline
La transición de estado genera `order_status_events`:
- debe ser idempotente también a nivel de operación de “update status” (ej. evitando crear doble evento por reintento).

## Transacciones (patrón)
Para `createOrder`, se recomienda:
- Transacción única que:
  1) valide publicación,
  2) reserve stock,
  3) cree `orders`,
  4) cree `order_items`,
  5) cree `payments` (o payment placeholder),
  6) registre “pending outbox event”.

## Interacción con tracking en tiempo real
La emisión realtime:
- no ocurre directamente en la transacción de DB,
- se hace mediante outbox + worker para no perder eventos si el proceso muere.

## Eventos de dominio (contratos internos)
Eventos recomendados:
- `OrderCreated`
  - `{ orderId, customerId, cookProfileId, fulfillmentType, status, eta }`
- `OrderStatusChanged`
  - `{ orderId, fromStatus, toStatus, occurredAt, actorUserId }`
- `PaymentStatusChanged`
  - `{ orderId, paymentStatus, providerRef }`

## Endpoints (referencia de dominio)
Aunque el contrato REST se define en `api`, el dominio requiere:
- `createOrder` (cliente)
- `confirmOrder` (cocinero)
- `updateOrderStatus` (cocinero/plataforma/admin)
- `cancelOrder` (cliente/cocinero/admin)
- `markDelivered/PickedUp` (según reglas)

---
Fin del documento.

