import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../application/meals_controller.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/marketplace/cook_trust_chip.dart';
import '../../../core/ui/marketplace/marketplace_utils.dart';
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

    return AppScaffold(
      title: 'Detalle',
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          final item = items.where((x) => x.id == mealPublicationId).firstOrNull;
          if (item == null) return const Center(child: Text('No encontrado'));

          final eta = MarketplaceUtils.pseudoEtaMinutes(item.id);
          final km = MarketplaceUtils.pseudoDistanceKm(item.id);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Hero(
                tag: 'mealHero-${item.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryDeep.withValues(alpha: 0.70),
                                AppColors.secondaryDeep.withValues(alpha: 0.40),
                                AppColors.accentDeep.withValues(alpha: 0.22),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.restaurant, size: 56, color: Colors.white),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.00),
                                Colors.black.withValues(alpha: 0.36),
                                Colors.black.withValues(alpha: 0.70),
                              ],
                              stops: const [0.0, 0.52, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left: AppSpacing.md,
                          top: AppSpacing.md,
                          child: _MetaPill(
                            icon: Icons.bolt,
                            label: item.stockAvailable <= 0
                                ? 'Agotado'
                                : item.stockAvailable <= 3
                                    ? 'Últimos ${item.stockAvailable}'
                                    : 'Disponible',
                            tone: item.stockAvailable <= 3 ? AppColors.warning : AppColors.success,
                          ),
                        ),
                        Positioned(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: CookTrustChip(
                            cookName: 'Cocinero cercano',
                            isVerified: true,
                            sanitaryLevelLabel: 'Sanitario (próx)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Corrientazo del día',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Hecho cerca de ti · Disponible hoy',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              _MetaRow(
                etaMinutes: eta,
                distanceKm: km,
                stock: item.stockAvailable,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'Qué incluye',
                child: Text(
                  'Sopa + seco + bebida (próximamente detalles reales desde backend).',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionCard(
                title: 'Ingredientes',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _IngredientChip('Arroz'),
                    _IngredientChip('Proteína'),
                    _IngredientChip('Ensalada'),
                    _IngredientChip('Sopa'),
                    _IngredientChip('Bebida'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionCard(
                title: 'Confianza',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TrustLine(icon: Icons.verified_outlined, text: 'Identidad verificada (próx)'),
                    const SizedBox(height: 8),
                    _TrustLine(icon: Icons.shield_outlined, text: 'Nivel sanitario (próx)'),
                    const SizedBox(height: 8),
                    _TrustLine(icon: Icons.support_agent, text: 'Soporte en la app'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: item.stockAvailable <= 0
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          _openOrderSheet(context, ref, mealPublicationId: item.id);
                        },
                  child: Text(item.stockAvailable <= 0 ? 'Agotado' : 'Pedir ahora'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Recogida recomendada · Ahorra al recoger · ETA $eta min',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        },
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
      final order = await ref.read(orderFlowControllerProvider.notifier).submit(req);
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
    final isSoldOut = err is ApiErrorResponseException && err.code == 'ORDER_SOLD_OUT';

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.border)),
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
                      onPressed: _loading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _Segmented(
                  value: _fulfillment,
                  onChanged: _loading ? null : (v) => setState(() => _fulfillment = v),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        'COP',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (err != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: (isSoldOut ? AppColors.warning : AppColors.danger).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: (isSoldOut ? AppColors.warning : AppColors.danger).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSoldOut ? Icons.bolt : Icons.error_outline,
                          color: isSoldOut ? AppColors.warning : AppColors.danger,
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
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
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
    final bg = selected ? AppColors.brand.withValues(alpha: 0.10) : Colors.transparent;
    final border = selected ? AppColors.brand.withValues(alpha: 0.18) : Colors.transparent;
    final color = selected ? AppColors.brand : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70);

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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.etaMinutes,
    required this.distanceKm,
    required this.stock,
  });

  final int etaMinutes;
  final double distanceKm;
  final int stock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetaPill(icon: Icons.timer_outlined, label: '$etaMinutes min'),
        const SizedBox(width: AppSpacing.sm),
        _MetaPill(icon: Icons.place_outlined, label: '${distanceKm.toStringAsFixed(1)} km'),
        const SizedBox(width: AppSpacing.sm),
        _MetaPill(
          icon: stock <= 3 ? Icons.bolt : Icons.check_circle_outline,
          label: stock <= 0
              ? 'Agotado'
              : stock <= 3
                  ? 'Últimos $stock'
                  : 'Disponible',
          tone: stock <= 3 ? AppColors.warning : AppColors.success,
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.tone,
  });

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? AppColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                ),
          ),
        ),
      ],
    );
  }
}

