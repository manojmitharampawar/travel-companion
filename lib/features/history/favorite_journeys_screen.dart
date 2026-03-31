import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/services/journey_reschedule_service.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/history/widgets/history_shared_widgets.dart';
import 'package:travel_companion/features/history/widgets/journey_reschedule_dialog.dart';
import 'package:travel_companion/providers/app_providers.dart';

/// Provider for enriched favorite journeys.
/// SOLID-S: Single Responsibility - provides favorite journeys data with station enrichment.
/// Enriches favorite journeys with boarding/destination station details from DB.
final favoriteJourneysProvider =
    FutureProvider<List<EnrichedJourney>>((ref) async {
  final journeyRepo = ref.read(journeyRepositoryProvider);
  final stationRepo = ref.read(stationRepositoryProvider);

  final journeys = await journeyRepo.getFavoriteJourneys();

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

/// Screen displaying favorite journeys with reschedule capability.
///
/// SOLID-S: Single Responsibility - displays favorite journeys and manages reschedule flow.
/// SOLID-O: Open for extension (can add filtering/sorting later).
/// Supports light/dark theme via GlassColors.of(context).
class FavoriteJourneysScreen extends ConsumerWidget {
  const FavoriteJourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteJourneysProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(favoriteJourneysProvider),
      color: const Color(0xFFFF9800),
      backgroundColor: GlassColors.of(context).dropdownBg,
      child: favoritesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9800)),
        ),
        error: (e, _) => GlassPlaceholder(
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFE74C3C),
          title: 'Error loading favorites',
          subtitle: 'Please try again later',
        ),
        data: (journeys) {
          if (journeys.isEmpty) {
            return GlassPlaceholder(
              icon: Icons.favorite_border_rounded,
              iconColor: const Color(0xFFFF5252),
              title: 'No favorite journeys yet',
              subtitle: 'Star your favorite routes to reschedule them quickly',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: journeys.length,
            itemBuilder: (context, index) {
              return _FavoriteCard(
                enrichedJourney: journeys[index],
                onReschedule: () =>
                    _handleReschedule(context, ref, journeys[index]),
                onRemoveFavorite: () async {
                  final j = journeys[index].journey;
                  await ref
                      .read(journeyRepositoryProvider)
                      .toggleFavorite(j.id!, false);
                  ref.invalidate(favoriteJourneysProvider);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Handles reschedule button tap: opens dialog and clones journey on confirmation.
  /// Flow: Dialog -> User selects date/time -> Clone journey -> Insert DB -> Invalidate providers -> Toast
  Future<void> _handleReschedule(
    BuildContext context,
    WidgetRef ref,
    EnrichedJourney enriched,
  ) async {
    final result = await showCupertinoDialog<(DateTime, TimeOfDay)>(
      context: context,
      builder: (context) => JourneyRescheduleDialog(
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 120)),
        initialTime: _parseScheduledTime(enriched.journey.scheduledTime),
      ),
    );

    if (result == null) return;

    final (selectedDate, selectedTime) = result;

    try {
      // Clone and reschedule using service
      final rescheduleService = JourneyRescheduleService(
        journeyRepository: ref.read(journeyRepositoryProvider),
      );

      await rescheduleService.rescheduleJourney(
        journey: enriched.journey,
        selectedDate: selectedDate,
        selectedTime: selectedTime,
      );

      // Invalidate providers to reflect new journey on home screen
      ref.invalidate(upcomingJourneysProvider);
      ref.invalidate(favoriteJourneysProvider);

      if (context.mounted) {
        AdaptiveFeedback.showToast(
          context,
          'Journey rescheduled to ${DateFormat('dd MMM yyyy').format(selectedDate)} at ${selectedTime.format(context)}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AdaptiveFeedback.showToast(
          context,
          'Error: Could not reschedule journey',
          isError: true,
        );
      }
    }
  }

  /// Parses scheduled time string (HH:mm) to TimeOfDay.
  /// Returns 6:00 AM as default if parsing fails.
  TimeOfDay? _parseScheduledTime(String? scheduledTime) {
    if (scheduledTime == null || scheduledTime.isEmpty) {
      return null;
    }

    try {
      final parts = scheduledTime.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }
}

/// Card widget displaying a favorite journey with reschedule button.
/// SOLID-S: Single Responsibility - renders favorite card with reschedule CTA.
class _FavoriteCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final VoidCallback onReschedule;
  final VoidCallback onRemoveFavorite;

  const _FavoriteCard({
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
              border: Border.all(
                color: g.border(0.12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              const Color(0xFFFF5252).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          size: 16, color: Color(0xFFFF5252)),
                    ),
                    const SizedBox(width: 8),
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
                        child: Icon(Icons.close_rounded,
                            size: 18, color: g.textAlpha(0.3)),
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

                if (journey.travelClass != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.airline_seat_recline_normal_rounded,
                          size: 13, color: g.textAlpha(0.4)),
                      const SizedBox(width: 6),
                      Text(
                        'Class: ${journey.travelClass}',
                        style: TextStyle(
                          color: g.textAlpha(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Reschedule button
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
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BCD4)
                                  .withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note_rounded,
                                size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Reschedule Journey',
                              style: TextStyle(
                                color: Colors.white,
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
