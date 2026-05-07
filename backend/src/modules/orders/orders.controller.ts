import { Body, Controller, Get, Param, Post, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { OrdersService } from "./orders.service";
import { CreateOrderDto } from "./orders.dto";

@ApiTags("orders")
@Controller("orders")
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Create order (foundation, reserves stock atomically)" })
  @ApiBody({ type: CreateOrderDto })
  @ApiResponse({ status: 201 })
  @Post()
  create(
    @CurrentUserDecorator() user: { userId: string },
    @Body() dto: CreateOrderDto
  ) {
    return this.orders.createOrder(user.userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Get order by id (customer access, foundation)" })
  @ApiResponse({ status: 200 })
  @Get(":orderId")
  get(@CurrentUserDecorator() user: { userId: string }, @Param("orderId") orderId: string) {
    return this.orders.getOrder(user.userId, orderId);
  }
}

