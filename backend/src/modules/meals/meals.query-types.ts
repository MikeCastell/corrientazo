/** Shapes returned by Prisma selects in MealsService (no GetPayload — Prisma 6 compat). */

export interface ListPublishedRow {
  id: string;
  meal_id: string;
  cook_profile_id: string;
  price_cop: number;
  stock_available: number;
  available_from: Date;
  available_to: Date;
  pickup_from: Date;
  pickup_to: Date;
  delivery_enabled: boolean;
  pickup_enabled: boolean;
  photo_url: string | null;
  title_override: string | null;
  description_override: string | null;
  meal: {
    title: string;
    description: string | null;
    photo_url: string | null;
    tags: string[];
  } | null;
  cook_profile: {
    bio: string | null;
    user: {
      name: string | null;
      avatar_url: string | null;
    };
  };
}

export interface PublicationIdRow {
  id: string;
}
