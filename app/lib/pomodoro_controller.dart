import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models/pomodoro_settings.dart';

enum PomodoroPhase { focus, shortBreak, longBreak }

/// Owns the countdown and the focus/break cycle.
///
/// The countdown is anchored to a wall-clock deadline rather than accumulated
/// ticks, so a delayed or throttled timer (a backgrounded tab, a busy phone)
/// never makes the clock drift.
class PomodoroController extends ChangeNotifier {
  PomodoroController({PomodoroSettings settings = const PomodoroSettings()})
      : _settings = settings {
    _remaining = durationFor(_phase);
  }

  static const _tick = Duration(milliseconds: 200);

  PomodoroSettings _settings;
  Timer? _ticker;
  DateTime? _deadline;
  late Duration _remaining;
  PomodoroPhase _phase = PomodoroPhase.focus;
  int _completedFocusSessions = 0;

  /// Called when a phase runs out, with the phase that finished and the one
  /// that follows it. The UI uses this for sound, haptics and a snack bar.
  void Function(PomodoroPhase finished, PomodoroPhase next)? onPhaseComplete;

  PomodoroSettings get settings => _settings;
  PomodoroPhase get phase => _phase;
  bool get isRunning => _ticker != null;
  int get completedFocusSessions => _completedFocusSessions;
  Duration get remaining => _remaining;

  /// Where the current focus session sits inside the long-break cycle, 1-based.
  int get positionInCycle =>
      (_completedFocusSessions % _settings.longBreakInterval) + 1;

  double get progress {
    final total = durationFor(_phase).inMilliseconds;
    if (total <= 0) return 0;
    final elapsed = total - _remaining.inMilliseconds.clamp(0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String get timeLabel {
    // Round up so a full 25 minute session reads as 25:00, not 24:59.
    final seconds = (_remaining.inMilliseconds / 1000).ceil().clamp(0, 359999);
    final minutes = seconds ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Duration durationFor(PomodoroPhase phase) => switch (phase) {
        PomodoroPhase.focus => Duration(minutes: _settings.focusMinutes),
        PomodoroPhase.shortBreak =>
          Duration(minutes: _settings.shortBreakMinutes),
        PomodoroPhase.longBreak =>
          Duration(minutes: _settings.longBreakMinutes),
      };

  void updateSettings(PomodoroSettings settings) {
    _settings = settings;

    // A new duration should show on the clock right away, but only while idle:
    // rewriting the deadline mid-session would be surprising.
    if (!isRunning) {
      _remaining = durationFor(_phase);
    }
    notifyListeners();
  }

  void startPause() => isRunning ? pause() : start();

  void start() {
    if (isRunning) return;
    if (_remaining <= Duration.zero) {
      _remaining = durationFor(_phase);
    }

    _deadline = DateTime.now().add(_remaining);
    _ticker = Timer.periodic(_tick, (_) => _onTick());
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;

    _remaining = _clampedRemaining();
    _stopTicker();
    notifyListeners();
  }

  /// Stops the clock and refills the current phase.
  void reset() {
    _stopTicker();
    _remaining = durationFor(_phase);
    notifyListeners();
  }

  /// Abandons the current phase and moves on without counting it.
  void skip() {
    _stopTicker();
    _advance(countFocusSession: false);
    notifyListeners();
  }

  /// Clears the tally and returns to a fresh focus session.
  void resetCycle() {
    _stopTicker();
    _completedFocusSessions = 0;
    _phase = PomodoroPhase.focus;
    _remaining = durationFor(_phase);
    notifyListeners();
  }

  void _onTick() {
    _remaining = _clampedRemaining();

    if (_remaining > Duration.zero) {
      notifyListeners();
      return;
    }

    _stopTicker();
    final finished = _phase;
    _advance(countFocusSession: true);
    onPhaseComplete?.call(finished, _phase);

    final autoStart = _phase == PomodoroPhase.focus
        ? _settings.autoStartFocus
        : _settings.autoStartBreaks;
    if (autoStart) {
      start();
    } else {
      notifyListeners();
    }
  }

  void _advance({required bool countFocusSession}) {
    if (_phase == PomodoroPhase.focus) {
      if (countFocusSession) _completedFocusSessions++;

      final dueForLongBreak = countFocusSession &&
          _completedFocusSessions % _settings.longBreakInterval == 0;
      _phase =
          dueForLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
    } else {
      _phase = PomodoroPhase.focus;
    }

    _remaining = durationFor(_phase);
  }

  Duration _clampedRemaining() {
    final deadline = _deadline;
    if (deadline == null) return _remaining;

    final left = deadline.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _deadline = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
