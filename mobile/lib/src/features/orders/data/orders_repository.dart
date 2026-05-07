import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../domain/order_create_request.dart';
import '../domain/order_create_response.dart';

class OrdersRepository {
  OrdersRepository(this._ref);
  final Ref _ref;

  Future<OrderCreateResponse> createOrder(OrderCreateRequest req) {
    return _ref.read(apiClientProvider).postJson<OrderCreateResponse>(
          '/orders',
          body: req.toJson(),
          decode: (json) =>
              OrderCreateResponse.fromJson(json as Map<String, dynamic>),
        );
  }

  Future<OrderCreateResponse> getById(String id) {
    return _ref.read(apiClientProvider).getJson<OrderCreateResponse>(
          '/orders/$id',
          decode: (json) =>
              OrderCreateResponse.fromJson(json as Map<String, dynamic>),
        );
  }
}

final ordersRepositoryProvider =
    Provider<OrdersRepository>((ref) => OrdersRepository(ref));

