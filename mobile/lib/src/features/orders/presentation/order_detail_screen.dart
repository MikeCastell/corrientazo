import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/marketplace/food_image.dart';
import '../../../core/networking/api_exception.dart';
import '../../../core/ui/marketplace/cook_trust_chip.dart';
import '../../../core/ui/states/app_empty_state.dart';
import '../data/orders_repository.dart';
import '../../customer/application/customer_orders_controller.dart';
import '../../cook/application/cook_orders_controller.dart';
import '../application/order_status_override.dart';
import '../domain/order_detail.dart';
import '../domain/order_cook_actions.dart';
import '../domain/order_status_labels.dart';
import '../domain/order_status_terminal.dart';
import 'widgets/order_cancel_flow.dart';
import 'widgets/order_tracking_progress.dart';

enum OrderDetailMode { customer, cook }

final orderDetailProvider = FutureProvider.family
    .autoDispose<OrderDetail, String>((ref, orderId) async {
      return ref.read(ordersRepositoryProvider).getById(orderId);
    });

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.mode,
  });

  final String orderId;
  final OrderDetailMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderDetailProvider(orderId));

    return AppScaffold(
      title: 'Pedido',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'No pudimos cargar el pedido',
          subtitle: e.toString(),
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (o) {
          final override = ref.watch(orderStatusOverrideProvider(orderId));
          final s = (override ?? o.status).toUpperCase();
          final tone = _toneForStatus(s);
          final statusLabel = orderStatusLabel(s);
          final etaLabel = orderPseudoEtaLabel(o.createdAt, s);
          final cancelled = _orderIsCancelled(s);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(orderDetailProvider(orderId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _Hero(
                  tone: tone,
                  statusLabel: statusLabel,
                  etaLabel: etaLabel,
                  mealTitle: o.mealTitle ?? 'Pedido',
                  mealPhotoUrl: o.mealPhotoUrl,
                ),
                const SizedBox(height: AppSpacing.md),
                if (cancelled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _CancelledInsightCard(
                      status: s,
                      cancelReason: o.cancelReason,
                    ),
                  ),
                _InfoGrid(
                  fulfillmentType: o.fulfillmentType,
                  quantity: o.quantity,
                  totalCop: o.totalCop,
                  createdAt: o.createdAt,
                  notes: o.notes,
                ),
                const SizedBox(height: AppSpacing.md),
                _TimelineCard(
                  status: s,
                  fulfillmentType: o.fulfillmentType,
                  timeline: o.timeline,
                ),
                const SizedBox(height: AppSpacing.md),
                if (mode == OrderDetailMode.customer && !cancelled)
                  _CustomerCancelPanel(
                    status: s,
                    onCancelTap: () async {
                      final ok = await showCustomerCancelConfirmSheet(context);
                      if (!context.mounted || !ok) return;
                      try {
                        await ref
                            .read(ordersRepositoryProvider)
                            .cancelOrder(orderId: o.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Pedido cancelado',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        ref.invalidate(orderDetailProvider(orderId));
                        ref.invalidate(customerOrdersControllerProvider);
                      } on ApiErrorResponseException catch (e) {
                        if (!context.mounted) return;
                        if (e.code == 'ORDER_CANCEL_NOT_ALLOWED') {
                          await showCustomerCannotCancelSheet(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.message),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    onExplainNoCancelTap: () =>
                        showCustomerCannotCancelSheet(context),
                  ),
                if (mode == OrderDetailMode.customer)
                  _CookCard(
                    cookName: o.cookName,
                    cookAvatarUrl: o.cookAvatarUrl,
                    cookBio: o.cookBio,
                    cookPhone: o.cookPhone,
                  )
                else
                  _CustomerCard(
                    name: o.customerName,
                    avatarUrl: o.customerAvatarUrl,
                    phone: o.customerPhone,
                  ),
                const SizedBox(height: AppSpacing.md),
                if (mode == OrderDetailMode.cook && !cancelled)
                  _CookActions(
                    status: s,
                    fulfillmentType: o.fulfillmentType,
                    onAction: (action) async {
                      HapticFeedback.selectionClick();
                      final next = statusAfterCookAction(action);
                      if (next != null) {
                        ref
                            .read(orderStatusOverrideProvider(orderId).notifier)
                            .setOverride(next);
                      }
                      try {
                        await ref
                            .read(cookOrdersControllerProvider.notifier)
                            .transition(orderId: o.id, action: action);
                        await ref.read(orderDetailProvider(orderId).future);
                        ref.invalidate(orderDetailProvider(orderId));
                        ref
                            .read(orderStatusOverrideProvider(orderId).notifier)
                            .setOverride(null);
                      } catch (e) {
                        ref
                            .read(orderStatusOverrideProvider(orderId).notifier)
                            .setOverride(null);
                        rethrow;
                      }
                    },
                    onCancelFlowTap: _cookMayCancelFromKitchen(s)
                        ? () async {
                            final sel =
                                await showCookCancelSheet(context);
                            if (!context.mounted || sel == null) return;
                            try {
                              await ref
                                  .read(ordersRepositoryProvider)
                                  .cancelOrder(
                                    orderId: o.id,
                                    reasonCode: sel.reasonCode,
                                    note: sel.note,
                                  );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pedido cancelado',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              ref.invalidate(orderDetailProvider(orderId));
                              ref.invalidate(cookOrdersControllerProvider);
                            } on ApiErrorResponseException catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No pudimos cancelar: revisa el estado del pedido.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                if (mode == OrderDetailMode.cook &&
                    !cancelled &&
                    (o.stockAvailable != null || o.publicationStatus != null))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: _OperationalCard(
                      publicationStatus: o.publicationStatus,
                      stockAvailable: o.stockAvailable,
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

bool _orderIsCancelled(String statusUpper) =>
    statusUpper.startsWith('CANCELLED');

bool _customerMayCancel(String statusUpper) {
  final u = statusUpper.toUpperCase();
  return u == 'INIT' || u == 'CONFIRMED';
}

bool _cookMayCancelFromKitchen(String statusUpper) {
  final u = statusUpper.toUpperCase();
  return u == 'INIT' || u == 'CONFIRMED' || u == 'PREPARING';
}

class _CancelledInsightCard extends StatelessWidget {
  const _CancelledInsightCard({
    required this.status,
    required this.cancelReason,
  });

  final String status;
  final String? cancelReason;

  @override
  Widget build(BuildContext context) {
    final clientInitiated = status.contains('CLIENT');
    final title = clientInitiated
        ? 'Pedido cancelado'
        : 'Tu cook no pudo completar este pedido hoy';
    final fallback = clientInitiated
        ? 'Lo cancelaste antes de que empezara la preparación.'
        : 'Te contamos qué pasó abajo — seguimos cuidando tu experiencia.';
    final body = (cancelReason != null && cancelReason!.trim().isNotEmpty)
        ? cancelReason!.trim()
        : fallback;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF3D2A1F),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.78),
                ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCancelPanel extends StatelessWidget {
  const _CustomerCancelPanel({
    required this.status,
    required this.onCancelTap,
    required this.onExplainNoCancelTap,
  });

  final String status;
  final VoidCallback onCancelTap;
  final VoidCallback onExplainNoCancelTap;

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final mayCancel = _customerMayCancel(s);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Necesitas cambiar algo?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (mayCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancelTap,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar pedido'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              )
            else if (!orderStatusIsTerminal(s))
              TextButton(
                onPressed: onExplainNoCancelTap,
                child: Text(
                  '¿Por qué no puedo cancelar desde la app?',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary.withValues(alpha: 0.92),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.tone,
    required this.statusLabel,
    required this.etaLabel,
    required this.mealTitle,
    required this.mealPhotoUrl,
  });

  final Color tone;
  final String statusLabel;
  final String etaLabel;
  final String mealTitle;
  final String? mealPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final fallbackGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.brand.withValues(alpha: 0.55),
        AppColors.accentDeep.withValues(alpha: 0.35),
      ],
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Stack(
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: FoodImage(
              asset: (mealPhotoUrl == null || mealPhotoUrl!.isEmpty)
                  ? 'assets/food/corrientazo.jpg'
                  : mealPhotoUrl!,
              fit: BoxFit.cover,
              fallbackGradient: fallbackGradient,
              fallbackIcon: Icons.restaurant_menu,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tone.withValues(alpha: 0.30)),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mealTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ETA: $etaLabel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.fulfillmentType,
    required this.quantity,
    required this.totalCop,
    required this.createdAt,
    required this.notes,
  });

  final String fulfillmentType;
  final int quantity;
  final int totalCop;
  final DateTime createdAt;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            runSpacing: 10,
            spacing: 10,
            children: [
              _Pill(
                icon: fulfillmentType.toUpperCase() == 'DELIVERY'
                    ? Icons.delivery_dining
                    : Icons.storefront,
                label: fulfillmentType.toUpperCase() == 'DELIVERY'
                    ? 'Domicilio'
                    : 'Recoger',
              ),
              _Pill(icon: Icons.shopping_bag_outlined, label: 'x$quantity'),
              _Pill(icon: Icons.payments_outlined, label: '\$$totalCop'),
              _Pill(
                icon: Icons.schedule,
                label:
                    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
              ),
            ],
          ),
          if (notes != null && notes!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Notas',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              notes!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.status,
    required this.fulfillmentType,
    required this.timeline,
  });

  final String status;
  final String fulfillmentType;
  final List<OrderStatusEvent> timeline;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          OrderTrackingProgress(
            status: status,
            fulfillmentType: fulfillmentType,
            tone: _toneForStatus(status),
            lightOnDark: false,
          ),
          const SizedBox(height: AppSpacing.md),
          ...timeline.reversed.take(4).map((e) {
            final when =
                '${e.occurredAt.hour.toString().padLeft(2, '0')}:${e.occurredAt.minute.toString().padLeft(2, '0')}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      orderStatusLabel(e.toStatus.toUpperCase()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    when,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CookCard extends StatelessWidget {
  const _CookCard({
    required this.cookName,
    required this.cookAvatarUrl,
    required this.cookBio,
    required this.cookPhone,
  });

  final String? cookName;
  final String? cookAvatarUrl;
  final String? cookBio;
  final String? cookPhone;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CookTrustChip(
              cookName: cookName ?? 'Cocina local',
              cookAvatarUrl: cookAvatarUrl,
              isVerified: true,
              sanitaryLevelLabel: 'Casero',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            cookBio == null || cookBio!.trim().isEmpty
                ? 'Comida casera, hecha al momento.'
                : cookBio!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
          if (cookPhone != null && cookPhone!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              cookPhone!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.name,
    required this.avatarUrl,
    required this.phone,
  });

  final String? name;
  final String? avatarUrl;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final fallbackGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.brand.withValues(alpha: 0.20),
        AppColors.secondary.withValues(alpha: 0.20),
      ],
    );
    return _Card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 44,
              height: 44,
              child: FoodImage(
                asset: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? 'assets/food/arepas.jpg'
                    : avatarUrl!,
                fit: BoxFit.cover,
                fallbackGradient: fallbackGradient,
                fallbackIcon: Icons.person,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Cliente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone ?? 'Sin teléfono',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CookActions extends StatelessWidget {
  const _CookActions({
    required this.status,
    required this.fulfillmentType,
    required this.onAction,
    this.onCancelFlowTap,
  });

  final String status;
  final String fulfillmentType;
  final ValueChanged<String> onAction;
  final VoidCallback? onCancelFlowTap;

  @override
  Widget build(BuildContext context) {
    final actions = cookActionsForOrder(
      status: status,
      fulfillmentType: fulfillmentType,
    );
    final showCancel = onCancelFlowTap != null;

    if (actions.isEmpty && !showCancel) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (actions.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in actions)
                  FilledButton(
                    onPressed: () => onAction(a.action),
                    child: Text(a.label),
                  ),
              ],
            ),
          if (showCancel) ...[
            if (actions.isNotEmpty) const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancelFlowTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: AppColors.danger.withValues(alpha: 0.40),
                  ),
                ),
                child: const Text('Cancelar pedido…'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OperationalCard extends StatelessWidget {
  const _OperationalCard({
    required this.publicationStatus,
    required this.stockAvailable,
  });
  final String? publicationStatus;
  final int? stockAvailable;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operación',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (stockAvailable != null)
            Text(
              'Stock relacionado: $stockAvailable',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          if (publicationStatus != null) ...[
            const SizedBox(height: 4),
            Text(
              'Publicación: ${publicationStatus!.toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.70),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

Color _toneForStatus(String s) {
  switch (s) {
    case 'INIT':
      return AppColors.primary;
    case 'CONFIRMED':
      return AppColors.accentDeep;
    case 'PREPARING':
      return AppColors.accentDeep;
    case 'READY_FOR_PICKUP':
    case 'READY_FOR_DISPATCH':
      return AppColors.secondary;
    case 'OUT_FOR_DELIVERY':
      return AppColors.accentDeep;
    case 'PICKED_UP':
    case 'DELIVERED':
      return AppColors.success;
    case 'CANCELLED_BY_CLIENT':
    case 'CANCELLED_BY_COOK':
    case 'CANCELLED_BY_ADMIN':
      return AppColors.warning;
    default:
      return AppColors.brand;
  }
}

