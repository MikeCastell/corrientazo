import { Body, Controller, Post } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

import { AuthService } from "./auth.service";
import { LoginDto, RefreshDto, RegisterDto } from "./dto";

@ApiTags("auth")
@Controller("auth")
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @ApiOperation({ summary: "Register a user (foundation)" })
  @ApiBody({ type: RegisterDto })
  @ApiResponse({
    status: 201,
    description: "Token pair issued",
    schema: {
      example: { accessToken: "<jwt>", refreshToken: "<uuid>" },
    },
  })
  @Post("register")
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @ApiOperation({ summary: "Login with phone/password (foundation)" })
  @ApiBody({ type: LoginDto })
  @ApiResponse({
    status: 201,
    description: "Token pair issued",
    schema: {
      example: { accessToken: "<jwt>", refreshToken: "<uuid>" },
    },
  })
  @Post("login")
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @ApiOperation({ summary: "Rotate refresh token and issue new access token" })
  @ApiBody({ type: RefreshDto })
  @ApiResponse({
    status: 201,
    description: "New token pair",
    schema: {
      example: { accessToken: "<jwt>", refreshToken: "<uuid>" },
    },
  })
  @Post("refresh")
  refresh(@Body() dto: RefreshDto) {
    return this.auth.refresh(dto.refreshToken);
  }

  @ApiOperation({ summary: "Revoke refresh token" })
  @ApiBody({ type: RefreshDto })
  @ApiResponse({ status: 201, schema: { example: { ok: true } } })
  @Post("logout")
  logout(@Body() dto: RefreshDto) {
    return this.auth.logout(dto.refreshToken);
  }
}

