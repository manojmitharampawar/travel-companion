import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class QuickTripStartButton extends StatelessWidget {
  final Color accentColor;
  final bool isStarting;
  final bool isDisabled;
  final VoidCallback onTap;

  const QuickTripStartButton({
    super.key,
    required this.accentColor,
    required this.isStarting,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? null
            : LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.8)],
              ),
        color: isDisabled ? g.cardFill(0.06) : null,
        borderRadius: BorderRadius.circular(16),
        border: isDisabled ? Border.all(color: g.border(0.1)) : null,
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: GestureDetector(
        onTap: isStarting || isDisabled ? null : onTap,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isStarting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                  ),
                )
              else
                Icon(
                  CupertinoIcons.play_arrow_solid,
                  size: 22,
                  color: isDisabled ? g.textAlpha(0.3) : CupertinoColors.white,
                ),
              const SizedBox(width: 8),
              Text(
                isStarting ? 'Starting...' : 'Start Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDisabled ? g.textAlpha(0.3) : CupertinoColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
