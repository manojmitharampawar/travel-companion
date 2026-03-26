import 'package:travel_companion/data/database/app_database.dart';
import 'package:travel_companion/data/models/location_point.dart';

class LocationRepository {
  Future<int> saveLocation(LocationPoint location) async {
    final db = await AppDatabase.database;
    return db.insert('custom_locations', {
      'name': location.name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'address': location.address,
      'used_count': 0,
      'last_used': DateTime.now().toIso8601String(),
    });
  }

  Future<List<LocationPoint>> searchLocations(String query) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'custom_locations',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'used_count DESC',
      limit: 20,
    );
    return results.map((row) => LocationPoint.fromMap(row)).toList();
  }

  Future<List<LocationPoint>> getRecentLocations({int limit = 10}) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'custom_locations',
      orderBy: 'last_used DESC',
      limit: limit,
    );
    return results.map((row) => LocationPoint.fromMap(row)).toList();
  }

  Future<void> incrementUsageCount(int id) async {
    final db = await AppDatabase.database;
    await db.rawUpdate(
      'UPDATE custom_locations SET used_count = used_count + 1, last_used = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> deleteLocation(int id) async {
    final db = await AppDatabase.database;
    await db.delete('custom_locations', where: 'id = ?', whereArgs: [id]);
  }
}
