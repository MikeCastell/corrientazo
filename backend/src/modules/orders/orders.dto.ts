import { IsIn, IsInt, IsNotEmpty, IsOptional, IsString, MaxLength, Min } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateOrderDto {
  @ApiProperty({ example: "<meal_publication_uuid>" })
  @IsString()
  mealPublicationId!: string;

  @ApiProperty({ example: 1 })
  @IsInt()
  @Min(1)
  quantity!: number;

  @ApiProperty({ example: "PICKUP", enum: ["PICKUP", "DELIVERY"] })
  @IsIn(["PICKUP", "DELIVERY"])
  fulfillmentType!: "PICKUP" | "DELIVERY";

  @ApiPropertyOptional({ example: "<address_uuid>" })
  @IsOptional()
  @IsString()
  deliveryAddressId?: string;
}

export class UpdateOrderStatusDto {
  @ApiProperty({
    example: "START_PREPARING",
    enum: [
      "CONFIRM",
      "START_PREPARING",
      "MARK_READY_PICKUP",
      "MARK_READY_DISPATCH",
      "MARK_OUT_FOR_DELIVERY",
      "MARK_DELIVERED",
      "MARK_PICKED_UP",
      "CANCEL_BY_CLIENT",
      "CANCEL_BY_COOK",
      "CANCEL_BY_ADMIN",
    ],
  })
  @IsString()
  action!:
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
}

/** Razones predefinidas cuando el cook cancela (MVP). */
export const CookCancelReasonCodes = [
  "NO_INGREDIENTS",
  "KITCHEN_ISSUE",
  "CANNOT_PREPARE",
  "UNEXPECTED_CLOSE",
  "OTHER",
] as const;

export type CookCancelReasonCode = (typeof CookCancelReasonCodes)[number];

export class CancelOrderDto {
  @ApiPropertyOptional({
    enum: CookCancelReasonCodes,
    description: "Solo aplica si cancela el cook; ignorado para clientes.",
  })
  @IsOptional()
  @IsString()
  @IsIn([...CookCancelReasonCodes])
  reasonCode?: CookCancelReasonCode;

  @ApiPropertyOptional({ example: "Sin pollo hoy en la plaza." })
  @IsOptional()
  @IsString()
  @MaxLength(220)
  note?: string;
}

/** `orderId` en body: evita 404 de proxies con POST …/cancel/<uuid> en la ruta. */
export class CancelOrderBodyDto extends CancelOrderDto {
  @ApiProperty({ example: "<order_uuid>" })
  @IsString()
  @IsNotEmpty()
  orderId!: string;
}

