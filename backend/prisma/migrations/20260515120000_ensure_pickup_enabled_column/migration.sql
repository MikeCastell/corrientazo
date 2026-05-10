-- Idempotente: corrige DBs que no aplicaron 20260510120000_meal_publication_pickup_enabled
ALTER TABLE "meal_publications" ADD COLUMN IF NOT EXISTS "pickup_enabled" BOOLEAN NOT NULL DEFAULT true;
