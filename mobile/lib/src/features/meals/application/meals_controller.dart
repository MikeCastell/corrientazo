import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meals_repository.dart';
import '../domain/meal_publication.dart';

final mealsFeedProvider = FutureProvider<List<MealPublication>>((ref) async {
  return ref.watch(mealsRepositoryProvider).listPublished();
});
