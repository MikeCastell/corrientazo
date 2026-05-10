import { Transform } from "class-transformer";
import { IsArray, IsBoolean, IsIn, IsInt, IsOptional, IsString, Min } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

/** Accepts true/false/1/0 from JSON clients that stringify booleans inconsistently. */
function normalizeOptionalBool(value: unknown): boolean | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;
  if (typeof value === "string") {
    const s = value.trim().toLowerCase();
    if (s === "true" || s === "1") return true;
    if (s === "false" || s === "0") return false;
  }
  return Boolean(value);
}

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

export class UpdateMealDto {
  @ApiPropertyOptional({ example: "Corrientazo ejecutivo" })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ example: "Incluye sopa, seco, jugo." })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: 12000 })
  @IsOptional()
  @IsInt()
  @Min(0)
  basePriceCop?: number;

  @ApiPropertyOptional({ example: "http://localhost:3000/uploads/meals/1.jpg" })
  @IsOptional()
  @IsString()
  photoUrl?: string;

  @ApiPropertyOptional({ example: ["Casero", "Almuerzo"] })
  @IsOptional()
  @IsArray()
  tags?: string[];
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
  @Transform(({ value }) => normalizeOptionalBool(value))
  @IsBoolean()
  deliveryEnabled?: boolean;

  @ApiPropertyOptional({ example: true, description: "If false, pickup orders are not allowed (solo domicilio)." })
  @IsOptional()
  @Transform(({ value }) => normalizeOptionalBool(value))
  @IsBoolean()
  pickupEnabled?: boolean;

  @ApiPropertyOptional({ example: null })
  @IsOptional()
  @IsString()
  deliveryZoneId?: string;

  @ApiPropertyOptional({ example: "PAUSED", enum: ["PUBLISHED", "PAUSED"] })
  @IsOptional()
  @IsString()
  @IsIn(["PUBLISHED", "PAUSED"])
  status?: string;
}

export class UpdateMealPublicationDto {
  @ApiPropertyOptional({ example: 15000 })
  @IsOptional()
  @IsInt()
  @Min(0)
  priceCop?: number;

  @ApiPropertyOptional({ example: 25 })
  @IsOptional()
  @IsInt()
  @Min(0)
  stockTotal?: number;

  @ApiPropertyOptional({ example: 18 })
  @IsOptional()
  @IsInt()
  @Min(0)
  stockAvailable?: number;

  @ApiPropertyOptional({ example: "PAUSED" })
  @IsOptional()
  @IsString()
  @IsIn(["PUBLISHED", "PAUSED", "ARCHIVED"])
  status?: string;
}

