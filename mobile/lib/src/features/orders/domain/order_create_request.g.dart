// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderCreateRequest _$OrderCreateRequestFromJson(Map<String, dynamic> json) =>
    OrderCreateRequest(
      mealPublicationId: json['mealPublicationId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      fulfillmentType: json['fulfillmentType'] as String,
      deliveryAddressId: json['deliveryAddressId'] as String?,
    );

Map<String, dynamic> _$OrderCreateRequestToJson(OrderCreateRequest instance) =>
    <String, dynamic>{
      'mealPublicationId': instance.mealPublicationId,
      'quantity': instance.quantity,
      'fulfillmentType': instance.fulfillmentType,
      'deliveryAddressId': instance.deliveryAddressId,
    };
