class AppEnv {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const startupDebug = bool.fromEnvironment(
    'STARTUP_DEBUG',
    defaultValue: false,
  );
}

