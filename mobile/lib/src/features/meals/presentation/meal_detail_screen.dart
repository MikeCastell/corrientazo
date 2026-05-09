import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../application/meals_controller.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/states/app_loading_center.dart';
import '../../../core/ui/marketplace/cook_trust_chip.dart';
import '../../../core/ui/marketplace/food_image.dart';
import '../../../core/ui/marketplace/marketplace_utils.dart';
import '../../../core/food/colombian_food_mock.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/networking/api_exception.dart';
import '../../orders/application/order_flow_controller.dart';
import '../../orders/domain/order_create_request.dart';
import '../../customer/data/customer_orders_store.dart';
import 'package:go_router/go_router.dart';

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key, required this.mealPublicationId});

  final String mealPublicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(mealsFeedProvider);

    return feed.when(
      loading: () => const AppScaffold(
        title: '',
        body: AppLoadingCenter(message: 'Cargando este plato…'),
      ),
      error: (e, _) => AppScaffold(
        title: '',
        body: Center(child: Text(e.toString())),
      ),
      data: (items) {
        final item = items.where((x) => x.id == mealPublicationId).firstOrNull;
        if (item == null) {
          return const AppScaffold(
            title: '',
            body: Center(child: Text('No encontrado')),
          );
        }

        final eta = MarketplaceUtils.pseudoEtaMinutes(item.id);
        final km = MarketplaceUtils.pseudoDistanceKm(item.id);
        final food = ColombianFoodMock.fromPublished(
          seed: item.mealId,
          title: item.title,
          photoUrl: item.photoUrl,
          cookName: item.cookName,
          cookAvatarUrl: item.cookAvatarUrl,
        );
        final description = (item.description ?? '').trim().isEmpty
            ? food.description
            : (item.description ?? '').trim();
        final ingredients = (item.tags == null || item.tags!.isEmpty)
            ? food.ingredients
            : item.tags!;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 460,
                backgroundColor: Colors.black,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'mealHero-${item.id}',
                        child: FoodImage(
                          asset: food.imageAsset,
                          fallbackGradient: food.heroGradient,
                          fallbackIcon: food.heroIcon,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.20),
                              Colors.black.withValues(alpha: 0.22),
                              const Color(0xFF1A0B06).withValues(alpha: 0.62),
                              Colors.black.withValues(alpha: 0.92),
                            ],
                            stops: const [0.0, 0.35, 0.75, 1.0],
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.35, -0.55),
                            radius: 1.05,
                            colors: [
                              Colors.white.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
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
                            Text(
                              food.category.toUpperCase(),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              food.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.9,
                                    height: 1.03,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                _MetaPill(
                                  icon: Icons.timer_outlined,
                                  label: '$eta min',
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _MetaPill(
                                  icon: Icons.place_outlined,
                                  label: '${km.toStringAsFixed(1)} km',
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _MetaPill(
                                  icon: item.stockAvailable <= 3
                                      ? Icons.bolt
                                      : Icons.check_circle_outline,
                                  label: item.stockAvailable <= 0
                                      ? 'Agotado'
                                      : item.stockAvailable <= 3
                                      ? 'Últimos ${item.stockAvailable}'
                                      : 'Disponible',
                                  tone: item.stockAvailable <= 3
                                      ? AppColors.warning
                                      : AppColors.success,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            CookTrustChip(
                              cookName: food.cookName,
                              cookAvatarUrl: item.cookAvatarUrl,
                              isVerified: true,
                              sanitaryLevelLabel: 'Sanitario (próx)',
                            ),
                          ],
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
                    AppSpacing.lg,
                    AppSpacing.md,
                    140,
                  ),
                  child: Column(
                    children: [
                      _SectionCard(
                        title: 'Qué incluye',
                        child: Text(
                          description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.35),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Ingredientes',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ingredients
                              .map(_IngredientChip.new)
                              .toList(growable: false),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Confianza',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TrustLine(
                              icon: Icons.verified_outlined,
                              text: 'Identidad verificada (próx)',
                            ),
                            const SizedBox(height: 8),
                            _TrustLine(
                              icon: Icons.shield_outlined,
                              text: 'Nivel sanitario (próx)',
                            ),
                            const SizedBox(height: 8),
                            _TrustLine(
                              icon: Icons.support_agent,
                              text: 'Soporte en la app',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: item.stockAvailable <= 0
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          _openOrderSheet(
                            context,
                            ref,
                            mealPublicationId: item.id,
                          );
                        },
                  child: Text(
                    item.stockAvailable <= 0 ? 'Agotado' : 'Pedir ahora',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.brand,
        ),
      ),
    );
  }
}

Future<void> _openOrderSheet(
  BuildContext context,
  WidgetRef ref, {
  required String mealPublicationId,
}) async {
  ref.read(orderFlowControllerProvider.notifier).reset();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OrderSheet(mealPublicationId: mealPublicationId),
  );
}

class _OrderSheet extends ConsumerStatefulWidget {
  const _OrderSheet({required this.mealPublicationId});
  final String mealPublicationId;

  @override
  ConsumerState<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends ConsumerState<_OrderSheet> {
  String _fulfillment = 'PICKUP';
  bool _loading = false;
  ApiException? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final req = OrderCreateRequest(
        mealPublicationId: widget.mealPublicationId,
        quantity: 1,
        fulfillmentType: _fulfillment,
        deliveryAddressId: null,
      );
      final order = await ref
          .read(orderFlowControllerProvider.notifier)
          .submit(req);
      if (!mounted) return;
      await ref.read(customerOrdersStoreProvider).addRecentOrderId(order.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('${const HomeRoute().location}/orders/${order.id}/success');
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;

    final err = _error;
    final isSoldOut =
        err is ApiErrorResponseException && err.code == 'ORDER_SOLD_OUT';

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: (isDark ? AppColors.borderDark : AppColors.border),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tu pedido',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _Segmented(
                  value: _fulfillment,
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _fulfillment = v),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant, color: AppColors.brand),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Corrientazo del día · x1',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        'COP',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (err != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: (isSoldOut ? AppColors.warning : AppColors.danger)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color:
                            (isSoldOut ? AppColors.warning : AppColors.danger)
                                .withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSoldOut ? Icons.bolt : Icons.error_outline,
                          color: isSoldOut
                              ? AppColors.warning
                              : AppColors.danger,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            isSoldOut
                                ? 'Se agotó justo ahora. Prueba otro corrientazo.'
                                : err.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Confirmando…' : 'Confirmar pedido'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    'Sin pagos todavía · Solo validamos el flujo',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegButton(
              selected: value == 'PICKUP',
              label: 'Recoger',
              icon: Icons.store_mall_directory_outlined,
              onTap: onChanged == null ? null : () => onChanged!('PICKUP'),
            ),
          ),
          Expanded(
            child: _SegButton(
              selected: value == 'DELIVERY',
              label: 'Domicilio',
              icon: Icons.delivery_dining,
              onTap: onChanged == null ? null : () => onChanged!('DELIVERY'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.brand.withValues(alpha: 0.10)
        : Colors.transparent;
    final border = selected
        ? AppColors.brand.withValues(alpha: 0.18)
        : Colors.transparent;
    final color = selected
        ? AppColors.brand
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70);

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? AppColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 16, color: AppColors.brand),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}
