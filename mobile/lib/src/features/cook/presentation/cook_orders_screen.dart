import 'package:flutter/material.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';

class CookOrdersScreen extends StatelessWidget {
  const CookOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
              ),
              child: const Icon(Icons.inbox_outlined, color: AppColors.brand),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aún no tienes pedidos',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cuando publiques una comida, aquí verás pedidos recibidos y podrás aceptarlos o rechazarlos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

