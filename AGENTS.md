# Travel Companion - AI Agents Guide

This Flutter app helps Indian travelers sleep safely by tracking them to their destination and alerting them when they approach their stop across trains, buses, metros, and local trains.

## Architecture Overview

**Multi-transport journey tracking system** with offline-capable GPS-based arrival detection:

- **Core Tracking**: `AlarmService` monitors distance-based thresholds (transport-specific) using location streams, triggers multi-stage alerts (30min/10min/arrived), plays alarms
- **State Management**: Riverpod providers in `app_providers.dart` manage singleton services (AlarmService, LocationService, Repositories)
- **Data Layer**: SQLite database via `sqflite` with models for Journey, Station, TrainRoute; repositories provide sync CRUD operations
  - **Background Services**: `JourneyReminderService` runs periodic timer every 30 minutes; `RepeatJourneyService` auto-creates recurring journey instances
  - **Additional Services**: `EmailService` (IRCTC email parsing), `RoutingService` (route calculations), `TileCacheService` (map tile caching)
- **UI Layers**: Feature-specific screens under `/features/{home,journey,map,history,settings,sms}` with transport-specific sub-screens (train/, bus/, metro/, local_train/)

### Key Design Decisions

1. **Transport-Specific Tuning**: Separate speed, alert distances, location polling intervals for train/bus/metro/local-train in `AppConstants`
2. **Equatable Models**: Journey/Station/etc extend `Equatable` for comparison-heavy operations (status checks, filtering)
3. **Service Initialization**: Services started in `main()` before runApp; `JourneyReminderService` and `RepeatJourneyService` run continuously
4. **Location Accuracy Trade-offs**: Uses `distanceFilter` to batch updates (500m-50m depending on transport); `locationIntervals` control polling frequency
5. **Riverpod Disposal**: AlarmService, LocationService registered with `ref.onDispose()` for cleanup

## Critical Data Flows

### Journey Lifecycle
```
User creates Journey
  → stored in DB via JourneyRepository
  → JourneyReminderService checks periodically (30min timer)
  → sends reminder notifications at T-24h, T-3h, T-0
  → User starts tracking on journey detail screen
    → AlarmService.startJourneyTracking() begins location stream
    → StreamSubscription listens to position updates
    → distance calculations trigger alert transitions (tracking→approaching→arrived)
    → fires notifications/alarms at each threshold
    → updates Journey.status in DB
```

### Multi-Transport Differences
- **Train**: Uses station codes, supports PNR/berth, longer distances (50km/15km/1km thresholds)
- **Bus/Metro**: Free-form origin/destination (lat/lon or map search), shorter distances (bus: 20km/5km/500m)
- **Recurring Journeys**: `repeatDays` bitmask (bit 0=Mon...bit 6=Sun) + `scheduledTime`; RepeatJourneyService auto-instantiates daily

## Essential Workflows


### Adding a Transport-Specific Journey
- Train: `/features/journey/train/add_train_journey_screen.dart` → lookup stations → confirm schedule
- Bus/Metro/LocalTrain: `/features/journey/{bus,metro,local_train}/add_*_journey_screen.dart` → map search → manual coordinates
- Quick Trip: `/features/journey/quick_trip_screen.dart` → ad-hoc journey setup
- All funnel through `JourneyRepository.insertJourney()`

### Starting Tracking (Offline-Capable)
1. User opens `JourneyDetailScreen` → taps "Start Tracking"
2. Calls `AlarmService.startJourneyTracking()` with Journey + destination LocationPoint
3. `LocationService.startTracking()` begins position stream (transport-specific polling intervals)
4. AlarmService listens to position stream, calculates Haversine distance
5. Fires notifications at thresholds; updates Journey status in DB
6. Works fully offline — destination loaded from DB at start, no network calls needed

### Editing & Repeating Journeys
- Edit screen: `/features/journey/edit_journey_screen.dart` — modifies all fields except `id`, `createdAt`
- Repeat setup: Sets `repeatDays` bitmask + `scheduledTime`; `RepeatJourneyService.start()` spawns fresh Journey instances daily
- Editable map routes: `/features/journey/widgets/` contains route/map components; coordinates stored in Journey model

## Project-Specific Patterns & Conventions

### Enum + Extension Pattern
```dart
enum TransportType { train, bus, metro, localTrain }
extension TransportTypeExtension on TransportType {
  String get label => ...; // "Train", "Bus", etc.
  Color get color => ...; // Transport-specific UI colors
  List<int> get intervals => AppConstants.locationIntervals[this]!;
  ...
}
```
Always use `.label`, `.color`, `.speedLabel`, etc. instead of switch statements elsewhere.

### Service Initialization (main.dart)
Services are instantiated and started in `main()` *before* runApp, not lazily:
```dart
await NotificationService.initialize();
final journeyRepo = JourneyRepository();
JourneyReminderService(journeyRepository: journeyRepo).startPeriodicCheck();
```
This ensures background tracking starts immediately on app launch.

### LocationPoint vs Station
- `LocationPoint`: Generic lat/lon + name; used for custom map searches, quick trips
- `Station`: DB-backed with code, state, zone; used for train station lookups
- Journey stores both: `originLatitude/Longitude` + `boardingStationCode`; UI prefers Station data when available

