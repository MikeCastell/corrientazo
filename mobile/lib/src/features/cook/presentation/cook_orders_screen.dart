import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/states/app_empty_state.dart';
import '../../../core/ui/states/app_loading_center.dart';
import '../../../core/ux/milestone_celebration.dart';
import '../../../core/ux/ux_milestones_store.dart';
import '../../orders/domain/order_cook_actions.dart';
import '../../orders/domain/order_summary.dart';
import '../application/cook_orders_controller.dart';
import '../domain/cook_order_operacion.dart';

class CookOrdersScreen extends ConsumerStatefulWidget {
  const CookOrdersScreen({super.key});

  @override
  ConsumerState<CookOrdersScreen> createState() => _CookOrdersScreenState();
}

class _CookOrdersScreenState extends ConsumerState<CookOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _milestoneUiBusy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _maybeCelebrate(List<OrderSummary> items) async {
    if (_milestoneUiBusy || !mounted) return;
    _milestoneUiBusy = true;
    try {
      final store = ref.read(uxMilestonesStoreProvider);

      if (items.isNotEmpty && !store.celebratedCookFirstOrder) {
        await showMilestoneCelebration(context, MilestoneKind.cookFirstOrder);
        await store.markCookFirstOrderCelebrated();
        if (!mounted) return;
      }

      final store2 = ref.read(uxMilestonesStoreProvider);
      final hasTerminal = items.any((o) {
        final u = o.status.toUpperCase();
        return u == 'DELIVERED' || u == 'PICKED_UP';
      });
      if (hasTerminal && !store2.celebratedCookFirstCompleted) {
        if (!mounted) return;
        await showMilestoneCelebration(
          context,
          MilestoneKind.cookFirstCompleted,
        );
        await store2.markCookFirstCompletedCelebrated();
      }
    } finally {
      _milestoneUiBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(cookOrdersControllerProvider);

    ref.listen(cookOrdersControllerProvider, (prev, next) {
      next.whenData((items) {
        Future.microtask(() => _maybeCelebrate(items));
      });
    });

    return AppScaffold(
      title: 'Pedidos',
      body: orders.when(
        loading: () => const AppLoadingCenter(message: 'Trayendo pedidos…'),
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'No pudimos cargar pedidos',
          subtitle: e.toString(),
          actionLabel: 'Reintentar',
          onAction: () =>
              ref.read(cookOrdersControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          Future<void> refresh() async =>
              ref.read(cookOrdersControllerProvider.notifier).refresh();

          if (items.isEmpty) {
            return AppEmptyState(
              kicker: 'Tu horno ya está listo',
              icon: Icons.inbox_outlined,
              title: 'Todavía sin pedidos',
              subtitle:
                  'Cuando alguien pida un plato que publicaste, aparece aquí. '
                  'Tira hacia abajo para refrescar — la lista se actualiza rápido.',
              actionLabel: 'Publicar un plato',
              onAction: () => context.go(const CookCreateMealRoute().location),
              secondaryActionLabel: 'Ir al dashboard',
              onSecondaryAction: () =>
                  context.go(const CookDashboardRoute().location),
            );
          }

          final active = items.where(cookOrderIsActive).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final historial = items.where((o) => cookOrderIsTerminal(o.status)).toList()
            ..sort(
              (a, b) => (b.updatedAt ?? b.createdAt)
                  .compareTo(a.updatedAt ?? a.createdAt),
            );

          List<Widget> orderTiles(Iterable<OrderSummary> source) => [
                for (final o in source)
                  _CookOrderCard(
                    orderId: o.id,
                    status: o.status,
                    totalCop: o.totalCop,
                    createdAt: o.createdAt,
                    customerName: o.customerName ?? 'Cliente',
                    quantity: o.quantity,
                    fulfillmentType: o.fulfillmentType,
                    mealTitle: o.mealTitle ?? 'Pedido',
                    onOpen: () =>
                        context.push(CookOrderDetailRoute(o.id).location),
                    onAction: (action) async {
                      HapticFeedback.selectionClick();
                      await ref
                          .read(cookOrdersControllerProvider.notifier)
                          .transition(orderId: o.id, action: action);
                    },
                  ),
              ];

          Widget tabBody({
            required bool isEmpty,
            required Widget emptyState,
            required List<Widget> tiles,
          }) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.12,
                        ),
                        emptyState,
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        ...tiles,
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Activos'),
                  Tab(text: 'Historial'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    tabBody(
                      isEmpty: active.isEmpty,
                      emptyState: AppEmptyState(
                        icon: Icons.restaurant_outlined,
                        title: 'Sin pedidos activos',
                        subtitle:
                            'Los pedidos nuevos aparecen aquí. Cuando los marques '
                            'como entregados o cancelados, pasan al historial.',
                        actionLabel: 'Publicar un plato',
                        onAction: () =>
                            context.go(const CookCreateMealRoute().location),
                      ),
                      tiles: orderTiles(active),
                    ),
                    tabBody(
                      isEmpty: historial.isEmpty,
                      emptyState: AppEmptyState(
                        icon: Icons.history,
                        title: 'Sin pedidos en el historial',
                        subtitle:
                            'Aquí verás pedidos entregados, recogidos o cancelados.',
                      ),
                      tiles: orderTiles(historial),
                    ),
                  ],
                ),
              ),
            ],
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
    required this.onOpen,
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
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final tone = _toneForStatus(s);
    final statusLabel = _labelForStatus(s);
    final eta = _pseudoEtaLabel(createdAt, s);
    final headlineSubtitle = s.startsWith('CANCELLED')
        ? statusLabel
        : '$statusLabel · ${_fulfillmentLabel(fulfillmentType)} · $eta';

    final actions = cookActionsForOrder(
      status: s,
      fulfillmentType: fulfillmentType,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onOpen,
      child: Container(
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        headlineSubtitle,
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
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in actions)
                            FilledButton.tonal(
                              onPressed: () => onAction(a.action),
                              child: Text(a.label),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
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
      case 'CANCELLED_BY_CLIENT':
      case 'CANCELLED_BY_COOK':
      case 'CANCELLED_BY_ADMIN':
        return AppColors.warning;
      default:
        if (s.startsWith('CANCELLED')) return AppColors.warning;
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
      case 'CANCELLED_BY_CLIENT':
        return 'Cancelado · cliente';
      case 'CANCELLED_BY_COOK':
        return 'Cancelado · cocina';
      case 'CANCELLED_BY_ADMIN':
        return 'Cancelado';
      default:
        if (s.startsWith('CANCELLED')) return 'Cancelado';
        return s;
    }
  }

  static String _fulfillmentLabel(String s) =>
      s.toUpperCase() == 'DELIVERY' ? 'Domicilio' : 'Recoger';

  static String _pseudoEtaLabel(DateTime createdAt, String status) {
    if (status.startsWith('CANCELLED')) return 'Pedido cerrado';
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

}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final u = status.toUpperCase();
    if (u.startsWith('CANCELLED')) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Este pedido quedó cancelado — aparece aquí en tu historial.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.62),
              ),
        ),
      );
    }

    final steps = const [
      ('INIT', 'Nuevo'),
      ('CONFIRMED', 'Confirmado'),
      ('PREPARING', 'Preparando'),
      ('READY_FOR_PICKUP', 'Listo'),
      ('PICKED_UP', 'Entregado'),
    ];

    final idx = steps.indexWhere((s) => s.$1 == u);
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
