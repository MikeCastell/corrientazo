/**
 * Endpoint público para webhooks de proveedores.
 *
 * Reglas de producción:
 * - Se debe configurar Nest para recibir rawBody (no JSON parseado)
 *   para validar firmas.
 * - Debe existir idempotencia por provider+providerRef.
 * - Debe responder 2xx rápido para evitar reintentos excesivos del proveedor.
 */
export class PaymentWebhooksController {
  // TODO: implementar con decorators de NestJS cuando se cree el módulo payments real.
}

