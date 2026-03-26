import 'dart:async';

import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';

class RepeatJourneyService {
  final JourneyRepository _journeyRepository;
  Timer? _checkTimer;

  RepeatJourneyService({required JourneyRepository journeyRepository})
      : _journeyRepository = journeyRepository;

  void start() {
    // Check on startup
    createTodaysRepeatJourneys();
    // Check periodically (every 6 hours)
    _checkTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => createTodaysRepeatJourneys(),
    );
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> createTodaysRepeatJourneys() async {
    final repeatJourneys = await _journeyRepository.getRepeatJourneys();
    final now = DateTime.now();
    // Monday = 1 in DateTime, our bitmask: bit 0 = Monday
    final todayBit = 1 << (now.weekday - 1);
    final todayDate = DateTime(now.year, now.month, now.day);

    for (final journey in repeatJourneys) {
      if (journey.repeatDays == null) continue;
      if (journey.repeatDays! & todayBit == 0) continue;

      // Check if a journey for today already exists with same route
      final existing = await _journeyRepository.getJourneysForDate(todayDate);
      final alreadyExists = existing.any((j) =>
          j.vehicleNumber == journey.vehicleNumber &&
          j.boardingStationCode == journey.boardingStationCode &&
          j.destinationStationCode == journey.destinationStationCode &&
          j.originName == journey.originName &&
          j.destinationName == journey.destinationName &&
          j.id != journey.id);

      if (!alreadyExists) {
        // Create today's instance from the repeat template
        DateTime journeyDateTime = todayDate;
        if (journey.scheduledTime != null) {
          final parts = journey.scheduledTime!.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            journeyDateTime = DateTime(now.year, now.month, now.day, hour, minute);
          }
        }

        final newJourney = journey.copyWith(
          id: null,
          journeyDate: journeyDateTime,
          status: JourneyStatus.upcoming,
          isFavorite: false,
          isQuickTrip: false,
          repeatDays: null, // Instance, not template
          createdAt: now,
        );

        await _journeyRepository.insertJourney(newJourney);
      }
    }
  }

  void dispose() {
    stop();
  }
}
