import 'package:flutter/material.dart';

import '../models/pomodoro_settings.dart';
import '../pomodoro_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.onSettingsChanged,
  });

  final PomodoroController controller;
  final ValueChanged<PomodoroSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.settings;

        return Scaffold(
          appBar: AppBar(title: const Text('設定')),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _SectionHeader('時間長度'),
              _MinuteSlider(
                label: '專注',
                value: settings.focusMinutes,
                min: 5,
                max: 90,
                onChanged: (v) => onSettingsChanged(settings.copyWith(focusMinutes: v)),
              ),
              _MinuteSlider(
                label: '短休息',
                value: settings.shortBreakMinutes,
                min: 1,
                max: 30,
                onChanged: (v) => onSettingsChanged(settings.copyWith(shortBreakMinutes: v)),
              ),
              _MinuteSlider(
                label: '長休息',
                value: settings.longBreakMinutes,
                min: 5,
                max: 60,
                onChanged: (v) => onSettingsChanged(settings.copyWith(longBreakMinutes: v)),
              ),
              _MinuteSlider(
                label: '幾個番茄後長休息',
                value: settings.longBreakInterval,
                min: 2,
                max: 8,
                unit: '個',
                onChanged: (v) => onSettingsChanged(settings.copyWith(longBreakInterval: v)),
              ),
              const Divider(height: 32),
              _SectionHeader('自動接續'),
              SwitchListTile(
                title: const Text('專注結束後自動開始休息'),
                value: settings.autoStartBreaks,
                onChanged: (v) => onSettingsChanged(settings.copyWith(autoStartBreaks: v)),
              ),
              SwitchListTile(
                title: const Text('休息結束後自動開始專注'),
                value: settings.autoStartFocus,
                onChanged: (v) => onSettingsChanged(settings.copyWith(autoStartFocus: v)),
              ),
              const Divider(height: 32),
              _SectionHeader('提示與外觀'),
              SwitchListTile(
                title: const Text('提示音'),
                value: settings.playSound,
                onChanged: (v) => onSettingsChanged(settings.copyWith(playSound: v)),
              ),
              SwitchListTile(
                title: const Text('震動回饋'),
                subtitle: const Text('行動裝置適用'),
                value: settings.haptics,
                onChanged: (v) => onSettingsChanged(settings.copyWith(haptics: v)),
              ),
              SwitchListTile(
                title: const Text('跟隨系統動態色彩'),
                subtitle: const Text('關閉時，配色會隨階段變換'),
                value: settings.dynamicColor,
                onChanged: (v) => onSettingsChanged(settings.copyWith(dynamicColor: v)),
              ),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    controller.resetCycle();
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(const SnackBar(content: Text('今日進度已重設')));
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('重設今日進度'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _MinuteSlider extends StatelessWidget {
  const _MinuteSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '分鐘',
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                '$value $unit',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}
