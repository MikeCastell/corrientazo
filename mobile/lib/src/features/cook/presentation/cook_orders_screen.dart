import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/states/app_empty_state.dart';
import '../application/cook_meals_controller.dart';

class CookOrdersScreen extends ConsumerWidget {
  const CookOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(cookMealsControllerProvider);

    return AppScaffold(
      title: 'Pedidos',
      body: meals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'No pudimos cargar pedidos',
          subtitle: e.toString(),
        ),
        data: (items) {
          if (items.where((m) => m.isActive).isEmpty) {
            return const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Aún no tienes pedidos',
              subtitle: 'Publica una comida y aquí aparecerán pedidos recibidos. Sin realtime por ahora.',
            );
          }

          // Placeholder premium: muestra pedidos mock para dar sensación operativa.
          final mock = [
            _CookOrderTile(
              id: 'A12F3B',
              statusLabel: 'Nuevo',
              tone: AppColors.primary,
              fulfillment: 'Recoger',
              eta: '15–25 min',
              price: '\$24.000',
              customer: 'Cliente cercano',
            ),
            _CookOrderTile(
              id: 'B91C0D',
              statusLabel: 'Preparando',
              tone: AppColors.accentDeep,
              fulfillment: 'Domicilio',
              eta: '25–35 min',
              price: '\$12.000',
              customer: 'Cliente frecuente',
            ),
          ];

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Recibidos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...mock,
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  'Nota: estos pedidos son placeholders para UX. Se conectan a backend en la próxima fase.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CookOrderTile extends StatelessWidget {
  const _CookOrderTile({
    required this.id,
    required this.statusLabel,
    required this.tone,
    required this.fulfillment,
    required this.eta,
    required this.price,
    required this.customer,
  });

  final String id;
  final String statusLabel;
  final Color tone;
  final String fulfillment;
  final String eta;
  final String price;
  final String customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: tone.withValues(alpha: 0.18)),
            ),
            child: Icon(Icons.receipt_long, color: tone),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido #$id',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '$statusLabel · $fulfillment · $eta',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: tone.withValues(alpha: 0.18)),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: tone,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

