import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/application/journey_enrichment/journey_enricher.dart';
import 'package:travel_companion/core/data/lookups/station_repository_lookup.dart';
import 'package:travel_companion/core/models/enriched_journey.dart';
import 'package:travel_companion/providers/app_providers.dart';

export 'package:travel_companion/core/models/enriched_journey.dart';

final upcomingJourneysProvider = FutureProvider<List<EnrichedJourney>>((
  ref,
) async {
  final journeyRepository = ref.read(journeyRepositoryProvider);
  final stationRepository = ref.read(stationRepositoryProvider);
  final journeys = await journeyRepository.getUpcomingJourneys();

  final enricher = JourneyEnricher(
    stationLookup: StationRepositoryLookup(stationRepository),
  );

  return Future.wait(journeys.map(enricher.enrich));
});

final allJourneysProvider = FutureProvider<List<EnrichedJourney>>((ref) async {
  final journeyRepository = ref.read(journeyRepositoryProvider);
  final stationRepository = ref.read(stationRepositoryProvider);
  final journeys = await journeyRepository.getAllJourneys();

  final enricher = JourneyEnricher(
    stationLookup: StationRepositoryLookup(stationRepository),
  );

  return Future.wait(journeys.map(enricher.enrich));
});
