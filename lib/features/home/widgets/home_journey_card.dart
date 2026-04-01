import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/core/ui/adaptive_navigation.dart';
import 'package:travel_companion/core/ui/glass/glass_panel.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/core/models/enriched_journey.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/home/widgets/home_journey_metadata_chip.dart';
import 'package:travel_companion/features/home/widgets/home_journey_status_badge.dart';
import 'package:travel_companion/features/home/widgets/home_journey_type_badge.dart';
import 'package:travel_companion/features/journey/journey_detail_navigation.dart';

class HomeJourneyCard extends ConsumerWidget {
  const HomeJourneyCard({super.key, required this.enrichedJourney});

  final EnrichedJourney enrichedJourney;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = GlassColors.of(context);
    final journey = enrichedJourney.journey;
    final isActive = journey.status == JourneyStatus.active;
    final isToday = journey.isToday;
    final transportType = journey.transportType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          adaptivePageRoute(getJourneyDetailScreen(enrichedJourney)),
        ),
        child: GlassPanel(
          borderRadius: 18,
          fillOpacity: isActive ? 0.1 : 0.08,
          borderOpacity: isActive ? 0.32 : 0.15,
          borderColor: isActive
              ? const Color(0xFF27AE60).withValues(alpha: 0.35)
              : null,
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        transportType.color,
                        transportType.color.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HomeJourneyTypeBadge(
                              transportType: transportType,
                              vehicleNumber: journey.vehicleNumber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _buildVehicleLabel(journey),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: colors.textAlpha(0.92),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            HomeJourneyStatusBadge(status: journey.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildStopDot(
                              color: const Color(0xFF27AE60),
                              glowColor: const Color(
                                0xFF27AE60,
                              ).withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                enrichedJourney.boardingName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textAlpha(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Icon(
                                CupertinoIcons.arrow_right,
                                size: 13,
                                color: colors.iconAlpha(0.3),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                enrichedJourney.destinationName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textAlpha(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildStopDot(
                              color: const Color(0xFFE74C3C),
                              glowColor: const Color(
                                0xFFE74C3C,
                              ).withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              HomeJourneyMetadataChip(
                                icon: CupertinoIcons.calendar,
                                label: AppDateUtils.relativeDay(
                                  journey.journeyDate,
                                ),
                                isHighlighted: isToday,
                              ),
                              if (journey.scheduledTime != null) ...[
                                const SizedBox(width: 6),
                                HomeJourneyMetadataChip(
                                  icon: CupertinoIcons.clock,
                                  label: journey.scheduledTime!,
                                ),
                              ],
                              if (journey.travelClass != null) ...[
                                const SizedBox(width: 6),
                                HomeJourneyMetadataChip(
                                  icon: CupertinoIcons.person_2,
                                  label: journey.travelClass!,
                                ),
                              ],
                              if (journey.pnr != null) ...[
                                const SizedBox(width: 6),
                                HomeJourneyMetadataChip(
                                  icon: CupertinoIcons.ticket,
                                  label: 'PNR: ${journey.pnr}',
                                ),
                              ],
                              if (journey.isRepeating) ...[
                                const SizedBox(width: 6),
                                HomeJourneyMetadataChip(
                                  icon: CupertinoIcons.refresh,
                                  label: journey.repeatDaysDisplay,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: colors.iconAlpha(0.25),
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

  String _buildVehicleLabel(Journey journey) {
    return journey.vehicleName ??
        (journey.vehicleNumber != null
            ? '${journey.transportType.label} ${journey.vehicleNumber}'
            : journey.transportType.label);
  }

  Widget _buildStopDot({required Color color, required Color glowColor}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: glowColor, blurRadius: 4)],
      ),
    );
  }
}
