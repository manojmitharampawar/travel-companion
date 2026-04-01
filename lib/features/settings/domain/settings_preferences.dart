abstract class SettingsPreferences {
  Future<bool> getBool(String key, {required bool fallback});
  Future<String> getString(String key, {required String fallback});
  Future<void> setBool(String key, bool value);
  Future<void> setString(String key, String value);
}
