// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_meal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookMeal _$CookMealFromJson(Map<String, dynamic> json) => CookMeal(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  priceCop: (json['price_cop'] as num).toInt(),
  stock: (json['stock'] as num).toInt(),
  fulfillmentType: json['fulfillment_type'] as String,
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  status: $enumDecode(_$CookMealStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CookMealToJson(CookMeal instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'price_cop': instance.priceCop,
  'stock': instance.stock,
  'fulfillment_type': instance.fulfillmentType,
  'ingredients': instance.ingredients,
  'status': _$CookMealStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$CookMealStatusEnumMap = {
  CookMealStatus.available: 'AVAILABLE',
  CookMealStatus.paused: 'PAUSED',
  CookMealStatus.soldOut: 'SOLD_OUT',
};
