import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';

class GlassSwapButton extends StatelessWidget {
  const GlassSwapButton({
    super.key,
    required this.visible,
    required this.accent,
    required this.onTap,
  });

  final bool visible;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.swapVert, size: 18, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Swap stops',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
