import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/application/journey_enrichment/journey_enricher.dart';
import 'package:travel_companion/core/data/lookups/station_repository_lookup.dart';
import 'package:travel_companion/core/models/enriched_journey.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/providers/app_providers.dart';

final historyJourneysProvider = FutureProvider<List<EnrichedJourney>>((ref) {
  final journeyRepository = ref.read(journeyRepositoryProvider);
  final stationRepository = ref.read(stationRepositoryProvider);
  final enricher = JourneyEnricher(
    stationLookup: StationRepositoryLookup(stationRepository),
  );

  return _loadEnrichedJourneys(
    loadJourneys: journeyRepository.getJourneyHistory,
    enricher: enricher,
  );
});

final favoriteJourneysProvider = FutureProvider<List<EnrichedJourney>>((ref) {
  final journeyRepository = ref.read(journeyRepositoryProvider);
  final stationRepository = ref.read(stationRepositoryProvider);
  final enricher = JourneyEnricher(
    stationLookup: StationRepositoryLookup(stationRepository),
  );

  return _loadEnrichedJourneys(
    loadJourneys: journeyRepository.getFavoriteJourneys,
    enricher: enricher,
  );
});

Future<List<EnrichedJourney>> _loadEnrichedJourneys({
  required Future<List<Journey>> Function() loadJourneys,
  required JourneyEnricher enricher,
}) async {
  final journeys = await loadJourneys();
  return Future.wait(journeys.map(enricher.enrich));
}
