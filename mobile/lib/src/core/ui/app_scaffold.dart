import 'dart:ui';

import 'package:flutter/material.dart';

import '../design/tokens/app_colors.dart';
import '../design/tokens/app_radius.dart';
import '../design/tokens/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final Widget? trailing;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = (isDark ? AppColors.surfaceDark : AppColors.surface).withValues(alpha: 0.72);

    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: bottomNavigationBar,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: glass,
                    border: Border.all(
                      color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.7),
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (trailing != null) ...[trailing!],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 84),
          child: body,
        ),
      ),
    );
  }
}

