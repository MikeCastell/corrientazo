import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/routing/app_router.dart';

class CookMealsScreen extends StatelessWidget {
  const CookMealsScreen({super.key});

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
              child: const Icon(Icons.restaurant_menu, color: AppColors.brand),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aún no has creado comidas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Crea tu primer corrientazo. Lo revisaremos y lo mostraremos a clientes cercanos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go(const CookCreateMealRoute().location),
                child: const Text('Crear comida'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

