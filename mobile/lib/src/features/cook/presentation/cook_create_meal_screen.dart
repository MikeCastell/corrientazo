import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/networking/api_exception.dart';
import '../../../core/ux/milestone_celebration.dart';
import '../../../core/ux/ux_milestones_store.dart';
import '../application/cook_meal_draft_templates_controller.dart';
import '../application/cook_meals_controller.dart';
import '../data/cook_meals_repository.dart';
import '../domain/cook_meal.dart';
import '../domain/cook_meal_draft_template.dart';

class CookCreateMealScreen extends ConsumerStatefulWidget {
  const CookCreateMealScreen({super.key, this.editMealId, this.templateId});

  final String? editMealId;
  final String? templateId;

  @override
  ConsumerState<CookCreateMealScreen> createState() =>
      _CookCreateMealScreenState();
}

class _CookCreateMealScreenState extends ConsumerState<CookCreateMealScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();

  String _fulfillment = 'PICKUP';
  final List<String> _ingredients = [];

  bool _saving = false;
  bool _aiBusy = false;
  String? _hydratedForEditId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editMealId != null && widget.editMealId!.isNotEmpty) {
        _ensureEditHydrated();
      } else {
        _hydrateFromTemplate();
      }
    });
  }

  @override
  void didUpdateWidget(CookCreateMealScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editMealId != widget.editMealId) {
      _hydratedForEditId = null;
      _clearFormFields();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.editMealId != null && widget.editMealId!.isNotEmpty) {
          _ensureEditHydrated();
        } else {
          _hydrateFromTemplate();
        }
      });
    }
  }

  void _clearFormFields() {
    _title.clear();
    _description.clear();
    _price.clear();
    _stock.clear();
    _fulfillment = 'PICKUP';
    _ingredients.clear();
  }

  void _applyMealToForm(CookMeal found) {
    _title.text = found.title;
    _description.text = found.description;
    _price.text = found.priceCop.toString();
    _stock.text = found.stock.toString();
    _fulfillment = found.fulfillmentType;
    _ingredients
      ..clear()
      ..addAll(found.ingredients);
  }

  Future<void> _ensureEditHydrated() async {
    final id = widget.editMealId;
    if (id == null || id.isEmpty) return;
    if (_hydratedForEditId == id) return;

    var async = ref.read(cookMealsControllerProvider);
    if (!async.hasValue) {
      await ref.read(cookMealsControllerProvider.notifier).refresh();
      async = ref.read(cookMealsControllerProvider);
    }

    final found = async.value?.where((m) => m.id == id).firstOrNull;
    if (found == null) return;

    _applyMealToForm(found);
    _hydratedForEditId = id;
    if (mounted) setState(() {});
  }

  void _hydrateFromTemplate() {
    if (widget.editMealId != null && widget.editMealId!.isNotEmpty) return;
    final tid = widget.templateId;
    if (tid == null || tid.isEmpty) return;
    final templates = ref.read(cookMealDraftTemplatesProvider);
    CookMealDraftTemplate? found;
    for (final t in templates) {
      if (t.id == tid) {
        found = t;
        break;
      }
    }
    if (found == null) return;
    _applyDraftTemplate(found);
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

  bool get _isEditing =>
      widget.editMealId != null && !widget.editMealId!.startsWith('m_');

  CookMeal? _existingMeal() {
    final id = widget.editMealId;
    if (id == null) return null;
    return ref
        .read(cookMealsControllerProvider)
        .maybeWhen(
          data: (v) => v.where((m) => m.id == id).firstOrNull,
          orElse: () => null,
        );
  }

  CookMeal _buildDraft({
    required String id,
    required DateTime createdAt,
    CookMeal? existing,
    CookMealStatus? statusOverride,
  }) {
    final price = int.tryParse(_price.text.trim()) ?? 0;
    final stock = int.tryParse(_stock.text.trim()) ?? 0;
    final status = statusOverride ??
        (stock <= 0 ? CookMealStatus.soldOut : CookMealStatus.paused);
    return CookMeal(
      id: id,
      publicationId: existing?.publicationId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      priceCop: price,
      stock: stock < 0 ? 0 : stock,
      fulfillmentType: _fulfillment,
      ingredients: List.of(_ingredients),
      status: status,
      createdAt: createdAt,
    );
  }

  Future<void> _save({required bool publish}) async {
    final title = _title.text.trim();
    final price = int.tryParse(_price.text.trim());
    final stock = int.tryParse(_stock.text.trim()) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del plato.')),
      );
      return;
    }
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un precio válido mayor a cero.')),
      );
      return;
    }
    if (publish && stock < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Para publicar indica cuántas porciones hay (mínimo 1).',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.selectionClick();

    try {
      if (_isEditing) {
        await ref.read(cookMealsControllerProvider.notifier).refresh();
      }

      final now = DateTime.now();
      final id = widget.editMealId ?? 'm_${now.millisecondsSinceEpoch}';
      final existing = _existingMeal();
      final createdAt = existing?.createdAt ?? now;

      final statusOverride = publish
          ? (int.tryParse(_stock.text.trim()) ?? 0) <= 0
              ? CookMealStatus.soldOut
              : CookMealStatus.available
          : (_isEditing && existing != null ? existing.status : null);

      var meal = _buildDraft(
        id: id,
        createdAt: createdAt,
        existing: existing,
        statusOverride: statusOverride,
      );

      final editingPublished = _isEditing && existing?.publicationId != null;

      await ref.read(cookMealsControllerProvider.notifier).upsert(
            meal,
            preservePublicationStatus: !publish && editingPublished,
            allowCreatePublication: publish,
          );
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

      final snack = publish
          ? 'Comida publicada'
          : (_isEditing && existing?.publicationId != null
              ? 'Cambios guardados en tu plato'
              : 'Borrador guardado');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snack)),
      );
      context.go(const CookMealsRoute().location);
    } catch (e) {
      if (!mounted) return;

      final msg = switch (e) {
        UnauthorizedException() =>
          'Tu sesión expiró. Vuelve a iniciar sesión e inténtalo de nuevo.',
        ApiErrorResponseException(:final code, :final message) => '$message ($code)',
        NetworkException(message: final m) =>
          'No pudimos conectar con el servidor. $m',
        FormatException(message: final m) => m,
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

  Future<ImageSource?> _askPhotoSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _suggestDescriptionFromPhoto() async {
    if (_saving || _aiBusy) return;
    final source = await _askPhotoSource();
    if (!mounted || source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (!mounted || file == null) return;

    setState(() => _aiBusy = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;
      final name =
          file.name.trim().isNotEmpty ? file.name.trim() : 'plato.jpg';
      final text = await ref
          .read(cookMealsRepositoryProvider)
          .describeMealFromPhotoBytes(bytes, filename: name);
      if (!mounted) return;
      _description.text = text;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Descripción sugerida — revísala y ajústala antes de publicar.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = switch (e) {
        UnauthorizedException() =>
          'Tu sesión expiró. Vuelve a iniciar sesión e inténtalo de nuevo.',
        ApiErrorResponseException(:final message) => message,
        NetworkException(message: final m) =>
          'No pudimos conectar con el servidor. $m',
        _ => 'No pudimos generar la descripción. Inténtalo de nuevo.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cookMealsControllerProvider, (previous, next) {
      final id = widget.editMealId;
      if (id == null || id.isEmpty) return;
      if (_hydratedForEditId == id) return;
      next.whenData((_) => _ensureEditHydrated());
    });

    final preview = _buildDraft(
      id: widget.editMealId ?? 'preview',
      createdAt: DateTime.now(),
    );

    final isEditLoading = widget.editMealId != null &&
        widget.editMealId!.isNotEmpty &&
        _hydratedForEditId != widget.editMealId;

    return AppScaffold(
      title: widget.editMealId == null ? 'Crear comida' : 'Editar comida',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (isEditLoading) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: AppSpacing.sm),
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: (_saving || _aiBusy) ? null : _suggestDescriptionFromPhoto,
              icon: _aiBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined, size: 20),
              label: Text(_aiBusy ? 'Analizando foto…' : 'Sugerir descripción con foto'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'La foto se envía al servidor para generar texto (clave Gemini). '
              'No sustituye revisar ingredientes y alérgenos.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                    height: 1.35,
                  ),
            ),
          ),
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
          Text(
            'Mis plantillas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Guarda lo que tienes en el formulario y vuelve a cargarlo cuando quieras. '
            'Son solo en este dispositivo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._buildTemplateSection(context),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _saving ? null : () => _save(publish: false),
                  child: Text(
                    _saving
                        ? 'Guardando…'
                        : (_isEditing ? 'Guardar' : 'Guardar borrador'),
                  ),
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
          if (_isEditing && _existingMeal()?.publicationId != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Guardar actualiza tu publicación activa (precio, cupos, método de entrega y datos del plato).',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                    height: 1.3,
                  ),
            ),
          ],
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

  List<Widget> _buildTemplateSection(BuildContext context) {
    final templates = ref.watch(cookMealDraftTemplatesProvider);
    final notifier = ref.read(cookMealDraftTemplatesProvider.notifier);

    return [
      if (templates.isEmpty)
        Text(
          'Todavía no tienes plantillas. Completa el formulario y pulsa «Guardar como plantilla».',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in templates)
              InputChip(
                label: Text(
                  t.label.isEmpty ? t.title : t.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _saving ? null : () => _applyDraftTemplate(t),
                onDeleted: _saving
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        notifier.remove(t.id);
                      },
                deleteIconColor:
                    Theme.of(context).colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
              ),
          ],
        ),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _saving ? null : () => _promptSaveAsTemplate(),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Guardar como plantilla'),
        ),
      ),
    ];
  }

  void _applyDraftTemplate(CookMealDraftTemplate t) {
    HapticFeedback.selectionClick();
    _title.text = t.title;
    _description.text = t.description;
    _price.text = t.priceCop.toString();
    _stock.text = t.stock.toString();
    _fulfillment = t.fulfillmentType;
    _ingredients
      ..clear()
      ..addAll(t.ingredients);
    setState(() {});
  }

  Future<void> _promptSaveAsTemplate() async {
    final initial = _title.text.trim().isEmpty
        ? 'Mi plantilla'
        : _title.text.trim();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _SaveTemplateNameDialog(initialName: initial),
    );
    if (!mounted) return;
    if (name == null) return;
    final label = name.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para la plantilla')),
      );
      return;
    }

    final price = int.tryParse(_price.text.trim()) ?? 0;
    final stock = int.tryParse(_stock.text.trim()) ?? 0;

    final template = CookMealDraftTemplate(
      id: 'tpl_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      title: _title.text.trim(),
      description: _description.text.trim(),
      priceCop: price < 0 ? 0 : price,
      stock: stock < 0 ? 0 : stock,
      fulfillmentType: _fulfillment,
      ingredients: List.of(_ingredients),
      savedAt: DateTime.now(),
    );

    await ref.read(cookMealDraftTemplatesProvider.notifier).add(template);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plantilla «$label» guardada')),
    );
  }
}

class _SaveTemplateNameDialog extends StatefulWidget {
  const _SaveTemplateNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_SaveTemplateNameDialog> createState() =>
      _SaveTemplateNameDialogState();
}

class _SaveTemplateNameDialogState extends State<_SaveTemplateNameDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guardar plantilla'),
      content: TextField(
        controller: _c,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nombre',
          hintText: 'Ej: Bandeja del lunes',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => Navigator.of(context).pop(_c.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_c.text),
          child: const Text('Guardar'),
        ),
      ],
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
