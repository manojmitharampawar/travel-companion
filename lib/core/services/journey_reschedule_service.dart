import 'package:flutter/material.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';

/// Service for rescheduling a journey (cloning + date/time update).
///
/// SOLID-S: Single Responsibility - only handles journey cloning and insertion.
/// SOLID-D: Depends on [JourneyRepository] injected via constructor.
///
/// Usage:
/// ```dart
/// final service = JourneyRescheduleService(journeyRepository: repo);
/// final newId = await service.rescheduleJourney(
///   journey: favorite,
///   selectedDate: DateTime(2026, 4, 15),
///   selectedTime: const TimeOfDay(hour: 7, minute: 30),
/// );
/// ```
class JourneyRescheduleService {
  final JourneyRepository journeyRepository;

  JourneyRescheduleService({
    required this.journeyRepository,
  });

  /// Clones a journey to a new date/time and inserts it.
  ///
  /// - Creates a new Journey via copyWith(id: null)
  /// - Resets status to 'upcoming'
  /// - Combines selectedDate with selectedTime for journeyDate
  /// - Clears favorite flag (reschedules are new journeys)
  /// - Inserts into database
  /// - Returns the newly created journey ID
  ///
  /// Throws: May throw database errors from journeyRepository
  Future<int> rescheduleJourney({
    required Journey journey,
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
  }) async {
    // Combine date and time
    final newJourneyDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Clone journey with reset ID, new date, and upcoming status
    final clonedJourney = journey.copyWith(
      id: null, // Reset ID to create new record
      journeyDate: newJourneyDate,
      status: JourneyStatus.upcoming, // New journeys start as upcoming
      isFavorite: false, // Reset favorite flag
      createdAt: DateTime.now(), // New creation timestamp
    );

    // Insert and return new ID
    return await journeyRepository.insertJourney(clonedJourney);
  }
}
