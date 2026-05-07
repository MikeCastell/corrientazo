import 'package:json_annotation/json_annotation.dart';

part 'cook_meal.g.dart';

enum CookMealStatus {
  @JsonValue('AVAILABLE')
  available,
  @JsonValue('PAUSED')
  paused,
  @JsonValue('SOLD_OUT')
  soldOut,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CookMeal {
  const CookMeal({
    required this.id,
    required this.title,
    required this.description,
    required this.priceCop,
    required this.stock,
    required this.fulfillmentType,
    required this.ingredients,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final int priceCop;
  final int stock;
  final String fulfillmentType; // "PICKUP" | "DELIVERY" | "BOTH"
  final List<String> ingredients;
  final CookMealStatus status;
  final DateTime createdAt;

  bool get isActive => status == CookMealStatus.available;

  CookMeal copyWith({
    String? title,
    String? description,
    int? priceCop,
    int? stock,
    String? fulfillmentType,
    List<String>? ingredients,
    CookMealStatus? status,
  }) {
    return CookMeal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priceCop: priceCop ?? this.priceCop,
      stock: stock ?? this.stock,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      ingredients: ingredients ?? this.ingredients,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory CookMeal.fromJson(Map<String, dynamic> json) => _$CookMealFromJson(json);
  Map<String, dynamic> toJson() => _$CookMealToJson(this);
}

