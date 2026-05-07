import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env/app_env.dart';
import '../../../core/networking/auth_token_store.dart';
import '../domain/auth_state.dart';
import '../data/auth_repository.dart';
import '../../users/data/users_repository.dart';

class AuthDebugStatusController extends Notifier<String> {
  @override
  String build() => 'Booting…';

  void set(String v) => state = v;
}

final authDebugStatusProvider =
    NotifierProvider<AuthDebugStatusController, String>(AuthDebugStatusController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Ensure init cannot block build; always resolves to known state.
    if (AppEnv.startupDebug) debugPrint('[auth] build() -> AuthUnknown');
    Future.microtask(_init);
    return const AuthUnknown();
  }

  Ref get _ref => ref;

  Future<void> _init() async {
    final sw = Stopwatch()..start();
    Timer? warn;
    warn = Timer(const Duration(seconds: 3), () {
      if (AppEnv.startupDebug) debugPrint('[auth] WARN _init() >3s (still pending)');
      _ref.read(authDebugStatusProvider.notifier).set(
            'WARN: init auth >3s (still pending)',
          );
    });

    if (AppEnv.startupDebug) debugPrint('[auth] _init() start');
    _ref.read(authDebugStatusProvider.notifier).set('Initializing auth…');

    try {
      _ref.read(authDebugStatusProvider.notifier).set('Reading secure storage…');

      // Defensive hard timeout: never allow splash to hang forever.
      final tokens = await _ref
          .read(authTokenStoreProvider)
          .read()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        if (AppEnv.startupDebug) {
          debugPrint('[auth] TIMEOUT reading tokens (>5s) -> forcing Unauthenticated');
        }
        _ref.read(authDebugStatusProvider.notifier).set('Timeout >5s -> Unauthenticated');
        return null;
      });

      if (AppEnv.startupDebug) {
        debugPrint(
          '[auth] _init() tokens: access=${tokens?.accessToken.isNotEmpty == true} '
          'refresh=${tokens?.refreshToken.isNotEmpty == true}',
        );
      }

      if (tokens == null) {
        if (AppEnv.startupDebug) {
          debugPrint(
            '[auth] _init() resolved -> Unauthenticated (no tokens) in ${sw.elapsedMilliseconds}ms',
          );
        }
        _ref.read(authDebugStatusProvider.notifier).set('Auth resolved -> Unauthenticated');
        state = const Unauthenticated();
        return;
      }

      _ref.read(authDebugStatusProvider.notifier).set('Fetching profile…');
      try {
        final me = await _ref
            .read(usersRepositoryProvider)
            .getMe()
            .timeout(const Duration(seconds: 5));

        if (AppEnv.startupDebug) {
          debugPrint(
            '[auth] _init() resolved -> Authenticated(role=${me.role}) in ${sw.elapsedMilliseconds}ms',
          );
        }
        _ref.read(authDebugStatusProvider.notifier).set('Auth resolved -> Authenticated (${me.role.name})');
        state = Authenticated(me);
        return;
      } on TimeoutException {
        if (AppEnv.startupDebug) {
          debugPrint('[auth] TIMEOUT /users/me (>5s) -> forcing Unauthenticated');
        }
        await _ref.read(authTokenStoreProvider).clear();
        _ref.read(authDebugStatusProvider.notifier).set('Auth resolved -> Unauthenticated (profile timeout)');
        state = const Unauthenticated();
        return;
      }

    } catch (e, st) {
      if (AppEnv.startupDebug) {
        debugPrint('[auth] _init() ERROR -> Unauthenticated. $e');
        debugPrint('$st');
      }
      _ref.read(authDebugStatusProvider.notifier).set(
            'Auth ERROR -> Unauthenticated (${e.runtimeType})',
          );
      await _ref.read(authTokenStoreProvider).clear();
      state = const Unauthenticated();
    } finally {
      warn.cancel();
    }
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
    final me = await _ref.read(usersRepositoryProvider).getMe();
    if (AppEnv.startupDebug) debugPrint('[auth] register() -> Authenticated(role=${me.role})');
    state = Authenticated(me);
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
    final me = await _ref.read(usersRepositoryProvider).getMe();
    if (AppEnv.startupDebug) debugPrint('[auth] login() -> Authenticated(role=${me.role})');
    state = Authenticated(me);
  }

  Future<void> logout() async {
    final store = _ref.read(authTokenStoreProvider);
    await store.clear();
    if (AppEnv.startupDebug) debugPrint('[auth] logout() -> Unauthenticated');
    state = const Unauthenticated();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

