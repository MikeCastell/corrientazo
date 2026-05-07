import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../domain/current_user.dart';

class UsersRepository {
  UsersRepository(this._ref);
  final Ref _ref;

  Future<CurrentUser> getMe() {
    return _ref
        .read(apiClientProvider)
        .getJson<CurrentUser>(
          '/users/me',
          decode: (json) => CurrentUser.fromJson(json as Map<String, dynamic>),
        );
  }
}

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(ref),
);
