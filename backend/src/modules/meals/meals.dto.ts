import { IsArray, IsBoolean, IsInt, IsOptional, IsString, Min } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateMealDto {
  @ApiProperty({ example: "Corrientazo ejecutivo" })
  @IsString()
  title!: string;

  @ApiPropertyOptional({ example: "Incluye sopa, seco, jugo." })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 12000 })
  @IsInt()
  @Min(0)
  basePriceCop!: number;

  @ApiPropertyOptional({ example: "https://cdn.example.com/meals/1.jpg" })
  @IsOptional()
  @IsString()
  photoUrl?: string;

  @ApiProperty({ example: ["Casero", "Almuerzo"] })
  @IsArray()
  tags!: string[];
}

export class PublishMealDto {
  @ApiProperty({ example: 14000 })
  @IsInt()
  @Min(0)
  priceCop!: number;

  @ApiProperty({ example: 30 })
  @IsInt()
  @Min(1)
  stockTotal!: number;

  @ApiProperty({ example: "2026-05-07T10:00:00.000Z" })
  @IsString()
  availableFrom!: string; // ISO

  @ApiProperty({ example: "2026-05-07T14:00:00.000Z" })
  @IsString()
  availableTo!: string; // ISO

  @ApiProperty({ example: "2026-05-07T12:00:00.000Z" })
  @IsString()
  pickupFrom!: string; // ISO

  @ApiProperty({ example: "2026-05-07T14:30:00.000Z" })
  @IsString()
  pickupTo!: string; // ISO

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  deliveryEnabled?: boolean;

  @ApiPropertyOptional({ example: null })
  @IsOptional()
  @IsString()
  deliveryZoneId?: string;
}

