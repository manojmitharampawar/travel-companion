import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/metro_line.dart';
import 'package:travel_companion/data/models/metro_station.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';
import 'package:travel_companion/data/repositories/metro_repository.dart';
import 'package:travel_companion/providers/app_providers.dart';

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

class MetroJourneyState {
  final String city;
  final String lineName;
  final MetroLine? selectedLine;
  final MetroStation? boardingStation;
  final MetroStation? destinationStation;
  final DateTime journeyDate;
  final TimeOfDay? departureTime;
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;
  
  // New fields for metro-specific data
  final List<String> availableCities;
  final List<MetroLine> availableLines;
  final List<MetroStation> stationsOnLine;
  final bool isLoadingCities;
  final bool isLoadingLines;
  final bool isLoadingStations;

  MetroJourneyState({
    this.city = '',
    this.lineName = '',
    this.selectedLine,
    this.boardingStation,
    this.destinationStation,
    DateTime? journeyDate,
    this.departureTime,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
    this.availableCities = const [],
    this.availableLines = const [],
    this.stationsOnLine = const [],
    this.isLoadingCities = false,
    this.isLoadingLines = false,
    this.isLoadingStations = false,
  }) : journeyDate = journeyDate ?? DateTime.now();

  MetroJourneyState copyWith({
    String? city,
    String? lineName,
    MetroLine? selectedLine,
    bool clearSelectedLine = false,
    MetroStation? boardingStation,
    bool clearBoardingStation = false,
    MetroStation? destinationStation,
    bool clearDestinationStation = false,
    DateTime? journeyDate,
    TimeOfDay? departureTime,
    bool clearDepartureTime = false,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? savedSuccessfully,
    List<String>? availableCities,
    List<MetroLine>? availableLines,
    List<MetroStation>? stationsOnLine,
    bool? isLoadingCities,
    bool? isLoadingLines,
    bool? isLoadingStations,
  }) {
    return MetroJourneyState(
      city: city ?? this.city,
      lineName: lineName ?? this.lineName,
      selectedLine: clearSelectedLine ? null : (selectedLine ?? this.selectedLine),
      boardingStation: clearBoardingStation ? null : (boardingStation ?? this.boardingStation),
      destinationStation: clearDestinationStation ? null : (destinationStation ?? this.destinationStation),
      journeyDate: journeyDate ?? this.journeyDate,
      departureTime: clearDepartureTime ? null : (departureTime ?? this.departureTime),
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
      availableCities: availableCities ?? this.availableCities,
      availableLines: availableLines ?? this.availableLines,
      stationsOnLine: stationsOnLine ?? this.stationsOnLine,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isLoadingLines: isLoadingLines ?? this.isLoadingLines,
      isLoadingStations: isLoadingStations ?? this.isLoadingStations,
    );
  }
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────

class MetroJourneyNotifier extends StateNotifier<MetroJourneyState> {
  final JourneyRepository _journeyRepo;
  final MetroRepository _metroRepo;

  MetroJourneyNotifier({
    required JourneyRepository journeyRepo,
    required MetroRepository metroRepo,
  })  : _journeyRepo = journeyRepo,
        _metroRepo = metroRepo,
        super(MetroJourneyState());

  /// Load available cities with metro systems
  Future<void> loadCities() async {
    state = state.copyWith(isLoadingCities: true);
    try {
      final cities = await _metroRepo.getCitiesWithMetro();
      state = state.copyWith(
        availableCities: cities,
        isLoadingCities: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingCities: false,
        errorMessage: 'Failed to load cities',
      );
    }
  }

  /// Set selected city and load its metro lines
  Future<void> setCity(String city) async {
    state = state.copyWith(
      city: city,
      clearSelectedLine: true,
      clearBoardingStation: true,
      clearDestinationStation: true,
      clearError: true,
    );
    await loadLinesForCity(city);
  }

  Future<void> loadLinesForCity(String city) async {
    state = state.copyWith(isLoadingLines: true);
    try {
      final lines = await _metroRepo.getLinesByCity(city);
      state = state.copyWith(
        availableLines: lines,
        isLoadingLines: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingLines: false,
        errorMessage: 'Failed to load metro lines',
      );
    }
  }

  /// Select a metro line and load its stations
  Future<void> selectLine(MetroLine line) async {
    state = state.copyWith(
      selectedLine: line,
      lineName: line.displayName,
      clearBoardingStation: true,
      clearDestinationStation: true,
    );
    await loadStationsForLine(line.id);
  }

  Future<void> loadStationsForLine(int lineId) async {
    state = state.copyWith(isLoadingStations: true);
    try {
      final stations = await _metroRepo.getStationsByLine(lineId);
      state = state.copyWith(
        stationsOnLine: stations,
        isLoadingStations: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingStations: false,
        errorMessage: 'Failed to load stations',
      );
    }
  }

  void setBoardingStation(MetroStation? station) {
    state = state.copyWith(
      boardingStation: station,
      // Clear destination if before or same as boarding
      clearDestinationStation: station != null && 
          state.destinationStation != null &&
          state.destinationStation!.stationIndex <= station.stationIndex,
    );
  }

  void setDestinationStation(MetroStation? station) {
    state = state.copyWith(destinationStation: station);
  }

  void setJourneyDate(DateTime d) => state = state.copyWith(journeyDate: d);

  void setDepartureTime(TimeOfDay? t) => t == null
      ? state = state.copyWith(clearDepartureTime: true)
      : state = state.copyWith(departureTime: t);

  /// Validates and persists the journey.
  Future<void> save() async {
    final s = state;
    if (s.city.isEmpty) {
      state = s.copyWith(errorMessage: 'Please select a city');
      return;
    }
    if (s.selectedLine == null) {
      state = s.copyWith(errorMessage: 'Please select a metro line');
      return;
    }
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
        vehicleNumber: s.selectedLine!.lineCode ?? s.selectedLine!.id.toString(),
        vehicleName: s.selectedLine!.displayName,
        journeyDate: s.journeyDate,
        boardingStationCode: s.boardingStation!.code,
        destinationStationCode: s.destinationStation!.code,
        originLatitude: s.boardingStation!.latitude,
        originLongitude: s.boardingStation!.longitude,
        destinationLatitude: s.destinationStation!.latitude,
        destinationLongitude: s.destinationStation!.longitude,
        originName: s.boardingStation!.name,
        destinationName: s.destinationStation!.name,
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
    metroRepo: ref.read(metroRepositoryProvider),
  ),
);
