/** Shapes returned by Prisma selects in OrdersService (no GetPayload — Prisma 6 compat). */

export interface OrderStatusEventRow {
  from_status: string | null;
  to_status: string;
  occurred_at: Date;
  actor_user_id: string | null;
}

export interface OrderByIdRow {
  id: string;
  customer_id: string;
  cook_profile_id: string;
  meal_publication_id: string;
  fulfillment_type: string;
  quantity: number;
  status: string;
  created_at: Date;
  total_cop: number;
  notes: string | null;
  cancel_reason: string | null;
  order_status_events: OrderStatusEventRow[];
  customer: {
    name: string | null;
    phone: string;
    avatar_url: string | null;
  };
  meal_publication: {
    id: string;
    stock_available: number;
    status: string;
    photo_url: string | null;
    title_override: string | null;
    meal: {
      title: string;
      photo_url: string | null;
    };
    cook_profile: {
      bio: string | null;
      user: {
        name: string | null;
        avatar_url: string | null;
        phone: string;
      };
    };
  } | null;
}

export interface CookOrderListRow {
  id: string;
  status: string;
  created_at: Date;
  updated_at: Date;
  total_cop: number;
  quantity: number;
  fulfillment_type: string;
  meal_publication_id: string;
  customer: {
    name: string | null;
    phone: string;
    avatar_url: string | null;
  };
  meal_publication: {
    id: string;
    photo_url: string | null;
    title_override: string | null;
    meal: {
      title: string;
      photo_url: string | null;
    };
  };
}

export interface CustomerOrderListRow {
  id: string;
  status: string;
  created_at: Date;
  total_cop: number;
  quantity: number;
  fulfillment_type: string;
  meal_publication_id: string;
  cook_profile_id: string;
  meal_publication: {
    id: string;
    photo_url: string | null;
    title_override: string | null;
    meal: {
      title: string;
      photo_url: string | null;
    };
  };
}

export type MealPublicationStockRow = {
  stock_available: number;
};
