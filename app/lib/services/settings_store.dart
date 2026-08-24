import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro_settings.dart';

/// Persists settings with shared_preferences, which is backed by the native
/// preference store on every platform Flutter targets.
class SettingsStore {
  static const _keyPrefix = 'pomodoro.';

  Future<PomodoroSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const fallback = PomodoroSettings();

    return fallback.copyWith(
      focusMinutes: prefs.getInt('${_keyPrefix}focusMinutes'),
      shortBreakMinutes: prefs.getInt('${_keyPrefix}shortBreakMinutes'),
      longBreakMinutes: prefs.getInt('${_keyPrefix}longBreakMinutes'),
      longBreakInterval: prefs.getInt('${_keyPrefix}longBreakInterval'),
      autoStartBreaks: prefs.getBool('${_keyPrefix}autoStartBreaks'),
      autoStartFocus: prefs.getBool('${_keyPrefix}autoStartFocus'),
      playSound: prefs.getBool('${_keyPrefix}playSound'),
      haptics: prefs.getBool('${_keyPrefix}haptics'),
      dynamicColor: prefs.getBool('${_keyPrefix}dynamicColor'),
    );
  }

  Future<void> save(PomodoroSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_keyPrefix}focusMinutes', settings.focusMinutes);
    await prefs.setInt('${_keyPrefix}shortBreakMinutes', settings.shortBreakMinutes);
    await prefs.setInt('${_keyPrefix}longBreakMinutes', settings.longBreakMinutes);
    await prefs.setInt('${_keyPrefix}longBreakInterval', settings.longBreakInterval);
    await prefs.setBool('${_keyPrefix}autoStartBreaks', settings.autoStartBreaks);
    await prefs.setBool('${_keyPrefix}autoStartFocus', settings.autoStartFocus);
    await prefs.setBool('${_keyPrefix}playSound', settings.playSound);
    await prefs.setBool('${_keyPrefix}haptics', settings.haptics);
    await prefs.setBool('${_keyPrefix}dynamicColor', settings.dynamicColor);
  }
}
