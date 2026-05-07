import 'package:flutter/material.dart';

class AppElevation {
  static List<BoxShadow> e1(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> e2(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.12),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ];
}

