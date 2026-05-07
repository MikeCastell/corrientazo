import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order_create_response.dart';
import '../data/customer_orders_store.dart';

class CustomerOrdersState {
  const CustomerOrdersState({
    required this.loading,
    required this.active,
    required this.past,
  });

  final bool loading;
  final List<OrderCreateResponse> active;
  final List<OrderCreateResponse> past;

  static const empty = CustomerOrdersState(loading: false, active: [], past: []);
}

class CustomerOrdersController extends AsyncNotifier<CustomerOrdersState> {
  @override
  Future<CustomerOrdersState> build() async {
    return _load();
  }

  Future<CustomerOrdersState> _load() async {
    final ids = await ref.read(customerOrdersStoreProvider).getRecentOrderIds();
    if (ids.isEmpty) return CustomerOrdersState.empty;

    final repo = ref.read(ordersRepositoryProvider);
    final results = <OrderCreateResponse>[];
    for (final id in ids.take(8)) {
      try {
        results.add(await repo.getById(id));
      } catch (_) {
        // If some ids fail (expired/auth), we just skip for now.
      }
    }

    final active = <OrderCreateResponse>[];
    final past = <OrderCreateResponse>[];
    for (final o in results) {
      final s = o.status.toUpperCase();
      final isTerminal = s == 'DELIVERED' || s == 'CANCELLED' || s == 'REFUNDED';
      (isTerminal ? past : active).add(o);
    }

    return CustomerOrdersState(
      loading: false,
      active: active,
      past: past,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final customerOrdersControllerProvider =
    AsyncNotifierProvider<CustomerOrdersController, CustomerOrdersState>(
  CustomerOrdersController.new,
);

