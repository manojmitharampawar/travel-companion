import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/core/services/alarm_service.dart';
import 'package:travel_companion/core/services/location_service.dart';
import 'package:travel_companion/data/datasources/remote/train_status_api.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';
import 'package:travel_companion/data/repositories/location_repository.dart';
import 'package:travel_companion/data/repositories/station_repository.dart';
import 'package:travel_companion/data/repositories/train_repository.dart';

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository();
});

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository();
});

final trainRepositoryProvider = Provider<TrainRepository>((ref) {
  return TrainRepository();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

final trainStatusApiProvider = Provider<TrainStatusApi>((ref) {
  return TrainStatusApi();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

final alarmServiceProvider = Provider<AlarmService>((ref) {
  final service = AlarmService(
    locationService: ref.read(locationServiceProvider),
    journeyRepository: ref.read(journeyRepositoryProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});
