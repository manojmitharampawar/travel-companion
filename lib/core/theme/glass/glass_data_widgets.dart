import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassTrainCard extends StatelessWidget {
  final String formattedDeparture;
  final String formattedArrival;
  final String travelDuration;
  final int stopsCount;
  final String? trainTypeLabel;
  final bool isFast;
  final Color lineColor;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  const GlassTrainCard({
    super.key,
    required this.formattedDeparture,
    required this.formattedArrival,
    required this.travelDuration,
    required this.stopsCount,
    this.trainTypeLabel,
    this.isFast = false,
    required this.lineColor,
    required this.isSelected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? accent.withValues(alpha: 0.18) : g.cardFill(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? accent.withValues(alpha: 0.6) : g.border(),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.2),
                          blurRadius: 12,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  _TimeColumn(
                    time: formattedDeparture,
                    label: 'DEP',
                    isSelected: isSelected,
                    accent: accent,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      lineColor.withValues(alpha: 0.6),
                                      lineColor,
                                      lineColor.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: g.cardFill(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                travelDuration,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: g.textAlpha(0.8),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      lineColor.withValues(alpha: 0.6),
                                      lineColor,
                                      lineColor.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 10, color: g.textTertiary),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (trainTypeLabel != null)
                              _GlassTypeBadge(
                                label: trainTypeLabel!,
                                isFast: isFast,
                                color: lineColor,
                              ),
                            if (trainTypeLabel != null) const SizedBox(width: 8),
                            Text(
                              '$stopsCount stops',
                              style: TextStyle(
                                fontSize: 10,
                                color: g.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _TimeColumn(
                    time: formattedArrival,
                    label: 'ARR',
                    isSelected: isSelected,
                    accent: accent,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: accent, size: 22),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String time;
  final String label;
  final bool isSelected;
  final Color accent;

  const _TimeColumn({
    required this.time,
    required this.label,
    required this.isSelected,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isSelected ? accent : g.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: g.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _GlassTypeBadge extends StatelessWidget {
  final String label;
  final bool isFast;
  final Color color;

  const _GlassTypeBadge({
    required this.label,
    required this.isFast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFast) ...[
            Icon(Icons.bolt, size: 10, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
