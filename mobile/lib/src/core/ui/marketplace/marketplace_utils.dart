import 'dart:math';

/// UI-only helpers to keep the marketplace feeling premium even before
/// geo/ETA data exists in backend.
class MarketplaceUtils {
  static int pseudoEtaMinutes(String stableId) {
    final n = _stableInt(stableId);
    return 18 + (n % 22); // 18..39
  }

  static double pseudoDistanceKm(String stableId) {
    final n = _stableInt(stableId);
    final meters = 250 + (n % 1800); // 250..2049m
    return meters / 1000.0;
  }

  static int _stableInt(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = 0x1fffffff & (h + c);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= (h >> 6);
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= (h >> 11);
    h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
    return max(0, h);
  }
}
