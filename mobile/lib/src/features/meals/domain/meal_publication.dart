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
    required this.title,
    required this.description,
    required this.tags,
    required this.photoUrl,
    required this.cookName,
    required this.cookAvatarUrl,
    required this.cookBio,
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

  // Enriched feed fields (may be null depending on backend version)
  final String? title;
  final String? description;
  final List<String>? tags;
  final String? photoUrl;
  final String? cookName;
  final String? cookAvatarUrl;
  final String? cookBio;

  factory MealPublication.fromJson(Map<String, dynamic> json) =>
      _$MealPublicationFromJson(json);

  Map<String, dynamic> toJson() => _$MealPublicationToJson(this);
}
