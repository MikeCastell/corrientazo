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
/// - Actualiza en silencio (sin pantalla de carga ni error si ya había datos).
class MealsFeedPoller extends Notifier<void> {
  Timer? _timer;
  bool _inFlight = false;
  DateTime? _lastSuccess;

  static const _pollInterval = Duration(seconds: 45);
  static const _minGapBetweenFetches = Duration(seconds: 30);

  @override
  void build() {
    ref.onDispose(() => _timer?.cancel());

    final auth = ref.watch(authControllerProvider);
    if (auth is! Authenticated || !auth.user.isCustomer) {
      _timer?.cancel();
      _timer = null;
      _inFlight = false;
      _lastSuccess = null;
      return;
    }

    _timer ??= Timer.periodic(_pollInterval, (_) => _tick());
  }

  Future<void> _tick() async {
    if (_inFlight) return;

    final auth = ref.read(authControllerProvider);
    if (auth is! Authenticated || !auth.user.isCustomer) return;

    final last = _lastSuccess;
    if (last != null && DateTime.now().difference(last) < _minGapBetweenFetches) {
      return;
    }

    _inFlight = true;
    try {
      await ref.read(mealsFeedProvider.notifier).silentRefresh();
      final feed = ref.read(mealsFeedProvider);
      if (feed.hasValue) _lastSuccess = DateTime.now();
    } catch (e, st) {
      if (AppEnv.startupDebug) {
        debugPrint('[meals_feed_poller] tick failed: $e\n$st');
      }
    } finally {
      _inFlight = false;
    }
  }
}

final mealsFeedPollerProvider = NotifierProvider<MealsFeedPoller, void>(
  MealsFeedPoller.new,
);
