import 'package:flutter/cupertino.dart';

class JourneyTrackingBackground extends StatelessWidget {
  final Color accentColor;
  final bool isApproaching;

  const JourneyTrackingBackground({
    super.key,
    required this.accentColor,
    this.isApproaching = false,
  });

  @override
  Widget build(BuildContext context) {
    final alertColor = isApproaching ? const Color(0xFFE74C3C) : accentColor;
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  alertColor.withValues(alpha: 0.15),
                  alertColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.08),
                  accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        if (isApproaching)
          Positioned(
            bottom: 80,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE74C3C).withValues(alpha: 0.12),
                    const Color(0xFFE74C3C).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
