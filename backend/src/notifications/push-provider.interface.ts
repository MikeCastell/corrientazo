export interface PushProvider {
  /**
   * Envía notificación a un dispositivo/token.
   * En producción: distinguir FCM/APNS con payloads nativos.
   */
  send(args: {
    deviceToken: string;
    title: string;
    body?: string;
    data?: Record<string, unknown>;
  }): Promise<{ ok: true }>;
}

