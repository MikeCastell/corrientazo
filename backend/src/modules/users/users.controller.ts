import { Controller, Get, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { UsersService } from "./users.service";

@Controller("users")
@ApiTags("users")
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Get current user profile" })
  @ApiResponse({
    status: 200,
    schema: {
      example: {
        id: "<uuid>",
        phone: "+573001234567",
        email: null,
        name: "Juan Pérez",
        role: "CUSTOMER",
        status: "ACTIVE",
        created_at: "2026-05-07T00:00:00.000Z",
      },
    },
  })
  @Get("me")
  me(@CurrentUserDecorator() user: { userId: string }) {
    return this.users.getMe(user.userId);
  }
}

