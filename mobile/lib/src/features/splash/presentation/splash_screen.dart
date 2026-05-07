import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../../core/routing/app_router.dart';

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
        child: Text(
          'CORRIENTAZO',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

