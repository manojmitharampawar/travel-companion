import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/providers/app_providers.dart';

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

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Journey History'),
          elevation: 0,
          backgroundColor: AppTheme.primaryColor,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: AppTheme.primaryColor,
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'History', icon: Icon(Icons.history)),
                  Tab(text: 'Favorites', icon: Icon(Icons.favorite)),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _HistoryTab(),
            _FavoritesTab(),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyJourneysProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.history,
                size: 56,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      data: (journeys) {
        if (journeys.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.history,
                    size: 56,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No journey history yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your completed journeys will appear here',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
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
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteJourneysProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (journeys) {
        if (journeys.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 56,
                    color: AppTheme.dangerColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorite journeys yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Star your favorite routes to reschedule them quickly',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: journeys.length,
          itemBuilder: (context, index) {
            return _FavoriteCard(
              enrichedJourney: journeys[index],
              onReschedule: () =>
                  _rescheduleJourney(context, ref, journeys[index]),
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
    );
  }

  void _rescheduleJourney(
    BuildContext context,
    WidgetRef ref,
    EnrichedJourney enriched,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      helpText: 'Select new journey date',
    );

    if (picked == null) return;

    await ref
        .read(journeyRepositoryProvider)
        .rescheduleFromFavorite(enriched.journey, picked);

    ref.invalidate(upcomingJourneysProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Journey rescheduled to ${DateFormat('dd MMM yyyy').format(picked)}',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final EnrichedJourney enrichedJourney;
  final VoidCallback onToggleFavorite;

  const _HistoryCard({
    required this.enrichedJourney,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final journey = enrichedJourney.journey;
    final type = journey.transportType;
    final isCompleted = journey.status == JourneyStatus.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted
              ? AppTheme.successColor.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? AppTheme.successColor.withValues(alpha: 0.3)
                : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: type.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type.icon, size: 16, color: Colors.white),
                        if (journey.vehicleNumber != null &&
                            journey.vehicleNumber!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            journey.vehicleNumber!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      journey.vehicleName ?? type.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      journey.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: journey.isFavorite ? AppTheme.dangerColor : Colors.grey[400],
                      size: 22,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: journey.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${enrichedJourney.boardingName} → ${enrichedJourney.destinationName}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    AppDateUtils.formatDate(journey.journeyDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.successColor.withValues(alpha: 0.15)
                          : AppTheme.dangerColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted
                            ? AppTheme.successColor.withValues(alpha: 0.4)
                            : AppTheme.dangerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      isCompleted ? '✓ Completed' : '✗ Cancelled',
                      style: TextStyle(
                        color: isCompleted ? AppTheme.successColor : AppTheme.dangerColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final journey = enrichedJourney.journey;
    final type = journey.transportType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 18,
                      color: AppTheme.dangerColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: type.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(type.icon, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      journey.vehicleName ?? '${type.label} Journey',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: onRemoveFavorite,
                    tooltip: 'Remove from favorites',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${enrichedJourney.boardingName} → ${enrichedJourney.destinationName}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 2,
              ),
              if (journey.travelClass != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.airline_seat_recline_normal,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Class: ${journey.travelClass}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onReschedule,
                  icon: const Icon(Icons.event_note),
                  label: const Text('Reschedule journey'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    elevation: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
