import { PaymentProvider, ProviderCreateResult } from "./payment-provider.interface";
import { PaymentMethod, PaymentStatus } from "../types";

/**
 * Adapter Daviplata (placeholder).
 */
export class DaviplataProvider implements PaymentProvider {
  method: PaymentMethod = "DAVIPLATA";

  async createPaymentIntent(input: {
    orderId: string;
    amountCop: number;
    metadata?: Record<string, unknown>;
  }): Promise<ProviderCreateResult> {
    return {
      providerRef: `daviplata_${input.orderId}`,
      redirectUrl: undefined,
      providerMetadata: { provider: "daviplata" },
    };
  }

  async verifyWebhookSignature(args: {
    headers: Record<string, string>;
    rawBody: string;
  }): Promise<void> {
    void args;
    // TODO: implementar verificación de firma / token.
  }

  async parseWebhookEvent(_rawPayload: unknown): Promise<{
    providerRef: string;
    status: PaymentStatus;
    providerMetadata?: Record<string, unknown>;
  }> {
    return {
      providerRef: "daviplata_provider_ref",
      status: "PAID",
      providerMetadata: { provider: "daviplata" },
    };
  }
}

