import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/states/app_empty_state.dart';
import '../application/cook_orders_controller.dart';

class CookOrdersScreen extends ConsumerWidget {
  const CookOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(cookOrdersControllerProvider);

    return AppScaffold(
      title: 'Pedidos',
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'No pudimos cargar pedidos',
          subtitle: e.toString(),
          actionLabel: 'Reintentar',
          onAction: () =>
              ref.read(cookOrdersControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Aún no tienes pedidos',
              subtitle:
                  'Cuando te caiga el primer pedido, lo verás aquí. Sin realtime por ahora: usa refrescar.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(cookOrdersControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Recibidos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...items.map(
                  (o) => _CookOrderCard(
                    orderId: o.id,
                    status: o.status,
                    totalCop: o.totalCop,
                    createdAt: o.createdAt,
                    customerName: o.customerName ?? 'Cliente',
                    quantity: o.quantity,
                    fulfillmentType: o.fulfillmentType,
                    mealTitle: o.mealTitle ?? 'Pedido',
                    onAction: (action) async {
                      HapticFeedback.selectionClick();
                      await ref
                          .read(cookOrdersControllerProvider.notifier)
                          .transition(orderId: o.id, action: action);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CookOrderCard extends StatelessWidget {
  const _CookOrderCard({
    required this.orderId,
    required this.status,
    required this.totalCop,
    required this.createdAt,
    required this.customerName,
    required this.mealTitle,
    required this.quantity,
    required this.fulfillmentType,
    required this.onAction,
  });

  final String orderId;
  final String status;
  final int totalCop;
  final DateTime createdAt;
  final String customerName;
  final String mealTitle;
  final int quantity;
  final String fulfillmentType;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final tone = _toneForStatus(s);
    final statusLabel = _labelForStatus(s);
    final eta = _pseudoEtaLabel(createdAt, s);

    final actions = _actionsForStatus(s);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'Pedido #${orderId.substring(0, 6).toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$statusLabel · ${_fulfillmentLabel(fulfillmentType)} · $eta',
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
                  horizontal: 10,
                  vertical: 6,
                ),
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
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            mealTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            'x$quantity · $customerName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Timeline(status: s),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  '\$$totalCop',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (actions.isEmpty)
                Text(
                  'Sin acciones',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  children: [
                    for (final a in actions)
                      FilledButton.tonal(
                        onPressed: () => onAction(a.action),
                        child: Text(a.label),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _toneForStatus(String s) {
    switch (s) {
      case 'INIT':
        return AppColors.primary;
      case 'CONFIRMED':
        return AppColors.accentDeep;
      case 'PREPARING':
        return AppColors.accentDeep;
      case 'READY_FOR_PICKUP':
        return AppColors.secondary;
      case 'PICKED_UP':
      case 'DELIVERED':
        return AppColors.success;
      default:
        return AppColors.brand;
    }
  }

  static String _labelForStatus(String s) {
    switch (s) {
      case 'INIT':
        return 'Nuevo';
      case 'CONFIRMED':
        return 'Confirmado';
      case 'PREPARING':
        return 'Preparando';
      case 'READY_FOR_PICKUP':
        return 'Listo';
      case 'PICKED_UP':
        return 'Entregado';
      case 'DELIVERED':
        return 'Entregado';
      default:
        return s;
    }
  }

  static String _fulfillmentLabel(String s) =>
      s.toUpperCase() == 'DELIVERY' ? 'Domicilio' : 'Recoger';

  static String _pseudoEtaLabel(DateTime createdAt, String status) {
    final mins = DateTime.now().difference(createdAt).inMinutes.abs();
    if (status == 'READY_FOR_PICKUP' ||
        status == 'PICKED_UP' ||
        status == 'DELIVERED') {
      return 'Listo';
    }
    final low = 15 + (mins % 8);
    final high = low + 12;
    return '$low–$high min';
  }

  static List<_ActionDef> _actionsForStatus(String s) {
    switch (s) {
      case 'INIT':
        return const [_ActionDef('CONFIRM', 'Confirmar')];
      case 'CONFIRMED':
        return const [_ActionDef('START_PREPARING', 'Empezar')];
      case 'PREPARING':
        return const [_ActionDef('MARK_READY_PICKUP', 'Listo')];
      case 'READY_FOR_PICKUP':
        return const [_ActionDef('MARK_PICKED_UP', 'Entregado')];
      default:
        return const [];
    }
  }
}

class _ActionDef {
  const _ActionDef(this.action, this.label);
  final String action;
  final String label;
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final steps = const [
      ('INIT', 'Nuevo'),
      ('CONFIRMED', 'Confirmado'),
      ('PREPARING', 'Preparando'),
      ('READY_FOR_PICKUP', 'Listo'),
      ('PICKED_UP', 'Entregado'),
    ];

    final idx = steps.indexWhere((s) => s.$1 == status);
    final activeIndex = idx < 0 ? 0 : idx;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _Dot(active: i <= activeIndex),
          if (i != steps.length - 1) _Line(active: i < activeIndex),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = active ? AppColors.brand : Theme.of(context).dividerColor;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = active ? AppColors.brand : Theme.of(context).dividerColor;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
