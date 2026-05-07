import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';

class CustomerOrdersStore {
  CustomerOrdersStore(this._ref);
  final Ref _ref;

  static const _kRecentIds = 'customer.recentOrderIds';

  Future<List<String>> getRecentOrderIds() async {
    final kv = _ref.read(secureKvStoreProvider);
    final raw = await kv.read(_kRecentIds);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> addRecentOrderId(String id) async {
    final kv = _ref.read(secureKvStoreProvider);
    final current = await getRecentOrderIds();
    final next = <String>[id, ...current.where((x) => x != id)];
    final capped = next.take(20).toList();
    await kv.write(_kRecentIds, jsonEncode(capped));
  }

  Future<void> clear() async {
    final kv = _ref.read(secureKvStoreProvider);
    await kv.delete(_kRecentIds);
  }
}

final customerOrdersStoreProvider = Provider<CustomerOrdersStore>(
  (ref) => CustomerOrdersStore(ref),
);
