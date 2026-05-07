/**
 * Reconciliación para pagos (resiliencia).
 *
 * Se ejecuta via job (BullMQ) para cubrir:
 * - webhooks tardíos,
 * - reintentos que fallaron,
 * - estados inconsistentes.
 *
 * Algoritmo propuesto:
 * 1) buscar payment_attempts no terminal (PENDING/FAILED_temporal)
 * 2) preguntar al provider por estado (adapter)
 * 3) si cambió:
 *    - aplicar update en DB con idempotencia,
 *    - registrar eventos en timeline/outbox
 * 4) si no cambió:
 *    - reprogramar retry/backoff
 */
export class PaymentsReconciliationService {
  async reconcileOnce() {
    // TODO: integrar con Prisma y adapters.
  }
}

