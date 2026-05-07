import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_spacing.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is Authenticated) {
        context.go(const HomeRoute().location);
      } else if (next is Unauthenticated) {
        context.go(const LoginRoute().location);
      }
    });

    return const Scaffold(
      body: Center(
        child: _SplashMark(),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

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
      ],
    );
  }
}

