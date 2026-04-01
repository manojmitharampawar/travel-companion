import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/data/datasources/remote/train_status_api.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';
import 'package:travel_companion/data/repositories/station_repository.dart';
import 'package:travel_companion/data/repositories/train_repository.dart';
import 'package:travel_companion/providers/app_providers.dart';
import 'package:travel_companion/features/journey/train/train_journey_state.dart';

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

class TrainJourneyNotifier extends StateNotifier<TrainJourneyState> {
  final JourneyRepository _journeyRepo;
  final StationRepository _stationRepo;
  final TrainRepository _trainRepo;
  final TrainStatusApi _trainApi;

  /// Debounce timer for train number input to avoid excessive API calls.
  /// Waits 600ms after user stops typing before fetching.
  Timer? _trainNumberDebounceTimer;

  TrainJourneyNotifier({
    required JourneyRepository journeyRepo,
    required StationRepository stationRepo,
    required TrainRepository trainRepo,
    required TrainStatusApi trainApi,
  }) : _journeyRepo = journeyRepo,
       _stationRepo = stationRepo,
       _trainRepo = trainRepo,
       _trainApi = trainApi,
       super(TrainJourneyState());

  @override
  void dispose() {
    _trainNumberDebounceTimer?.cancel();
    super.dispose();
  }

  void setPnr(String value) =>
      state = state.copyWith(pnr: value, clearError: true);
  void setTrainName(String value) => state = state.copyWith(trainName: value);

  void setBoardingStation(Station? s) => s == null
      ? state = state.copyWith(clearBoardingStation: true)
      : state = state.copyWith(boardingStation: s);

  void setDestinationStation(Station? s) => s == null
      ? state = state.copyWith(clearDestinationStation: true)
      : state = state.copyWith(destinationStation: s);

  void setJourneyDate(DateTime d) => state = state.copyWith(journeyDate: d);

  void setTravelClass(String? c) => c == null
      ? state = state.copyWith(clearTravelClass: true)
      : state = state.copyWith(travelClass: c);

  void setBerth(String value) => state = state.copyWith(berth: value);

  /// Selects a boarding stop from the train route (via TrainStopSelector).
  void selectBoardingStop(TrainRouteStop stop) {
    final station = _stopToStation(stop);
    state = state.copyWith(
      boardingStation: station,
      // Clear destination if it is now before the new boarding stop
      clearDestinationStation:
          state.destinationStation != null &&
          _stopSequenceFor(state.destinationStation!.code) <= stop.stopSequence,
    );
  }

  /// Selects a destination stop from the train route (via TrainStopSelector).
  void selectDestinationStop(TrainRouteStop stop) {
    state = state.copyWith(destinationStation: _stopToStation(stop));
  }

  int _stopSequenceFor(String code) {
    return state.trainRouteStops
            .where((s) => s.stationCode == code)
            .map((s) => s.stopSequence)
            .firstOrNull ??
        0;
  }

  Station _stopToStation(TrainRouteStop stop) {
    return Station(
      id: 0,
      code: stop.stationCode,
      name: stop.stationName,
      latitude: stop.latitude,
      longitude: stop.longitude,
    );
  }

