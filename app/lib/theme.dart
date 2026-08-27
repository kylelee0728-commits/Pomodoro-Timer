import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'pomodoro_controller.dart';

/// Seed colours for each phase: tomato, mint, deep blue.
const _seeds = <PomodoroPhase, Color>{
  PomodoroPhase.focus: Color(0xFFE14B3C),
  PomodoroPhase.shortBreak: Color(0xFF3FA766),
  PomodoroPhase.longBreak: Color(0xFF2E7DD1),
};

Color seedFor(PomodoroPhase phase) => _seeds[phase]!;

/// The scheme for a phase: the platform's dynamic scheme when the user wants
/// it and the platform offers one, otherwise a scheme seeded from the phase
/// colour so the whole UI shifts as the cycle moves.
ColorScheme buildScheme({
  required PomodoroPhase phase,
  required Brightness brightness,
  ColorScheme? dynamicScheme,
}) {
  if (dynamicScheme != null) {
    return dynamicScheme.harmonized();
  }

  return ColorScheme.fromSeed(
      seedColor: seedFor(phase), brightness: brightness);
}

ThemeData buildTheme(ColorScheme scheme) => ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );

/// The accent used for the ring and the phase label, blended towards the
/// active scheme so it never clashes with a dynamic palette.
Color phaseAccent(PomodoroPhase phase, ColorScheme scheme) =>
    seedFor(phase).harmonizeWith(scheme.primary);
