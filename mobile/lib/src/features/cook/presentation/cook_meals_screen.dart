import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/states/app_empty_state.dart';
import '../application/cook_meals_controller.dart';
import '../domain/cook_meal.dart';

class CookMealsScreen extends ConsumerWidget {
  const CookMealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(cookMealsControllerProvider);

    return AppScaffold(
      title: 'Mis comidas',
      trailing: IconButton(
        tooltip: 'Crear',
        onPressed: () => context.go(const CookCreateMealRoute().location),
        icon: const Icon(Icons.add_circle_outline),
      ),
      body: meals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'No pudimos cargar tus comidas',
          subtitle: e.toString(),
          actionLabel: 'Reintentar',
          onAction: () => ref.read(cookMealsControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: Icons.restaurant_menu,
              title: 'Aún no has creado comidas',
              subtitle: 'Crea tu primer corrientazo con foto, precio y stock. Empieza a vender hoy.',
              actionLabel: 'Crear comida',
              onAction: () => context.go(const CookCreateMealRoute().location),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.read(cookMealsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _CookMealCard(
                meal: items[i],
                onToggleActive: () async {
                  HapticFeedback.selectionClick();
                  final next = items[i].status == CookMealStatus.available
                      ? CookMealStatus.paused
                      : CookMealStatus.available;
                  await ref.read(cookMealsControllerProvider.notifier).setStatus(items[i].id, next);
                },
                onEdit: () => context.go('${const CookCreateMealRoute().location}?edit=${items[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CookMealCard extends StatelessWidget {
  const _CookMealCard({
    required this.meal,
    required this.onToggleActive,
    required this.onEdit,
  });

  final CookMeal meal;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isAvailable = meal.status == CookMealStatus.available;
    final isSoldOut = meal.status == CookMealStatus.soldOut;
    final tone = isSoldOut
        ? AppColors.warning
        : isAvailable
            ? AppColors.secondary
            : AppColors.accentDeep;
    final statusLabel = isSoldOut
        ? 'Agotado'
        : isAvailable
            ? 'Disponible'
            : 'Pausado';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.14),
                  AppColors.secondary.withValues(alpha: 0.14),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock: ${meal.stock} · ${meal.fulfillmentType}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _StatusPill(label: statusLabel, tone: tone),
                    const SizedBox(width: 8),
                    _StatusPill(label: '\$${meal.priceCop}', tone: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              IconButton(
                tooltip: 'Editar',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              Switch(
                value: isAvailable,
                onChanged: isSoldOut ? null : (_) => onToggleActive(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: tone,
            ),
      ),
    );
  }
}

