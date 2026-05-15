import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/users/domain/current_user.dart';

/// Navegación al tocar una notificación de pedido (tap en foreground/background).
class NotificationNavigationController extends Notifier<void> {
  String? _pendingOrderId;

  @override
  void build() {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is Authenticated) {
        flushPending();
      }
    });
  }

  void onOrderNotificationTap(String orderId) {
    final id = orderId.trim();
    if (id.isEmpty) return;
    _navigateToOrder(id);
  }

  void flushPending() {
    final id = _pendingOrderId;
    if (id == null) return;
    _pendingOrderId = null;
    _navigateToOrder(id);
  }

  void _navigateToOrder(String orderId) {
    final auth = ref.read(authControllerProvider);
    if (auth is! Authenticated) {
      _pendingOrderId = orderId;
      return;
    }

    final GoRouter router = ref.read(appRouterProvider);
    final location = auth.user.role == UserRole.cook
        ? CookOrderDetailRoute(orderId).location
        : CustomerOrderDetailRoute(orderId).location;
    router.go(location);
  }
}

final notificationNavigationProvider =
    NotifierProvider<NotificationNavigationController, void>(
  NotificationNavigationController.new,
);
