import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/states/app_shimmer.dart';
import '../../../core/ui/states/app_empty_state.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/food/colombian_food_mock.dart';
import '../../../core/ui/marketplace/food_image.dart';
import '../../../core/ui/marketplace/meal_card_premium.dart';
import '../application/meals_controller.dart';
import '../application/customer_home_category.dart';
import '../domain/meal_publication.dart';
import '../../customer/application/customer_orders_controller.dart';
import '../../customer/presentation/widgets/customer_welcome_banner.dart';
import '../../orders/domain/order_summary.dart';

class HomeMealsScreen extends ConsumerWidget {
  const HomeMealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(mealsFeedProvider);
    final orders = ref.watch(customerOrdersControllerProvider);

    return AppScaffold(
      title: '',
      showTopBar: false,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(mealsFeedProvider.future),
        child: CustomScrollView(
          // Pull-to-refresh even when content is short; avoids zero-height slivers on small screens.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _EditorialHeader(
                onLogout: () =>
                    ref.read(authControllerProvider.notifier).logout(),
              ),
            ),
            const SliverToBoxAdapter(child: CustomerWelcomeBanner()),
            SliverToBoxAdapter(
              child: orders.maybeWhen(
                data: (s) {
                  if (s.active.isEmpty) return const SizedBox.shrink();
                  final o = s.active.first;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: _ActiveOrderBanner(order: o),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: _EditorialCategories()),
            ...feed.when(
              loading: () => const <Widget>[
                SliverToBoxAdapter(child: _MealsLoadingInline()),
              ],
              error: (e, _) => <Widget>[
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: Icons.wifi_off_outlined,
                    title: 'No pudimos cargar el feed',
                    subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
                    actionLabel: 'Reintentar',
                    onAction: () => ref.refresh(mealsFeedProvider),
                  ),
                ),
              ],
              data: (items) {
                if (items.isEmpty) {
                  return <Widget>[
                    // Avoid LayoutBuilder here: inside scroll slivers it can re-enter layout and
                    // trigger _debugRelayoutBoundaryAlreadyMarkedNeedsLayout (red screen).
                    SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final viewH = MediaQuery.sizeOf(context).height;
                          final minH = (viewH - 240).clamp(220.0, 720.0);
                          return SizedBox(
                            width: double.infinity,
                            height: minH,
                            child: AppEmptyState(
                              kicker: 'Respira — el barrio cocina a su ritmo',
                              icon: Icons.ramen_dining,
                              title: 'Hoy no hay platos publicados',
                              subtitle:
                                  'Los cocineros suben cupos nuevos durante el día. '
                                  'Vuelve en un rato o prueba refrescar.',
                              actionLabel: 'Actualizar lista',
                              onAction: () => ref.refresh(mealsFeedProvider),
                            ),
                          );
                        },
                      ),
                    ),
                  ];
                }

                final category = ref.watch(customerHomeCategoryProvider);
                final filtered =
                    mealsForCustomerCategory(items, category);

                if (filtered.isEmpty) {
                  return <Widget>[
                    SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final viewH = MediaQuery.sizeOf(context).height;
                          final minH = (viewH - 240).clamp(220.0, 720.0);
                          final isPostres =
                              category == CustomerHomeCategory.postres;
                          return SizedBox(
                            width: double.infinity,
                            height: minH,
                            child: AppEmptyState(
                              icon: isPostres
                                  ? Icons.icecream_outlined
                                  : Icons.restaurant_outlined,
                              title: isPostres
                                  ? 'No hay postres publicados'
                                  : 'No hay corrientazos en esta categoría',
                              subtitle: isPostres
                                  ? 'Prueba Corrientazos o vuelve más tarde. '
                                      'Si publicas un postre, usa palabras como '
                                      '«postre», «torta» o «dulce» en el nombre o etiquetas.'
                                  : 'Hoy puede que solo haya postres: elige la categoría Postres arriba.',
                              actionLabel: 'Actualizar lista',
                              onAction: () => ref.refresh(mealsFeedProvider),
                            ),
                          );
                        },
                      ),
                    ),
                  ];
                }

                final heading = switch (category) {
                  null => 'Explora el menú',
                  CustomerHomeCategory.postres => 'Postres',
                  CustomerHomeCategory.corrientazos => 'Corrientazos',
                };
                final sectionSubtitle = category == null
                    ? 'Filtra con Corrientazos o Postres cuando quieras.'
                    : 'Solo opciones disponibles para pedir ahora.';

                return <Widget>[
                  if (category == null)
                    SliverToBoxAdapter(child: _FeaturedStrip(items: filtered)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  heading,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sectionSubtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.58),
                                        height: 1.3,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Menú completo (próximamente).',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              'Menú completo',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.90,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, i) => MealCardPremium(
                        key: ValueKey('feed-${filtered[i].id}'),
                        id: filtered[i].id,
                        mealId: filtered[i].mealId,
                        priceCop: filtered[i].priceCop,
                        stockAvailable: filtered[i].stockAvailable,
                        title: filtered[i].title,
                        description: filtered[i].description,
                        tags: filtered[i].tags,
                        photoUrl: filtered[i].photoUrl,
                        cookName: filtered[i].cookName,
                        cookAvatarUrl: filtered[i].cookAvatarUrl,
                        cookBio: filtered[i].cookBio,
                        fulfillmentLabel:
                            filtered[i].fulfillmentCustomerLabel,
                        onTap: () => context.go(
                          '${const HomeRoute().location}/meals/${filtered[i].id}',
                        ),
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MealsLoadingInline extends StatelessWidget {
  const _MealsLoadingInline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == 2 ? 0 : AppSpacing.lg),
            child: AppShimmer(
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ActiveOrderBanner extends ConsumerWidget {
  const _ActiveOrderBanner({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = order.status.toUpperCase();
    final eta = _pseudoEtaLabel(order.createdAt, status);
    final narrow = MediaQuery.sizeOf(context).width < 360;

    void onOpen() => context.push(CustomerOrderDetailRoute(order.id).location);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brand.withValues(alpha: 0.16),
              AppColors.primary.withValues(alpha: 0.10),
              Theme.of(context).colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      leading(context),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: textBlock(context, status, eta)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.tonal(
                    onPressed: onOpen,
                    child: const Text('Ver pedido'),
                  ),
                ],
              )
            : Row(
                children: [
                  leading(context),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: textBlock(context, status, eta)),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 140,
                    height: 44,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: Size.zero,
                      ),
                      onPressed: onOpen,
                      child: const Text('Ver pedido'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static Widget leading(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: AppColors.brand.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
    ),
    child: const Icon(Icons.receipt_long, color: AppColors.brand),
  );

  static Widget textBlock(BuildContext context, String status, String eta) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pedido activo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            '${_labelForStatus(status)} · ETA $eta',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

String _labelForStatus(String s) {
  switch (s) {
    case 'INIT':
      return 'Nuevo';
    case 'CONFIRMED':
      return 'Confirmado';
    case 'PREPARING':
      return 'Preparando';
    case 'READY_FOR_PICKUP':
      return 'Listo';
    case 'DELIVERED':
    case 'PICKED_UP':
      return 'Entregado';
    default:
      return s;
  }
}

String _pseudoEtaLabel(DateTime createdAt, String status) {
  final mins = DateTime.now().difference(createdAt).inMinutes.abs();
  if (status == 'READY_FOR_PICKUP' ||
      status == 'PICKED_UP' ||
      status == 'DELIVERED') {
    return 'Listo';
  }
  final low = 15 + (mins % 8);
  final high = low + 12;
  return '$low–$high min';
}

class _EditorialHeader extends StatelessWidget {
  const _EditorialHeader({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locationTone = const Color(0xFF6B4A3A).withValues(alpha: 0.62);
    final subtitleTone = const Color(0xFF6B4A3A).withValues(alpha: 0.78);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 6),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          MediaQuery.paddingOf(context).top + AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place_outlined, size: 16, color: locationTone),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bogotá • Almuerzos caseros cerca de ti',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: locationTone,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: onLogout,
                  icon: Icon(
                    Icons.logout,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '¿Qué se te antoja hoy? 🍲',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
                height: 1.05,
                color: scheme.onSurface.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Comida casera hecha por cooks reales cerca de ti',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: subtitleTone,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SearchBarPremium(
              placeholder: 'Busca corrientazos o postres…',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Búsqueda (próximamente).'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBarPremium extends StatelessWidget {
  const _SearchBarPremium({required this.placeholder, required this.onTap});

  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = (isDark ? AppColors.surfaceDark : AppColors.surface)
        .withValues(alpha: isDark ? 0.84 : 0.92);
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border.withValues(alpha: 0.85)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.05),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.06 : 0.05,
                ),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: AppColors.brand.withValues(alpha: 0.72),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedStrip extends StatelessWidget {
  const _FeaturedStrip({required this.items});

  final List<MealPublication> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final hero = items.first;
    final food = ColombianFoodMock.forMeal(hero.mealId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recomendados',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recomendados (próximamente).'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Ver todo',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary.withValues(alpha: 0.90),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _FeaturedHeroCard(
            title: hero.title ?? food.title,
            subtitle: (hero.description ?? food.subtitle).trim().isEmpty
                ? food.subtitle
                : (hero.description ?? food.subtitle),
            priceCop: hero.priceCop,
            imageAsset: food.imageAsset,
            icon: food.heroIcon,
            gradient: food.heroGradient,
            onTap: () =>
                context.go('${const HomeRoute().location}/meals/${hero.id}'),
          ),
        ],
      ),
    );
  }
}

