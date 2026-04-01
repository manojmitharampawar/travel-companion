import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/services/alarm_service.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class JourneyTrackingActionBar extends StatelessWidget {
  final TrackingState state;
  final TransportType type;
  final VoidCallback onDismiss;
  final VoidCallback onStop;

  const JourneyTrackingActionBar({
    super.key,
    required this.state,
    required this.type,
    required this.onDismiss,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state == TrackingState.approaching) ...[
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    pressedOpacity: 0.8,
                    onPressed: onDismiss,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE74C3C,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.bell_slash_fill,
                            color: CupertinoColors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "I'm Awake! Dismiss Alarm",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  pressedOpacity: 0.8,
                  onPressed: onStop,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          type.color.withValues(alpha: 0.15),
                          type.color.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: type.color.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.stop_circle, color: type.color),
                        const SizedBox(width: 8),
                        Text(
                          'Stop Tracking',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: type.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
