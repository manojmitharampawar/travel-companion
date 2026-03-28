import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/local_train_line.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';
import 'package:travel_companion/data/repositories/local_train_repository.dart';
import 'package:travel_companion/providers/app_providers.dart';

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

class LocalTrainJourneyState {
  // Step 1: line selection
  final List<LocalTrainLine> availableLines;
  final LocalTrainLine? selectedLine;
  final bool isLoadingLines;

  // Step 2: station selection
  final List<LocalTrainStation> lineStations;
  final LocalTrainStation? sourceStation;
  final LocalTrainStation? destStation;
  final bool isLoadingStations;

  // Step 3: schedule results
  final List<UpcomingTrain> upcomingTrains;
  final bool isLoadingSchedule;
  final UpcomingTrain? selectedTrain;

  // Step 4: optional extras
  final String? travelClass;

  // Status
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

  LocalTrainJourneyState({
    this.availableLines = const [],
    this.selectedLine,
    this.isLoadingLines = false,
    this.lineStations = const [],
    this.sourceStation,
    this.destStation,
    this.isLoadingStations = false,
    this.upcomingTrains = const [],
    this.isLoadingSchedule = false,
    this.selectedTrain,
    this.travelClass,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  LocalTrainJourneyState copyWith({
    List<LocalTrainLine>? availableLines,
    LocalTrainLine? selectedLine,
    bool clearSelectedLine = false,
    bool? isLoadingLines,
    List<LocalTrainStation>? lineStations,
    LocalTrainStation? sourceStation,
    bool clearSourceStation = false,
    LocalTrainStation? destStation,
    bool clearDestStation = false,
    bool? isLoadingStations,
    List<UpcomingTrain>? upcomingTrains,
    bool? isLoadingSchedule,
    UpcomingTrain? selectedTrain,
    bool clearSelectedTrain = false,
    String? travelClass,
    bool clearTravelClass = false,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? savedSuccessfully,
  }) {
    return LocalTrainJourneyState(
      availableLines: availableLines ?? this.availableLines,
      selectedLine: clearSelectedLine ? null : (selectedLine ?? this.selectedLine),
      isLoadingLines: isLoadingLines ?? this.isLoadingLines,
      lineStations: lineStations ?? this.lineStations,
      sourceStation: clearSourceStation ? null : (sourceStation ?? this.sourceStation),
      destStation: clearDestStation ? null : (destStation ?? this.destStation),
      isLoadingStations: isLoadingStations ?? this.isLoadingStations,
      upcomingTrains: upcomingTrains ?? this.upcomingTrains,
      isLoadingSchedule: isLoadingSchedule ?? this.isLoadingSchedule,
      selectedTrain: clearSelectedTrain ? null : (selectedTrain ?? this.selectedTrain),
      travelClass: clearTravelClass ? null : (travelClass ?? this.travelClass),
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }

  /// Current step in the flow (0-indexed).
  int get currentStep {
    if (selectedLine == null) return 0;
    if (sourceStation == null || destStation == null) return 1;
    return 2;
  }
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────

class LocalTrainJourneyNotifier extends StateNotifier<LocalTrainJourneyState> {
  final JourneyRepository _journeyRepo;
  final LocalTrainRepository _localTrainRepo;

  LocalTrainJourneyNotifier({
    required JourneyRepository journeyRepo,
    required LocalTrainRepository localTrainRepo,
  })  : _journeyRepo = journeyRepo,
        _localTrainRepo = localTrainRepo,
        super(LocalTrainJourneyState()) {
    _loadLines();
  }

  Future<void> _loadLines() async {
    state = state.copyWith(isLoadingLines: true);
    try {
      final lines = await _localTrainRepo.getLines();
      state = state.copyWith(availableLines: lines, isLoadingLines: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingLines: false,
        errorMessage: 'Failed to load lines: $e',
      );
    }
  }

  Future<void> selectLine(LocalTrainLine line) async {
    state = state.copyWith(
      selectedLine: line,
      isLoadingStations: true,
      // Reset downstream
      clearSourceStation: true,
      clearDestStation: true,
      upcomingTrains: const [],
      clearSelectedTrain: true,
      clearError: true,
    );
    try {
      final stations = await _localTrainRepo.getStationsForLine(line.id);
      state = state.copyWith(lineStations: stations, isLoadingStations: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingStations: false,
        errorMessage: 'Failed to load stations: $e',
      );
    }
  }

  void setSourceStation(LocalTrainStation? station) {
    state = state.copyWith(
      sourceStation: station,
      clearSourceStation: station == null,
      upcomingTrains: const [],
      clearSelectedTrain: true,
      clearError: true,
    );
    _autoFetchSchedule();
  }

  void setDestStation(LocalTrainStation? station) {
    state = state.copyWith(
      destStation: station,
      clearDestStation: station == null,
      upcomingTrains: const [],
      clearSelectedTrain: true,
      clearError: true,
    );
    _autoFetchSchedule();
  }

  void swapStations() {
    final src = state.sourceStation;
    final dst = state.destStation;
    state = state.copyWith(
      sourceStation: dst,
      clearSourceStation: dst == null,
      destStation: src,
      clearDestStation: src == null,
      upcomingTrains: const [],
      clearSelectedTrain: true,
    );
    _autoFetchSchedule();
  }

  void _autoFetchSchedule() {
    if (state.sourceStation != null && state.destStation != null) {
      fetchUpcomingTrains();
    }
  }

  Future<void> fetchUpcomingTrains() async {
    final src = state.sourceStation;
    final dst = state.destStation;
    if (src == null || dst == null || state.selectedLine == null) return;
    if (src.code == dst.code) {
      state = state.copyWith(errorMessage: 'Source and destination must differ');
      return;
    }

    state = state.copyWith(isLoadingSchedule: true, clearError: true);
    try {
      final now = TimeOfDay.now();
      final trains = await _localTrainRepo.getUpcomingTrains(
        lineId: state.selectedLine!.id,
        sourceIndex: src.stationIndex,
        destIndex: dst.stationIndex,
        after: now,
        limit: 15,
      );
      state = state.copyWith(upcomingTrains: trains, isLoadingSchedule: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingSchedule: false,
        errorMessage: 'Failed to load schedule: $e',
      );
    }
  }

  void selectTrain(UpcomingTrain train) {
    state = state.copyWith(selectedTrain: train, clearError: true);
  }

  void setTravelClass(String? c) => c == null
      ? state = state.copyWith(clearTravelClass: true)
      : state = state.copyWith(travelClass: c);

  void goBackToLineSelection() {
    state = state.copyWith(
      clearSelectedLine: true,
      lineStations: const [],
      clearSourceStation: true,
      clearDestStation: true,
      upcomingTrains: const [],
      clearSelectedTrain: true,
    );
  }

  void goBackToStationSelection() {
    state = state.copyWith(
      upcomingTrains: const [],
      clearSelectedTrain: true,
    );
  }

  /// Save the selected train as a journey.
  Future<void> save() async {
    final s = state;
    if (s.sourceStation == null || s.destStation == null) {
      state = s.copyWith(errorMessage: 'Please select source and destination');
      return;
    }
    if (s.selectedTrain == null) {
      state = s.copyWith(errorMessage: 'Please select a train');
      return;
    }

    state = s.copyWith(isSaving: true, clearError: true);
    try {
      final train = s.selectedTrain!;
      final dep = train.departureAtSource;
      final scheduledTimeStr =
          '${dep.hour.toString().padLeft(2, '0')}:${dep.minute.toString().padLeft(2, '0')}';

      final journey = Journey(
        transportType: TransportType.localTrain,
        vehicleNumber: '${train.lineCode}-${train.trainType}',
        vehicleName: '${train.lineName} (${train.trainTypeLabel})',
        journeyDate: DateTime.now(),
        boardingStationCode: s.sourceStation!.code,
        destinationStationCode: s.destStation!.code,
        originLatitude: s.sourceStation!.latitude,
        originLongitude: s.sourceStation!.longitude,
        destinationLatitude: s.destStation!.latitude,
        destinationLongitude: s.destStation!.longitude,
        originName: s.sourceStation!.name,
        destinationName: s.destStation!.name,
        travelClass: s.travelClass,
        scheduledTime: scheduledTimeStr,
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

final localTrainJourneyNotifierProvider =
    StateNotifierProvider.autoDispose<LocalTrainJourneyNotifier, LocalTrainJourneyState>(
  (ref) => LocalTrainJourneyNotifier(
    journeyRepo: ref.read(journeyRepositoryProvider),
    localTrainRepo: ref.read(localTrainRepositoryProvider),
  ),
);
