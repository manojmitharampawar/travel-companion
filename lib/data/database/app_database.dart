import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:travel_companion/data/database/local_train_seed_data.dart';
import 'package:travel_companion/data/database/metro_schedule_seed_data.dart';
import 'package:travel_companion/data/database/train_seed_data.dart';

class AppDatabase {
  static Database? _database;
  static const int _version = 8;

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

    await db.execute('''
      CREATE TABLE metro_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city TEXT NOT NULL,
        line_name TEXT NOT NULL,
        line_code TEXT UNIQUE,
        line_color TEXT,
        start_station_code TEXT,
        end_station_code TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE metro_stations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        line_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        station_index INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        FOREIGN KEY (line_id) REFERENCES metro_lines(id),
        FOREIGN KEY (code) REFERENCES stations(code)
      )
    ''');

    await db.execute('''
      CREATE TABLE local_train_lines (
        id INTEGER PRIMARY KEY,
        city TEXT NOT NULL,
        line_name TEXT NOT NULL,
        line_code TEXT UNIQUE NOT NULL,
        color TEXT,
        start_station TEXT,
        end_station TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE local_train_stations (
        id INTEGER PRIMARY KEY,
        line_id INTEGER NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        station_index INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        platform_count INTEGER DEFAULT 2,
        FOREIGN KEY (line_id) REFERENCES local_train_lines(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE local_train_schedules (
        id INTEGER PRIMARY KEY,
        line_id INTEGER NOT NULL,
        direction TEXT NOT NULL,
        train_type TEXT NOT NULL,
        departure_hour INTEGER NOT NULL,
        departure_minute INTEGER NOT NULL,
        skip_station_indices TEXT,
        FOREIGN KEY (line_id) REFERENCES local_train_lines(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE metro_schedules (
        id INTEGER PRIMARY KEY,
        line_id INTEGER NOT NULL,
        direction TEXT NOT NULL,
        departure_hour INTEGER NOT NULL,
        departure_minute INTEGER NOT NULL,
        FOREIGN KEY (line_id) REFERENCES metro_lines(id)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_stations_code ON stations(code)');
    await db.execute('CREATE INDEX idx_stations_name ON stations(name)');
    await db.execute(
      'CREATE INDEX idx_train_routes_number ON train_routes(train_number)',
    );
    await db.execute('CREATE INDEX idx_journeys_status ON journeys(status)');
    await db.execute(
      'CREATE INDEX idx_journeys_date ON journeys(journey_date)',
    );
    await db.execute(
      'CREATE INDEX idx_journeys_transport ON journeys(transport_type)',
    );
    await db.execute(
      'CREATE INDEX idx_custom_locations_name ON custom_locations(name)',
    );
    await db.execute('CREATE INDEX idx_metro_lines_city ON metro_lines(city)');
    await db.execute(
      'CREATE INDEX idx_metro_stations_line ON metro_stations(line_id)',
    );
    await db.execute(
      'CREATE INDEX idx_metro_stations_code ON metro_stations(code)',
    );
    await db.execute(
      'CREATE INDEX idx_lt_lines_city ON local_train_lines(city)',
    );
    await db.execute(
      'CREATE INDEX idx_lt_stations_line ON local_train_stations(line_id)',
    );
    await db.execute(
      'CREATE INDEX idx_lt_schedules_line ON local_train_schedules(line_id)',
    );
    await db.execute(
      'CREATE INDEX idx_metro_schedules_line ON metro_schedules(line_id)',
    );

    // Seed data
    await _seedStations(db);
    await _seedTrainRoutes(db);
    await _seedTrainRoutesFromCsv(db);
    await _seedMetroData(db);
    await MetroScheduleSeedData.seed(db);
    await LocalTrainSeedData.seed(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add new columns to journeys table
      await db.execute(
        "ALTER TABLE journeys ADD COLUMN transport_type TEXT DEFAULT 'train'",
      );
      await db.execute('ALTER TABLE journeys ADD COLUMN vehicle_number TEXT');
      await db.execute('ALTER TABLE journeys ADD COLUMN vehicle_name TEXT');
      await db.execute('ALTER TABLE journeys ADD COLUMN origin_latitude REAL');
      await db.execute('ALTER TABLE journeys ADD COLUMN origin_longitude REAL');
      await db.execute(
        'ALTER TABLE journeys ADD COLUMN destination_latitude REAL',
      );
      await db.execute(
        'ALTER TABLE journeys ADD COLUMN destination_longitude REAL',
      );
      await db.execute('ALTER TABLE journeys ADD COLUMN origin_name TEXT');
      await db.execute('ALTER TABLE journeys ADD COLUMN destination_name TEXT');
      await db.execute(
        'ALTER TABLE journeys ADD COLUMN is_quick_trip INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE journeys ADD COLUMN repeat_days INTEGER');
      await db.execute('ALTER TABLE journeys ADD COLUMN scheduled_time TEXT');

      // Migrate existing train data
      await db.execute(
        'UPDATE journeys SET vehicle_number = train_number, vehicle_name = train_name',
      );

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
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_journeys_transport ON journeys(transport_type)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_custom_locations_name ON custom_locations(name)',
      );
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
    if (oldVersion < 5) {
      // Create metro tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS metro_lines (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          city TEXT NOT NULL,
          line_name TEXT NOT NULL,
          line_code TEXT UNIQUE,
          line_color TEXT,
          start_station_code TEXT,
          end_station_code TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS metro_stations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE NOT NULL,
          line_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          station_index INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          FOREIGN KEY (line_id) REFERENCES metro_lines(id),
          FOREIGN KEY (code) REFERENCES stations(code)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_metro_lines_city ON metro_lines(city)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_metro_stations_line ON metro_stations(line_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_metro_stations_code ON metro_stations(code)',
      );

      // Seed metro data (lines only — no stations in v5)
      await _seedMetroData(db);
    }
    if (oldVersion < 6) {
      // v6: Re-seed metro data to include stations (v5 only had lines)
      await db.delete('metro_stations');
      await db.delete('metro_lines');
      await _seedMetroData(db);

      // v6: Ensure railway stations are seeded (may have been missed in earlier versions)
      final stationCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM stations'),
      );
      if (stationCount == null || stationCount < 100) {
        await _seedStations(db);
      }
    }
    if (oldVersion < 7) {
      // v7: Local train schedule tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_train_lines (
          id INTEGER PRIMARY KEY,
          city TEXT NOT NULL,
          line_name TEXT NOT NULL,
          line_code TEXT UNIQUE NOT NULL,
          color TEXT,
          start_station TEXT,
          end_station TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_train_stations (
          id INTEGER PRIMARY KEY,
          line_id INTEGER NOT NULL,
          code TEXT NOT NULL,
          name TEXT NOT NULL,
          station_index INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          platform_count INTEGER DEFAULT 2,
          FOREIGN KEY (line_id) REFERENCES local_train_lines(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_train_schedules (
          id INTEGER PRIMARY KEY,
          line_id INTEGER NOT NULL,
          direction TEXT NOT NULL,
          train_type TEXT NOT NULL,
          departure_hour INTEGER NOT NULL,
          departure_minute INTEGER NOT NULL,
          skip_station_indices TEXT,
          FOREIGN KEY (line_id) REFERENCES local_train_lines(id)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lt_lines_city ON local_train_lines(city)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lt_stations_line ON local_train_stations(line_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lt_schedules_line ON local_train_schedules(line_id)',
      );
      await LocalTrainSeedData.seed(db);
    }
    if (oldVersion < 8) {
      // v8: Metro schedule table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS metro_schedules (
          id INTEGER PRIMARY KEY,
          line_id INTEGER NOT NULL,
          direction TEXT NOT NULL,
          departure_hour INTEGER NOT NULL,
          departure_minute INTEGER NOT NULL,
          FOREIGN KEY (line_id) REFERENCES metro_lines(id)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_metro_schedules_line ON metro_schedules(line_id)',
      );
      await MetroScheduleSeedData.seed(db);
    }
  }

  /// Seeds metro lines AND stations for major Indian cities.
  static Future<void> _seedMetroData(Database db) async {
    try {
      // ── Helper to insert a line + its stations in one go ──
      Future<void> seedLine({
        required String city,
        required String lineName,
        required String lineCode,
        required String color,
        required List<Map<String, dynamic>> stations,
      }) async {
        final lineResult = await db.insert('metro_lines', {
          'city': city,
          'line_name': lineName,
          'line_code': lineCode,
          'line_color': color,
          'start_station_code': stations.first['code'],
          'end_station_code': stations.last['code'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // If insert was ignored (already exists), look up the id
        int lineId;
        if (lineResult == 0) {
          final rows = await db.query(
            'metro_lines',
            where: 'line_code = ?',
            whereArgs: [lineCode],
            limit: 1,
          );
          if (rows.isEmpty) return;
          lineId = rows.first['id'] as int;
        } else {
          lineId = lineResult;
        }

        final batch = db.batch();
        for (var i = 0; i < stations.length; i++) {
          final s = stations[i];
          batch.insert('metro_stations', {
            'code': s['code'],
            'line_id': lineId,
            'name': s['name'],
            'station_index': i,
            'latitude': s['lat'],
            'longitude': s['lng'],
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
      }

      // ═══════════════════════════════════════════
      // DELHI METRO
      // ═══════════════════════════════════════════

      // Red Line (Line 1)
      await seedLine(
        city: 'Delhi',
        lineName: 'Red Line',
        lineCode: 'DL-RED',
        color: '#E31C23',
        stations: [
          {
            'code': 'DL_RITHALA',
            'name': 'Rithala',
            'lat': 28.7209,
            'lng': 77.1074,
          },
          {
            'code': 'DL_ROHINI_WEST',
            'name': 'Rohini West',
            'lat': 28.7148,
            'lng': 77.1113,
          },
          {
            'code': 'DL_ROHINI_EAST',
            'name': 'Rohini East',
            'lat': 28.7085,
            'lng': 77.1199,
          },
          {
            'code': 'DL_PITAMPURA',
            'name': 'Pitampura',
            'lat': 28.7016,
            'lng': 77.1310,
          },
          {
            'code': 'DL_KOHAT_ENCLAVE',
            'name': 'Kohat Enclave',
            'lat': 28.6978,
            'lng': 77.1387,
          },
          {
            'code': 'DL_NETAJI_SUBHASH',
            'name': 'Netaji Subhash Place',
            'lat': 28.6935,
            'lng': 77.1531,
          },
          {
            'code': 'DL_KESHAV_PURAM',
            'name': 'Keshav Puram',
            'lat': 28.6891,
            'lng': 77.1628,
          },
          {
            'code': 'DL_KANHAIYA_NAGAR',
            'name': 'Kanhaiya Nagar',
            'lat': 28.6848,
            'lng': 77.1704,
          },
          {
            'code': 'DL_INDERLOK',
            'name': 'Inderlok',
            'lat': 28.6733,
            'lng': 77.1716,
          },
          {
            'code': 'DL_SHASTRI_NAGAR',
            'name': 'Shastri Nagar',
            'lat': 28.6720,
            'lng': 77.1803,
          },
          {
            'code': 'DL_PRATAP_NAGAR',
            'name': 'Pratap Nagar',
            'lat': 28.6693,
            'lng': 77.1893,
          },
          {
            'code': 'DL_PULBANGASH',
            'name': 'Pulbangash',
            'lat': 28.6663,
            'lng': 77.1983,
          },
          {
            'code': 'DL_TIS_HAZARI',
            'name': 'Tis Hazari',
            'lat': 28.6638,
            'lng': 77.2087,
          },
          {
            'code': 'DL_KASHMERE_GATE',
            'name': 'Kashmere Gate',
            'lat': 28.6602,
            'lng': 77.2282,
          },
          {
            'code': 'DL_SHASTRI_PARK',
            'name': 'Shastri Park',
            'lat': 28.6686,
            'lng': 77.2461,
          },
          {
            'code': 'DL_SEELAMPUR',
            'name': 'Seelampur',
            'lat': 28.6668,
            'lng': 77.2596,
          },
          {
            'code': 'DL_WELCOME',
            'name': 'Welcome',
            'lat': 28.6685,
            'lng': 77.2680,
          },
          {
            'code': 'DL_SHAHDARA',
            'name': 'Shahdara',
            'lat': 28.6732,
            'lng': 77.2887,
          },
          {
            'code': 'DL_DILSHAD_GARDEN',
            'name': 'Dilshad Garden',
            'lat': 28.6789,
            'lng': 77.3180,
          },
        ],
      );

      // Yellow Line (Line 2)
      await seedLine(
        city: 'Delhi',
        lineName: 'Yellow Line',
        lineCode: 'DL-YELLOW',
        color: '#FDB913',
        stations: [
          {
            'code': 'DL_SAMAYPUR_BADLI',
            'name': 'Samaypur Badli',
            'lat': 28.7449,
            'lng': 77.1361,
          },
          {
            'code': 'DL_ROHINI_SECTOR18',
            'name': 'Rohini Sector 18-19',
            'lat': 28.7389,
            'lng': 77.1388,
          },
          {
            'code': 'DL_HAIDERPUR_BADLI',
            'name': 'Haiderpur Badli Mor',
            'lat': 28.7271,
            'lng': 77.1494,
          },
          {
            'code': 'DL_JAHANGIRPURI',
            'name': 'Jahangirpuri',
            'lat': 28.7255,
            'lng': 77.1624,
          },
          {
            'code': 'DL_ADARSH_NAGAR',
            'name': 'Adarsh Nagar',
            'lat': 28.7163,
            'lng': 77.1709,
          },
          {
            'code': 'DL_AZADPUR',
            'name': 'Azadpur',
            'lat': 28.7074,
            'lng': 77.1790,
          },
          {
            'code': 'DL_MODEL_TOWN',
            'name': 'Model Town',
            'lat': 28.6994,
            'lng': 77.1890,
          },
          {
            'code': 'DL_GTB_NAGAR',
            'name': 'GTB Nagar',
            'lat': 28.6911,
            'lng': 77.1990,
          },
          {
            'code': 'DL_VISHWAVIDYALAYA',
            'name': 'Vishwavidyalaya',
            'lat': 28.6816,
            'lng': 77.2098,
          },
          {
            'code': 'DL_VIDHAN_SABHA',
            'name': 'Vidhan Sabha',
            'lat': 28.6716,
            'lng': 77.2190,
          },
          {
            'code': 'DL_CIVIL_LINES',
            'name': 'Civil Lines',
            'lat': 28.6625,
            'lng': 77.2235,
          },
          {
            'code': 'DL_KASHMERE_GATE_Y',
            'name': 'Kashmere Gate',
            'lat': 28.6602,
            'lng': 77.2282,
          },
          {
            'code': 'DL_CHANDNI_CHOWK',
            'name': 'Chandni Chowk',
            'lat': 28.6507,
            'lng': 77.2302,
          },
          {
            'code': 'DL_CHAWRI_BAZAR',
            'name': 'Chawri Bazar',
            'lat': 28.6452,
            'lng': 77.2261,
          },
          {
            'code': 'DL_NEW_DELHI',
            'name': 'New Delhi',
            'lat': 28.6424,
            'lng': 77.2194,
          },
          {
            'code': 'DL_RAJIV_CHOWK',
            'name': 'Rajiv Chowk',
            'lat': 28.6328,
            'lng': 77.2195,
          },
          {
            'code': 'DL_PATEL_CHOWK',
            'name': 'Patel Chowk',
            'lat': 28.6225,
            'lng': 77.2147,
          },
          {
            'code': 'DL_CENTRAL_SECTT',
            'name': 'Central Secretariat',
            'lat': 28.6146,
            'lng': 77.2115,
          },
          {
            'code': 'DL_UDYOG_BHAWAN',
            'name': 'Udyog Bhawan',
            'lat': 28.6072,
            'lng': 77.2087,
          },
          {
            'code': 'DL_LOK_KALYAN_MARG',
            'name': 'Lok Kalyan Marg',
            'lat': 28.5971,
            'lng': 77.2049,
          },
          {
            'code': 'DL_JORBAGH',
            'name': 'Jor Bagh',
            'lat': 28.5897,
            'lng': 77.2063,
          },
          {'code': 'DL_INA', 'name': 'INA', 'lat': 28.5791, 'lng': 77.2093},
          {'code': 'DL_AIIMS', 'name': 'AIIMS', 'lat': 28.5688, 'lng': 77.2076},
          {
            'code': 'DL_GREEN_PARK',
            'name': 'Green Park',
            'lat': 28.5593,
            'lng': 77.2067,
          },
          {
            'code': 'DL_HAUZ_KHAS',
            'name': 'Hauz Khas',
            'lat': 28.5430,
            'lng': 77.2066,
          },
          {
            'code': 'DL_MALVIYA_NAGAR',
            'name': 'Malviya Nagar',
            'lat': 28.5280,
            'lng': 77.2097,
          },
          {'code': 'DL_SAKET', 'name': 'Saket', 'lat': 28.5210, 'lng': 77.2148},
          {
            'code': 'DL_QUTAB_MINAR',
            'name': 'Qutab Minar',
            'lat': 28.5131,
            'lng': 77.1853,
          },
          {
            'code': 'DL_CHHATTARPUR',
            'name': 'Chhattarpur',
            'lat': 28.5070,
            'lng': 77.1752,
          },
          {
            'code': 'DL_SULTANPUR',
            'name': 'Sultanpur',
            'lat': 28.4973,
            'lng': 77.1578,
          },
          {
            'code': 'DL_GHITORNI',
            'name': 'Ghitorni',
            'lat': 28.4932,
            'lng': 77.1483,
          },
          {
            'code': 'DL_ARJAN_GARH',
            'name': 'Arjan Garh',
            'lat': 28.4830,
            'lng': 77.1297,
          },
          {
            'code': 'DL_GURU_DRONACHARYA',
            'name': 'Guru Dronacharya',
            'lat': 28.4822,
            'lng': 77.1007,
          },
          {
            'code': 'DL_SIKANDERPUR',
            'name': 'Sikanderpur',
            'lat': 28.4805,
            'lng': 77.0903,
          },
          {
            'code': 'DL_MG_ROAD',
            'name': 'MG Road',
            'lat': 28.4792,
            'lng': 77.0749,
          },
          {
            'code': 'DL_IFFCO_CHOWK',
            'name': 'IFFCO Chowk',
            'lat': 28.4726,
            'lng': 77.0722,
          },
          {
            'code': 'DL_HUDA_CITY_CENTRE',
            'name': 'HUDA City Centre',
            'lat': 28.4594,
            'lng': 77.0726,
          },
        ],
      );

      // Blue Line (Line 3)
      await seedLine(
        city: 'Delhi',
        lineName: 'Blue Line',
        lineCode: 'DL-BLUE',
        color: '#002DA5',
        stations: [
          {
            'code': 'DL_DWARKA_SEC21',
            'name': 'Dwarka Sector 21',
            'lat': 28.5523,
            'lng': 77.0583,
          },
          {
            'code': 'DL_DWARKA_SEC8',
            'name': 'Dwarka Sector 8',
            'lat': 28.5631,
            'lng': 77.0658,
          },
          {
            'code': 'DL_DWARKA_SEC14',
            'name': 'Dwarka Sector 14',
            'lat': 28.5699,
            'lng': 77.0645,
          },
          {
            'code': 'DL_DWARKA_SEC11',
            'name': 'Dwarka Sector 11',
            'lat': 28.5763,
            'lng': 77.0619,
          },
          {
            'code': 'DL_DWARKA_SEC10',
            'name': 'Dwarka Sector 10',
            'lat': 28.5818,
            'lng': 77.0587,
          },
          {
            'code': 'DL_DWARKA_SEC9',
            'name': 'Dwarka Sector 9',
            'lat': 28.5856,
            'lng': 77.0639,
          },
          {
            'code': 'DL_DWARKA_MOD',
            'name': 'Dwarka Mor',
            'lat': 28.6098,
            'lng': 77.0524,
          },
          {
            'code': 'DL_NAWADA',
            'name': 'Nawada',
            'lat': 28.6192,
            'lng': 77.0454,
          },
          {
            'code': 'DL_UTTAM_NAGAR_WEST',
            'name': 'Uttam Nagar West',
            'lat': 28.6231,
            'lng': 77.0395,
          },
          {
            'code': 'DL_UTTAM_NAGAR_EAST',
            'name': 'Uttam Nagar East',
            'lat': 28.6278,
            'lng': 77.0453,
          },
          {
            'code': 'DL_JANAKPURI_WEST',
            'name': 'Janakpuri West',
            'lat': 28.6310,
            'lng': 77.0811,
          },
          {
            'code': 'DL_JANAKPURI_EAST',
            'name': 'Janakpuri East',
            'lat': 28.6340,
            'lng': 77.0897,
          },
          {
            'code': 'DL_TILAK_NAGAR',
            'name': 'Tilak Nagar',
            'lat': 28.6405,
            'lng': 77.0973,
          },
          {
            'code': 'DL_SUBHASH_NAGAR',
            'name': 'Subhash Nagar',
            'lat': 28.6448,
            'lng': 77.1056,
          },
          {
            'code': 'DL_TAGORE_GARDEN',
            'name': 'Tagore Garden',
            'lat': 28.6475,
            'lng': 77.1138,
          },
          {
            'code': 'DL_RAJOURI_GARDEN',
            'name': 'Rajouri Garden',
            'lat': 28.6498,
            'lng': 77.1227,
          },
          {
            'code': 'DL_RAMESH_NAGAR',
            'name': 'Ramesh Nagar',
            'lat': 28.6515,
            'lng': 77.1385,
          },
          {
            'code': 'DL_MOTI_NAGAR',
            'name': 'Moti Nagar',
            'lat': 28.6546,
            'lng': 77.1456,
          },
          {
            'code': 'DL_KIRTI_NAGAR',
            'name': 'Kirti Nagar',
            'lat': 28.6568,
            'lng': 77.1544,
          },
          {
            'code': 'DL_RAJENDRA_PLACE',
            'name': 'Rajendra Place',
            'lat': 28.6440,
            'lng': 77.1729,
          },
          {
            'code': 'DL_KAROL_BAGH',
            'name': 'Karol Bagh',
            'lat': 28.6456,
            'lng': 77.1903,
          },
          {
            'code': 'DL_JHANDEWALAN',
            'name': 'Jhandewalan',
            'lat': 28.6436,
            'lng': 77.2005,
          },
          {
            'code': 'DL_RK_ASHRAM',
            'name': 'R.K. Ashram Marg',
            'lat': 28.6406,
            'lng': 77.2092,
          },
          {
            'code': 'DL_RAJIV_CHOWK_BL',
            'name': 'Rajiv Chowk',
            'lat': 28.6328,
            'lng': 77.2195,
          },
          {
            'code': 'DL_BARAKHAMBA',
            'name': 'Barakhamba Road',
            'lat': 28.6319,
            'lng': 77.2293,
          },
          {
            'code': 'DL_MANDI_HOUSE',
            'name': 'Mandi House',
            'lat': 28.6261,
            'lng': 77.2352,
          },
          {
            'code': 'DL_PRAGATI_MAIDAN',
            'name': 'Pragati Maidan',
            'lat': 28.6210,
            'lng': 77.2471,
          },
          {
            'code': 'DL_INDRAPRASTHA',
            'name': 'Indraprastha',
            'lat': 28.6157,
            'lng': 77.2558,
          },
          {
            'code': 'DL_YAMUNA_BANK',
            'name': 'Yamuna Bank',
            'lat': 28.6143,
            'lng': 77.2701,
          },
          {
            'code': 'DL_AKSHARDHAM',
            'name': 'Akshardham',
            'lat': 28.6124,
            'lng': 77.2835,
          },
          {
            'code': 'DL_MAYUR_VIHAR1',
            'name': 'Mayur Vihar-I',
            'lat': 28.6071,
            'lng': 77.2932,
          },
          {
            'code': 'DL_MAYUR_VIHAR_EXT',
            'name': 'Mayur Vihar Extension',
            'lat': 28.6035,
            'lng': 77.3036,
          },
          {
            'code': 'DL_NEW_ASHOK_NAGAR',
            'name': 'New Ashok Nagar',
            'lat': 28.5937,
            'lng': 77.3107,
          },
          {
            'code': 'DL_NOIDA_SEC15',
            'name': 'Noida Sector 15',
            'lat': 28.5856,
            'lng': 77.3161,
          },
          {
            'code': 'DL_NOIDA_SEC16',
            'name': 'Noida Sector 16',
            'lat': 28.5794,
            'lng': 77.3170,
          },
          {
            'code': 'DL_NOIDA_SEC18',
            'name': 'Noida Sector 18',
            'lat': 28.5707,
            'lng': 77.3260,
          },
          {
            'code': 'DL_BOTANICAL_GARDEN',
            'name': 'Botanical Garden',
            'lat': 28.5647,
            'lng': 77.3342,
          },
          {
            'code': 'DL_GOLF_COURSE',
            'name': 'Golf Course',
            'lat': 28.5603,
            'lng': 77.3435,
          },
          {
            'code': 'DL_NOIDA_CITY_CENTRE',
            'name': 'Noida City Centre',
            'lat': 28.5734,
            'lng': 77.3564,
          },
          {
            'code': 'DL_NOIDA_SEC34',
            'name': 'Noida Sector 34',
            'lat': 28.5818,
            'lng': 77.3544,
          },
          {
            'code': 'DL_NOIDA_SEC52',
            'name': 'Noida Sector 52',
            'lat': 28.5905,
            'lng': 77.3599,
          },
          {
            'code': 'DL_NOIDA_SEC61',
            'name': 'Noida Sector 61',
            'lat': 28.5977,
            'lng': 77.3631,
          },
          {
            'code': 'DL_NOIDA_SEC62',
            'name': 'Noida Sector 62',
            'lat': 28.6083,
            'lng': 77.3632,
          },
        ],
      );

      // Green Line (Line 5)
      await seedLine(
        city: 'Delhi',
        lineName: 'Green Line',
        lineCode: 'DL-GREEN',
        color: '#06A649',
        stations: [
          {
            'code': 'DL_MUNDKA',
            'name': 'Mundka',
            'lat': 28.6813,
            'lng': 77.0272,
          },
          {
            'code': 'DL_MUNDKA_IND',
            'name': 'Mundka Industrial Area',
            'lat': 28.6769,
            'lng': 77.0370,
          },
          {
            'code': 'DL_GHEVRA',
            'name': 'Ghevra',
            'lat': 28.6718,
            'lng': 77.0469,
          },
          {
            'code': 'DL_TIKRI_KALAN',
            'name': 'Tikri Kalan',
            'lat': 28.6667,
            'lng': 77.0530,
          },
          {
            'code': 'DL_TIKRI_BORDER',
            'name': 'Tikri Border',
            'lat': 28.6623,
            'lng': 77.0588,
          },
          {
            'code': 'DL_PANDIT_SHREE',
            'name': 'Pandit Shree Ram Sharma',
            'lat': 28.6573,
            'lng': 77.0647,
          },
          {
            'code': 'DL_BAHADURGARH_CITY',
            'name': 'Bahadurgarh City',
            'lat': 28.6523,
            'lng': 77.0700,
          },
          {
            'code': 'DL_BRIG_HOSHIAR',
            'name': 'Brigadier Hoshiar Singh',
            'lat': 28.6932,
            'lng': 77.0455,
          },
        ],
      );

      // ═══════════════════════════════════════════
      // MUMBAI METRO
      // ═══════════════════════════════════════════

      // Line 1 (Blue Line — Versova–Ghatkopar)
      await seedLine(
        city: 'Mumbai',
        lineName: 'Line 1',
        lineCode: 'MUM-L1',
        color: '#0C60CA',
        stations: [
          {
            'code': 'MUM_VERSOVA',
            'name': 'Versova',
            'lat': 19.1315,
            'lng': 72.8184,
          },
          {
            'code': 'MUM_DN_NAGAR',
            'name': 'D.N. Nagar',
            'lat': 19.1263,
            'lng': 72.8266,
          },
          {
            'code': 'MUM_AZAD_NAGAR',
            'name': 'Azad Nagar',
            'lat': 19.1194,
            'lng': 72.8349,
          },
          {
            'code': 'MUM_ANDHERI',
            'name': 'Andheri',
            'lat': 19.1189,
            'lng': 72.8463,
          },
          {
            'code': 'MUM_WEH',
            'name': 'Western Express Highway',
            'lat': 19.1106,
            'lng': 72.8572,
          },
          {
            'code': 'MUM_CHAKALA',
            'name': 'Chakala (J.B. Nagar)',
            'lat': 19.1063,
            'lng': 72.8634,
          },
          {
            'code': 'MUM_AIRPORT_RD',
            'name': 'Airport Road',
            'lat': 19.1013,
            'lng': 72.8735,
          },
          {
            'code': 'MUM_MAROL_NAKA',
            'name': 'Marol Naka',
            'lat': 19.0982,
            'lng': 72.8802,
          },
          {
            'code': 'MUM_SAKI_NAKA',
            'name': 'Saki Naka',
            'lat': 19.0894,
            'lng': 72.8870,
          },
          {
            'code': 'MUM_ASALPHA',
            'name': 'Asalpha',
            'lat': 19.0828,
            'lng': 72.8913,
          },
          {
            'code': 'MUM_JAGRUTI_NAGAR',
            'name': 'Jagruti Nagar',
            'lat': 19.0791,
            'lng': 72.8967,
          },
          {
            'code': 'MUM_GHATKOPAR',
            'name': 'Ghatkopar',
            'lat': 19.0860,
            'lng': 72.9080,
          },
        ],
      );

      // Line 2A (Yellow Line — Dahisar East–Andheri West)
      await seedLine(
        city: 'Mumbai',
        lineName: 'Line 2A',
        lineCode: 'MUM-L2A',
        color: '#FF6600',
        stations: [
          {
            'code': 'MUM_DAHISAR_E',
            'name': 'Dahisar East',
            'lat': 19.2513,
            'lng': 72.8646,
          },
          {
            'code': 'MUM_ANAND_NAGAR',
            'name': 'Anand Nagar',
            'lat': 19.2410,
            'lng': 72.8616,
          },
          {
            'code': 'MUM_KANDIVALI_WEST',
            'name': 'Kandivali West',
            'lat': 19.2075,
            'lng': 72.8421,
          },
          {
            'code': 'MUM_BORIVALI_WEST',
            'name': 'Borivali West',
            'lat': 19.2286,
            'lng': 72.8528,
          },
          {
            'code': 'MUM_MALAD_WEST',
            'name': 'Malad West',
            'lat': 19.1868,
            'lng': 72.8353,
          },
          {
            'code': 'MUM_GOREGAON_WEST',
            'name': 'Goregaon West',
            'lat': 19.1659,
            'lng': 72.8320,
          },
          {
            'code': 'MUM_OSHIWARA',
            'name': 'Oshiwara',
            'lat': 19.1520,
            'lng': 72.8307,
          },
          {
            'code': 'MUM_ANDHERI_WEST',
            'name': 'Andheri West',
            'lat': 19.1358,
            'lng': 72.8275,
          },
        ],
      );

      // ═══════════════════════════════════════════
      // BANGALORE METRO (Namma Metro)
      // ═══════════════════════════════════════════

      // Purple Line
      await seedLine(
        city: 'Bangalore',
        lineName: 'Purple Line',
        lineCode: 'BLR-PURPLE',
        color: '#6B2C91',
        stations: [
          {
            'code': 'BLR_CHALLAGHATTA',
            'name': 'Challaghatta',
            'lat': 12.9893,
            'lng': 77.5004,
          },
          {
            'code': 'BLR_KENGERI',
            'name': 'Kengeri',
            'lat': 12.9862,
            'lng': 77.5141,
          },
          {
            'code': 'BLR_KENGERI_BUS',
            'name': 'Kengeri Bus Terminal',
            'lat': 12.9820,
            'lng': 77.5259,
          },
          {
            'code': 'BLR_PATTANAGERE',
            'name': 'Pattanagere',
            'lat': 12.9734,
            'lng': 77.5356,
          },
          {
            'code': 'BLR_JNANA_BHARATHI',
            'name': 'Jnana Bharathi',
            'lat': 12.9635,
            'lng': 77.5452,
          },
          {
            'code': 'BLR_RR_NAGAR',
            'name': 'Rajarajeshwari Nagar',
            'lat': 12.9583,
            'lng': 77.5421,
          },
          {
            'code': 'BLR_NAYANDAHALLI',
            'name': 'Nayandahalli',
            'lat': 12.9590,
            'lng': 77.5516,
          },
          {
            'code': 'BLR_MYSURU_RD',
            'name': 'Mysuru Road',
            'lat': 12.9587,
            'lng': 77.5591,
          },
          {
            'code': 'BLR_DEEPANJALI',
            'name': 'Deepanjali Nagar',
            'lat': 12.9601,
            'lng': 77.5684,
          },
          {
            'code': 'BLR_ATTIGUPPE',
            'name': 'Attiguppe',
            'lat': 12.9592,
            'lng': 77.5721,
          },
          {
            'code': 'BLR_VIJAYANAGAR',
            'name': 'Vijayanagar',
            'lat': 12.9623,
            'lng': 77.5753,
          },
          {
            'code': 'BLR_HOSAHALLI',
            'name': 'Hosahalli',
            'lat': 12.9652,
            'lng': 77.5790,
          },
          {
            'code': 'BLR_MAGADI_RD',
            'name': 'Magadi Road',
            'lat': 12.9676,
            'lng': 77.5743,
          },
          {
            'code': 'BLR_CITY_RLY',
            'name': 'KSR Bengaluru City Railway',
            'lat': 12.9774,
            'lng': 77.5714,
          },
          {
            'code': 'BLR_MAJESTIC',
            'name': 'Majestic (Interchange)',
            'lat': 12.9766,
            'lng': 77.5718,
          },
          {
            'code': 'BLR_SIR_MV',
            'name': 'Sir M. Visvesvaraya',
            'lat': 12.9739,
            'lng': 77.5774,
          },
          {
            'code': 'BLR_CUBBON_PARK',
            'name': 'Cubbon Park',
            'lat': 12.9773,
            'lng': 77.5936,
          },
          {
            'code': 'BLR_MG_ROAD',
            'name': 'MG Road',
            'lat': 12.9755,
            'lng': 77.6059,
          },
          {
            'code': 'BLR_TRINITY',
            'name': 'Trinity',
            'lat': 12.9738,
            'lng': 77.6113,
          },
          {
            'code': 'BLR_HALASURU',
            'name': 'Halasuru',
            'lat': 12.9774,
            'lng': 77.6179,
          },
          {
            'code': 'BLR_INDIRANAGAR',
            'name': 'Indiranagar',
            'lat': 12.9785,
            'lng': 77.6397,
          },
          {
            'code': 'BLR_SWAMI_VIVEKA',
            'name': 'Swami Vivekananda Road',
            'lat': 12.9872,
            'lng': 77.6516,
          },
          {
            'code': 'BLR_BAIYAPPANAHALLI',
            'name': 'Baiyappanahalli',
            'lat': 12.9908,
            'lng': 77.6571,
          },
        ],
      );

      // Green Line
      await seedLine(
        city: 'Bangalore',
        lineName: 'Green Line',
        lineCode: 'BLR-GREEN',
        color: '#06A649',
        stations: [
          {
            'code': 'BLR_NAGASANDRA',
            'name': 'Nagasandra',
            'lat': 13.0434,
            'lng': 77.5156,
          },
          {
            'code': 'BLR_DASARAHALLI',
            'name': 'Dasarahalli',
            'lat': 13.0377,
            'lng': 77.5196,
          },
          {
            'code': 'BLR_JALAHALLI',
            'name': 'Jalahalli',
            'lat': 13.0306,
            'lng': 77.5337,
          },
          {
            'code': 'BLR_PEENYA_IND',
            'name': 'Peenya Industry',
            'lat': 13.0275,
            'lng': 77.5184,
          },
          {
            'code': 'BLR_PEENYA',
            'name': 'Peenya',
            'lat': 13.0194,
            'lng': 77.5263,
          },
          {
            'code': 'BLR_GORAGUNTEPALYA',
            'name': 'Goraguntepalya',
            'lat': 13.0137,
            'lng': 77.5337,
          },
          {
            'code': 'BLR_YESHWANTHPUR',
            'name': 'Yeshwanthpur',
            'lat': 13.0067,
            'lng': 77.5428,
          },
          {
            'code': 'BLR_SANDAL_SOAP',
            'name': 'Sandal Soap Factory',
            'lat': 12.9990,
            'lng': 77.5508,
          },
          {
            'code': 'BLR_MAHALAKSHMI',
            'name': 'Mahalakshmi',
            'lat': 12.9918,
            'lng': 77.5565,
          },
          {
            'code': 'BLR_RAJAJINAGAR',
            'name': 'Rajajinagar',
            'lat': 12.9888,
            'lng': 77.5630,
          },
          {
            'code': 'BLR_MAHAKAVI_KUVEMPU',
            'name': 'Mahakavi Kuvempu Road',
            'lat': 12.9845,
            'lng': 77.5669,
          },
          {
            'code': 'BLR_SRIRAMPURA',
            'name': 'Srirampura',
            'lat': 12.9809,
            'lng': 77.5674,
          },
          {
            'code': 'BLR_MAJESTIC_G',
            'name': 'Majestic (Interchange)',
            'lat': 12.9766,
            'lng': 77.5718,
          },
          {
            'code': 'BLR_CHICKPETE',
            'name': 'Chickpete',
            'lat': 12.9695,
            'lng': 77.5755,
          },
          {
            'code': 'BLR_KR_MARKET',
            'name': 'K.R. Market',
            'lat': 12.9618,
            'lng': 77.5762,
          },
          {
            'code': 'BLR_NATIONAL_COLLEGE',
            'name': 'National College',
            'lat': 12.9533,
            'lng': 77.5743,
          },
          {
            'code': 'BLR_LALBAGH',
            'name': 'Lalbagh',
            'lat': 12.9474,
            'lng': 77.5830,
          },
          {
            'code': 'BLR_SOUTH_END',
            'name': 'South End Circle',
            'lat': 12.9415,
            'lng': 77.5905,
          },
          {
            'code': 'BLR_JAYANAGAR',
            'name': 'Jayanagar',
            'lat': 12.9332,
            'lng': 77.5821,
          },
          {
            'code': 'BLR_RV_ROAD',
            'name': 'RV Road',
            'lat': 12.9337,
            'lng': 77.5748,
          },
          {
            'code': 'BLR_BANASHANKARI',
            'name': 'Banashankari',
            'lat': 12.9251,
            'lng': 77.5729,
          },
          {
            'code': 'BLR_JP_NAGAR',
            'name': 'JP Nagar',
            'lat': 12.9077,
            'lng': 77.5840,
          },
          {
            'code': 'BLR_YELACHENAHALLI',
            'name': 'Yelachenahalli',
            'lat': 12.8951,
            'lng': 77.5869,
          },
          {
            'code': 'BLR_KONANAKUNTE',
            'name': 'Konanakunte Cross',
            'lat': 12.8841,
            'lng': 77.5819,
          },
          {
            'code': 'BLR_SILK_INSTITUTE',
            'name': 'Silk Institute',
            'lat': 12.8682,
            'lng': 77.5782,
          },
        ],
      );

      // ═══════════════════════════════════════════
      // CHENNAI METRO
      // ═══════════════════════════════════════════

      // Blue Line (Line 1)
      await seedLine(
        city: 'Chennai',
        lineName: 'Blue Line',
        lineCode: 'CHN-L1',
        color: '#006BB6',
        stations: [
          {
            'code': 'CHN_WIMCO_NAGAR',
            'name': 'Wimco Nagar',
            'lat': 13.1560,
            'lng': 80.3063,
          },
          {
            'code': 'CHN_TIRUVOTTIYUR',
            'name': 'Tiruvottiyur',
            'lat': 13.1558,
            'lng': 80.2983,
          },
          {
            'code': 'CHN_THERADI',
            'name': 'Tiruvottiyur Theradi',
            'lat': 13.1520,
            'lng': 80.2910,
          },
          {
            'code': 'CHN_KALADIPET',
            'name': 'Kaladipet',
            'lat': 13.1439,
            'lng': 80.2880,
          },
          {
            'code': 'CHN_TOLLGATE',
            'name': 'Tollgate',
            'lat': 13.1300,
            'lng': 80.2782,
          },
          {
            'code': 'CHN_NEW_WASHERMENPET',
            'name': 'New Washermenpet',
            'lat': 13.1166,
            'lng': 80.2771,
          },
          {
            'code': 'CHN_TONDIARPET',
            'name': 'Tondiarpet',
            'lat': 13.1117,
            'lng': 80.2753,
          },
          {
            'code': 'CHN_WASHERMENPET',
            'name': 'Washermenpet',
            'lat': 13.1072,
            'lng': 80.2741,
          },
          {
            'code': 'CHN_MANNADI',
            'name': 'Mannadi',
            'lat': 13.0963,
            'lng': 80.2864,
          },
          {
            'code': 'CHN_HIGH_COURT',
            'name': 'High Court',
            'lat': 13.0872,
            'lng': 80.2867,
          },
          {
            'code': 'CHN_GOVT_ESTATE',
            'name': 'Government Estate',
            'lat': 13.0724,
            'lng': 80.2754,
          },
          {'code': 'CHN_LIC', 'name': 'LIC', 'lat': 13.0685, 'lng': 80.2703},
          {
            'code': 'CHN_THOUSAND_LIGHTS',
            'name': 'Thousand Lights',
            'lat': 13.0583,
            'lng': 80.2587,
          },
          {
            'code': 'CHN_AG_DMS',
            'name': 'AG-DMS',
            'lat': 13.0531,
            'lng': 80.2533,
          },
          {
            'code': 'CHN_TEYNAMPET',
            'name': 'Teynampet',
            'lat': 13.0470,
            'lng': 80.2504,
          },
          {
            'code': 'CHN_NANDANAM',
            'name': 'Nandanam',
            'lat': 13.0382,
            'lng': 80.2453,
          },
          {
            'code': 'CHN_SAIDAPET',
            'name': 'Saidapet',
            'lat': 13.0240,
            'lng': 80.2238,
          },
          {
            'code': 'CHN_LITTLE_MOUNT',
            'name': 'Little Mount',
            'lat': 13.0147,
            'lng': 80.2210,
          },
          {
            'code': 'CHN_GUINDY',
            'name': 'Guindy',
            'lat': 13.0093,
            'lng': 80.2123,
          },
          {
            'code': 'CHN_ALANDUR',
            'name': 'Alandur',
            'lat': 12.9997,
            'lng': 80.2043,
          },
          {
            'code': 'CHN_NANGANALLUR',
            'name': 'Nanganallur Road',
            'lat': 12.9826,
            'lng': 80.1946,
          },
          {
            'code': 'CHN_MEENAMBAKKAM',
            'name': 'Meenambakkam',
            'lat': 12.9770,
            'lng': 80.1807,
          },
          {
            'code': 'CHN_AIRPORT',
            'name': 'Chennai Airport',
            'lat': 12.9774,
            'lng': 80.1706,
          },
        ],
      );

      // Green Line (Line 2)
      await seedLine(
        city: 'Chennai',
        lineName: 'Green Line',
        lineCode: 'CHN-L2',
        color: '#00A651',
        stations: [
          {
            'code': 'CHN_CHENNAI_CENTRAL',
            'name': 'Chennai Central',
            'lat': 13.0838,
            'lng': 80.2758,
          },
          {
            'code': 'CHN_EGMORE',
            'name': 'Egmore',
            'lat': 13.0733,
            'lng': 80.2620,
          },
          {
            'code': 'CHN_NEHRU_PARK',
            'name': 'Nehru Park',
            'lat': 13.0649,
            'lng': 80.2583,
          },
          {
            'code': 'CHN_KILPAUK',
            'name': 'Kilpauk',
            'lat': 13.0567,
            'lng': 80.2438,
          },
          {
            'code': 'CHN_PACHAIYAPPAS',
            'name': "Pachaiyappa's College",
            'lat': 13.0520,
            'lng': 80.2387,
          },
          {
            'code': 'CHN_SHENOY_NAGAR',
            'name': 'Shenoy Nagar',
            'lat': 13.0486,
            'lng': 80.2314,
          },
          {
            'code': 'CHN_ANNA_NAGAR_EAST',
            'name': 'Anna Nagar East',
            'lat': 13.0483,
            'lng': 80.2218,
          },
          {
            'code': 'CHN_ANNA_NAGAR_TOWER',
            'name': 'Anna Nagar Tower',
            'lat': 13.0475,
            'lng': 80.2117,
          },
          {
            'code': 'CHN_THIRUMANGALAM',
            'name': 'Thirumangalam',
            'lat': 13.0456,
            'lng': 80.2004,
          },
          {
            'code': 'CHN_KOYAMBEDU',
            'name': 'Koyambedu',
            'lat': 13.0362,
            'lng': 80.1968,
          },
          {'code': 'CHN_CMBT', 'name': 'CMBT', 'lat': 13.0335, 'lng': 80.2024},
          {
            'code': 'CHN_ARUMBAKKAM',
            'name': 'Arumbakkam',
            'lat': 13.0306,
            'lng': 80.2081,
          },
          {
            'code': 'CHN_VADAPALANI',
            'name': 'Vadapalani',
            'lat': 13.0493,
            'lng': 80.2118,
          },
          {
            'code': 'CHN_ASHOK_NAGAR',
            'name': 'Ashok Nagar',
            'lat': 13.0381,
            'lng': 80.2124,
          },
          {
            'code': 'CHN_EKKATTUTHANGAL',
            'name': 'Ekkattuthangal',
            'lat': 13.0172,
            'lng': 80.2063,
          },
          {
            'code': 'CHN_ALANDUR_G',
            'name': 'Alandur (Interchange)',
            'lat': 12.9997,
            'lng': 80.2043,
          },
          {
            'code': 'CHN_ST_THOMAS',
            'name': 'St. Thomas Mount',
            'lat': 12.9953,
            'lng': 80.1953,
          },
        ],
      );

      // ═══════════════════════════════════════════
      // HYDERABAD METRO
      // ═══════════════════════════════════════════

      // Red Line (Line 1 — Miyapur–LB Nagar)
      await seedLine(
        city: 'Hyderabad',
        lineName: 'Red Line',
        lineCode: 'HYD-RED',
        color: '#C60C30',
        stations: [
          {
            'code': 'HYD_MIYAPUR',
            'name': 'Miyapur',
            'lat': 17.4966,
            'lng': 78.3491,
          },
          {
            'code': 'HYD_JNTU',
            'name': 'JNTU College',
            'lat': 17.4939,
            'lng': 78.3623,
          },
          {
            'code': 'HYD_KPHB',
            'name': 'KPHB Colony',
            'lat': 17.4873,
            'lng': 78.3860,
          },
          {
            'code': 'HYD_KUKAT_BUS',
            'name': 'Kukatpally',
            'lat': 17.4847,
            'lng': 78.3958,
          },
          {
            'code': 'HYD_PRASHASAN_NAGAR',
            'name': 'Prashasan Nagar',
            'lat': 17.4815,
            'lng': 78.4049,
          },
          {
            'code': 'HYD_BALANAGAR',
            'name': 'Balanagar',
            'lat': 17.4748,
            'lng': 78.4130,
          },
          {
            'code': 'HYD_MOOSAPET',
            'name': 'Moosapet',
            'lat': 17.4668,
            'lng': 78.4192,
          },
          {
            'code': 'HYD_BHARATNAGAR',
            'name': 'Bharat Nagar',
            'lat': 17.4581,
            'lng': 78.4235,
          },
          {
            'code': 'HYD_ERRAGADDA',
            'name': 'Erragadda',
            'lat': 17.4492,
            'lng': 78.4336,
          },
          {
            'code': 'HYD_ESI',
            'name': 'ESI Hospital',
            'lat': 17.4405,
            'lng': 78.4395,
          },
          {
            'code': 'HYD_SR_NAGAR',
            'name': 'SR Nagar',
            'lat': 17.4365,
            'lng': 78.4444,
          },
          {
            'code': 'HYD_AMEERPET',
            'name': 'Ameerpet',
            'lat': 17.4359,
            'lng': 78.4488,
          },
          {
            'code': 'HYD_PANJAGUTTA',
            'name': 'Panjagutta',
            'lat': 17.4301,
            'lng': 78.4532,
          },
          {
            'code': 'HYD_IRRUM_MANZIL',
            'name': 'Irrum Manzil',
            'lat': 17.4277,
            'lng': 78.4546,
          },
          {
            'code': 'HYD_KHAIRATABAD',
            'name': 'Khairatabad',
            'lat': 17.4201,
            'lng': 78.4580,
          },
          {
            'code': 'HYD_LAKDI_KA_PUL',
            'name': 'Lakdi Ka Pul',
            'lat': 17.4069,
            'lng': 78.4650,
          },
          {
            'code': 'HYD_ASSEMBLY',
            'name': 'Assembly',
            'lat': 17.3989,
            'lng': 78.4694,
          },
          {
            'code': 'HYD_NAMPALLY',
            'name': 'Nampally',
            'lat': 17.3893,
            'lng': 78.4714,
          },
          {
            'code': 'HYD_GANDHI_BHAVAN',
            'name': 'Gandhi Bhavan',
            'lat': 17.3817,
            'lng': 78.4725,
          },
          {
            'code': 'HYD_OSMANIA_MEDICAL',
            'name': 'Osmania Medical College',
            'lat': 17.3721,
            'lng': 78.4741,
          },
          {'code': 'HYD_MGBS', 'name': 'MGBS', 'lat': 17.3701, 'lng': 78.4810},
          {
            'code': 'HYD_MALAKPET',
            'name': 'Malakpet',
            'lat': 17.3654,
            'lng': 78.4901,
          },
          {
            'code': 'HYD_NEW_MARKET',
            'name': 'New Market',
            'lat': 17.3612,
            'lng': 78.4955,
          },
          {
            'code': 'HYD_MUSARAMBAGH',
            'name': 'Musarambagh',
            'lat': 17.3574,
            'lng': 78.5000,
          },
          {
            'code': 'HYD_DILSUKHNAGAR',
            'name': 'Dilsukhnagar',
            'lat': 17.3553,
            'lng': 78.5259,
          },
          {
            'code': 'HYD_CHAITANYAPURI',
            'name': 'Chaitanyapuri',
            'lat': 17.3496,
            'lng': 78.5326,
          },
          {
            'code': 'HYD_VICTORIA_MEM',
            'name': 'Victoria Memorial',
            'lat': 17.3441,
            'lng': 78.5398,
          },
          {
            'code': 'HYD_LB_NAGAR',
            'name': 'LB Nagar',
            'lat': 17.3478,
            'lng': 78.5507,
          },
        ],
      );

      // Blue Line (Line 2 — JBS Parade Ground–Falaknuma)
      await seedLine(
        city: 'Hyderabad',
        lineName: 'Blue Line',
        lineCode: 'HYD-BLUE',
        color: '#002DA5',
        stations: [
          {
            'code': 'HYD_JBS',
            'name': 'JBS Parade Ground',
            'lat': 17.4530,
            'lng': 78.5009,
          },
          {
            'code': 'HYD_SECUNDERABAD_W',
            'name': 'Secunderabad West',
            'lat': 17.4410,
            'lng': 78.4989,
          },
          {
            'code': 'HYD_GANDHI_HOSPITAL',
            'name': 'Gandhi Hospital',
            'lat': 17.4302,
            'lng': 78.4919,
          },
          {
            'code': 'HYD_MUSHEERABAD',
            'name': 'Musheerabad',
            'lat': 17.4194,
            'lng': 78.4857,
          },
          {
            'code': 'HYD_RTC_X_RD',
            'name': 'RTC X Road',
            'lat': 17.4103,
            'lng': 78.4793,
          },
          {
            'code': 'HYD_CHIKKADPALLY',
            'name': 'Chikkadpally',
            'lat': 17.4005,
            'lng': 78.4744,
          },
          {
            'code': 'HYD_NARAYANGUDA',
            'name': 'Narayanguda',
            'lat': 17.3903,
            'lng': 78.4821,
          },
          {
            'code': 'HYD_SULTAN_BAZAR',
            'name': 'Sultan Bazaar',
            'lat': 17.3840,
            'lng': 78.4878,
          },
          {
            'code': 'HYD_MGBS_BL',
            'name': 'MGBS (Interchange)',
            'lat': 17.3701,
            'lng': 78.4810,
          },
          {
            'code': 'HYD_SHALIBANDA',
            'name': 'Shalibanda',
            'lat': 17.3621,
            'lng': 78.4789,
          },
          {
            'code': 'HYD_FALAKNUMA',
            'name': 'Falaknuma',
            'lat': 17.3373,
            'lng': 78.4610,
          },
        ],
      );

      // Green Line (Line 3 — Nagole–Raidurg)
      await seedLine(
        city: 'Hyderabad',
        lineName: 'Green Line',
        lineCode: 'HYD-GREEN',
        color: '#00A651',
        stations: [
          {
            'code': 'HYD_NAGOLE',
            'name': 'Nagole',
            'lat': 17.3926,
            'lng': 78.5623,
          },
          {
            'code': 'HYD_UPPAL',
            'name': 'Uppal',
            'lat': 17.3986,
            'lng': 78.5555,
          },
          {
            'code': 'HYD_SURVEY_OF_INDIA',
            'name': 'Survey of India',
            'lat': 17.4063,
            'lng': 78.5420,
          },
          {'code': 'HYD_NGRI', 'name': 'NGRI', 'lat': 17.4123, 'lng': 78.5315},
          {
            'code': 'HYD_HABSIGUDA',
            'name': 'Habsiguda',
            'lat': 17.4183,
            'lng': 78.5233,
          },
          {
            'code': 'HYD_TARNAKA',
            'name': 'Tarnaka',
            'lat': 17.4274,
            'lng': 78.5132,
          },
          {
            'code': 'HYD_METTUGUDA',
            'name': 'Mettuguda',
            'lat': 17.4342,
            'lng': 78.5066,
          },
          {
            'code': 'HYD_SECUNDERABAD',
            'name': 'Secunderabad',
            'lat': 17.4344,
            'lng': 78.5013,
          },
          {
            'code': 'HYD_PARADE_GROUND',
            'name': 'Parade Ground',
            'lat': 17.4398,
            'lng': 78.4937,
          },
          {
            'code': 'HYD_RASOOLPURA',
            'name': 'Rasoolpura',
            'lat': 17.4403,
            'lng': 78.4816,
          },
          {
            'code': 'HYD_BEGUMPET',
            'name': 'Begumpet',
            'lat': 17.4432,
            'lng': 78.4688,
          },
          {
            'code': 'HYD_AMEERPET_G',
            'name': 'Ameerpet (Interchange)',
            'lat': 17.4359,
            'lng': 78.4488,
          },
          {
            'code': 'HYD_MADHURA_NAGAR',
            'name': 'Madhura Nagar',
            'lat': 17.4381,
            'lng': 78.4365,
          },
          {
            'code': 'HYD_YUSUFGUDA',
            'name': 'Yusufguda',
            'lat': 17.4411,
            'lng': 78.4263,
          },
          {
            'code': 'HYD_ROAD_NO5_JUBILEE',
            'name': 'Road No. 5 Jubilee Hills',
            'lat': 17.4300,
            'lng': 78.4190,
          },
          {
            'code': 'HYD_JUBILEE_HILLS',
            'name': 'Jubilee Hills Check Post',
            'lat': 17.4255,
            'lng': 78.4088,
          },
          {
            'code': 'HYD_PEDDAMMA',
            'name': 'Peddamma Temple',
            'lat': 17.4230,
            'lng': 78.3993,
          },
          {
            'code': 'HYD_MADHAPUR',
            'name': 'Madhapur',
            'lat': 17.4377,
            'lng': 78.3929,
          },
          {
            'code': 'HYD_DURGAM_CHERUVU',
            'name': 'Durgam Cheruvu',
            'lat': 17.4404,
            'lng': 78.3812,
          },
          {
            'code': 'HYD_HITECH_CITY',
            'name': 'HITEC City',
            'lat': 17.4428,
            'lng': 78.3779,
          },
          {
            'code': 'HYD_RAIDURG',
            'name': 'Raidurg',
            'lat': 17.4393,
            'lng': 78.3695,
          },
        ],
      );

      // ═══════════════════════════════════════════
      // KOLKATA METRO
      // ═══════════════════════════════════════════

      // Blue Line (Line 1 — North-South)
      await seedLine(
        city: 'Kolkata',
        lineName: 'Blue Line',
        lineCode: 'KOL-BLUE',
        color: '#005DA6',
        stations: [
          {
            'code': 'KOL_DAKSHINESWAR',
            'name': 'Dakshineswar',
            'lat': 22.6543,
            'lng': 88.3577,
          },
          {
            'code': 'KOL_BARANAGAR',
            'name': 'Baranagar',
            'lat': 22.6383,
            'lng': 88.3625,
          },
          {
            'code': 'KOL_NOAPARA',
            'name': 'Noapara',
            'lat': 22.6288,
            'lng': 88.3676,
          },
          {
            'code': 'KOL_DUM_DUM',
            'name': 'Dum Dum',
            'lat': 22.6205,
            'lng': 88.3663,
          },
          {
            'code': 'KOL_BELGACHHIA',
            'name': 'Belgachhia',
            'lat': 22.6094,
            'lng': 88.3737,
          },
          {
            'code': 'KOL_SHYAMBAZAR',
            'name': 'Shyambazar',
            'lat': 22.5966,
            'lng': 88.3710,
          },
          {
            'code': 'KOL_SOVABAZAR',
            'name': 'Sovabazar–Sutanuti',
            'lat': 22.5903,
            'lng': 88.3651,
          },
          {
            'code': 'KOL_GIRISH_PARK',
            'name': 'Girish Park',
            'lat': 22.5817,
            'lng': 88.3598,
          },
          {
            'code': 'KOL_MAHATMA_GANDHI',
            'name': 'Mahatma Gandhi Road',
            'lat': 22.5709,
            'lng': 88.3534,
          },
          {
            'code': 'KOL_CENTRAL',
            'name': 'Central',
            'lat': 22.5631,
            'lng': 88.3530,
          },
          {
            'code': 'KOL_CHANDNI_CHOWK',
            'name': 'Chandni Chowk',
            'lat': 22.5595,
            'lng': 88.3491,
          },
          {
            'code': 'KOL_ESPLANADE',
            'name': 'Esplanade',
            'lat': 22.5553,
            'lng': 88.3523,
          },
          {
            'code': 'KOL_PARK_STREET',
            'name': 'Park Street',
            'lat': 22.5478,
            'lng': 88.3527,
          },
          {
            'code': 'KOL_MAIDAN',
            'name': 'Maidan',
            'lat': 22.5420,
            'lng': 88.3468,
          },
          {
            'code': 'KOL_RABINDRA_SAROBAR',
            'name': 'Rabindra Sarobar',
            'lat': 22.5186,
            'lng': 88.3518,
          },
          {
            'code': 'KOL_KALIGHAT',
            'name': 'Kalighat',
            'lat': 22.5256,
            'lng': 88.3437,
          },
          {
            'code': 'KOL_JATIN_DAS_PARK',
            'name': 'Jatin Das Park',
            'lat': 22.5128,
            'lng': 88.3398,
          },
          {
            'code': 'KOL_NETAJI_BHAVAN',
            'name': 'Netaji Bhavan',
            'lat': 22.5074,
            'lng': 88.3459,
          },
          {
            'code': 'KOL_MASTERDA',
            'name': 'Masterda Surya Sen',
            'lat': 22.4981,
            'lng': 88.3422,
          },
          {
            'code': 'KOL_KAVI_NAZRUL',
            'name': 'Kavi Nazrul',
            'lat': 22.4801,
            'lng': 88.3377,
          },
          {
            'code': 'KOL_NEW_GARIA',
            'name': 'New Garia',
            'lat': 22.4624,
            'lng': 88.3872,
          },
        ],
      );
    } catch (e) {
      // Log but don't crash — metro seed is non-critical
      // ignore: avoid_print
      print('Metro seed failed: $e');
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
      final csvString = await rootBundle.loadString(
        'assets/db/train_routes.csv',
      );
      final lines = csvString.split('\n');
      if (lines.isEmpty) return;

      // Get current max id so CSV ids don't collide with Dart seed ids
      final maxIdResult = await db.rawQuery(
        'SELECT MAX(id) as max_id FROM train_routes',
      );
      var nextId =
          (Sqflite.firstIntValue(
                await db.rawQuery('SELECT COUNT(*) FROM train_routes'),
              ) ??
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
        final distanceKm = fields.length > 7
            ? int.tryParse(fields[7].trim())
            : null;

        batch.insert('train_routes', {
          'id': nextId++,
          'train_number': fields[0].trim(),
          'train_name': fields[1].trim(),
          'station_code': fields[2].trim(),
          'stop_sequence': int.tryParse(fields[3].trim()) ?? 0,
          'arrival_time': arrivalTime.isEmpty ? null : arrivalTime,
          'departure_time': departureTime.isEmpty ? null : departureTime,
          'day': day,
          'distance_km': distanceKm,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // CSV not found or malformed — skip silently, Dart seed is the fallback
    }
  }

  static Future<void> _seedFallbackStations(Database db) async {
    final stations = [
      {
        'code': 'NDLS',
        'name': 'New Delhi',
        'latitude': 28.6424,
        'longitude': 77.2194,
        'state': 'Delhi',
        'zone': 'NR',
      },
      {
        'code': 'BCT',
        'name': 'Mumbai Central',
        'latitude': 18.9690,
        'longitude': 72.8197,
        'state': 'Maharashtra',
        'zone': 'WR',
      },
      {
        'code': 'CSMT',
        'name': 'Chhatrapati Shivaji Maharaj Terminus',
        'latitude': 18.9398,
        'longitude': 72.8355,
        'state': 'Maharashtra',
        'zone': 'CR',
      },
      {
        'code': 'HWH',
        'name': 'Howrah Junction',
        'latitude': 22.5839,
        'longitude': 88.3428,
        'state': 'West Bengal',
        'zone': 'ER',
      },
      {
        'code': 'MAS',
        'name': 'Chennai Central',
        'latitude': 13.0827,
        'longitude': 80.2707,
        'state': 'Tamil Nadu',
        'zone': 'SR',
      },
      {
        'code': 'SBC',
        'name': 'KSR Bengaluru',
        'latitude': 12.9784,
        'longitude': 77.5710,
        'state': 'Karnataka',
        'zone': 'SWR',
      },
      {
        'code': 'HYB',
        'name': 'Hyderabad Deccan',
        'latitude': 17.3616,
        'longitude': 78.4747,
        'state': 'Telangana',
        'zone': 'SCR',
      },
      {
        'code': 'PUNE',
        'name': 'Pune Junction',
        'latitude': 18.5285,
        'longitude': 73.8743,
        'state': 'Maharashtra',
        'zone': 'CR',
      },
      {
        'code': 'ADI',
        'name': 'Ahmedabad Junction',
        'latitude': 23.0258,
        'longitude': 72.6003,
        'state': 'Gujarat',
        'zone': 'WR',
      },
      {
        'code': 'JP',
        'name': 'Jaipur Junction',
        'latitude': 26.9196,
        'longitude': 75.7878,
        'state': 'Rajasthan',
        'zone': 'NWR',
      },
      {
        'code': 'LKO',
        'name': 'Lucknow Charbagh',
        'latitude': 26.8322,
        'longitude': 80.9167,
        'state': 'Uttar Pradesh',
        'zone': 'NR',
      },
      {
        'code': 'PNBE',
        'name': 'Patna Junction',
        'latitude': 25.6053,
        'longitude': 85.1347,
        'state': 'Bihar',
        'zone': 'ECR',
      },
      {
        'code': 'BPL',
        'name': 'Bhopal Junction',
        'latitude': 23.2687,
        'longitude': 77.4119,
        'state': 'Madhya Pradesh',
        'zone': 'WCR',
      },
      {
        'code': 'NGP',
        'name': 'Nagpur Junction',
        'latitude': 21.1503,
        'longitude': 79.0903,
        'state': 'Maharashtra',
        'zone': 'CR',
      },
      {
        'code': 'SC',
        'name': 'Secunderabad Junction',
        'latitude': 17.4344,
        'longitude': 78.5013,
        'state': 'Telangana',
        'zone': 'SCR',
      },
      {
        'code': 'BZA',
        'name': 'Vijayawada Junction',
        'latitude': 16.5175,
        'longitude': 80.6186,
        'state': 'Andhra Pradesh',
        'zone': 'SCR',
      },
      {
        'code': 'TVC',
        'name': 'Thiruvananthapuram Central',
        'latitude': 8.4894,
        'longitude': 76.9516,
        'state': 'Kerala',
        'zone': 'SR',
      },
      {
        'code': 'ERS',
        'name': 'Ernakulam Junction',
        'latitude': 9.9681,
        'longitude': 76.2880,
        'state': 'Kerala',
        'zone': 'SR',
      },
      {
        'code': 'GHY',
        'name': 'Guwahati',
        'latitude': 26.1445,
        'longitude': 91.7362,
        'state': 'Assam',
        'zone': 'NFR',
      },
      {
        'code': 'JAT',
        'name': 'Jammu Tawi',
        'latitude': 32.7304,
        'longitude': 74.8671,
        'state': 'Jammu & Kashmir',
        'zone': 'NR',
      },
      {
        'code': 'ASR',
        'name': 'Amritsar Junction',
        'latitude': 31.6340,
        'longitude': 74.8723,
        'state': 'Punjab',
        'zone': 'NR',
      },
      {
        'code': 'LTT',
        'name': 'Lokmanya Tilak Terminus',
        'latitude': 19.0680,
        'longitude': 72.8892,
        'state': 'Maharashtra',
        'zone': 'CR',
      },
      {
        'code': 'NZM',
        'name': 'Hazrat Nizamuddin',
        'latitude': 28.5893,
        'longitude': 77.2507,
        'state': 'Delhi',
        'zone': 'NR',
      },
      {
        'code': 'DLI',
        'name': 'Old Delhi Junction',
        'latitude': 28.6615,
        'longitude': 77.2295,
        'state': 'Delhi',
        'zone': 'NR',
      },
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
