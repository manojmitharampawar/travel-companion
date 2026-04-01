import 'package:flutter/cupertino.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/journey/journey_detail_screen.dart';

/// Helper function that returns the glass-styled Journey Details screen
/// for any transport type.
Widget getJourneyDetailScreen(EnrichedJourney enrichedJourney) {
  return JourneyDetailScreen(enrichedJourney: enrichedJourney);
}
