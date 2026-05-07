import { Body, Controller, Get, Param, Post, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { OrdersService } from "./orders.service";
import { CreateOrderDto, UpdateOrderStatusDto } from "./orders.dto";

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
  @ApiOperation({ summary: "List orders for current user (customer or cook)" })
  @ApiResponse({ status: 200 })
  @Get()
  list(@CurrentUserDecorator() user: { userId: string }) {
    return this.orders.listOrders(user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Get order by id (customer access, foundation)" })
  @ApiResponse({ status: 200 })
  @Get(":orderId")
  get(@CurrentUserDecorator() user: { userId: string }, @Param("orderId") orderId: string) {
    return this.orders.getOrder(user.userId, orderId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles("COOK")
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Update order status (cook, foundation)" })
  @ApiBody({ type: UpdateOrderStatusDto })
  @ApiResponse({ status: 200 })
  @Post(":orderId/status")
  updateStatus(
    @CurrentUserDecorator() user: { userId: string },
    @Param("orderId") orderId: string,
    @Body() dto: UpdateOrderStatusDto
  ) {
    return this.orders.updateStatusAsCook(user.userId, orderId, dto.action);
  }
}

