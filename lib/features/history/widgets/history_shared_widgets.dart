import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/theme/glass_widgets.dart';

/// Placeholder widget for empty states and error messages.
/// SOLID-S: Single Responsibility - displays empty/error state with icon, title, subtitle
class GlassPlaceholder extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const GlassPlaceholder({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(icon, size: 48, color: iconColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: g.text,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: g.textAlpha(0.45),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Status chip displaying journey completion status (Completed/Cancelled).
/// SOLID-S: Single Responsibility - renders status badge with color coding
class GlassStatusChip extends StatelessWidget {
  final bool isCompleted;

  const GlassStatusChip({
    required this.isCompleted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCompleted ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);
    final text = isCompleted ? 'Completed' : 'Cancelled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Background orbs for glass-morphism effect.
/// SOLID-S: Single Responsibility - renders decorative gradient circles
class HistoryBackgroundOrbs extends StatelessWidget {
  static const _kAccent = Color(0xFF0D47A1);

  const HistoryBackgroundOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GlassColors.of(context).bg,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -60,
            child: _GlowOrb(color: _kAccent, size: 200),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: _GlowOrb(color: GlassConstants.meshPurple, size: 180),
          ),
          Positioned(
            top: 300,
            left: -30,
            child: _GlowOrb(color: GlassConstants.meshCyan, size: 130),
          ),
        ],
      ),
    );
  }
}

/// Decorative glowing orb for glass effect.
/// SOLID-S: Single Responsibility - renders a single radial gradient circle
class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.06),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
