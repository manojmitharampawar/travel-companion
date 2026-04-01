# Travel Companion — Claude Guide

## Project Overview

A smart Indian transit companion app that monitors your journey and triggers GPS-based alarms as you approach your destination. Supports Train, Bus, Metro, and Local Train transport types. Built with a **Cupertino-first + Glassmorphism** design system.

## Claude Coding Agent Instructions

Claude must always:
- Follow standard coding practices and idiomatic Dart/Flutter conventions
- Apply clean architecture and design patterns as used in this codebase (Riverpod, Repository, Service, Singleton)
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
- **Use the Glass Design System** for all UI work (see Design System section below)
- **Use Cupertino widgets** as primary (CupertinoPageScaffold, CupertinoPageRoute), with Material fallback for complex widgets (DropdownButtonFormField, TabBar)
- **Never hardcode colors** — always use `GlassColors.of(context)` for theme-aware colors
- **Never hardcode spacing** — use `GlassSpacing` tokens and `GlassLayout` helpers
- **Never hardcode text styles** — use `GlassTypography.of(context)`
- Extract reusable UI components into `widgets/` or `core/theme/glass/` where appropriate
- Add/update unit tests for new features or bug fixes
- Reference and update `AGENTS.md` if introducing new patterns/conventions

**Summary:**
Claude must always produce code that is clean, maintainable, and adheres to SOLID and KISS principles, passes Sonar quality checks, and follows the Cupertino + Glassmorphism design system. When in doubt, prefer simplicity and consistency with the existing codebase.

## Tech Stack

- **Framework:** Flutter (Dart 3.11.1+), **Cupertino-first** with Material compatibility layer
- **Design System:** Custom Glassmorphism (`core/theme/glass/`) with `BackdropFilter` blur effects
- **State Management:** flutter_riverpod ^2.6.1 with riverpod_generator (code-gen)
- **Database:** sqflite (SQLite) — includes 27,600+ Indian railway stations
- **Location:** geolocator + flutter_background_service for continuous GPS tracking
- **Notifications/Alarms:** flutter_local_notifications + android_alarm_manager_plus + just_audio
- **Maps:** flutter_map (OpenStreetMap) + latlong2
- **HTTP:** dio for external APIs
- **Permissions:** permission_handler

## Design System — Glassmorphism + Cupertino

### Color Access Pattern
```dart
final g = GlassColors.of(context);
// Background: g.bg, g.bgGradient
// Text: g.text, g.textSecondary, g.textTertiary, g.textHint, g.textAlpha(0.8)
// Cards: g.cardFill(), g.cardFillSolid()
// Borders: g.border(), g.inputBorder, g.inputFocusBorder
// Inputs: g.inputFill
// Semantic: g.statusInfo, g.statusSuccess, g.statusWarning, g.statusDanger
// Transport: g.trainAccent, g.busAccent, g.metroAccent, g.localTrainAccent
// Scaffold: g.bg, g.appBarBg, g.bottomBarBg
// On accent surfaces: GlassColors.onAccent (always white)
```

### Layout & Spacing Pattern
```dart
final horizontal = GlassLayout.horizontalPadding(context);  // Responsive padding
final heroTop = GlassLayout.heroTopPadding(context);         // Safe area + status bar
final bottomPad = GlassLayout.bottomContentPadding(context); // Bottom safe area
// Spacing tokens: GlassSpacing.xxs(4), xs(8), sm(12), md(16), lg(24), xl(32), xxl(48), mega(72)
```

### Typography Pattern
```dart
final typography = GlassTypography.of(context);
// Styles: typography.largeTitle, .title, .subtitle, .body, .label, .caption, .mono
```

