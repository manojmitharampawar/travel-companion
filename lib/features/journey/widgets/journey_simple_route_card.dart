import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class JourneySimpleRouteCard extends StatelessWidget {
  final LocationPoint origin;
  final LocationPoint destination;
  final TransportType type;

  const JourneySimpleRouteCard({
    super.key,
    required this.origin,
    required this.destination,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF27AE60),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 30,
                    color: CupertinoColors.white.withValues(alpha: 0.15),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE74C3C),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE74C3C).withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      origin.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: g.textAlpha(0.9),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      destination.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: g.textAlpha(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(type.icon, size: 20, color: type.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
