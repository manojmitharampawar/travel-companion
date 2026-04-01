import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/journey.dart';

class GlassStatusPill extends StatelessWidget {
  final JourneyStatus status;

  const GlassStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final (label, color) = switch (status) {
      JourneyStatus.upcoming => ('Upcoming', g.statusInfo),
      JourneyStatus.active => ('Active', g.statusSuccess),
      JourneyStatus.completed => ('Completed', g.statusNeutral),
      JourneyStatus.cancelled => ('Cancelled', g.statusDanger),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
