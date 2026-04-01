import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class FullscreenMapCloseButton extends StatelessWidget {
  const FullscreenMapCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);
    final surface = colors.isDark
        ? const Color(0xFF0A0E21).withValues(alpha: 0.8)
        : colors.cardFillSolid(0.9);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border(0.15)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.fullscreen_exit,
              size: 20,
              color: colors.textAlpha(0.85),
            ),
          ),
        ),
      ),
    );
  }
}
