// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDetail _$OrderDetailFromJson(Map<String, dynamic> json) => OrderDetail(
  id: json['id'] as String,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  totalCop: (json['total_cop'] as num).toInt(),
  quantity: (json['quantity'] as num).toInt(),
  fulfillmentType: json['fulfillment_type'] as String,
  mealPublicationId: json['meal_publication_id'] as String?,
  timeline: (json['timeline'] as List<dynamic>)
      .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  notes: json['notes'] as String?,
  mealTitle: json['meal_title'] as String?,
  mealPhotoUrl: json['meal_photo_url'] as String?,
  cookName: json['cook_name'] as String?,
  cookAvatarUrl: json['cook_avatar_url'] as String?,
  cookPhone: json['cook_phone'] as String?,
  cookBio: json['cook_bio'] as String?,
  publicationStatus: json['publication_status'] as String?,
  stockAvailable: (json['stock_available'] as num?)?.toInt(),
  customerName: json['customer_name'] as String?,
  customerPhone: json['customer_phone'] as String?,
  customerAvatarUrl: json['customer_avatar_url'] as String?,
  cancelReason: json['cancel_reason'] as String?,
);

Map<String, dynamic> _$OrderDetailToJson(OrderDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'total_cop': instance.totalCop,
      'quantity': instance.quantity,
      'fulfillment_type': instance.fulfillmentType,
      'meal_publication_id': instance.mealPublicationId,
      'notes': instance.notes,
      'timeline': instance.timeline,
      'meal_title': instance.mealTitle,
      'meal_photo_url': instance.mealPhotoUrl,
      'cook_name': instance.cookName,
      'cook_avatar_url': instance.cookAvatarUrl,
      'cook_phone': instance.cookPhone,
      'cook_bio': instance.cookBio,
      'publication_status': instance.publicationStatus,
      'stock_available': instance.stockAvailable,
      'customer_name': instance.customerName,
      'customer_phone': instance.customerPhone,
      'customer_avatar_url': instance.customerAvatarUrl,
      'cancel_reason': instance.cancelReason,
    };

OrderStatusEvent _$OrderStatusEventFromJson(Map<String, dynamic> json) =>
    OrderStatusEvent(
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      actorUserId: json['actor_user_id'] as String,
    );

Map<String, dynamic> _$OrderStatusEventToJson(OrderStatusEvent instance) =>
    <String, dynamic>{
      'from_status': instance.fromStatus,
      'to_status': instance.toStatus,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'actor_user_id': instance.actorUserId,
    };
