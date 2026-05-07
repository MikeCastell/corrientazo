import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cook_meals_store.dart';
import '../domain/cook_meal.dart';

class CookMealsController extends AsyncNotifier<List<CookMeal>> {
  @override
  Future<List<CookMeal>> build() async {
    return ref.read(cookMealsStoreProvider).readAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cookMealsStoreProvider).readAll());
  }

  Future<void> upsert(CookMeal meal) async {
    final current = state.value ?? await ref.read(cookMealsStoreProvider).readAll();
    final next = [
      meal,
      ...current.where((m) => m.id != meal.id),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await ref.read(cookMealsStoreProvider).writeAll(next);
    state = AsyncValue.data(next);
  }

  Future<void> setStatus(String id, CookMealStatus status) async {
    final current = state.value ?? await ref.read(cookMealsStoreProvider).readAll();
    final next = current.map((m) => m.id == id ? m.copyWith(status: status) : m).toList();
    await ref.read(cookMealsStoreProvider).writeAll(next);
    state = AsyncValue.data(next);
  }
}

final cookMealsControllerProvider =
    AsyncNotifierProvider<CookMealsController, List<CookMeal>>(CookMealsController.new);

