import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/services/alarm_service.dart';

class JourneyTrackingStateBanner extends StatelessWidget {
  final TrackingState state;

  const JourneyTrackingStateBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (state) {
      TrackingState.idle => (
        const Color(0xFF6E6E73),
        CupertinoIcons.location_slash,
        'Initializing...',
      ),
      TrackingState.tracking => (
        const Color(0xFF27AE60),
        CupertinoIcons.location_fill,
        'Tracking your journey',
      ),
      TrackingState.approaching => (
        const Color(0xFFE74C3C),
        CupertinoIcons.exclamationmark_triangle_fill,
        'APPROACHING DESTINATION!',
      ),
      TrackingState.arrived => (
        const Color(0xFF3498DB),
        CupertinoIcons.check_mark_circled_solid,
        'You have arrived!',
      ),
    };

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border(
              bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, color: color, size: 17, key: ValueKey(state)),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
