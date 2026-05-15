import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_notifications.dart';
import 'notification_navigation.dart';

/// Inicializa notificaciones y enlaza taps → detalle del pedido.
class NotificationBootstrap extends ConsumerStatefulWidget {
  const NotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState extends ConsumerState<NotificationBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wire());
  }

  void _wire() {
    ref.read(notificationNavigationProvider);
    ref.read(localNotificationsProvider).setOrderTapHandler((orderId) {
      ref.read(notificationNavigationProvider.notifier).onOrderNotificationTap(
            orderId,
          );
    });
    ref.read(localNotificationsProvider).initIfNeeded();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
