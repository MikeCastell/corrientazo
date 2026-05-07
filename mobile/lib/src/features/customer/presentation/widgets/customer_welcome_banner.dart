import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/app_colors.dart';
import '../../../../core/design/tokens/app_radius.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/ux/ux_milestones_store.dart';

/// Dismissible “first visit” welcome — syncs to [UxMilestonesStore].
class CustomerWelcomeBanner extends ConsumerStatefulWidget {
  const CustomerWelcomeBanner({super.key});

  @override
  ConsumerState<CustomerWelcomeBanner> createState() =>
      _CustomerWelcomeBannerState();
}

class _CustomerWelcomeBannerState extends ConsumerState<CustomerWelcomeBanner> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();

    final store = ref.read(uxMilestonesStoreProvider);
    if (store.customerWelcomeDismissed) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Material(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + 2,
              AppSpacing.xs,
              AppSpacing.sm + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏠', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No cocines hoy',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Encuentra algo casero cerca de ti. '
                        'Cupos reales, cocina real.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () async {
                    await ref
                        .read(uxMilestonesStoreProvider)
                        .dismissCustomerWelcome();
                    if (!mounted) return;
                    setState(() => _hidden = true);
                  },
                  icon: Icon(
                    Icons.close,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}
