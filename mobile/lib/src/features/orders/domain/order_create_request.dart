import 'package:json_annotation/json_annotation.dart';

part 'order_create_request.g.dart';

// IMPORTANT: backend expects camelCase keys (CreateOrderDto).
@JsonSerializable()
class OrderCreateRequest {
  const OrderCreateRequest({
    required this.mealPublicationId,
    required this.quantity,
    required this.fulfillmentType,
    this.deliveryAddressId,
  });

  final String mealPublicationId;
  final int quantity;
  final String fulfillmentType; // "PICKUP" | "DELIVERY"
  final String? deliveryAddressId;

  factory OrderCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCreateRequestToJson(this);
}
