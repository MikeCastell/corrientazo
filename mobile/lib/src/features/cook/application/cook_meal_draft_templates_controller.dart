import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/shared_preferences_provider.dart';
import '../domain/cook_meal_draft_template.dart';

class CookMealDraftTemplatesController extends Notifier<List<CookMealDraftTemplate>> {
  static const _prefsKey = 'cook_meal_draft_templates_v1';
  static const _maxTemplates = 40;

  @override
  List<CookMealDraftTemplate> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return CookMealDraftTemplate.decodeList(prefs.getString(_prefsKey));
  }

  Future<void> _persist(List<CookMealDraftTemplate> next) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefsKey, CookMealDraftTemplate.encodeList(next));
    state = next;
  }

  Future<void> add(CookMealDraftTemplate template) async {
    final withoutDupLabel = state.where((t) => t.id != template.id).toList();
    final next = [template, ...withoutDupLabel].take(_maxTemplates).toList();
    await _persist(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((t) => t.id != id).toList();
    await _persist(next);
  }
}

final cookMealDraftTemplatesProvider =
    NotifierProvider<CookMealDraftTemplatesController, List<CookMealDraftTemplate>>(
  CookMealDraftTemplatesController.new,
);
