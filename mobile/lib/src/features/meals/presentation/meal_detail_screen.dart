import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../application/meals_controller.dart';
import '../domain/meal_publication.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/marketplace/food_image.dart';
import '../../../core/ui/marketplace/marketplace_utils.dart';
import '../../../core/food/colombian_food_mock.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/networking/api_exception.dart';
import '../../orders/application/order_flow_controller.dart';
import '../../orders/domain/order_create_request.dart';
import '../../customer/data/customer_orders_store.dart';
import 'package:go_router/go_router.dart';

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key, required this.mealPublicationId});

  final String mealPublicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(mealsFeedProvider);

    return feed.when(
      loading: () => const AppScaffold(title: '', body: _MealDetailLoading()),
      error: (e, _) => AppScaffold(
        title: '',
        body: Center(child: Text(e.toString())),
      ),
      data: (items) {
        final item = items.where((x) => x.id == mealPublicationId).firstOrNull;
        if (item == null) {
          return const AppScaffold(
            title: '',
            body: Center(child: Text('No encontrado')),
          );
        }

        final eta = MarketplaceUtils.pseudoEtaMinutes(item.id);
        final km = MarketplaceUtils.pseudoDistanceKm(item.id);
        final food = ColombianFoodMock.fromPublished(
          seed: item.mealId,
          title: item.title,
          photoUrl: item.photoUrl,
          cookName: item.cookName,
          cookAvatarUrl: item.cookAvatarUrl,
        );
        final description = (item.description ?? '').trim().isEmpty
            ? food.description
            : (item.description ?? '').trim();
        final ingredients = (item.tags == null || item.tags!.isEmpty)
            ? food.ingredients
            : item.tags!;
        final tagList = (item.tags ?? const <String>[])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .take(3)
            .toList(growable: false);
        final isSoldOut = item.stockAvailable <= 0;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroCinematic(
                  id: item.id,
                  imageAsset: food.imageAsset,
                  icon: food.heroIcon,
                  gradient: food.heroGradient,
                  title: food.title,
                  categoryUpper: food.category.toUpperCase(),
                  etaLabel: '$eta - ${eta + 10} min',
                  kmLabel: '${km.toStringAsFixed(1)} km',
                  stockAvailable: item.stockAvailable,
                  onBack: () => Navigator.of(context).maybePop(),
                  onFavorite: () {},
                  onShare: () {},
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!isSoldOut && item.stockAvailable <= 3)
                            _EditorialTagPill(
                              label: '🔥 Últimas ${item.stockAvailable}',
                              tone: AppColors.warning,
                            ),
                          if (tagList.isNotEmpty)
                            for (final t in tagList)
                              _EditorialTagPill(label: t),
                          if (tagList.isEmpty)
                            const _EditorialTagPill(label: 'Casero'),
                          _EditorialTagPill(
                            label: item.fulfillmentCustomerLabel,
                            tone: AppColors.accentDeep,
                          ),
                          const _EditorialTagPill(label: 'Recién hecho'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        food.title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              height: 1.05,
                              color: const Color(
                                0xFF241913,
                              ).withValues(alpha: 0.95),
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: const Color(
                            0xFF6B4A3A,
                          ).withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _CookIdentityCard(
                        cookName: food.cookName,
                        cookAvatarUrl: item.cookAvatarUrl,
                        cookBio: (item.cookBio ?? '').trim().isEmpty
                            ? 'Sazón casera, como en casa.'
                            : (item.cookBio ?? '').trim(),
                        onTap: () {
                          context.go(
                            PublicCookProfileRoute(item.cookProfileId).location,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _AlmaDelPlato(
                        cookName: food.cookName,
                        story: _almaStory(
                          cookName: food.cookName,
                          description: description,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          _InfoPill(
                            icon: Icons.schedule,
                            label: '$eta - ${eta + 10} min',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _InfoPill(
                            icon: Icons.place_outlined,
                            label: '${km.toStringAsFixed(1)} km',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _InfoPill(
                            icon: isSoldOut
                                ? Icons.block
                                : item.stockAvailable <= 3
                                ? Icons.bolt
                                : Icons.verified_outlined,
                            label: isSoldOut
                                ? 'Agotado'
                                : item.stockAvailable <= 3
                                ? 'Últimos'
                                : 'Disponible',
                            tone: isSoldOut
                                ? AppColors.danger
                                : item.stockAvailable <= 3
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _FulfillmentNoticeCard(publication: item),
                      _SectionCard(
                        title: 'Qué incluye',
                        child: Text(
                          description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.35),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Ingredientes',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ingredients
                              .map(_IngredientChip.new)
                              .toList(growable: false),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Confianza',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TrustLine(
                              icon: Icons.verified_outlined,
                              text: 'Identidad verificada (próx)',
                            ),
                            const SizedBox(height: 8),
                            _TrustLine(
                              icon: Icons.shield_outlined,
                              text: 'Nivel sanitario (próx)',
                            ),
                            const SizedBox(height: 8),
                            _TrustLine(
                              icon: Icons.support_agent,
                              text: 'Soporte en la app',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: _OrderFooterBar(
              priceCop: item.priceCop,
              enabled: item.stockAvailable > 0,
              onTap: () {
                HapticFeedback.selectionClick();
                _openOrderSheet(context, ref, publication: item);
              },
            ),
          ),
        );
      },
    );
  }
}

String _almaStory({required String cookName, required String description}) {
  final desc = description.trim();
  if (desc.isEmpty) {
    return 'Hoy cociné como en casa: con calma, con cariño, y pensando en que '
        'tu almuerzo llegue caliente y sabroso.';
  }
  if (desc.length <= 120) {
    return 'Este plato lo hice pensando en ese primer bocado que abraza: '
        '$desc';
  }
  return desc;
}

class _FulfillmentNoticeCard extends StatelessWidget {
  const _FulfillmentNoticeCard({required this.publication});
  final MealPublication publication;

  @override
  Widget build(BuildContext context) {
    final p = publication;
    if (p.allowsBothFulfillmentModes) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.brand.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.takeout_dining, color: AppColors.brand, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Puedes elegir recoger o domicilio al confirmar el pedido.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (p.deliveryEnabled && !p.pickupEnabled) {
      return _fulfillmentEmphasis(
        context,
        icon: Icons.delivery_dining,
        text:
            'Solo a domicilio: este plato no se recoge en el punto. No incluye recogida en el local.',
      );
    }
    return _fulfillmentEmphasis(
      context,
      icon: Icons.store_mall_directory_outlined,
      text:
          'Solo recogida: debes recoger el plato con el cocinero. No está disponible domicilio para este plato.',
    );
  }

  Widget _fulfillmentEmphasis(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentDeep, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.4,
                color: const Color(0xFF3D2A1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderFulfillmentHint extends StatelessWidget {
  const _OrderFulfillmentHint({required this.publication});
  final MealPublication publication;

  @override
  Widget build(BuildContext context) {
    final p = publication;
    final text = p.deliveryEnabled && !p.pickupEnabled
        ? 'Solo domicilio: tu pedido irá con reparto; no es para recoger en el local.'
        : 'Solo recogida: no hay envío a domicilio para este plato.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            p.deliveryEnabled && !p.pickupEnabled
                ? Icons.delivery_dining
                : Icons.store_mall_directory_outlined,
            color: AppColors.accentDeep,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlmaDelPlato extends StatelessWidget {
  const _AlmaDelPlato({required this.cookName, required this.story});

  final String cookName;
  final String story;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final ink = const Color(0xFF241913).withValues(alpha: 0.92);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: border.withValues(alpha: 0.80)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: -10,
            child: Icon(
              Icons.format_quote_rounded,
              size: 72,
              color: ink.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El Alma del Plato',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: ink.withValues(alpha: 0.90),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '“$story”',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: ink.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '— $cookName',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  color: const Color(0xFF6B4A3A).withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealDetailLoading extends StatelessWidget {
  const _MealDetailLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = (isDark ? AppColors.surfaceDark : AppColors.surface)
        .withValues(alpha: isDark ? 0.35 : 0.55);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                color: base,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.xl),
                  bottomRight: Radius.circular(AppRadius.xl),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                140,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        child: Container(
                          height: 28,
                          width: 88,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    height: 30,
                    width: 260,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 18,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 18,
                    width: 320,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    height: 92,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                  .withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCinematic extends StatelessWidget {
  const _HeroCinematic({
    required this.id,
    required this.imageAsset,
    required this.icon,
    required this.gradient,
    required this.title,
    required this.categoryUpper,
    required this.etaLabel,
    required this.kmLabel,
    required this.stockAvailable,
    required this.onBack,
    required this.onFavorite,
    required this.onShare,
  });

  final String id;
  final String imageAsset;
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String categoryUpper;
  final String etaLabel;
  final String kmLabel;
  final int stockAvailable;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonBg = (isDark ? Colors.black : Colors.white).withValues(
      alpha: isDark ? 0.18 : 0.20,
    );
    final buttonFg = (isDark ? Colors.white : Colors.black).withValues(
      alpha: isDark ? 0.92 : 0.86,
    );

    return SizedBox(
      height: 460,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppRadius.xl),
              bottomRight: Radius.circular(AppRadius.xl),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'mealHero-$id',
                  child: FoodImage(
                    asset: imageAsset,
                    fallbackGradient: gradient,
                    fallbackIcon: icon,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.18),
                        const Color(0xFF1A0B06).withValues(alpha: 0.58),
                        Colors.black.withValues(alpha: 0.86),
                      ],
                      stops: const [0.0, 0.35, 0.74, 1.0],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.55),
                      radius: 1.05,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryUpper,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.9,
                              height: 1.03,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaPill(icon: Icons.schedule, label: etaLabel),
                          _MetaPill(icon: Icons.place_outlined, label: kmLabel),
                          _MetaPill(
                            icon: stockAvailable <= 0
                                ? Icons.block
                                : stockAvailable <= 3
                                ? Icons.bolt
                                : Icons.check_circle_outline,
                            label: stockAvailable <= 0
                                ? 'Agotado'
                                : stockAvailable <= 3
                                ? 'Últimos $stockAvailable'
                                : 'Disponible',
                            tone: stockAvailable <= 0
                                ? AppColors.danger
                                : stockAvailable <= 3
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: topPad + 10,
            child: Row(
              children: [
                _OverlayIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  background: buttonBg,
                  foreground: buttonFg,
                  onTap: onBack,
                ),
                const Spacer(),
                _OverlayIconButton(
                  icon: Icons.favorite_border_rounded,
                  background: buttonBg,
                  foreground: buttonFg,
                  onTap: onFavorite,
                ),
                const SizedBox(width: 10),
                _OverlayIconButton(
                  icon: Icons.ios_share_rounded,
                  background: buttonBg,
                  foreground: buttonFg,
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Material(
        color: background,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: foreground, size: 18),
          ),
        ),
      ),
    );
  }
}

class _EditorialTagPill extends StatelessWidget {
  const _EditorialTagPill({required this.label, this.tone});

  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final t = tone ?? AppColors.brand;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = t.withValues(alpha: isDark ? 0.16 : 0.10);
    final border = t.withValues(alpha: isDark ? 0.26 : 0.16);
    final fg = t.withValues(alpha: 0.92);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.1,
          color: fg,
        ),
      ),
    );
  }
}

class _CookIdentityCard extends StatelessWidget {
  const _CookIdentityCard({
    required this.cookName,
    required this.cookAvatarUrl,
    required this.cookBio,
    required this.onTap,
  });

  final String cookName;
  final String? cookAvatarUrl;
  final String cookBio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: border.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.035),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                  foregroundImage: (cookAvatarUrl ?? '').trim().isEmpty
                      ? null
                      : NetworkImage(cookAvatarUrl!),
                  child: const Icon(Icons.person, color: AppColors.brand),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.90),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hecho hoy por $cookName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cookBio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.25,
                      color: const Color(0xFF6B4A3A).withValues(alpha: 0.74),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? AppColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderFooterBar extends StatelessWidget {
  const _OrderFooterBar({
    required this.priceCop,
    required this.enabled,
    required this.onTap,
  });

  final int priceCop;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: border.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.06),
              blurRadius: 26,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.14),
                ),
              ),
              child: Text(
                _formatCop(priceCop),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: const Color(0xFF241913).withValues(alpha: 0.92),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.92),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    elevation: 0,
                  ),
                  onPressed: enabled ? onTap : null,
                  child: Text(enabled ? 'Pedir ahora' : 'Agotado'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCop(int value) {
  final raw = value.toString();
  final b = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final idxFromEnd = raw.length - i;
    b.write(raw[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) b.write('.');
  }
  return 'COP \$${b.toString()}';
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.brand,
        ),
      ),
    );
  }
}

