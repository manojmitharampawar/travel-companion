import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';

class TrainStationDot extends StatelessWidget {
  final bool isEndpoint;
  final bool isOrigin;
  final Color accentColor;

  const TrainStationDot({
    super.key,
    required this.isEndpoint,
    required this.isOrigin,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isEndpoint) {
      final color = isOrigin
          ? const Color(0xFF27AE60)
          : const Color(0xFFE74C3C);
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: CupertinoColors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
          ],
        ),
        child: Icon(
          isOrigin ? AppIcons.tripOrigin : AppIcons.locationOn,
          size: 10,
          color: CupertinoColors.white,
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: accentColor,
        shape: BoxShape.circle,
        border: Border.all(color: CupertinoColors.white, width: 1.5),
      ),
    );
  }
}
