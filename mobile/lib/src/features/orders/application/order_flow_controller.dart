import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_exception.dart';
import '../data/orders_repository.dart';
import '../domain/order_create_request.dart';
import '../domain/order_create_response.dart';

sealed class OrderFlowState {
  const OrderFlowState();
}

class OrderFlowIdle extends OrderFlowState {
  const OrderFlowIdle();
}

class OrderFlowSubmitting extends OrderFlowState {
  const OrderFlowSubmitting();
}

class OrderFlowSuccess extends OrderFlowState {
  const OrderFlowSuccess(this.order);
  final OrderCreateResponse order;
}

class OrderFlowError extends OrderFlowState {
  const OrderFlowError(this.error);
  final ApiException error;
}

class OrderFlowController extends Notifier<OrderFlowState> {
  @override
  OrderFlowState build() => const OrderFlowIdle();

  Future<OrderCreateResponse> submit(OrderCreateRequest req) async {
    state = const OrderFlowSubmitting();
    try {
      final order = await ref.read(ordersRepositoryProvider).createOrder(req);
      state = OrderFlowSuccess(order);
      return order;
    } on ApiException catch (e) {
      state = OrderFlowError(e);
      rethrow;
    }
  }

  void reset() => state = const OrderFlowIdle();
}

final orderFlowControllerProvider =
    NotifierProvider<OrderFlowController, OrderFlowState>(
      OrderFlowController.new,
    );
