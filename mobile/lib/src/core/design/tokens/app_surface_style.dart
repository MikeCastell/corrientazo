import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Fondos pensados para **app de comida**: limpios, cálidos, que no compitan con fotos de platos.
///
/// Cambiá [kAppSurfaceStyle] y hacé hot restart.
///
/// - [flatKitchenMotifs] — **motivos de cocina** (sartén, vapor, plato, tomate, hoja) en esquinas,
///   misma idea de capas que los bloques viejos pero con temática culinaria.
/// - [flatCream] — crema uniforme (mantel), cero decoración.
/// - [flatTwoBand] — dos cremas muy cercanas (sutil).
/// - [flatDotPaper] — puntitos tipo papel menú.
/// - [gradientAmbient] — degradado suave + burbujas en [AppScaffold].
/// - [flatBrandFrame] — acento fino arriba/izquierda (marca).
enum AppSurfaceStyle {
  gradientAmbient,
  flatCream,
  flatTwoBand,
  flatDotPaper,
  flatBrandFrame,
  flatKitchenMotifs,
}

/// Fondo por defecto: motivos de cocina suaves sobre crema.
const AppSurfaceStyle kAppSurfaceStyle = AppSurfaceStyle.flatKitchenMotifs;

bool get kAppSurfaceShowsGlowBlobs =>
    kAppSurfaceStyle == AppSurfaceStyle.gradientAmbient;

/// Fondo de pantalla según [kAppSurfaceStyle].
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
      case AppSurfaceStyle.flatDotPaper:
        return _FlatDotPaper(isDark: isDark);
      case AppSurfaceStyle.flatBrandFrame:
        return _FlatBrandFrame(isDark: isDark);
      case AppSurfaceStyle.flatKitchenMotifs:
        return CustomPaint(
          painter: _KitchenMotifPainter(isDark: isDark),
          child: const SizedBox.expand(),
        );
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
    final hi = AppColors.surface2;
    final lo = AppColors.bg;
    return Column(
      children: [
        Expanded(child: ColoredBox(color: hi)),
        Expanded(child: ColoredBox(color: lo)),
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
        .withValues(alpha: isDark ? 0.045 : 0.04);
    const step = 22.0;
    final p = Paint()..color = dot;
    var row = 0;
    for (var y = 0.0; y < size.height; y += step, row++) {
      final offsetX = row % 2 == 0 ? 0.0 : step * 0.5;
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x + offsetX, y), 1.0, p);
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
          height: 3,
          child: ColoredBox(
            color: AppColors.primary.withValues(alpha: 0.45),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: 3,
          child: ColoredBox(
            color: AppColors.accent.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

/// Siluetas planas inspiradas en cocina casera (sin fotos, no compiten con cards).
class _KitchenMotifPainter extends CustomPainter {
  _KitchenMotifPainter({required this.isDark});

  final bool isDark;

  /// Opacidad en modo claro; en oscuro baja un poco para no ensuciar.
  double _a(double light) => isDark ? light * 0.42 : light;

  @override
  void paint(Canvas canvas, Size size) {
    final base = isDark ? AppColors.bgDark : AppColors.bg;
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // — Sartén (arriba-izquierda), misma zona que el bloque naranja viejo —
    canvas.save();
    canvas.translate(-size.width * 0.06, size.height * 0.02);
    canvas.rotate(-0.2);
    fill.color = AppColors.primary.withValues(alpha: _a(0.30));
    final panRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 36, 200, 40),
      const Radius.circular(20),
    );
    canvas.drawRRect(panRect, fill);
    fill.color = AppColors.primary.withValues(alpha: _a(0.36));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(188, 42, 64, 16),
        const Radius.circular(8),
      ),
      fill,
    );
    canvas.restore();

    // — Vapor (abajo-derecha), curvas suaves —
    canvas.save();
    canvas.translate(size.width * 0.62, size.height * 0.72);
    stroke
      ..strokeWidth = 4.2
      ..color = AppColors.accent.withValues(alpha: _a(0.28));
    for (var i = 0; i < 3; i++) {
      final ox = i * 22.0;
      final p = Path()
        ..moveTo(ox, 20)
        ..quadraticBezierTo(ox + 16, 0, ox + 4, -36)
        ..quadraticBezierTo(ox - 8, -52, ox + 2, -78);
      canvas.drawPath(p, stroke);
    }
    canvas.restore();

    // — Plato / fuente (arriba-derecha), solo borde —
    canvas.save();
    canvas.translate(size.width * 0.72, -size.height * 0.04);
    canvas.rotate(0.14);
    stroke
      ..strokeWidth = 5
      ..color = AppColors.secondary.withValues(alpha: _a(0.26));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 220, height: 64),
      stroke,
    );
    canvas.restore();

    // — “Tomate” redondo (derecha, centro-alto) —
    fill.color = AppColors.secondary.withValues(alpha: _a(0.24));
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.16),
      30,
      fill,
    );
    fill.color = AppColors.secondary.withValues(alpha: _a(0.12));
    canvas.drawCircle(Offset(size.width * 0.88 - 6, size.height * 0.14), 5, fill);

    // — Hoja / hierba (abajo-izquierda) —
    canvas.save();
    canvas.translate(size.width * 0.06, size.height * 0.78);
    canvas.rotate(-0.35);
    fill.color = AppColors.accent.withValues(alpha: _a(0.22));
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(36, -28, 72, -4)
      ..quadraticBezierTo(40, 20, 0, 0);
    canvas.drawPath(leaf, fill);
    canvas.restore();

    // — Cuchara / cazo simplificado (izquierda media), silueta redondeada —
    canvas.save();
    canvas.translate(size.width * 0.02, size.height * 0.38);
    canvas.rotate(0.55);
    fill.color = AppColors.primary.withValues(alpha: _a(0.14));
    canvas.drawOval(const Rect.fromLTWH(0, 0, 36, 52), fill);
    stroke
      ..strokeWidth = 5
      ..color = AppColors.primary.withValues(alpha: _a(0.20));
    canvas.drawLine(const Offset(18, 48), const Offset(18, 112), stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KitchenMotifPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
