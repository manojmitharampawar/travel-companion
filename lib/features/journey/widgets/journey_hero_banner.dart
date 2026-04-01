import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/journey/widgets/glass_status_pill.dart';

class JourneyHeroBanner extends StatelessWidget {
  final Journey journey;
  final TransportType type;

  const JourneyHeroBanner({
    super.key,
    required this.journey,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final accentColor = type.color;

    final vehicleName =
        journey.vehicleName ??
        (journey.vehicleNumber != null
            ? '${type.label} ${journey.vehicleNumber}'
            : type.label);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor.withValues(alpha: 0.15), g.bg],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: g.border(0.06), width: 1),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 44 + 6, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: g.cardFill(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: g.border(0.15)),
                      ),
                      child: Icon(type.icon, size: 30, color: accentColor),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleName,
                        style: TextStyle(
                          color: g.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (journey.vehicleNumber != null &&
                          journey.vehicleNumber!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          journey.vehicleNumber!,
                          style: TextStyle(
                            color: g.textAlpha(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: 11,
                            color: g.textAlpha(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.relativeDay(journey.journeyDate),
                            style: TextStyle(
                              color: g.textAlpha(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (journey.scheduledTime != null) ...[
                            const SizedBox(width: 10),
                            Icon(
                              CupertinoIcons.time,
                              size: 11,
                              color: g.textAlpha(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              journey.scheduledTime!,
                              style: TextStyle(
                                color: g.textAlpha(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GlassStatusPill(status: journey.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
