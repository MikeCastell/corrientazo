import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsBoolean, IsOptional, IsString } from "class-validator";

export class UpdateCookProfileDto {
  @ApiPropertyOptional({ example: "Cocina La Esquina" })
  @IsOptional()
  @IsString()
  businessName?: string;

  @ApiPropertyOptional({ example: "Corrientazos caseros, porción generosa, sazón de barrio." })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({ example: "<address_uuid>" })
  @IsOptional()
  @IsString()
  kitchenAddressId?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  pickupEnabled?: boolean;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  deliveryEnabled?: boolean;

  @ApiPropertyOptional({
    example: "{\"openDays\":[1,2,3,4,5],\"pickupWindow\":{\"from\":\"11:00\",\"to\":\"15:00\"}}",
  })
  @IsOptional()
  operationalPolicyJson?: unknown;
}

