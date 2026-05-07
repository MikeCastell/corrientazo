import { Controller, Get, UseGuards } from "@nestjs/common";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { UsersService } from "./users.service";

@Controller("users")
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @Get("me")
  me(@CurrentUserDecorator() user: { userId: string }) {
    return this.users.getMe(user.userId);
  }
}

