import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class JourneyStopTimelineItem extends StatelessWidget {
  final String name;
  final String code;
  final String? time;
  final int? distanceKm;
  final bool isFirst;
  final bool isLast;
  final Color accentColor;

  const JourneyStopTimelineItem({
    super.key,
    required this.name,
    required this.code,
    this.time,
    this.distanceKm,
    required this.isFirst,
    required this.isLast,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isFirst
        ? const Color(0xFF27AE60)
        : isLast
        ? const Color(0xFFE74C3C)
        : accentColor.withValues(alpha: 0.7);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                Container(
                  width: isFirst || isLast ? 12 : 8,
                  height: isFirst || isLast ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: (isFirst || isLast)
                        ? [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                    border: (isFirst || isLast)
                        ? null
                        : Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: isFirst || isLast ? 13 : 12,
                            fontWeight: isFirst || isLast
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: GlassColors.of(
                              context,
                            ).textAlpha(isFirst || isLast ? 0.9 : 0.7),
                          ),
                        ),
                        if (code.isNotEmpty)
                          Text(
                            code,
                            style: TextStyle(
                              fontSize: 10,
                              color: GlassColors.of(context).textAlpha(0.4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (time != null && time!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        time!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: GlassColors.of(context).textAlpha(0.5),
                        ),
                      ),
                    ),
                  if (distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GlassColors.of(context).cardFill(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$distanceKm km',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: GlassColors.of(context).textAlpha(0.4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
