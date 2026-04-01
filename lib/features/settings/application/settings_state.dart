class SettingsState {
  final bool dayBeforeReminder;
  final bool hoursBeforeReminder;
  final bool autoStartTracking;
  final String alarmDistance;
  final bool isLoading;

  const SettingsState({
    this.dayBeforeReminder = true,
    this.hoursBeforeReminder = true,
    this.autoStartTracking = true,
    this.alarmDistance = '15',
    this.isLoading = true,
  });

  SettingsState copyWith({
    bool? dayBeforeReminder,
    bool? hoursBeforeReminder,
    bool? autoStartTracking,
    String? alarmDistance,
    bool? isLoading,
  }) {
    return SettingsState(
      dayBeforeReminder: dayBeforeReminder ?? this.dayBeforeReminder,
      hoursBeforeReminder: hoursBeforeReminder ?? this.hoursBeforeReminder,
      autoStartTracking: autoStartTracking ?? this.autoStartTracking,
      alarmDistance: alarmDistance ?? this.alarmDistance,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
