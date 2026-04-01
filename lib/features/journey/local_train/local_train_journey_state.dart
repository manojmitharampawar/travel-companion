import 'package:travel_companion/data/models/local_train_line.dart';
import 'package:travel_companion/data/models/local_train_schedule.dart';

class LocalTrainJourneyState {
  final List<LocalTrainLine> availableLines;
  final LocalTrainLine? selectedLine;
  final bool isLoadingLines;

  final List<LocalTrainStation> lineStations;
  final LocalTrainStation? sourceStation;
  final LocalTrainStation? destStation;
  final bool isLoadingStations;

  final List<UpcomingTrain> upcomingTrains;
  final bool isLoadingSchedule;
  final UpcomingTrain? selectedTrain;

  final String? travelClass;

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
      selectedLine: clearSelectedLine
          ? null
          : (selectedLine ?? this.selectedLine),
      isLoadingLines: isLoadingLines ?? this.isLoadingLines,
      lineStations: lineStations ?? this.lineStations,
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
      travelClass: clearTravelClass ? null : (travelClass ?? this.travelClass),
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }

  int get currentStep {
    if (selectedLine == null) return 0;
    if (sourceStation == null || destStation == null) return 1;
    return 2;
  }
}
