import { Body, Controller, Get, Patch, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { CookService } from "./cook.service";
import { UpdateCookProfileDto } from "./cook.dto";

@ApiTags("cook")
@Controller("cook")
export class CookController {
  constructor(private readonly cooks: CookService) {}

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Get cook profile (MVP)" })
  @ApiResponse({ status: 200 })
  @Get("profile")
  getProfile(@CurrentUserDecorator() user: { userId: string }) {
    return this.cooks.getProfile(user.userId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Update cook profile (MVP)" })
  @ApiBody({ type: UpdateCookProfileDto })
  @ApiResponse({ status: 200 })
  @Patch("profile")
  updateProfile(@CurrentUserDecorator() user: { userId: string }, @Body() dto: UpdateCookProfileDto) {
    return this.cooks.updateProfile(user.userId, dto);
  }
}

