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
import '../../features/customer/presentation/public_cook_profile_screen.dart';
import '../../features/cook/presentation/cook_dashboard_screen.dart';
import '../../features/cook/presentation/cook_meals_screen.dart';
import '../../features/cook/presentation/cook_create_meal_hub_screen.dart';
import '../../features/cook/presentation/cook_create_meal_screen.dart';
import '../../features/cook/presentation/cook_orders_screen.dart';
import '../../features/cook/presentation/cook_profile_screen.dart';
import '../../features/users/domain/current_user.dart';
import '../ui/shells/role_shells.dart';
import '../env/app_env.dart';

CustomTransitionPage<T> _fadeSlidePage<T>({
  required GoRouterState state,
  required Widget child,
  Offset begin = const Offset(0.0, 0.03),
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: animation.drive(slide), child: child),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (AppEnv.startupDebug) {
    debugPrint('[router] build with authState=${authState.runtimeType}');
  }

  return GoRouter(
    initialLocation: const SplashRoute().location,
    refreshListenable: _GoRouterRefresh(ref, authState),
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: const SplashRoute().location,
        name: SplashRoute.name,
        pageBuilder: (context, state) => _fadeSlidePage<void>(
          state: state,
          child: const SplashScreen(),
          begin: const Offset(0.0, 0.01),
        ),
      ),
      GoRoute(
        path: const LoginRoute().location,
        name: LoginRoute.name,
        pageBuilder: (context, state) => _fadeSlidePage<void>(
          state: state,
          child: const LoginScreen(),
          begin: const Offset(0.0, 0.02),
        ),
      ),
      GoRoute(
        path: const RegisterRoute().location,
        name: RegisterRoute.name,
        pageBuilder: (context, state) => _fadeSlidePage<void>(
          state: state,
          child: const RegisterScreen(),
          begin: const Offset(0.0, 0.02),
        ),
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
                pageBuilder: (context, state) => _fadeSlidePage<void>(
                  state: state,
                  child: const HomeMealsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'meals/:id',
                    name: MealDetailRoute.name,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _fadeSlidePage<void>(
                        state: state,
                        child: MealDetailScreen(mealPublicationId: id),
                        begin: const Offset(0.0, 0.04),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'orders/:id/success',
                    name: OrderSuccessRoute.name,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _fadeSlidePage<void>(
                        state: state,
                        child: OrderSuccessScreen(orderId: id),
                        begin: const Offset(0.0, 0.02),
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
                pageBuilder: (context, state) => _fadeSlidePage<void>(
                  state: state,
                  child: const CustomerOrdersScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: CustomerOrderDetailRoute.name,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _fadeSlidePage<void>(
                        state: state,
                        child: OrderDetailScreen(
                          orderId: id,
                          mode: OrderDetailMode.customer,
                        ),
                        begin: const Offset(0.02, 0.0),
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
                pageBuilder: (context, state) => _fadeSlidePage<void>(
                  state: state,
                  child: const CustomerProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      // Public cook profile (customer-facing). Keep it as a top-level route so it can
      // be opened from any tab without cross-branch push issues.
      GoRoute(
        path: PublicCookProfileRoute.pattern,
        name: PublicCookProfileRoute.name,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.trim().isEmpty) {
            return _fadeSlidePage<void>(
              state: state,
              child: const Scaffold(
                body: Center(child: Text('Perfil de cook inválido')),
              ),
              begin: const Offset(0.02, 0.0),
            );
          }
          return _fadeSlidePage<void>(
            state: state,
            child: PublicCookProfileScreen(cookProfileId: id),
            begin: const Offset(0.02, 0.0),
          );
        },
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
                pageBuilder: (context, state) => _fadeSlidePage<void>(
                  state: state,
                  child: const CookDashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CookMealsRoute().location,
                name: CookMealsRoute.name,
                pageBuilder: (context, state) => _fadeSlidePage<void>(
                  state: state,
                  child: const CookMealsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: const CookCreateMealRoute().location,
                name: CookCreateMealRoute.name,
                pageBuilder: (context, state) => _fadeSlidePage<void>(
                  state: state,
                  child: const CookCreateMealHubScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'form',
                    name: CookCreateMealFormRoute.name,
                    pageBuilder: (context, state) {
                      final editId = state.uri.queryParameters['edit'];
                      final templateId =
                          state.uri.queryParameters['template'];
                      final editMealId =
                          (editId != null && editId.isNotEmpty) ? editId : null;
                      final tplId = (templateId != null && templateId.isNotEmpty)
                          ? templateId
                          : null;
                      return _fadeSlidePage<void>(
                        state: state,
                        child: CookCreateMealScreen(
                          // Fuerza estado nuevo al cambiar ?edit= / ?template= (go() reutiliza la ruta).
                          key: ValueKey(
                            'cook-meal-form-${editMealId ?? ''}::${tplId ?? ''}',
                          ),
                          editMealId: editMealId,
                          templateId: tplId,
                        ),
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
                path: const CookOrdersRoute().location,
                name: CookOrdersRoute.name,
                pageBuilder: (context, state) => _fadeSlidePage<void>(
                  state: state,
                  child: const CookOrdersScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: CookOrderDetailRoute.name,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _fadeSlidePage<void>(
                        state: state,
                        child: OrderDetailScreen(
                          orderId: id,
                          mode: OrderDetailMode.cook,
                        ),
                        begin: const Offset(0.02, 0.0),
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
                pageBuilder: (context, state) => _fadeSlidePage<void>(
                  state: state,
                  child: const CookProfileScreen(),
                ),
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
        if (AppEnv.startupDebug) {
          debugPrint('[router] redirect (need login) loc="$loc" -> "$dest"');
        }
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
      if (AppEnv.startupDebug) {
        debugPrint('[router] redirect (no-op) loc="$loc" -> null');
      }
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

class PublicCookProfileRoute {
  const PublicCookProfileRoute(this.cookProfileId);
  final String cookProfileId;
  static const name = 'public_cook_profile';
  static const pattern = '/c/cooks/:id';
  String get location => '/c/cooks/$cookProfileId';
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

/// Formulario de alta/edición (`/k/create/form`).
class CookCreateMealFormRoute {
  const CookCreateMealFormRoute();

  static const name = 'cook_create_form';

  /// Query opcional: [editMealId] plato existente, [templateId] plantilla local.
  static String location({String? editMealId, String? templateId}) {
    final q = <String>[];
    if (editMealId != null && editMealId.isNotEmpty) {
      q.add('edit=${Uri.encodeQueryComponent(editMealId)}');
    }
    if (templateId != null && templateId.isNotEmpty) {
      q.add('template=${Uri.encodeQueryComponent(templateId)}');
    }
    final qs = q.isEmpty ? '' : '?${q.join('&')}';
    return '/k/create/form$qs';
  }
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
