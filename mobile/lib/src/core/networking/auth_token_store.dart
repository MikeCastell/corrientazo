import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';
import 'token_pair.dart';

class AuthTokenStore {
  AuthTokenStore(this._ref);

  static const _kAccess = 'auth.accessToken';
  static const _kRefresh = 'auth.refreshToken';

  final Ref _ref;

  Future<TokenPair?> read() async {
    final kv = _ref.read(secureKvStoreProvider);
    final access = await kv.read(_kAccess);
    final refresh = await kv.read(_kRefresh);
    if (access == null || refresh == null) return null;
    return TokenPair(accessToken: access, refreshToken: refresh);
  }

  Future<void> write(TokenPair pair) async {
    final kv = _ref.read(secureKvStoreProvider);
    await kv.write(_kAccess, pair.accessToken);
    await kv.write(_kRefresh, pair.refreshToken);
  }

  Future<void> clear() async {
    final kv = _ref.read(secureKvStoreProvider);
    await kv.delete(_kAccess);
    await kv.delete(_kRefresh);
  }
}

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) => AuthTokenStore(ref));

