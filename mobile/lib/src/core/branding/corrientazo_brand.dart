import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/tokens/app_colors.dart';

/// Rutas de assets de marca. Sustituí `logo_marca.png` por tu logo nuevo (mismo nombre).
class BrandAssets {
  static const String logoMarca = 'assets/branding/logo_marca.png';
  static const String logoFallback = 'assets/branding/LogoOFICIAL.png';
}

/// Ilustración principal del logo (PNG).
class CorrientazoLogoMark extends StatelessWidget {
  const CorrientazoLogoMark({
    super.key,
    this.height = 120,
    this.semanticLabel = 'Logo CORRIENTAZO',
  });

  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Image.asset(
        BrandAssets.logoMarca,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Image.asset(
          BrandAssets.logoFallback,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// **CORRIEN** (naranja) + **TAZO** (verde), como en el logo.
class CorrientazoWordmark extends StatelessWidget {
  const CorrientazoWordmark({
    super.key,
    this.fontSize = 28,
    this.textAlign = TextAlign.center,
    this.maxLines = 1,
  });

  final double fontSize;
  final TextAlign textAlign;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.fredoka(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: -0.5,
    );
    return Text.rich(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: maxLines > 1,
      TextSpan(
        children: [
          TextSpan(text: 'CORRIEN', style: base.copyWith(color: AppColors.primary)),
          TextSpan(text: 'TAZO', style: base.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }
}

/// Línea tipo logo: — SABOR DE HOGAR —
class CorrientazoTagline extends StatelessWidget {
  const CorrientazoTagline({
    super.key,
    this.fontSize = 13,
    this.textAlign = TextAlign.center,
  });

  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final dash = GoogleFonts.fredoka(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      letterSpacing: 0.5,
    );
    final body = GoogleFonts.fredoka(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.accent,
      letterSpacing: 1.6,
    );
    return Text.rich(
      textAlign: textAlign,
      TextSpan(
        children: [
          TextSpan(text: '— ', style: dash),
          TextSpan(text: 'SABOR DE HOGAR', style: body),
          TextSpan(text: ' —', style: dash),
        ],
      ),
    );
  }
}

/// Bloque hero: logo + wordmark + tagline (login / splash / piezas grandes).
class CorrientazoBrandBlock extends StatelessWidget {
  const CorrientazoBrandBlock({
    super.key,
    this.logoHeight = 100,
    this.wordmarkSize = 30,
    this.taglineSize = 12,
    this.spacingAfterLogo = 12,
    this.spacingAfterWordmark = 6,
  });

  final double logoHeight;
  final double wordmarkSize;
  final double taglineSize;
  final double spacingAfterLogo;
  final double spacingAfterWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CorrientazoLogoMark(height: logoHeight),
        SizedBox(height: spacingAfterLogo),
        CorrientazoWordmark(fontSize: wordmarkSize),
        SizedBox(height: spacingAfterWordmark),
        CorrientazoTagline(fontSize: taglineSize),
      ],
    );
  }
}
