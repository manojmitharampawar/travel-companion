# Travel Companion — Claude Guide

## Project Overview

A smart Indian transit companion app that monitors your journey and triggers GPS-based alarms as you approach your destination. Supports Train, Bus, Metro, and Local Train transport types.

## Claude Coding Agent Instructions

Claude must always:
- Follow standard coding practices and idiomatic Dart/Flutter conventions
- Apply clean architecture and design patterns as used in this codebase (Provider, Repository, Service, Singleton)
- Ensure all code passes SonarQube/SonarCloud quality checks (no critical/major issues)
- Adhere to SOLID and KISS principles:
  - **S**ingle Responsibility: Each class/function has one job
  - **O**pen/Closed: Open for extension, closed for modification
  - **L**iskov Substitution: Subtypes must be substitutable for base types
  - **I**nterface Segregation: Prefer small, focused interfaces
  - **D**ependency Inversion: Depend on abstractions, not concretions
  - **KISS**: Keep code as simple as possible, avoid over-engineering
- Write maintainable, readable, and well-documented code
- Use Riverpod for state management and follow the provider patterns in `lib/providers/app_providers.dart`
- Separate UI, business logic, and data access into distinct layers
- Follow Material Design and mobile UX standards:
  - Consistent padding, spacing, and typography
  - Responsive layouts for all device sizes
  - Clear feedback for user actions (loading, errors)
  - Intuitive navigation and minimal user input (auto-fill, smart defaults)
- Extract reusable UI components into `widgets/` where appropriate
- Add/update unit tests for new features or bug fixes
- Reference and update `AGENTS.md` if introducing new patterns/conventions

**Summary:**
Claude must always produce code that is clean, maintainable, and adheres to SOLID and KISS principles, passes Sonar quality checks, and follows mobile UI/UX best practices for Flutter. When in doubt, prefer simplicity and consistency with the existing codebase.

## Tech Stack

- **Framework:** Flutter (Dart 3.11.1+), Material Design
- **State Management:** flutter_riverpod ^2.6.1 with riverpod_generator (code-gen)
- **Database:** sqflite (SQLite) — includes 27,600+ Indian railway stations
- **Location:** geolocator + flutter_background_service for continuous GPS tracking
- **Notifications/Alarms:** flutter_local_notifications + android_alarm_manager_plus + just_audio
- **Maps:** flutter_map (OpenStreetMap) + latlong2
- **HTTP:** dio for external APIs
- **Permissions:** permission_handler

## Project Structure

```
lib/
├── main.dart / app.dart          # Entry point and root widget
├── core/
│   ├── constants/                # Alarm thresholds, tracking intervals
│   ├── services/                 # 11+ services (alarm, location, notification, etc.)
│   ├── theme/                    # Light/dark theme definitions
│   └── utils/                   # Date, transport helpers
├── data/
│   ├── database/                 # SQLite setup and station seed data
│   ├── datasources/              # Remote API clients
│   ├── models/                   # Journey, Station, etc.
│   └── repositories/             # Data access layer
├── features/
│   ├── home/                     # Home screen + provider
│   ├── journey/                  # Journey management
│   │   ├── train/ bus/ metro/ local_train/   # Transport-specific screens
│   │   └── widgets/              # Shared form widgets
│   ├── map/                      # Map view + location picker
│   ├── history/                  # Completed journeys
│   ├── settings/                 # User preferences
│   └── sms/                      # IRCTC SMS parsing
└── providers/                    # Global Riverpod providers (app_providers.dart)
```

## Key Domain Concepts

### Transport-Specific Alarm Thresholds (`core/constants/`)
| Transport    | Far Alert | Mid Alert | Near Alert |
|-------------|-----------|-----------|------------|
| Train       | 50 km     | 15 km     | 1 km       |
| Bus         | 20 km     | 5 km      | 500 m      |
| Metro       | 5 km      | 2 km      | 300 m      |
| Local Train | 10 km     | 3 km      | 500 m      |

### Journey Status Flow
`upcoming → active → completed | cancelled`

Journeys can be one-off (quick trips) or repeating (daily/specific days).

### Background Tracking
The app runs a background service from app launch for continuous GPS monitoring. Location polling interval adapts between "far" and "near" modes based on distance to destination.

## Common Commands

```bash
flutter pub get                          # Install dependencies
flutter run                              # Run app
dart run build_runner build              # Regenerate Riverpod code after annotation changes
flutter test                             # Run tests
flutter build apk --release             # Android release build
flutter analyze                          # Lint check
```

**Always run `build_runner` after modifying any file with `@riverpod` annotations.**

## Development Notes

- Riverpod providers are centralized in `lib/providers/app_providers.dart` for DI
- New features should follow clean architecture: model → repository → provider → screen
- Transport-agnostic logic lives in `core/`; transport-specific overrides go in `features/journey/<transport>/`
- The station database is seeded from `assets/db/stations.csv` on first launch
- Alarm audio files are in `assets/sounds/` (alarm.mp3 and alarm.wav)
- SMS parsing supports IRCTC ticket format for auto-filling journey details
- Platform permissions (location, notifications, background execution) are requested at runtime via `permission_handler`
- Map integration is currently a placeholder using `flutter_map` with OpenStreetMap; future plans include Google Maps integration for geocoding and richer map features.
- Testing focuses on unit tests for services and repositories; UI tests are planned for future iterations.
- The app is designed to be extensible for additional transport types and features (e.g., ride-sharing, flight tracking) with minimal changes to core logic.
- The app's architecture emphasizes separation of concerns, testability, and maintainability, following best practices for Flutter development and clean architecture principles.
- The project is actively developed with a focus on user experience, reliability, and performance, especially in background tracking and alarm triggering scenarios. Feedback and contributions are welcome!
- The app is currently in early development stages, with core features implemented and ongoing work on UI/UX improvements, additional transport types, and map integration. Future updates will include more detailed documentation, expanded test coverage, and user guides.
- The app is designed to be a comprehensive travel companion for Indian transit users, with a focus on real-time journey monitoring, smart alarms, and seamless user experience across multiple transport modes. The architecture allows for easy addition of new features and transport types as the project evolves.
- Follow SOLID principles and clean architecture guidelines when adding new features or modifying existing code to maintain code quality and scalability.
- Follow logging and error handling best practices, especially in background services and external API interactions, to ensure reliability and ease of debugging.

## Assets

- `assets/db/stations.csv` — 27,600+ Indian railway stations with coordinates
- `assets/sounds/alarm.mp3` / `alarm.wav` — Alarm audio
- `assets/images/` — App images (currently empty placeholder)
