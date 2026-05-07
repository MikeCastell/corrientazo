import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';

class CookMealsRepository {
  CookMealsRepository(this._ref);
  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<List<CookMealTemplateDto>> listMine() {
    return _api.getJson<List<CookMealTemplateDto>>(
      '/cook/meals',
      decode: (json) {
        final list = (json as List).cast<dynamic>();
        return list
            .map((e) => CookMealTemplateDto.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      },
    );
  }

  Future<CookMealTemplateDto> create({
    required String title,
    required String? description,
    required int basePriceCop,
    required List<String> tags,
    required String? photoUrl,
  }) {
    return _api.postJson<CookMealTemplateDto>(
      '/meals',
      body: {
        'title': title,
        'description': description,
        'basePriceCop': basePriceCop,
        'tags': tags,
        'photoUrl': photoUrl,
      },
      decode: (json) =>
          CookMealTemplateDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<CookMealTemplateDto> update(
    String mealId, {
    required String title,
    required String? description,
    required int basePriceCop,
    required List<String> tags,
    required String? photoUrl,
  }) {
    return _api.patchJson<CookMealTemplateDto>(
      '/cook/meals/$mealId',
      body: {
        'title': title,
        'description': description,
        'basePriceCop': basePriceCop,
        'tags': tags,
        'photoUrl': photoUrl,
      },
      decode: (json) =>
          CookMealTemplateDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> delete(String mealId) async {
    await _api.deleteJson('/cook/meals/$mealId');
  }

  Future<CookMealPublicationDto> publish(
    String mealId, {
    required int priceCop,
    required int stockTotal,
    required DateTime availableFrom,
    required DateTime availableTo,
    required DateTime pickupFrom,
    required DateTime pickupTo,
    bool deliveryEnabled = false,
    String? deliveryZoneId,
  }) {
    return _api.postJson<CookMealPublicationDto>(
      '/meals/$mealId/publish',
      body: {
        'priceCop': priceCop,
        'stockTotal': stockTotal,
        'availableFrom': availableFrom.toUtc().toIso8601String(),
        'availableTo': availableTo.toUtc().toIso8601String(),
        'pickupFrom': pickupFrom.toUtc().toIso8601String(),
        'pickupTo': pickupTo.toUtc().toIso8601String(),
        'deliveryEnabled': deliveryEnabled,
        'deliveryZoneId': deliveryZoneId,
      },
      decode: (json) =>
          CookMealPublicationDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<CookMealPublicationDto> updatePublication(
    String publicationId, {
    String? status,
    int? stockAvailable,
    int? stockTotal,
    int? priceCop,
  }) {
    return _api.patchJson<CookMealPublicationDto>(
      '/meal-publications/$publicationId',
      body: {
        'status': status,
        'stockAvailable': stockAvailable,
        'stockTotal': stockTotal,
        'priceCop': priceCop,
      },
      decode: (json) =>
          CookMealPublicationDto.fromJson(json as Map<String, dynamic>),
    );
  }
}

final cookMealsRepositoryProvider = Provider<CookMealsRepository>(
  (ref) => CookMealsRepository(ref),
);

class CookMealTemplateDto {
  const CookMealTemplateDto({
    required this.id,
    required this.title,
    required this.description,
    required this.basePriceCop,
    required this.photoUrl,
    required this.tags,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.latestPublication,
  });

  final String id;
  final String title;
  final String? description;
  final int basePriceCop;
  final String? photoUrl;
  final List<String> tags;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CookMealPublicationDto? latestPublication;

  factory CookMealTemplateDto.fromJson(Map<String, dynamic> json) {
    final pubs = json['publications'];
    CookMealPublicationDto? latest;
    if (pubs is List && pubs.isNotEmpty) {
      final first = pubs.first;
      if (first is Map<String, dynamic>) {
        latest = CookMealPublicationDto.fromJson(first);
      }
    }
    return CookMealTemplateDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      basePriceCop: (json['base_price_cop'] as num).toInt(),
      photoUrl: json['photo_url'] as String?,
      tags: (json['tags'] as List).cast<String>(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      latestPublication: latest,
    );
  }
}

class CookMealPublicationDto {
  const CookMealPublicationDto({
    required this.id,
    required this.mealId,
    required this.cookProfileId,
    required this.priceCop,
    required this.stockTotal,
    required this.stockAvailable,
    required this.status,
  });

  final String id;
  final String? mealId;
  final String? cookProfileId;
  final int? priceCop;
  final int? stockTotal;
  final int? stockAvailable;
  final String? status;

  factory CookMealPublicationDto.fromJson(Map<String, dynamic> json) {
    return CookMealPublicationDto(
      id: json['id'] as String,
      mealId: json['meal_id'] as String?,
      cookProfileId: json['cook_profile_id'] as String?,
      priceCop: (json['price_cop'] as num?)?.toInt(),
      stockTotal: (json['stock_total'] as num?)?.toInt(),
      stockAvailable: (json['stock_available'] as num?)?.toInt(),
      status: json['status'] as String?,
    );
  }
}
