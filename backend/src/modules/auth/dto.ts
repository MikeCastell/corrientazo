import { IsIn, IsOptional, IsString, MinLength } from "class-validator";

export class RegisterDto {
  @IsString()
  phone!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsIn(["CUSTOMER", "COOK"])
  role?: "CUSTOMER" | "COOK";
}

export class LoginDto {
  @IsString()
  phone!: string;

  @IsString()
  password!: string;
}

export class RefreshDto {
  @IsString()
  refreshToken!: string;
}

