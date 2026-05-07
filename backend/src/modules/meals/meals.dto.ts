import { IsArray, IsBoolean, IsInt, IsOptional, IsString, Min } from "class-validator";

export class CreateMealDto {
  @IsString()
  title!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsInt()
  @Min(0)
  basePriceCop!: number;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsArray()
  tags!: string[];
}

export class PublishMealDto {
  @IsInt()
  @Min(0)
  priceCop!: number;

  @IsInt()
  @Min(1)
  stockTotal!: number;

  @IsString()
  availableFrom!: string; // ISO

  @IsString()
  availableTo!: string; // ISO

  @IsString()
  pickupFrom!: string; // ISO

  @IsString()
  pickupTo!: string; // ISO

  @IsOptional()
  @IsBoolean()
  deliveryEnabled?: boolean;

  @IsOptional()
  @IsString()
  deliveryZoneId?: string;
}

