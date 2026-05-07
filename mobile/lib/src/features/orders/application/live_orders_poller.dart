import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../../core/env/app_env.dart';
import '../../../core/notifications/local_notifications.dart';
import '../data/orders_repository.dart';
import '../domain/order_summary.dart';
import '../../customer/application/customer_orders_controller.dart';
import '../../cook/application/cook_orders_controller.dart';

/// Polling "light realtime" without sockets.
/// - Customer: status changes -> local notification + refresh.
/// - Cook: new order -> haptic + local notification + refresh.
class LiveOrdersPoller extends Notifier<void> {
  Timer? _timer;
  List<OrderSummary> _last = const [];
  final Map<String, _PublicationSnapshot> _lastPublicationByOrderId = {};

  @override
  void build() {
    ref.onDispose(() => _timer?.cancel());

    final auth = ref.watch(authControllerProvider);
    if (auth is! Authenticated) {
      _timer?.cancel();
      _timer = null;
      _last = const [];
      _lastPublicationByOrderId.clear();
      return;
    }

    _timer ??= Timer.periodic(const Duration(seconds: 12), (_) => _tick());
    // Run an immediate tick on first build for quick UI hydration.
    Future.microtask(_tick);
    // Request notification permission early (Android 13+). Cooks usually hit this on the
    // first poll via show(); customers only call show() after a status/publication change.
    Future.microtask(() => ref.read(localNotificationsProvider).initIfNeeded());
  }

  Future<void> _tick() async {
    final auth = ref.read(authControllerProvider);
    if (auth is! Authenticated) return;

    try {
      final next = await ref.read(ordersRepositoryProvider).listMine();

      final prevById = {for (final o in _last) o.id: o};
      final nextById = {for (final o in next) o.id: o};

      if (auth.user.isCook) {
        // New orders for cook
        final prevIds = prevById.keys.toSet();
        final newOnes = next.where((o) => !prevIds.contains(o.id)).toList();
        if (newOnes.isNotEmpty) {
          HapticFeedback.heavyImpact();
          await ref
              .read(localNotificationsProvider)
              .show(
                id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
                title: 'Nuevo pedido',
                body: '${newOnes.length} pedido(s) entraron. Abre “Pedidos”.',
              );
          // Only refresh UI when something changed.
          ref.invalidate(cookOrdersControllerProvider);
        }
      } else {
        // Status changes for customer
        final changed = <OrderSummary>[];
        for (final entry in nextById.entries) {
          final prev = prevById[entry.key];
          if (prev == null) continue;
          if (prev.status.toUpperCase() != entry.value.status.toUpperCase()) {
            changed.add(entry.value);
          }
        }
        final hadStatusChange = changed.isNotEmpty;
        if (hadStatusChange) {
          final o = changed.first;
          final prev = prevById[o.id];
          final nextS = o.status.toUpperCase();
          final prevS = prev?.status.toUpperCase();

          final msg = _customerStatusMessage(prevS: prevS, nextS: nextS);
          await ref
              .read(localNotificationsProvider)
              .show(
                id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
                title: msg.title,
                body: msg.body,
              );

          // Refresh UI only when something changed.
          ref.invalidate(customerOrdersControllerProvider);
        }

        // Cook updated the meal/publication: detect on ACTIVE orders via order detail.
        // This keeps the experience "alive" without polling lots of endpoints.
        final active = next
            .where((o) => !_isTerminal(o.status))
            .take(3)
            .toList();
        if (active.isNotEmpty) {
          await _checkPublicationUpdatesForActiveOrders(active);
        }
      }

      _last = next;
    } catch (e) {
      if (AppEnv.startupDebug) {
        debugPrint('[live_orders_poller] tick failed: $e');
      }
    }
  }

  Future<void> _checkPublicationUpdatesForActiveOrders(
    List<OrderSummary> active,
  ) async {
    // Avoid extra work on the very first run.
    if (_last.isEmpty) return;

    try {
      for (final o in active) {
        final detail = await ref.read(ordersRepositoryProvider).getById(o.id);
        final snap = _PublicationSnapshot(
          status: detail.publicationStatus?.toUpperCase(),
          stockAvailable: detail.stockAvailable,
        );

        final prev = _lastPublicationByOrderId[o.id];
        _lastPublicationByOrderId[o.id] = snap;
        if (prev == null) continue;

        final changed =
            prev.status != snap.status ||
            prev.stockAvailable != snap.stockAvailable;
        if (!changed) continue;

        final status = snap.status == null ? '' : 'Estado: ${snap.status}';
        final stock = snap.stockAvailable == null
            ? ''
            : 'Stock: ${snap.stockAvailable}';
        final body = [status, stock].where((x) => x.isNotEmpty).join(' · ');

        await ref
            .read(localNotificationsProvider)
            .show(
              id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
              title: 'Actualización del cocinero',
              body: body.isEmpty
                  ? 'Tu plato fue actualizado.'
                  : 'Tu plato fue actualizado. $body',
            );
      }
    } catch (e) {
      if (AppEnv.startupDebug) {
        debugPrint('[live_orders_poller] publication check failed: $e');
      }
    }
  }
}

bool _isTerminal(String s) {
  final v = s.toUpperCase();
  return v == 'DELIVERED' || v == 'CANCELLED' || v == 'REFUNDED';
}

({String title, String body}) _customerStatusMessage({
  required String? prevS,
  required String nextS,
}) {
  if (prevS == null) {
    return (
      title: 'Pedido actualizado',
      body: 'Estado: ${_labelForStatus(nextS)}',
    );
  }
  if (prevS == 'INIT' && nextS == 'CONFIRMED') {
    return (
      title: 'Pedido confirmado',
      body: 'El cocinero ya aceptó tu pedido. Empezamos.',
    );
  }
  if (nextS == 'PREPARING') {
    return (
      title: 'En preparación',
      body: 'Tu corrientazo ya se está haciendo.',
    );
  }
  if (nextS == 'READY_FOR_PICKUP') {
    return (
      title: 'Listo para recoger',
      body: 'Ya puedes pasar por tu pedido.',
    );
  }
  if (nextS == 'DELIVERED' || nextS == 'PICKED_UP') {
    return (title: 'Pedido entregado', body: 'Buen provecho.');
  }
  return (
    title: 'Tu pedido avanzó',
    body: 'Ahora está: ${_labelForStatus(nextS)}',
  );
}

String _labelForStatus(String s) {
  switch (s.toUpperCase()) {
    case 'INIT':
      return 'Nuevo';
    case 'CONFIRMED':
      return 'Confirmado';
    case 'PREPARING':
      return 'Preparando';
    case 'READY_FOR_PICKUP':
      return 'Listo';
    case 'DELIVERED':
    case 'PICKED_UP':
      return 'Entregado';
    default:
      return s;
  }
}

class _PublicationSnapshot {
  const _PublicationSnapshot({
    required this.status,
    required this.stockAvailable,
  });
  final String? status;
  final int? stockAvailable;
}

final liveOrdersPollerProvider = NotifierProvider<LiveOrdersPoller, void>(
  LiveOrdersPoller.new,
);
