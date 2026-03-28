import 'package:flutter/material.dart';
import 'package:travel_companion/data/database/app_database.dart';
import 'package:travel_companion/data/models/local_train_line.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';

class LocalTrainRepository {
  /// All lines for a given city (default: Mumbai).
  Future<List<LocalTrainLine>> getLines({String city = 'Mumbai'}) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'local_train_lines',
      where: 'city = ?',
      whereArgs: [city],
      orderBy: 'id',
    );
    return rows.map(LocalTrainLine.fromMap).toList();
  }

  /// All stations on a line, ordered by station_index.
  Future<List<LocalTrainStation>> getStationsForLine(int lineId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'local_train_stations',
      where: 'line_id = ?',
      whereArgs: [lineId],
      orderBy: 'station_index ASC',
    );
    return rows.map(LocalTrainStation.fromMap).toList();
  }

  /// Find upcoming trains between two stations on a given line.
  ///
  /// Returns the next [limit] trains departing after [after] from [sourceIndex]
  /// heading towards [destIndex]. Computes arrival time using ~3 min/stop for
  /// SLOW, ~2 min/stop for FAST (counting only stops the train makes).
  Future<List<UpcomingTrain>> getUpcomingTrains({
    required int lineId,
    required int sourceIndex,
    required int destIndex,
    required TimeOfDay after,
    int limit = 10,
  }) async {
    final db = await AppDatabase.database;

    // Determine direction
    final direction = destIndex > sourceIndex ? 'UP' : 'DN';

    // Fetch all schedules for this line + direction
    final rows = await db.query(
      'local_train_schedules',
      where: 'line_id = ? AND direction = ?',
      whereArgs: [lineId, direction],
      orderBy: 'departure_hour ASC, departure_minute ASC',
    );

    final schedules = rows.map(LocalTrainScheduleEntry.fromMap).toList();

    // Fetch line info
    final lineRows = await db.query(
      'local_train_lines',
      where: 'id = ?',
      whereArgs: [lineId],
      limit: 1,
    );
    if (lineRows.isEmpty) return [];
    final line = LocalTrainLine.fromMap(lineRows.first);

    // Fetch all stations on this line
    final stations = await getStationsForLine(lineId);
    final totalStations = stations.length;

    final results = <UpcomingTrain>[];

    for (final schedule in schedules) {
      // Check if this train stops at both source and destination
      // For UP direction: origin is index 0, so departure time offset increases
      // For DN direction: origin is last index, so we reverse
      final originIndex = direction == 'UP' ? 0 : totalStations - 1;

      if (!schedule.stopsAt(sourceIndex) || !schedule.stopsAt(destIndex)) {
        continue;
      }

      // Calculate minutes from origin to source station
      final minutesPerStop = schedule.trainType == 'FAST' ? 2.0 : 3.0;

      // Count stops from origin to source (only stops this train makes)
      int stopsToSource = 0;
      if (direction == 'UP') {
        for (int i = originIndex; i < sourceIndex; i++) {
          if (schedule.stopsAt(i)) stopsToSource++;
        }
      } else {
        for (int i = originIndex; i > sourceIndex; i--) {
          if (schedule.stopsAt(i)) stopsToSource++;
        }
      }

      final minutesToSource = (stopsToSource * minutesPerStop).round();
      final sourceDepartureMinutes =
          schedule.departureHour * 60 + schedule.departureMinute + minutesToSource;
      final sourceHour = (sourceDepartureMinutes ~/ 60) % 24;
      final sourceMinute = sourceDepartureMinutes % 60;

      // Skip if already departed from source
      final afterMinutes = after.hour * 60 + after.minute;
      if (sourceDepartureMinutes < afterMinutes) continue;

      // Count stops from source to destination
      int stopsSourceToDest = 0;
      if (direction == 'UP') {
        for (int i = sourceIndex; i <= destIndex; i++) {
          if (schedule.stopsAt(i)) stopsSourceToDest++;
        }
      } else {
        for (int i = sourceIndex; i >= destIndex; i--) {
          if (schedule.stopsAt(i)) stopsSourceToDest++;
        }
      }
      // Subtract 1 because departure station doesn't count as a "travel" stop
      stopsSourceToDest = stopsSourceToDest > 0 ? stopsSourceToDest - 1 : 0;

      final travelMinutes = (stopsSourceToDest * minutesPerStop).round();
      final arrivalMinutes = sourceDepartureMinutes + travelMinutes;
      final arrivalHour = (arrivalMinutes ~/ 60) % 24;
      final arrivalMinute = arrivalMinutes % 60;

      results.add(UpcomingTrain(
        schedule: schedule,
        trainType: schedule.trainType,
        direction: direction,
        departureAtSource: TimeOfDay(hour: sourceHour, minute: sourceMinute),
        arrivalAtDestination: TimeOfDay(hour: arrivalHour, minute: arrivalMinute),
        travelMinutes: travelMinutes,
        stopsCount: stopsSourceToDest,
        lineCode: line.lineCode,
        lineName: line.lineName,
        lineColor: line.lineColor,
      ));

      if (results.length >= limit) break;
    }

    return results;
  }

  /// Search stations across all lines by name or code.
  Future<List<LocalTrainStation>> searchStations(String query) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'local_train_stations',
      where: 'name LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
      limit: 20,
    );
    return rows.map(LocalTrainStation.fromMap).toList();
  }
}
