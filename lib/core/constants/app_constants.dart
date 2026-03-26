import 'package:travel_companion/data/models/transport_type.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Travel Companion';
  static const String dbName = 'travel_companion.db';
  static const String stationsDbAsset = 'assets/db/stations.db';

  // Alarm thresholds (in meters) — train defaults
  static const double alertDistance30Min = 50000; // ~50km
  static const double alertDistance10Min = 15000; // ~15km
  static const double arrivalDistance = 1000; // ~1km
  static const double boardingProximity = 1000; // 1km to auto-detect boarding

  // Transport-specific alarm thresholds (meters)
  static const Map<TransportType, List<double>> alertThresholds = {
    TransportType.train: [50000, 15000, 1000],     // 50km, 15km, 1km
    TransportType.bus: [20000, 5000, 500],          // 20km, 5km, 500m
    TransportType.metro: [5000, 2000, 300],         // 5km, 2km, 300m
    TransportType.localTrain: [10000, 3000, 500],   // 10km, 3km, 500m
  };

  static double alertFar(TransportType type) => alertThresholds[type]![0];
  static double alertNear(TransportType type) => alertThresholds[type]![1];
  static double alertArrival(TransportType type) => alertThresholds[type]![2];

  // Average speeds (meters per second)
  static const Map<TransportType, double> avgSpeedMps = {
    TransportType.train: 55000 / 3600,       // 55 km/h
    TransportType.bus: 30000 / 3600,          // 30 km/h
    TransportType.metro: 35000 / 3600,        // 35 km/h
    TransportType.localTrain: 40000 / 3600,   // 40 km/h
  };

  // Location tracking intervals (in seconds) per transport
  static const int locationIntervalFar = 60;
  static const int locationIntervalNear = 15;
  static const double nearThresholdMeters = 30000;

  // Transport-specific location intervals [far, near] in seconds
  static const Map<TransportType, List<int>> locationIntervals = {
    TransportType.train: [60, 15],
    TransportType.bus: [30, 10],
    TransportType.metro: [15, 8],
    TransportType.localTrain: [20, 10],
  };

  // Transport-specific distance filters [far, near] in meters
  static const Map<TransportType, List<int>> distanceFilters = {
    TransportType.train: [500, 50],
    TransportType.bus: [200, 30],
    TransportType.metro: [100, 20],
    TransportType.localTrain: [150, 30],
  };

  // Notification channels
  static const String reminderChannelId = 'journey_reminders';
  static const String reminderChannelName = 'Journey Reminders';
  static const String alarmChannelId = 'arrival_alarm';
  static const String alarmChannelName = 'Arrival Alarm';
  static const String trackingChannelId = 'journey_tracking';
  static const String trackingChannelName = 'Journey Tracking';

  // IRCTC SMS sender IDs
  static const List<String> irctcSenderIds = [
    'IRCTC',
    'AX-IRCTCE',
    'AD-IRCTCE',
    'VM-IRCTCE',
    'BZ-IRCTCE',
    'IRCTCWEB',
  ];

  // Reminder offsets
  static const Duration dayBeforeReminder = Duration(hours: 24);
  static const Duration hoursBeforeReminder = Duration(hours: 3);

  // Notification IDs
  static const int trackingNotificationId = 0;
  static const int approachingFarNotificationId = 100;
  static const int arrivedNotificationId = 200;
  static const int alarmNotificationId = 999;
}
