import 'dart:ui';
import 'package:travel_companion/core/models/app_time.dart';

/// A single station on a local train line, with its position and coordinates.
class LocalTrainStation {
  final int id;
  final int lineId;
  final String code;
  final String name;
  final int stationIndex;
  final double latitude;
  final double longitude;
  final int platformCount;

  const LocalTrainStation({
    required this.id,
    required this.lineId,
    required this.code,
    required this.name,
    required this.stationIndex,
    required this.latitude,
    required this.longitude,
    this.platformCount = 2,
  });

  factory LocalTrainStation.fromMap(Map<String, dynamic> map) =>
      LocalTrainStation(
        id: map['id'] as int,
        lineId: map['line_id'] as int,
        code: map['code'] as String,
        name: map['name'] as String,
        stationIndex: map['station_index'] as int,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        platformCount: (map['platform_count'] as int?) ?? 2,
      );

  String get displayName => '$name ($code)';
}

/// A scheduled train departure from the origin station of a line.
class LocalTrainScheduleEntry {
  final int id;
  final int lineId;
  final String direction; // 'UP' or 'DN'
  final String trainType; // 'SLOW', 'FAST', 'SEMI_FAST'
  final int departureHour;
  final int departureMinute;
  final List<int> skipStationIndices;

  const LocalTrainScheduleEntry({
    required this.id,
    required this.lineId,
    required this.direction,
    required this.trainType,
    required this.departureHour,
    required this.departureMinute,
    this.skipStationIndices = const [],
  });

  factory LocalTrainScheduleEntry.fromMap(Map<String, dynamic> map) {
    final skipStr = map['skip_station_indices'] as String?;
    return LocalTrainScheduleEntry(
      id: map['id'] as int,
      lineId: map['line_id'] as int,
      direction: map['direction'] as String,
      trainType: map['train_type'] as String,
      departureHour: map['departure_hour'] as int,
      departureMinute: map['departure_minute'] as int,
      skipStationIndices: skipStr != null && skipStr.isNotEmpty
          ? skipStr.split(',').map(int.parse).toList()
          : [],
    );
  }

  AppTime get departureTime =>
      AppTime(hour: departureHour, minute: departureMinute);

  bool stopsAt(int stationIndex) => !skipStationIndices.contains(stationIndex);
}

/// A computed "next train" result with arrival times at source and destination.
class UpcomingTrain {
  final LocalTrainScheduleEntry schedule;
  final String trainType;
  final String direction;
  final AppTime departureAtSource;
  final AppTime arrivalAtDestination;
  final int travelMinutes;
  final int stopsCount;
  final String lineCode;
  final String lineName;
  final Color lineColor;

  const UpcomingTrain({
    required this.schedule,
    required this.trainType,
    required this.direction,
    required this.departureAtSource,
    required this.arrivalAtDestination,
    required this.travelMinutes,
    required this.stopsCount,
    required this.lineCode,
    required this.lineName,
    required this.lineColor,
  });

  String get trainTypeLabel {
    switch (trainType) {
      case 'FAST':
        return 'Fast';
      case 'SEMI_FAST':
        return 'Semi-Fast';
      default:
        return 'Slow';
    }
  }

  String get formattedDeparture =>
      '${departureAtSource.hour.toString().padLeft(2, '0')}:${departureAtSource.minute.toString().padLeft(2, '0')}';

  String get formattedArrival =>
      '${arrivalAtDestination.hour.toString().padLeft(2, '0')}:${arrivalAtDestination.minute.toString().padLeft(2, '0')}';

  String get travelDuration {
    final h = travelMinutes ~/ 60;
    final m = travelMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
