import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../domain/cook_meal.dart';

class CookMealsStore {
  CookMealsStore(this._ref);
  final Ref _ref;

  static const _kMeals = 'cook.meals.v1';

  Future<List<CookMeal>> readAll() async {
    final kv = _ref.read(secureKvStoreProvider);
    final raw = await kv.read(_kMeals);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CookMeal.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeAll(List<CookMeal> meals) async {
    final kv = _ref.read(secureKvStoreProvider);
    final raw = jsonEncode(meals.map((m) => m.toJson()).toList());
    await kv.write(_kMeals, raw);
  }
}

final cookMealsStoreProvider = Provider<CookMealsStore>((ref) => CookMealsStore(ref));

