-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'CUSTOMER', 'COOK');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'SUSPENDED', 'DELETED');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('INIT', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'READY_FOR_DISPATCH', 'OUT_FOR_DELIVERY', 'DELIVERED', 'PICKED_UP', 'CANCELLED_BY_CLIENT', 'CANCELLED_BY_COOK', 'CANCELLED_BY_ADMIN', 'REFUNDED');

-- CreateEnum
CREATE TYPE "FulfillmentType" AS ENUM ('PICKUP', 'DELIVERY');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('CASH', 'NEQUI', 'DAVIPLATA', 'FUTURE_GATEWAY');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "SanitaryCheckStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "SanitaryReportType" AS ENUM ('HYGIENE', 'LATE', 'FRAUD', 'WRONG_ITEM', 'MISSING_ITEM', 'SPOILED', 'OTHER');

-- CreateEnum
CREATE TYPE "SanitaryReportStatus" AS ENUM ('OPEN', 'UNDER_REVIEW', 'RESOLVED');

-- CreateEnum
CREATE TYPE "SuspensionStatus" AS ENUM ('ACTIVE', 'EXPIRED', 'REVOKED');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('ORDER_STATUS', 'ORDER_ETA', 'PAYMENT_STATUS', 'SANITARY_UPDATE', 'PROMO', 'SYSTEM', 'SUPPORT');

