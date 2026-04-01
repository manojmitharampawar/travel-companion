import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass/cupertino_glass_stepper.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool isLoading;
  final bool filled;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    required this.accentColor,
    this.isLoading = false,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: filled
                    ? LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
                color: filled
                    ? null
                    : (isDark
                          ? CupertinoColors.white.withValues(alpha: 0.1)
                          : CupertinoColors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: filled
                      ? CupertinoColors.white.withValues(alpha: 0.25)
                      : accentColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, size: 22, color: CupertinoColors.white),
                  if (icon != null || isLoading) const SizedBox(width: 10),
                  Text(
                    isLoading ? 'Saving...' : label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: filled ? CupertinoColors.white : accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassAppBarHero extends StatelessWidget {
  final Color primaryColor;
  final Color? secondaryColor;
  final IconData icon;
  final String title;
  final String subtitle;

  const GlassAppBarHero({
    super.key,
    required this.primaryColor,
    this.secondaryColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryColor ?? primaryColor.withValues(alpha: 0.7);
    final topPad = MediaQuery.paddingOf(context).top + 44 + 4;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondary],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CupertinoColors.white.withValues(alpha: 0.12),
                    CupertinoColors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CupertinoColors.white.withValues(alpha: 0.08),
                    CupertinoColors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, topPad, 24, 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(icon, size: 32, color: CupertinoColors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox.shrink(),
                      Text(
                        title,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlassStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  final Color accent;

  const GlassStepIndicator({
    super.key,
    required this.currentStep,
    required this.labels,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: CupertinoGlassStepper(
        currentStep: currentStep,
        accentColor: accent,
        steps: labels.map((label) => CupertinoGlassStep(title: label)).toList(),
      ),
    );
  }
}
