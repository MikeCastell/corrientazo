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
    this.deliveryEnabled = false,
    this.pickupEnabled = true,
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

  /// From publication: whether the cook offers delivery for this offer.
  @JsonKey(defaultValue: false)
  final bool deliveryEnabled;

  /// From publication: whether the cook allows pickup (false = solo domicilio).
  @JsonKey(defaultValue: true)
  final bool pickupEnabled;

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

extension MealPublicationFulfillment on MealPublication {
  /// Short label for cards and detail (customer-facing).
  String get fulfillmentCustomerLabel {
    if (deliveryEnabled && pickupEnabled) return 'Recoger o domicilio';
    if (deliveryEnabled && !pickupEnabled) return 'Solo domicilio';
    return 'Solo recogida';
  }

  /// Single mode when the cook allows only one fulfillment type.
  String get defaultFulfillmentForOrder =>
      deliveryEnabled && !pickupEnabled ? 'DELIVERY' : 'PICKUP';

  bool get allowsBothFulfillmentModes => deliveryEnabled && pickupEnabled;
}
