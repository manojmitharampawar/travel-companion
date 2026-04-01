import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/ui/adaptive_feedback.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/features/history/application/history_journey_queries.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/journey/widgets/journey_detail_shared_widgets.dart';
import 'package:travel_companion/providers/app_providers.dart';

class JourneyDetailActions {
  const JourneyDetailActions._();

  static Future<bool> toggleFavorite({
    required WidgetRef ref,
    required Journey journey,
    required bool currentValue,
  }) async {
    final id = journey.id;
    if (id == null) {
      return currentValue;
    }

    final nextValue = !currentValue;
    await ref.read(journeyRepositoryProvider).toggleFavorite(id, nextValue);
    _invalidateJourneyCollections(ref);
    return nextValue;
  }

  static Future<void> showJourneyActions({
    required BuildContext context,
    required WidgetRef ref,
    required Journey journey,
    required String cancelLabel,
  }) async {
    final selectedAction = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext, 'cancel'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.xmark_circle, size: 18),
                  const SizedBox(width: 8),
                  Text(cancelLabel),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(sheetContext, 'delete'),
              child: const Text('Delete'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Dismiss'),
          ),
        );
      },
    );

    if (!context.mounted || selectedAction == null) {
      return;
    }

    if (selectedAction == 'delete') {
      await _deleteJourney(context: context, ref: ref, journey: journey);
      return;
    }
    if (selectedAction == 'cancel') {
      await _cancelJourney(context: context, ref: ref, journey: journey);
    }
  }

  static Future<void> _deleteJourney({
    required BuildContext context,
    required WidgetRef ref,
    required Journey journey,
  }) async {
    try {
      final confirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return GlassConfirmDialog(
            title: 'Delete Journey?',
            message: 'This action cannot be undone.',
            confirmLabel: 'Delete',
            confirmColor: const Color(0xFFE74C3C),
            onConfirm: () => Navigator.pop(dialogContext, true),
            onCancel: () => Navigator.pop(dialogContext, false),
          );
        },
      );

      if (confirm != true) {
        return;
      }

      await ref.read(journeyRepositoryProvider).deleteJourney(journey.id!);
      _invalidateJourneyCollections(ref);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (context.mounted) {
        AdaptiveFeedback.showToast(context, 'Error: $error', isError: true);
      }
    }
  }

  static Future<void> _cancelJourney({
    required BuildContext context,
    required WidgetRef ref,
    required Journey journey,
  }) async {
    await ref
        .read(journeyRepositoryProvider)
        .updateJourneyStatus(journey.id!, JourneyStatus.cancelled);

    _invalidateJourneyCollections(ref);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  static void _invalidateJourneyCollections(WidgetRef ref) {
    ref.invalidate(upcomingJourneysProvider);
    ref.invalidate(historyJourneysProvider);
    ref.invalidate(favoriteJourneysProvider);
  }
}
