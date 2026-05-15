import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env/app_env.dart';
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

  Future<void> upsert(
    CookMeal meal, {
    /// Si true, no cambia PUBLISHED/PAUSED de la oferta (solo precio, stock, etc.).
    bool preservePublicationStatus = false,
    /// Si false, no crea publicación nueva al guardar (solo al publicar).
    bool allowCreatePublication = true,
  }) async {
    final repo = ref.read(cookMealsRepositoryProvider);
    // Never no-op while the list is still loading: the user can publish a new
    // dish before [build] finishes; the old `if (state.isLoading) return` skipped
    // all network calls and the UI still looked like a success.

    final wantsPublish = meal.status == CookMealStatus.available;
    final now = DateTime.now();
    final availableFrom = now.subtract(const Duration(minutes: 5));
    // Longer window so cooks don't “expire” invisibly during testing / overnight.
    // Backend feed shows only publications where now is within [available_from, available_to].
    final availableTo = now.add(const Duration(hours: 12));
    final pickupFrom = now.add(const Duration(minutes: 20));
    final pickupTo = now.add(const Duration(hours: 12));
    final desiredPubStatus = preservePublicationStatus
        ? null
        : (wantsPublish ? 'PUBLISHED' : 'PAUSED');
    final ff = _fulfillmentFlags(meal.fulfillmentType);

    if (meal.id.startsWith('m_')) {
      final created = await repo.create(
        title: meal.title,
        description: meal.description.isEmpty ? null : meal.description,
        basePriceCop: meal.priceCop,
        tags: meal.ingredients,
        photoUrl: null,
      );
      if (meal.stock > 0 && allowCreatePublication) {
        await repo.publish(
          created.id,
          priceCop: meal.priceCop,
          stockTotal: meal.stock,
          availableFrom: availableFrom,
          availableTo: availableTo,
          pickupFrom: pickupFrom,
          pickupTo: pickupTo,
          deliveryEnabled: ff.delivery,
          pickupEnabled: ff.pickup,
          deliveryZoneId: null,
          status: desiredPubStatus,
        );
      }
      await refresh();
      return;
    }

    await repo.update(
      meal.id,
      title: meal.title,
      description: meal.description.isEmpty ? null : meal.description,
      basePriceCop: meal.priceCop,
      tags: meal.ingredients,
    );
    if (meal.stock > 0) {
      if (meal.publicationId != null) {
        await repo.updatePublication(
          meal.publicationId!,
          status: desiredPubStatus,
          priceCop: meal.priceCop,
          stockAvailable: meal.stock,
          stockTotal: meal.stock,
        );
      } else if (allowCreatePublication) {
        await repo.publish(
          meal.id,
          priceCop: meal.priceCop,
          stockTotal: meal.stock,
          availableFrom: availableFrom,
          availableTo: availableTo,
          pickupFrom: pickupFrom,
          pickupTo: pickupTo,
          deliveryEnabled: ff.delivery,
          pickupEnabled: ff.pickup,
          deliveryZoneId: null,
          status: desiredPubStatus,
        );
      }
    } else if (meal.publicationId != null) {
      await repo.updatePublication(
        meal.publicationId!,
        status: preservePublicationStatus ? null : 'PAUSED',
        priceCop: meal.priceCop,
        stockTotal: 0,
        stockAvailable: 0,
      );
    }
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

    if (AppEnv.startupDebug) {
      // ignore: avoid_print
      print('[cook] setStatus meal=$id pub=$pubId -> $status');
    }

    // Optimistic UI update so the cook sees it instantly.
    final optimistic = [
      for (final m in current)
        if (m.id == id) m.copyWith(status: status) else m,
    ];
    state = AsyncData(optimistic);

    final repo = ref.read(cookMealsRepositoryProvider);
    final nextStatus = status == CookMealStatus.available
        ? 'PUBLISHED'
        : 'PAUSED';
    try {
      await repo.updatePublication(pubId, status: nextStatus);
    } finally {
      // Always reconcile from server after.
      await refresh();
    }
  }

  Future<void> deleteMeal(String id) async {
    await ref.read(cookMealsRepositoryProvider).delete(id);
    await refresh();
  }

  /// Publicar en masa (reactivar oferta o crear publicación si aún no existe).
  Future<
      ({
        int published,
        int skippedSoldOut,
        int skippedNoStock,
      })> bulkPublish(List<CookMeal> meals) async {
    final repo = ref.read(cookMealsRepositoryProvider);
    final now = DateTime.now();
    final availableFrom = now.subtract(const Duration(minutes: 5));
    final availableTo = now.add(const Duration(hours: 12));
    final pickupFrom = now.add(const Duration(minutes: 20));
    final pickupTo = now.add(const Duration(hours: 12));

    var published = 0;
    var skippedSoldOut = 0;
    var skippedNoStock = 0;

    for (final m in meals) {
      if (m.status == CookMealStatus.soldOut) {
        skippedSoldOut++;
        continue;
      }
      if (m.stock <= 0) {
        skippedNoStock++;
        continue;
      }
      final ff = _fulfillmentFlags(m.fulfillmentType);

      if (m.publicationId != null) {
        await repo.updatePublication(
          m.publicationId!,
          status: 'PUBLISHED',
          priceCop: m.priceCop,
          stockTotal: m.stock,
          stockAvailable: m.stock,
        );
      } else {
        await repo.update(
          m.id,
          title: m.title,
          description: m.description.isEmpty ? null : m.description,
          basePriceCop: m.priceCop,
          tags: m.ingredients,
          photoUrl: null,
        );
        await repo.publish(
          m.id,
          priceCop: m.priceCop,
          stockTotal: m.stock,
          availableFrom: availableFrom,
          availableTo: availableTo,
          pickupFrom: pickupFrom,
          pickupTo: pickupTo,
          deliveryEnabled: ff.delivery,
          pickupEnabled: ff.pickup,
          deliveryZoneId: null,
          status: 'PUBLISHED',
        );
      }
      published++;
    }
    await refresh();
    return (
      published: published,
      skippedSoldOut: skippedSoldOut,
      skippedNoStock: skippedNoStock,
    );
  }

  /// Pausar ofertas existentes (omite platos sin publicación).
  Future<({int paused, int skippedNoPublication})> bulkPause(
    List<CookMeal> meals,
  ) async {
    final repo = ref.read(cookMealsRepositoryProvider);
    var paused = 0;
    var skippedNoPublication = 0;
    for (final m in meals) {
      if (m.publicationId == null) {
        skippedNoPublication++;
        continue;
      }
      await repo.updatePublication(m.publicationId!, status: 'PAUSED');
      paused++;
    }
    await refresh();
    return (paused: paused, skippedNoPublication: skippedNoPublication);
  }

  Future<void> bulkDelete(List<String> ids) async {
    final repo = ref.read(cookMealsRepositoryProvider);
    for (final id in ids) {
      await repo.delete(id);
    }
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
      fulfillmentType: _flagsToFulfillment(pub?.deliveryEnabled, pub?.pickupEnabled),
      ingredients: t.tags,
      status: stock <= 0 ? CookMealStatus.soldOut : status,
      createdAt: t.createdAt,
    );
  }
}

({bool delivery, bool pickup}) _fulfillmentFlags(String type) {
  switch (type) {
    case 'DELIVERY':
      return (delivery: true, pickup: false);
    case 'BOTH':
      return (delivery: true, pickup: true);
    default:
      return (delivery: false, pickup: true);
  }
}

String _flagsToFulfillment(bool? deliveryEnabled, bool? pickupEnabled) {
  final d = deliveryEnabled ?? false;
  final p = pickupEnabled ?? true;
  if (d && p) return 'BOTH';
  if (d && !p) return 'DELIVERY';
  return 'PICKUP';
}

final cookMealsControllerProvider =
    AsyncNotifierProvider<CookMealsController, List<CookMeal>>(
      CookMealsController.new,
    );

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
