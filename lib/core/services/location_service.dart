import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:travel_companion/core/constants/app_constants.dart';
import 'package:travel_companion/data/models/transport_type.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _positionController = StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    );
  }

  Future<void> startTracking({
    bool nearDestination = false,
    TransportType transportType = TransportType.train,
  }) async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return;

    await stopTracking();

    final intervals = AppConstants.locationIntervals[transportType]!;
    final filters = AppConstants.distanceFilters[transportType]!;

    final intervalSeconds = nearDestination ? intervals[1] : intervals[0];
    final distanceFilter = nearDestination ? filters[1] : filters[0];

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
      intervalDuration: Duration(seconds: intervalSeconds),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: 'Tracking your journey to keep you safe',
        notificationTitle: 'Travel Companion',
        enableWakeLock: true,
        notificationChannelName: AppConstants.trackingChannelName,
      ),
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) => _positionController.add(position),
          onError: (error) => _positionController.addError(error),
        );
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculate distance between two points in meters using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Estimate time to reach destination based on transport-specific speed
  static Duration estimateTimeToReach(
    double distanceMeters, {
    TransportType type = TransportType.train,
  }) {
    final speed =
        AppConstants.avgSpeedMps[type] ??
        AppConstants.avgSpeedMps[TransportType.train]!;
    final seconds = distanceMeters / speed;
    return Duration(seconds: seconds.round());
  }

  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
