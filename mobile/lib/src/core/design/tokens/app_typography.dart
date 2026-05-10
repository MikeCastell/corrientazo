import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía global CORRIENTAZO — **casual premium**, cálida y cercana (no fintech).
///
/// ### Familia principal: **Nunito**
/// - Formas redondeadas y amables, muy legible en móvil.
/// - Sensación “food / casero / startup latina” sin rigidez corporativa.
///
/// ### Alternativas que encajan con la misma dirección (si algún día cambias 1 línea):
/// - **Rubik**: un poco más urbano / street-food premium.
/// - **Outfit**: más geométrico; puede acercarse a “producto SaaS” si no se dosifica.
///
/// La jerarquía se ajusta aquí solamente; las pantallas siguen usando `Theme.of(context).textTheme`.
class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.text;
    final text2Color = isDark ? AppColors.text2Dark : AppColors.text2;

    final materialBase =
        ThemeData(brightness: brightness, useMaterial3: true).textTheme;
    final nunitoBase = GoogleFonts.nunitoTextTheme(materialBase);

    final t = nunitoBase.apply(
      bodyColor: textColor,
      displayColor: textColor,
      decorationColor: text2Color,
    );

    // Títulos: protagonistas, fuertes, con tracking cerrado (editorial moderna).
    // Cuerpo / microcopy: algo más aire y tracking neutro‑positivo → más humano y descansado.
    return t.copyWith(
      displayLarge: t.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.45,
        height: 1.02,
      ),
      displayMedium: t.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.15,
        height: 1.04,
      ),
      displaySmall: t.displaySmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        height: 1.06,
      ),
      headlineLarge: t.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.95,
        height: 1.06,
      ),
      headlineMedium: t.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.82,
        height: 1.08,
      ),
      headlineSmall: t.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.65,
        height: 1.10,
      ),
      titleLarge: t.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.42,
        height: 1.18,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.22,
        height: 1.22,
      ),
      titleSmall: t.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.08,
        height: 1.24,
      ),
      bodyLarge: t.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.06,
        height: 1.48,
      ),
      bodyMedium: t.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08,
        height: 1.44,
      ),
      bodySmall: t.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.12,
        height: 1.40,
      ),
      labelLarge: t.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.04,
        height: 1.25,
      ),
      labelMedium: t.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06,
        height: 1.22,
      ),
      labelSmall: t.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08,
        height: 1.18,
      ),
    );
  }
}
