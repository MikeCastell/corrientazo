import 'dart:math';

import 'package:flutter/material.dart';

import '../design/tokens/app_colors.dart';

class FoodMock {
  const FoodMock({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.ingredients,
    required this.cookName,
    required this.badge,
    required this.imageAsset,
    required this.heroGradient,
    required this.heroIcon,
  });

  final String title;
  final String subtitle;
  final String description;
  final String category;
  final List<String> ingredients;
  final String cookName;
  final String badge; // e.g. "Recién hecho", "Casero", "Barrio"
  final String imageAsset;
  final LinearGradient heroGradient;
  final IconData heroIcon;
}

class ColombianFoodMock {
  static FoodMock forMeal(String seed) {
    final r = _rng(seed);
    final dish = _dishes[r.nextInt(_dishes.length)];
    final cook = _cookNames[r.nextInt(_cookNames.length)];
    final badge = _badges[r.nextInt(_badges.length)];
    final hood = _hoods[r.nextInt(_hoods.length)];
    final mood = _moods[r.nextInt(_moods.length)];

    final title = dish.title;
    final category = dish.category;
    final ingredients = dish.ingredients;

    final subtitle = '$hood · $mood';
    final description = dish.description(r);

    final heroIcon = dish.icon;
    final heroGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        dish.primary.withValues(alpha: 0.80),
        dish.secondary.withValues(alpha: 0.55),
        AppColors.accentDeep.withValues(alpha: 0.35),
      ],
    );

    return FoodMock(
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      ingredients: ingredients,
      cookName: cook,
      badge: badge,
      imageAsset: dish.imageAsset,
      heroGradient: heroGradient,
      heroIcon: heroIcon,
    );
  }

  static FoodMock fromPublished({
    required String seed,
    String? title,
    String? photoUrl,
    String? cookName,
    String? cookAvatarUrl,
  }) {
    final base = ColombianFoodMock.forMeal(seed);
    final img = (photoUrl == null || photoUrl.trim().isEmpty)
        ? base.imageAsset
        : photoUrl;
    return FoodMock(
      title: title ?? base.title,
      subtitle: base.subtitle,
      description: base.description,
      category: base.category,
      ingredients: base.ingredients,
      cookName: cookName ?? base.cookName,
      badge: base.badge,
      imageAsset: img,
      heroGradient: base.heroGradient,
      heroIcon: base.heroIcon,
    );
  }

  static Random _rng(String s) {
    var h = 2166136261;
    for (final code in s.codeUnits) {
      h ^= code;
      h = (h * 16777619) & 0x7fffffff;
    }
    return Random(h);
  }
}

class _Dish {
  const _Dish({
    required this.title,
    required this.category,
    required this.ingredients,
    required this.imageAsset,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.description,
  });

  final String title;
  final String category;
  final List<String> ingredients;
  final String imageAsset;
  final IconData icon;
  final Color primary;
  final Color secondary;
  final String Function(Random r) description;
}

const _badges = [
  'Casero',
  'Recién hecho',
  'Sazón de casa',
  'Del barrio',
  'Porción generosa',
];

const _hoods = [
  'Chapinero',
  'Teusaquillo',
  'Galerías',
  'La Soledad',
  'San Felipe',
  'NQS',
  'Centro',
  'Modelia',
];

const _moods = [
  'Almuerzo ejecutivo',
  'Corrientazo bogotano',
  'Comida de casa',
  'Para recargar',
  'Calientico',
];

const _cookNames = [
  'Doña Lili',
  'Don Jairo',
  'Cocina La 12',
  'Sazón de Barrio',
  'La Esquina Casera',
  'Cocina de Angie',
  'El Fogón del Parque',
];

