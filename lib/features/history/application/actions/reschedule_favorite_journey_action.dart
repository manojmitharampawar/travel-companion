import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_companion/core/services/journey_reschedule_service.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/features/history/application/history_journey_queries.dart';
import 'package:travel_companion/features/history/widgets/journey_reschedule_dialog.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/providers/app_providers.dart';

class RescheduleFavoriteJourneyAction {
  const RescheduleFavoriteJourneyAction._();

  static Future<void> execute({
    required BuildContext context,
    required WidgetRef ref,
    required EnrichedJourney enrichedJourney,
  }) async {
    final result = await showCupertinoDialog<(DateTime, DateTime)>(
      context: context,
      builder: (_) => JourneyRescheduleDialog(
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 120)),
        initialTime: _parseScheduledTime(enrichedJourney.journey.scheduledTime),
      ),
    );

    if (result == null) {
      return;
    }

    final (selectedDate, selectedTime) = result;

    try {
      final service = JourneyRescheduleService(
        journeyRepository: ref.read(journeyRepositoryProvider),
      );

      await service.rescheduleJourney(
        journey: enrichedJourney.journey,
        selectedDate: selectedDate,
        selectedTime: selectedTime,
      );

      ref.invalidate(upcomingJourneysProvider);
      ref.invalidate(favoriteJourneysProvider);

      if (context.mounted) {
        AdaptiveFeedback.showToast(
          context,
          'Journey rescheduled to ${DateFormat('dd MMM yyyy').format(selectedDate)} at ${DateFormat('hh:mm a').format(selectedTime)}',
        );
      }
    } catch (_) {
      if (context.mounted) {
        AdaptiveFeedback.showToast(
          context,
          'Error: Could not reschedule journey',
          isError: true,
        );
      }
    }
  }

  static DateTime? _parseScheduledTime(String? scheduledTime) {
    if (scheduledTime == null || scheduledTime.isEmpty) {
      return null;
    }

    try {
      final parts = scheduledTime.split(':');
      if (parts.length != 2) {
        return null;
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }

      return DateTime(0, 1, 1, hour, minute);
    } catch (_) {
      return null;
    }
  }
}
