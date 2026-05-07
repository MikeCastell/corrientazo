import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/food/colombian_food_mock.dart';
import '../../../core/networking/api_exception.dart';
import '../../../core/ux/milestone_celebration.dart';
import '../../../core/ux/ux_milestones_store.dart';
import '../application/cook_meals_controller.dart';
import '../domain/cook_meal.dart';

class CookCreateMealScreen extends ConsumerStatefulWidget {
  const CookCreateMealScreen({super.key, this.editMealId});

  final String? editMealId;

  @override
  ConsumerState<CookCreateMealScreen> createState() =>
      _CookCreateMealScreenState();
}

class _CookCreateMealScreenState extends ConsumerState<CookCreateMealScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController(text: '12000');
  final _stock = TextEditingController(text: '10');

  String _fulfillment = 'PICKUP';
  final List<String> _ingredients = ['Arroz', 'Proteína', 'Ensalada'];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateIfEditing());
  }

  void _hydrateIfEditing() {
    final id = widget.editMealId;
    if (id == null) return;
    final meals = ref
        .read(cookMealsControllerProvider)
        .maybeWhen(data: (v) => v, orElse: () => null);
    final found = meals?.where((m) => m.id == id).firstOrNull;
    if (found == null) return;

    _title.text = found.title;
    _description.text = found.description;
    _price.text = found.priceCop.toString();
    _stock.text = found.stock.toString();
    _fulfillment = found.fulfillmentType;
    _ingredients
      ..clear()
      ..addAll(found.ingredients);
    setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  CookMeal _buildDraft({required String id, required DateTime createdAt}) {
    final price = int.tryParse(_price.text.trim()) ?? 0;
    final stock = int.tryParse(_stock.text.trim()) ?? 0;
    final status = stock <= 0 ? CookMealStatus.soldOut : CookMealStatus.paused;
    return CookMeal(
      id: id,
      publicationId: null,
      title: _title.text.trim().isEmpty
          ? 'Nuevo corrientazo'
          : _title.text.trim(),
      description: _description.text.trim(),
      priceCop: price <= 0 ? 12000 : price,
      stock: stock < 0 ? 0 : stock,
      fulfillmentType: _fulfillment,
      ingredients: List.of(_ingredients),
      status: status,
      createdAt: createdAt,
    );
  }

  Future<void> _save({required bool publish}) async {
    setState(() => _saving = true);
    HapticFeedback.selectionClick();

    try {
      final now = DateTime.now();
      final id = widget.editMealId ?? 'm_${now.millisecondsSinceEpoch}';
      final existing = ref
          .read(cookMealsControllerProvider)
          .maybeWhen(
            data: (v) => v.where((m) => m.id == id).firstOrNull,
            orElse: () => null,
          );
      final createdAt = existing?.createdAt ?? now;

      var meal = _buildDraft(id: id, createdAt: createdAt);
      if (publish) {
        meal = meal.copyWith(
          status: meal.stock <= 0
              ? CookMealStatus.soldOut
              : CookMealStatus.available,
        );
      }

      await ref.read(cookMealsControllerProvider.notifier).upsert(meal);
      if (!mounted) return;

      if (publish) {
        final store = ref.read(uxMilestonesStoreProvider);
        if (!store.celebratedCookFirstPublish) {
          await showMilestoneCelebration(
            context,
            MilestoneKind.cookFirstPublish,
          );
          await store.markCookFirstPublishCelebrated();
          if (!mounted) return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publish ? 'Comida publicada' : 'Borrador guardado'),
        ),
      );
      context.go(const CookMealsRoute().location);
    } catch (e) {
      if (!mounted) return;

      final msg = switch (e) {
        UnauthorizedException() =>
          'Tu sesión expiró. Vuelve a iniciar sesión e inténtalo de nuevo.',
        ApiErrorResponseException(code: final c, message: final m) => '$m ($c)',
        NetworkException(message: final m) =>
          'No pudimos conectar con el servidor. $m',
        _ =>
          publish
              ? 'No pudimos publicar. Intenta de nuevo.'
              : 'No pudimos guardar. Intenta de nuevo.',
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildDraft(
      id: widget.editMealId ?? 'preview',
      createdAt: DateTime.now(),
    );

    return AppScaffold(
      title: widget.editMealId == null ? 'Crear comida' : 'Editar comida',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (widget.editMealId == null) ...[
            Text(
              'Plantillas rápidas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Elige una base colombiana real y ajusta en segundos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TemplateChip(
                  label: 'Corrientazo res',
                  onTap: _saving ? null : () => _applyTemplate('tpl-res'),
                ),
                _TemplateChip(
                  label: 'Ajiaco',
                  onTap: _saving ? null : () => _applyTemplate('tpl-ajiaco'),
                ),
                _TemplateChip(
                  label: 'Lentejas',
                  onTap: _saving ? null : () => _applyTemplate('tpl-lentejas'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _PreviewCard(meal: preview),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _title,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nombre'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio (COP)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FulfillmentSelector(
            value: _fulfillment,
            onChanged: _saving
                ? null
                : (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _fulfillment = v);
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ingredientes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._ingredients.map(
                (x) => _IngredientPill(
                  label: x,
                  onRemove: _saving
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _ingredients.remove(x));
                        },
                ),
              ),
              _AddIngredientButton(
                enabled: !_saving,
                onAdd: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _ingredients.add(v));
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _saving ? null : () => _save(publish: false),
                  child: Text(_saving ? 'Guardando…' : 'Guardar borrador'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : () => _save(publish: true),
                  child: Text(_saving ? 'Publicando…' : 'Publicar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sin pagos · Sin realtime · Solo estructura operativa.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  void _applyTemplate(String seed) {
    HapticFeedback.selectionClick();
    final f = ColombianFoodMock.forMeal(seed);
    _title.text = f.title;
    _description.text = f.description;
    _ingredients
      ..clear()
      ..addAll(f.ingredients.take(5));
    setState(() {});
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.accentDeep,
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.meal});
  final CookMeal meal;

  @override
  Widget build(BuildContext context) {
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.secondary.withValues(alpha: 0.16),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.photo_camera_outlined, color: Colors.white),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  meal.description.isEmpty
                      ? 'Descripción (opcional)'
                      : meal.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Pill(label: '\$${meal.priceCop}', tone: AppColors.primary),
                    const SizedBox(width: 8),
                    _Pill(
                      label: 'Stock ${meal.stock}',
                      tone: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      label: meal.fulfillmentType,
                      tone: AppColors.accentDeep,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.tone});
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

class _FulfillmentSelector extends StatelessWidget {
  const _FulfillmentSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String>? onChanged;

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
            'Tipo de entrega',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(
                label: 'Recoger',
                selected: value == 'PICKUP',
                tone: AppColors.secondary,
                onTap: onChanged == null ? null : () => onChanged!('PICKUP'),
              ),
              _Choice(
                label: 'Domicilio',
                selected: value == 'DELIVERY',
                tone: AppColors.primary,
                onTap: onChanged == null ? null : () => onChanged!('DELIVERY'),
              ),
              _Choice(
                label: 'Ambos',
                selected: value == 'BOTH',
                tone: AppColors.accentDeep,
                onTap: onChanged == null ? null : () => onChanged!('BOTH'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.tone,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? tone.withValues(alpha: 0.12) : Colors.transparent;
    final border = selected
        ? tone.withValues(alpha: 0.18)
        : Theme.of(context).dividerColor;
    final color = selected
        ? tone
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _IngredientPill extends StatelessWidget {
  const _IngredientPill({required this.label, required this.onRemove});
  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(99),
            child: Icon(
              Icons.close,
              size: 18,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddIngredientButton extends StatelessWidget {
  const _AddIngredientButton({required this.enabled, required this.onAdd});
  final bool enabled;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              final v = await showDialog<String>(
                context: context,
                builder: (context) => const _AddIngredientDialog(),
              );
              if (v == null) return;
              final t = v.trim();
              if (t.isEmpty) return;
              onAdd(t);
            },
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
        ),
        child: Text(
          '+ Ingrediente',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.accentDeep,
          ),
        ),
      ),
    );
  }
}

class _AddIngredientDialog extends StatefulWidget {
  const _AddIngredientDialog();

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar ingrediente'),
      content: TextField(
        controller: _c,
        decoration: const InputDecoration(labelText: 'Ej: Lentejas'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_c.text),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
