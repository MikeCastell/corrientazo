/**
 * Servicio de procesamiento de webhooks (Nequi/Daviplata).
 *
 * Responsabilidades:
 * - validar firma del proveedor,
 * - parsear evento a estado interno,
 * - aplicar idempotencia por (provider_name, provider_ref),
 * - actualizar payment_attempts y payments,
 * - registrar timeline y eventos de dominio via outbox.
 *
 * Nota: el wiring exacto con Prisma/BullMQ se implementa en el módulo payments.
 */
export class PaymentWebhookService {
  async processWebhook(args: {
    providerName: string;
    providerRawBody: string;
    headers: Record<string, string>;
    paymentAttemptId?: string;
    rawPayload: unknown;
  }): Promise<{ ok: true }> {
    // 1) verificar firma con el adapter correspondiente
    // 2) parsear a { providerRef, status, providerMetadata }
    // 3) idempotencia:
    //    - intentar insertar en payment_webhooks con unique(provider, ref)
    //    - si ya existe: retornar ok
    // 4) actualizar payment_attempts y payments
    // 5) emitir evento (outbox) para realtime + notificaciones
    void args;
    return { ok: true };
  }
}

