import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class JourneyMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subLabel;

  const JourneyMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: g.cardFill(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g.border(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: g.textAlpha(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      subLabel!,
                      style: TextStyle(fontSize: 10, color: g.textAlpha(0.3)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
