import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/token_pair.dart';

class AuthRepository {
  AuthRepository(this._ref);
  final Ref _ref;

  Future<TokenPair> register({
    required String phone,
    required String password,
    required String name,
    required String role,
  }) {
    return _ref
        .read(apiClientProvider)
        .postJson<TokenPair>(
          '/auth/register',
          body: {
            'phone': phone,
            'password': password,
            'name': name,
            'role': role,
          },
          decode: (json) => TokenPair.fromJson(json as Map<String, dynamic>),
        );
  }

  Future<TokenPair> login({required String phone, required String password}) {
    return _ref
        .read(apiClientProvider)
        .postJson<TokenPair>(
          '/auth/login',
          body: {'phone': phone, 'password': password},
          decode: (json) => TokenPair.fromJson(json as Map<String, dynamic>),
        );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref),
);
