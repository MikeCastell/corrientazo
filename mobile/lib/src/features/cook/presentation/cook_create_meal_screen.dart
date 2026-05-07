import 'package:flutter/material.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';

class CookCreateMealScreen extends StatelessWidget {
  const CookCreateMealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Crear comida',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Este es un placeholder premium. La creación real se conecta al backend en la siguiente fase.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        _FieldCard(
          title: 'Título',
          hint: 'Ej: Corrientazo de res',
          icon: Icons.title,
        ),
        const SizedBox(height: AppSpacing.sm),
        _FieldCard(
          title: 'Precio (COP)',
          hint: 'Ej: 12000',
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        _FieldCard(
          title: 'Stock disponible',
          hint: 'Ej: 10',
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Creación real: próximamente (sin pagos / sin realtime).'),
                ),
              );
            },
            child: const Text('Guardar borrador'),
          ),
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.title,
    required this.hint,
    required this.icon,
  });

  final String title;
  final String hint;
  final IconData icon;

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: AppColors.brand),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