final _dishes = <_Dish>[
  _Dish(
    title: 'Corrientazo de res sudada',
    category: 'Corrientazo',
    ingredients: [
      'Sopa del día',
      'Res sudada',
      'Arroz',
      'Ensalada',
      'Maduro',
      'Jugo',
    ],
    imageAsset: 'assets/food/corrientazo.png',
    icon: Icons.restaurant,
    primary: AppColors.primaryDeep,
    secondary: AppColors.secondaryDeep,
    description: (r) {
      final salsita = [
        'hogao',
        'salsita criolla',
        'ajicito suave',
      ][r.nextInt(3)];
      return 'Res sudada con $salsita, arroz suelto, ensalada fresca y jugo natural. '
          'Sabe a almuerzo de casa, pero con flow de barrio.';
    },
  ),
  _Dish(
    title: 'Ajiaco santafereño (porción generosa)',
    category: 'Sopas',
    ingredients: [
      'Pollo',
      'Papa criolla',
      'Guasca',
      'Crema',
      'Alcaparras',
      'Arepa',
    ],
    imageAsset: 'assets/food/ajiaco.png',
    icon: Icons.soup_kitchen,
    primary: AppColors.accentDeep,
    secondary: AppColors.primaryDeep,
    description: (r) =>
        'Ajiaco calientico con guasca, papa criolla y pollo desmechado. '
        'Viene con crema, alcaparras y arepita. Perfecto para Bogotá.',
  ),
  _Dish(
    title: 'Bandeja paisa (mini, bien montada)',
    category: 'Tradicional',
    ingredients: [
      'Fríjoles',
      'Arroz',
      'Chicharrón',
      'Huevo',
      'Arepa',
      'Aguacate',
    ],
    imageAsset: 'assets/food/bandeja.png',
    icon: Icons.local_dining,
    primary: AppColors.secondaryDeep,
    secondary: AppColors.accentDeep,
    description: (r) =>
        'Fríjol espesito, arroz, chicharrón crocante y huevito. '
        'Mini pero rendidora: queda uno feliz.',
  ),
  _Dish(
    title: 'Pollo guisado + arroz con coco',
    category: 'Caribe',
    ingredients: [
      'Pollo guisado',
      'Arroz con coco',
      'Ensalada',
      'Patacón',
      'Limonada',
    ],
    imageAsset: 'assets/food/caribe.png',
    icon: Icons.set_meal,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    description: (r) =>
        'Pollo guisado jugoso con arroz con coco, patacón y ensalada. '
        'Saborcito caribe, pero hecho aquí cerquita.',
  ),
  _Dish(
    title: 'Lentejas caseras + chuleta',
    category: 'Corrientazo',
    ingredients: [
      'Lentejas',
      'Chuleta',
      'Arroz',
      'Ensalada',
      'Plátano',
      'Jugo',
    ],
    imageAsset: 'assets/food/lentejas.png',
    icon: Icons.ramen_dining,
    primary: AppColors.secondary,
    secondary: AppColors.primary,
    description: (r) =>
        'Lentejita casera con buen espesor, chuleta y arroz. '
        'Clásico que salva el día: barato, rico y contundente.',
  ),
  _Dish(
    title: 'Arepas rellenas de la esquina',
    category: 'Arepas',
    ingredients: [
      'Arepa dorada',
      'Queso',
      'Pollo desmechado',
      'Hogao',
      'Aguacate',
    ],
    imageAsset: 'assets/food/arepas.png',
    icon: Icons.bakery_dining,
    primary: AppColors.accentDeep,
    secondary: AppColors.primary,
    description: (r) =>
        'Arepas doraditas, rellenas con pollo, queso y hogao. '
        'Rápidas, callejeras y con sabor de antojo de tarde.',
  ),
  _Dish(
    title: 'Combo de empanadas con ají',
    category: 'Fritos',
    ingredients: [
      'Empanadas',
      'Ají casero',
      'Limón',
      'Papa criolla',
      'Guacamole',
    ],
    imageAsset: 'assets/food/fritos.png',
    icon: Icons.fastfood,
    primary: AppColors.primary,
    secondary: AppColors.accentDeep,
    description: (r) =>
        'Empanadas crocantes con ají casero y limón. '
        'Perfectas para compartir o matar el antojo sin complicarse.',
  ),
  _Dish(
    title: 'Jugos naturales + arepita',
    category: 'Jugos',
    ingredients: ['Mango', 'Lulo', 'Mora', 'Hierbabuena', 'Arepita'],
    imageAsset: 'assets/food/jugos.png',
    icon: Icons.local_drink,
    primary: AppColors.secondary,
    secondary: AppColors.accent,
    description: (r) =>
        'Jugos naturales fríos, hechos al momento, con arepita dorada. '
        'Fresco, local y perfecto para acompañar el almuerzo.',
  ),
];
