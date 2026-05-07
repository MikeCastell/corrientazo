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