Future<void> _openOrderSheet(
  BuildContext context,
  WidgetRef ref, {
  required MealPublication publication,
}) async {
  ref.read(orderFlowControllerProvider.notifier).reset();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OrderSheet(publication: publication),
  );
}

class _OrderSheet extends ConsumerStatefulWidget {
  const _OrderSheet({required this.publication});
  final MealPublication publication;

  @override
  ConsumerState<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends ConsumerState<_OrderSheet> {
  late String _fulfillment;
  int _quantity = 1;
  bool _loading = false;
  ApiException? _error;

  int get _maxQty {
    final s = widget.publication.stockAvailable;
    return s < 1 ? 1 : s;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.publication;
    _fulfillment = p.defaultFulfillmentForOrder;
    _quantity = 1;
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final qty = _quantity.clamp(1, _maxQty);
      final req = OrderCreateRequest(
        mealPublicationId: widget.publication.id,
        quantity: qty,
        fulfillmentType: _fulfillment,
        deliveryAddressId: null,
      );
      final order = await ref
          .read(orderFlowControllerProvider.notifier)
          .submit(req);
      if (!mounted) return;
      await ref.read(customerOrdersStoreProvider).addRecentOrderId(order.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('${const HomeRoute().location}/orders/${order.id}/success');
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;

    final err = _error;
    final isSoldOut =
        err is ApiErrorResponseException && err.code == 'ORDER_SOLD_OUT';
    final titleRaw = (widget.publication.title ?? '').trim();
    final lineTitle = titleRaw.isEmpty ? 'Plato' : titleRaw;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: (isDark ? AppColors.borderDark : AppColors.border),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tu pedido',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (widget.publication.allowsBothFulfillmentModes)
                  _Segmented(
                    value: _fulfillment,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _fulfillment = v),
                  )
                else
                  _OrderFulfillmentHint(publication: widget.publication),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.restaurant, color: AppColors.brand),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lineTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatCop(widget.publication.priceCop)} · unidad',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.58),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Text(
                            'Cantidad',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          _OrderQuantityStepper(
                            quantity: _quantity,
                            enabled: !_loading,
                            onDecrement: _quantity > 1 && !_loading
                                ? () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _quantity--);
                                  }
                                : null,
                            onIncrement:
                                _quantity < _maxQty && !_loading
                                ? () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _quantity++);
                                  }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _maxQty == 1
                            ? 'Solo queda 1 unidad disponible.'
                            : 'Máximo $_maxQty unidades (stock del cocinero).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.55),
                          height: 1.25,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          Text(
                            _formatCop(
                              widget.publication.priceCop * _quantity,
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (err != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: (isSoldOut ? AppColors.warning : AppColors.danger)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color:
                            (isSoldOut ? AppColors.warning : AppColors.danger)
                                .withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSoldOut ? Icons.bolt : Icons.error_outline,
                          color: isSoldOut
                              ? AppColors.warning
                              : AppColors.danger,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            isSoldOut
                                ? 'Se agotó justo ahora. Prueba otro corrientazo.'
                                : err.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Confirmando…' : 'Confirmar pedido'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    'Sin pagos todavía · Solo validamos el flujo',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
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

class _OrderQuantityStepper extends StatelessWidget {
  const _OrderQuantityStepper({
    required this.quantity,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final bool enabled;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: enabled ? onDecrement : null,
            icon: Icon(
              Icons.remove_rounded,
              color: onDecrement != null
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.28),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: enabled ? onIncrement : null,
            icon: Icon(
              Icons.add_rounded,
              color: onIncrement != null
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.28),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegButton(
              selected: value == 'PICKUP',
              label: 'Recoger',
              icon: Icons.store_mall_directory_outlined,
              onTap: onChanged == null ? null : () => onChanged!('PICKUP'),
            ),
          ),
          Expanded(
            child: _SegButton(
              selected: value == 'DELIVERY',
              label: 'Domicilio',
              icon: Icons.delivery_dining,
              onTap: onChanged == null ? null : () => onChanged!('DELIVERY'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.brand.withValues(alpha: 0.10)
        : Colors.transparent;
    final border = selected
        ? AppColors.brand.withValues(alpha: 0.18)
        : Colors.transparent;
    final color = selected
        ? AppColors.brand
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70);

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? AppColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 16, color: AppColors.brand),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}
