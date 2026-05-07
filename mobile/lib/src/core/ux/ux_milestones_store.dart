import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/shared_preferences_provider.dart';

/// Lightweight local flags for first-time celebrations & dismissible tips (not auth).
class UxMilestonesStore {
  UxMilestonesStore(this._prefs);

  final SharedPreferences _prefs;

  static const _cookFirstPublish = 'ux_v1_cook_celebrated_first_publish';
  static const _cookFirstOrder = 'ux_v1_cook_celebrated_first_order';
  static const _cookFirstCompleted = 'ux_v1_cook_celebrated_first_completed';
  static const _customerWelcomeDismissed = 'ux_v1_customer_welcome_dismissed';

  bool get celebratedCookFirstPublish =>
      _prefs.getBool(_cookFirstPublish) ?? false;

  Future<void> markCookFirstPublishCelebrated() =>
      _prefs.setBool(_cookFirstPublish, true);

  bool get celebratedCookFirstOrder => _prefs.getBool(_cookFirstOrder) ?? false;

  Future<void> markCookFirstOrderCelebrated() =>
      _prefs.setBool(_cookFirstOrder, true);

  bool get celebratedCookFirstCompleted =>
      _prefs.getBool(_cookFirstCompleted) ?? false;

  Future<void> markCookFirstCompletedCelebrated() =>
      _prefs.setBool(_cookFirstCompleted, true);

  bool get customerWelcomeDismissed =>
      _prefs.getBool(_customerWelcomeDismissed) ?? false;

  Future<void> dismissCustomerWelcome() =>
      _prefs.setBool(_customerWelcomeDismissed, true);
}

final uxMilestonesStoreProvider = Provider<UxMilestonesStore>((ref) {
  return UxMilestonesStore(ref.watch(sharedPreferencesProvider));
});
