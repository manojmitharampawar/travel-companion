import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass/glass_constants.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassOrbBackground extends StatelessWidget {
  const GlassOrbBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);

    return ColoredBox(
      color: colors.bg,
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _buildOrb(context: context, color: colors.accent, size: 250),
          ),
          Positioned(
            bottom: 120,
            left: -70,
            child: _buildOrb(
              context: context,
              color: GlassConstants.meshPurple,
              size: 200,
            ),
          ),
          Positioned(
            top: 350,
            right: -40,
            child: _buildOrb(
              context: context,
              color: GlassConstants.meshCyan,
              size: 150,
            ),
          ),
          Positioned(
            bottom: -40,
            right: 60,
            child: _buildOrb(
              context: context,
              color: colors.secondaryAccent,
              size: 120,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb({
    required BuildContext context,
    required Color color,
    required double size,
  }) {
    final colors = GlassColors.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.orbAlpha(color, 0.25),
            colors.orbAlpha(color, 0.06),
            colors.orbAlpha(color, 0),
          ],
        ),
      ),
    );
  }
}
