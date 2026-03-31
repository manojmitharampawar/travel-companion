import 'package:flutter/material.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/features/home/home_provider.dart';
import 'package:travel_companion/features/journey/train/train_journey_detail_screen.dart';
import 'package:travel_companion/features/journey/metro/metro_journey_detail_screen.dart';
import 'package:travel_companion/features/journey/bus/bus_journey_detail_screen.dart';
import 'package:travel_companion/features/journey/local_train/local_train_journey_detail_screen.dart';

/// Helper function to navigate to the appropriate journey detail screen
/// based on the transport type
Widget getJourneyDetailScreen(EnrichedJourney enrichedJourney) {
  final transportType = enrichedJourney.journey.transportType;
  
  return switch (transportType) {
    TransportType.train => TrainJourneyDetailScreen(enrichedJourney: enrichedJourney),
    TransportType.metro => MetroJourneyDetailScreen(enrichedJourney: enrichedJourney),
    TransportType.bus => BusJourneyDetailScreen(enrichedJourney: enrichedJourney),
    TransportType.localTrain => LocalTrainJourneyDetailScreen(enrichedJourney: enrichedJourney),
  };
}
