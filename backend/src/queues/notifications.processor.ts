/**
 * Processor BullMQ para enviar notificaciones push.
 *
 * Responsabilidades:
 * - recibir job con notificationId
 * - cargar notificación y sus dispositivos (futuro)
 * - enviar vía PushProvider (FCM/APNS)
 * - marcar resultado y aplicar retry policy
 *
 * Nota: el soporte de dispositivos/token se agrega en una fase posterior
 * con un modelo `user_devices` (no incluido en el schema actual).
 */
export class NotificationsSendProcessor {
  async process(job: {
    id: string;
    data: { notificationId: string; userId: string; correlationId?: string };
  }): Promise<void> {
    // TODO:
    // 1) idempotencia: verificar si el job ya fue procesado
    // 2) cargar notification en DB
    // 3) enviar push (cuando existan tokens)
    // 4) registrar resultados (logs + posible tabla push_status)
    void job;
  }
}

