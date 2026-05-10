import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/meal_publication.dart';

/// Categoría principal en el home del cliente (solo UI + filtrado local).
enum CustomerHomeCategory {
  corrientazos,
  postres,
}

class CustomerHomeCategoryNotifier extends Notifier<CustomerHomeCategory?> {
  /// `null` = vista inicial al abrir la app (incluye «Recomendados»).
  @override
  CustomerHomeCategory? build() => null;

  void select(CustomerHomeCategory category) {
    if (state == category) return;
    state = category;
  }
}

final customerHomeCategoryProvider =
    NotifierProvider<
        CustomerHomeCategoryNotifier,
        CustomerHomeCategory?>(
  CustomerHomeCategoryNotifier.new,
);

/// Heurística: postres por palabras en título, descripción o tags del publicador.
bool mealPublicationReadsAsPostre(MealPublication m) {
  final tags = (m.tags ?? []).map((t) => t.toLowerCase().trim()).join(' ');
  final title = (m.title ?? '').toLowerCase();
  final desc = (m.description ?? '').toLowerCase();
  final haystack = '$tags $title $desc';

  const hints = <String>[
    'postre',
    'postres',
    'dulce',
    'dulces',
    'torta',
    'brownie',
    'brownies',
    'helado',
    'flan',
    'merengue',
    'arroz con leche',
    'quesillo',
    'gelatina',
    'cake',
    'dessert',
    'pay de',
    'pie de',
    'natilla',
    'milhoja',
    'alfajor',
    'arequipe',
    'budín',
    'pudín',
    'mousse',
    'cupcake',
    'galleta',
    'galletas',
  ];

  for (final k in hints) {
    if (haystack.contains(k)) return true;
  }
  return false;
}

List<MealPublication> mealsForCustomerCategory(
  List<MealPublication> all,
  CustomerHomeCategory? category,
) {
  if (category == null) return List<MealPublication>.from(all);
  switch (category) {
    case CustomerHomeCategory.corrientazos:
      return all.where((m) => !mealPublicationReadsAsPostre(m)).toList();
    case CustomerHomeCategory.postres:
      return all.where(mealPublicationReadsAsPostre).toList();
  }
}
