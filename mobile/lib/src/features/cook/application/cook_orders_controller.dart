import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order_status_terminal.dart';
import '../../orders/domain/order_summary.dart';

class CookOrdersController extends AsyncNotifier<List<OrderSummary>> {
  @override
  Future<List<OrderSummary>> build() async {
    return ref.read(ordersRepositoryProvider).listMine();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ordersRepositoryProvider).listMine(),
    );
  }

  Future<void> silentRefresh() async {
    final previous = state;
    try {
      final items = await ref.read(ordersRepositoryProvider).listMine();
      state = AsyncData(items);
    } catch (_) {
      if (previous.hasValue) state = previous;
    }
  }

  void applyServerOrders(List<OrderSummary> items) {
    state = AsyncData(items);
  }

  List<OrderSummary> _withStatus(
    List<OrderSummary> items,
    String orderId,
    String nextStatus,
  ) {
    final now = DateTime.now();
    return [
      for (final o in items)
        if (o.id == orderId)
          o.copyWith(status: nextStatus, updatedAt: now)
        else
          o,
    ];
  }

  Future<void> transition({
    required String orderId,
    required String action,
  }) async {
    final snapshot = state.value;
    final nextStatus = statusAfterCookAction(action);

    if (snapshot != null && nextStatus != null) {
      state = AsyncData(_withStatus(snapshot, orderId, nextStatus));
    }

    try {
      await ref
          .read(ordersRepositoryProvider)
          .updateStatus(orderId: orderId, action: action);
      await silentRefresh();
    } catch (e) {
      if (snapshot != null) {
        state = AsyncData(snapshot);
      }
      rethrow;
    }
  }
}

final cookOrdersControllerProvider =
    AsyncNotifierProvider<CookOrdersController, List<OrderSummary>>(
      CookOrdersController.new,
    );
