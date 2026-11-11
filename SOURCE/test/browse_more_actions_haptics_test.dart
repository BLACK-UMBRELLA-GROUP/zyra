import 'support/confirm_sheet_test_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/browse/browse_screen.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('Browse three-dot action emits haptic and opens once', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraBrowseMoreActionsButton(onPressed: () => opens++),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('browse-more-actions')));
    await tester.pump();

    expect(opens, 1);
    expect(
      calls.where(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.lightImpact',
      ),
      hasLength(1),
    );
  });

  testWidgets('Browse three-dot emits haptic on open and overlay close', (
    tester,
  ) async {
    var open = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: ZyraBrowseMoreActionsButton(
                    onPressed: () => setState(() => open = true),
                  ),
                ),
                if (open)
                  Positioned.fill(
                    child: ZyraBrowseActionModeDismissLayer(
                      onDismiss: () => setState(() => open = false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('browse-more-actions'));
    await tester.tap(button);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('browse-action-mode-dismiss-layer')),
      findsOneWidget,
    );

    await tester.tapAt(tester.getCenter(button));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('browse-action-mode-dismiss-layer')),
      findsNothing,
    );
    expect(
      calls.where(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.lightImpact',
      ),
      hasLength(2),
    );
  });

  testWidgets('Browse three-dot still opens when member haptics are off', (
    tester,
  ) async {
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    var opens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraBrowseMoreActionsButton(onPressed: () => opens++),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('browse-more-actions')));
    await tester.pump();

    expect(opens, 1);
    expect(
      calls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
  });

  testWidgets(
    'Hide confirmation fills the nav with Cancel then red Hide profile',
    (tester) async {
      final choices = <bool?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ConfirmSheetTestEntry(onDecision: choices.add)),
        ),
      );
      final cancel = find.byKey(const ValueKey('browse-hide-cancel'));
      final confirm = find.byKey(const ValueKey('browse-hide-confirm'));
      Future<void> open() async {
        await tester.tap(find.text('Open confirmation'));
        await tester.pumpAndSettle();
      }

      await open();
      expect(
        tester.getRect(confirm).bottom,
        lessThan(tester.getRect(cancel).top),
      );
      expect(
        tester.getSize(cancel).width,
        closeTo(tester.getSize(confirm).width, .01),
      );
      expect(
        tester.widget<Text>(find.text('Hide profile')).style?.color,
        ZyraColors.dangerText,
      );
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      await open();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(choices, [false, true]);
    },
  );

  testWidgets('hide confirmation has no popup and page tap restores nav', (
    tester,
  ) async {
    final choices = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('Original navigation'),
              ConfirmSheetTestEntry(onDecision: choices.add),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    expect(find.text('Hide Sara?'), findsOneWidget);
    await tester.tapAt(const Offset(400, 100));
    await tester.pumpAndSettle();
    expect(find.text('Original navigation').hitTestable(), findsOneWidget);
    expect(find.text('Hide Sara?'), findsNothing);
    expect(choices, [null]);
  });
}
