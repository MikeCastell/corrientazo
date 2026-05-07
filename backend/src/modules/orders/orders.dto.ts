import { IsIn, IsInt, IsOptional, IsString, Min } from "class-validator";
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

