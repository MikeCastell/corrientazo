import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../design/tokens/app_colors.dart';

class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.borderDark : const Color(0xFFEEF2FF);
    final highlight = isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: child,
    );
  }
}
