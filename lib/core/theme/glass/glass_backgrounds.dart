import 'package:flutter/material.dart';
import 'glass_constants.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GlassBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final bgColors =
        colors ??
        (isDark
            ? [
                const Color(0xFF0A0E21),
                const Color(0xFF0D1B3E),
                const Color(0xFF1A0A2E),
                const Color(0xFF0A1628),
              ]
            : [
                const Color(0xFFE8EAF6),
                const Color(0xFFE0F7FA),
                const Color(0xFFF3E5F5),
                const Color(0xFFE8EAF6),
              ]);

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
    final accent = primaryColor ?? GlassConstants.meshBlue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? const Color(0xFF0A0E21) : const Color(0xFFF0F2F8);

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
