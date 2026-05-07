export const OrdersSocketEvents = {
  ORDER_SUBSCRIBE: "order:subscribe",
  ORDER_SUBSCRIBED: "order:subscribed",
  ORDER_SYNC: "order:sync",
  ORDER_STATUS_UPDATED: "order.status.updated",
  ORDER_ETA_UPDATED: "order.eta.updated",
} as const;

export type OrderStatusUpdatedPayload = {
  orderId: string;
  status: string;
  fromStatus?: string;
  toStatus?: string;
  actorUserId?: string;
  occurredAt: string; // ISO
};

export type OrderEtaUpdatedPayload = {
  orderId: string;
  etaMinutes?: number;
  updatedAt: string; // ISO
};

