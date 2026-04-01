import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/ui/glass/glass_panel.dart';

class GlassMessageState extends StatelessWidget {
  const GlassMessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionTap,
    this.tintColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final colors = GlassColors.of(context);
    final effectiveTint = tintColor ?? colors.accent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: effectiveTint),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onActionTap != null) ...[
                const SizedBox(height: 20),
                CupertinoButton(
                  onPressed: onActionTap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: effectiveTint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      color: effectiveTint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
