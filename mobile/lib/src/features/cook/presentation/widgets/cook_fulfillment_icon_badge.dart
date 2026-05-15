import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_colors.dart';

/// Iconos para PICKUP / DELIVERY / BOTH (vista cocinero, sin texto en inglés).
class CookFulfillmentIconBadge extends StatelessWidget {
  const CookFulfillmentIconBadge({
    super.key,
    required this.fulfillmentType,
    this.tone,
    this.iconSize = 18,
  });

  final String fulfillmentType;
  final Color? tone;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.accentDeep;
    final mode = fulfillmentType.toUpperCase();

    return Tooltip(
      message: _tooltip(mode),
      child: Semantics(
        label: _tooltip(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: _icons(mode, color),
        ),
      ),
    );
  }

  static String _tooltip(String mode) {
    return switch (mode) {
      'DELIVERY' => 'Solo domicilio',
      'BOTH' => 'Recoger o domicilio',
      _ => 'Solo recogida',
    };
  }

  Widget _icons(String mode, Color color) {
    final pickup = Icon(
      Icons.storefront_outlined,
      color: color,
      size: iconSize,
    );
    final delivery = Icon(
      Icons.delivery_dining_outlined,
      color: color,
      size: iconSize,
    );

    return switch (mode) {
      'DELIVERY' => delivery,
      'BOTH' => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            pickup,
            const SizedBox(width: 4),
            delivery,
          ],
        ),
      _ => pickup,
    };
  }
}
