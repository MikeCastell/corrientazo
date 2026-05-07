import { IsIn, IsInt, IsOptional, IsString, Min } from "class-validator";

export class CreateOrderDto {
  @IsString()
  mealPublicationId!: string;

  @IsInt()
  @Min(1)
  quantity!: number;

  @IsIn(["PICKUP", "DELIVERY"])
  fulfillmentType!: "PICKUP" | "DELIVERY";

  @IsOptional()
  @IsString()
  deliveryAddressId?: string;
}

