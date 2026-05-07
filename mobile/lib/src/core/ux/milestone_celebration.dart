import 'package:flutter/material.dart';

import '../design/tokens/app_spacing.dart';

enum MilestoneKind { cookFirstPublish, cookFirstOrder, cookFirstCompleted }

/// Warm, human milestone — not gamified; single sheet, dismissible.
Future<void> showMilestoneCelebration(
  BuildContext context,
  MilestoneKind kind,
) async {
  final copy = switch (kind) {
    MilestoneKind.cookFirstPublish => (
      title: 'Tu plato ya está en el barrio',
      body:
          'Alguien puede pedirlo ahora mismo. Lo más difícil ya pasó: seguir es más fácil.',
    ),
    MilestoneKind.cookFirstOrder => (
      title: 'Te llegó tu primer pedido',
      body:
          'Hay una persona real esperando tu corrientazo. Gracias por cocinar cerca.',
    ),
    MilestoneKind.cookFirstCompleted => (
      title: 'Primer pedido completado',
      body:
          'Hiciste que esto circulara de verdad. Así se construye confianza, paso a paso.',
    ),
  };

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                copy.body,
                style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                  height: 1.35,
                  color: Theme.of(
                    ctx,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
