import 'package:sqflite/sqflite.dart';

/// Seeds frequency-based schedules for metro systems across Indian cities.
///
/// Metro trains run at fixed frequencies that vary by time of day:
/// - Peak hours (8-10, 17-20): every 3-4 minutes
/// - Off-peak: every 6-8 minutes
/// - Early morning / late night: every 10-15 minutes
class MetroScheduleSeedData {
  static Future<void> seed(Database db) async {
    // Get all metro lines from the database
    final lines = await db.query('metro_lines');
    if (lines.isEmpty) return;

    final batch = db.batch();
    int id = 1;

    for (final line in lines) {
      final lineId = line['id'] as int;
      final city = line['city'] as String;

      // Get city-specific schedule profile
      final profile = _getScheduleProfile(city);

      for (final direction in ['UP', 'DN']) {
        for (final slot in profile) {
          for (int h = slot.startHour; h <= slot.endHour; h++) {
            for (int m = 0; m < 60; m += slot.frequencyMinutes) {
              batch.insert('metro_schedules', {
                'id': id++,
                'line_id': lineId,
                'direction': direction,
                'departure_hour': h,
                'departure_minute': m,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }
        }
      }
    }

    await batch.commit(noResult: true);
  }

  static List<_TimeSlot> _getScheduleProfile(String city) {
    switch (city) {
      case 'Delhi':
        // Delhi Metro: 5 AM to 11 PM, high frequency
        return [
          _TimeSlot(5, 5, 15), // Early: every 15 min
          _TimeSlot(6, 7, 8), // Pre-peak: every 8 min
          _TimeSlot(8, 10, 4), // Morning peak: every 4 min
          _TimeSlot(11, 16, 6), // Off-peak: every 6 min
          _TimeSlot(17, 20, 4), // Evening peak: every 4 min
          _TimeSlot(21, 22, 8), // Late: every 8 min
          _TimeSlot(23, 23, 15), // Last trains: every 15 min
        ];
      case 'Mumbai':
        // Mumbai Metro: 6 AM to 10:30 PM
        return [
          _TimeSlot(6, 7, 10),
          _TimeSlot(8, 10, 4),
          _TimeSlot(11, 16, 7),
          _TimeSlot(17, 20, 4),
          _TimeSlot(21, 22, 10),
        ];
      case 'Bangalore':
        // Namma Metro: 5 AM to 11 PM
        return [
          _TimeSlot(5, 6, 15),
          _TimeSlot(7, 9, 5),
          _TimeSlot(10, 16, 8),
          _TimeSlot(17, 20, 5),
          _TimeSlot(21, 23, 10),
        ];
      case 'Kolkata':
        // Kolkata Metro: 6:45 AM to 9:55 PM
        return [
          _TimeSlot(7, 8, 10),
          _TimeSlot(9, 11, 5),
          _TimeSlot(12, 16, 8),
          _TimeSlot(17, 20, 5),
          _TimeSlot(21, 21, 10),
        ];
      case 'Chennai':
        // Chennai Metro: 5:30 AM to 11 PM
        return [
          _TimeSlot(5, 6, 15),
          _TimeSlot(7, 9, 5),
          _TimeSlot(10, 16, 8),
          _TimeSlot(17, 20, 5),
          _TimeSlot(21, 23, 12),
        ];
      case 'Hyderabad':
        // Hyderabad Metro: 6 AM to 10 PM
        return [
          _TimeSlot(6, 7, 10),
          _TimeSlot(8, 10, 5),
          _TimeSlot(11, 16, 8),
          _TimeSlot(17, 20, 5),
          _TimeSlot(21, 22, 10),
        ];
      default:
        // Generic Indian metro schedule
        return [
          _TimeSlot(6, 7, 12),
          _TimeSlot(8, 10, 5),
          _TimeSlot(11, 16, 8),
          _TimeSlot(17, 20, 5),
          _TimeSlot(21, 22, 12),
        ];
    }
  }
}

class _TimeSlot {
  final int startHour;
  final int endHour;
  final int frequencyMinutes;

  const _TimeSlot(this.startHour, this.endHour, this.frequencyMinutes);
}
