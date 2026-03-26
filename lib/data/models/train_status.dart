import 'package:equatable/equatable.dart';

class TrainStatus extends Equatable {
  final String trainNumber;
  final String trainName;
  final String currentStation;
  final int delayMinutes;
  final DateTime lastUpdated;
  final List<StationStatus> stationStatuses;

  const TrainStatus({
    required this.trainNumber,
    required this.trainName,
    required this.currentStation,
    required this.delayMinutes,
    required this.lastUpdated,
    this.stationStatuses = const [],
  });

  bool get isOnTime => delayMinutes <= 5;
  bool get isLate => delayMinutes > 5;

  String get delayText {
    if (isOnTime) return 'On Time';
    final hours = delayMinutes ~/ 60;
    final mins = delayMinutes % 60;
    if (hours > 0) {
      return 'Late by ${hours}h ${mins}m';
    }
    return 'Late by ${mins}m';
  }

  @override
  List<Object?> get props => [
        trainNumber, trainName, currentStation,
        delayMinutes, lastUpdated, stationStatuses,
      ];
}

class StationStatus extends Equatable {
  final String stationCode;
  final String stationName;
  final String? scheduledArrival;
  final String? actualArrival;
  final String? scheduledDeparture;
  final String? actualDeparture;
  final int delayMinutes;
  final bool hasPassed;

  const StationStatus({
    required this.stationCode,
    required this.stationName,
    this.scheduledArrival,
    this.actualArrival,
    this.scheduledDeparture,
    this.actualDeparture,
    this.delayMinutes = 0,
    this.hasPassed = false,
  });

  @override
  List<Object?> get props => [
        stationCode, stationName, scheduledArrival,
        actualArrival, scheduledDeparture, actualDeparture,
        delayMinutes, hasPassed,
      ];
}
