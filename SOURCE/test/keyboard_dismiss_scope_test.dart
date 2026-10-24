import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_keyboard_dismiss_scope.dart';

void main() {
  testWidgets('a tap outside dismisses the field and keeps the tap working', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var buttonTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ZyraKeyboardDismissScope(
          child: Scaffold(
            body: Column(
              children: [
                TextField(
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Feedback'),
                ),
                FilledButton(
                  onPressed: () => buttonTaps += 1,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Send'));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
    expect(buttonTaps, 1);
  });

  testWidgets('tapping inside the active field keeps it focused', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ZyraKeyboardDismissScope(
          child: Scaffold(body: TextField(focusNode: focusNode)),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('explicit page change dismissal clears a mounted field', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(focusNode: focusNode)),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    dismissZyraKeyboardAfterNavigation();
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('changing route dismisses a field even without an outside tap', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [ZyraKeyboardDismissNavigatorObserver()],
        home: Scaffold(body: TextField(focusNode: focusNode)),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Next page')),
      ),
    );
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
    expect(find.text('Next page'), findsOneWidget);
  });

  testWidgets('popping a form route clears its keyboard focus immediately', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final formFocus = FocusNode();
    addTearDown(formFocus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [ZyraKeyboardDismissNavigatorObserver()],
        home: const Scaffold(body: Text('Profile')),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: TextField(focusNode: formFocus)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(formFocus.hasFocus, isTrue);

    navigatorKey.currentState!.pop();
    await tester.pump();

    expect(formFocus.hasFocus, isFalse);
  });
}
