import 'package:flutter/material.dart';

class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    required this.asset,
    required this.fallbackGradient,
    required this.fallbackIcon,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final LinearGradient fallbackGradient;
  final IconData fallbackIcon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (asset.startsWith('http://') || asset.startsWith('https://')) {
      return Image.network(
        asset,
        fit: fit,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _FallbackFoodImage(
            gradient: fallbackGradient,
            icon: fallbackIcon,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _FallbackFoodImage(
            gradient: fallbackGradient,
            icon: fallbackIcon,
          );
        },
      );
    }

    return Image.asset(
      asset,
      fit: fit,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _FallbackFoodImage(
          gradient: fallbackGradient,
          icon: fallbackIcon,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _FallbackFoodImage(
          gradient: fallbackGradient,
          icon: fallbackIcon,
        );
      },
    );
  }
}

class _FallbackFoodImage extends StatelessWidget {
  const _FallbackFoodImage({required this.gradient, required this.icon});

  final LinearGradient gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Center(child: Icon(icon, size: 52, color: Colors.white)),
    );
  }
}
