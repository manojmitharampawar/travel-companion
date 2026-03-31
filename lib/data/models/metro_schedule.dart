import 'dart:ui';
import 'package:flutter/material.dart' show TimeOfDay;

/// A metro schedule entry representing a departure from the first station.
class MetroScheduleEntry {
  final int id;
  final int lineId;
  final String direction; // 'UP' or 'DN'
  final int departureHour;
  final int departureMinute;

  const MetroScheduleEntry({
    required this.id,
    required this.lineId,
    required this.direction,
    required this.departureHour,
    required this.departureMinute,
  });

  factory MetroScheduleEntry.fromMap(Map<String, dynamic> map) {
    return MetroScheduleEntry(
      id: map['id'] as int,
      lineId: map['line_id'] as int,
      direction: map['direction'] as String,
      departureHour: map['departure_hour'] as int,
      departureMinute: map['departure_minute'] as int,
    );
  }

  TimeOfDay get departureTime =>
      TimeOfDay(hour: departureHour, minute: departureMinute);
}

/// A computed upcoming metro train with arrival times at source and destination.
class UpcomingMetro {
  final MetroScheduleEntry schedule;
  final String direction;
  final TimeOfDay departureAtSource;
  final TimeOfDay arrivalAtDestination;
  final int travelMinutes;
  final int stopsCount;
  final String lineCode;
  final String lineName;
  final Color lineColor;

  const UpcomingMetro({
    required this.schedule,
    required this.direction,
    required this.departureAtSource,
    required this.arrivalAtDestination,
    required this.travelMinutes,
    required this.stopsCount,
    required this.lineCode,
    required this.lineName,
    required this.lineColor,
  });

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
