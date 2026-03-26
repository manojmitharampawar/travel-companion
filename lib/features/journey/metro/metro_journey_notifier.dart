import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';
import 'package:travel_companion/data/repositories/station_repository.dart';
import 'package:travel_companion/providers/app_providers.dart';

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

class MetroJourneyState {
  final String lineName;
  final Station? boardingStation;
  final Station? destinationStation;
  final DateTime journeyDate;
  final TimeOfDay? departureTime;
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

  MetroJourneyState({
    this.lineName = '',
    this.boardingStation,
    this.destinationStation,
    DateTime? journeyDate,
    this.departureTime,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  }) : journeyDate = journeyDate ?? DateTime.now();

  MetroJourneyState copyWith({
    String? lineName,
    Station? boardingStation,
    bool clearBoardingStation = false,
    Station? destinationStation,
    bool clearDestinationStation = false,
    DateTime? journeyDate,
    TimeOfDay? departureTime,
    bool clearDepartureTime = false,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? savedSuccessfully,
  }) {
    return MetroJourneyState(
      lineName: lineName ?? this.lineName,
      boardingStation: clearBoardingStation ? null : (boardingStation ?? this.boardingStation),
      destinationStation:
          clearDestinationStation ? null : (destinationStation ?? this.destinationStation),
      journeyDate: journeyDate ?? this.journeyDate,
      departureTime: clearDepartureTime ? null : (departureTime ?? this.departureTime),
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────

class MetroJourneyNotifier extends StateNotifier<MetroJourneyState> {
  final JourneyRepository _journeyRepo;
  final StationRepository _stationRepo;

  MetroJourneyNotifier({
    required JourneyRepository journeyRepo,
    required StationRepository stationRepo,
  })  : _journeyRepo = journeyRepo,
        _stationRepo = stationRepo,
        super(MetroJourneyState());

  void setLineName(String value) =>
      state = state.copyWith(lineName: value, clearError: true);

  void setBoardingStation(Station? s) => s == null
      ? state = state.copyWith(clearBoardingStation: true)
      : state = state.copyWith(boardingStation: s);

  void setDestinationStation(Station? s) => s == null
      ? state = state.copyWith(clearDestinationStation: true)
      : state = state.copyWith(destinationStation: s);

  void setJourneyDate(DateTime d) => state = state.copyWith(journeyDate: d);

  void setDepartureTime(TimeOfDay? t) => t == null
      ? state = state.copyWith(clearDepartureTime: true)
      : state = state.copyWith(departureTime: t);

  Future<List<Station>> searchMetroStations(String query) =>
      _stationRepo.searchMetroStations(query);

  /// Validates and persists the journey.
  Future<void> save() async {
    final s = state;
    if (s.boardingStation == null) {
      state = s.copyWith(errorMessage: 'Please select boarding station');
      return;
    }
    if (s.destinationStation == null) {
      state = s.copyWith(errorMessage: 'Please select destination station');
      return;
    }
    if (s.boardingStation!.code == s.destinationStation!.code) {
      state = s.copyWith(errorMessage: 'Boarding and destination must differ');
      return;
    }

    state = s.copyWith(isSaving: true, clearError: true);
    try {
      final journey = Journey(
        transportType: TransportType.metro,
        vehicleNumber: s.lineName.isEmpty ? null : s.lineName,
        journeyDate: s.journeyDate,
        boardingStationCode: s.boardingStation!.code,
        destinationStationCode: s.destinationStation!.code,
        originLatitude: s.boardingStation!.latitude,
        originLongitude: s.boardingStation!.longitude,
        destinationLatitude: s.destinationStation!.latitude,
        destinationLongitude: s.destinationStation!.longitude,
        originName: s.boardingStation!.name,
        destinationName: s.destinationStation!.name,
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

final metroJourneyNotifierProvider =
    StateNotifierProvider.autoDispose<MetroJourneyNotifier, MetroJourneyState>(
  (ref) => MetroJourneyNotifier(
    journeyRepo: ref.read(journeyRepositoryProvider),
    stationRepo: ref.read(stationRepositoryProvider),
  ),
);
