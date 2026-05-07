/**
 * Servicio de notificaciones:
 * - crea historial en DB
 * - encola jobs push (BullMQ) o emite realtime via outbox.
 *
 * El wiring exacto con Prisma/BullMQ se implementa al conectar el módulo
 * `notifications` y `queues`.
 */
export class NotificationsService {
  async createNotification(args: {
    userId: string;
    type: string;
    title?: string;
    body?: string;
    payload?: unknown;
    correlationId?: string;
    orderId?: string;
  }): Promise<{ notificationId: string }> {
    // 1) insertar en `notifications`
    // 2) registrar outbox event (ideal) o enviar a queue directamente
    // 3) retorno con notificationId
    void args;
    return { notificationId: "notification_id_stub" };
  }

  async markAsRead(args: { userId: string; notificationId: string }): Promise<void> {
    void args;
  }
}

