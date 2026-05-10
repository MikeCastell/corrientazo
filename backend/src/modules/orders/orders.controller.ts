import { Body, Controller, Get, Param, Post, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiBody, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUserDecorator } from "../../common/decorators/current-user.decorator";
import { OrdersService } from "./orders.service";
import {
  CancelOrderBodyDto,
  CancelOrderDto,
  CreateOrderDto,
  UpdateOrderStatusDto,
} from "./orders.dto";

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

  /// Cancelación vía **POST /orders/cancel** + JSON `{ orderId, … }`.
  /// Misma idea que `POST /orders` para crear: una sola ruta estable sin UUID en el path.

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth("bearer")
  @ApiOperation({
    summary: "Cancelar pedido (cliente o cook; reglas y stock en servidor)",
  })
  @ApiBody({ type: CancelOrderBodyDto })
  @ApiResponse({ status: 200 })
  @Post("cancel")
  cancel(
    @CurrentUserDecorator() user: { userId: string },
    @Body() dto: CancelOrderBodyDto
  ) {
    const { orderId, ...meta } = dto;
    return this.orders.cancelOrder(user.userId, orderId, meta);
  }

  /** Misma lógica que `POST …/cancel`, pero `orderId` va en la URL (como `…/status`). Útil si el proxy/CDN no enruta bien `POST …/orders/cancel`. */
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth("bearer")
  @ApiOperation({
    summary: "Cancelar pedido (variante con id en la URL)",
  })
  @ApiBody({ type: CancelOrderDto })
  @ApiResponse({ status: 200 })
  @Post(":orderId/cancel")
  cancelByOrderId(
    @CurrentUserDecorator() user: { userId: string },
    @Param("orderId") orderId: string,
    @Body() dto: CancelOrderDto
  ) {
    return this.orders.cancelOrder(user.userId, orderId, dto);
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

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth("bearer")
  @ApiOperation({ summary: "Get order by id (customer access, foundation)" })
  @ApiResponse({ status: 200 })
  @Get(":orderId")
  get(@CurrentUserDecorator() user: { userId: string }, @Param("orderId") orderId: string) {
    return this.orders.getOrder(user.userId, orderId);
  }
}

