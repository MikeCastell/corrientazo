import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../env/app_env.dart';

class SecureKvStore {
  const SecureKvStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    final sw = Stopwatch()..start();
    Timer? warn;
    warn = Timer(const Duration(seconds: 3), () {
      if (AppEnv.startupDebug) {
        debugPrint('[secure_kv] WARN read("$key") >3s (still pending)');
      }
    });
    if (AppEnv.startupDebug) debugPrint('[secure_kv] read("$key") start');
    try {
      final v = await _storage.read(key: key);
      if (AppEnv.startupDebug) {
        debugPrint(
          '[secure_kv] read("$key") done in ${sw.elapsedMilliseconds}ms -> ${v == null ? "null" : "non-null"}',
        );
      }
      return v;
    } finally {
      warn.cancel();
    }
  }

  Future<void> write(String key, String value) async {
    final sw = Stopwatch()..start();
    Timer? warn;
    warn = Timer(const Duration(seconds: 3), () {
      if (AppEnv.startupDebug) {
        debugPrint('[secure_kv] WARN write("$key") >3s (still pending)');
      }
    });
    if (AppEnv.startupDebug) debugPrint('[secure_kv] write("$key") start');
    try {
      await _storage.write(key: key, value: value);
      if (AppEnv.startupDebug) {
        debugPrint('[secure_kv] write("$key") done in ${sw.elapsedMilliseconds}ms');
      }
    } finally {
      warn.cancel();
    }
  }

  Future<void> delete(String key) async {
    final sw = Stopwatch()..start();
    Timer? warn;
    warn = Timer(const Duration(seconds: 3), () {
      if (AppEnv.startupDebug) {
        debugPrint('[secure_kv] WARN delete("$key") >3s (still pending)');
      }
    });
    if (AppEnv.startupDebug) debugPrint('[secure_kv] delete("$key") start');
    try {
      await _storage.delete(key: key);
      if (AppEnv.startupDebug) {
        debugPrint('[secure_kv] delete("$key") done in ${sw.elapsedMilliseconds}ms');
      }
    } finally {
      warn.cancel();
    }
  }

  Future<void> deleteAll() async {
    final sw = Stopwatch()..start();
    Timer? warn;
    warn = Timer(const Duration(seconds: 3), () {
      if (AppEnv.startupDebug) {
        debugPrint('[secure_kv] WARN deleteAll() >3s (still pending)');
      }
    });
    if (AppEnv.startupDebug) debugPrint('[secure_kv] deleteAll() start');
    try {
      await _storage.deleteAll();
      if (AppEnv.startupDebug) {
        debugPrint('[secure_kv] deleteAll() done in ${sw.elapsedMilliseconds}ms');
      }
    } finally {
      warn.cancel();
    }
  }
}

