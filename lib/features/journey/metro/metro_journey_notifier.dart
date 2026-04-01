import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/models/app_time.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/metro_line.dart';
import 'package:travel_companion/data/models/metro_schedule.dart';
import 'package:travel_companion/data/models/metro_station.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';
import 'package:travel_companion/data/repositories/metro_repository.dart';
import 'package:travel_companion/providers/app_providers.dart';
import 'package:travel_companion/features/journey/metro/metro_journey_state.dart';

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

class MetroJourneyNotifier extends StateNotifier<MetroJourneyState> {
  final JourneyRepository _journeyRepo;
  final MetroRepository _metroRepo;

  MetroJourneyNotifier({
    required JourneyRepository journeyRepo,
    required MetroRepository metroRepo,
  }) : _journeyRepo = journeyRepo,
       _metroRepo = metroRepo,
       super(MetroJourneyState()) {
    loadCities();
  }

  Future<void> loadCities() async {
    state = state.copyWith(isLoadingCities: true);
    try {
      final cities = await _metroRepo.getCitiesWithMetro();
      state = state.copyWith(availableCities: cities, isLoadingCities: false);
    } catch (_) {
      state = state.copyWith(
        isLoadingCities: false,
        errorMessage: 'Failed to load cities',
      );
    }
  }

  Future<void> setCity(String city) async {
    state = state.copyWith(
      city: city,
      isLoadingLines: true,
      // Reset downstream
      clearSelectedLine: true,
      stationsOnLine: const [],
      clearSourceStation: true,
      clearDestStation: true,
      upcomingTrains: const [],
      clearSelectedTrain: true,
      clearError: true,
    );
    try {
      final lines = await _metroRepo.getLinesByCity(city);
      state = state.copyWith(availableLines: lines, isLoadingLines: false);
    } catch (_) {
      state = state.copyWith(
        isLoadingLines: false,
        errorMessage: 'Failed to load metro lines',
      );
    }
  }

  Future<void> selectLine(MetroLine line) async {
    state = state.copyWith(
      selectedLine: line,
      isLoadingStations: true,
      clearSourceStation: true,
      clearDestStation: true,
      upcomingTrains: const [],
      clearSelectedTrain: true,
      clearError: true,
    );
    try {
      final stations = await _metroRepo.getStationsByLine(line.id);
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

  void setSourceStation(MetroStation? station) {
    state = state.copyWith(
      sourceStation: station,
      clearSourceStation: station == null,
      upcomingTrains: const [],
      clearSelectedTrain: true,
      clearError: true,
    );
    _autoFetchSchedule();
  }

  void setDestStation(MetroStation? station) {
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
      state = state.copyWith(
        errorMessage: 'Source and destination must differ',
      );
      return;
    }

    state = state.copyWith(isLoadingSchedule: true, clearError: true);
    try {
      final now = AppTime.now();
      final trains = await _metroRepo.getUpcomingMetros(
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

  void selectTrain(UpcomingMetro train) {
    state = state.copyWith(selectedTrain: train, clearError: true);
  }

  void goBackToCitySelection() {
    state = MetroJourneyState(availableCities: state.availableCities);
  }

  void goBackToLineSelection() {
    state = state.copyWith(
      clearSelectedLine: true,
      stationsOnLine: const [],
      clearSourceStation: true,
      clearDestStation: true,
      upcomingTrains: const [],
      clearSelectedTrain: true,
    );
  }

  /// Save the selected metro train as a journey.
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
        transportType: TransportType.metro,
        vehicleNumber: train.lineCode,
        vehicleName: train.lineName,
        journeyDate: DateTime.now(),
        boardingStationCode: s.sourceStation!.code,
        destinationStationCode: s.destStation!.code,
        originLatitude: s.sourceStation!.latitude,
        originLongitude: s.sourceStation!.longitude,
        destinationLatitude: s.destStation!.latitude,
        destinationLongitude: s.destStation!.longitude,
        originName: s.sourceStation!.name,
        destinationName: s.destStation!.name,
        scheduledTime: scheduledTimeStr,
        createdAt: DateTime.now(),
      );
      await _journeyRepo.insertJourney(journey);
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

final metroJourneyNotifierProvider =
    StateNotifierProvider.autoDispose<MetroJourneyNotifier, MetroJourneyState>(
      (ref) => MetroJourneyNotifier(
        journeyRepo: ref.read(journeyRepositoryProvider),
        metroRepo: ref.read(metroRepositoryProvider),
      ),
    );
