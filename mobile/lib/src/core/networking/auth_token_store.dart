import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../env/app_env.dart';
import '../storage/storage_providers.dart';
import 'token_pair.dart';

class AuthTokenStore {
  AuthTokenStore(this._ref);

  static const _kAccess = 'auth.accessToken';
  static const _kRefresh = 'auth.refreshToken';

  final Ref _ref;

  Future<TokenPair?> read() async {
    if (AppEnv.startupDebug) debugPrint('[auth_token_store] read() start');
    final kv = _ref.read(secureKvStoreProvider);
    final access = await kv.read(_kAccess);
    final refresh = await kv.read(_kRefresh);
    if (access == null || refresh == null) {
      if (AppEnv.startupDebug) {
        debugPrint(
          '[auth_token_store] read() -> null (missing access/refresh)',
        );
      }
      return null;
    }
    if (AppEnv.startupDebug) {
      debugPrint('[auth_token_store] read() -> non-null tokens');
    }
    return TokenPair(accessToken: access, refreshToken: refresh);
  }

  Future<void> write(TokenPair pair) async {
    if (AppEnv.startupDebug) debugPrint('[auth_token_store] write() start');
    final kv = _ref.read(secureKvStoreProvider);
    await kv.write(_kAccess, pair.accessToken);
    await kv.write(_kRefresh, pair.refreshToken);
    if (AppEnv.startupDebug) debugPrint('[auth_token_store] write() done');
  }

  Future<void> clear() async {
    if (AppEnv.startupDebug) debugPrint('[auth_token_store] clear() start');
    final kv = _ref.read(secureKvStoreProvider);
    await kv.delete(_kAccess);
    await kv.delete(_kRefresh);
    if (AppEnv.startupDebug) debugPrint('[auth_token_store] clear() done');
  }
}

final authTokenStoreProvider = Provider<AuthTokenStore>(
  (ref) => AuthTokenStore(ref),
);
