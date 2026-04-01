import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/features/history/application/history_journey_queries.dart';
import 'package:travel_companion/providers/app_providers.dart';

class ToggleFavoriteJourneyAction {
  const ToggleFavoriteJourneyAction._();

  static Future<void> execute({
    required WidgetRef ref,
    required int journeyId,
    required bool isFavorite,
  }) async {
    await ref
        .read(journeyRepositoryProvider)
        .toggleFavorite(journeyId, isFavorite);
    ref.invalidate(historyJourneysProvider);
    ref.invalidate(favoriteJourneysProvider);
  }
}
