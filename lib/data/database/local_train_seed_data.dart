import 'package:sqflite/sqflite.dart';

/// Seeds Mumbai suburban railway lines, stations, and frequency-based schedules.
class LocalTrainSeedData {
  static Future<void> seed(Database db) async {
    await _seedLines(db);
    await _seedStations(db);
    await _seedSchedules(db);
  }

  // ═══════════════════════════════════════════
  // Lines
  // ═════════════════════════���═════════════════

  static Future<void> _seedLines(Database db) async {
    final lines = [
      {
        'id': 1,
        'city': 'Mumbai',
        'line_name': 'Western Line',
        'line_code': 'WR',
        'color': '#1565C0',
        'start_station': 'CCG',
        'end_station': 'VR',
      },
      {
        'id': 2,
        'city': 'Mumbai',
        'line_name': 'Central Line',
        'line_code': 'CR',
        'color': '#C62828',
        'start_station': 'CSMT',
        'end_station': 'KYN',
      },
      {
        'id': 3,
        'city': 'Mumbai',
        'line_name': 'Harbour Line',
        'line_code': 'HR',
        'color': '#2E7D32',
        'start_station': 'CSMT',
        'end_station': 'PNVL',
      },
      {
        'id': 4,
        'city': 'Mumbai',
        'line_name': 'Trans-Harbour Line',
        'line_code': 'TH',
        'color': '#6A1B9A',
        'start_station': 'TNA',
        'end_station': 'PNVL',
      },
      {
        'id': 5,
        'city': 'Kolkata',
        'line_name': 'Sealdah Main',
        'line_code': 'SDAH-M',
        'color': '#0D47A1',
        'start_station': 'SDAH',
        'end_station': 'BNJ',
      },
      {
        'id': 6,
        'city': 'Chennai',
        'line_name': 'Beach–Tambaram',
        'line_code': 'MAS-TBM',
        'color': '#E65100',
        'start_station': 'MSB',
        'end_station': 'TBM',
      },
    ];
    final batch = db.batch();
    for (final line in lines) {
      batch.insert(
        'local_train_lines',
        line,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // ═══════════════════════════════════════════
  // Stations (ordered by station_index)
  // ═══════════════════════════════════════════

  static Future<void> _seedStations(Database db) async {
    final batch = db.batch();
    int id = 1;

    void addStations(int lineId, List<Map<String, dynamic>> stations) {
      for (int i = 0; i < stations.length; i++) {
        final s = stations[i];
        batch.insert('local_train_stations', {
          'id': id++,
          'line_id': lineId,
          'code': s['code'],
          'name': s['name'],
          'station_index': i,
          'latitude': s['lat'],
          'longitude': s['lng'],
          'platform_count': s['platforms'] ?? 2,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // ── Western Line (Churchgate → Virar) ──
    addStations(1, [
      {
        'code': 'CCG',
        'name': 'Churchgate',
        'lat': 18.9354,
        'lng': 72.8274,
        'platforms': 5,
      },
      {'code': 'MRG', 'name': 'Marine Lines', 'lat': 18.9437, 'lng': 72.8235},
      {'code': 'CHR', 'name': 'Charni Road', 'lat': 18.9519, 'lng': 72.8199},
      {'code': 'GTR', 'name': 'Grant Road', 'lat': 18.9630, 'lng': 72.8165},
      {
        'code': 'BCR',
        'name': 'Mumbai Central',
        'lat': 18.9690,
        'lng': 72.8197,
        'platforms': 4,
      },
      {
        'code': 'ELH',
        'name': 'Elphinstone Road',
        'lat': 18.9840,
        'lng': 72.8250,
      },
      {
        'code': 'DDR',
        'name': 'Dadar',
        'lat': 19.0178,
        'lng': 72.8425,
        'platforms': 4,
      },
      {'code': 'MWAD', 'name': 'Matunga Road', 'lat': 19.0271, 'lng': 72.8465},
      {'code': 'MHD', 'name': 'Mahim', 'lat': 19.0413, 'lng': 72.8402},
      {
        'code': 'BDR',
        'name': 'Bandra',
        'lat': 19.0545,
        'lng': 72.8401,
        'platforms': 4,
      },
      {'code': 'KHR', 'name': 'Khar Road', 'lat': 19.0659, 'lng': 72.8374},
      {'code': 'SNC', 'name': 'Santacruz', 'lat': 19.0795, 'lng': 72.8425},
      {'code': 'VLP', 'name': 'Vile Parle', 'lat': 19.0984, 'lng': 72.8433},
      {
        'code': 'AND',
        'name': 'Andheri',
        'lat': 19.1197,
        'lng': 72.8468,
        'platforms': 4,
      },
      {'code': 'JOG', 'name': 'Jogeshwari', 'lat': 19.1368, 'lng': 72.8490},
      {'code': 'RAM', 'name': 'Ram Mandir', 'lat': 19.1444, 'lng': 72.8510},
      {'code': 'GGN', 'name': 'Goregaon', 'lat': 19.1660, 'lng': 72.8495},
      {'code': 'MLN', 'name': 'Malad', 'lat': 19.1868, 'lng': 72.8441},
      {'code': 'KDV', 'name': 'Kandivali', 'lat': 19.2072, 'lng': 72.8467},
      {
        'code': 'BVI',
        'name': 'Borivali',
        'lat': 19.2286,
        'lng': 72.8567,
        'platforms': 4,
      },
      {'code': 'DIC', 'name': 'Dahisar', 'lat': 19.2513, 'lng': 72.8567},
      {'code': 'MRA', 'name': 'Mira Road', 'lat': 19.2800, 'lng': 72.8687},
      {'code': 'BYMR', 'name': 'Bhayandar', 'lat': 19.3004, 'lng': 72.8523},
      {'code': 'NIG', 'name': 'Naigaon', 'lat': 19.3413, 'lng': 72.8527},
      {
        'code': 'BSR',
        'name': 'Vasai Road',
        'lat': 19.3695,
        'lng': 72.8275,
        'platforms': 4,
      },
      {'code': 'NLSPR', 'name': 'Nallasopara', 'lat': 19.4176, 'lng': 72.8103},
      {
        'code': 'VR',
        'name': 'Virar',
        'lat': 19.4559,
        'lng': 72.8117,
        'platforms': 4,
      },
    ]);

    // ── Central Line (CSMT → Kalyan) ──
    addStations(2, [
      {
        'code': 'CSMT',
        'name': 'CSMT (Mumbai)',
        'lat': 18.9398,
        'lng': 72.8355,
        'platforms': 8,
      },
      {'code': 'MSJ', 'name': 'Masjid Bunder', 'lat': 18.9473, 'lng': 72.8393},
      {'code': 'SBR', 'name': 'Sandhurst Road', 'lat': 18.9568, 'lng': 72.8433},
      {'code': 'BCL', 'name': 'Byculla', 'lat': 18.9780, 'lng': 72.8327},
      {'code': 'CPI', 'name': 'Chinchpokli', 'lat': 18.9883, 'lng': 72.8329},
      {'code': 'CRD', 'name': 'Currey Road', 'lat': 18.9945, 'lng': 72.8370},
      {'code': 'PR', 'name': 'Parel', 'lat': 19.0050, 'lng': 72.8395},
      {
        'code': 'DDR_C',
        'name': 'Dadar Central',
        'lat': 19.0178,
        'lng': 72.8425,
        'platforms': 4,
      },
      {'code': 'MTN', 'name': 'Matunga', 'lat': 19.0271, 'lng': 72.8527},
      {'code': 'SN', 'name': 'Sion', 'lat': 19.0440, 'lng': 72.8620},
      {
        'code': 'KWR',
        'name': 'Kurla',
        'lat': 19.0651,
        'lng': 72.8790,
        'platforms': 4,
      },
      {'code': 'VDL', 'name': 'Vidyavihar', 'lat': 19.0786, 'lng': 72.8877},
      {
        'code': 'GC',
        'name': 'Ghatkopar',
        'lat': 19.0860,
        'lng': 72.9080,
        'platforms': 4,
      },
      {'code': 'VKR', 'name': 'Vikhroli', 'lat': 19.1011, 'lng': 72.9203},
      {'code': 'KNS', 'name': 'Kanjurmarg', 'lat': 19.1172, 'lng': 72.9303},
      {'code': 'BND', 'name': 'Bhandup', 'lat': 19.1313, 'lng': 72.9370},
      {'code': 'NHV', 'name': 'Nahur', 'lat': 19.1404, 'lng': 72.9429},
      {
        'code': 'MUL',
        'name': 'Mulund',
        'lat': 19.1726,
        'lng': 72.9565,
        'platforms': 4,
      },
      {
        'code': 'TNA',
        'name': 'Thane',
        'lat': 19.1860,
        'lng': 72.9757,
        'platforms': 6,
      },
      {'code': 'KPR', 'name': 'Kalva', 'lat': 19.1942, 'lng': 72.9940},
      {
        'code': 'DI',
        'name': 'Dombivli',
        'lat': 19.2183,
        'lng': 73.0864,
        'platforms': 4,
      },
      {
        'code': 'KYN',
        'name': 'Kalyan Junction',
        'lat': 19.2437,
        'lng': 73.1292,
        'platforms': 6,
      },
    ]);

    // ── Harbour Line (CSMT → Panvel) ──
    addStations(3, [
      {
        'code': 'CSMT_H',
        'name': 'CSMT (Harbour)',
        'lat': 18.9398,
        'lng': 72.8355,
      },
      {
        'code': 'MSJ_H',
        'name': 'Masjid (Harbour)',
        'lat': 18.9473,
        'lng': 72.8393,
      },
      {
        'code': 'SBR_H',
        'name': 'Sandhurst Road (H)',
        'lat': 18.9568,
        'lng': 72.8433,
      },
      {'code': 'DKR', 'name': 'Dockyard Road', 'lat': 18.9609, 'lng': 72.8540},
      {'code': 'RYR', 'name': 'Reay Road', 'lat': 18.9680, 'lng': 72.8560},
      {'code': 'CTN', 'name': 'Cotton Green', 'lat': 18.9835, 'lng': 72.8567},
      {'code': 'SVR', 'name': 'Sewri', 'lat': 18.9980, 'lng': 72.8603},
      {'code': 'WDLA', 'name': 'Wadala Road', 'lat': 19.0168, 'lng': 72.8637},
      {'code': 'GTL', 'name': 'GTB Nagar', 'lat': 19.0288, 'lng': 72.8657},
      {'code': 'CNB', 'name': 'Chunabhatti', 'lat': 19.0370, 'lng': 72.8707},
      {
        'code': 'KWR_H',
        'name': 'Kurla (Harbour)',
        'lat': 19.0651,
        'lng': 72.8790,
      },
      {'code': 'TEL', 'name': 'Tilak Nagar', 'lat': 19.0664, 'lng': 72.8872},
      {'code': 'CLA', 'name': 'Chembur', 'lat': 19.0626, 'lng': 72.8965},
      {'code': 'GVD', 'name': 'Govandi', 'lat': 19.0508, 'lng': 72.9065},
      {'code': 'MBQ', 'name': 'Mankhurd', 'lat': 19.0432, 'lng': 72.9280},
      {
        'code': 'VAS',
        'name': 'Vashi',
        'lat': 19.0646,
        'lng': 72.9977,
        'platforms': 4,
      },
      {'code': 'SWD', 'name': 'Sanpada', 'lat': 19.0574, 'lng': 73.0077},
      {'code': 'JNR', 'name': 'Juinagar', 'lat': 19.0486, 'lng': 73.0160},
      {
        'code': 'NRI',
        'name': 'Nerul',
        'lat': 19.0329,
        'lng': 73.0190,
        'platforms': 4,
      },
      {
        'code': 'SDR',
        'name': 'Seawoods-Darave',
        'lat': 19.0194,
        'lng': 73.0258,
      },
      {'code': 'BPKN', 'name': 'Belapur CBD', 'lat': 19.0237, 'lng': 73.0393},
      {'code': 'KMN', 'name': 'Kharghar', 'lat': 19.0309, 'lng': 73.0613},
      {'code': 'MRD', 'name': 'Mansarovar', 'lat': 19.0340, 'lng': 73.0706},
      {'code': 'KHDL', 'name': 'Khandeshwar', 'lat': 19.0285, 'lng': 73.0819},
      {
        'code': 'PNVL',
        'name': 'Panvel',
        'lat': 18.9930,
        'lng': 73.1096,
        'platforms': 4,
      },
    ]);

    // ── Trans-Harbour Line (Thane → Panvel) ──
    addStations(4, [
      {
        'code': 'TNA_TH',
        'name': 'Thane (Trans-Harbour)',
        'lat': 19.1860,
        'lng': 72.9757,
      },
      {'code': 'ARDL', 'name': 'Airoli', 'lat': 19.1534, 'lng': 73.0095},
      {'code': 'RBN', 'name': 'Rabale', 'lat': 19.1366, 'lng': 73.0156},
      {'code': 'GNR', 'name': 'Ghansoli', 'lat': 19.1199, 'lng': 73.0100},
      {'code': 'KOP', 'name': 'Koparkhairne', 'lat': 19.1035, 'lng': 73.0090},
      {'code': 'TBR', 'name': 'Turbhe', 'lat': 19.0820, 'lng': 73.0103},
      {
        'code': 'VAS_TH',
        'name': 'Vashi (Trans-Harbour)',
        'lat': 19.0646,
        'lng': 72.9977,
      },
      {
        'code': 'SWD_TH',
        'name': 'Sanpada (TH)',
        'lat': 19.0574,
        'lng': 73.0077,
      },
      {
        'code': 'JNR_TH',
        'name': 'Juinagar (TH)',
        'lat': 19.0486,
        'lng': 73.0160,
      },
      {'code': 'NRI_TH', 'name': 'Nerul (TH)', 'lat': 19.0329, 'lng': 73.0190},
      {
        'code': 'SDR_TH',
        'name': 'Seawoods (TH)',
        'lat': 19.0194,
        'lng': 73.0258,
      },
      {
        'code': 'BPKN_TH',
        'name': 'Belapur CBD (TH)',
        'lat': 19.0237,
        'lng': 73.0393,
      },
      {
        'code': 'KMN_TH',
        'name': 'Kharghar (TH)',
        'lat': 19.0309,
        'lng': 73.0613,
      },
      {
        'code': 'MRD_TH',
        'name': 'Mansarovar (TH)',
        'lat': 19.0340,
        'lng': 73.0706,
      },
      {
        'code': 'KHDL_TH',
        'name': 'Khandeshwar (TH)',
        'lat': 19.0285,
        'lng': 73.0819,
      },
      {
        'code': 'PNVL_TH',
        'name': 'Panvel (TH)',
        'lat': 18.9930,
        'lng': 73.1096,
      },
    ]);

    await batch.commit(noResult: true);
  }

  // ═══════════════════════════════════════════
  // Schedules (frequency-based for peak/off-peak)
  // ═══════════════════════════════════════════

  static Future<void> _seedSchedules(Database db) async {
    final batch = db.batch();
    int id = 1;

    // Frequency-based schedules: we generate departure times from base station
    // at regular intervals throughout the day.
    //
    // Format: for each line + direction, we store (hour, minute) departure
    // entries from the FIRST station. Intermediate ETAs are calculated at runtime
    // using avg speed per station (~3 min between stops).

    void addSchedule({
      required int lineId,
      required String
      direction, // 'UP' (towards terminus) or 'DN' (away from terminus)
      required String trainType, // 'SLOW', 'FAST', 'SEMI_FAST'
      required int startHour,
      required int endHour,
      required int frequencyMinutes,
      List<int> skipStationIndices = const [], // stations FAST trains skip
    }) {
      for (int h = startHour; h <= endHour; h++) {
        for (int m = 0; m < 60; m += frequencyMinutes) {
          batch.insert('local_train_schedules', {
            'id': id++,
            'line_id': lineId,
            'direction': direction,
            'train_type': trainType,
            'departure_hour': h,
            'departure_minute': m,
            'skip_station_indices': skipStationIndices.isNotEmpty
                ? skipStationIndices.join(',')
                : null,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }

    // ── Western Line schedules ──
    // SLOW trains: every 6 min peak, 10 min off-peak
    addSchedule(
      lineId: 1,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 4,
      endHour: 6,
      frequencyMinutes: 15,
    );
    addSchedule(
      lineId: 1,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 6,
    );
    addSchedule(
      lineId: 1,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 12,
      endHour: 16,
      frequencyMinutes: 10,
    );
    addSchedule(
      lineId: 1,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 6,
    );
    addSchedule(
      lineId: 1,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 22,
      endHour: 23,
      frequencyMinutes: 15,
    );

    addSchedule(
      lineId: 1,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 4,
      endHour: 6,
      frequencyMinutes: 15,
    );
    addSchedule(
      lineId: 1,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 6,
    );
    addSchedule(
      lineId: 1,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 12,
      endHour: 16,
      frequencyMinutes: 10,
    );
    addSchedule(
      lineId: 1,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 6,
    );
    addSchedule(
      lineId: 1,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 22,
      endHour: 23,
      frequencyMinutes: 15,
    );

    // FAST trains: every 8 min peak, 15 min off-peak (skip small stations)
    addSchedule(
      lineId: 1,
      direction: 'UP',
      trainType: 'FAST',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 8,
      skipStationIndices: [1, 2, 3, 5, 7, 8, 10, 14, 15, 17, 21, 23],
    ); // Skip Marine Lines, Charni Road, Grant Rd, Elphinstone, Matunga Rd, Mahim, Khar, Jogeshwari, Ram Mandir, Malad, Mira Rd, Naigaon
    addSchedule(
      lineId: 1,
      direction: 'UP',
      trainType: 'FAST',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 8,
      skipStationIndices: [1, 2, 3, 5, 7, 8, 10, 14, 15, 17, 21, 23],
    );
    addSchedule(
      lineId: 1,
      direction: 'DN',
      trainType: 'FAST',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 8,
      skipStationIndices: [1, 2, 3, 5, 7, 8, 10, 14, 15, 17, 21, 23],
    );
    addSchedule(
      lineId: 1,
      direction: 'DN',
      trainType: 'FAST',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 8,
      skipStationIndices: [1, 2, 3, 5, 7, 8, 10, 14, 15, 17, 21, 23],
    );

    // ── Central Line schedules ──
    addSchedule(
      lineId: 2,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 4,
      endHour: 6,
      frequencyMinutes: 15,
    );
    addSchedule(
      lineId: 2,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 5,
    );
    addSchedule(
      lineId: 2,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 12,
      endHour: 16,
      frequencyMinutes: 10,
    );
    addSchedule(
      lineId: 2,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 5,
    );
    addSchedule(
      lineId: 2,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 22,
      endHour: 23,
      frequencyMinutes: 15,
    );

    addSchedule(
      lineId: 2,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 4,
      endHour: 6,
      frequencyMinutes: 15,
    );
    addSchedule(
      lineId: 2,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 5,
    );
    addSchedule(
      lineId: 2,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 12,
      endHour: 16,
      frequencyMinutes: 10,
    );
    addSchedule(
      lineId: 2,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 5,
    );
    addSchedule(
      lineId: 2,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 22,
      endHour: 23,
      frequencyMinutes: 15,
    );

    // FAST trains for Central Line
    addSchedule(
      lineId: 2,
      direction: 'UP',
      trainType: 'FAST',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 8,
      skipStationIndices: [1, 2, 4, 5, 6, 8, 11, 13, 14, 15, 16],
    ); // Skip Masjid, Sandhurst, Chinch, Currey, Parel, Matunga, Vidyavihar, Vikhroli, Kanjur, Bhandup, Nahur
    addSchedule(
      lineId: 2,
      direction: 'UP',
      trainType: 'FAST',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 8,
      skipStationIndices: [1, 2, 4, 5, 6, 8, 11, 13, 14, 15, 16],
    );
    addSchedule(
      lineId: 2,
      direction: 'DN',
      trainType: 'FAST',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 8,
      skipStationIndices: [1, 2, 4, 5, 6, 8, 11, 13, 14, 15, 16],
    );
    addSchedule(
      lineId: 2,
      direction: 'DN',
      trainType: 'FAST',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 8,
      skipStationIndices: [1, 2, 4, 5, 6, 8, 11, 13, 14, 15, 16],
    );

    // ── Harbour Line schedules (SLOW only) ──
    addSchedule(
      lineId: 3,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 5,
      endHour: 6,
      frequencyMinutes: 15,
    );
    addSchedule(
      lineId: 3,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 8,
    );
    addSchedule(
      lineId: 3,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 12,
      endHour: 16,
      frequencyMinutes: 12,
    );
    addSchedule(
      lineId: 3,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 8,
    );
    addSchedule(
      lineId: 3,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 22,
      endHour: 23,
      frequencyMinutes: 20,
    );

    addSchedule(
      lineId: 3,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 5,
      endHour: 6,
      frequencyMinutes: 15,
    );
    addSchedule(
      lineId: 3,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 7,
      endHour: 11,
      frequencyMinutes: 8,
    );
    addSchedule(
      lineId: 3,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 12,
      endHour: 16,
      frequencyMinutes: 12,
    );
    addSchedule(
      lineId: 3,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 17,
      endHour: 21,
      frequencyMinutes: 8,
    );
    addSchedule(
      lineId: 3,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 22,
      endHour: 23,
      frequencyMinutes: 20,
    );

    // ── Trans-Harbour Line schedules ──
    addSchedule(
      lineId: 4,
      direction: 'UP',
      trainType: 'SLOW',
      startHour: 5,
      endHour: 23,
      frequencyMinutes: 15,
    );
    addSchedule(
      lineId: 4,
      direction: 'DN',
      trainType: 'SLOW',
      startHour: 5,
      endHour: 23,
      frequencyMinutes: 15,
    );

    await batch.commit(noResult: true);
  }
}
