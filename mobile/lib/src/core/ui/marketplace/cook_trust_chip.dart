import 'package:flutter/material.dart';

import '../../design/tokens/app_colors.dart';
import '../../design/tokens/app_radius.dart';
import '../../design/tokens/app_spacing.dart';

class CookTrustChip extends StatelessWidget {
  const CookTrustChip({
    super.key,
    required this.cookName,
    required this.isVerified,
    required this.sanitaryLevelLabel,
  });

  final String cookName;
  final bool isVerified;
  final String sanitaryLevelLabel; // future-ready label

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final bg = (isDark ? AppColors.surfaceDark : AppColors.surface).withValues(alpha: 0.70);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: border.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.22)),
            ),
            child: const Icon(Icons.person, size: 14, color: AppColors.brand),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              cookName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            icon: isVerified ? Icons.verified : Icons.verified_outlined,
            label: isVerified ? 'Verificado' : 'Verificación',
            color: isVerified ? AppColors.info : AppColors.text2,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            icon: Icons.shield_outlined,
            label: sanitaryLevelLabel,
            color: AppColors.brand,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

