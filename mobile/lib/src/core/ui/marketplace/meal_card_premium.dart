import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/tokens/app_colors.dart';
import '../../design/tokens/app_elevation.dart';
import '../../design/tokens/app_radius.dart';
import '../../design/tokens/app_spacing.dart';
import 'cook_trust_chip.dart';
import 'marketplace_utils.dart';

class MealCardPremium extends StatefulWidget {
  const MealCardPremium({
    super.key,
    required this.id,
    required this.priceCop,
    required this.stockAvailable,
    required this.onTap,
  });

  final String id;
  final int priceCop;
  final int stockAvailable;
  final VoidCallback onTap;

  @override
  State<MealCardPremium> createState() => _MealCardPremiumState();
}

class _MealCardPremiumState extends State<MealCardPremium> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final surface = Theme.of(context).colorScheme.surface;
    final shadowBase = isDark ? Colors.black : const Color(0xFF0F172A);

    final eta = MarketplaceUtils.pseudoEtaMinutes(widget.id);
    final km = MarketplaceUtils.pseudoDistanceKm(widget.id);

    final isSoldOut = widget.stockAvailable <= 0;

    return AnimatedScale(
      scale: _pressed ? 0.99 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: isSoldOut
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border),
            boxShadow: isDark ? null : AppElevation.e1(shadowBase),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image (placeholder) — future-ready for real photos.
              Hero(
                tag: 'mealHero-${widget.id}',
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryDeep.withValues(alpha: isDark ? 0.62 : 0.18),
                              AppColors.secondaryDeep.withValues(alpha: isDark ? 0.42 : 0.12),
                              AppColors.accentDeep.withValues(alpha: isDark ? 0.22 : 0.10),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.restaurant, size: 44, color: Colors.white),
                        ),
                      ),
                      // cinematic lighting
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.00),
                              Colors.black.withValues(alpha: 0.30),
                              Colors.black.withValues(alpha: 0.62),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: CookTrustChip(
                              cookName: 'Hecho cerca de ti',
                              isVerified: true,
                              sanitaryLevelLabel: 'Sanitario (próx)',
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        child: _Badge(
                          icon: Icons.timer_outlined,
                          label: '$eta min',
                          tone: AppColors.brand,
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: _Badge(
                          icon: Icons.place_outlined,
                          label: '${km.toStringAsFixed(1)} km',
                          tone: AppColors.accent,
                        ),
                      ),
                      Positioned(
                        bottom: AppSpacing.md,
                        right: AppSpacing.md,
                        child: _AvailabilityBadge(
                          stock: widget.stockAvailable,
                        ),
                      ),
                      if (isSoldOut)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.58),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                ),
                                child: Text(
                                  'Agotado',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Corrientazo del día',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Disponible hoy · Cupos limitados',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _PricePill(priceCop: widget.priceCop),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Row(
                  children: const [
                    _PickupSavingsPill(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.priceCop});
  final int priceCop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(
        '\$$priceCop',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
      ),
    );
  }
}

class _PickupSavingsPill extends StatelessWidget {
  const _PickupSavingsPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.store_mall_directory_outlined, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            'Ahorra al recoger',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final tone = stock <= 3 ? AppColors.warning : AppColors.success;
    final label = stock <= 0
        ? 'Agotado'
        : stock <= 3
            ? 'Últimos $stock'
            : 'Disponible';

    return _Badge(
      icon: stock <= 3 ? Icons.bolt : Icons.check_circle_outline,
      label: label,
      tone: tone,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tone),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: tone,
                ),
          ),
        ],
      ),
    );
  }
}

