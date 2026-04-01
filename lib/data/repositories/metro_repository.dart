import 'package:travel_companion/core/models/app_time.dart';
import 'package:travel_companion/data/database/app_database.dart';
import 'package:travel_companion/data/models/metro_line.dart';
import 'package:travel_companion/data/models/metro_schedule.dart';
import 'package:travel_companion/data/models/metro_station.dart';

/// Repository for metro line and station queries.
class MetroRepository {
  /// Get all metro lines for a given city.
  Future<List<MetroLine>> getLinesByCity(String city) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'metro_lines',
      where: 'city = ?',
      whereArgs: [city],
      orderBy: 'line_name ASC',
    );
    return results.map(MetroLine.fromMap).toList();
  }

  /// Get all unique cities that have metro lines.
  Future<List<String>> getCitiesWithMetro() async {
    final db = await AppDatabase.database;
    final results = await db.rawQuery(
      'SELECT DISTINCT city FROM metro_lines ORDER BY city ASC',
    );
    return results.map((r) => r['city'] as String).toList();
  }

  /// Get all stations on a specific metro line, ordered by station_index.
  Future<List<MetroStation>> getStationsByLine(int lineId) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'metro_stations',
      where: 'line_id = ?',
      whereArgs: [lineId],
      orderBy: 'station_index ASC',
    );
    return results.map(MetroStation.fromMap).toList();
  }

  /// Get a specific metro station by code.
  Future<MetroStation?> getStationByCode(String code) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'metro_stations',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MetroStation.fromMap(results.first);
  }

  /// Search metro stations by name within a specific line.
  Future<List<MetroStation>> searchStationsByLine(
    int lineId,
    String query,
  ) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'metro_stations',
      where: 'line_id = ? AND name LIKE ?',
      whereArgs: [lineId, '%$query%'],
      orderBy: 'station_index ASC',
    );
    return results.map(MetroStation.fromMap).toList();
  }

  /// Get the route between two stations on the same metro line.
  /// Returns stations from startCode to endCode (inclusive), ordered by station_index.
  Future<List<MetroStation>> getStationRoute({
    required int lineId,
    required String startCode,
    required String endCode,
  }) async {
    final allStations = await getStationsByLine(lineId);
    if (allStations.isEmpty) return [];

    int? startIdx;
    int? endIdx;

    for (var i = 0; i < allStations.length; i++) {
      if (allStations[i].code == startCode) startIdx = i;
      if (allStations[i].code == endCode) endIdx = i;
    }

    if (startIdx == null || endIdx == null) return [];
    if (startIdx > endIdx) {
      // Swap if reversed
      final temp = startIdx;
      startIdx = endIdx;
      endIdx = temp;
    }

    return allStations.sublist(startIdx, endIdx + 1);
  }

  /// Insert a new metro line.
  Future<int> insertMetroLine(MetroLine line) async {
    final db = await AppDatabase.database;
    return await db.insert('metro_lines', line.toMap());
  }

  /// Insert a new metro station.
  Future<int> insertMetroStation(MetroStation station) async {
    final db = await AppDatabase.database;
    return await db.insert('metro_stations', station.toMap());
  }

  /// Get metro line by ID.
  Future<MetroLine?> getLineById(int lineId) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'metro_lines',
      where: 'id = ?',
      whereArgs: [lineId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MetroLine.fromMap(results.first);
  }

  /// Find upcoming metro trains between two stations on a given line.
  ///
  /// Metro trains stop at every station (~2 min/stop).
  /// Returns the next [limit] trains departing after [after].
  Future<List<UpcomingMetro>> getUpcomingMetros({
    required int lineId,
    required int sourceIndex,
    required int destIndex,
    required AppTime after,
    int limit = 10,
  }) async {
    final db = await AppDatabase.database;

    final direction = destIndex > sourceIndex ? 'UP' : 'DN';

    final rows = await db.query(
      'metro_schedules',
      where: 'line_id = ? AND direction = ?',
      whereArgs: [lineId, direction],
      orderBy: 'departure_hour ASC, departure_minute ASC',
    );

    final schedules = rows.map(MetroScheduleEntry.fromMap).toList();

    // Fetch line info
    final line = await getLineById(lineId);
    if (line == null) return [];

    // Get total station count for this line
    final stations = await getStationsByLine(lineId);
    final totalStations = stations.length;

    const minutesPerStop = 2.0; // Metro: ~2 min between stops
    final results = <UpcomingMetro>[];

    for (final schedule in schedules) {
      final originIndex = direction == 'UP' ? 0 : totalStations - 1;

      // Minutes from origin to source
      final stopsToSource = (sourceIndex - originIndex).abs();
      final minutesToSource = (stopsToSource * minutesPerStop).round();
      final sourceDepartureMinutes =
          schedule.departureHour * 60 +
          schedule.departureMinute +
          minutesToSource;
      final sourceHour = (sourceDepartureMinutes ~/ 60) % 24;
      final sourceMinute = sourceDepartureMinutes % 60;

      // Skip if already departed
      final afterMinutes = after.hour * 60 + after.minute;
      if (sourceDepartureMinutes < afterMinutes) continue;

      // Travel time from source to destination
      final stopsSourceToDest = (destIndex - sourceIndex).abs();
      final travelMinutes = (stopsSourceToDest * minutesPerStop).round();
      final arrivalMinutes = sourceDepartureMinutes + travelMinutes;
      final arrivalHour = (arrivalMinutes ~/ 60) % 24;
      final arrivalMinute = arrivalMinutes % 60;

      results.add(
        UpcomingMetro(
          schedule: schedule,
          direction: direction,
          departureAtSource: AppTime(hour: sourceHour, minute: sourceMinute),
          arrivalAtDestination: AppTime(
            hour: arrivalHour,
            minute: arrivalMinute,
          ),
          travelMinutes: travelMinutes,
          stopsCount: stopsSourceToDest,
          lineCode: line.lineCode ?? line.id.toString(),
          lineName: line.displayName,
          lineColor: line.color,
        ),
      );

      if (results.length >= limit) break;
    }

    return results;
  }
}
