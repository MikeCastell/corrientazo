import 'package:flutter/material.dart';
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
      title: 'Disponible hoy',
      body: feed.when(
        loading: () => const _MealsLoading(),
        error: (e, _) => AppEmptyState(
          icon: Icons.wifi_off_outlined,
          title: 'No pudimos cargar el feed',
          subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: () => ref.refresh(mealsFeedProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.refresh(mealsFeedProvider.future),
          child: CustomScrollView(
            // Pull-to-refresh even when content is short; avoids zero-height slivers on small screens.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _FeedHeader(
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
              const SliverToBoxAdapter(child: _VisualCategories()),
              if (items.isEmpty)
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
                )
              else ...[
                SliverToBoxAdapter(child: _FeaturedStrip(items: items)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, i) => MealCardPremium(
                      id: items[i].id,
                      mealId: items[i].mealId,
                      priceCop: items[i].priceCop,
                      stockAvailable: items[i].stockAvailable,
                      title: items[i].title,
                      photoUrl: items[i].photoUrl,
                      cookName: items[i].cookName,
                      cookAvatarUrl: items[i].cookAvatarUrl,
                      cookBio: items[i].cookBio,
                      onTap: () => context.go(
                        '${const HomeRoute().location}/meals/${items[i].id}',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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

    void onOpen() =>
        context.push(CustomerOrderDetailRoute(order.id).location);

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
                  FilledButton.tonal(
                    onPressed: onOpen,
                    child: const Text('Ver pedido'),
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

  static Widget textBlock(
    BuildContext context,
    String status,
    String eta,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pedido activo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_labelForStatus(status)} · ETA $eta',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.70),
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

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comida casera cerca de ti',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hoy · Fresco · Cupos limitados',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.brand),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Buscar corrientazo, sopa, jugo…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AppColors.brand.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    'Cerca',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealsLoading extends StatelessWidget {
  const _MealsLoading();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _FeedHeader(onLogout: () {})),
        const SliverToBoxAdapter(child: _VisualCategories()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          sliver: SliverList.separated(
            itemCount: 6,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              return AppShimmer(
                child: Container(
                  height: 360,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedStrip extends StatelessWidget {
  const _FeaturedStrip({required this.items});

  final List<MealPublication> items;

  @override
  Widget build(BuildContext context) {
    final picks = items.take(5).toList(growable: false);
    if (picks.isEmpty) return const SizedBox.shrink();

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
          Text(
            'Hoy está pesado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: picks.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final item = picks[i];
                final food = ColombianFoodMock.forMeal(item.mealId);
                return _FeaturedTile(
                  title: food.title,
                  subtitle: food.subtitle,
                  imageAsset: food.imageAsset,
                  icon: food.heroIcon,
                  gradient: food.heroGradient,
                  onTap: () => context.go(
                    '${const HomeRoute().location}/meals/${item.id}',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Explora el barrio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          width: 300,
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
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.80),
                    ],
                    stops: const [0.0, 0.55, 1.0],
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
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _VisualCategories extends StatelessWidget {
  const _VisualCategories();

  static const _items = [
    _VisualCategory(
      'Corrientazos',
      'assets/food/corrientazo.png',
      Icons.restaurant,
    ),
    _VisualCategory('Sopas', 'assets/food/ajiaco.png', Icons.soup_kitchen),
    _VisualCategory('Arepas', 'assets/food/arepas.png', Icons.bakery_dining),
    _VisualCategory('Fritos', 'assets/food/fritos.png', Icons.fastfood),
    _VisualCategory('Jugos', 'assets/food/jugos.png', Icons.local_drink),
    _VisualCategory(
      'Ejecutivos',
      'assets/food/bandeja.png',
      Icons.local_dining,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => _CategoryTile(category: _items[index]),
      ),
    );
  }
}

class _VisualCategory {
  const _VisualCategory(this.label, this.asset, this.icon);

  final String label;
  final String asset;
  final IconData icon;
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final _VisualCategory category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FoodImage(
              asset: category.asset,
              fallbackGradient: ColombianFoodMock.forMeal(
                category.label,
              ).heroGradient,
              fallbackIcon: category.icon,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
