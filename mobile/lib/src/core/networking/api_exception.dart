sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException() : super('Unauthorized');
}

class ApiErrorResponseException extends ApiException {
  const ApiErrorResponseException({
    required this.code,
    required String message,
  }) : super(message);

  final String code;
}

