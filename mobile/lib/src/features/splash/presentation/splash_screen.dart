import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/env/app_env.dart';
import '../../auth/application/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.995,
    end: 1.01,
  ).chain(CurveTween(curve: Curves.easeInOutCubic)).animate(_breath);

  late final Animation<double> _logoGlow = Tween<double>(
    begin: 0.05,
    end: 0.11,
  ).chain(CurveTween(curve: Curves.easeInOutCubic)).animate(_breath);

  static const _messages = <String>[
    'Cargando sabor de hogar…',
    'Buscando corrientazos cerca de ti…',
    'Preparando algo delicioso…',
    'Hoy se come bueno.',
  ];

  int _msgIndex = 0;
  Timer? _rotator;

  @override
  void initState() {
    super.initState();
    _rotator = Timer.periodic(const Duration(milliseconds: 1850), (_) {
      if (!mounted) return;
      setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _rotator?.cancel();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final status = ref.watch(authDebugStatusProvider);

    if (AppEnv.startupDebug) {
      // ignore: avoid_print
      debugPrint(
        '[splash] build authState=${authState.runtimeType} status="$status"',
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final titleTone = AppColors.secondary; // Tomato Red
    final subtleText = scheme.onSurface.withValues(alpha: 0.62);
    final warmBrown = const Color(0xFF6B4A3A).withValues(alpha: 0.82);

    final loadingLabel = AppEnv.startupDebug ? status : _messages[_msgIndex];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Warm ambient wash (very subtle)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bg,
                    AppColors.bg,
                    AppColors.primary.withValues(alpha: 0.04),
                    AppColors.accent.withValues(alpha: 0.03),
                  ],
                  stops: const [0.0, 0.55, 0.80, 1.0],
                ),
              ),
            ),
          ),

          // Bogotá silhouette (monochrome, low opacity)
          Positioned(
            left: 0,
            right: 0,
            bottom: -4,
            height: math.min(240, MediaQuery.sizeOf(context).height * 0.28),
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BogotaSilhouettePainter(
                  color: const Color(0xFF6B4A3A).withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _breath,
                        builder: (context, _) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(
                                  alpha: 0.92,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl + 6,
                                ),
                                border: Border.all(
                                  color: AppColors.border.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: _logoGlow.value,
                                    ),
                                    blurRadius: 34,
                                    offset: const Offset(0, 18),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 26,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/branding/LogoOFICIAL.png',
                                height: 140,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'CORRIENTAZO',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: titleTone,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sabor de hogar, directo a tu mesa',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: warmBrown,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _WarmDots(),
                      const SizedBox(height: AppSpacing.lg),
                      Column(
                        children: [
                          Text(
                            'BOGOTÁ, COLOMBIA',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  letterSpacing: 2.1,
                                  fontWeight: FontWeight.w900,
                                  color: subtleText,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 86,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.border.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Emotional loading line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.soup_kitchen_outlined,
                            size: 18,
                            color: AppColors.accentDeep.withValues(alpha: 0.72),
                          ),
                          const SizedBox(width: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: Text(
                              loadingLabel,
                              key: ValueKey(loadingLabel),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.70,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),

                      if (AppEnv.startupDebug) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'AuthState: ${authState.runtimeType}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmDots extends StatefulWidget {
  const _WarmDots();

  @override
  State<_WarmDots> createState() => _WarmDotsState();
}

class _WarmDotsState extends State<_WarmDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tones = <Color>[
      AppColors.secondary, // tomato
      AppColors.primary, // mango/orange
      AppColors.border.withValues(alpha: 0.85), // beige
    ];
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (t + i * 0.18) % 1.0;
            final a = 0.35 + 0.55 * (0.5 + 0.5 * math.sin(phase * math.pi * 2));
            return Container(
              margin: EdgeInsets.only(right: i == 2 ? 0 : 10),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: tones[i].withValues(alpha: a.clamp(0.15, 0.95)),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        );
      },
    );
  }
}

class _BogotaSilhouettePainter extends CustomPainter {
  const _BogotaSilhouettePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;

    // Back mountains (cerros)
    final m = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.44,
        size.width * 0.36,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.70,
        size.width * 0.72,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.40,
        size.width,
        size.height * 0.52,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(m, p);

    // City blocks (low skyline + church tower)
    final c = Paint()..color = color.withValues(alpha: color.a * 0.9);
    final baseY = size.height * 0.68;

    void block(double x, double w, double h) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, baseY - h, w, h + (size.height - baseY)),
          const Radius.circular(6),
        ),
        c,
      );
    }

    final unit = size.width / 16;
    block(unit * 0.7, unit * 1.3, size.height * 0.10);
    block(unit * 2.2, unit * 1.1, size.height * 0.14);
    block(unit * 3.6, unit * 1.8, size.height * 0.09);
    block(unit * 5.8, unit * 1.2, size.height * 0.16);
    block(unit * 7.2, unit * 2.2, size.height * 0.11);
    block(unit * 9.8, unit * 1.4, size.height * 0.15);
    block(unit * 11.5, unit * 1.8, size.height * 0.10);
    block(unit * 13.5, unit * 1.1, size.height * 0.13);

    // Church tower hint
    final towerX = unit * 8.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          towerX,
          baseY - size.height * 0.20,
          unit * 0.6,
          size.height * 0.20 + (size.height - baseY),
        ),
        const Radius.circular(6),
      ),
      c,
    );
    canvas.drawCircle(
      Offset(towerX + unit * 0.3, baseY - size.height * 0.22),
      unit * 0.16,
      c,
    );

    // Light fog layer
    final fog = Paint()
      ..color = AppColors.bg.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRect(Rect.fromLTWH(0, baseY - 26, size.width, size.height), fog);
  }

  @override
  bool shouldRepaint(covariant _BogotaSilhouettePainter oldDelegate) =>
      oldDelegate.color != color;
}
