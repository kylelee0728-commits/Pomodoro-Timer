import 'dart:math' as math;

/// Durations and behaviour flags that drive the timer.
class PomodoroSettings {
  const PomodoroSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.longBreakInterval = 4,
    this.autoStartBreaks = true,
    this.autoStartFocus = false,
    this.playSound = true,
    this.haptics = true,
    this.dynamicColor = true,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  /// Number of focus sessions before a long break.
  final int longBreakInterval;

  final bool autoStartBreaks;
  final bool autoStartFocus;
  final bool playSound;
  final bool haptics;

  /// Follow the platform's dynamic colour (Android 12+, and some desktops).
  final bool dynamicColor;

  PomodoroSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakInterval,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? playSound,
    bool? haptics,
    bool? dynamicColor,
  }) {
    return PomodoroSettings(
      focusMinutes: _clamp(focusMinutes ?? this.focusMinutes, 1, 180),
      shortBreakMinutes:
          _clamp(shortBreakMinutes ?? this.shortBreakMinutes, 1, 60),
      longBreakMinutes:
          _clamp(longBreakMinutes ?? this.longBreakMinutes, 1, 120),
      longBreakInterval:
          _clamp(longBreakInterval ?? this.longBreakInterval, 1, 12),
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      playSound: playSound ?? this.playSound,
      haptics: haptics ?? this.haptics,
      dynamicColor: dynamicColor ?? this.dynamicColor,
    );
  }

  static int _clamp(int value, int min, int max) =>
      math.max(min, math.min(max, value));
}
