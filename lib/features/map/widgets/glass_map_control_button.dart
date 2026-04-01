import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassMapControlButton extends StatelessWidget {
  const GlassMapControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);

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
              color: isActive
                  ? const Color(0xFF3498DB).withValues(alpha: 0.2)
                  : colors.isDark
                  ? const Color(0xFF0A0E21).withValues(alpha: 0.7)
                  : CupertinoColors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF3498DB).withValues(alpha: 0.4)
                    : colors.border(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF3498DB) : colors.textAlpha(0.8),
            ),
          ),
        ),
      ),
    );
  }
}
