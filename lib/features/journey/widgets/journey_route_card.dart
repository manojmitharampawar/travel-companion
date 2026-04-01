import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/home/home_provider.dart';

import 'journey_station_label.dart';

class JourneyRouteCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final Journey journey;
  final TransportType type;

  const JourneyRouteCard({
    super.key,
    required this.enrichedJourney,
    required this.journey,
    required this.type,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF27AE60),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 44,
                    color: type.color.withValues(alpha: 0.25),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE74C3C),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE74C3C).withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JourneyStationLabel(
                      tag: 'FROM',
                      name: enrichedJourney.boardingName,
                      code: journey.boardingStationCode ?? '',
                      color: const Color(0xFF27AE60),
                    ),
                    const SizedBox(height: 18),
                    JourneyStationLabel(
                      tag: 'TO',
                      name: enrichedJourney.destinationName,
                      code: journey.destinationStationCode ?? '',
                      color: const Color(0xFFE74C3C),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
