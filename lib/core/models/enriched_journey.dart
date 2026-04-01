import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/station.dart';

class EnrichedJourney {
  const EnrichedJourney({
    required this.journey,
    this.boardingStation,
    this.destinationStation,
    this.origin,
    this.destination,
  });

  final Journey journey;
  final Station? boardingStation;
  final Station? destinationStation;
  final LocationPoint? origin;
  final LocationPoint? destination;

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
    if (destinationStation != null) {
      return LocationPoint.fromStation(destinationStation!);
    }
    if (destination != null) {
      return destination;
    }
    if (journey.destinationLatitude != null &&
        journey.destinationLongitude != null) {
      return LocationPoint(
        name: journey.destinationName ?? 'Destination',
        latitude: journey.destinationLatitude!,
        longitude: journey.destinationLongitude!,
      );
    }
    return null;
  }

  LocationPoint? get originPoint {
    if (boardingStation != null) {
      return LocationPoint.fromStation(boardingStation!);
    }
    if (origin != null) {
      return origin;
    }
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
