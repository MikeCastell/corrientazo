import { PaymentProvider, ProviderCreateResult } from "./payment-provider.interface";
import { PaymentMethod, PaymentStatus } from "../types";

/**
 * Adapter Nequi (placeholder).
 *
 * En producción:
 * - se usan credenciales y endpoints del proveedor,
 * - se valida la firma del webhook (o el esquema de autenticación),
 * - se normaliza el payload a PaymentStatus interno.
 */
export class NequiProvider implements PaymentProvider {
  method: PaymentMethod = "NEQUI";

  async createPaymentIntent(input: {
    orderId: string;
    amountCop: number;
    metadata?: Record<string, unknown>;
  }): Promise<ProviderCreateResult> {
    // TODO: integrar con la API de Nequi.
    return {
      providerRef: `nequi_${input.orderId}`,
      providerMetadata: { provider: "nequi" },
    };
  }

  async verifyWebhookSignature(args: {
    headers: Record<string, string>;
    rawBody: string;
  }): Promise<void> {
    // TODO: implementar verificación de firma.
    void args;
  }

  async parseWebhookEvent(_rawPayload: unknown): Promise<{
    providerRef: string;
    status: PaymentStatus;
    providerMetadata?: Record<string, unknown>;
  }> {
    // TODO: mapear el payload real de Nequi.
    return {
      providerRef: "nequi_provider_ref",
      status: "PAID",
      providerMetadata: { provider: "nequi" },
    };
  }
}

