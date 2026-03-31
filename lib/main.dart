import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/app.dart';
import 'package:travel_companion/core/services/notification_service.dart';
import 'package:travel_companion/core/services/journey_reminder_service.dart';
import 'package:travel_companion/core/services/repeat_journey_service.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  final journeyRepo = JourneyRepository();

  // Start journey reminder service for pre-journey notifications
  final reminderService = JourneyReminderService(
    journeyRepository: journeyRepo,
  );
  reminderService.startPeriodicCheck();

  // Start repeat journey service to auto-create daily instances
  final repeatService = RepeatJourneyService(
    journeyRepository: journeyRepo,
  );
  repeatService.start();

  runApp(const ProviderScope(child: TravelCompanionApp()));
}
