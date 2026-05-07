import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../domain/order_create_request.dart';
import '../domain/order_create_response.dart';
import '../domain/order_detail.dart';
import '../domain/order_summary.dart';

class OrdersRepository {
  OrdersRepository(this._ref);
  final Ref _ref;

  Future<OrderCreateResponse> createOrder(OrderCreateRequest req) {
    return _ref
        .read(apiClientProvider)
        .postJson<OrderCreateResponse>(
          '/orders',
          body: req.toJson(),
          decode: (json) =>
              OrderCreateResponse.fromJson(json as Map<String, dynamic>),
        );
  }

  Future<OrderDetail> getById(String id) {
    return _ref
        .read(apiClientProvider)
        .getJson<OrderDetail>(
          '/orders/$id',
          decode: (json) => OrderDetail.fromJson(json as Map<String, dynamic>),
        );
  }

  Future<List<OrderSummary>> listMine() {
    return _ref
        .read(apiClientProvider)
        .getJson<List<OrderSummary>>(
          '/orders',
          decode: (json) {
            final list = (json as List).cast<dynamic>();
            return list
                .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
                .toList(growable: false);
          },
        );
  }

  Future<void> updateStatus({
    required String orderId,
    required String action,
  }) async {
    await _ref
        .read(apiClientProvider)
        .postJson<void>('/orders/$orderId/status', body: {'action': action});
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref),
);
