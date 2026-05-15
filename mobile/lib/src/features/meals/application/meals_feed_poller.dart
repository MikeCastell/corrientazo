import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../../core/env/app_env.dart';
import 'meals_controller.dart';

/// Refresco liviano del feed sin sockets (MVP).
///
/// - Solo corre para usuarios `CUSTOMER`.
/// - Cada N segundos refresca `mealsFeedProvider` para que cambios del cook
///   (pickup/delivery, stock, etc.) se vean en la UI con baja latencia.
class MealsFeedPoller extends Notifier<void> {
  Timer? _timer;
  bool _inFlight = false;

  @override
  void build() {
    ref.onDispose(() => _timer?.cancel());

    final auth = ref.watch(authControllerProvider);
    if (auth is! Authenticated || !auth.user.isCustomer) {
      _timer?.cancel();
      _timer = null;
      _inFlight = false;
      return;
    }

    _timer ??= Timer.periodic(const Duration(seconds: 15), (_) => _tick());
    // Hidratar rápido al entrar al app.
    Future.microtask(_tick);
  }

  Future<void> _tick() async {
    if (_inFlight) return;
    final auth = ref.read(authControllerProvider);
    if (auth is! Authenticated || !auth.user.isCustomer) return;
    _inFlight = true;
    try {
      // Forzamos refresh para que el FutureProvider entregue contenido nuevo.
      ref.invalidate(mealsFeedProvider);
      await ref.read(mealsFeedProvider.future);
    } catch (e, st) {
      if (AppEnv.startupDebug) {
        debugPrint('[meals_feed_poller] failed: $e\n$st');
      }
    } finally {
      _inFlight = false;
    }
  }
}

final mealsFeedPollerProvider = NotifierProvider<MealsFeedPoller, void>(
  MealsFeedPoller.new,
);

