import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.text;
    final text2Color = isDark ? AppColors.text2Dark : AppColors.text2;

    final base = Typography.material2021().black;
    return base.apply(
      bodyColor: textColor,
      displayColor: textColor,
      decorationColor: text2Color,
    );
  }
}

