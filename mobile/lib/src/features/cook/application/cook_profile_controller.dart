import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cook_profile_repository.dart';

class CookProfileController extends AsyncNotifier<CookProfileDto> {
  @override
  Future<CookProfileDto> build() async {
    return ref.read(cookProfileRepositoryProvider).getMine();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(cookProfileRepositoryProvider).getMine(),
    );
  }

  Future<CookProfileDto> save({
    String? businessName,
    String? avatarUrl,
    String? bio,
  }) async {
    final repo = ref.read(cookProfileRepositoryProvider);
    final next = await repo.update(
      businessName: businessName,
      avatarUrl: avatarUrl,
      bio: bio,
    );
    state = AsyncData(next);
    return next;
  }
}

final cookProfileControllerProvider =
    AsyncNotifierProvider<CookProfileController, CookProfileDto>(
      CookProfileController.new,
    );
