import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.text;
    final text2Color = isDark ? AppColors.text2Dark : AppColors.text2;

    final base = Typography.material2021().black;
    final t = base.apply(
      bodyColor: textColor,
      displayColor: textColor,
      decorationColor: text2Color,
    );

    // More cinematic hierarchy (no extra font deps).
    return t.copyWith(
      displayLarge: t.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
        height: 1.03,
      ),
      displayMedium: t.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        height: 1.06,
      ),
      headlineLarge: t.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.9,
        height: 1.08,
      ),
      headlineMedium: t.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        height: 1.10,
      ),
      headlineSmall: t.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
        height: 1.12,
      ),
      titleLarge: t.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.35,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.20,
      ),
      labelLarge: t.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.10,
      ),
    );
  }
}

