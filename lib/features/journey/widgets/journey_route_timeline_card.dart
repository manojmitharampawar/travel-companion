import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class JourneyRouteTimeline extends StatelessWidget {
  final List<TrainRoute> routeStops;
  final TransportType type;

  const JourneyRouteTimeline({
    super.key,
    required this.routeStops,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: g.cardFill(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g.border(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.map_pin_ellipse,
                      size: 14,
                      color: type.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Route - ${routeStops.length} stops',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: type.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: routeStops.length,
                itemBuilder: (_, i) {
                  final stop = routeStops[i];
                  final isFirst = i == 0;
                  final isLast = i == routeStops.length - 1;
                  final isTerminal = isFirst || isLast;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 20,
                          child: Column(
                            children: [
                              Container(
                                width: isTerminal ? 12 : 8,
                                height: isTerminal ? 12 : 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFirst
                                      ? const Color(0xFF27AE60)
                                      : isLast
                                      ? const Color(0xFFE74C3C)
                                      : CupertinoColors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: type.color.withValues(alpha: 0.18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    stop.stationCode,
                                    style: TextStyle(
                                      fontSize: isTerminal ? 14 : 13,
                                      fontWeight: isTerminal
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isTerminal
                                          ? CupertinoColors.white.withValues(
                                              alpha: 0.9,
                                            )
                                          : CupertinoColors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                    ),
                                  ),
                                ),
                                if (stop.departureTime != null ||
                                    stop.arrivalTime != null)
                                  Text(
                                    stop.departureTime ?? stop.arrivalTime!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