-- CreateEnum
CREATE TYPE "OutboxStatus" AS ENUM ('NEW', 'PROCESSING', 'SENT', 'FAILED');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'CUSTOMER',
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "phone" TEXT NOT NULL,
    "email" TEXT,
    "name" TEXT,
    "avatar_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token_hash" TEXT NOT NULL,
    "revoked_at" TIMESTAMP(3),
    "expires_at" TIMESTAMP(3) NOT NULL,
    "rotated_from_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "auth_passwords" (
    "user_id" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "auth_passwords_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "addresses" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "label" TEXT,
    "formatted_address" TEXT,
    "lat" DOUBLE PRECISION NOT NULL,
    "lng" DOUBLE PRECISION NOT NULL,
    "instructions" TEXT,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "addresses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cook_profiles" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "bio" TEXT,
    "kitchen_address_id" TEXT,
    "sanitary_level_id" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT false,
    "delivery_enabled" BOOLEAN NOT NULL DEFAULT false,
    "pickup_enabled" BOOLEAN NOT NULL DEFAULT true,
    "operational_policy_json" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "cook_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "delivery_zones" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "city" TEXT,
    "min_lat" DOUBLE PRECISION NOT NULL,
    "min_lng" DOUBLE PRECISION NOT NULL,
    "max_lat" DOUBLE PRECISION NOT NULL,
    "max_lng" DOUBLE PRECISION NOT NULL,
    "center_lat" DOUBLE PRECISION,
    "center_lng" DOUBLE PRECISION,
    "radius_km" DOUBLE PRECISION,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "delivery_zones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cook_delivery_zones" (
    "id" TEXT NOT NULL,
    "cook_profile_id" TEXT NOT NULL,
    "delivery_zone_id" TEXT NOT NULL,
    "max_delivery_fee_cop" INTEGER,
    "enabled_from" TIMESTAMP(3),
    "enabled_to" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "cook_delivery_zones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "meals" (
    "id" TEXT NOT NULL,
    "cook_profile_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "photo_url" TEXT,
    "base_price_cop" INTEGER NOT NULL,
    "tags" TEXT[],
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "meals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "meal_publications" (
    "id" TEXT NOT NULL,
    "meal_id" TEXT NOT NULL,
    "cook_profile_id" TEXT NOT NULL,
    "title_override" TEXT,
    "description_override" TEXT,
    "price_cop" INTEGER NOT NULL,
    "photo_url" TEXT,
    "available_from" TIMESTAMP(3) NOT NULL,
    "available_to" TIMESTAMP(3) NOT NULL,
    "pickup_from" TIMESTAMP(3) NOT NULL,
    "pickup_to" TIMESTAMP(3) NOT NULL,
    "delivery_enabled" BOOLEAN NOT NULL DEFAULT false,
    "delivery_zone_id" TEXT,
    "stock_total" INTEGER NOT NULL,
    "stock_available" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PUBLISHED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "meal_publications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "orders" (
    "id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "cook_profile_id" TEXT NOT NULL,
    "meal_publication_id" TEXT NOT NULL,
    "fulfillment_type" "FulfillmentType" NOT NULL,
    "delivery_address_id" TEXT,
    "quantity" INTEGER NOT NULL,
    "subtotal_cop" INTEGER NOT NULL,
    "platform_fee_cop" INTEGER NOT NULL,
    "delivery_fee_cop" INTEGER,
    "total_cop" INTEGER NOT NULL,
    "pickup_eta_minutes" INTEGER,
    "delivery_eta_minutes" INTEGER,
    "notes" TEXT,
    "status" "OrderStatus" NOT NULL DEFAULT 'INIT',
    "cancel_reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "meal_publication_id" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "title_snapshot" TEXT NOT NULL,
    "unit_price_cop" INTEGER NOT NULL,
    "subtotal_cop" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_status_events" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "from_status" "OrderStatus",
    "to_status" "OrderStatus" NOT NULL,
    "occurred_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actor_user_id" TEXT,
    "meta_json" JSONB,

    CONSTRAINT "order_status_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "method" "PaymentMethod" NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "amount_cop" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'COP',
    "paid_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment_attempts" (
    "id" TEXT NOT NULL,
    "payment_id" TEXT NOT NULL,
    "method" "PaymentMethod" NOT NULL,
    "status" "PaymentStatus" NOT NULL,
    "provider_name" TEXT NOT NULL,
    "provider_ref" TEXT,
    "idempotency_key" TEXT,
    "attempt_metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payment_attempts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment_webhooks" (
    "id" TEXT NOT NULL,
    "payment_attempt_id" TEXT NOT NULL,
    "provider_name" TEXT NOT NULL,
    "provider_ref" TEXT NOT NULL,
    "raw_payload_json" JSONB,
    "signature_valid" BOOLEAN NOT NULL DEFAULT true,
    "processed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payment_webhooks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reviews" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "cook_profile_id" TEXT NOT NULL,
    "meal_id" TEXT,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "tags" TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reviews_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cook_reputation_snapshots" (
    "id" TEXT NOT NULL,
    "cook_profile_id" TEXT NOT NULL,
    "overall_score" DECIMAL(10,4) NOT NULL,
    "rating_avg" DECIMAL(10,4) NOT NULL,
    "rating_count" INTEGER NOT NULL,
    "hygiene_score" DECIMAL(10,4) NOT NULL,
    "report_count" INTEGER NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "cook_reputation_snapshots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL,
    "title" TEXT,
    "body" TEXT,
    "payload_json" JSONB,
    "order_id" TEXT,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sanitary_levels" (
    "id" TEXT NOT NULL,
    "level_number" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "checklist_json" JSONB NOT NULL,
    "evidence_rules_json" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sanitary_levels_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sanitary_checks" (
    "id" TEXT NOT NULL,
    "cook_profile_id" TEXT NOT NULL,
    "sanitary_level_id" TEXT NOT NULL,
    "status" "SanitaryCheckStatus" NOT NULL DEFAULT 'PENDING',
    "completed_at" TIMESTAMP(3),
    "reviewed_at" TIMESTAMP(3),
    "reviewed_by_admin_id" TEXT,
    "data_json" JSONB,
    "evidence_urls_json" JSONB,
    "checklist_version" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sanitary_checks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reports" (
    "id" TEXT NOT NULL,
    "reporter_user_id" TEXT NOT NULL,
    "cook_profile_id" TEXT NOT NULL,
    "order_id" TEXT,
    "sanitary_check_id" TEXT,
    "type" "SanitaryReportType" NOT NULL,
    "status" "SanitaryReportStatus" NOT NULL DEFAULT 'OPEN',
    "severity" INTEGER NOT NULL DEFAULT 1,
    "description" TEXT,
    "evidence_urls_json" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "resolved_by_admin_id" TEXT,
    "resolved_at" TIMESTAMP(3),

    CONSTRAINT "reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "suspensions" (
    "id" TEXT NOT NULL,
    "cook_profile_id" TEXT NOT NULL,
    "status" "SuspensionStatus" NOT NULL DEFAULT 'ACTIVE',
    "reason_type" "SanitaryReportType",
    "reason_text" TEXT,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ends_at" TIMESTAMP(3),
    "revoked_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "suspensions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "idempotency_keys" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "idempotency_key" TEXT NOT NULL,
    "request_hash" TEXT,
    "response_json" JSONB,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "idempotency_keys_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "domain_event_outbox" (
    "id" TEXT NOT NULL,
    "event_type" TEXT NOT NULL,
    "aggregate_type" TEXT,
    "aggregate_id" TEXT,
    "payload_json" JSONB NOT NULL,
    "status" "OutboxStatus" NOT NULL DEFAULT 'NEW',
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processed_at" TIMESTAMP(3),
    "last_error" TEXT,

    CONSTRAINT "domain_event_outbox_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_role_status_idx" ON "users"("role", "status");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_expires_at_idx" ON "refresh_tokens"("user_id", "expires_at");

-- CreateIndex
CREATE INDEX "addresses_user_id_lat_lng_idx" ON "addresses"("user_id", "lat", "lng");

-- CreateIndex
CREATE UNIQUE INDEX "cook_profiles_user_id_key" ON "cook_profiles"("user_id");

-- CreateIndex
CREATE INDEX "cook_profiles_is_active_delivery_enabled_pickup_enabled_idx" ON "cook_profiles"("is_active", "delivery_enabled", "pickup_enabled");

-- CreateIndex
CREATE INDEX "delivery_zones_is_active_min_lat_max_lat_idx" ON "delivery_zones"("is_active", "min_lat", "max_lat");

-- CreateIndex
CREATE UNIQUE INDEX "delivery_zones_name_city_key" ON "delivery_zones"("name", "city");

-- CreateIndex
CREATE INDEX "cook_delivery_zones_delivery_zone_id_idx" ON "cook_delivery_zones"("delivery_zone_id");

-- CreateIndex
CREATE UNIQUE INDEX "cook_delivery_zones_cook_profile_id_delivery_zone_id_key" ON "cook_delivery_zones"("cook_profile_id", "delivery_zone_id");

-- CreateIndex
CREATE INDEX "meals_cook_profile_id_is_active_idx" ON "meals"("cook_profile_id", "is_active");

-- CreateIndex
CREATE INDEX "meal_publications_cook_profile_id_available_from_available__idx" ON "meal_publications"("cook_profile_id", "available_from", "available_to");

-- CreateIndex
CREATE INDEX "meal_publications_delivery_enabled_delivery_zone_id_pickup__idx" ON "meal_publications"("delivery_enabled", "delivery_zone_id", "pickup_from");

-- CreateIndex
CREATE INDEX "orders_customer_id_created_at_idx" ON "orders"("customer_id", "created_at");

-- CreateIndex
CREATE INDEX "orders_cook_profile_id_status_idx" ON "orders"("cook_profile_id", "status");

-- CreateIndex
CREATE INDEX "orders_meal_publication_id_status_idx" ON "orders"("meal_publication_id", "status");

-- CreateIndex
CREATE INDEX "order_items_meal_publication_id_idx" ON "order_items"("meal_publication_id");

-- CreateIndex
CREATE UNIQUE INDEX "order_items_order_id_meal_publication_id_key" ON "order_items"("order_id", "meal_publication_id");

-- CreateIndex
CREATE INDEX "order_status_events_order_id_occurred_at_idx" ON "order_status_events"("order_id", "occurred_at");

-- CreateIndex
CREATE UNIQUE INDEX "payments_order_id_key" ON "payments"("order_id");

-- CreateIndex
CREATE INDEX "payments_status_method_idx" ON "payments"("status", "method");

-- CreateIndex
CREATE INDEX "payment_attempts_status_provider_name_created_at_idx" ON "payment_attempts"("status", "provider_name", "created_at");

-- CreateIndex
CREATE INDEX "payment_webhooks_processed_at_idx" ON "payment_webhooks"("processed_at");

-- CreateIndex
CREATE UNIQUE INDEX "payment_webhooks_provider_name_provider_ref_key" ON "payment_webhooks"("provider_name", "provider_ref");

-- CreateIndex
CREATE UNIQUE INDEX "reviews_order_id_key" ON "reviews"("order_id");

-- CreateIndex
CREATE INDEX "reviews_cook_profile_id_created_at_idx" ON "reviews"("cook_profile_id", "created_at");

-- CreateIndex
CREATE INDEX "cook_reputation_snapshots_cook_profile_id_updated_at_idx" ON "cook_reputation_snapshots"("cook_profile_id", "updated_at");

-- CreateIndex
CREATE INDEX "notifications_user_id_created_at_idx" ON "notifications"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "notifications_type_created_at_idx" ON "notifications"("type", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "sanitary_levels_level_number_key" ON "sanitary_levels"("level_number");

-- CreateIndex
CREATE INDEX "sanitary_levels_level_number_idx" ON "sanitary_levels"("level_number");

-- CreateIndex
CREATE INDEX "sanitary_checks_cook_profile_id_status_idx" ON "sanitary_checks"("cook_profile_id", "status");

-- CreateIndex
CREATE INDEX "suspensions_cook_profile_id_status_idx" ON "suspensions"("cook_profile_id", "status");

-- CreateIndex
CREATE INDEX "idempotency_keys_expires_at_idx" ON "idempotency_keys"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "idempotency_keys_user_id_action_idempotency_key_key" ON "idempotency_keys"("user_id", "action", "idempotency_key");

-- CreateIndex
CREATE INDEX "domain_event_outbox_status_created_at_idx" ON "domain_event_outbox"("status", "created_at");

-- CreateIndex
CREATE INDEX "domain_event_outbox_aggregate_type_aggregate_id_idx" ON "domain_event_outbox"("aggregate_type", "aggregate_id");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "auth_passwords" ADD CONSTRAINT "auth_passwords_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cook_profiles" ADD CONSTRAINT "cook_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cook_profiles" ADD CONSTRAINT "cook_profiles_sanitary_level_id_fkey" FOREIGN KEY ("sanitary_level_id") REFERENCES "sanitary_levels"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cook_delivery_zones" ADD CONSTRAINT "cook_delivery_zones_cook_profile_id_fkey" FOREIGN KEY ("cook_profile_id") REFERENCES "cook_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cook_delivery_zones" ADD CONSTRAINT "cook_delivery_zones_delivery_zone_id_fkey" FOREIGN KEY ("delivery_zone_id") REFERENCES "delivery_zones"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meals" ADD CONSTRAINT "meals_cook_profile_id_fkey" FOREIGN KEY ("cook_profile_id") REFERENCES "cook_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meal_publications" ADD CONSTRAINT "meal_publications_meal_id_fkey" FOREIGN KEY ("meal_id") REFERENCES "meals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meal_publications" ADD CONSTRAINT "meal_publications_cook_profile_id_fkey" FOREIGN KEY ("cook_profile_id") REFERENCES "cook_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meal_publications" ADD CONSTRAINT "meal_publications_delivery_zone_id_fkey" FOREIGN KEY ("delivery_zone_id") REFERENCES "delivery_zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_cook_profile_id_fkey" FOREIGN KEY ("cook_profile_id") REFERENCES "cook_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_delivery_address_id_fkey" FOREIGN KEY ("delivery_address_id") REFERENCES "addresses"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_meal_publication_id_fkey" FOREIGN KEY ("meal_publication_id") REFERENCES "meal_publications"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_meal_publication_id_fkey" FOREIGN KEY ("meal_publication_id") REFERENCES "meal_publications"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_status_events" ADD CONSTRAINT "order_status_events_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_attempts" ADD CONSTRAINT "payment_attempts_payment_id_fkey" FOREIGN KEY ("payment_id") REFERENCES "payments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_webhooks" ADD CONSTRAINT "payment_webhooks_payment_attempt_id_fkey" FOREIGN KEY ("payment_attempt_id") REFERENCES "payment_attempts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_cook_profile_id_fkey" FOREIGN KEY ("cook_profile_id") REFERENCES "cook_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_meal_id_fkey" FOREIGN KEY ("meal_id") REFERENCES "meals"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cook_reputation_snapshots" ADD CONSTRAINT "cook_reputation_snapshots_cook_profile_id_fkey" FOREIGN KEY ("cook_profile_id") REFERENCES "cook_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sanitary_checks" ADD CONSTRAINT "sanitary_checks_cook_profile_id_fkey" FOREIGN KEY ("cook_profile_id") REFERENCES "cook_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sanitary_checks" ADD CONSTRAINT "sanitary_checks_sanitary_level_id_fkey" FOREIGN KEY ("sanitary_level_id") REFERENCES "sanitary_levels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_cook_profile_id_fkey" FOREIGN KEY ("cook_profile_id") REFERENCES "cook_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_sanitary_check_id_fkey" FOREIGN KEY ("sanitary_check_id") REFERENCES "sanitary_checks"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "suspensions" ADD CONSTRAINT "suspensions_cook_profile_id_fkey" FOREIGN KEY ("cook_profile_id") REFERENCES "cook_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

