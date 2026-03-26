import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/data/datasources/remote/train_status_api.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';
import 'package:travel_companion/data/repositories/station_repository.dart';
import 'package:travel_companion/data/repositories/train_repository.dart';
import 'package:travel_companion/providers/app_providers.dart';

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

class TrainJourneyState {
  final String pnr;
  final String trainNumber;
  final String trainName;
  final Station? boardingStation;
  final Station? destinationStation;
  final DateTime journeyDate;
  final String? travelClass;
  final String berth;
  final bool isAutoFilling;
  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

  TrainJourneyState({
    this.pnr = '',
    this.trainNumber = '',
    this.trainName = '',
    this.boardingStation,
    this.destinationStation,
    DateTime? journeyDate,
    this.travelClass,
    this.berth = '',
    this.isAutoFilling = false,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  }) : journeyDate = journeyDate ?? DateTime.now().add(const Duration(days: 1));

  TrainJourneyState copyWith({
    String? pnr,
    String? trainNumber,
    String? trainName,
    Station? boardingStation,
    bool clearBoardingStation = false,
    Station? destinationStation,
    bool clearDestinationStation = false,
    DateTime? journeyDate,
    String? travelClass,
    bool clearTravelClass = false,
    String? berth,
    bool? isAutoFilling,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? savedSuccessfully,
  }) {
    return TrainJourneyState(
      pnr: pnr ?? this.pnr,
      trainNumber: trainNumber ?? this.trainNumber,
      trainName: trainName ?? this.trainName,
      boardingStation: clearBoardingStation ? null : (boardingStation ?? this.boardingStation),
      destinationStation:
          clearDestinationStation ? null : (destinationStation ?? this.destinationStation),
      journeyDate: journeyDate ?? this.journeyDate,
      travelClass: clearTravelClass ? null : (travelClass ?? this.travelClass),
      berth: berth ?? this.berth,
      isAutoFilling: isAutoFilling ?? this.isAutoFilling,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────

class TrainJourneyNotifier extends StateNotifier<TrainJourneyState> {
  final JourneyRepository _journeyRepo;
  final StationRepository _stationRepo;
  final TrainRepository _trainRepo;
  final TrainStatusApi _trainApi;

  TrainJourneyNotifier({
    required JourneyRepository journeyRepo,
    required StationRepository stationRepo,
    required TrainRepository trainRepo,
    required TrainStatusApi trainApi,
  })  : _journeyRepo = journeyRepo,
        _stationRepo = stationRepo,
        _trainRepo = trainRepo,
        _trainApi = trainApi,
        super(TrainJourneyState());

  void setPnr(String value) => state = state.copyWith(pnr: value, clearError: true);
  void setTrainName(String value) => state = state.copyWith(trainName: value);
  void setBoardingStation(Station? s) => s == null
      ? state = state.copyWith(clearBoardingStation: true)
      : state = state.copyWith(boardingStation: s);
  void setDestinationStation(Station? s) => s == null
      ? state = state.copyWith(clearDestinationStation: true)
      : state = state.copyWith(destinationStation: s);
  void setJourneyDate(DateTime d) => state = state.copyWith(journeyDate: d);
  void setTravelClass(String? c) =>
      c == null ? state = state.copyWith(clearTravelClass: true) : state = state.copyWith(travelClass: c);
  void setBerth(String value) => state = state.copyWith(berth: value);

  /// Updates the train number and auto-fills name + endpoints when possible.
  Future<void> setTrainNumber(String value) async {
    state = state.copyWith(trainNumber: value, clearError: true);

    if (value.length < 4) return;

    state = state.copyWith(isAutoFilling: true);
    try {
      // 1. Try local DB first (fast)
      final localName = await _trainRepo.getTrainNameByNumber(value);
      if (localName != null && state.trainName.isEmpty) {
        state = state.copyWith(trainName: localName);
      }

      // 2. Auto-fill endpoints if not yet set
      if (state.boardingStation == null || state.destinationStation == null) {
        final endpoints = await _trainRepo.getTrainEndpoints(value);
        if (endpoints != null) {
          if (state.boardingStation == null) {
            final from = await _stationRepo.getStationByCode(endpoints['from_station']!);
            if (from != null) state = state.copyWith(boardingStation: from);
          }
          if (state.destinationStation == null) {
            final to = await _stationRepo.getStationByCode(endpoints['to_station']!);
            if (to != null) state = state.copyWith(destinationStation: to);
          }
        }
      }

      // 3. Fallback to remote API for 5-digit numbers with no local match
      if (value.length == 5 && state.trainName.isEmpty) {
        final details = await _trainApi.getTrainDetails(value);
        final remoteName = details?['train_name'] as String?;
        if (remoteName != null && remoteName.isNotEmpty) {
          state = state.copyWith(trainName: remoteName);
        }
      }
    } catch (_) {
      // Auto-fill is best-effort; ignore errors
    } finally {
      state = state.copyWith(isAutoFilling: false);
    }
  }

  Future<List<Station>> searchStations(String query) =>
      _stationRepo.searchStations(query);

  /// Validates and persists the journey.
  Future<void> save() async {
    final s = state;
    if (s.trainNumber.isEmpty) {
      state = s.copyWith(errorMessage: 'Train number is required');
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
        transportType: TransportType.train,
        pnr: s.pnr.isEmpty ? null : s.pnr,
        vehicleNumber: s.trainNumber,
        vehicleName: s.trainName.isEmpty ? null : s.trainName,
        journeyDate: s.journeyDate,
        boardingStationCode: s.boardingStation!.code,
        destinationStationCode: s.destinationStation!.code,
        originLatitude: s.boardingStation!.latitude,
        originLongitude: s.boardingStation!.longitude,
        destinationLatitude: s.destinationStation!.latitude,
        destinationLongitude: s.destinationStation!.longitude,
        originName: s.boardingStation!.name,
        destinationName: s.destinationStation!.name,
        travelClass: s.travelClass,
        berth: s.berth.isEmpty ? null : s.berth,
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

final trainJourneyNotifierProvider =
    StateNotifierProvider.autoDispose<TrainJourneyNotifier, TrainJourneyState>(
  (ref) => TrainJourneyNotifier(
    journeyRepo: ref.read(journeyRepositoryProvider),
    stationRepo: ref.read(stationRepositoryProvider),
    trainRepo: ref.read(trainRepositoryProvider),
    trainApi: ref.read(trainStatusApiProvider),
  ),
);
