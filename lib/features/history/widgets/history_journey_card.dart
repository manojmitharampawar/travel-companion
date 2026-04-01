import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/models/enriched_journey.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/history/widgets/history_shared_widgets.dart';

class HistoryJourneyCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final VoidCallback onToggleFavorite;

  const HistoryJourneyCard({
    super.key,
    required this.enrichedJourney,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final journey = enrichedJourney.journey;
    final type = journey.transportType;
    final isCompleted = journey.status == JourneyStatus.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF27AE60).withValues(alpha: 0.06)
                  : g.cardFill(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF27AE60).withValues(alpha: 0.2)
                    : g.border(0.12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: type.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: type.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type.icon, size: 14, color: type.color),
                          if (journey.vehicleNumber != null &&
                              journey.vehicleNumber!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              journey.vehicleNumber!,
                              style: TextStyle(
                                color: type.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        journey.vehicleName ?? type.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: g.textAlpha(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggleFavorite,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          journey.isFavorite
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: journey.isFavorite
                              ? const Color(0xFFFF5252)
                              : g.textAlpha(0.3),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF27AE60,
                            ).withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        enrichedJourney.boardingName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: g.textAlpha(0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        CupertinoIcons.arrow_right,
                        size: 12,
                        color: g.textAlpha(0.25),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        enrichedJourney.destinationName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: g.textAlpha(0.75),
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE74C3C,
                            ).withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 13,
                      color: g.textAlpha(0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppDateUtils.formatDate(journey.journeyDate),
                      style: TextStyle(color: g.textAlpha(0.5), fontSize: 12),
                    ),
                    const Spacer(),
                    GlassStatusChip(isCompleted: isCompleted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
