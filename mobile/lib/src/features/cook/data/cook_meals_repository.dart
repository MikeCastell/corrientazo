import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/json_bool.dart';

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

  Future<void> update(
    String mealId, {
    required String title,
    required String? description,
    required int basePriceCop,
    required List<String> tags,
    String? photoUrl,
  }) {
    final body = <String, dynamic>{
      'title': title,
      'basePriceCop': basePriceCop,
      'tags': tags,
    };
    if (description != null) body['description'] = description;
    if (photoUrl != null) body['photoUrl'] = photoUrl;

    return _api.patchJson<void>('/cook/meals/$mealId', body: body);
  }

  Future<void> delete(String mealId) async {
    await _api.deleteJson('/cook/meals/$mealId');
  }

  /// IA en servidor (Gemini): genera texto a partir de una foto del plato.
  Future<String> describeMealFromPhotoBytes(
    List<int> bytes, {
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final json = await _api.postMultipart<Map<String, dynamic>>(
      '/cook/meals/describe-photo',
      formData,
      decode: (j) => j as Map<String, dynamic>,
    );
    final d = json['description'];
    if (d is! String || d.trim().isEmpty) {
      throw const FormatException('Respuesta sin descripción');
    }
    return d.trim();
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
    bool pickupEnabled = true,
    String? deliveryZoneId,
    String? status,
  }) {
    // Backend defaults: pickupEnabled ?? true, deliveryEnabled ?? false.
    // Omit booleans when they match defaults so older ValidationPipe configs
    // that don't whitelist `pickupEnabled` still accept publication (recogida / ambos).
    final body = <String, dynamic>{
      'priceCop': priceCop,
      'stockTotal': stockTotal,
      'availableFrom': availableFrom.toUtc().toIso8601String(),
      'availableTo': availableTo.toUtc().toIso8601String(),
      'pickupFrom': pickupFrom.toUtc().toIso8601String(),
      'pickupTo': pickupTo.toUtc().toIso8601String(),
      if (deliveryEnabled) 'deliveryEnabled': true,
      if (!pickupEnabled) 'pickupEnabled': false,
      'deliveryZoneId': ?deliveryZoneId,
      'status': ?status,
    };

    return _api.postJson<CookMealPublicationDto>(
      '/meals/$mealId/publish',
      body: body,
      decode: (json) =>
          CookMealPublicationDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> updatePublication(
    String publicationId, {
    String? status,
    int? stockAvailable,
    int? stockTotal,
    int? priceCop,
  }) {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (stockAvailable != null) body['stockAvailable'] = stockAvailable;
    if (stockTotal != null) body['stockTotal'] = stockTotal;
    if (priceCop != null) body['priceCop'] = priceCop;

    return _api.patchJson<void>(
      '/meal-publications/$publicationId',
      body: body,
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
    this.deliveryEnabled,
    this.pickupEnabled,
  });

  final String id;
  final String? mealId;
  final String? cookProfileId;
  final int? priceCop;
  final int? stockTotal;
  final int? stockAvailable;
  final String? status;
  final bool? deliveryEnabled;
  final bool? pickupEnabled;

  factory CookMealPublicationDto.fromJson(Map<String, dynamic> json) {
    return CookMealPublicationDto(
      id: json['id'] as String,
      mealId: json['meal_id'] as String?,
      cookProfileId: json['cook_profile_id'] as String?,
      priceCop: (json['price_cop'] as num?)?.toInt(),
      stockTotal: (json['stock_total'] as num?)?.toInt(),
      stockAvailable: (json['stock_available'] as num?)?.toInt(),
      status: json['status'] as String?,
      deliveryEnabled: coerceBoolOrNull(json['delivery_enabled']),
      pickupEnabled: coerceBoolOrNull(json['pickup_enabled']),
    );
  }
}
