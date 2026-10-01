// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro_to_deploy/main.dart';

void main() {
  testWidgets('Pomodoro app displays timer and focus settings', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      previousFlutterErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousFlutterErrorHandler);
    SharedPreferences.setMockInitialValues({
      'totalSprints': 4,
      'breakMinutes': 4,
      'dailyGoal': 20,
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsNothing);
    expect(
      tester.getSize(find.byType(CircularProgressIndicator)).width,
      greaterThan(215),
    );
    expect(tester.widget<Text>(find.text('25:00')).maxLines, 1);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.stop), findsOneWidget);

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.stop), findsNothing);

    tester.view.physicalSize = const Size(680, 800);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNWidgets(2));
    expect(
      tester.widget<Text>(find.text('Settings').first).style?.fontSize,
      36,
    );
    expect(find.text('Sprint Setting'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Sprint Setting')).style?.fontSize,
      22,
    );
    expect(find.text('Focus session'), findsNothing);
    expect(find.text('1h 55m'), findsOneWidget);
    expect(find.text('100 min focus, 15 min rest'), findsOneWidget);
    expect(find.text('Sprint length'), findsOneWidget);
    expect(find.text('(Standard Pomodoro)'), findsOneWidget);
    expect(find.text('Sprints per session'), findsOneWidget);
    expect(find.text("Focus rounds before you're done"), findsNothing);
    expect(find.text('Break length'), findsOneWidget);
    expect(find.text('Rest between sprints'), findsNothing);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('Daily goal'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Daily goal')).style?.fontSize, 22);
    expect(find.text('Session per day'), findsOneWidget);
    expect(find.text('Sprints per day'), findsNothing);
    expect(find.text('About 20 sessions a day'), findsNothing);
    expect(find.text('20 sprints'), findsNothing);

    final sprintCountField =
      find.byKey(const ValueKey('value-Sprints per session'));
    final breakLengthField = find.byKey(const ValueKey('value-Break length'));
    final sessionsPerDayField = find.byKey(const ValueKey('value-Session per day'));
    expect(tester.widget<TextField>(sessionsPerDayField).controller!.text, '20');
    expect(
      find.byKey(const ValueKey('decrement-Break length')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('increment-Break length')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('increment-Session per day')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('decrement-Session per day')),
      findsOneWidget,
    );
    final minBreakButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('decrement-Break length')),
    );
    final maxGoalButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('increment-Session per day')),
    );
    expect(minBreakButton.onPressed, isNull);
    expect(maxGoalButton.onPressed, isNull);
    expect(
      minBreakButton.style?.backgroundColor?.resolve({WidgetState.disabled}),
      isNot(minBreakButton.style?.backgroundColor?.resolve({})),
    );
    expect(
      maxGoalButton.style?.backgroundColor?.resolve({WidgetState.disabled}),
      isNot(maxGoalButton.style?.backgroundColor?.resolve({})),
    );

    final valueCenterX = tester.getCenter(sprintCountField).dx;
    expect(tester.getCenter(breakLengthField).dx, closeTo(valueCenterX, 0.1));
    expect(
      tester.getCenter(sessionsPerDayField).dx,
      closeTo(valueCenterX, 0.1),
    );
    expect(
      tester.widget<Text>(find.text('Sprints per session')).style?.fontSize,
      16,
    );
    expect(
      tester.widget<Text>(find.text('(Standard Pomodoro)')).style?.fontSize,
      14,
    );

    final fixedSprintValue = tester.widget<Text>(find.text('25 min'));
    final adjustableSprintValue = tester.widget<TextField>(sprintCountField);
    final fixedNumberStyle =
        (fixedSprintValue.textSpan! as TextSpan).children!.first.style;
    final adjustableNumberStyle = adjustableSprintValue.style;
    expect(fixedNumberStyle?.fontSize, adjustableNumberStyle?.fontSize);
    expect(fixedNumberStyle?.fontWeight, adjustableNumberStyle?.fontWeight);
    final lightScheme = Theme.of(
      tester.element(find.text('25 min')),
    ).colorScheme;
    final fixedPill = tester.widget<Container>(
      find.byKey(const ValueKey('fixedSprintValuePill')),
    );
    final lightSummary = tester.widget<Container>(
      find.byKey(const ValueKey('sessionSummary')),
    );
    expect(fixedNumberStyle?.color, adjustableNumberStyle?.color);
    expect(fixedNumberStyle?.color, lightScheme.onSurface);
    expect(
      (fixedPill.decoration! as BoxDecoration).color,
      lightScheme.primaryContainer,
    );
    expect(
      (lightSummary.decoration! as BoxDecoration).color,
      lightScheme.surfaceContainerLow,
    );

    await tester.tap(breakLengthField);
    await tester.enterText(breakLengthField, '2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(breakLengthField).controller!.text, '5');

    await tester.tap(sessionsPerDayField);
    await tester.enterText(sessionsPerDayField, '99');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(sessionsPerDayField).controller!.text, '20');
    final lightRestSegment = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('restTimeSegment')),
    );
    expect(
      (lightRestSegment.decoration as BoxDecoration).color,
      const Color(0xFF246B91),
    );

    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, 600));
    await tester.pumpAndSettle();
    final darkScheme = Theme.of(
      tester.element(find.text('1h 55m')),
    ).colorScheme;
    final summary = tester.widget<Container>(
      find.byKey(const ValueKey('sessionSummary')),
    );
    expect(darkScheme.primary, const Color(0xFFFF7A62));
    expect(darkScheme.primaryContainer, const Color(0xFF2B2B2B));
    expect(
      (summary.decoration! as BoxDecoration).color,
      darkScheme.surfaceContainerLow,
    );
    final darkRestSegment = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('restTimeSegment')),
    );
    expect(
      (darkRestSegment.decoration as BoxDecoration).color,
      const Color(0xFF79BDE2),
    );
    final darkMinusButton = tester.widget<IconButton>(
      find.byIcon(Icons.remove).first,
    );
    expect(
      darkMinusButton.style?.backgroundColor?.resolve({}),
      lightScheme.secondaryContainer,
    );
    expect(
      darkMinusButton.style?.foregroundColor?.resolve({}),
      lightScheme.onSecondaryContainer,
    );
  });
}
