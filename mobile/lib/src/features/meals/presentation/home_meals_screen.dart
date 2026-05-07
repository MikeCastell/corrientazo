import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/states/app_shimmer.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../application/meals_controller.dart';
import '../domain/meal_publication.dart';

class HomeMealsScreen extends ConsumerWidget {
  const HomeMealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(mealsFeedProvider);

    return AppScaffold(
      title: 'Disponible hoy',
      trailing: IconButton(
        onPressed: () => ref.read(authControllerProvider.notifier).logout(),
        icon: const Icon(Icons.logout),
        tooltip: 'Salir',
      ),
      body: feed.when(
        loading: () => const _MealsLoading(),
        error: (e, _) => _CenteredState(
          title: 'No pudimos cargar el feed',
          subtitle: e.toString(),
          actionLabel: 'Reintentar',
          onAction: () => ref.refresh(mealsFeedProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.refresh(mealsFeedProvider.future),
          child: items.isEmpty
              ? const _CenteredState(
                  title: 'Nada por ahora',
                  subtitle: 'Vuelve en unos minutos. Los corrientazos cambian rápido.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _MealCard(item: items[i]),
                ),
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.item});
  final MealPublication item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('${const HomeRoute().location}/meals/${item.id}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.restaurant, color: AppColors.brand),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Corrientazo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '\$${item.priceCop} COP · Cupos: ${item.stockAvailable}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _MealsLoading extends StatelessWidget {
  const _MealsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return AppShimmer(
          child: Container(
            height: 84,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      },
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.title,
    this.subtitle = '',
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.brand),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