### Status Enums & DB Serialization
Journey statuses: `upcoming, active, completed, cancelled` stored as string names in DB:
```dart
await db.update('journeys', {'status': status.name}, ...);
// Deserialization: JourneyStatus.values.byName(row['status'])
```

### Timestamp Handling
- `journeyDate`: DateTime for the departure/travel date
- `createdAt`: DateTime when Journey was recorded; immutable after creation
- Use `DateUtils` for formatting (see `/core/utils/date_utils.dart`)

## Critical Integration Points

### Notifications
- `NotificationService` manages 3 channels: reminders, alarms, tracking (see `AppConstants.reminderChannelId`, `AppConstants.reminderChannelName`, `AppConstants.alarmChannelId`, `AppConstants.alarmChannelName`)
- JourneyReminderService calls `NotificationService.showReminder()` at T-24h, T-3h, T-0
- AlarmService calls `NotificationService.showArrivalNotification()` when distance < threshold
- Alarm audio: `AlarmService` loads `assets/sounds/{alarm.mp3, alarm.wav}` via `just_audio`

### Location Permissions & Foreground Service
- `LocationService.checkAndRequestPermission()` handles Android + iOS permission flows
- Android foreground service enabled via `ForegroundNotificationConfig` in locationSettings
- iOS: requires Location NSUserDefaults in Info.plist (already configured)

### Database Seeding
- Train routes seeded from `data/database/train_seed_data.dart` on first DB creation
- Stations loaded from CSV: `assets/db/stations.csv` (parsed in `StationRepository`)
- Metro routes seeded from `metro_local_seed_data.dart`

### External APIs
- `TrainStatusApi` in `data/datasources/remote/` — checks real-time train status (via Dio)
- `MetroStationApi` in `data/datasources/remote/` — metro station lookups
- SMS parsing: `sms_service.dart` intercepts IRCTC SMS for auto-booking detection
- Email parsing: `email_service.dart` parses IRCTC ticket emails for auto-booking detection
- Geocoding: `GeocodingService` converts address ↔ lat/lon (currently placeholder for Google Maps integration)

## Dependency Tree (Key Providers)

```
journeyRepositoryProvider
  └─ used by: AlarmService, JourneyReminderService, feature screens
stationRepositoryProvider
  └─ used by: Journey enrichment (EnrichedJourney), train screens
locationServiceProvider
  └─ depends on: nothing; managed by AlarmService
alarmServiceProvider
  └─ depends on: locationServiceProvider, journeyRepositoryProvider
  └─ used by: JourneyTrackingScreen
trainStatusApiProvider
  └─ used by: train detail fetching
metroRepositoryProvider
  └─ used by: metro journey screens
localTrainRepositoryProvider
  └─ used by: local train journey screens
locationRepositoryProvider
  └─ used by: location lookups, map features
```

## Build & Test Commands

```bash
# Clean + build
flutter clean && flutter pub get

# Run debug on connected device/emulator
flutter run

# Android APK
flutter build apk --release

# iOS build (requires macOS)
flutter build ios --release

# Run analyzer & tests
flutter analyze
flutter test

# Code generation (Riverpod + build_runner)
dart run build_runner build --delete-conflicting-outputs
```

Note: First run may take ~30s for DB initialization and service startup.

## File Organization Logic

- **`lib/core/`**: Shared utilities (constants, services, theme, date/transport utils)
- **`lib/core/services/`**: Alarm, location, notification, journey reminder, repeat journey, geocoding, SMS, email, routing, and tile cache services
- **`lib/data/`**: Database, models, repositories (data layer — no UI)
- **`lib/data/repositories/`**: Journey, station, train, metro, local train, and location repositories
- **`lib/features/`**: UI screens by feature; transport-specific folders (train/, bus/); shared widgets in `/widgets/`
- **`lib/providers/`**: Riverpod provider definitions (app_providers.dart is the only file)
- **`assets/db/`**: CSV station data (`stations.csv`, `train_routes.csv`), seed SQLite dumps
- **`assets/sounds/`**: Alarm audio files (alarm.mp3, alarm.wav)

## Debugging Tips

- **Tracking Not Starting**: Check `LocationService.checkAndRequestPermission()` — likely permission denial
- **Alarms Not Firing**: Verify distance thresholds in `AppConstants`; test with manual coordinate injection
- **Background Service Stops**: Ensure `android_alarm_manager_plus` callbacks registered; check battery saver settings
- **DB Issues**: Try `flutter pub add --dev build_runner` + `dart run build_runner build` if migrations fail
- **Notification Not Showing**: Verify channels created in `NotificationService.initialize()` match Android 12+ requirements

## Important Notes for New Developers

1. All Journey operations are **synchronous DB calls** (not async-heavy) — fine for small datasets
2. **No local caching layer** — every read hits DB; Riverpod providers are singletons, not cached selectors
3. **GPS accuracy varies**; design UX to handle ±100-200m noise (see distance filter logic)
4. **Offline design**: Track screen works entirely offline — destination & route pre-loaded at start
5. **No backend sync** — all data lives in local SQLite; export/import via CSV if needed
6. **PNR parsing currently manual** — SMS parsing infrastructure in place for future automation

