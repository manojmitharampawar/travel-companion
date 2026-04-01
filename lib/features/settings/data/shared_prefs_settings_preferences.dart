import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_companion/features/settings/domain/settings_preferences.dart';

class SharedPrefsSettingsPreferences implements SettingsPreferences {
  @override
  Future<bool> getBool(String key, {required bool fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? fallback;
  }

  @override
  Future<String> getString(String key, {required String fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? fallback;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
