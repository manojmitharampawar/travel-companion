import 'package:travel_companion/data/database/app_database.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';

class TrainRepository {
  /// Get train details (name) by train number from local DB
  Future<String?> getTrainNameByNumber(String trainNumber) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'train_routes',
      columns: ['train_name'],
      where: 'train_number = ?',
      whereArgs: [trainNumber],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['train_name'] as String?;
  }

  /// Get all stops for a train in order
  Future<List<TrainRoute>> getTrainRoute(String trainNumber) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'train_routes',
      where: 'train_number = ?',
      whereArgs: [trainNumber],
      orderBy: 'stop_sequence ASC',
    );
    return results.map(TrainRoute.fromMap).toList();
  }

  /// Get route between two stations for a specific train
  Future<List<TrainRoute>> getRouteBetweenStations({
    required String trainNumber,
    required String fromStation,
    required String toStation,
  }) async {
    final fullRoute = await getTrainRoute(trainNumber);
    if (fullRoute.isEmpty) return [];

    int? fromIdx;
    int? toIdx;

    for (var i = 0; i < fullRoute.length; i++) {
      if (fullRoute[i].stationCode == fromStation) fromIdx = i;
      if (fullRoute[i].stationCode == toStation) toIdx = i;
    }

    if (fromIdx == null || toIdx == null || fromIdx >= toIdx) return fullRoute;
    return fullRoute.sublist(fromIdx, toIdx + 1);
  }

  /// Search trains by number or name
  Future<List<Map<String, String>>> searchTrains(String query) async {
    final db = await AppDatabase.database;
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT train_number, train_name
      FROM train_routes
      WHERE train_number LIKE ? OR train_name LIKE ?
      LIMIT 20
      ''',
      ['%$query%', '%$query%'],
    );

    return results
        .map(
          (r) => {
            'train_number': r['train_number'] as String,
            'train_name': r['train_name'] as String,
          },
        )
        .toList();
  }

  /// Get source and destination for a train
  Future<Map<String, String>?> getTrainEndpoints(String trainNumber) async {
    final route = await getTrainRoute(trainNumber);
    if (route.isEmpty) return null;

    return {
      'from_station': route.first.stationCode,
      'to_station': route.last.stationCode,
      'train_name': route.first.trainName,
    };
  }

  /// Get all stops for a train with geographic coordinates (JOIN with stations).
  /// Only returns stops that have matching station records with coordinates.
  Future<List<TrainRouteStop>> getRouteStopsWithCoordinates(
    String trainNumber,
  ) async {
    final db = await AppDatabase.database;
    final results = await db.rawQuery(
      '''
      SELECT tr.station_code, tr.stop_sequence, tr.arrival_time,
             tr.departure_time, tr.distance_km,
             s.name AS station_name, s.latitude, s.longitude
      FROM train_routes tr
      LEFT JOIN stations s ON tr.station_code = s.code
      WHERE tr.train_number = ?
      ORDER BY tr.stop_sequence ASC
      ''',
      [trainNumber],
    );

    return results
        .where((r) => r['latitude'] != null && r['longitude'] != null)
        .map(TrainRouteStop.fromMap)
        .toList();
  }

  /// Get stops between two stations (inclusive) with geographic coordinates.
  /// Falls back to the full route when station indices cannot be found.
  Future<List<TrainRouteStop>> getRouteSegmentWithCoordinates({
    required String trainNumber,
    required String fromStation,
    required String toStation,
  }) async {
    final fullRoute = await getRouteStopsWithCoordinates(trainNumber);
    if (fullRoute.isEmpty) return [];

    int? fromIdx;
    int? toIdx;
    for (var i = 0; i < fullRoute.length; i++) {
      if (fullRoute[i].stationCode == fromStation) fromIdx = i;
      if (fullRoute[i].stationCode == toStation) toIdx = i;
    }

    if (fromIdx == null || toIdx == null || fromIdx >= toIdx) return fullRoute;
    return fullRoute.sublist(fromIdx, toIdx + 1);
  }
}
