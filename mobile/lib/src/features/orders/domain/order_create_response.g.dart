// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_create_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderCreateResponse _$OrderCreateResponseFromJson(Map<String, dynamic> json) =>
    OrderCreateResponse(
      id: json['id'] as String,
      status: json['status'] as String,
      totalCop: (json['total_cop'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$OrderCreateResponseToJson(
  OrderCreateResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'total_cop': instance.totalCop,
  'created_at': instance.createdAt.toIso8601String(),
};
