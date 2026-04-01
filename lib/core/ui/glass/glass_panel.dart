import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 18,
    this.blurSigma = 16,
    this.fillOpacity = 0.08,
    this.borderOpacity = 0.16,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final double fillOpacity;
  final double borderOpacity;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.cardFill(fillOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? colors.border(borderOpacity),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
