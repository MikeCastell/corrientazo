---
title: "CORRIENTAZO — Payments Module (Adapters + Webhooks + Reconciliation)"
version: "1.0"
last_updated: "2026-05-07"
---

## Objetivo
Proveer un módulo de pagos preparado para:
- **Nequi**
- **Daviplata**
- **Futuras pasarelas** (tarjeta/otros) sin reescribir el core.

Requisitos de producción:
- idempotencia para webhooks,
- reintentos y reconciliación,
- consistencia con el estado del pedido y timeline,
- observabilidad (métricas y logs por attempt).

## Diseño por adapters
El core no conoce detalles de cada proveedor; se integra vía un contrato `PaymentProvider`.

### Interface (conceptual)
- `createPaymentIntent(orderId, amount, method, metadata)`
- `verifyWebhookSignature(headers, rawBody)`
- `parseWebhookEvent(rawPayload)` → mapea a estados internos
- `normalizePaymentReference(...)` → `providerRef`

### Implementaciones
- `NequiProvider`
- `DaviplataProvider`
- `CashProvider` (para efectivo como flujo interno, sin webhooks externos)

## Modelo de datos (Prisma) usado
Usa las entidades:
- `payments` (1 por orden en MVP)
- `payment_attempts` (cada intento contra proveedor)
- `payment_webhooks` (idempotencia por `provider_name + provider_ref`)

Regla:
- `payments.status` refleja el estado agregado.
- `payment_attempts.status` refleja el intento individual.

## Flujo de “iniciar pago”
1. Cliente crea orden y selecciona método.
2. `POST /payments/start` (o se inicia dentro de `POST /orders`) crea:
   - `payment` (estado `PENDING`)
   - `payment_attempt` (estado `PENDING`)
3. Se llama al adapter:
   - para métodos tipo Nequi/Daviplata, el adapter genera una acción:
     - redirect,
     - link de pago,
     - o payload para iniciar cobranza (según provider).
4. Se devuelve al cliente un “resultado” (URL o metadata) con:
   - `paymentId`
   - `paymentAttemptId`
   - `providerRef` (si aplica para rastreo)

## Webhooks: idempotencia + consistencia
1. El provider llama `POST /payments/webhooks/:provider`.
2. El endpoint:
   - valida firma (`verifyWebhookSignature`),
   - parsea evento y normaliza a `PaymentStatus`,
   - extrae `providerRef`.
3. Se guarda el webhook:
   - `payment_webhooks` con `payment_attempt_id` y `provider_ref`.
   - `@@unique([provider_name, provider_ref])` impide duplicados.
4. Si el webhook ya fue procesado:
   - se responde `200` (idempotencia),
   - no se re-aplica estado.
5. Si es un evento nuevo:
   - se actualiza `payment_attempts.status` y `payments.status`,
   - se crea transición de pedido/timeline si aplica (ej. permitir confirmar si pago se requiere).

## Reconciliación (resiliencia)
Problema real:
- algunos webhooks llegan tarde o se pierden.

Solución:
Se ejecuta un worker programado:
1. Busca `payment_attempts` en estado no terminal (PENDING/FAILED temporal).
2. Llama al provider (adapter) para consulta de estado.
3. Aplica cambios solo si el estado cambió.
4. Registra eventos y actualiza timeline.

## Estados y reglas de negocio
PaymentStatus (interno):
- `PENDING` → inicial / aún no confirmado
- `PAID` → confirmación final
- `FAILED` → no aprobado / fallido definitivo
- `REFUNDED` → reembolso confirmado

Reglas recomendadas con orders:
- Si el método es efectivo:
  - `payments.status` puede vivir en `PENDING_CASH` en una futura iteración.
  - En MVP: el estado se considera “pagado” cuando el cocinero/admin confirma entrega (política interna).
- Si método es transferencias (Nequi/Daviplata):
  - el pedido solo avanza a estados de cumplimiento una vez `PAID` (o política de “confirmación por cocinero” si así lo decides).

## Observabilidad (producción)
Para cada payment attempt se registra:
- `provider_name`
- `provider_ref`
- correlación:
  - `x-correlation-id`
- timestamps:
  - request start
  - webhook received
  - payment reconciled

Métricas sugeridas:
- `payment_attempts_total` por provider y estado
- `webhook_processing_latency_seconds`
- `webhook_dedup_rate`

---
Fin del documento.

