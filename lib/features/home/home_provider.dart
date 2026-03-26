import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/repositories/station_repository.dart';
import 'package:travel_companion/providers/app_providers.dart';

class EnrichedJourney {
  final Journey journey;
  final Station? boardingStation;
  final Station? destinationStation;
  final LocationPoint? origin;
  final LocationPoint? destination;

  EnrichedJourney({
    required this.journey,
    this.boardingStation,
    this.destinationStation,
    this.origin,
    this.destination,
  });

  String get boardingName =>
      boardingStation?.name ??
      journey.originName ??
      journey.boardingStationCode ??
      'Origin';

  String get destinationName =>
      destinationStation?.name ??
      journey.destinationName ??
      journey.destinationStationCode ??
      'Destination';

  LocationPoint? get destinationPoint {
    if (destinationStation != null) return LocationPoint.fromStation(destinationStation!);
    if (destination != null) return destination;
    if (journey.destinationLatitude != null && journey.destinationLongitude != null) {
      return LocationPoint(
        name: journey.destinationName ?? 'Destination',
        latitude: journey.destinationLatitude!,
        longitude: journey.destinationLongitude!,
      );
    }
    return null;
  }

  LocationPoint? get originPoint {
    if (boardingStation != null) return LocationPoint.fromStation(boardingStation!);
    if (origin != null) return origin;
    if (journey.originLatitude != null && journey.originLongitude != null) {
      return LocationPoint(
        name: journey.originName ?? 'Origin',
        latitude: journey.originLatitude!,
        longitude: journey.originLongitude!,
      );
    }
    return null;
  }
}

Future<EnrichedJourney> _enrichJourney(
  Journey journey, {
  required StationRepository stationRepo,
}) async {
  Station? boarding;
  Station? destination;
  LocationPoint? originPt;
  LocationPoint? destPt;

  if (journey.boardingStationCode != null && journey.boardingStationCode!.isNotEmpty) {
    boarding = await stationRepo.getStationByCode(journey.boardingStationCode!);
  }
  if (journey.destinationStationCode != null && journey.destinationStationCode!.isNotEmpty) {
    destination = await stationRepo.getStationByCode(journey.destinationStationCode!);
  }

  if (journey.originLatitude != null && journey.originLongitude != null) {
    originPt = LocationPoint(
      name: journey.originName ?? 'Origin',
      latitude: journey.originLatitude!,
      longitude: journey.originLongitude!,
      stationCode: journey.boardingStationCode,
    );
  }
  if (journey.destinationLatitude != null && journey.destinationLongitude != null) {
    destPt = LocationPoint(
      name: journey.destinationName ?? 'Destination',
      latitude: journey.destinationLatitude!,
      longitude: journey.destinationLongitude!,
      stationCode: journey.destinationStationCode,
    );
  }

  return EnrichedJourney(
    journey: journey,
    boardingStation: boarding,
    destinationStation: destination,
    origin: originPt,
    destination: destPt,
  );
}

final upcomingJourneysProvider =
    FutureProvider<List<EnrichedJourney>>((ref) async {
  final journeyRepo = ref.read(journeyRepositoryProvider);
  final stationRepo = ref.read(stationRepositoryProvider);
  final journeys = await journeyRepo.getUpcomingJourneys();
  return Future.wait(journeys.map((j) => _enrichJourney(j, stationRepo: stationRepo)));
});

final allJourneysProvider =
    FutureProvider<List<EnrichedJourney>>((ref) async {
  final journeyRepo = ref.read(journeyRepositoryProvider);
  final stationRepo = ref.read(stationRepositoryProvider);
  final journeys = await journeyRepo.getAllJourneys();
  return Future.wait(journeys.map((j) => _enrichJourney(j, stationRepo: stationRepo)));
});
