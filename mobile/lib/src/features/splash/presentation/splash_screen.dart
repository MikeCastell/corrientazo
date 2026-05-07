import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/env/app_env.dart';
import '../../auth/application/auth_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final status = ref.watch(authDebugStatusProvider);

    if (AppEnv.startupDebug) {
      // ignore: avoid_print
      debugPrint('[splash] build authState=${authState.runtimeType} status="$status"');
    }

    return Scaffold(
      body: Center(
        child: _SplashMark(
          debugStatus: status,
          authStateLabel: authState.runtimeType.toString(),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark({
    required this.debugStatus,
    required this.authStateLabel,
  });

  final String debugStatus;
  final String authStateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.22)),
          ),
          child: const Icon(Icons.restaurant, color: AppColors.brand, size: 30),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'CORRIENTAZO',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Comida casera cerca de ti',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
        ),
        if (AppEnv.startupDebug) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.14)),
            ),
            child: Column(
              children: [
                Text(
                  debugStatus,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AuthState: $authStateLabel',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

