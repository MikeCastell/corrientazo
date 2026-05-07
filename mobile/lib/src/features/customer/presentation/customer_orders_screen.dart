import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/states/app_empty_state.dart';
import '../application/customer_orders_controller.dart';

class CustomerOrdersScreen extends ConsumerWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersControllerProvider);

    return orders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppEmptyState(
        icon: Icons.error_outline,
        title: 'No pudimos cargar tus pedidos',
        subtitle: e.toString(),
        actionLabel: 'Reintentar',
        onAction: () =>
            ref.read(customerOrdersControllerProvider.notifier).refresh(),
      ),
      data: (data) {
        if (data.active.isEmpty && data.past.isEmpty) {
          return AppEmptyState(
            icon: Icons.receipt_long,
            title: 'Tus pedidos aparecerán aquí',
            subtitle:
                'Cuando hagas tu primer pedido, podrás ver estado y detalles desde esta pestaña.',
            actionLabel: 'Explorar corrientazos',
            onAction: () => context.go(const CustomerHomeRoute().location),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(customerOrdersControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (data.active.isNotEmpty) ...[
                _SectionTitle(title: 'Activos'),
                const SizedBox(height: AppSpacing.sm),
                ...data.active.map(
                  (o) => _OrderCard(
                    orderId: o.id,
                    status: o.status,
                    totalCop: o.totalCop,
                    mealTitle: o.mealTitle,
                    quantity: o.quantity,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (data.past.isNotEmpty) ...[
                _SectionTitle(title: 'Anteriores'),
                const SizedBox(height: AppSpacing.sm),
                ...data.past.map(
                  (o) => _OrderCard(
                    orderId: o.id,
                    status: o.status,
                    totalCop: o.totalCop,
                    mealTitle: o.mealTitle,
                    quantity: o.quantity,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderId,
    required this.status,
    required this.totalCop,
    this.mealTitle,
    this.quantity,
  });

  final String orderId;
  final String status;
  final int totalCop;
  final String? mealTitle;
  final int? quantity;

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final isDone = s == 'DELIVERED';
    final isCancelled = s == 'CANCELLED';

    final tone = isCancelled
        ? AppColors.danger
        : isDone
        ? AppColors.success
        : AppColors.brand;

    final label = isCancelled
        ? 'Cancelado'
        : isDone
        ? 'Entregado'
        : 'En progreso';

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
            child: Icon(
              isCancelled
                  ? Icons.close
                  : isDone
                  ? Icons.check
                  : Icons.local_fire_department_outlined,
              color: tone,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido #${orderId.substring(0, 6).toUpperCase()}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mealTitle == null
                      ? label
                      : (quantity == null || quantity == 1)
                      ? '$label · $mealTitle'
                      : '$label · x$quantity · $mealTitle',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: tone.withValues(alpha: 0.18)),
            ),
            child: Text(
              '\$$totalCop',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
