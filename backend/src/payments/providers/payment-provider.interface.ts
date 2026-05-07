import { PaymentMethod, PaymentStatus } from "../../types";

export type ProviderCreateResult = {
  providerRef?: string;
  // Link / redirect URL o payload para iniciar el cobro (depende del proveedor)
  redirectUrl?: string;
  providerMetadata?: Record<string, unknown>;
};

export interface PaymentProvider {
  method: PaymentMethod;

  /**
   * Inicia el cobro en el proveedor (o crea el contexto de pago).
   * No actualiza DB: el service llama adapter y luego persiste.
   */
  createPaymentIntent(input: {
    orderId: string;
    amountCop: number;
    metadata?: Record<string, unknown>;
  }): Promise<ProviderCreateResult>;

  /**
   * Valida firma del webhook (si el provider la maneja).
   * Debe lanzar error si la firma es inválida.
   */
  verifyWebhookSignature(args: { headers: Record<string, string>; rawBody: string }): Promise<void>;

  /**
   * Convierte payload del webhook a un estado interno.
   */
  parseWebhookEvent(rawPayload: unknown): Promise<{
    providerRef: string;
    status: PaymentStatus;
    // campos opcionales del provider útiles para auditoria
    providerMetadata?: Record<string, unknown>;
  }>;
}

