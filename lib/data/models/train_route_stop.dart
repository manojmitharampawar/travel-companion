import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// A train stop enriched with geographic coordinates from the stations table.
/// Used for map rendering and route visualization.
class TrainRouteStop extends Equatable {
  final String stationCode;
  final String stationName;
  final int stopSequence;
  final double latitude;
  final double longitude;
  final String? arrivalTime;
  final String? departureTime;
  final int? distanceKm;

  const TrainRouteStop({
    required this.stationCode,
    required this.stationName,
    required this.stopSequence,
    required this.latitude,
    required this.longitude,
    this.arrivalTime,
    this.departureTime,
    this.distanceKm,
  });

  factory TrainRouteStop.fromMap(Map<String, dynamic> map) {
    return TrainRouteStop(
      stationCode: map['station_code'] as String,
      stationName:
          (map['station_name'] as String?) ?? (map['station_code'] as String),
      stopSequence: map['stop_sequence'] as int,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      arrivalTime: map['arrival_time'] as String?,
      departureTime: map['departure_time'] as String?,
      distanceKm: map['distance_km'] as int?,
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

  String get displayLabel => '$stationName ($stationCode)';

  /// Returns departure time if available, otherwise arrival time.
  String get timeDisplay {
    if (departureTime != null && departureTime!.isNotEmpty) {
      return departureTime!;
    }
    if (arrivalTime != null && arrivalTime!.isNotEmpty) {
      return arrivalTime!;
    }
    return '';
  }

  @override
  List<Object?> get props => [stationCode, stopSequence];
}
