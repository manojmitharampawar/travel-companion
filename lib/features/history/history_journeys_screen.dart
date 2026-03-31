import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/history/widgets/history_shared_widgets.dart';
import 'package:travel_companion/features/history/favorite_journeys_screen.dart';
import 'package:travel_companion/providers/app_providers.dart';

/// Provider for enriched journey history (completed/cancelled journeys).
/// SOLID-S: Single Responsibility - provides journey history data with station enrichment.
/// Enriches raw journeys with boarding/destination station details from DB.
final historyJourneysProvider =
    FutureProvider<List<EnrichedJourney>>((ref) async {
  final journeyRepo = ref.read(journeyRepositoryProvider);
  final stationRepo = ref.read(stationRepositoryProvider);

  final journeys = await journeyRepo.getJourneyHistory();

  final enriched = <EnrichedJourney>[];
  for (final journey in journeys) {
    final boarding = journey.boardingStationCode != null
        ? await stationRepo.getStationByCode(journey.boardingStationCode!)
        : null;
    final destination = journey.destinationStationCode != null
        ? await stationRepo.getStationByCode(journey.destinationStationCode!)
        : null;
    enriched.add(EnrichedJourney(
      journey: journey,
      boardingStation: boarding,
      destinationStation: destination,
    ));
  }
  return enriched;
});

/// Screen displaying completed/cancelled journey history.
///
/// SOLID-S: Single Responsibility - displays history journeys in a list.
/// SOLID-O: Open for extension (can add filtering/sorting later).
/// Supports light/dark theme via GlassColors.of(context).
class HistoryJourneysScreen extends ConsumerWidget {
  const HistoryJourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyJourneysProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(historyJourneysProvider),
      color: const Color(0xFFFF9800),
      backgroundColor: GlassColors.of(context).dropdownBg,
      child: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9800)),
        ),
        error: (e, _) => GlassPlaceholder(
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFE74C3C),
          title: 'Error loading history',
          subtitle: 'Please try again later',
        ),
        data: (journeys) {
          if (journeys.isEmpty) {
            return GlassPlaceholder(
              icon: Icons.history_rounded,
              iconColor: Colors.white.withValues(alpha: 0.3),
              title: 'No journey history yet',
              subtitle: 'Your completed journeys will appear here',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: journeys.length,
            itemBuilder: (context, index) => _HistoryCard(
              enrichedJourney: journeys[index],
              onToggleFavorite: () async {
                final j = journeys[index].journey;
                await ref
                    .read(journeyRepositoryProvider)
                    .toggleFavorite(j.id!, !j.isFavorite);
                ref.invalidate(historyJourneysProvider);
                ref.invalidate(favoriteJourneysProvider);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Card widget displaying a single history journey item.
/// SOLID-S: Single Responsibility - renders a history card with toggle favorite.
class _HistoryCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final VoidCallback onToggleFavorite;

  const _HistoryCard({
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
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
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

                // Route
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
                            color: const Color(0xFF27AE60)
                                .withValues(alpha: 0.4),
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
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 12, color: g.textAlpha(0.25)),
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
                            color: const Color(0xFFE74C3C)
                                .withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: g.textAlpha(0.4)),
                    const SizedBox(width: 6),
                    Text(
                      AppDateUtils.formatDate(journey.journeyDate),
                      style: TextStyle(
                        color: g.textAlpha(0.5),
                        fontSize: 12,
                      ),
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

// Export for reuse in providers module (if needed elsewhere)
// Note: favoriteJourneysProvider will be moved to favorite_journeys_screen.dart
