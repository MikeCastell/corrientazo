import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order_summary.dart';
import '../../orders/domain/order_status_terminal.dart';

class CustomerOrdersState {
  const CustomerOrdersState({
    required this.loading,
    required this.active,
    required this.past,
  });

  final bool loading;
  final List<OrderSummary> active;
  final List<OrderSummary> past;

  static const empty = CustomerOrdersState(
    loading: false,
    active: [],
    past: [],
  );
}

class CustomerOrdersController extends AsyncNotifier<CustomerOrdersState> {
  @override
  Future<CustomerOrdersState> build() async {
    return _load();
  }

  CustomerOrdersState _fromSummaries(List<OrderSummary> results) {
    if (results.isEmpty) return CustomerOrdersState.empty;

    final active = <OrderSummary>[];
    final past = <OrderSummary>[];
    for (final o in results) {
      (orderStatusIsTerminal(o.status) ? past : active).add(o);
    }

    return CustomerOrdersState(loading: false, active: active, past: past);
  }

  Future<CustomerOrdersState> _load() async {
    final repo = ref.read(ordersRepositoryProvider);
    return _fromSummaries(await repo.listMine());
  }

  /// Actualiza la UI al instante cuando el poller detecta cambios del servidor.
  void applyServerOrders(List<OrderSummary> orders) {
    state = AsyncData(_fromSummaries(orders));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Polling / notificaciones: actualiza sin vaciar la lista.
  Future<void> silentRefresh() async {
    final previous = state;
    try {
      state = AsyncData(await _load());
    } catch (_) {
      if (previous.hasValue) state = previous;
    }
  }
}

final customerOrdersControllerProvider =
    AsyncNotifierProvider<CustomerOrdersController, CustomerOrdersState>(
      CustomerOrdersController.new,
    );
