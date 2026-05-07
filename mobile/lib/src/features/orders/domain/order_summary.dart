import 'package:json_annotation/json_annotation.dart';

part 'order_summary.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.totalCop,
    required this.createdAt,
    required this.quantity,
    required this.fulfillmentType,
    required this.mealPublicationId,
    this.mealTitle,
    this.mealPhotoUrl,
    this.customerName,
    this.customerPhone,
    this.customerAvatarUrl,
  });

  final String id;
  final String status;
  final int totalCop;
  final DateTime createdAt;

  final int quantity;
  final String fulfillmentType; // "PICKUP" | "DELIVERY"
  final String mealPublicationId;

  // Enriched fields (cook or customer list)
  final String? mealTitle;
  final String? mealPhotoUrl;

  // Cook-only enrichment (backend omits for customers)
  final String? customerName;
  final String? customerPhone;
  final String? customerAvatarUrl;

  factory OrderSummary.fromJson(Map<String, dynamic> json) =>
      _$OrderSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSummaryToJson(this);
}
