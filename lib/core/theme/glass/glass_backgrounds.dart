import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

import 'glass_constants.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GlassBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final bgColors = colors ?? g.bgGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgColors,
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class GlassMeshBackground extends StatelessWidget {
  final Widget child;
  final Color? primaryColor;

  const GlassMeshBackground({
    super.key,
    required this.child,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final accent = primaryColor ?? g.accent;
    final baseBg = g.bg;

    return Container(
      color: baseBg,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowOrb(color: accent, size: 220),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _GlowOrb(color: GlassConstants.meshPurple, size: 180),
          ),
          Positioned(
            top: 300,
            right: -30,
            child: _GlowOrb(color: GlassConstants.meshCyan, size: 140),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