### Core Glass Components (`core/theme/glass/`)
| Component | File | Purpose |
|-----------|------|---------|
| `GlassCard` | glass_cards.dart | Frosted glass panel with blur, border, shadow |
| `GlassSectionCard` | glass_cards.dart | Card with icon + title header |
| `GlassChip` | glass_cards.dart | Tag/badge with optional highlight |
| `GlassPickerField<T>` | glass_cards.dart | Dropdown selector with bottom sheet picker |
| `GlassButton` | glass_actions.dart | Gradient or outlined action button with blur |
| `GlassAppBarHero` | glass_actions.dart | Gradient hero header with decorative orbs |
| `GlassStepIndicator` | glass_actions.dart | Multi-step progress indicator |
| `GlassBackground` | glass_backgrounds.dart | Full-screen gradient wrapper |
| `GlassMeshBackground` | glass_backgrounds.dart | Gradient mesh with floating glow orbs |
| `GlassTrainCard` | glass_data_widgets.dart | Schedule card with departure/arrival |
| `GlassConstants` | glass_constants.dart | Blur, radius, opacity, mesh color constants |
| `GlassSpacing` | glass_tokens.dart | Spacing scale (4px → 72px) |
| `GlassMotion` | glass_tokens.dart | Animation durations and curves |
| `GlassBreakpoints` | glass_tokens.dart | Responsive breakpoints (600/940/1280px) |
| `GlassLayout` | glass_tokens.dart | Responsive padding/margin helpers |
| `GlassTypography` | glass_tokens.dart | Context-aware text styles from CupertinoTheme |

### Adaptive Utilities (`core/ui/`)
- `adaptivePageRoute(page)` — Returns `CupertinoPageRoute` for all navigation
- `AdaptiveFeedback.showToast(context, message)` — Overlay-based toast (not SnackBar)

### Transport Color System
| Transport | Light | Dark |
|-----------|-------|------|
| Train | `#1565C0` | `#1E88E5` |
| Bus | `#2E7D32` | `#43A047` |
| Metro | `#006BB6` | `#29B6F6` |
| Local Train | `#E65100` | `#FF8A50` |

## Project Structure

