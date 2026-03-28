import 'package:travel_companion/data/database/app_database.dart';
import 'package:travel_companion/data/models/journey.dart';

class JourneyRepository {
  Future<int> insertJourney(Journey journey) async {
    final db = await AppDatabase.database;
    return db.insert('journeys', journey.toMap());
  }

  Future<void> updateJourney(Journey journey) async {
    final db = await AppDatabase.database;
    await db.update(
      'journeys',
      journey.toMap(),
      where: 'id = ?',
      whereArgs: [journey.id],
    );
  }

  Future<void> updateJourneyStatus(int id, JourneyStatus status) async {
    final db = await AppDatabase.database;
    await db.update(
      'journeys',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteJourney(int id) async {
    final db = await AppDatabase.database;
    await db.delete('journeys', where: 'id = ?', whereArgs: [id]);
  }

  Future<Journey?> getJourneyById(int id) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'journeys',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Journey.fromMap(results.first);
  }

  /// Auto-completes past-dated upcoming/active journeys, then returns remaining upcoming ones.
  Future<List<Journey>> getUpcomingJourneys() async {
    final db = await AppDatabase.database;

    // Move past-dated journeys (before today) from upcoming/active → completed
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await db.update(
      'journeys',
      {'status': 'completed'},
      where: "status IN ('upcoming', 'active') AND journey_date < ? AND (repeat_days IS NULL OR repeat_days = 0)",
      whereArgs: [todayStr],
    );

    final results = await db.query(
      'journeys',
      where: 'status IN (?, ?) AND (repeat_days IS NULL OR repeat_days = 0)',
      whereArgs: ['upcoming', 'active'],
      orderBy: 'journey_date ASC',
    );
    return results.map(Journey.fromMap).toList();
  }

  Future<List<Journey>> getAllJourneys() async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'journeys',
      where: 'repeat_days IS NULL OR repeat_days = 0',
      orderBy: 'journey_date DESC',
    );
    return results.map(Journey.fromMap).toList();
  }

  Future<List<Journey>> getJourneysForDate(DateTime date) async {
    final db = await AppDatabase.database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final results = await db.query(
      'journeys',
      where: 'journey_date LIKE ? AND (repeat_days IS NULL OR repeat_days = 0)',
      whereArgs: ['$dateStr%'],
    );
    return results.map(Journey.fromMap).toList();
  }

  Future<Journey?> getActiveJourney() async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'journeys',
      where: 'status = ?',
      whereArgs: ['active'],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Journey.fromMap(results.first);
  }

  Future<bool> journeyExistsForPnr(String pnr) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'journeys',
      where: 'pnr = ?',
      whereArgs: [pnr],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<List<Journey>> getJourneyHistory() async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'journeys',
      where: 'status IN (?, ?) AND (repeat_days IS NULL OR repeat_days = 0)',
      whereArgs: ['completed', 'cancelled'],
      orderBy: 'journey_date DESC',
    );
    return results.map(Journey.fromMap).toList();
  }

  Future<List<Journey>> getFavoriteJourneys() async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'journeys',
      where: 'is_favorite = 1',
      orderBy: 'journey_date DESC',
    );
    return results.map(Journey.fromMap).toList();
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await AppDatabase.database;
    await db.update(
      'journeys',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> rescheduleFromFavorite(Journey favorite, DateTime newDate) async {
    final newJourney = favorite.copyWith(
      id: null,
      journeyDate: newDate,
      status: JourneyStatus.upcoming,
      createdAt: DateTime.now(),
      pnr: null,
    );
    return insertJourney(newJourney);
  }

  /// Get journeys with repeat_days set (templates)
  Future<List<Journey>> getRepeatJourneys() async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'journeys',
      where: 'repeat_days IS NOT NULL AND repeat_days > 0',
    );
    return results.map(Journey.fromMap).toList();
  }

  /// Get active quick trips
  Future<List<Journey>> getQuickTrips() async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'journeys',
      where: 'is_quick_trip = 1 AND status = ?',
      whereArgs: ['active'],
      orderBy: 'created_at DESC',
    );
    return results.map(Journey.fromMap).toList();
  }
}
