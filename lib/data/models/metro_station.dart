import 'package:equatable/equatable.dart';

/// A metro station belonging to a specific metro line.
class MetroStation extends Equatable {
  final int id;
  final String code; // Station code (unique across all metros)
  final int lineId; // FK to metro_lines
  final String name;
  final int stationIndex; // Order in the line (0-based)
  final double latitude;
  final double longitude;

  const MetroStation({
    required this.id,
    required this.code,
    required this.lineId,
    required this.name,
    required this.stationIndex,
    required this.latitude,
    required this.longitude,
  });

  factory MetroStation.fromMap(Map<String, dynamic> map) {
    return MetroStation(
      id: map['id'] as int,
      code: map['code'] as String,
      lineId: map['line_id'] as int,
      name: map['name'] as String,
      stationIndex: map['station_index'] as int,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'line_id': lineId,
      'name': name,
      'station_index': stationIndex,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [id, code, lineId, name, stationIndex];
}

