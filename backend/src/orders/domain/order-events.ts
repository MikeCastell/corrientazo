import { OrderStatus } from "./order-status";

export interface OrderCreatedEvent {
  eventType: "order.created";
  orderId: string;
  customerId: string;
  cookProfileId: string;
  fulfillmentType: "PICKUP" | "DELIVERY";
  status: OrderStatus;
  occurredAt: string; // ISO
  eta?: {
    etaMinutes?: number;
    updatedAt?: string;
  };
}

export interface OrderStatusChangedEvent {
  eventType: "order.status.changed";
  orderId: string;
  fromStatus: OrderStatus;
  toStatus: OrderStatus;
  actorUserId?: string;
  occurredAt: string; // ISO
}

export interface OrderEtaUpdatedEvent {
  eventType: "order.eta.updated";
  orderId: string;
  etaMinutes?: number;
  updatedAt: string; // ISO
}

