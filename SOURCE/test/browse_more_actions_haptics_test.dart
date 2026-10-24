import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/browse/browse_screen.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

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
            call.arguments == 'HapticFeedbackType.selectionClick',
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
            call.arguments == 'HapticFeedbackType.selectionClick',
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
      var cancels = 0;
      var confirms = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FloatingNavConfirmationBar(
                  onCancel: () => cancels++,
                  onConfirm: () => confirms++,
                ),
              ],
            ),
          ),
        ),
      );

      final cancel = find.byKey(const ValueKey('browse-hide-cancel'));
      final confirm = find.byKey(const ValueKey('browse-hide-confirm'));
      expect(cancel, findsOneWidget);
      expect(confirm, findsOneWidget);
      expect(
        tester.getRect(cancel).left,
        lessThan(tester.getRect(confirm).left),
      );
      expect(
        tester.getSize(cancel).width,
        closeTo(tester.getSize(confirm).width, 0.01),
      );
      expect(
        tester.getSize(cancel).width + tester.getSize(confirm).width,
        greaterThan(700),
      );
      expect(
        tester.widget<Text>(find.text('Hide profile')).style?.color,
        ZyraColors.destructive,
      );

      await tester.tap(cancel);
      await tester.tap(confirm);
      await tester.pump();
      expect(cancels, 1);
      expect(confirms, 1);
    },
  );

  testWidgets('hide confirmation has no popup and page tap restores nav', (
    tester,
  ) async {
    var confirming = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Stack(
              children: [
                if (!confirming)
                  const Center(child: Text('Original navigation')),
                if (confirming)
                  Positioned.fill(
                    child: ZyraBrowseActionModeDismissLayer(
                      onDismiss: () => setState(() => confirming = false),
                    ),
                  ),
                if (confirming)
                  FloatingNavConfirmationBar(
                    onCancel: () => setState(() => confirming = false),
                    onConfirm: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hide this profile?'), findsNothing);
    await tester.tapAt(const Offset(400, 200));
    await tester.pump();
    expect(find.text('Original navigation'), findsOneWidget);
    expect(find.byType(FloatingNavConfirmationBar), findsNothing);
  });
}
