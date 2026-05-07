import { Module } from "@nestjs/common";

import { OrdersTrackingGateway } from "./sockets/orders-tracking.gateway";

@Module({
  providers: [OrdersTrackingGateway],
  exports: [OrdersTrackingGateway],
})
export class RealtimeModule {}

