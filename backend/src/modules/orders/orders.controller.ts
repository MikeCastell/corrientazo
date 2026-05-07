import { Body, Controller, Get, Param, Post, UseGuards } from "@nestjs/common";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { OrdersService } from "./orders.service";
import { CreateOrderDto } from "./orders.dto";

@Controller("orders")
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  create(
    @CurrentUserDecorator() user: { userId: string },
    @Body() dto: CreateOrderDto
  ) {
    return this.orders.createOrder(user.userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get(":orderId")
  get(@CurrentUserDecorator() user: { userId: string }, @Param("orderId") orderId: string) {
    return this.orders.getOrder(user.userId, orderId);
  }
}