class _FeaturedHeroCard extends StatelessWidget {
  const _FeaturedHeroCard({
    required this.title,
    required this.subtitle,
    required this.priceCop,
    required this.imageAsset,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int priceCop;
  final String imageAsset;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.0 : 0.08);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FoodImage(
              asset: imageAsset,
              fallbackGradient: gradient,
              fallbackIcon: icon,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.22),
                    const Color(0xFF1A0B06).withValues(alpha: 0.62),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: Row(
                children: const [
                  _FeaturedChip(label: 'Destacado'),
                  SizedBox(width: 8),
                  _FeaturedChip(label: 'Popular', translucent: true),
                ],
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
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        _formatCop(priceCop),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedChip extends StatelessWidget {
  const _FeaturedChip({required this.label, this.translucent = false});

  final String label;
  final bool translucent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: translucent
            ? Colors.white.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: translucent
            ? Border.all(color: Colors.white.withValues(alpha: 0.20))
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
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
  return '\$${b.toString()}';
}

class _EditorialCategories extends ConsumerWidget {
  const _EditorialCategories();

  static const _items = <_CategoryItem>[
    _CategoryItem(
      CustomerHomeCategory.corrientazos,
      'Corrientazos',
      Icons.restaurant,
    ),
    _CategoryItem(
      CustomerHomeCategory.postres,
      'Postres',
      Icons.icecream_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(customerHomeCategoryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _items.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = _items[index];
            final active = selected == item.category;
            return _CategoryCircle(
              label: item.label,
              icon: item.icon,
              active: active,
              onTap: () {
                if (active) return;
                HapticFeedback.selectionClick();
                ref
                    .read(customerHomeCategoryProvider.notifier)
                    .select(item.category);
              },
            );
          },
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.category, this.label, this.icon);

  final CustomerHomeCategory category;
  final String label;
  final IconData icon;
}

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseText = const Color(0xFF6B4A3A).withValues(alpha: 0.86);

    final circleBg = active
        ? AppColors.primary.withValues(alpha: 0.92)
        : (isDark ? AppColors.surfaceDark : AppColors.surface).withValues(
            alpha: isDark ? 0.76 : 0.96,
          );
    final circleBorder = active
        ? Colors.transparent
        : (isDark ? AppColors.borderDark : AppColors.border).withValues(
            alpha: 0.80,
          );
    final iconColor = active
        ? AppColors.bg
        : AppColors.brand.withValues(alpha: isDark ? 0.75 : 0.78);
    final labelColor = active
        ? baseText.withValues(alpha: 0.92)
        : baseText.withValues(alpha: 0.74);

    final baseShadow = Colors.black.withValues(alpha: isDark ? 0.0 : 0.030);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: active ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final scale = 1.0 + (0.018 * t);
        final shadowA = (0.020 + 0.040 * t).clamp(0.0, 0.070);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 210),
                curve: Curves.easeOutCubic,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: circleBorder),
                  boxShadow: [
                    BoxShadow(
                      color: baseShadow.withValues(alpha: shadowA),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                    if (active)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        blurRadius: 26,
                        offset: const Offset(0, 16),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    splashColor: Colors.white.withValues(
                      alpha: active ? 0.10 : 0.06,
                    ),
                    highlightColor: Colors.white.withValues(
                      alpha: active ? 0.06 : 0.04,
                    ),
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        opacity: active ? 1.0 : 0.90,
                        child: Icon(icon, size: 30, color: iconColor),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                opacity: active ? 1.0 : 0.92,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: active ? FontWeight.w900 : FontWeight.w800,
                    letterSpacing: -0.1,
                    color: labelColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
