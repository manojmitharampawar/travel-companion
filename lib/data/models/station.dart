import 'package:equatable/equatable.dart';

class Station extends Equatable {
  final int id;
  final String code;
  final String name;
  final double latitude;
  final double longitude;
  final String? state;
  final String? zone;
  final String? stationType; // 'metro', 'local_train', 'railway', etc.

  const Station({
    required this.id,
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.state,
    this.zone,
    this.stationType,
  });

  factory Station.fromMap(Map<String, dynamic> map) {
    return Station(
      id: map['id'] as int,
      code: map['code'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      state: map['state'] as String?,
      zone: map['zone'] as String?,
      stationType: map['station_type'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'zone': zone,
      if (stationType != null) 'station_type': stationType,
    };
  }

  String get displayName => '$name ($code)';

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    latitude,
    longitude,
    state,
    zone,
    stationType,
  ];

  @override
  String toString() => displayName;
}