```
lib/
├── main.dart                      # Bootstrap, service init
├── app.dart                       # CupertinoApp root, GlassNavigationShell (3-tab)
├── core/
│   ├── constants/                 # Alarm thresholds, tracking intervals
│   ├── services/                  # 11+ services (alarm, location, notification, etc.)
│   ├── theme/
│   │   ├── app_theme.dart         # Dual Cupertino + Material theme generation
│   │   ├── glass_theme.dart       # GlassColors — centerpiece color system
│   │   ├── glass_widgets.dart     # Barrel export for glass/ components
│   │   ├── glass/                 # Glass component library (6 files)
│   │   │   ├── glass_constants.dart
│   │   │   ├── glass_tokens.dart  # GlassSpacing, GlassMotion, GlassLayout, GlassTypography
│   │   │   ├── glass_actions.dart # GlassButton, GlassAppBarHero, GlassStepIndicator
│   │   │   ├── glass_backgrounds.dart # GlassBackground, GlassMeshBackground
│   │   │   ├── glass_cards.dart   # GlassCard, GlassSectionCard, GlassChip, GlassPickerField
│   │   │   └── glass_data_widgets.dart # GlassTrainCard
│   │   ├── app_logo.dart          # Custom-painted app logo
│   │   └── modern_ui_components.dart # Legacy Material widgets (to be phased out)
│   ├── ui/
│   │   ├── adaptive_navigation.dart  # CupertinoPageRoute helper
│   │   └── adaptive_feedback.dart    # Overlay-based toast system
│   └── utils/                     # Date, transport helpers
├── data/
│   ├── database/                  # SQLite setup and station seed data
│   ├── datasources/               # Remote API clients (TrainStatusApi, MetroStationApi)
│   ├── models/                    # Journey, Station, MetroStation, TrainRouteStop, etc.
│   └── repositories/              # JourneyRepository, TrainRepository, MetroRepository, etc.
├── features/
│   ├── home/                      # Home screen + upcomingJourneysProvider
│   ├── journey/
│   │   ├── journey_detail_screen.dart        # Generic detail wrapper (polymorphic)
│   │   ├── journey_detail_navigation.dart    # Navigation helper for detail routing
│   │   ├── journey_tracking_screen.dart      # Real-time GPS tracking UI
│   │   ├── quick_trip_screen.dart            # Quick trip with auto-detect location
│   │   ├── add_journey_screen.dart           # Generic add journey form
│   │   ├── edit_journey_screen.dart          # Edit existing journey
│   │   ├── train/
│   │   │   ├── add_train_journey_screen.dart
│   │   │   ├── train_journey_detail_screen.dart    # Train-specific detail
│   │   │   └── train_journey_notifier.dart
│   │   ├── bus/
│   │   │   ├── add_bus_journey_screen.dart
│   │   │   ├── bus_journey_detail_screen.dart      # Bus-specific detail
│   │   │   └── bus_journey_notifier.dart
│   │   ├── metro/
│   │   │   ├── add_metro_journey_screen.dart
│   │   │   ├── metro_journey_detail_screen.dart    # Metro-specific detail
│   │   │   └── metro_journey_notifier.dart
│   │   ├── local_train/
│   │   │   ├── add_local_train_journey_screen.dart
│   │   │   ├── local_train_journey_detail_screen.dart  # Local train-specific detail
│   │   │   └── local_train_journey_notifier.dart
│   │   └── widgets/
│   │       ├── journey_detail_shared_widgets.dart  # Shared detail components (GlassInfoGrid)
│   │       ├── journey_form_widgets.dart           # Form section cards, date/time pickers
│   │       ├── location_search_field.dart          # Geocoding search with map picker
│   │       └── train_stop_selector.dart            # Route stop selector with timeline
│   ├── map/                       # Transport-specific map widgets + location pickers
│   ├── history/
│   │   ├── history_screen.dart              # Tab router (History + Favorites)
│   │   ├── history_journeys_screen.dart     # Completed/cancelled journeys
│   │   ├── favorite_journeys_screen.dart    # Favorited journeys with reschedule
│   │   └── widgets/                         # Shared history components
│   ├── settings/                  # User preferences (theme, tracking, permissions)
│   └── sms/                       # IRCTC SMS parsing
└── providers/                     # Global Riverpod providers (app_providers.dart)
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

Journeys can be one-off (quick trips) or repeating (daily/specific days via 7-bit bitmask).

### Background Tracking
The app runs a background service from app launch for continuous GPS monitoring. Location polling interval adapts between "far" and "near" modes based on distance to destination.

### Navigation Architecture
- **Root:** `CupertinoApp` with dual Cupertino + Material theme builder
- **Shell:** `GlassNavigationShell` — 3-tab bottom navigation (Home, History, Settings)
- **Per-tab:** Nested `Navigator` stacks with isolated back navigation
- **Routes:** All navigation uses `CupertinoPageRoute` via `adaptivePageRoute()`
- **Detail screens:** Transport-specific (train, bus, metro, local_train) with shared `journey_detail_shared_widgets.dart`

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
- Maps use `flutter_map` with OpenStreetMap tiles; train maps include optional OpenRailwayMap overlay
- Theme mode (system/light/dark) is persisted to SharedPreferences via `themeModeProvider`
- `GlassColors.of(context)` reads brightness from `CupertinoTheme` first, falls back to `MediaQuery.platformBrightness`
- `modern_ui_components.dart` contains legacy Material widgets — prefer glass components for new code
- Use `AdaptiveFeedback.showToast()` for user feedback instead of `SnackBar`
- Each transport type has its own detail screen (`*_journey_detail_screen.dart`) with type-appropriate actions (e.g., train shows route stops, metro allows station changes within line)
- Follow SOLID principles and clean architecture guidelines when adding new features
- Follow logging and error handling best practices, especially in background services

## Assets

- `assets/db/stations.csv` — 27,600+ Indian railway stations with coordinates
- `assets/sounds/alarm.mp3` / `alarm.wav` — Alarm audio
- `assets/images/` — App images (currently empty placeholder)
