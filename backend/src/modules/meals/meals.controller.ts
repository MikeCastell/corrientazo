import { Body, Controller, Get, Param, Post, UseGuards } from "@nestjs/common";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { CreateMealDto, PublishMealDto } from "./meals.dto";
import { MealsService } from "./meals.service";

@Controller("meals")
export class MealsController {
  constructor(private readonly meals: MealsService) {}

  @Get()
  listPublished() {
    return this.meals.listPublished();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @Post()
  createMeal(
    @CurrentUserDecorator() user: { userId: string },
    @Body() dto: CreateMealDto
  ) {
    return this.meals.createMealTemplate(user.userId, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @Post(":mealId/publish")
  publish(
    @CurrentUserDecorator() user: { userId: string },
    @Param("mealId") mealId: string,
    @Body() dto: PublishMealDto
  ) {
    return this.meals.publishMeal(user.userId, mealId, dto);
  }
}

