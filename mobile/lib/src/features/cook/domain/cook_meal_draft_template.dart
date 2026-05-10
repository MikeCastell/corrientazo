import 'dart:convert';

/// Borrador guardado localmente por el cocinero (no es el modelo de comida del API).
class CookMealDraftTemplate {
  const CookMealDraftTemplate({
    required this.id,
    required this.label,
    required this.title,
    required this.description,
    required this.priceCop,
    required this.stock,
    required this.fulfillmentType,
    required this.ingredients,
    required this.savedAt,
  });

  final String id;
  final String label;
  final String title;
  final String description;
  final int priceCop;
  final int stock;
  final String fulfillmentType;
  final List<String> ingredients;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'title': title,
        'description': description,
        'priceCop': priceCop,
        'stock': stock,
        'fulfillmentType': fulfillmentType,
        'ingredients': ingredients,
        'savedAt': savedAt.toIso8601String(),
      };

  factory CookMealDraftTemplate.fromJson(Map<String, dynamic> json) {
    final ing = json['ingredients'];
    return CookMealDraftTemplate(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceCop: (json['priceCop'] as num?)?.toInt() ?? 12000,
      stock: (json['stock'] as num?)?.toInt() ?? 10,
      fulfillmentType: json['fulfillmentType'] as String? ?? 'PICKUP',
      ingredients: ing is List
          ? ing.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static String encodeList(List<CookMealDraftTemplate> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<CookMealDraftTemplate> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CookMealDraftTemplate.fromJson)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }
}
