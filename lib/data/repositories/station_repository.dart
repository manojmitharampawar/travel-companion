import 'package:sqflite/sqflite.dart';
import 'package:travel_companion/data/database/app_database.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/datasources/remote/metro_station_api.dart';

class StationRepository {
  final _metroStationApi = MetroStationApi();

  Future<List<Station>> searchStations(String query) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'stations',
      where: 'name LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%${query.toUpperCase()}%'],
      limit: 20,
    );
    return results.map(Station.fromMap).toList();
  }

  /// Search metro stations by name or code, falling back to API if local data is sparse.
  Future<List<Station>> searchMetroStations(String query) =>
      _searchByTypeWithApiFallback(
        query: query,
        stationType: 'metro',
        apiFetch: (q) => _metroStationApi.searchMetroStations(q, null),
      );

  /// Search local train stations by name or code, falling back to API if local data is sparse.
  Future<List<Station>> searchLocalTrainStations(String query) =>
      _searchByTypeWithApiFallback(
        query: query,
        stationType: 'local_train',
        apiFetch: (q) => _metroStationApi.searchLocalTrainStations(q, null),
      );

  Future<List<Station>> _searchByTypeWithApiFallback({
    required String query,
    required String stationType,
    required Future<List<Station>> Function(String) apiFetch,
  }) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'stations',
      where: 'station_type = ? AND (name LIKE ? OR code LIKE ? OR zone LIKE ?)',
      whereArgs: [
        stationType,
        '%$query%',
        '%${query.toUpperCase()}%',
        '%$query%',
      ],
      limit: 20,
    );

    final stations = results.map(Station.fromMap).toList();

    if (stations.length < 5) {
      try {
        final apiStations = await apiFetch(query);
        await _upsertStations(db, apiStations, stationType);
        stations.addAll(apiStations);
      } catch (_) {
        // API unavailable — return local results only
      }
    }

    return stations;
  }

  Future<void> _upsertStations(
    Database db,
    List<Station> stations,
    String stationType,
  ) async {
    for (final station in stations) {
      final data = station.toMap();
      if ((data['id'] as int?) == 0) data.remove('id');
      data['station_type'] = stationType;
      await db.insert(
        'stations',
        data,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Get all metro stations by line
  Future<List<Station>> getMetroStationsByLine(String lineName) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'stations',
      where: 'station_type = ? AND zone LIKE ?',
      whereArgs: ['metro', '%$lineName%'],
      orderBy: 'name ASC',
    );
    return results.map(Station.fromMap).toList();
  }

  /// Get all local train stations by line
  Future<List<Station>> getLocalTrainStationsByLine(String lineName) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'stations',
      where: 'station_type = ? AND zone LIKE ?',
      whereArgs: ['local_train', '%$lineName%'],
      orderBy: 'name ASC',
    );
    return results.map(Station.fromMap).toList();
  }

  Future<Station?> getStationByCode(String code) async {
    final db = await AppDatabase.database;

    // 1. Try main stations table
    final results = await db.query(
      'stations',
      where: 'code = ?',
      whereArgs: [code.toUpperCase()],
      limit: 1,
    );
    if (results.isNotEmpty) return Station.fromMap(results.first);

    // 2. Try local_train_stations table
    final ltResults = await db.query(
      'local_train_stations',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (ltResults.isNotEmpty) {
      final r = ltResults.first;
      return Station(
        id: r['id'] as int,
        code: r['code'] as String,
        name: r['name'] as String,
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
        stationType: 'local_train',
      );
    }

    // 3. Try metro_stations table
    final metroResults = await db.query(
      'metro_stations',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (metroResults.isNotEmpty) {
      final r = metroResults.first;
      return Station(
        id: r['id'] as int,
        code: r['code'] as String,
        name: r['name'] as String,
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
        stationType: 'metro',
      );
    }

    return null;
  }

  Future<Station?> getStationByName(String name) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'stations',
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Station.fromMap(results.first);
  }

  Future<List<Station>> getAllStations() async {
    final db = await AppDatabase.database;
    final results = await db.query('stations', orderBy: 'name ASC');
    return results.map(Station.fromMap).toList();
  }

  Future<Station?> findNearestStation(
    double latitude,
    double longitude, {
    double maxDistanceKm = 5.0,
  }) async {
    final db = await AppDatabase.database;
    // ~111km per degree latitude; ~85km per degree longitude at Indian latitudes
    final latDelta = maxDistanceKm / 111.0;
    final lonDelta = maxDistanceKm / 85.0;

    final results = await db.query(
      'stations',
      where: 'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?',
      whereArgs: [
        latitude - latDelta,
        latitude + latDelta,
        longitude - lonDelta,
        longitude + lonDelta,
      ],
    );

    if (results.isEmpty) return null;

    final stations = results.map(Station.fromMap).toList();
    stations.sort((a, b) {
      final dA = _distSq(latitude, longitude, a.latitude, a.longitude);
      final dB = _distSq(latitude, longitude, b.latitude, b.longitude);
      return dA.compareTo(dB);
    });

    return stations.first;
  }

  // Euclidean approximation — sufficient for short-range station proximity sorting
  double _distSq(double lat1, double lon1, double lat2, double lon2) {
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    return dLat * dLat + dLon * dLon;
  }
}
