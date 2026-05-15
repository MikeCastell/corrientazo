import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_bootstrap.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/orders/application/live_orders_poller.dart';
import '../features/meals/application/meals_feed_poller.dart';

class CorrientazoApp extends ConsumerWidget {
  const CorrientazoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.watch(liveOrdersPollerProvider);
    ref.watch(mealsFeedPollerProvider);

    return NotificationBootstrap(
      child: MaterialApp.router(
        title: 'CORRIENTAZO',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        // Tema claro por defecto: la paleta crema+naranja+verde del logo solo está en light().
        // Con ThemeMode.system, el modo oscuro del teléfono ocultaba esos colores.
        themeMode: ThemeMode.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
