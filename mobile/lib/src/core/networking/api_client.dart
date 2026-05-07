import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env/app_env.dart';
import 'api_exception.dart';
import 'auth_token_store.dart';
import 'token_pair.dart';

class ApiClient {
  ApiClient(this._ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppEnv.apiBaseUrl}/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tokens = await _ref.read(authTokenStoreProvider).read();
          if (tokens != null) {
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          // Only handle 401 once per request
          final status = err.response?.statusCode;
          final req = err.requestOptions;
          final alreadyRetried = req.extra['retried'] == true;

          if (status == 401 && !alreadyRetried) {
            try {
              final newPair = await _refreshToken();
              if (newPair == null) {
                await _ref.read(authTokenStoreProvider).clear();
                return handler.reject(err);
              }

              req.extra['retried'] = true;
              req.headers['Authorization'] = 'Bearer ${newPair.accessToken}';
              final cloned = await _dio.fetch(req);
              return handler.resolve(cloned);
            } catch (_) {
              await _ref.read(authTokenStoreProvider).clear();
              return handler.reject(err);
            }
          }

          handler.next(err);
        },
      ),
    );
  }

  final Ref _ref;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<TokenPair?> _refreshToken() async {
    // Mutex to avoid refresh storms
    if (_refreshing != null) return _refreshing;
    _refreshing = _doRefresh().whenComplete(() => _refreshing = null);
    return _refreshing;
  }

  Future<TokenPair?> _doRefresh() async {
    final store = _ref.read(authTokenStoreProvider);
    final tokens = await store.read();
    if (tokens == null) return null;

    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': tokens.refreshToken},
      options: Options(headers: {'Authorization': null}),
    );

    final data = resp.data;
    if (data == null) return null;
    final pair = TokenPair.fromJson(data);
    await store.write(pair);
    return pair;
  }

  Future<T> getJson<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic json)? decode,
  }) async {
    try {
      final r = await _dio.get<dynamic>(path, queryParameters: query);
      return decode != null ? decode(r.data) : r.data as T;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<T> postJson<T>(
    String path, {
    Object? body,
    T Function(dynamic json)? decode,
  }) async {
    try {
      final r = await _dio.post<dynamic>(path, data: body);
      return decode != null ? decode(r.data) : r.data as T;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  ApiException _mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkException('Network timeout');
    }
    final status = e.response?.statusCode;
    if (status == 401) return const UnauthorizedException();

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        final code = err['code']?.toString() ?? 'API_ERROR';
        final msg = err['message']?.toString() ?? 'Request failed';
        return ApiErrorResponseException(code: code, message: msg);
      }
    }
    return NetworkException(e.message ?? 'Request failed');
  }

  Future<TokenPair?>? _refreshing;
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));

