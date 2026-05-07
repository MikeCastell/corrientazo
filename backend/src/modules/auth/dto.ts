import { IsIn, IsOptional, IsString, MinLength } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class RegisterDto {
  @ApiProperty({ example: "+573001234567" })
  @IsString()
  phone!: string;

  @ApiProperty({ example: "ChangeMe123!" })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiPropertyOptional({ example: "Juan Pérez" })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: "CUSTOMER", enum: ["CUSTOMER", "COOK"] })
  @IsOptional()
  @IsIn(["CUSTOMER", "COOK"])
  role?: "CUSTOMER" | "COOK";
}

export class LoginDto {
  @ApiProperty({ example: "+573001234567" })
  @IsString()
  phone!: string;

  @ApiProperty({ example: "ChangeMe123!" })
  @IsString()
  password!: string;
}

export class RefreshDto {
  @ApiProperty({ example: "b3b1f5b2-2f7a-4a6a-9b5a-8e2f9e6a3b11" })
  @IsString()
  refreshToken!: string;
}

