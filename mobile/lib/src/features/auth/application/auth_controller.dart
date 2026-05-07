import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/auth_token_store.dart';
import '../domain/auth_state.dart';
import '../data/auth_repository.dart';

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthUnknown();
  }

  Ref get _ref => ref;

  Future<void> _init() async {
    final tokens = await _ref.read(authTokenStoreProvider).read();
    state = tokens == null ? const Unauthenticated() : const Authenticated();
  }

  Future<void> register({
    required String phone,
    required String password,
    required String name,
    required String role,
  }) async {
    final pair = await _ref.read(authRepositoryProvider).register(
          phone: phone,
          password: password,
          name: name,
          role: role,
        );
    await _ref.read(authTokenStoreProvider).write(pair);
    state = const Authenticated();
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    final pair = await _ref.read(authRepositoryProvider).login(
          phone: phone,
          password: password,
        );
    await _ref.read(authTokenStoreProvider).write(pair);
    state = const Authenticated();
  }

  Future<void> logout() async {
    final store = _ref.read(authTokenStoreProvider);
    await store.clear();
    state = const Unauthenticated();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

