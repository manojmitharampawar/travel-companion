import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';

import 'journey_strip_node.dart';

class JourneyHorizontalRouteStrip extends StatelessWidget {
  final List<TrainRouteStop> stops;
  final int nextStopIndex;
  final TransportType type;
  final ScrollController scrollController;

  const JourneyHorizontalRouteStrip({
    super.key,
    required this.stops,
    required this.nextStopIndex,
    required this.type,
    required this.scrollController,
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
                    'Route - ${stops.length} stops',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: type.color,
                    ),
                  ),
                  const Spacer(),
                  if (nextStopIndex > 0)
                    Text(
                      '$nextStopIndex passed',
                      style: TextStyle(fontSize: 11, color: g.textAlpha(0.4)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(stops.length, (i) {
                    final stop = stops[i];
                    final isPassed = i < nextStopIndex;
                    final isNext = i == nextStopIndex;
                    final isFirst = i == 0;
                    final isLast = i == stops.length - 1;

                    return JourneyStripNode(
                      stop: stop,
                      isPassed: isPassed,
                      isNext: isNext,
                      isFirst: isFirst,
                      isLast: isLast,
                      accentColor: type.color,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
