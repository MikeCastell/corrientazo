import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/meals/presentation/meal_detail_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/orders/presentation/order_success_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/meals/presentation/home_meals_screen.dart';
import '../../features/customer/presentation/customer_orders_screen.dart';
import '../../features/customer/presentation/customer_profile_screen.dart';
import '../../features/cook/presentation/cook_dashboard_screen.dart';
import '../../features/cook/presentation/cook_meals_screen.dart';
import '../../features/cook/presentation/cook_create_meal_screen.dart';
import '../../features/cook/presentation/cook_orders_screen.dart';
import '../../features/cook/presentation/cook_profile_screen.dart';
import '../../features/users/domain/current_user.dart';
import '../ui/shells/role_shells.dart';
import '../env/app_env.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (AppEnv.startupDebug)
    debugPrint('[router] build with authState=${authState.runtimeType}');

  return GoRouter(
    initialLocation: const SplashRoute().location,
    refreshListenable: _GoRouterRefresh(ref, authState),
    debugLogDiagnostics: true,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CustomerHomeRoute().location,
                name: CustomerHomeRoute.name,
                builder: (context, state) => const HomeMealsScreen(),
                routes: [
                  GoRoute(
                    path: 'meals/:id',
                    name: MealDetailRoute.name,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return CustomTransitionPage<void>(
                        key: state.pageKey,
                        child: MealDetailScreen(mealPublicationId: id),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              final slide = Tween<Offset>(
                                begin: const Offset(0.0, 0.04),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOutCubic));
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: animation.drive(slide),
                                  child: child,
                                ),
                              );
                            },
                      );
                    },
                  ),
                  GoRoute(
                    path: 'orders/:id/success',
                    name: OrderSuccessRoute.name,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return CustomTransitionPage<void>(
                        key: state.pageKey,
                        child: OrderSuccessScreen(orderId: id),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              final fade = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              );
                              return FadeTransition(
                                opacity: fade,
                                child: child,
                              );
                            },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CustomerOrdersRoute().location,
                name: CustomerOrdersRoute.name,
                builder: (context, state) => const CustomerOrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: CustomerOrderDetailRoute.name,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return OrderDetailScreen(
                        orderId: id,
                        mode: OrderDetailMode.customer,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CustomerProfileRoute().location,
                name: CustomerProfileRoute.name,
                builder: (context, state) => const CustomerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CookShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CookDashboardRoute().location,
                name: CookDashboardRoute.name,
                builder: (context, state) => const CookDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CookMealsRoute().location,
                name: CookMealsRoute.name,
                builder: (context, state) => const CookMealsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CookCreateMealRoute().location,
                name: CookCreateMealRoute.name,
                builder: (context, state) {
                  final editId = state.uri.queryParameters['edit'];
                  return CookCreateMealScreen(editMealId: editId);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CookOrdersRoute().location,
                name: CookOrdersRoute.name,
                builder: (context, state) => const CookOrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: CookOrderDetailRoute.name,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return OrderDetailScreen(
                        orderId: id,
                        mode: OrderDetailMode.cook,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CookProfileRoute().location,
                name: CookProfileRoute.name,
                builder: (context, state) => const CookProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isSplash = loc == const SplashRoute().location;
      final isAuthRoute =
          loc == const LoginRoute().location ||
          loc == const RegisterRoute().location;
      final isUnknown = authState is AuthUnknown;
      final isLoggedIn = authState is Authenticated;
      final role = authState is Authenticated ? authState.user.role : null;
      final isCustomerArea = loc.startsWith('/c');
      final isCookArea = loc.startsWith('/k');

      // While bootstrapping auth, keep user on splash only.
      if (isUnknown) {
        final dest = isSplash ? null : const SplashRoute().location;
        if (AppEnv.startupDebug) {
          debugPrint(
            '[router] redirect (unknown) loc="$loc" -> ${dest ?? "null"}',
          );
        }
        return dest;
      }

      // Once auth is known, splash should immediately resolve.
      if (isSplash) {
        final dest = isLoggedIn
            ? (role == UserRole.cook
                  ? const CookDashboardRoute().location
                  : const CustomerHomeRoute().location)
            : const LoginRoute().location;
        if (AppEnv.startupDebug) {
          debugPrint(
            '[router] redirect (splash resolved) loc="$loc" -> "$dest"',
          );
        }
        return dest;
      }

      if (!isLoggedIn && !isAuthRoute) {
        const dest = '/login';
        if (AppEnv.startupDebug)
          debugPrint('[router] redirect (need login) loc="$loc" -> "$dest"');
        return dest;
      }
      if (isLoggedIn) {
        if (role == UserRole.cook) {
          if (isAuthRoute) return const CookDashboardRoute().location;
          if (isCustomerArea) return const CookDashboardRoute().location;
        } else {
          if (isAuthRoute) return const CustomerHomeRoute().location;
          if (isCookArea) return const CustomerHomeRoute().location;
        }
      }
      if (AppEnv.startupDebug)
        debugPrint('[router] redirect (no-op) loc="$loc" -> null');
      return null;
    },
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
});

class _GoRouterRefresh extends ChangeNotifier {
  _GoRouterRefresh(this.ref, this.state) {
    ref.listen<AuthState>(
      authControllerProvider,
      (_, next) => notifyListeners(),
    );
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
  String get location => const CustomerHomeRoute().location;
}

class MealDetailRoute {
  const MealDetailRoute();
  static const name = 'meal_detail';
}

class OrderSuccessRoute {
  const OrderSuccessRoute();
  static const name = 'order_success';
}

class CustomerHomeRoute {
  const CustomerHomeRoute();
  static const name = 'customer_home';
  String get location => '/c/home';
}

class CustomerOrdersRoute {
  const CustomerOrdersRoute();
  static const name = 'customer_orders';
  String get location => '/c/orders';
}

class CustomerOrderDetailRoute {
  const CustomerOrderDetailRoute(this.orderId);
  final String orderId;
  static const name = 'customer_order_detail';
  String get location => '/c/orders/$orderId';
}

class CustomerProfileRoute {
  const CustomerProfileRoute();
  static const name = 'customer_profile';
  String get location => '/c/profile';
}

class CookDashboardRoute {
  const CookDashboardRoute();
  static const name = 'cook_dashboard';
  String get location => '/k/dashboard';
}

class CookMealsRoute {
  const CookMealsRoute();
  static const name = 'cook_meals';
  String get location => '/k/meals';
}

class CookCreateMealRoute {
  const CookCreateMealRoute();
  static const name = 'cook_create_meal';
  String get location => '/k/create';
}

class CookOrdersRoute {
  const CookOrdersRoute();
  static const name = 'cook_orders';
  String get location => '/k/orders';
}

class CookOrderDetailRoute {
  const CookOrderDetailRoute(this.orderId);
  final String orderId;
  static const name = 'cook_order_detail';
  String get location => '/k/orders/$orderId';
}

class CookProfileRoute {
  const CookProfileRoute();
  static const name = 'cook_profile';
  String get location => '/k/profile';
}
