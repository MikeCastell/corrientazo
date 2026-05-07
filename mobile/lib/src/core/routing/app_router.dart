import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/meals/presentation/home_meals_screen.dart';
import '../../features/meals/presentation/meal_detail_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/application/auth_controller.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: const SplashRoute().location,
    refreshListenable: _GoRouterRefresh(ref, authState),
    routes: [
      GoRoute(
        path: const SplashRoute().location,
        name: SplashRoute.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: const LoginRoute().location,
        name: LoginRoute.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: const RegisterRoute().location,
        name: RegisterRoute.name,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: const HomeRoute().location,
        name: HomeRoute.name,
        builder: (context, state) => const HomeMealsScreen(),
        routes: [
          GoRoute(
            path: 'meals/:id',
            name: MealDetailRoute.name,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MealDetailScreen(mealPublicationId: id);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isSplash = loc == const SplashRoute().location;
      final isAuthRoute = loc == const LoginRoute().location || loc == const RegisterRoute().location;
      final isLoggedIn = authState is Authenticated;

      if (isSplash) return null;

      if (!isLoggedIn && !isAuthRoute) return const LoginRoute().location;
      if (isLoggedIn && isAuthRoute) return const HomeRoute().location;
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(state.error.toString())),
    ),
  );
});

class _GoRouterRefresh extends ChangeNotifier {
  _GoRouterRefresh(this.ref, this.state) {
    ref.listen<AuthState>(authControllerProvider, (_, next) => notifyListeners());
  }

  final Ref ref;
  final AuthState state;
}

class SplashRoute {
  const SplashRoute();
  static const name = 'splash';
  String get location => '/';
}

class LoginRoute {
  const LoginRoute();
  static const name = 'login';
  String get location => '/login';
}

class RegisterRoute {
  const RegisterRoute();
  static const name = 'register';
  String get location => '/register';
}

class HomeRoute {
  const HomeRoute();
  static const name = 'home';
  String get location => '/home';
}

class MealDetailRoute {
  const MealDetailRoute();
  static const name = 'meal_detail';
}

