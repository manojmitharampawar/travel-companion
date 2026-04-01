import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/features/settings/application/settings_controller.dart';
import 'package:travel_companion/features/settings/application/settings_state.dart';
import 'package:travel_companion/features/settings/data/shared_prefs_settings_preferences.dart';
import 'package:travel_companion/features/settings/domain/settings_preferences.dart';

final settingsPreferencesProvider = Provider<SettingsPreferences>((ref) {
  return SharedPrefsSettingsPreferences();
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final controller = SettingsController(
        preferences: ref.read(settingsPreferencesProvider),
      );
      controller.load();
      return controller;
    });
