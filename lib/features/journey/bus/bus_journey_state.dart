import 'package:travel_companion/core/models/app_time.dart';
import 'package:travel_companion/core/services/routing_service.dart';
import 'package:travel_companion/data/models/location_point.dart';

class BusJourneyState {
  final String routeNumber;
  final String operatorName;
  final LocationPoint? origin;
  final LocationPoint? destination;
  final DateTime journeyDate;
  final AppTime? departureTime;
  final bool isDetectingLocation;
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

  final RouteResult? routeResult;
  final bool isFetchingRoute;

  final bool isCachingTiles;
  final int tileCacheProgress;
  final bool tilesCached;

  BusJourneyState({
    this.routeNumber = '',
    this.operatorName = '',
    this.origin,
    this.destination,
    DateTime? journeyDate,
    this.departureTime,
    this.isDetectingLocation = false,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
    this.routeResult,
    this.isFetchingRoute = false,
    this.isCachingTiles = false,
    this.tileCacheProgress = 0,
    this.tilesCached = false,
  }) : journeyDate = journeyDate ?? DateTime.now();

  BusJourneyState copyWith({
    String? routeNumber,
    String? operatorName,
    LocationPoint? origin,
    bool clearOrigin = false,
    LocationPoint? destination,
    bool clearDestination = false,
    DateTime? journeyDate,
    AppTime? departureTime,
    bool clearDepartureTime = false,
    bool? isDetectingLocation,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? savedSuccessfully,
    RouteResult? routeResult,
    bool clearRoute = false,
    bool? isFetchingRoute,
    bool? isCachingTiles,
    int? tileCacheProgress,
    bool? tilesCached,
  }) {
    return BusJourneyState(
      routeNumber: routeNumber ?? this.routeNumber,
      operatorName: operatorName ?? this.operatorName,
      origin: clearOrigin ? null : (origin ?? this.origin),
      destination: clearDestination ? null : (destination ?? this.destination),
      journeyDate: journeyDate ?? this.journeyDate,
      departureTime: clearDepartureTime
          ? null
          : (departureTime ?? this.departureTime),
      isDetectingLocation: isDetectingLocation ?? this.isDetectingLocation,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
      routeResult: clearRoute ? null : (routeResult ?? this.routeResult),
      isFetchingRoute: isFetchingRoute ?? this.isFetchingRoute,
      isCachingTiles: isCachingTiles ?? this.isCachingTiles,
      tileCacheProgress: tileCacheProgress ?? this.tileCacheProgress,
      tilesCached: tilesCached ?? this.tilesCached,
    );
  }
}
