// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderSummary _$OrderSummaryFromJson(Map<String, dynamic> json) => OrderSummary(
  id: json['id'] as String,
  status: json['status'] as String,
  totalCop: (json['total_cop'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  quantity: (json['quantity'] as num).toInt(),
  fulfillmentType: json['fulfillment_type'] as String,
  mealPublicationId: json['meal_publication_id'] as String,
  mealTitle: json['meal_title'] as String?,
  mealPhotoUrl: json['meal_photo_url'] as String?,
  customerName: json['customer_name'] as String?,
  customerPhone: json['customer_phone'] as String?,
  customerAvatarUrl: json['customer_avatar_url'] as String?,
);

Map<String, dynamic> _$OrderSummaryToJson(OrderSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'total_cop': instance.totalCop,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'quantity': instance.quantity,
      'fulfillment_type': instance.fulfillmentType,
      'meal_publication_id': instance.mealPublicationId,
      'meal_title': instance.mealTitle,
      'meal_photo_url': instance.mealPhotoUrl,
      'customer_name': instance.customerName,
      'customer_phone': instance.customerPhone,
      'customer_avatar_url': instance.customerAvatarUrl,
    };
