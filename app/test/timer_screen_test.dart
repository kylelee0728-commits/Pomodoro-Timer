import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/pomodoro_controller.dart';
import 'package:pomodoro/screens/timer_screen.dart';

void main() {
  Future<PomodoroController> pumpTimer(WidgetTester tester) async {
    final controller = PomodoroController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: TimerScreen(controller: controller, onSettingsChanged: (_) {}),
    ));

    return controller;
  }

  testWidgets('shows a full focus session on first paint', (tester) async {
    await pumpTimer(tester);

    expect(find.text('專注中'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('開始'), findsOneWidget);
  });

  testWidgets('the primary button starts and pauses the clock', (tester) async {
    final controller = await pumpTimer(tester);

    await tester.tap(find.text('開始'));
    await tester.pump();

    expect(controller.isRunning, isTrue);
    expect(find.text('暫停'), findsOneWidget);

    await tester.tap(find.text('暫停'));
    await tester.pump();

    expect(controller.isRunning, isFalse);
  });

  testWidgets('skip moves to the break and repaints', (tester) async {
    final controller = await pumpTimer(tester);

    await tester.tap(find.byTooltip('跳過此階段'));
    await tester.pumpAndSettle();

    expect(controller.phase, PomodoroPhase.shortBreak);
    expect(find.text('短休息'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
  });

  testWidgets('the settings screen opens from the app bar', (tester) async {
    await pumpTimer(tester);

    await tester.tap(find.byTooltip('設定'));
    await tester.pumpAndSettle();

    expect(find.text('時間長度'), findsOneWidget);
    expect(find.text('專注'), findsOneWidget);
  });
}
