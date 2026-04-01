import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_companion/features/settings/application/settings_state.dart';
import 'package:travel_companion/features/settings/domain/settings_preferences.dart';

class SettingsController extends StateNotifier<SettingsState> {
  static const _dayBeforeReminderKey = 'dayBeforeReminder';
  static const _hoursBeforeReminderKey = 'hoursBeforeReminder';
  static const _autoStartTrackingKey = 'autoStartTracking';
  static const _alarmDistanceKey = 'alarmDistance';

  final SettingsPreferences _preferences;

  SettingsController({required SettingsPreferences preferences})
    : _preferences = preferences,
      super(const SettingsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final dayBefore = await _preferences.getBool(
      _dayBeforeReminderKey,
      fallback: true,
    );
    final hoursBefore = await _preferences.getBool(
      _hoursBeforeReminderKey,
      fallback: true,
    );
    final autoStart = await _preferences.getBool(
      _autoStartTrackingKey,
      fallback: true,
    );
    final alarmDistance = await _preferences.getString(
      _alarmDistanceKey,
      fallback: '15',
    );
    state = state.copyWith(
      dayBeforeReminder: dayBefore,
      hoursBeforeReminder: hoursBefore,
      autoStartTracking: autoStart,
      alarmDistance: alarmDistance,
      isLoading: false,
    );
  }

  Future<void> setDayBeforeReminder(bool value) async {
    state = state.copyWith(dayBeforeReminder: value);
    await _preferences.setBool(_dayBeforeReminderKey, value);
  }

  Future<void> setHoursBeforeReminder(bool value) async {
    state = state.copyWith(hoursBeforeReminder: value);
    await _preferences.setBool(_hoursBeforeReminderKey, value);
  }

  Future<void> setAutoStartTracking(bool value) async {
    state = state.copyWith(autoStartTracking: value);
    await _preferences.setBool(_autoStartTrackingKey, value);
  }

  Future<void> setAlarmDistance(String value) async {
    state = state.copyWith(alarmDistance: value);
    await _preferences.setString(_alarmDistanceKey, value);
  }
}
