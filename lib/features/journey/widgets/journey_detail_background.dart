import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class JourneyDetailBackground extends StatelessWidget {
  final Color accentColor;

  const JourneyDetailBackground({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  g.orbAlpha(accentColor, 0.15),
                  accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  g.orbAlpha(accentColor, 0.08),
                  accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
