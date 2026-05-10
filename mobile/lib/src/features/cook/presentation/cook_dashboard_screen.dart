import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/states/app_empty_state.dart';
import '../../../core/ui/states/app_loading_center.dart';
import '../../../core/routing/app_router.dart';
import '../application/cook_meals_controller.dart';
import '../application/cook_orders_controller.dart';
import '../application/cook_profile_controller.dart';
import '../data/cook_profile_repository.dart';
import '../domain/cook_meal.dart';
import '../../orders/domain/order_summary.dart';
import 'widgets/cook_getting_started_card.dart';

bool _profileFeelsComplete(CookProfileDto p) {
  final bioOk = (p.bio ?? '').trim().length >= 12;
  final avatarOk = (p.userAvatarUrl ?? '').trim().isNotEmpty;
  return bioOk || avatarOk;
}

/// Completed / cancelled / refunded — not "por atender" en el dashboard.
bool _isTerminalOrderStatus(String raw) {
  final s = raw.toUpperCase();
  if (s == 'DELIVERED' || s == 'PICKED_UP' || s == 'REFUNDED') return true;
  if (s.startsWith('CANCELLED')) return true;
  return false;
}

bool _isActiveOrder(OrderSummary o) => !_isTerminalOrderStatus(o.status);

class CookDashboardScreen extends ConsumerWidget {
  const CookDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(cookMealsControllerProvider);
    final orders = ref.watch(cookOrdersControllerProvider);
    final profile = ref.watch(cookProfileControllerProvider);

    return AppScaffold(
      title: 'Dashboard',
      body: meals.when(
        loading: () => const AppLoadingCenter(message: 'Cargando tu cocina…'),
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'No pudimos cargar tu panel',
          subtitle: e.toString(),
          actionLabel: 'Reintentar',
          onAction: () =>
              ref.read(cookMealsControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          return orders.when(
            loading: () =>
                const AppLoadingCenter(message: 'Sincronizando pedidos…'),
            error: (e, _) => AppEmptyState(
              icon: Icons.error_outline,
              title: 'No pudimos cargar pedidos',
              subtitle: e.toString(),
              actionLabel: 'Reintentar',
              onAction: () =>
                  ref.read(cookOrdersControllerProvider.notifier).refresh(),
            ),
            data: (orderItems) {
              return profile.when(
                loading: () =>
                    const AppLoadingCenter(message: 'Cargando tu perfil…'),
                error: (e, _) => AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'No pudimos cargar tu perfil',
                  subtitle: e.toString(),
                  actionLabel: 'Reintentar',
                  onAction: () => ref
                      .read(cookProfileControllerProvider.notifier)
                      .refresh(),
                ),
                data: (prof) {
                  final active = items.where((m) => m.isActive).length;
                  final paused = items
                      .where((m) => m.status == CookMealStatus.paused)
                      .length;
                  final soldOut = items
                      .where((m) => m.status == CookMealStatus.soldOut)
                      .length;
                  final hasPublished = items.any(
                    (m) => m.publicationId != null,
                  );
                  final activeOrders =
                      orderItems.where(_isActiveOrder).length;

                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Text(
                        'Operación de hoy',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Aquí ves lo que importa: qué cocinas, qué piden, qué falta.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CookGettingStartedCard(
                        hasPublishedMeal: hasPublished,
                        profileFeelsComplete: _profileFeelsComplete(prof),
                        hasOrders: orderItems.isNotEmpty,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Comidas activas',
                              value: '$active',
                              subtitle: 'Publicadas y visibles',
                              icon: Icons.restaurant_menu,
                              tone: AppColors.secondary,
                              onTap: () =>
                                  context.go(const CookMealsRoute().location),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _MetricCard(
                              title: 'Pedidos activos',
                              value: '$activeOrders',
                              subtitle: activeOrders == 0
                                  ? 'Nada pendiente por ahora'
                                  : 'Por preparar o entregar',
                              icon: Icons.inbox_outlined,
                              tone: AppColors.primary,
                              onTap: () =>
                                  context.go(const CookOrdersRoute().location),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Platos pausados',
                              value: '$paused',
                              subtitle: 'No visibles',
                              icon: Icons.pause_circle_outline,
                              tone: AppColors.accentDeep,
                              onTap: () =>
                                  context.go(const CookMealsRoute().location),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _MetricCard(
                              title: 'Agotadas',
                              value: '$soldOut',
                              subtitle: 'Sin stock',
                              icon: Icons.bolt,
                              tone: AppColors.warning,
                              onTap: () =>
                                  context.go(const CookMealsRoute().location),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _CtaCard(
                        title: items.isEmpty
                            ? 'Crea tu primera comida'
                            : 'Crea una nueva comida',
                        subtitle:
                            'Título, precio, stock e ingredientes. Publica en segundos.',
                        primaryLabel: 'Crear comida',
                        onPrimary: () =>
                            context.go(const CookCreateMealRoute().location),
                        secondaryLabel: 'Ver mis comidas',
                        onSecondary: () =>
                            context.go(const CookMealsRoute().location),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tone,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
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
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: tone.withValues(alpha: 0.18)),
                    ),
                    child: Icon(icon, color: tone),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: tone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  const _CtaCard({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimary,
                  child: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
