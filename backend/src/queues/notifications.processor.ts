import { Processor, WorkerHost } from "@nestjs/bullmq";
import { Job } from "bullmq";

/**
 * Processor mínimo para mantener el worker vivo y validar wiring BullMQ.
 * No implementa push real (fase futura).
 */
@Processor("notifications.send")
export class NotificationsSendProcessor extends WorkerHost {
  async process(
    job: Job<{ notificationId: string; userId: string; correlationId?: string }>
  ): Promise<void> {
    // Wiring-only: el objetivo es que el worker permanezca vivo y procese jobs.
    // eslint-disable-next-line no-console
    console.log("[worker] notifications.send job received", {
      jobId: job.id,
      notificationId: job.data.notificationId,
      userId: job.data.userId,
      correlationId: job.data.correlationId,
    });
  }
}

