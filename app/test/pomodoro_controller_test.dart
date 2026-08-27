import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/models/pomodoro_settings.dart';
import 'package:pomodoro/pomodoro_controller.dart';

void main() {
  test('starts on a full focus session', () {
    final controller = PomodoroController(
      settings: const PomodoroSettings(focusMinutes: 25),
    );

    expect(controller.phase, PomodoroPhase.focus);
    expect(controller.timeLabel, '25:00');
    expect(controller.progress, 0);
  });

  test('skip alternates focus and break without counting the session', () {
    final controller = PomodoroController();

    controller.skip();
    expect(controller.phase, PomodoroPhase.shortBreak);
    expect(controller.completedFocusSessions, 0);

    controller.skip();
    expect(controller.phase, PomodoroPhase.focus);
  });

  test('a new duration shows immediately while idle', () {
    final controller = PomodoroController();

    controller.updateSettings(const PomodoroSettings(focusMinutes: 50));
    expect(controller.timeLabel, '50:00');
  });

  test('settings are clamped to a sane range', () {
    const settings = PomodoroSettings();

    expect(settings.copyWith(focusMinutes: 0).focusMinutes, 1);
    expect(settings.copyWith(focusMinutes: 999).focusMinutes, 180);
    expect(settings.copyWith(longBreakInterval: 99).longBreakInterval, 12);
  });

  test('cycle position wraps at the long-break interval', () {
    final controller = PomodoroController(
      settings: const PomodoroSettings(longBreakInterval: 4),
    );

    expect(controller.positionInCycle, 1);
  });
}
