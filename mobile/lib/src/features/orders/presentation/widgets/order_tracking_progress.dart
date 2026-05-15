import 'package:flutter/material.dart';

import '../../domain/order_tracking.dart';

/// Barra de progreso continua (sustituye los puntitos del timeline).
class OrderTrackingProgress extends StatelessWidget {
  const OrderTrackingProgress({
    super.key,
    required this.status,
    required this.fulfillmentType,
    required this.tone,
    this.lightOnDark = true,
  });

  final String status;
  final String fulfillmentType;
  final Color tone;
  final bool lightOnDark;

  @override
  Widget build(BuildContext context) {
    final tracking = orderTrackingSnapshot(
      status: status,
      fulfillmentType: fulfillmentType,
    );
    final trackColor = lightOnDark
        ? Colors.white.withValues(alpha: 0.22)
        : Theme.of(context).dividerColor;
    final labelColor = lightOnDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tracking.currentStepLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: trackColor),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: tracking.progress.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tone,
                          Color.lerp(tone, Colors.white, 0.28) ?? tone,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tone.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
