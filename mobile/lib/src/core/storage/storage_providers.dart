import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_kv_store.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureKvStoreProvider = Provider<SecureKvStore>((ref) {
  return SecureKvStore(ref.watch(flutterSecureStorageProvider));
});
