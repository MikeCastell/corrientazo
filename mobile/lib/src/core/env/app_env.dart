class AppEnv {
  /// Raw compile-time define; prefer [apiBaseUrl] which ignores stray CLI junk after the URL.
  static const apiBaseUrlRaw = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Base URL without accidental `--dart-define=...` suffix when defines were misparsed by the shell.
  static String get apiBaseUrl {
    final s = apiBaseUrlRaw.trim();
    final i = s.indexOf(' ');
    return i > 0 ? s.substring(0, i).trim() : s;
  }

  static const startupDebug = bool.fromEnvironment(
    'STARTUP_DEBUG',
    defaultValue: false,
  );
}
