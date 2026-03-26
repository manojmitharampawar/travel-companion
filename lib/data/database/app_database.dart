import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:travel_companion/data/database/train_seed_data.dart';

class AppDatabase {
  static Database? _database;
  static const int _version = 4;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, 'travel_companion.db');

    return openDatabase(
      dbPath,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stations (
        id INTEGER PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        state TEXT,
        zone TEXT,
        station_type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE train_routes (
        id INTEGER PRIMARY KEY,
        train_number TEXT NOT NULL,
        train_name TEXT NOT NULL,
        station_code TEXT NOT NULL,
        stop_sequence INTEGER NOT NULL,
        arrival_time TEXT,
        departure_time TEXT,
        day INTEGER DEFAULT 1,
        distance_km INTEGER,
        FOREIGN KEY (station_code) REFERENCES stations(code)
      )
    ''');

    await db.execute('''
      CREATE TABLE journeys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transport_type TEXT DEFAULT 'train',
        pnr TEXT,
        train_number TEXT DEFAULT '',
        train_name TEXT,
        vehicle_number TEXT,
        vehicle_name TEXT,
        journey_date TEXT NOT NULL,
        boarding_station_code TEXT DEFAULT '',
        destination_station_code TEXT DEFAULT '',
        origin_latitude REAL,
        origin_longitude REAL,
        destination_latitude REAL,
        destination_longitude REAL,
        origin_name TEXT,
        destination_name TEXT,
        class TEXT,
        berth TEXT,
        is_favorite INTEGER DEFAULT 0,
        is_quick_trip INTEGER DEFAULT 0,
        repeat_days INTEGER,
        scheduled_time TEXT,
        status TEXT DEFAULT 'upcoming',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        address TEXT,
        used_count INTEGER DEFAULT 0,
        last_used TEXT
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_stations_code ON stations(code)');
    await db.execute('CREATE INDEX idx_stations_name ON stations(name)');
    await db.execute('CREATE INDEX idx_train_routes_number ON train_routes(train_number)');
    await db.execute('CREATE INDEX idx_journeys_status ON journeys(status)');
    await db.execute('CREATE INDEX idx_journeys_date ON journeys(journey_date)');
    await db.execute('CREATE INDEX idx_journeys_transport ON journeys(transport_type)');
    await db.execute('CREATE INDEX idx_custom_locations_name ON custom_locations(name)');

    // Seed data
    await _seedStations(db);
    await _seedTrainRoutes(db);
    await _seedTrainRoutesFromCsv(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to journeys table
      await db.execute("ALTER TABLE journeys ADD COLUMN transport_type TEXT DEFAULT 'train'");
      await db.execute('ALTER TABLE journeys ADD COLUMN vehicle_number TEXT');
      await db.execute('ALTER TABLE journeys ADD COLUMN vehicle_name TEXT');
      await db.execute('ALTER TABLE journeys ADD COLUMN origin_latitude REAL');
      await db.execute('ALTER TABLE journeys ADD COLUMN origin_longitude REAL');
      await db.execute('ALTER TABLE journeys ADD COLUMN destination_latitude REAL');
      await db.execute('ALTER TABLE journeys ADD COLUMN destination_longitude REAL');
      await db.execute('ALTER TABLE journeys ADD COLUMN origin_name TEXT');
      await db.execute('ALTER TABLE journeys ADD COLUMN destination_name TEXT');
      await db.execute('ALTER TABLE journeys ADD COLUMN is_quick_trip INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE journeys ADD COLUMN repeat_days INTEGER');
      await db.execute('ALTER TABLE journeys ADD COLUMN scheduled_time TEXT');

      // Migrate existing train data
      await db.execute('UPDATE journeys SET vehicle_number = train_number, vehicle_name = train_name');

      // Create custom_locations table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_locations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          address TEXT,
          used_count INTEGER DEFAULT 0,
          last_used TEXT
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_journeys_transport ON journeys(transport_type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_custom_locations_name ON custom_locations(name)');
    }
    if (oldVersion < 3) {
      // Add station_type column to stations table for filtering metro/local train
      try {
        await db.execute('ALTER TABLE stations ADD COLUMN station_type TEXT');
      } catch (e) {
        // Column might already exist, skip silently
      }
    }
    if (oldVersion < 4) {
      // Seed additional train routes from CSV (safe: uses INSERT OR IGNORE)
      await _seedTrainRoutesFromCsv(db);
    }
  }

  /// Loads station data from bundled CSV asset.
  static Future<void> _seedStations(Database db) async {
    try {
      // Check if stations table is already populated
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM stations'),
      );
      if (count != null && count > 0) {
        // Already seeded, skip
        return;
      }

      final csvString = await rootBundle.loadString('assets/db/stations.csv');
      final lines = csvString.split('\n');

      final batch = db.batch();
      var id = 1;
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final fields = _parseCsvLine(line);
        if (fields.length < 6) continue;

        batch.insert('stations', {
          'id': id++,
          'code': fields[0].trim(),
          'name': fields[1].trim(),
          'latitude': double.tryParse(fields[2].trim()) ?? 0.0,
          'longitude': double.tryParse(fields[3].trim()) ?? 0.0,
          'state': fields[4].trim(),
          'zone': fields[5].trim(),
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Try fallback only if table is empty
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM stations'),
      );
      if (count == null || count == 0) {
        await _seedFallbackStations(db);
      }
    }
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    fields.add(current.toString());
    return fields;
  }

  static Future<void> _seedTrainRoutes(Database db) async {
    final routes = getTrainSeedData();
    final batch = db.batch();
    for (var i = 0; i < routes.length; i++) {
      batch.insert('train_routes', {'id': i + 1, ...routes[i]});
    }
    await batch.commit(noResult: true);
  }

  /// Seeds additional train routes from the bundled CSV asset.
  /// Uses INSERT OR IGNORE so it is safe to call on both fresh installs and upgrades.
  static Future<void> _seedTrainRoutesFromCsv(Database db) async {
    try {
      final csvString =
          await rootBundle.loadString('assets/db/train_routes.csv');
      final lines = csvString.split('\n');
      if (lines.isEmpty) return;

      // Get current max id so CSV ids don't collide with Dart seed ids
      final maxIdResult =
          await db.rawQuery('SELECT MAX(id) as max_id FROM train_routes');
      var nextId = (Sqflite.firstIntValue(
                  await db.rawQuery('SELECT COUNT(*) FROM train_routes')) ??
              0) +
          1;
      final currentMaxId = maxIdResult.first['max_id'] as int? ?? 0;
      nextId = currentMaxId + 1;

      final batch = db.batch();
      // Skip header line (index 0)
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final fields = _parseCsvLine(line);
        // train_number,train_name,station_code,stop_sequence,
        // arrival_time,departure_time,day,distance_km
        if (fields.length < 6) continue;

        final arrivalTime = fields.length > 4 ? fields[4].trim() : '';
        final departureTime = fields.length > 5 ? fields[5].trim() : '';
        final day = fields.length > 6 ? int.tryParse(fields[6].trim()) ?? 1 : 1;
        final distanceKm =
            fields.length > 7 ? int.tryParse(fields[7].trim()) : null;

        batch.insert(
          'train_routes',
          {
            'id': nextId++,
            'train_number': fields[0].trim(),
            'train_name': fields[1].trim(),
            'station_code': fields[2].trim(),
            'stop_sequence': int.tryParse(fields[3].trim()) ?? 0,
            'arrival_time': arrivalTime.isEmpty ? null : arrivalTime,
            'departure_time': departureTime.isEmpty ? null : departureTime,
            'day': day,
            'distance_km': distanceKm,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // CSV not found or malformed — skip silently, Dart seed is the fallback
    }
  }

  static Future<void> _seedFallbackStations(Database db) async {
    final stations = [
      {'code': 'NDLS', 'name': 'New Delhi', 'latitude': 28.6424, 'longitude': 77.2194, 'state': 'Delhi', 'zone': 'NR'},
      {'code': 'BCT', 'name': 'Mumbai Central', 'latitude': 18.9690, 'longitude': 72.8197, 'state': 'Maharashtra', 'zone': 'WR'},
      {'code': 'CSMT', 'name': 'Chhatrapati Shivaji Maharaj Terminus', 'latitude': 18.9398, 'longitude': 72.8355, 'state': 'Maharashtra', 'zone': 'CR'},
      {'code': 'HWH', 'name': 'Howrah Junction', 'latitude': 22.5839, 'longitude': 88.3428, 'state': 'West Bengal', 'zone': 'ER'},
      {'code': 'MAS', 'name': 'Chennai Central', 'latitude': 13.0827, 'longitude': 80.2707, 'state': 'Tamil Nadu', 'zone': 'SR'},
      {'code': 'SBC', 'name': 'KSR Bengaluru', 'latitude': 12.9784, 'longitude': 77.5710, 'state': 'Karnataka', 'zone': 'SWR'},
      {'code': 'HYB', 'name': 'Hyderabad Deccan', 'latitude': 17.3616, 'longitude': 78.4747, 'state': 'Telangana', 'zone': 'SCR'},
      {'code': 'PUNE', 'name': 'Pune Junction', 'latitude': 18.5285, 'longitude': 73.8743, 'state': 'Maharashtra', 'zone': 'CR'},
      {'code': 'ADI', 'name': 'Ahmedabad Junction', 'latitude': 23.0258, 'longitude': 72.6003, 'state': 'Gujarat', 'zone': 'WR'},
      {'code': 'JP', 'name': 'Jaipur Junction', 'latitude': 26.9196, 'longitude': 75.7878, 'state': 'Rajasthan', 'zone': 'NWR'},
      {'code': 'LKO', 'name': 'Lucknow Charbagh', 'latitude': 26.8322, 'longitude': 80.9167, 'state': 'Uttar Pradesh', 'zone': 'NR'},
      {'code': 'PNBE', 'name': 'Patna Junction', 'latitude': 25.6053, 'longitude': 85.1347, 'state': 'Bihar', 'zone': 'ECR'},
      {'code': 'BPL', 'name': 'Bhopal Junction', 'latitude': 23.2687, 'longitude': 77.4119, 'state': 'Madhya Pradesh', 'zone': 'WCR'},
      {'code': 'NGP', 'name': 'Nagpur Junction', 'latitude': 21.1503, 'longitude': 79.0903, 'state': 'Maharashtra', 'zone': 'CR'},
      {'code': 'SC', 'name': 'Secunderabad Junction', 'latitude': 17.4344, 'longitude': 78.5013, 'state': 'Telangana', 'zone': 'SCR'},
      {'code': 'BZA', 'name': 'Vijayawada Junction', 'latitude': 16.5175, 'longitude': 80.6186, 'state': 'Andhra Pradesh', 'zone': 'SCR'},
      {'code': 'TVC', 'name': 'Thiruvananthapuram Central', 'latitude': 8.4894, 'longitude': 76.9516, 'state': 'Kerala', 'zone': 'SR'},
      {'code': 'ERS', 'name': 'Ernakulam Junction', 'latitude': 9.9681, 'longitude': 76.2880, 'state': 'Kerala', 'zone': 'SR'},
      {'code': 'GHY', 'name': 'Guwahati', 'latitude': 26.1445, 'longitude': 91.7362, 'state': 'Assam', 'zone': 'NFR'},
      {'code': 'JAT', 'name': 'Jammu Tawi', 'latitude': 32.7304, 'longitude': 74.8671, 'state': 'Jammu & Kashmir', 'zone': 'NR'},
      {'code': 'ASR', 'name': 'Amritsar Junction', 'latitude': 31.6340, 'longitude': 74.8723, 'state': 'Punjab', 'zone': 'NR'},
      {'code': 'LTT', 'name': 'Lokmanya Tilak Terminus', 'latitude': 19.0680, 'longitude': 72.8892, 'state': 'Maharashtra', 'zone': 'CR'},
      {'code': 'NZM', 'name': 'Hazrat Nizamuddin', 'latitude': 28.5893, 'longitude': 77.2507, 'state': 'Delhi', 'zone': 'NR'},
      {'code': 'DLI', 'name': 'Old Delhi Junction', 'latitude': 28.6615, 'longitude': 77.2295, 'state': 'Delhi', 'zone': 'NR'},
    ];

    final batch = db.batch();
    for (var i = 0; i < stations.length; i++) {
      batch.insert('stations', {'id': i + 1, ...stations[i]});
    }
    await batch.commit(noResult: true);
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
