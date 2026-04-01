import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/models/enriched_journey.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class FavoriteJourneyCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final VoidCallback onReschedule;
  final VoidCallback onRemoveFavorite;

  const FavoriteJourneyCard({
    super.key,
    required this.enrichedJourney,
    required this.onReschedule,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final journey = enrichedJourney.journey;
    final type = journey.transportType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: g.cardFill(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: g.border(0.12)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.heart_fill,
                        size: 16,
                        color: Color(0xFFFF5252),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                      child: Icon(type.icon, size: 14, color: type.color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        journey.vehicleName ?? '${type.label} Journey',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: g.textAlpha(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onRemoveFavorite,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 18,
                          color: g.textAlpha(0.3),
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
                if (journey.travelClass != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.person_2_fill,
                        size: 13,
                        color: g.textAlpha(0.4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Class: ${journey.travelClass}',
                        style: TextStyle(color: g.textAlpha(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onReschedule,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00BCD4).withValues(alpha: 0.7),
                              const Color(0xFF00BCD4).withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.white.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00BCD4,
                              ).withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.calendar_badge_plus,
                              size: 18,
                              color: CupertinoColors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Reschedule Journey',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
