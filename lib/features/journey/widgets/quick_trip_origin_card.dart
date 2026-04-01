import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/location_point.dart';

class QuickTripOriginCard extends StatelessWidget {
  final LocationPoint? origin;
  final bool isGettingLocation;

  const QuickTripOriginCard({
    super.key,
    required this.origin,
    required this.isGettingLocation,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.location_solid,
                  color: Color(0xFF27AE60),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: TextStyle(
                        fontSize: 11,
                        color: g.textAlpha(0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isGettingLocation)
                      Text(
                        'Detecting location...',
                        style: TextStyle(fontSize: 14, color: g.textAlpha(0.6)),
                      )
                    else
                      Text(
                        origin?.displayName ?? 'Unknown location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: g.textAlpha(0.9),
                        ),
                      ),
                  ],
                ),
              ),
              if (isGettingLocation)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CupertinoActivityIndicator(color: g.textAlpha(0.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
