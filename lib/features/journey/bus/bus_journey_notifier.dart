import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';
import 'package:travel_companion/data/repositories/location_repository.dart';
import 'package:travel_companion/providers/app_providers.dart';

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

class BusJourneyState {
  final String routeNumber;
  final String operatorName;
  final LocationPoint? origin;
  final LocationPoint? destination;
  final DateTime journeyDate;
  final TimeOfDay? departureTime;
  final bool isDetectingLocation;
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

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
  }) : journeyDate = journeyDate ?? DateTime.now();

  BusJourneyState copyWith({
    String? routeNumber,
    String? operatorName,
    LocationPoint? origin,
    bool clearOrigin = false,
    LocationPoint? destination,
    bool clearDestination = false,
    DateTime? journeyDate,
    TimeOfDay? departureTime,
    bool clearDepartureTime = false,
    bool? isDetectingLocation,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? savedSuccessfully,
  }) {
    return BusJourneyState(
      routeNumber: routeNumber ?? this.routeNumber,
      operatorName: operatorName ?? this.operatorName,
      origin: clearOrigin ? null : (origin ?? this.origin),
      destination: clearDestination ? null : (destination ?? this.destination),
      journeyDate: journeyDate ?? this.journeyDate,
      departureTime: clearDepartureTime ? null : (departureTime ?? this.departureTime),
      isDetectingLocation: isDetectingLocation ?? this.isDetectingLocation,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────

class BusJourneyNotifier extends StateNotifier<BusJourneyState> {
  final JourneyRepository _journeyRepo;
  final LocationRepository _locationRepo;

  BusJourneyNotifier({
    required JourneyRepository journeyRepo,
    required LocationRepository locationRepo,
  })  : _journeyRepo = journeyRepo,
        _locationRepo = locationRepo,
        super(BusJourneyState());

  void setRouteNumber(String value) =>
      state = state.copyWith(routeNumber: value, clearError: true);

  void setOperatorName(String value) => state = state.copyWith(operatorName: value);

  void setOrigin(LocationPoint? point) => point == null
      ? state = state.copyWith(clearOrigin: true)
      : state = state.copyWith(origin: point);

  void setDestination(LocationPoint? point) => point == null
      ? state = state.copyWith(clearDestination: true)
      : state = state.copyWith(destination: point);

  void setJourneyDate(DateTime d) => state = state.copyWith(journeyDate: d);

  void setDepartureTime(TimeOfDay? t) => t == null
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LocationPoint(
        name: 'Current Location',
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      // Save to recents for future use
      await _locationRepo.saveLocation(point);
      state = state.copyWith(origin: point, isDetectingLocation: false);
    } catch (_) {
      state = state.copyWith(
        isDetectingLocation: false,
        errorMessage: 'Could not detect location. Please enter manually.',
      );
    }
  }

  Future<List<LocationPoint>> searchLocations(String query) =>
      _locationRepo.searchLocations(query);

  /// Validates and persists the journey.
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
      state = state.copyWith(isSaving: false, savedSuccessfully: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save: $e');
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
