import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado optimista mientras el servidor confirma un cambio de pedido.
class OrderStatusOverrideNotifier extends Notifier<String?> {
  OrderStatusOverrideNotifier(this.orderId);

  final String orderId;

  @override
  String? build() => null;

  void setOverride(String? status) => state = status;
}

final orderStatusOverrideProvider =
    NotifierProvider.family<OrderStatusOverrideNotifier, String?, String>(
  OrderStatusOverrideNotifier.new,
);
