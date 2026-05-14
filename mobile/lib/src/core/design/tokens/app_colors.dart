import 'package:flutter/material.dart';

/// Semantic color tokens for CORRIENTAZO.
class AppColors {
  // Brand palette — alineado con `assets/branding/LogoOFICIAL.png`
  // - Primario: naranja “CORRIEN” (plato / texto)
  // - Secundario: rojo tomate (energía / CTAs fuertes)
  // - Acento: verde bosque “TAZO” / tagline (legible sobre crema)
  // - Fondo: crema cálida del logo (no blanco puro)
  static const primary = Color(0xFFE75F18); // naranja logo
  static const primaryDeep = Color(0xFFC44E0F);
  static const secondary = Color(0xFFD9482B); // Tomato Red
  static const secondaryDeep = Color(0xFFB9351C);
  static const accent = Color(0xFF1F5845); // verde bosque logo (TAZO)
  static const accentDeep = Color(0xFF163E32);

  // Keep existing naming used across UI.
  static const brand = primary;
  static const brandDeep = primaryDeep;
  static const ember = primary;
  static const emberDeep = primaryDeep;
  static const neon = accent;
  static const night = Color(0xFF120B0A); // deep warm night (less "SaaS")
  static const night2 = Color(0xFF1A1210);

  // Neutrals (fondo tipo lienzo del logo)
  static const bg = Color(0xFFFAF7F2); // crema cálida logo
  static const surface = Color(0xFFFFFFFF); // arroz / tarjetas
  static const surface2 = Color(0xFFFFFBF7);
  static const border = Color(0xFFE8DFD4);

  static const text = Color(0xFF0F172A);
  static const text2 = Color(0xFF64748B);

  // Semantic states
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF2563EB);

  // Dark
  static const bgDark = night;
  static const surfaceDark = Color(0xFF1A1210);
  static const borderDark = Color(0xFF2A1D1A);
  static const textDark = Color(0xFFF8FAFC);
  static const text2Dark = Color(0xFFCAB8AF);

  // Atmosphere helpers (cheap, deterministic)
  static LinearGradient ambientBackground(Brightness b) {
    final isDark = b == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              night,
              night2,
              primaryDeep.withValues(alpha: 0.22),
              secondary.withValues(alpha: 0.10),
              accent.withValues(alpha: 0.08),
            ]
          : [
              bg,
              surface2,
              primary.withValues(alpha: 0.11),
              secondary.withValues(alpha: 0.085),
              accent.withValues(alpha: 0.09),
            ],
      stops: isDark
          ? const [0.0, 0.45, 0.72, 0.88, 1.0]
          : const [0.0, 0.48, 0.74, 0.86, 1.0],
    );
  }
}
