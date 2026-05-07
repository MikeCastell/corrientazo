import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_colors.dart';
import '../../../../core/design/tokens/app_radius.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/routing/app_router.dart';

/// Lightweight onboarding checklist for new cooks — no scoring, just clarity.
class CookGettingStartedCard extends StatelessWidget {
  const CookGettingStartedCard({
    super.key,
    required this.hasPublishedMeal,
    required this.profileFeelsComplete,
    required this.hasOrders,
  });

  final bool hasPublishedMeal;
  final bool profileFeelsComplete;
  final bool hasOrders;

  bool get _allDone => hasPublishedMeal && profileFeelsComplete && hasOrders;

  @override
  Widget build(BuildContext context) {
    if (_allDone) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.secondary.withValues(alpha: 0.06),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Empieza con calma',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tres pasos y tu cocina queda lista para el barrio.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.68),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CheckRow(
            done: hasPublishedMeal,
            title: 'Publica tu primer plato',
            subtitle: 'Foto, precio y stock. Los vecinos ya pueden pedir.',
            onTap: () => context.go(const CookCreateMealRoute().location),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            done: profileFeelsComplete,
            title: 'Completa tu perfil',
            subtitle: 'Una bio y tu foto ayudan a confiar en tu cocina.',
            onTap: () => context.go(const CookProfileRoute().location),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CheckRow(
            done: hasOrders,
            title: 'Tu primer pedido',
            subtitle: hasOrders
                ? 'Ya llegó — revisa la pestaña Pedidos.'
                : 'Cuando llegue, te avisamos aquí y con notificación.',
            onTap: () => context.go(const CookOrdersRoute().location),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.done,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool done;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? AppColors.success : AppColors.brand,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.35),
                      color: done
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.45)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.62),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
