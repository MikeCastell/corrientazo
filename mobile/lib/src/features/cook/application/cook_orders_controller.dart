import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/data/orders_repository.dart';
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

  Future<void> transition({
    required String orderId,
    required String action,
  }) async {
    await ref
        .read(ordersRepositoryProvider)
        .updateStatus(orderId: orderId, action: action);
    await refresh();
  }
}

final cookOrdersControllerProvider =
    AsyncNotifierProvider<CookOrdersController, List<OrderSummary>>(
      CookOrdersController.new,
    );
