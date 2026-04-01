import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassMetroSelectedChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onChangePressed;

  const GlassMetroSelectedChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onChangePressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.swapHoriz, size: 16, color: g.textAlpha(0.6)),
                const SizedBox(width: 4),
                Text(
                  'Change',
                  style: TextStyle(fontSize: 12, color: g.textAlpha(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
