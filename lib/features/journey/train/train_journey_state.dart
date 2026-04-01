import 'package:travel_companion/data/models/station.dart';
import 'package:travel_companion/data/models/train_route_stop.dart';

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
  final List<TrainRouteStop> trainRouteStops;

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
    this.trainRouteStops = const [],
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
    List<TrainRouteStop>? trainRouteStops,
  }) {
    return TrainJourneyState(
      pnr: pnr ?? this.pnr,
      trainNumber: trainNumber ?? this.trainNumber,
      trainName: trainName ?? this.trainName,
      boardingStation: clearBoardingStation
          ? null
          : (boardingStation ?? this.boardingStation),
      destinationStation: clearDestinationStation
          ? null
          : (destinationStation ?? this.destinationStation),
      journeyDate: journeyDate ?? this.journeyDate,
      travelClass: clearTravelClass ? null : (travelClass ?? this.travelClass),
      berth: berth ?? this.berth,
      isAutoFilling: isAutoFilling ?? this.isAutoFilling,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
      trainRouteStops: trainRouteStops ?? this.trainRouteStops,
    );
  }

  List<TrainRouteStop> get destinationStops {
    if (boardingStation == null || trainRouteStops.isEmpty) {
      return trainRouteStops;
    }
    final boardingSeq = trainRouteStops
        .where((s) => s.stationCode == boardingStation!.code)
        .map((s) => s.stopSequence)
        .firstOrNull;
    if (boardingSeq == null) return trainRouteStops;
    return trainRouteStops.where((s) => s.stopSequence > boardingSeq).toList();
  }
}
