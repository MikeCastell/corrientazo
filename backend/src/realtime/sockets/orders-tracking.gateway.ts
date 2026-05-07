import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from "@nestjs/websockets";
import { Server, Socket } from "socket.io";

import { OrdersSocketEvents } from "../socket-events/orders.events";

/**
 * Tracking en vivo del pedido.
 *
 * Consistencia:
 * - El estado real vive en PostgreSQL.
 * - Socket.io entrega cambios al cliente (best effort) y el cliente puede re-sincronizar con REST.
 *
 * Autenticación:
 * - se recomienda un auth middleware/guard de sockets que valide JWT y setee socket.data.userId.
 */
@WebSocketGateway({
  namespace: "/realtime",
  transports: ["websocket"],
  cors: {
    origin: "*", // restringir en producción con whitelist
  },
})
export class OrdersTrackingGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  async handleConnection(client: Socket) {
    // Recomendado:
    // - en el auth middleware, setear socket.data.userId y/o userRole.
    // - unirse a room global: user:{userId}
    const userId = (client.data as any)?.userId;
    if (userId) {
      client.join(`user:${userId}`);
    }
  }

  async handleDisconnect(_client: Socket) {
    // no-op; el cliente re-suscribe y/o hace order:sync.
  }

  @SubscribeMessage(OrdersSocketEvents.ORDER_SUBSCRIBE)
  async onOrderSubscribe(
    @MessageBody() body: { orderId: string },
    @ConnectedSocket() client: Socket
  ) {
    const userId = (client.data as any)?.userId;
    const { orderId } = body;

    // 1) Validar acceso al pedido:
    // - el user debe ser customer/cook de la orden
    // 2) Join a la room:
    // - order:{orderId}
    // 3) ACK:
    // - order:subscribed
    //
    // Nota: en la implementación real, esta validación llama a OrdersService.
    client.join(`order:${orderId}`);
    client.emit(OrdersSocketEvents.ORDER_SUBSCRIBED, { orderId, ok: true, userId });
  }

  // No se maneja aquí "order:status.updated":
  // Se emite desde el worker/outbox o desde el service tras transacción DB.
}

