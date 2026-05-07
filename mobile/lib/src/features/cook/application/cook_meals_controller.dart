import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cook_meals_repository.dart';
import '../domain/cook_meal.dart';

class CookMealsController extends AsyncNotifier<List<CookMeal>> {
  @override
  Future<List<CookMeal>> build() async {
    final items = await ref.read(cookMealsRepositoryProvider).listMine();
    return items.map(_toDomain).toList(growable: false);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await ref.read(cookMealsRepositoryProvider).listMine();
      return items.map(_toDomain).toList(growable: false);
    });
  }

  Future<void> upsert(CookMeal meal) async {
    final repo = ref.read(cookMealsRepositoryProvider);
    if (state.isLoading) return;

    if (meal.id.startsWith('m_')) {
      await repo.create(
        title: meal.title,
        description: meal.description.isEmpty ? null : meal.description,
        basePriceCop: meal.priceCop,
        tags: meal.ingredients,
        photoUrl: null,
      );
      await refresh();
      return;
    }

    await repo.update(
      meal.id,
      title: meal.title,
      description: meal.description.isEmpty ? null : meal.description,
      basePriceCop: meal.priceCop,
      tags: meal.ingredients,
      photoUrl: null,
    );
    await refresh();
  }

  Future<void> setStatus(String id, CookMealStatus status) async {
    // In backend, status lives on meal_publications (offers), not on meal templates.
    // For MVP, we toggle the latest publication if present; otherwise we no-op.
    final current = state.value ?? await build();
    final found = current.where((m) => m.id == id).firstOrNull;
    if (found == null) return;

    final pubId = found.publicationId;
    if (pubId == null) return;

    final repo = ref.read(cookMealsRepositoryProvider);
    final nextStatus = status == CookMealStatus.available
        ? 'PUBLISHED'
        : 'PAUSED';
    await repo.updatePublication(pubId, status: nextStatus);
    await refresh();
  }

  Future<void> deleteMeal(String id) async {
    await ref.read(cookMealsRepositoryProvider).delete(id);
    await refresh();
  }

  CookMeal _toDomain(CookMealTemplateDto t) {
    final pub = t.latestPublication;
    final status = switch (pub?.status) {
      'PUBLISHED' => CookMealStatus.available,
      'PAUSED' => CookMealStatus.paused,
      _ => CookMealStatus.paused,
    };
    final stock = pub?.stockAvailable ?? 0;
    final price = pub?.priceCop ?? t.basePriceCop;

    return CookMeal(
      id: t.id,
      publicationId: pub?.id,
      title: t.title,
      description: t.description ?? '',
      priceCop: price,
      stock: stock,
      fulfillmentType: 'PICKUP',
      ingredients: t.tags,
      status: stock <= 0 ? CookMealStatus.soldOut : status,
      createdAt: t.createdAt,
    );
  }
}

final cookMealsControllerProvider =
    AsyncNotifierProvider<CookMealsController, List<CookMeal>>(
      CookMealsController.new,
    );

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
