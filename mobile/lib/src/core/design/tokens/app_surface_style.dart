import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilo de fondo global (MVP: cambiá [kAppSurfaceStyle] y hot restart).
///
/// Opciones **planas** (sin degradado suave tipo “atmósfera”):
/// - [flatCream] — un solo color crema (o noche en dark).
/// - [flatTwoBand] — dos franjas horizontales sólidas (papel doblado).
/// - [flatCornerBlocks] — bloques naranja/verde en esquinas, colores planos.
/// - [flatDotPaper] — crema + rejilla de puntitos (una tinta).
/// - [flatBrandFrame] — crema + franja superior naranja + acento lateral verde.
///
/// Con degradado (comportamiento anterior):
/// - [gradientAmbient] — gradiente + burbujas en [AppScaffold].
enum AppSurfaceStyle {
  gradientAmbient,
  flatCream,
  flatTwoBand,
  flatCornerBlocks,
  flatDotPaper,
  flatBrandFrame,
}

/// **Elegí el fondo aquí** (un solo valor para toda la app).
const AppSurfaceStyle kAppSurfaceStyle = AppSurfaceStyle.flatCornerBlocks;

bool get kAppSurfaceShowsGlowBlobs =>
    kAppSurfaceStyle == AppSurfaceStyle.gradientAmbient;

/// Fondo de pantalla según [kAppSurfaceStyle] (y modo claro/oscuro).
class AppSurfaceBackground extends StatelessWidget {
  const AppSurfaceBackground({super.key, required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    switch (kAppSurfaceStyle) {
      case AppSurfaceStyle.gradientAmbient:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.ambientBackground(brightness),
          ),
        );
      case AppSurfaceStyle.flatCream:
        return ColoredBox(
          color: isDark ? AppColors.bgDark : AppColors.bg,
        );
      case AppSurfaceStyle.flatTwoBand:
        return _FlatTwoBand(isDark: isDark);
      case AppSurfaceStyle.flatCornerBlocks:
        return _FlatCornerBlocks(isDark: isDark);
      case AppSurfaceStyle.flatDotPaper:
        return _FlatDotPaper(isDark: isDark);
      case AppSurfaceStyle.flatBrandFrame:
        return _FlatBrandFrame(isDark: isDark);
    }
  }
}

class _FlatTwoBand extends StatelessWidget {
  const _FlatTwoBand({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      return const ColoredBox(color: AppColors.bgDark);
    }
    const top = Color(0xFFFDF9F4);
    const bottom = Color(0xFFF5EFE6);
    return const Column(
      children: [
        Expanded(child: ColoredBox(color: top)),
        Expanded(child: ColoredBox(color: bottom)),
      ],
    );
  }
}

class _FlatCornerBlocks extends StatelessWidget {
  const _FlatCornerBlocks({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.bgDark : AppColors.bg;
    if (isDark) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: base),
          Positioned(
            top: 8,
            left: -24,
            child: Transform.rotate(
              angle: -0.16,
              child: Container(
                width: 200,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: -40,
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: 240,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(36),
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 8,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        // Bloques más grandes, más dentro de pantalla y más saturados (alfa alto).
        Positioned(
          top: 12,
          left: -28,
          child: Transform.rotate(
            angle: -0.16,
            child: Container(
              width: 260,
              height: 170,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: -48,
          child: Transform.rotate(
            angle: 0.2,
            child: Container(
              width: 280,
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),
        Positioned(
          top: 96,
          right: 4,
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.32),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 140,
          left: -20,
          child: Transform.rotate(
            angle: 0.12,
            child: Container(
              width: 120,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FlatDotPaper extends StatelessWidget {
  const _FlatDotPaper({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotGridPainter(isDark: isDark),
      child: const SizedBox.expand(),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final base = isDark ? AppColors.bgDark : AppColors.bg;
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    final dot = (isDark ? AppColors.text2Dark : AppColors.text2)
        .withValues(alpha: isDark ? 0.06 : 0.055);
    const step = 22.0;
    final p = Paint()..color = dot;
    var row = 0;
    for (var y = 0.0; y < size.height; y += step, row++) {
      final offsetX = row % 2 == 0 ? 0.0 : step * 0.5;
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x + offsetX, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _FlatBrandFrame extends StatelessWidget {
  const _FlatBrandFrame({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.bgDark : AppColors.bg;
    if (isDark) {
      return ColoredBox(color: base);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 5,
          child: ColoredBox(
            color: AppColors.primary.withValues(alpha: 0.85),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: 4,
          child: ColoredBox(
            color: AppColors.accent.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
