// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_publication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealPublication _$MealPublicationFromJson(Map<String, dynamic> json) =>
    MealPublication(
      id: json['id'] as String,
      mealId: json['meal_id'] as String,
      cookProfileId: json['cook_profile_id'] as String,
      priceCop: (json['price_cop'] as num).toInt(),
      stockAvailable: (json['stock_available'] as num).toInt(),
      availableFrom: DateTime.parse(json['available_from'] as String),
      availableTo: DateTime.parse(json['available_to'] as String),
      pickupFrom: DateTime.parse(json['pickup_from'] as String),
      pickupTo: DateTime.parse(json['pickup_to'] as String),
      title: json['title'] as String?,
      photoUrl: json['photo_url'] as String?,
      cookName: json['cook_name'] as String?,
      cookAvatarUrl: json['cook_avatar_url'] as String?,
    );

Map<String, dynamic> _$MealPublicationToJson(MealPublication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'meal_id': instance.mealId,
      'cook_profile_id': instance.cookProfileId,
      'price_cop': instance.priceCop,
      'stock_available': instance.stockAvailable,
      'available_from': instance.availableFrom.toIso8601String(),
      'available_to': instance.availableTo.toIso8601String(),
      'pickup_from': instance.pickupFrom.toIso8601String(),
      'pickup_to': instance.pickupTo.toIso8601String(),
      'title': instance.title,
      'photo_url': instance.photoUrl,
      'cook_name': instance.cookName,
      'cook_avatar_url': instance.cookAvatarUrl,
    };
