import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class JourneyNextStopCard extends StatelessWidget {
  final TrainRouteStop stop;
  final TransportType type;

  const JourneyNextStopCard({
    super.key,
    required this.stop,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final orangeAccent = g.statusWarning;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: orangeAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: orangeAccent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.tram_fill,
                  size: 20,
                  color: orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Stop',
                      style: TextStyle(
                        fontSize: 11,
                        color: GlassColors.of(context).textAlpha(0.5),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      stop.stationName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GlassColors.of(context).textAlpha(0.9),
                      ),
                    ),
                    Text(
                      stop.stationCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: GlassColors.of(context).textAlpha(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (stop.timeDisplay.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Arr.',
                      style: TextStyle(
                        fontSize: 10,
                        color: GlassColors.of(context).textAlpha(0.4),
                      ),
                    ),
                    const Text('', style: TextStyle(fontSize: 0)),
                    Text(
                      stop.timeDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: orangeAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
