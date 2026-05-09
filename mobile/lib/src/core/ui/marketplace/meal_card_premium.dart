import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/tokens/app_colors.dart';
import '../../design/tokens/app_elevation.dart';
import '../../design/tokens/app_radius.dart';
import '../../design/tokens/app_spacing.dart';
import 'food_image.dart';
import 'marketplace_utils.dart';
import '../../food/colombian_food_mock.dart';

class MealCardPremium extends StatefulWidget {
  const MealCardPremium({
    super.key,
    required this.id,
    required this.mealId,
    required this.priceCop,
    required this.stockAvailable,
    this.title,
    this.description,
    this.tags,
    this.photoUrl,
    this.cookName,
    this.cookAvatarUrl,
    this.cookBio,
    required this.onTap,
  });

  final String id;
  final String mealId;
  final int priceCop;
  final int stockAvailable;
  final String? title;
  final String? description;
  final List<String>? tags;
  final String? photoUrl;
  final String? cookName;
  final String? cookAvatarUrl;
  final String? cookBio;
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

    final km = MarketplaceUtils.pseudoDistanceKm(widget.id);

    final food = ColombianFoodMock.fromPublished(
      seed: widget.mealId,
      title: widget.title,
      photoUrl: widget.photoUrl,
      cookName: widget.cookName,
      cookAvatarUrl: widget.cookAvatarUrl,
    );
    final desc = (widget.description ?? '').trim();
    final tagList = (widget.tags ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList(growable: false);

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
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: border),
            boxShadow: isDark ? null : AppElevation.e2(shadowBase),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 360,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'mealHero-${widget.id}',
                  child: FoodImage(
                    asset: food.imageAsset,
                    fallbackGradient: food.heroGradient,
                    fallbackIcon: food.heroIcon,
                  ),
                ),
                // cinematic + warm darkness
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.18),
                        const Color(0xFF1A0B06).withValues(alpha: 0.60),
                        Colors.black.withValues(alpha: 0.86),
                      ],
                      stops: const [0.0, 0.35, 0.72, 1.0],
                    ),
                  ),
                ),
                // highlight flare
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.40, -0.55),
                      radius: 1.05,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  child: Row(
                    children: [
                      _Badge(
                        icon: Icons.local_fire_department_outlined,
                        label: food.badge,
                        tone: AppColors.primary,
                      ),
                      const Spacer(),
                      _Badge(
                        icon: Icons.place_outlined,
                        label: '${km.toStringAsFixed(1)} km',
                        tone: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  top: 64,
                  child: _AvailabilityBadge(stock: widget.stockAvailable),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.category.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        food.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Por ${food.cookName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.74),
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (widget.stockAvailable > 0 &&
                                    widget.stockAvailable <= 3)
                                  _TagPill(
                                    label:
                                        '🔥 Últimas ${widget.stockAvailable}',
                                  ),
                                for (final t in tagList) _TagPill(label: t),
                                if (tagList.isEmpty)
                                  const _TagPill(label: 'Casero'),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _PricePill(priceCop: widget.priceCop),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSoldOut)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.62),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Text(
                            'Agotado',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
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

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white.withValues(alpha: 0.86),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        ),
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
  const _Badge({required this.icon, required this.label, required this.tone});

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
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
