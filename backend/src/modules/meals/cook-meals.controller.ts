import { Controller, Delete, Get, Param, Patch, UseGuards, Body } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { MealsService } from "./meals.service";
import { UpdateMealDto } from "./meals.dto";

@ApiTags("cook")
@Controller("cook/meals")
export class CookMealsController {
  constructor(private readonly meals: MealsService) {}

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "List cook meal templates (cook)" })
  @ApiResponse({ status: 200 })
  @Get()
  listMine(@CurrentUserDecorator() user: { userId: string }) {
    return this.meals.listCookMeals(user.userId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Update meal template (cook)" })
  @ApiBody({ type: UpdateMealDto })
  @ApiResponse({ status: 200 })
  @Patch(":mealId")
  update(
    @CurrentUserDecorator() user: { userId: string },
    @Param("mealId") mealId: string,
    @Body() dto: UpdateMealDto
  ) {
    return this.meals.updateMealTemplate(user.userId, mealId, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Delete meal template (cook)" })
  @ApiResponse({ status: 200 })
  @Delete(":mealId")
  remove(@CurrentUserDecorator() user: { userId: string }, @Param("mealId") mealId: string) {
    return this.meals.deleteMealTemplate(user.userId, mealId);
  }
}

