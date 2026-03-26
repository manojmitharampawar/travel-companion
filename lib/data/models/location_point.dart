import 'package:equatable/equatable.dart';
import 'package:travel_companion/data/models/station.dart';

class LocationPoint extends Equatable {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String? stationCode;
  final String? address;

  const LocationPoint({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.stationCode,
    this.address,
  });

  factory LocationPoint.fromStation(Station station) {
    return LocationPoint(
      id: station.id,
      name: station.name,
      latitude: station.latitude,
      longitude: station.longitude,
      stationCode: station.code,
    );
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      id: map['id'] as int?,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      stationCode: map['station_code'] as String?,
      address: map['address'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'station_code': stationCode,
      'address': address,
    };
  }

  String get displayName {
    if (stationCode != null) return '$name ($stationCode)';
    if (address != null) return '$name, $address';
    return name;
  }

  LocationPoint copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    String? stationCode,
    String? address,
  }) {
    return LocationPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      stationCode: stationCode ?? this.stationCode,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [id, name, latitude, longitude, stationCode, address];
}
