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
          onAction: () =>
              ref.read(cookMealsControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: Icons.restaurant_menu,
              title: 'Aún no has creado comidas',
              subtitle:
                  'Crea tu primer corrientazo con foto, precio y stock. Empieza a vender hoy.',
              actionLabel: 'Crear comida',
              onAction: () => context.go(const CookCreateMealRoute().location),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(cookMealsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _CookMealCard(
                meal: items[i],
                onAction: (action) async {
                  if (action == _CookMealAction.edit) {
                    context.go(
                      '${const CookCreateMealRoute().location}?edit=${items[i].id}',
                    );
                    return;
                  }

                  if (action == _CookMealAction.toggleActive) {
                    HapticFeedback.selectionClick();
                    if (items[i].publicationId == null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Este plato aún no está publicado. Entra a Editar y publícalo para poder activarlo/pausarlo.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    // Immediate feedback so we know the tap reached this handler.
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cambiando estado… (pub: ${items[i].publicationId})',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(milliseconds: 900),
                      ),
                    );

                    final next = items[i].status == CookMealStatus.available
                        ? CookMealStatus.paused
                        : CookMealStatus.available;
                    try {
                      await ref
                          .read(cookMealsControllerProvider.notifier)
                          .setStatus(items[i].id, next);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            next == CookMealStatus.paused
                                ? 'Plato pausado'
                                : 'Plato activado',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No pudimos cambiar el estado. ($e)'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    return;
                  }

                  if (action == _CookMealAction.delete) {
                    final confirmed = await _confirmDeleteMeal(
                      context,
                      title: items[i].title,
                    );
                    if (confirmed != true) return;

                    if (!context.mounted) return;
                    await _runDelete(
                      context,
                      ref,
                      mealId: items[i].id,
                      title: items[i].title,
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _CookMealAction { edit, toggleActive, delete }

class _CookMealCard extends StatelessWidget {
  const _CookMealCard({required this.meal, required this.onAction});

  final CookMeal meal;
  final ValueChanged<_CookMealAction> onAction;

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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock: ${meal.stock} · ${meal.fulfillmentType}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _StatusPill(label: statusLabel, tone: tone),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: '\$${meal.priceCop}',
                      tone: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              PopupMenuButton<_CookMealAction>(
                tooltip: 'Opciones',
                onSelected: onAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _CookMealAction.edit,
                    child: _MenuRow(icon: Icons.edit_outlined, label: 'Editar'),
                  ),
                  PopupMenuItem(
                    value: _CookMealAction.toggleActive,
                    enabled: !isSoldOut,
                    child: _MenuRow(
                      icon: isAvailable
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      label: isAvailable ? 'Pausar' : 'Activar',
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _CookMealAction.delete,
                    child: _MenuRow(
                      icon: Icons.delete_outline,
                      label: 'Eliminar…',
                      tone: AppColors.danger,
                    ),
                  ),
                ],
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: c,
          ),
        ),
      ],
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

Future<bool?> _confirmDeleteMeal(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final surface = (isDark ? AppColors.surfaceDark : AppColors.surface)
          .withValues(alpha: 0.96);

      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Eliminar plato',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '¿Eliminar “$title”? Ya no aparecerá en el marketplace.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.30),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Esto no se puede deshacer.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Eliminar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _runDelete(
  BuildContext context,
  WidgetRef ref, {
  required String mealId,
  required String title,
}) async {
  HapticFeedback.mediumImpact();

  final messenger = ScaffoldMessenger.of(context);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final surface = (isDark ? AppColors.surfaceDark : AppColors.surface)
          .withValues(alpha: 0.96);

      Future<void>.microtask(() async {
        try {
          await ref
              .read(cookMealsControllerProvider.notifier)
              .deleteMeal(mealId);
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
          HapticFeedback.selectionClick();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Plato eliminado: “$title”'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'No pudimos eliminar el plato. Intenta de nuevo. ($e)',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Eliminando “$title”…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
