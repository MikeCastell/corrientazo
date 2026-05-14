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
      return ColoredBox(color: base);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        Positioned(
          top: -40,
          left: -50,
          child: Transform.rotate(
            angle: -0.18,
            child: Container(
              width: 180,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -60,
          child: Transform.rotate(
            angle: 0.22,
            child: Container(
              width: 200,
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: -30,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
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
