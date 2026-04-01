import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:travel_companion/core/constants/app_constants.dart';
import 'package:travel_companion/core/services/location_service.dart';
import 'package:travel_companion/core/utils/date_utils.dart';
import 'package:travel_companion/core/services/notification_service.dart';
import 'package:travel_companion/data/models/journey.dart';
import 'package:travel_companion/data/models/location_point.dart';
import 'package:travel_companion/data/models/train_route.dart';
import 'package:travel_companion/data/models/transport_type.dart';
import 'package:travel_companion/data/repositories/journey_repository.dart';

enum TrackingState { idle, tracking, approaching, arrived }

class AlarmService {
  final LocationService _locationService;
  final JourneyRepository _journeyRepository;
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<Position>? _trackingSubscription;

  Journey? _activeJourney;
  LocationPoint? _destination;
  LocationPoint? _origin;
  List<TrainRoute> _routeStops = [];
  TrackingState _state = TrackingState.idle;
  bool _alarm30MinFired = false;
  bool _alarm10MinFired = false;
  bool _isNearMode = false;
  Position? _lastPosition;

  final _stateController = StreamController<TrackingState>.broadcast();
  final _distanceController = StreamController<double>.broadcast();
  final _positionController = StreamController<Position>.broadcast();

  Stream<TrackingState> get stateStream => _stateController.stream;
  Stream<double> get distanceStream => _distanceController.stream;
  Stream<Position> get positionStream => _positionController.stream;
  TrackingState get currentState => _state;
  List<TrainRoute> get routeStops => _routeStops;
  Position? get lastPosition => _lastPosition;
  LocationPoint? get origin => _origin;
  LocationPoint? get destination => _destination;

  AlarmService({
    required LocationService locationService,
    required JourneyRepository journeyRepository,
  }) : _locationService = locationService,
       _journeyRepository = journeyRepository;

  Future<void> startJourneyTracking({
    required Journey journey,
    required LocationPoint destination,
    LocationPoint? origin,
    List<TrainRoute> routeStops = const [],
  }) async {
    _activeJourney = journey;
    _destination = destination;
    _origin = origin;
    _routeStops = routeStops;
    _alarm30MinFired = false;
    _alarm10MinFired = false;
    _isNearMode = false;

    _updateState(TrackingState.tracking);

    // Update journey status to active
    await _journeyRepository.updateJourneyStatus(
      journey.id!,
      JourneyStatus.active,
    );

    // Start location tracking with transport-specific intervals
    final type = journey.transportType;
    await _locationService.startTracking(transportType: type);

    // Show persistent tracking notification
    await NotificationService.showTrackingNotification(
      title: '${type.label} Journey Active',
      body: 'Tracking your journey to ${destination.name}',
    );

    // Listen to position updates
    _trackingSubscription = _locationService.positionStream.listen(
      _onPositionUpdate,
    );
  }

  void _onPositionUpdate(Position position) {
    if (_destination == null || _activeJourney == null) return;

    _lastPosition = position;
    _positionController.add(position);

    final distance = LocationService.calculateDistance(
      position.latitude,
      position.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );

    _distanceController.add(distance);

    final type = _activeJourney!.transportType;
    final distanceKm = (distance / 1000).toStringAsFixed(1);
    final eta = LocationService.estimateTimeToReach(distance, type: type);
    final etaText = AppDateUtils.formatDuration(eta);

    NotificationService.showTrackingNotification(
      title: '${type.label} to ${_destination!.name}',
      body: '${distanceKm}km away | ETA: $etaText',
    );

    // Check transport-specific alert thresholds
    final arrivalDist = AppConstants.alertArrival(type);
    final nearDist = AppConstants.alertNear(type);
    final farDist = AppConstants.alertFar(type);

    if (distance <= arrivalDist) {
      _onArrived();
    } else if (distance <= nearDist && !_alarm10MinFired) {
      _onApproachingNear(distance, etaText);
    } else if (distance <= farDist && !_alarm30MinFired) {
      _onApproachingFar(etaText);
    }

    // Battery optimization: adaptive location intervals
    final nearThreshold = farDist * 0.6; // 60% of far threshold
    if (distance <= nearThreshold && !_isNearMode) {
      _isNearMode = true;
      _locationService.startTracking(
        transportType: type,
        nearDestination: true,
      );
    } else if (distance > nearThreshold * 1.5 && _isNearMode) {
      _isNearMode = false;
      _locationService.startTracking(
        transportType: type,
        nearDestination: false,
      );
    }
  }

  void _onApproachingFar(String etaText) {
    _alarm30MinFired = true;
    NotificationService.showReminder(
      id: AppConstants.approachingFarNotificationId,
      title: 'Approaching ${_destination!.name}',
      body: 'Estimated arrival: $etaText',
    );
  }

  Future<void> _onApproachingNear(double distance, String etaText) async {
    _alarm10MinFired = true;
    _updateState(TrackingState.approaching);

    await NotificationService.showArrivalAlarm(
      stationName: _destination!.name,
      estimatedTime: etaText,
    );

    await _playAlarmSound();
  }

  Future<void> _onArrived() async {
    _updateState(TrackingState.arrived);
    await stopAlarmSound();

    if (_activeJourney != null) {
      await _journeyRepository.updateJourneyStatus(
        _activeJourney!.id!,
        JourneyStatus.completed,
      );
    }

    await NotificationService.cancelAlarm();
    await NotificationService.showReminder(
      id: AppConstants.arrivedNotificationId,
      title: 'You have arrived!',
      body: 'Welcome to ${_destination!.name}. Gather your belongings.',
    );

    await stopTracking();
  }

  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/alarm.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
    } catch (e) {
      try {
        HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  Future<void> stopAlarmSound() async {
    await _audioPlayer.stop();
  }

  Future<void> stopTracking() async {
    await _trackingSubscription?.cancel();
    _trackingSubscription = null;
    await _locationService.stopTracking();
    await NotificationService.cancel(AppConstants.trackingNotificationId);
    _updateState(TrackingState.idle);
    _activeJourney = null;
    _destination = null;
    _origin = null;
    _routeStops = [];
    _isNearMode = false;
  }

  void _updateState(TrackingState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    stopTracking();
    _audioPlayer.dispose();
    _stateController.close();
    _distanceController.close();
    _positionController.close();
  }
}
