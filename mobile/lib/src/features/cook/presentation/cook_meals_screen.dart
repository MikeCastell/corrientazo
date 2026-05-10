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
import '../../../core/ui/states/app_loading_center.dart';
import '../application/cook_meals_controller.dart';
import '../domain/cook_meal.dart';

class CookMealsScreen extends ConsumerStatefulWidget {
  const CookMealsScreen({super.key});

  @override
  ConsumerState<CookMealsScreen> createState() => _CookMealsScreenState();
}

class _CookMealsScreenState extends ConsumerState<CookMealsScreen> {
  bool _selecting = false;
  final Set<String> _selected = {};

  void _exitSelection() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggleSelected(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  List<CookMeal> _picked(List<CookMeal> items) =>
      items.where((m) => _selected.contains(m.id)).toList();

  Future<void> _bulkPublish(List<CookMeal> items) async {
    final picked = _picked(items);
    if (picked.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text('Publicando…')),
          ],
        ),
      ),
    );
    try {
      final r =
          await ref.read(cookMealsControllerProvider.notifier).bulkPublish(picked);
      if (!mounted) return;
      nav.pop();
      _exitSelection();
      final extra = <String>[];
      if (r.skippedSoldOut > 0) {
        extra.add('${r.skippedSoldOut} agotados');
      }
      if (r.skippedNoStock > 0) {
        extra.add('${r.skippedNoStock} sin stock');
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            extra.isEmpty
                ? 'Publicados: ${r.published}'
                : 'Publicados: ${r.published} · Omitidos: ${extra.join(', ')}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2200),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        ),
      );
    } catch (e) {
      if (mounted) nav.pop();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('No pudimos publicar en masa. ($e)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _bulkPause(List<CookMeal> items) async {
    final picked = _picked(items);
    if (picked.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text('Pausando…')),
          ],
        ),
      ),
    );
    try {
      final r =
          await ref.read(cookMealsControllerProvider.notifier).bulkPause(picked);
      if (!mounted) return;
      nav.pop();
      _exitSelection();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            r.skippedNoPublication > 0
                ? 'Pausados: ${r.paused} · Sin oferta previa: ${r.skippedNoPublication}'
                : 'Pausados: ${r.paused}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2200),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        ),
      );
    } catch (e) {
      if (mounted) nav.pop();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('No pudimos pausar en masa. ($e)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _bulkDelete(List<CookMeal> items) async {
    final picked = _picked(items);
    if (picked.isEmpty) return;
    final confirmed = await _confirmBulkDelete(context, count: picked.length);
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Eliminando ${picked.length} platos…',
              ),
            ),
          ],
        ),
      ),
    );
    try {
      await ref.read(cookMealsControllerProvider.notifier).bulkDelete(
            picked.map((m) => m.id).toList(),
          );
      if (!mounted) return;
      nav.pop();
      _exitSelection();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            picked.length == 1
                ? 'Eliminado: «${picked.first.title}»'
                : '${picked.length} platos eliminados',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1600),
          dismissDirection: DismissDirection.horizontal,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        ),
      );
    } catch (e) {
      if (mounted) nav.pop();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('No pudimos eliminar todo. ($e)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(cookMealsControllerProvider);
    final hasPlates =
        meals.maybeWhen(data: (l) => l.isNotEmpty, orElse: () => false);

    return AppScaffold(
      title: _selecting ? '${_selected.length} seleccionados' : 'Platos',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPlates)
            IconButton(
              tooltip: _selecting ? 'Cerrar selección' : 'Seleccionar varios',
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selecting = !_selecting;
                  if (!_selecting) _selected.clear();
                });
              },
              icon: Icon(_selecting ? Icons.close : Icons.checklist_outlined),
            ),
          if (!_selecting)
            IconButton(
              tooltip: 'Crear',
              onPressed: () => context.go(const CookCreateMealRoute().location),
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
      bottomNavigationBar: _selecting && hasPlates
          ? _BulkActionsBar(
              selectedCount: _selected.length,
              totalCount: meals.maybeWhen(
                data: (l) => l.length,
                orElse: () => 0,
              ),
              onSelectAll: () {
                final list = meals.maybeWhen(
                  data: (l) => l,
                  orElse: () => <CookMeal>[],
                );
                setState(() => _selected
                  ..clear()
                  ..addAll(list.map((e) => e.id)));
              },
              onClearSelection: () => setState(_selected.clear),
              onPublish: () => meals.maybeWhen(
                    data: _bulkPublish,
                    orElse: () {},
                  ),
              onPause: () => meals.maybeWhen(
                    data: _bulkPause,
                    orElse: () {},
                  ),
              onDelete: () => meals.maybeWhen(
                    data: _bulkDelete,
                    orElse: () {},
                  ),
            )
          : null,
      body: meals.when(
        loading: () => const AppLoadingCenter(message: 'Trayendo tus platos…'),
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
              kicker: 'Empieza con algo que amas cocinar',
              icon: Icons.restaurant_menu,
              title: 'Tu menú empieza vacío — es normal',
              subtitle:
                  'Un nombre honesto, precio claro y cuántos vas a servir. '
                  'Publica y los vecinos ya pueden pedir.',
              actionLabel: 'Publicar mi primer plato',
              onAction: () => context.go(const CookCreateMealRoute().location),
              secondaryActionLabel: 'Ver dashboard',
              onSecondaryAction: () =>
                  context.go(const CookDashboardRoute().location),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(cookMealsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                _selecting ? 120 : AppSpacing.md,
              ),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _CookMealCard(
                meal: items[i],
                selectionMode: _selecting,
                selected: _selected.contains(items[i].id),
                onToggleSelect: () => _toggleSelected(items[i].id),
                onAction: (action) async {
                  if (action == _CookMealAction.edit) {
                    context.go(
                      CookCreateMealFormRoute.location(editMealId: items[i].id),
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

class _BulkActionsBar extends StatelessWidget {
  const _BulkActionsBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onPublish,
    required this.onPause,
    required this.onDelete,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onPublish;
  final VoidCallback onPause;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 16,
      color: scheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '$selectedCount de $totalCount',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed:
                        selectedCount >= totalCount ? null : onSelectAll,
                    child: const Text('Todos'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: selectedCount == 0 ? null : onClearSelection,
                    child: const Text('Ninguno'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: 'Publicar seleccionados',
                      child: FilledButton.tonal(
                        onPressed:
                            selectedCount == 0 ? null : onPublish,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Icon(Icons.publish_outlined, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tooltip(
                      message: 'Pausar seleccionados',
                      child: FilledButton.tonal(
                        onPressed:
                            selectedCount == 0 ? null : onPause,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            const Icon(Icons.pause_circle_outline, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tooltip(
                      message: 'Eliminar seleccionados',
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed:
                            selectedCount == 0 ? null : onDelete,
                        child: const Icon(Icons.delete_outline, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CookMealAction { edit, toggleActive, delete }

class _CookMealCard extends StatelessWidget {
  const _CookMealCard({
    required this.meal,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onAction,
  });

  final CookMeal meal;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelect;
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

    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Checkbox(
                value: selected,
                onChanged: (_) => onToggleSelect(),
              ),
            ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: selectionMode ? onToggleSelect : null,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stock: ${meal.stock} · ${meal.fulfillmentType}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.65),
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
                  ],
                ),
              ),
            ),
          ),
          if (!selectionMode) ...[
            const SizedBox(width: AppSpacing.sm),
            PopupMenuButton<_CookMealAction>(
              tooltip: 'Opciones',
              onSelected: onAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _CookMealAction.edit,
                  child:
                      _MenuRow(icon: Icons.edit_outlined, label: 'Editar'),
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
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
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

Future<bool?> _confirmBulkDelete(
  BuildContext context, {
  required int count,
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
                          'Eliminar varios platos',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                    '¿Eliminar $count platos seleccionados? '
                    'Esta acción no se puede deshacer.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.30,
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
                          child: const Text('Eliminar todos'),
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
              content: Text('Eliminado: “$title”'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 1600),
              dismissDirection: DismissDirection.horizontal,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
              duration: const Duration(seconds: 4),
              dismissDirection: DismissDirection.horizontal,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
