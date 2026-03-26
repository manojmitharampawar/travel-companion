import 'package:equatable/equatable.dart';

class TrainRoute extends Equatable {
  final int id;
  final String trainNumber;
  final String trainName;
  final String stationCode;
  final int stopSequence;
  final String? arrivalTime;
  final String? departureTime;
  final int day;
  final int? distanceKm;

  const TrainRoute({
    required this.id,
    required this.trainNumber,
    required this.trainName,
    required this.stationCode,
    required this.stopSequence,
    this.arrivalTime,
    this.departureTime,
    this.day = 1,
    this.distanceKm,
  });

  factory TrainRoute.fromMap(Map<String, dynamic> map) {
    return TrainRoute(
      id: map['id'] as int,
      trainNumber: map['train_number'] as String,
      trainName: map['train_name'] as String,
      stationCode: map['station_code'] as String,
      stopSequence: map['stop_sequence'] as int,
      arrivalTime: map['arrival_time'] as String?,
      departureTime: map['departure_time'] as String?,
      day: (map['day'] as int?) ?? 1,
      distanceKm: map['distance_km'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'train_number': trainNumber,
      'train_name': trainName,
      'station_code': stationCode,
      'stop_sequence': stopSequence,
      'arrival_time': arrivalTime,
      'departure_time': departureTime,
      'day': day,
      'distance_km': distanceKm,
    };
  }

  @override
  List<Object?> get props => [
        id, trainNumber, trainName, stationCode,
        stopSequence, arrivalTime, departureTime, day, distanceKm,
      ];
}
