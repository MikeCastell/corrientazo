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
    final glass = (isDark ? AppColors.surfaceDark : AppColors.surface)
        .withValues(alpha: isDark ? 0.62 : 0.72);
    final border = (isDark ? AppColors.borderDark : AppColors.border)
        .withValues(alpha: isDark ? 0.55 : 0.75);

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
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: glass,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.22 : 0.08,
                        ),
                        blurRadius: isDark ? 24 : 18,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.brand.withValues(
                          alpha: isDark ? 0.10 : 0.06,
                        ),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
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
        child: Stack(
          children: [
            // Ambient background (cheap gradient + subtle glow)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.ambientBackground(
                    Theme.of(context).brightness,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -120,
              left: -90,
              child: _GlowBlob(
                color: AppColors.primary,
                size: 260,
                alpha: isDark ? 0.14 : 0.12,
              ),
            ),
            Positioned(
              bottom: -140,
              right: -110,
              child: _GlowBlob(
                color: AppColors.secondary,
                size: 320,
                alpha: isDark ? 0.12 : 0.08,
              ),
            ),
            Positioned(
              top: 140,
              right: -120,
              child: _GlowBlob(
                color: AppColors.accent,
                size: 280,
                alpha: isDark ? 0.10 : 0.07,
              ),
            ),
            Padding(padding: const EdgeInsets.only(top: 84), child: body),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.size,
    required this.alpha,
  });

  final Color color;
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
