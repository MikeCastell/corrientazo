import 'package:json_annotation/json_annotation.dart';

part 'meal_publication.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MealPublication {
  const MealPublication({
    required this.id,
    required this.mealId,
    required this.cookProfileId,
    required this.priceCop,
    required this.stockAvailable,
    required this.availableFrom,
    required this.availableTo,
    required this.pickupFrom,
    required this.pickupTo,
  });

  final String id;
  final String mealId;
  final String cookProfileId;
  final int priceCop;
  final int stockAvailable;
  final DateTime availableFrom;
  final DateTime availableTo;
  final DateTime pickupFrom;
  final DateTime pickupTo;

  factory MealPublication.fromJson(Map<String, dynamic> json) =>
      _$MealPublicationFromJson(json);

  Map<String, dynamic> toJson() => _$MealPublicationToJson(this);
}

