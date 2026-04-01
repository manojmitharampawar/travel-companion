import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';

class GlassTrainRouteLoadedBanner extends StatelessWidget {
  final int stopCount;
  final String trainName;
  final Color accentColor;

  const GlassTrainRouteLoadedBanner({
    super.key,
    required this.stopCount,
    required this.trainName,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.checkCircleRounded, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$stopCount stops loaded${trainName.isNotEmpty ? ' · $trainName' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