  /// Sets train number and initiates debounced auto-fetching.
  ///
  /// Called on every keystroke in the train number field.
  /// Debounces for 600ms to avoid excessive API calls while user is typing.
  /// Once user stops typing (600ms pause), automatically fetches:
  /// - Train name from local DB
  /// - Route stops with coordinates
  /// - Auto-fills boarding/destination stations if not set
  void setTrainNumber(String value) {
    // Cancel previous debounce timer
    _trainNumberDebounceTimer?.cancel();

    state = state.copyWith(trainNumber: value, clearError: true);

    // Clear route stops immediately to show the input is being processed
    if (value.length < 4) {
      state = state.copyWith(trainRouteStops: const []);
      return;
    }

    // Debounce: wait 600ms for user to stop typing before auto-fetching
    state = state.copyWith(isAutoFilling: true);
    _trainNumberDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performAutoFetch(value);
    });
  }

  /// Performs the actual auto-fetch operation after debounce timer fires.
  ///
  /// Strategy: local DB first (instant), then remote API if local has gaps.
  Future<void> _performAutoFetch(String trainNumber) async {
    try {
      // 1. Try local DB first (fast)
      final localName = await _trainRepo.getTrainNameByNumber(trainNumber);
      if (localName != null && state.trainName.isEmpty) {
        state = state.copyWith(trainName: localName);
      }

      // 2. Load route stops with coordinates for TrainStopSelector
      final stops = await _trainRepo.getRouteStopsWithCoordinates(trainNumber);
      if (stops.isNotEmpty) {
        state = state.copyWith(trainRouteStops: stops);
      }

      // 3. If local DB had no name or no route, fetch from remote API at runtime
      final needsRemoteName = state.trainName.isEmpty;
      final needsRemoteRoute = stops.isEmpty;

      if (needsRemoteName || needsRemoteRoute) {
        final details = await _trainApi.getTrainDetails(trainNumber);
        if (details != null) {
          // Fill train name from API
          if (needsRemoteName) {
            final remoteName = details['train_name'] as String?;
            if (remoteName != null && remoteName.isNotEmpty) {
              state = state.copyWith(trainName: remoteName);
            }
          }

          // Build route stops from API response if local DB had none
          if (needsRemoteRoute) {
            final routeList = details['route'] as List?;
            if (routeList != null && routeList.isNotEmpty) {
              final apiStops = <TrainRouteStop>[];
              for (int i = 0; i < routeList.length; i++) {
                final r = routeList[i] as Map<String, dynamic>;
                final code = r['station_code'] as String? ?? '';
                final name = r['station_name'] as String? ?? code;
                // Try to resolve coordinates from local station DB
                final localStation = await _stationRepo.getStationByCode(code);
                apiStops.add(
                  TrainRouteStop(
                    stationCode: code,
                    stationName: name,
                    stopSequence: i + 1,
                    arrivalTime: r['scheduled_arrival'] as String?,
                    departureTime: r['scheduled_departure'] as String?,
                    latitude: localStation?.latitude ?? 0.0,
                    longitude: localStation?.longitude ?? 0.0,
                  ),
                );
              }
              // Only use API stops if we got valid data
              if (apiStops.isNotEmpty) {
                state = state.copyWith(trainRouteStops: apiStops);
              }
            }
          }
        }
      }

      // 4. Auto-fill endpoints if not yet set (use resolved stop data)
      final resolvedStops = state.trainRouteStops;
      if (state.boardingStation == null || state.destinationStation == null) {
        if (resolvedStops.isNotEmpty) {
          if (state.boardingStation == null) {
            state = state.copyWith(
              boardingStation: _stopToStation(resolvedStops.first),
            );
          }
          if (state.destinationStation == null) {
            state = state.copyWith(
              destinationStation: _stopToStation(resolvedStops.last),
            );
          }
        } else {
          // Last resort: use endpoint codes from train_routes table
          final endpoints = await _trainRepo.getTrainEndpoints(trainNumber);
          if (endpoints != null) {
            if (state.boardingStation == null) {
              final from = await _stationRepo.getStationByCode(
                endpoints['from_station']!,
              );
              if (from != null) state = state.copyWith(boardingStation: from);
            }
            if (state.destinationStation == null) {
              final to = await _stationRepo.getStationByCode(
                endpoints['to_station']!,
              );
              if (to != null) state = state.copyWith(destinationStation: to);
            }
          }
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

final trainJourneyNotifierProvider =
    StateNotifierProvider.autoDispose<TrainJourneyNotifier, TrainJourneyState>(
      (ref) => TrainJourneyNotifier(
        journeyRepo: ref.read(journeyRepositoryProvider),
        stationRepo: ref.read(stationRepositoryProvider),
        trainRepo: ref.read(trainRepositoryProvider),
        trainApi: ref.read(trainStatusApiProvider),
      ),
    );
