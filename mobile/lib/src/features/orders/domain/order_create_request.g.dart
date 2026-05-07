// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderCreateRequest _$OrderCreateRequestFromJson(Map<String, dynamic> json) =>
    OrderCreateRequest(
      mealPublicationId: json['meal_publication_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      fulfillmentType: json['fulfillment_type'] as String,
      deliveryAddressId: json['delivery_address_id'] as String?,
    );

Map<String, dynamic> _$OrderCreateRequestToJson(OrderCreateRequest instance) =>
    <String, dynamic>{
      'meal_publication_id': instance.mealPublicationId,
      'quantity': instance.quantity,
      'fulfillment_type': instance.fulfillmentType,
      'delivery_address_id': instance.deliveryAddressId,
    };
