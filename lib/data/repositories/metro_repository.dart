import 'package:travel_companion/data/database/app_database.dart';
import 'package:travel_companion/data/models/metro_line.dart';
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
  Future<List<MetroStation>> searchStationsByLine(int lineId, String query) async {
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
}

