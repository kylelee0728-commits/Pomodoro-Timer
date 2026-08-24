import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pomodoro_settings.dart';
import '../pomodoro_controller.dart';
import '../theme.dart';
import '../widgets/progress_ring.dart';
import 'settings_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    super.key,
    required this.controller,
    required this.onSettingsChanged,
  });

  final PomodoroController controller;
  final ValueChanged<PomodoroSettings> onSettingsChanged;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.onPhaseComplete = _announce;
  }

  @override
  void dispose() {
    widget.controller.onPhaseComplete = null;
    super.dispose();
  }

  void _announce(PomodoroPhase finished, PomodoroPhase next) {
    final settings = widget.controller.settings;
    if (settings.playSound) SystemSound.play(SystemSoundType.alert);
    if (settings.haptics) HapticFeedback.mediumImpact();

    if (!mounted) return;

    final message = switch (next) {
      PomodoroPhase.focus => '休息結束，開始下一個 ${settings.focusMinutes} 分鐘的專注。',
      PomodoroPhase.shortBreak => '番茄完成！休息 ${settings.shortBreakMinutes} 分鐘。',
      PomodoroPhase.longBreak =>
        '番茄完成！長休息 ${settings.longBreakMinutes} 分鐘，走遠一點。',
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ));
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(
        controller: widget.controller,
        onSettingsChanged: widget.onSettingsChanged,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return CallbackShortcuts(
      // Space is the muscle-memory play/pause key on desktop.
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): controller.startPause,
        const SingleActivator(LogicalKeyboardKey.keyR): controller.reset,
      },
      child: Focus(
        autofocus: true,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => _buildScaffold(context, controller),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, PomodoroController controller) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = phaseAccent(controller.phase, scheme);

    final (title, hint) = switch (controller.phase) {
      PomodoroPhase.focus => ('專注中', '關掉通知，只做一件事'),
      PomodoroPhase.shortBreak => ('短休息', '站起來、看遠方、喝口水'),
      PomodoroPhase.longBreak => ('長休息', '好好離開座位一下'),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄鐘'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune),
            tooltip: '設定',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ringSize = math
                .min(
                  320.0,
                  math.min(
                      constraints.maxWidth - 64, constraints.maxHeight - 260),
                )
                .clamp(180.0, 320.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: ConstrainedBox(
                // Centre the column on a tall window, but let it scroll on a
                // short one instead of overflowing.
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(hint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        )),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: ProgressRing(
                        value: controller.progress,
                        color: accent,
                        trackColor: scheme.surfaceContainerHighest,
                        thickness: 18,
                        child: Text(
                          controller.timeLabel,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w300,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _CycleDots(controller: controller, accent: accent),
                    const SizedBox(height: 8),
                    Text(
                      '今天已完成 ${controller.completedFocusSessions} 個番茄',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Controls(controller: controller),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller});

  final PomodoroController controller;

  @override
  Widget build(BuildContext context) {
    final running = controller.isRunning;
    final label = running ? '暫停' : (controller.progress > 0 ? '繼續' : '開始');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: controller.reset,
          icon: const Icon(Icons.refresh),
          tooltip: '重設此階段',
          iconSize: 24,
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: controller.startPause,
          icon: Icon(running ? Icons.pause : Icons.play_arrow),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size(148, 56),
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          onPressed: controller.skip,
          icon: const Icon(Icons.skip_next),
          tooltip: '跳過此階段',
          iconSize: 24,
        ),
      ],
    );
  }
}

/// One dot per focus session in the current long-break cycle.
class _CycleDots extends StatelessWidget {
  const _CycleDots({required this.controller, required this.accent});

  final PomodoroController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final total = controller.settings.longBreakInterval;
    final done = controller.phase == PomodoroPhase.longBreak
        ? total
        : controller.completedFocusSessions % total;

    return Wrap(
      spacing: 8,
      children: List.generate(total, (index) {
        final filled = index < done;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? accent
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }),
    );
  }
}
