import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/tokens/app_colors.dart';
import '../../../../core/design/tokens/app_radius.dart';
import '../../../../core/design/tokens/app_spacing.dart';

/// Resultado al cancelar desde cocina (motivo predefinido + nota opcional).
class CookCancelSelection {
  const CookCancelSelection({
    required this.reasonCode,
    this.note,
  });

  final String reasonCode;
  final String? note;
}

/// Bottom sheet editorial: cliente confirma cancelación antes de que cocina avance.
Future<bool> showCustomerCancelConfirmSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: Theme.of(ctx).dividerColor),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Cancelar este corrientazo?',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tu cook todavía no ha comenzado a preparar este pedido. '
                'Si cancelas, liberamos el cupo para otras personas del barrio.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.76),
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(ctx).pop(false);
                      },
                      child: const Text('Mejor no'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.danger.withValues(alpha: 0.92),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(ctx).pop(true);
                      },
                      child: const Text('Sí, cancelar'),
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
  return result ?? false;
}

/// Cuando ya va en cocina: explicación humana (sin error técnico).
Future<void> showCustomerCannotCancelSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: Theme.of(ctx).dividerColor),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu corrientazo ya comenzó a prepararse 🍲',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Cuando el cocinero ya está cocinando, no podemos cancelar desde la app '
                'para no desperdiciar su trabajo. Si necesitas ayuda, escribe o llama a tu cook.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      height: 1.38,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.76),
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CookReasonOption {
  const _CookReasonOption(this.code, this.label);
  final String code;
  final String label;
}

const _cookReasons = <_CookReasonOption>[
  _CookReasonOption('NO_INGREDIENTS', 'Sin ingredientes disponibles'),
  _CookReasonOption('KITCHEN_ISSUE', 'Problema en cocina'),
  _CookReasonOption('CANNOT_PREPARE', 'Ya no puedo preparar este plato'),
  _CookReasonOption('UNEXPECTED_CLOSE', 'Cierre inesperado'),
  _CookReasonOption('OTHER', 'Otro motivo'),
];

/// Cook cancela con motivo — devuelve selección o null si cierra.
Future<CookCancelSelection?> showCookCancelSheet(BuildContext context) async {
  return showModalBottomSheet<CookCancelSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _CookCancelSheetBody(
        onConfirm: (sel) {
          Navigator.of(ctx).pop(sel);
        },
      );
    },
  );
}

class _CookCancelSheetBody extends StatefulWidget {
  const _CookCancelSheetBody({required this.onConfirm});

  final void Function(CookCancelSelection sel) onConfirm;

  @override
  State<_CookCancelSheetBody> createState() => _CookCancelSheetBodyState();
}

class _CookCancelSheetBodyState extends State<_CookCancelSheetBody> {
  String _code = 'NO_INGREDIENTS';
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final surface = Theme.of(context).colorScheme.surface;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cancelar este pedido',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Este pedido ya no podrá continuar. '
                  'Le avisamos al cliente con calma y devolvemos el cupo al menú.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.74),
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Motivo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in _cookReasons)
                      ChoiceChip(
                        label: Text(r.label),
                        selected: _code == r.code,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _code = r.code);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  maxLength: 220,
                  decoration: InputDecoration(
                    labelText: 'Detalle opcional',
                    hintText: 'Algo breve para el cliente…',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          AppColors.danger.withValues(alpha: 0.90),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      final note = _noteCtrl.text.trim();
                      widget.onConfirm(
                        CookCancelSelection(
                          reasonCode: _code,
                          note: note.isEmpty ? null : note,
                        ),
                      );
                    },
                    child: const Text('Confirmar cancelación'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
