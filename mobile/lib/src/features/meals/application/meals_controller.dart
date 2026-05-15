import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env/app_env.dart';
import '../data/meals_repository.dart';
import '../domain/meal_publication.dart';

class MealsFeedController extends AsyncNotifier<List<MealPublication>> {
  @override
  Future<List<MealPublication>> build() async {
    return ref.read(mealsRepositoryProvider).listPublished();
  }

  /// Pull-to-refresh / reintentar: el usuario espera ver actividad de carga.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(mealsRepositoryProvider).listPublished(),
    );
  }

  /// Polling en segundo plano: no vacía la lista ni muestra error si ya hay datos.
  Future<void> silentRefresh() async {
    if (state.isLoading) return;

    final previous = state;
    try {
      final items = await ref.read(mealsRepositoryProvider).listPublished();
      state = AsyncData(items);
    } catch (e, st) {
      if (AppEnv.startupDebug) {
        debugPrint('[meals_feed] silent refresh failed: $e\n$st');
      }
      if (!previous.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }
}

final mealsFeedProvider =
    AsyncNotifierProvider<MealsFeedController, List<MealPublication>>(
  MealsFeedController.new,
);
