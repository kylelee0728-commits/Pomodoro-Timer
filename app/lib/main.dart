import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'models/pomodoro_settings.dart';
import 'pomodoro_controller.dart';
import 'screens/timer_screen.dart';
import 'services/settings_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = SettingsStore();
  final settings = await store.load();

  runApp(PomodoroApp(store: store, initialSettings: settings));
}

class PomodoroApp extends StatefulWidget {
  const PomodoroApp({
    super.key,
    required this.store,
    required this.initialSettings,
  });

  final SettingsStore store;
  final PomodoroSettings initialSettings;

  @override
  State<PomodoroApp> createState() => _PomodoroAppState();
}

class _PomodoroAppState extends State<PomodoroApp> {
  late final PomodoroController _controller =
      PomodoroController(settings: widget.initialSettings);

  late PomodoroPhase _phase = _controller.phase;
  late bool _useDynamicColor = _controller.settings.dynamicColor;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  /// The theme only depends on the phase and the colour preference, so the app
  /// shell is rebuilt on those changes rather than on every 200 ms tick.
  void _onControllerChanged() {
    final phase = _controller.phase;
    final useDynamicColor = _controller.settings.dynamicColor;
    if (phase == _phase && useDynamicColor == _useDynamicColor) return;

    setState(() {
      _phase = phase;
      _useDynamicColor = useDynamicColor;
    });
  }

  void _applySettings(PomodoroSettings settings) {
    _controller.updateSettings(settings);
    widget.store.save(settings);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: '番茄鐘',
          debugShowCheckedModeBanner: false,
          // MaterialApp cross-fades between themes, so the palette eases from
          // one phase to the next instead of snapping.
          theme: buildTheme(buildScheme(
            phase: _phase,
            brightness: Brightness.light,
            dynamicScheme: _useDynamicColor ? lightDynamic : null,
          )),
          darkTheme: buildTheme(buildScheme(
            phase: _phase,
            brightness: Brightness.dark,
            dynamicScheme: _useDynamicColor ? darkDynamic : null,
          )),
          home: TimerScreen(
            controller: _controller,
            onSettingsChanged: _applySettings,
          ),
        );
      },
    );
  }
}
