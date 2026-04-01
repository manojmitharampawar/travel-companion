import 'package:travel_companion/core/domain/contracts/station_lookup.dart';
import 'package:travel_companion/core/models/enriched_journey.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/station.dart';

class JourneyEnricher {
  const JourneyEnricher({required StationLookup stationLookup})
    : _stationLookup = stationLookup;

  final StationLookup _stationLookup;

  Future<EnrichedJourney> enrich(Journey journey) async {
    final boardingStation = await _resolveStation(journey.boardingStationCode);
    final destinationStation = await _resolveStation(
      journey.destinationStationCode,
    );

    return EnrichedJourney(
      journey: journey,
      boardingStation: boardingStation,
      destinationStation: destinationStation,
      origin: _mapJourneyPoint(
        name: journey.originName ?? 'Origin',
        latitude: journey.originLatitude,
        longitude: journey.originLongitude,
        stationCode: journey.boardingStationCode,
      ),
      destination: _mapJourneyPoint(
        name: journey.destinationName ?? 'Destination',
        latitude: journey.destinationLatitude,
        longitude: journey.destinationLongitude,
        stationCode: journey.destinationStationCode,
      ),
    );
  }

  Future<Station?> _resolveStation(String? code) async {
    if (code == null || code.isEmpty) {
      return null;
    }
    return _stationLookup.getByCode(code);
  }

  LocationPoint? _mapJourneyPoint({
    required String name,
    required double? latitude,
    required double? longitude,
    required String? stationCode,
  }) {
    if (latitude == null || longitude == null) {
      return null;
    }

    return LocationPoint(
      name: name,
      latitude: latitude,
      longitude: longitude,
      stationCode: stationCode,
    );
  }
}
