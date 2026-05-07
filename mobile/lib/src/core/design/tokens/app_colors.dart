import 'package:flutter/material.dart';

/// Semantic color tokens for CORRIENTAZO.
class AppColors {
  // Gastronomic urban identity (rojo/verde/amarillo) — premium & warm.
  // Primary: rojo cálido (salsa/plancha), Secondary: verde fresco (cilantro/lima),
  // Accent: amarillo energético (maíz/aji), Neutrals: crema cálida.
  static const primary = Color(0xFFE23A2E); // warm red
  static const primaryDeep = Color(0xFFB9241B);
  static const secondary = Color(0xFF1F8A4C); // fresh green
  static const secondaryDeep = Color(0xFF16683A);
  static const accent = Color(0xFFF3B62B); // energetic yellow
  static const accentDeep = Color(0xFFCC951C);

  // Keep existing naming used across UI.
  static const brand = primary;
  static const brandDeep = primaryDeep;
  static const ember = primary;
  static const emberDeep = primaryDeep;
  static const neon = accent;
  static const night = Color(0xFF120B0A); // deep warm night (less "SaaS")
  static const night2 = Color(0xFF1A1210);

  // Neutrals
  static const bg = Color(0xFFFFF7ED); // warm cream
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFFFFBF5);
  static const border = Color(0xFFF1E3D6);

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
              const Color(0xFFFFF7ED),
              const Color(0xFFFFFBF5),
              primary.withValues(alpha: 0.08),
              secondary.withValues(alpha: 0.07),
              accent.withValues(alpha: 0.06),
            ],
      stops: isDark ? const [0.0, 0.45, 0.72, 0.88, 1.0] : const [0.0, 0.48, 0.74, 0.86, 1.0],
    );
  }
}

