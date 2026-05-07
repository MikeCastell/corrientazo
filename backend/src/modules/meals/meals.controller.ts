import { Body, Controller, Get, Param, Post, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { CreateMealDto, PublishMealDto } from "./meals.dto";
import { MealsService } from "./meals.service";

@ApiTags("meals")
@Controller("meals")
export class MealsController {
  constructor(private readonly meals: MealsService) {}

  @Get()
  @ApiOperation({ summary: "List published meal offers (foundation)" })
  @ApiResponse({ status: 200 })
  listPublished() {
    return this.meals.listPublished();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Create meal template (cook)" })
  @ApiBody({ type: CreateMealDto })
  @Post()
  createMeal(
    @CurrentUserDecorator() user: { userId: string },
    @Body() dto: CreateMealDto
  ) {
    return this.meals.createMealTemplate(user.userId, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Publish meal template as offer window (cook)" })
  @ApiBody({ type: PublishMealDto })
  @Post(":mealId/publish")
  publish(
    @CurrentUserDecorator() user: { userId: string },
    @Param("mealId") mealId: string,
    @Body() dto: PublishMealDto
  ) {
    return this.meals.publishMeal(user.userId, mealId, dto);
  }
}

