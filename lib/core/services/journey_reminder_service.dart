import 'dart:async';

import 'package:travel_companion/core/services/notification_service.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';

class JourneyReminderService {
  final JourneyRepository _journeyRepository;
  Timer? _reminderTimer;

  JourneyReminderService({required JourneyRepository journeyRepository})
      : _journeyRepository = journeyRepository;

  void startPeriodicCheck() {
    _reminderTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => checkAndNotify(),
    );
    checkAndNotify();
  }

  void stopPeriodicCheck() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  Future<void> checkAndNotify() async {
    final journeys = await _journeyRepository.getUpcomingJourneys();
    final now = DateTime.now();

    for (final journey in journeys) {
      if (journey.status != JourneyStatus.upcoming) continue;
      if (journey.isQuickTrip) continue;

      final timeUntilJourney = journey.journeyDate.difference(now);
      final typeLabel = journey.transportType.label;
      final vehicleInfo = _vehicleInfo(journey);

      // Journey is tomorrow (18-24 hours away)
      if (timeUntilJourney.inHours >= 18 && timeUntilJourney.inHours <= 24) {
        await NotificationService.showReminder(
          id: journey.id! * 10 + 1,
          title: '$typeLabel Journey Tomorrow!',
          body: '$vehicleInfo departs tomorrow. Get ready!',
        );
      }

      // Journey is in 3 hours
      if (timeUntilJourney.inMinutes >= 150 &&
          timeUntilJourney.inMinutes <= 210) {
        final extraTip = journey.isTrain
            ? " Don't forget your ID proof and ticket."
            : '';
        await NotificationService.showReminder(
          id: journey.id! * 10 + 2,
          title: '$typeLabel Journey in 3 hours!',
          body: '$vehicleInfo departs soon.$extraTip',
        );
      }

      // Journey starts now (within 30 minutes)
      if (timeUntilJourney.inMinutes >= -30 &&
          timeUntilJourney.inMinutes <= 30) {
        await NotificationService.showJourneyStartNotification(
          journeyId: journey.id!,
          trainName: vehicleInfo,
          destinationCode: journey.destinationStationCode ??
              journey.destinationName ??
              'Destination',
        );
      }
    }
  }

  String _vehicleInfo(Journey journey) {
    if (journey.vehicleName != null && journey.vehicleName!.isNotEmpty) {
      return journey.vehicleName!;
    }
    if (journey.vehicleNumber != null && journey.vehicleNumber!.isNotEmpty) {
      return '${journey.transportType.label} ${journey.vehicleNumber}';
    }
    return journey.transportType.label;
  }

  void dispose() {
    stopPeriodicCheck();
  }
}
