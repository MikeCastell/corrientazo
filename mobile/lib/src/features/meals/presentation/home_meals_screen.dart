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
import '../../../core/ui/marketplace/meal_card_premium.dart';
import '../application/meals_controller.dart';

class HomeMealsScreen extends ConsumerWidget {
  const HomeMealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(mealsFeedProvider);

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
            slivers: [
              SliverToBoxAdapter(child: _FeedHeader(onLogout: () => ref.read(authControllerProvider.notifier).logout())),
              if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.ramen_dining,
                    title: 'Nada por ahora',
                    subtitle: 'Vuelve en unos minutos. Los corrientazos cambian rápido.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => MealCardPremium(
                      id: items[i].id,
                      priceCop: items[i].priceCop,
                      stockAvailable: items[i].stockAvailable,
                      onTap: () => context.go('${const HomeRoute().location}/meals/${items[i].id}'),
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

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
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
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
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
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          sliver: SliverList.separated(
            itemCount: 6,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return AppShimmer(
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
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
