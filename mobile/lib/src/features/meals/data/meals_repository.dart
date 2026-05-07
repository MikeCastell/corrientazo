import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../domain/meal_publication.dart';

class MealsRepository {
  MealsRepository(this._ref);
  final Ref _ref;

  Future<List<MealPublication>> listPublished() {
    return _ref.read(apiClientProvider).getJson<List<MealPublication>>(
          '/meals',
          decode: (json) {
            final list = (json as List).cast<dynamic>();
            return list
                .map((e) => MealPublication.fromJson(e as Map<String, dynamic>))
                .toList(growable: false);
          },
        );
  }
}

final mealsRepositoryProvider = Provider<MealsRepository>((ref) => MealsRepository(ref));

