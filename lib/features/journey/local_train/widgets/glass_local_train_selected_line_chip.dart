import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/local_train_line.dart';

class GlassLocalTrainSelectedLineChip extends StatelessWidget {
  final LocalTrainLine line;
  final VoidCallback onChangePressed;

  const GlassLocalTrainSelectedLineChip({
    super.key,
    required this.line,
    required this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: line.lineColor,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: line.lineColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            line.lineName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: line.lineColor,
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
                Icon(AppIcons.swapHoriz, size: 16, color: g.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Change',
                  style: TextStyle(fontSize: 12, color: g.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
