import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/app_icons.dart';

class TrainRouteConnector extends StatelessWidget {
  final Color accent;

  const TrainRouteConnector({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(AppIcons.circle, size: 10, color: accent),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.15)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          AppIcons.flagRounded,
          size: 12,
          color: accent.withValues(alpha: 0.9),
        ),
      ],
    );
  }
}
