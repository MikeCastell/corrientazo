import { Module } from "@nestjs/common";

import { MealsController } from "./meals.controller";
import { CookMealsController } from "./cook-meals.controller";
import { MealPublicationsController } from "./meal-publications.controller";
import { MealsService } from "./meals.service";

@Module({
  controllers: [MealsController, CookMealsController, MealPublicationsController],
  providers: [MealsService],
  exports: [MealsService],
})
export class MealsModule {}

