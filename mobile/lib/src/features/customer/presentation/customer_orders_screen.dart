import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/food/colombian_food_mock.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/ui/states/app_empty_state.dart';
import '../../../core/ui/marketplace/food_image.dart';
import '../../meals/application/meals_controller.dart';
import '../../orders/domain/order_summary.dart';
import '../application/customer_orders_controller.dart';

class CustomerOrdersScreen extends ConsumerWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersControllerProvider);
    final feed = ref
        .watch(mealsFeedProvider)
        .maybeWhen(data: (items) => items, orElse: () => const []);

    return orders.when(
      loading: () => const _OrdersLoading(),
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
            kicker: 'Se siente rico estrenarse',
            icon: Icons.shopping_bag_outlined,
            title: 'Todavía no has pedido tu primer corrientazo 🍲',
            subtitle:
                'Cuando pidas, aquí verás el progreso con calma: quién cocina, '
                'en qué va y cuándo está listo.',
            actionLabel: 'Ver platos de hoy',
            onAction: () => context.go(const CustomerHomeRoute().location),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(customerOrdersControllerProvider.notifier).refresh(),
          child: Scaffold(
            backgroundColor: AppColors.bg,
            body: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      MediaQuery.paddingOf(context).top + AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tus pedidos',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Con calma: tu almuerzo casero va en camino.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                color: const Color(
                                  0xFF6B4A3A,
                                ).withValues(alpha: 0.78),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (data.active.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: _ActiveOrderHero(
                        order: data.active.first,
                        feed: feed,
                      ),
                    ),
                  ),
                if (data.past.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: _SectionHeader(
                        title: 'Anteriores',
                        actionLabel: 'Ver todo',
                        onAction: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Historial completo (próximamente).',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: data.past.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, i) =>
                          _OrderCardEditorial(order: data.past[i], feed: feed),
                    ),
                  ),
                ] else
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrdersLoading extends StatelessWidget {
  const _OrdersLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = (isDark ? AppColors.surfaceDark : AppColors.surface)
        .withValues(alpha: isDark ? 0.35 : 0.55);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                MediaQuery.paddingOf(context).top + AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 30,
                    width: 200,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 18,
                    width: 280,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            sliver: SliverList.separated(
              itemCount: 3,
              separatorBuilder: (context, _) =>
                  const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, _) => Container(
                height: 132,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary.withValues(alpha: 0.90),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveOrderHero extends StatelessWidget {
  const _ActiveOrderHero({required this.order, required this.feed});

  final OrderSummary order;
  final List<dynamic> feed; // meal publications list (typed in meals domain)

  @override
  Widget build(BuildContext context) {
    final s = order.status.toUpperCase();
    final t = _trackingTone(s);
    final cookProfileId = _cookProfileIdFor(order, feed);
    final (title, subtitle) = _humanTrackingCopy(
      status: s,
      cookName: _cookNameFor(order, feed),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: () => context.push(CustomerOrderDetailRoute(order.id).location),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.0
                    : 0.08,
              ),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            _OrderPhoto(
              photoUrl: order.mealPhotoUrl,
              fallbackSeed: order.mealPublicationId,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.18),
                    const Color(0xFF1A0B06).withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: Row(
                children: [
                  _Chip(
                    label: 'Pedido activo',
                    background: AppColors.primary.withValues(alpha: 0.92),
                    foreground: Colors.white,
                  ),
                  const Spacer(),
                  _Chip(
                    label: _shortOrderCode(order.id),
                    background: Colors.white.withValues(alpha: 0.16),
                    foreground: Colors.white,
                    border: Colors.white.withValues(alpha: 0.22),
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SoftProgress(current: _trackingStepIndex(s), tone: t),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Chip(
                        label: _friendlyTime(order.createdAt),
                        background: Colors.white.withValues(alpha: 0.16),
                        foreground: Colors.white,
                        border: Colors.white.withValues(alpha: 0.22),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: _formatCop(order.totalCop),
                        background: t.withValues(alpha: 0.18),
                        foreground: Colors.white,
                        border: t.withValues(alpha: 0.22),
                      ),
                      const Spacer(),
                      if (cookProfileId != null) ...[
                        _PillButton(
                          label: 'Ver cook',
                          onTap: () => context.go(
                            PublicCookProfileRoute(cookProfileId).location,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _PillButton(
                        label: 'Ver detalles',
                        onTap: () => context.push(
                          CustomerOrderDetailRoute(order.id).location,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCardEditorial extends StatelessWidget {
  const _OrderCardEditorial({required this.order, required this.feed});

  final OrderSummary order;
  final List<dynamic> feed;

  @override
  Widget build(BuildContext context) {
    final s = order.status.toUpperCase();
    final tone = _trackingTone(s);
    final title = (order.mealTitle ?? '').trim().isEmpty
        ? 'Corrientazo del día'
        : (order.mealTitle ?? '').trim();
    final human = _humanStatusLine(s);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: () => context.push(CustomerOrderDetailRoute(order.id).location),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark.withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color:
                (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderDark
                        : AppColors.border)
                    .withValues(alpha: 0.80),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.0
                    : 0.035,
              ),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                width: 84,
                height: 84,
                child: _OrderPhoto(
                  photoUrl: order.mealPhotoUrl,
                  fallbackSeed: order.mealPublicationId,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    human,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B4A3A).withValues(alpha: 0.74),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniPill(
                        label: _friendlyDate(order.createdAt),
                        tone: tone,
                      ),
                      const SizedBox(width: 8),
                      _MiniPill(label: _formatCop(order.totalCop), tone: tone),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
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

class _OrderPhoto extends StatelessWidget {
  const _OrderPhoto({required this.photoUrl, required this.fallbackSeed});

  final String? photoUrl;
  final String fallbackSeed;

  @override
  Widget build(BuildContext context) {
    final url = (photoUrl ?? '').trim();
    final food = ColombianFoodMock.forMeal(fallbackSeed);

    if (url.isEmpty) {
      return FoodImage(
        asset: food.imageAsset,
        fallbackGradient: food.heroGradient,
        fallbackIcon: food.heroIcon,
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => FoodImage(
        asset: food.imageAsset,
        fallbackGradient: food.heroGradient,
        fallbackIcon: food.heroIcon,
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return DecoratedBox(
          decoration: BoxDecoration(gradient: food.heroGradient),
          child: Center(
            child: Icon(
              food.heroIcon,
              size: 28,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: tone.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _SoftProgress extends StatelessWidget {
  const _SoftProgress({required this.current, required this.tone});

  final int current; // 0..3
  final Color tone;

  static const _labels = ['Recibido', 'Preparando', 'En camino', 'Entregado'];
  static const _icons = [
    Icons.check,
    Icons.restaurant,
    Icons.delivery_dining,
    Icons.door_front_door_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 18,
                child: Container(
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.20),
                ),
              ),
              Positioned(
                left: 0,
                top: 18,
                child: Container(
                  height: 2,
                  width: (c.maxWidth * ((current.clamp(0, 3)) / 3)),
                  color: tone.withValues(alpha: 0.75),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) {
                  final active = i <= current;
                  return Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: active
                              ? tone.withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: active
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  width: 3,
                                )
                              : null,
                        ),
                        child: Icon(
                          _icons[i],
                          size: 18,
                          color: Colors.white.withValues(
                            alpha: active ? 1.0 : 0.78,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _labels[i],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(
                            alpha: i == current ? 1.0 : 0.78,
                          ),
                          fontWeight: i == current
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _trackingTone(String statusUpper) {
  final s = statusUpper;
  if (s == 'CANCELLED' || s == 'REFUNDED') return AppColors.danger;
  if (s == 'DELIVERED' || s == 'READY_FOR_PICKUP' || s == 'PICKED_UP') {
    return AppColors.success;
  }
  if (s == 'CONFIRMED' || s == 'ACCEPTED') return AppColors.primary;
  if (s == 'PREPARING' || s == 'IN_KITCHEN') return AppColors.brand;
  if (s == 'ON_THE_WAY' || s == 'OUT_FOR_DELIVERY') return AppColors.accent;
  return AppColors.brand;
}

int _trackingStepIndex(String statusUpper) {
  switch (statusUpper) {
    case 'CONFIRMED':
    case 'ACCEPTED':
      return 0;
    case 'PREPARING':
    case 'IN_KITCHEN':
      return 1;
    case 'ON_THE_WAY':
    case 'OUT_FOR_DELIVERY':
    case 'READY_FOR_PICKUP':
    case 'PICKED_UP':
      return 2;
    case 'DELIVERED':
      return 3;
    default:
      return 1;
  }
}

(String, String) _humanTrackingCopy({
  required String status,
  required String cookName,
}) {
  switch (status) {
    case 'CONFIRMED':
    case 'ACCEPTED':
      return ('Pedido confirmado', '$cookName ya lo tiene en su cocina.');
    case 'PREPARING':
    case 'IN_KITCHEN':
      return (
        'Tu almuerzo ya está en preparación 🍲',
        '$cookName está cocinando tu pedido.',
      );
    case 'ON_THE_WAY':
    case 'OUT_FOR_DELIVERY':
      return (
        'Tu corrientazo ya va en camino',
        'Va saliendo calientico — ya casi.',
      );
    case 'READY_FOR_PICKUP':
      return (
        'Listo para recoger',
        'Está recién hecho. Cuando llegues, te lo entregan.',
      );
    case 'PICKED_UP':
      return ('Ya lo recogiste', 'Buen provecho — ojalá te sepa a hogar.');
    case 'DELIVERED':
      return (
        'Listo para disfrutar 👌',
        'Gracias por apoyar cocina de barrio.',
      );
    case 'CANCELLED':
      return ('Pedido cancelado', 'Si quieres, te ayudo a pedir otro.');
    default:
      return ('Preparando tu sabor', '$cookName lo está dejando perfecto.');
  }
}

String _humanStatusLine(String statusUpper) {
  switch (statusUpper) {
    case 'DELIVERED':
      return 'Listo para disfrutar 👌';
    case 'READY_FOR_PICKUP':
      return 'Listo para recoger';
    case 'ON_THE_WAY':
    case 'OUT_FOR_DELIVERY':
      return 'Ya va en camino';
    case 'PREPARING':
    case 'IN_KITCHEN':
      return 'En preparación 🍲';
    case 'CONFIRMED':
    case 'ACCEPTED':
      return 'Confirmado';
    case 'CANCELLED':
      return 'Cancelado';
    default:
      return 'En progreso';
  }
}

String _cookNameFor(OrderSummary order, List<dynamic> feed) {
  try {
    final id = order.mealPublicationId;
    for (final x in feed) {
      if (x.id == id) {
        final name = (x.cookName as String?)?.trim() ?? '';
        if (name.isNotEmpty) return name;
        break;
      }
    }
  } catch (_) {
    // best-effort enrichment
  }
  return 'Tu cook del barrio';
}

String? _cookProfileIdFor(OrderSummary order, List<dynamic> feed) {
  try {
    final id = order.mealPublicationId;
    for (final x in feed) {
      if (x.id == id) {
        final v = (x.cookProfileId as String?)?.trim() ?? '';
        if (v.isNotEmpty) return v;
        break;
      }
    }
  } catch (_) {
    // best-effort enrichment
  }
  return null;
}

String _shortOrderCode(String id) =>
    'Orden #${id.substring(0, 6).toUpperCase()}';

String _friendlyTime(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final hh = ((h + 11) % 12) + 1;
  final ap = h >= 12 ? 'PM' : 'AM';
  return '$hh:$m $ap';
}

String _friendlyDate(DateTime dt) {
  final now = DateTime.now();
  final d0 = DateTime(now.year, now.month, now.day);
  final d1 = DateTime(dt.year, dt.month, dt.day);
  final diff = d0.difference(d1).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return '${dt.day}/${dt.month}';
}

String _formatCop(int value) {
  final raw = value.toString();
  final b = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final idxFromEnd = raw.length - i;
    b.write(raw[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) b.write('.');
  }
  return 'COP \$${b.toString()}';
}
