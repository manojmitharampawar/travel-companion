# Cupertino + Glassmorphic Migration Plan

## Goal
Remove direct dependency on Material UI patterns from app UX and standardize on Cupertino-first navigation, page shells, dialogs/feedback, and adaptive glass components with seamless light/dark behavior.

## Current Status (as of Phase 2D conversion)
- App shell migrated to `CupertinoApp` with compatibility `material.Theme` wrapper.
- Theme mode defaults to `system` and uses adaptive brightness resolution.
- Glass widget system refactored into reusable modules under `lib/core/theme/glass/`.
- Adaptive route helper added and all `MaterialPageRoute` usages in `lib/features/` replaced.
- Adaptive toast helper added for non-Material feedback.
- `HomeScreen`, `SettingsScreen`, `HistoryScreen`, and `AddJourneyScreen` moved to `CupertinoPageScaffold`.
- Phase 2B completed in feature screens: `SnackBar` flows replaced with `AdaptiveFeedback.showToast` and `showDialog`/`AlertDialog` flows replaced with Cupertino dialog APIs.
- All previously identified `SliverAppBar` sections (13 screens) replaced with CupertinoNavigationBar-style glass headers.
- Phase 2C completed for primary journey/map/history/settings flows listed below (all run under `CupertinoPageScaffold` with adaptive navigation).
- Phase 2D baseline completed for targeted Material UX semantics: no `Scaffold`, `SliverAppBar`, `SnackBar`, `AlertDialog`, `showModalBottomSheet`, or `MaterialPageRoute` usage in `lib/features/`.
- Phase 2E in progress: semantic status color tokens added to `GlassColors` and wired into shared/detail journey UI; broader tokenization pass remains.
- Phase 2F in progress: full `flutter analyze` passes with no errors; remaining findings are lint/info quality items.

## Remaining Work

### Phase 2A: Shared UI Foundations
- Create reusable Cupertino glass primitives:
  - `GlassCupertinoNavBar` (back, title, trailing actions)
  - `GlassCupertinoSection` (header + card body)
  - `GlassCupertinoPrimaryButton` (CTA with loading state)
  - `GlassCupertinoField` and `GlassCupertinoPickerField`
- Add adaptive action sheet helper to replace `showModalBottomSheet` where possible.
- Add adaptive confirm dialog helper to replace `AlertDialog`.

### Phase 2B: Feedback + Dialog Migration
- [x] Replace all `ScaffoldMessenger.of(context).showSnackBar` calls with `AdaptiveFeedback.showToast`.
- [x] Replace `showDialog`/`AlertDialog` calls with Cupertino dialogs in feature screens.
- [x] Preserve existing messaging semantics and error/success color intent.

### Phase 2C: Screen-by-Screen UI Migration
- [x] Journey screens:
  - `add_train_journey_screen.dart`
  - `add_bus_journey_screen.dart`
  - `add_metro_journey_screen.dart`
  - `add_local_train_journey_screen.dart`
  - `edit_journey_screen.dart`
  - `quick_trip_screen.dart`
  - `journey_detail_screen.dart`
  - `journey_tracking_screen.dart`
- [x] Transport detail screens:
  - `train_journey_detail_screen.dart`
  - `metro_journey_detail_screen.dart`
  - `local_train_journey_detail_screen.dart`
  - `bus_journey_detail_screen.dart`
- [x] Map screens:
  - `map_location_picker.dart`
  - `bus_map_picker_screen.dart`
  - `fullscreen_map_screen.dart`

### Phase 2D: Remove Material UX Dependencies
- [x] Replace Material-only widgets where still used for UI semantics:
  - `Scaffold`, `SliverAppBar`, `SnackBar`, `AlertDialog`, `showModalBottomSheet`
- [x] Keep targeted Material internals only where Flutter currently lacks equivalent behavior and encapsulate in adapters.

### Phase 2E: Theme Hardening (Light/Dark)
- [~] Audit all hardcoded colors and route through `GlassColors` tokens.
- [~] Validate contrast for text/icons/chips/cards in both modes.
- [~] Ensure map overlays, popups, and controls remain legible in both modes.

### Phase 2F: Quality + Cleanup
- [~] Resolve analyzer warnings introduced before migration where practical.
- [~] Remove obsolete Material imports in migrated files.
- [ ] Add widget tests for:
  - Theme mode switching (system/light/dark)
  - Adaptive navigation and dialogs
  - Visibility/contrast smoke checks for core screens

## Acceptance Criteria
- No user-visible Material page transitions.
- No `Scaffold` usage in feature screens.
- No `SnackBar` or `AlertDialog` usage in feature screens.
- Light and dark mode visual parity across all primary journeys.
- `flutter analyze` reports no new migration-related issues.

## Suggested Execution Order
1. Finish feedback/dialog migration globally.
2. Migrate journey creation/editing flows.
3. Migrate journey detail/tracking flows.
4. Migrate map screens and remaining history/settings internals.
5. Perform full contrast and regression pass.
