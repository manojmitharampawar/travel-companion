import 'package:travel_companion/data/models/metro_line.dart';
import 'package:travel_companion/data/models/metro_schedule.dart';
import 'package:travel_companion/data/models/metro_station.dart';

class MetroJourneyState {
  final List<String> availableCities;
  final String city;
  final bool isLoadingCities;

  final List<MetroLine> availableLines;
  final MetroLine? selectedLine;
  final bool isLoadingLines;

  final List<MetroStation> stationsOnLine;
  final MetroStation? sourceStation;
  final MetroStation? destStation;
  final bool isLoadingStations;

  final List<UpcomingMetro> upcomingTrains;
  final bool isLoadingSchedule;
  final UpcomingMetro? selectedTrain;

  final bool isSaving;
  final String? errorMessage;
  final bool savedSuccessfully;

  MetroJourneyState({
    this.availableCities = const [],
    this.city = '',
    this.isLoadingCities = false,
    this.availableLines = const [],
    this.selectedLine,
    this.isLoadingLines = false,
    this.stationsOnLine = const [],
    this.sourceStation,
    this.destStation,
    this.isLoadingStations = false,
    this.upcomingTrains = const [],
    this.isLoadingSchedule = false,
    this.selectedTrain,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  MetroJourneyState copyWith({
    List<String>? availableCities,
    String? city,
    bool? isLoadingCities,
    List<MetroLine>? availableLines,
    MetroLine? selectedLine,
    bool clearSelectedLine = false,
    bool? isLoadingLines,
    List<MetroStation>? stationsOnLine,
    MetroStation? sourceStation,
    bool clearSourceStation = false,
    MetroStation? destStation,
    bool clearDestStation = false,
    bool? isLoadingStations,
    List<UpcomingMetro>? upcomingTrains,
    bool? isLoadingSchedule,
    UpcomingMetro? selectedTrain,
    bool clearSelectedTrain = false,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? savedSuccessfully,
  }) {
    return MetroJourneyState(
      availableCities: availableCities ?? this.availableCities,
      city: city ?? this.city,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      availableLines: availableLines ?? this.availableLines,
      selectedLine: clearSelectedLine
          ? null
          : (selectedLine ?? this.selectedLine),
      isLoadingLines: isLoadingLines ?? this.isLoadingLines,
      stationsOnLine: stationsOnLine ?? this.stationsOnLine,
      sourceStation: clearSourceStation
          ? null
          : (sourceStation ?? this.sourceStation),
      destStation: clearDestStation ? null : (destStation ?? this.destStation),
      isLoadingStations: isLoadingStations ?? this.isLoadingStations,
      upcomingTrains: upcomingTrains ?? this.upcomingTrains,
      isLoadingSchedule: isLoadingSchedule ?? this.isLoadingSchedule,
      selectedTrain: clearSelectedTrain
          ? null
          : (selectedTrain ?? this.selectedTrain),
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }

  int get currentStep {
    if (city.isEmpty) return 0;
    if (selectedLine == null) return 1;
    if (sourceStation == null || destStation == null) return 2;
    return 3;
  }
}
