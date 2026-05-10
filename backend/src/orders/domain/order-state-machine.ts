import { OrderStatus } from "./order-status";

export type OrderAction =
  | "CONFIRM"
  | "START_PREPARING"
  | "MARK_READY_PICKUP"
  | "MARK_READY_DISPATCH"
  | "MARK_OUT_FOR_DELIVERY"
  | "MARK_DELIVERED"
  | "MARK_PICKED_UP"
  | "CANCEL_BY_CLIENT"
  | "CANCEL_BY_COOK"
  | "CANCEL_BY_ADMIN";

export interface TransitionResult {
  from: OrderStatus;
  to: OrderStatus;
  action: OrderAction;
}

/**
 * State machine determinista: define transiciones válidas y ayuda a evitar
 * updates arbitrarios de `orders.status`.
 *
 * La capa Service debe además aplicar validaciones de negocio (ventanas, cobertura, etc.).
 */
export class OrderStateMachine {
  static getTransition(from: OrderStatus, action: OrderAction): OrderStatus {
    const t = this.transitions.get(from)?.get(action);
    if (!t) throw new Error(`Invalid transition: ${from} + ${action}`);
    return t;
  }

  static canTransition(from: OrderStatus, action: OrderAction): boolean {
    return Boolean(this.transitions.get(from)?.has(action));
  }

  static validateTransition(from: OrderStatus, to: OrderStatus, action: OrderAction) {
    const expected = this.getTransition(from, action);
    if (expected !== to) {
      throw new Error(`Transition mismatch: expected ${expected} but got ${to}`);
    }
  }

  static transitions: Map<OrderStatus, Map<OrderAction, OrderStatus>> = new Map([
    [
      OrderStatus.INIT,
      new Map<OrderAction, OrderStatus>([
        ["CONFIRM", OrderStatus.CONFIRMED],
        ["CANCEL_BY_CLIENT", OrderStatus.CANCELLED_BY_CLIENT],
        ["CANCEL_BY_COOK", OrderStatus.CANCELLED_BY_COOK],
        ["CANCEL_BY_ADMIN", OrderStatus.CANCELLED_BY_ADMIN],
      ]),
    ],
    [
      OrderStatus.CONFIRMED,
      new Map<OrderAction, OrderStatus>([
        ["START_PREPARING", OrderStatus.PREPARING],
        ["CANCEL_BY_CLIENT", OrderStatus.CANCELLED_BY_CLIENT],
        ["CANCEL_BY_ADMIN", OrderStatus.CANCELLED_BY_ADMIN],
        ["CANCEL_BY_COOK", OrderStatus.CANCELLED_BY_COOK],
      ]),
    ],
    [
      OrderStatus.PREPARING,
      new Map<OrderAction, OrderStatus>([
        ["MARK_READY_PICKUP", OrderStatus.READY_FOR_PICKUP],
        ["MARK_READY_DISPATCH", OrderStatus.READY_FOR_DISPATCH],
        ["CANCEL_BY_ADMIN", OrderStatus.CANCELLED_BY_ADMIN],
        ["CANCEL_BY_COOK", OrderStatus.CANCELLED_BY_COOK],
      ]),
    ],
    [
      OrderStatus.READY_FOR_PICKUP,
      new Map<OrderAction, OrderStatus>([
        ["MARK_PICKED_UP", OrderStatus.PICKED_UP],
        ["CANCEL_BY_ADMIN", OrderStatus.CANCELLED_BY_ADMIN],
      ]),
    ],
    [
      OrderStatus.READY_FOR_DISPATCH,
      new Map<OrderAction, OrderStatus>([
        ["MARK_OUT_FOR_DELIVERY", OrderStatus.OUT_FOR_DELIVERY],
        ["CANCEL_BY_ADMIN", OrderStatus.CANCELLED_BY_ADMIN],
      ]),
    ],
    [
      OrderStatus.OUT_FOR_DELIVERY,
      new Map<OrderAction, OrderStatus>([
        ["MARK_DELIVERED", OrderStatus.DELIVERED],
        ["CANCEL_BY_ADMIN", OrderStatus.CANCELLED_BY_ADMIN],
      ]),
    ],
    // Terminal states: no transitions excepto refund/admin governance (se maneja como acción separada)
    [
      OrderStatus.DELIVERED,
      new Map<OrderAction, OrderStatus>([["CANCEL_BY_ADMIN", OrderStatus.REFUNDED]]),
    ],
    [
      OrderStatus.PICKED_UP,
      new Map<OrderAction, OrderStatus>([["CANCEL_BY_ADMIN", OrderStatus.REFUNDED]]),
    ],
  ]);
}

