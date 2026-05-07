import { Body, Controller, Get, Param, Patch, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { MealsService } from "./meals.service";
import { UpdateMealPublicationDto } from "./meals.dto";

@ApiTags("meal_publications")
@Controller("meal-publications")
export class MealPublicationsController {
  constructor(private readonly meals: MealsService) {}

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "List cook meal publications (cook)" })
  @ApiResponse({ status: 200 })
  @Get("/cook")
  listCookPublications(@CurrentUserDecorator() user: { userId: string }) {
    return this.meals.listCookPublications(user.userId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Update meal publication operational fields (cook)" })
  @ApiBody({ type: UpdateMealPublicationDto })
  @ApiResponse({ status: 200 })
  @Patch(":publicationId")
  update(
    @CurrentUserDecorator() user: { userId: string },
    @Param("publicationId") publicationId: string,
    @Body() dto: UpdateMealPublicationDto
  ) {
    return this.meals.updatePublication(user.userId, publicationId, dto);
  }
}

