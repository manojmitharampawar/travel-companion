import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_companion/core/models/app_time.dart';
import 'package:travel_companion/core/services/routing_service.dart';
import 'package:travel_companion/core/services/tile_cache_service.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';
import 'package:travel_companion/data/repositories/location_repository.dart';
import 'package:travel_companion/providers/app_providers.dart';
import 'package:travel_companion/features/journey/bus/bus_journey_state.dart';

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

class BusJourneyNotifier extends StateNotifier<BusJourneyState> {
  final JourneyRepository _journeyRepo;
  final LocationRepository _locationRepo;

  BusJourneyNotifier({
    required JourneyRepository journeyRepo,
    required LocationRepository locationRepo,
  }) : _journeyRepo = journeyRepo,
       _locationRepo = locationRepo,
       super(BusJourneyState());

  void setRouteNumber(String value) =>
      state = state.copyWith(routeNumber: value, clearError: true);

  void setOperatorName(String value) =>
      state = state.copyWith(operatorName: value);

  void setOrigin(LocationPoint? point) {
    if (point == null) {
      state = state.copyWith(clearOrigin: true, clearRoute: true);
    } else {
      state = state.copyWith(origin: point);
      _fetchRouteIfReady();
    }
  }

  void setDestination(LocationPoint? point) {
    if (point == null) {
      state = state.copyWith(clearDestination: true, clearRoute: true);
    } else {
      state = state.copyWith(destination: point);
      _fetchRouteIfReady();
    }
  }

  void swapLocations() {
    final o = state.origin;
    final d = state.destination;
    state = state.copyWith(
      origin: d,
      destination: o,
      clearOrigin: d == null,
      clearDestination: o == null,
      clearRoute: true,
    );
    _fetchRouteIfReady();
  }

  void setJourneyDate(DateTime d) => state = state.copyWith(journeyDate: d);

  void setDepartureTime(AppTime? t) => t == null
      ? state = state.copyWith(clearDepartureTime: true)
      : state = state.copyWith(departureTime: t);

  /// Auto-detect current GPS position and set as origin.
  Future<void> detectCurrentLocation() async {
    state = state.copyWith(isDetectingLocation: true, clearError: true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final point = LocationPoint(
        name: 'Current Location',
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      await _locationRepo.saveLocation(point);
      state = state.copyWith(origin: point, isDetectingLocation: false);
      _fetchRouteIfReady();
    } catch (_) {
      state = state.copyWith(
        isDetectingLocation: false,
        errorMessage: 'Could not detect location. Please enter manually.',
      );
    }
  }

  Future<List<LocationPoint>> searchLocations(String query) =>
      _locationRepo.searchLocations(query);

  /// Fetches the OSRM road route when both origin and destination are set.
  Future<void> _fetchRouteIfReady() async {
    final o = state.origin;
    final d = state.destination;
    if (o == null || d == null) return;

    state = state.copyWith(isFetchingRoute: true, clearRoute: true);
    try {
      final result = await RoutingService.fetchRoute(
        origin: LatLng(o.latitude, o.longitude),
        destination: LatLng(d.latitude, d.longitude),
      );
      if (mounted) {
        state = state.copyWith(routeResult: result, isFetchingRoute: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isFetchingRoute: false);
      }
    }
  }

  /// Pre-downloads map tiles for offline use along the route.
  Future<void> downloadMapForOffline() async {
    final route = state.routeResult;
    final o = state.origin;
    final d = state.destination;
    if (o == null || d == null) return;

    state = state.copyWith(
      isCachingTiles: true,
      tileCacheProgress: 0,
      tilesCached: false,
    );

    try {
      const tileUrl =
          'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

      if (route != null && route.isNotEmpty) {
        // Cache along the OSRM road route
        await TileCacheService.preDownloadRoute(
          routePoints: route.points,
          urlTemplate: tileUrl,
          minZoom: 10,
          maxZoom: 15,
          corridorPadding: 1,
          onProgress: (done, total) {
            if (mounted && total > 0) {
              state = state.copyWith(
                tileCacheProgress: ((done / total) * 100).round(),
              );
            }
          },
        );
      } else {
        // No route yet — cache around origin and destination
        await TileCacheService.preDownloadPoints(
          points: [
            LatLng(o.latitude, o.longitude),
            LatLng(d.latitude, d.longitude),
          ],
          urlTemplate: tileUrl,
          minZoom: 12,
          maxZoom: 16,
          padding: 2,
          onProgress: (done, total) {
            if (mounted && total > 0) {
              state = state.copyWith(
                tileCacheProgress: ((done / total) * 100).round(),
              );
            }
          },
        );
      }

      if (mounted) {
        state = state.copyWith(
          isCachingTiles: false,
          tileCacheProgress: 100,
          tilesCached: true,
        );
      }

      final cacheSize = await TileCacheService.getCacheSizeText();
      dev.log(
        'Tile cache complete. Total cache size: $cacheSize',
        name: 'BusJourney',
      );
    } catch (e) {
      dev.log('Tile caching failed: $e', name: 'BusJourney');
      if (mounted) {
        state = state.copyWith(
          isCachingTiles: false,
          errorMessage: 'Map download failed. Please try again.',
        );
      }
    }
  }

  /// Validates and persists the journey, then pre-caches map tiles.
  Future<void> save() async {
    final s = state;
    if (s.origin == null) {
      state = s.copyWith(errorMessage: 'Please set your boarding location');
      return;
    }
    if (s.destination == null) {
      state = s.copyWith(errorMessage: 'Please set your destination');
      return;
    }

    state = s.copyWith(isSaving: true, clearError: true);
    try {
      final journey = Journey(
        transportType: TransportType.bus,
        vehicleNumber: s.routeNumber.isEmpty ? null : s.routeNumber,
        vehicleName: s.operatorName.isEmpty ? null : s.operatorName,
        journeyDate: s.journeyDate,
        originLatitude: s.origin!.latitude,
        originLongitude: s.origin!.longitude,
        destinationLatitude: s.destination!.latitude,
        destinationLongitude: s.destination!.longitude,
        originName: s.origin!.name,
        destinationName: s.destination!.name,
        scheduledTime: s.departureTime == null
            ? null
            : '${s.departureTime!.hour.toString().padLeft(2, '0')}:${s.departureTime!.minute.toString().padLeft(2, '0')}',
        createdAt: DateTime.now(),
      );
      await _journeyRepo.insertJourney(journey);

      // Pre-cache map tiles in background, detached from notifier lifecycle.
      // This runs independently so disposing the notifier won't cause crashes.
      final routePoints = s.routeResult?.points ?? [];
      final originLatLng = LatLng(s.origin!.latitude, s.origin!.longitude);
      final destLatLng = LatLng(
        s.destination!.latitude,
        s.destination!.longitude,
      );
      TileCacheService.preDownloadRoute(
            routePoints: routePoints.isNotEmpty
                ? routePoints
                : [originLatLng, destLatLng],
            minZoom: 10,
            maxZoom: 15,
          )
          .then((_) {
            dev.log('Background tile pre-cache complete', name: 'BusJourney');
          })
          .catchError((e) {
            dev.log('Background tile pre-cache failed: $e', name: 'BusJourney');
          });

      state = state.copyWith(isSaving: false, savedSuccessfully: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save: $e',
      );
    }
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

final busJourneyNotifierProvider =
    StateNotifierProvider.autoDispose<BusJourneyNotifier, BusJourneyState>(
      (ref) => BusJourneyNotifier(
        journeyRepo: ref.read(journeyRepositoryProvider),
        locationRepo: ref.read(locationRepositoryProvider),
      ),
    );
