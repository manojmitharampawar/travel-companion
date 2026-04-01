import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/journey/journey_tracking_screen.dart';

class GlassBottomCta extends ConsumerWidget {
  final Journey journey;
  final EnrichedJourney enrichedJourney;
  final TransportType type;

  const GlassBottomCta({
    super.key,
    required this.journey,
    required this.enrichedJourney,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = GlassColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: g.bg.withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: g.border(0.1), width: 1)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [type.color, type.color.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: type.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => _startTracking(context),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        journey.isActive
                            ? CupertinoIcons.location_fill
                            : CupertinoIcons.play_arrow_solid,
                        color: CupertinoColors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        journey.isActive
                            ? 'View Live Tracking'
                            : 'Start Journey Tracking',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startTracking(BuildContext context) {
    final destPoint = enrichedJourney.destinationPoint;
    if (destPoint == null) {
      AdaptiveFeedback.showToast(
        context,
        'Destination location data not available',
        isError: true,
      );
      return;
    }
    Navigator.push(
      context,
      adaptivePageRoute(JourneyTrackingScreen(journey: journey)),
    );
  }
}
