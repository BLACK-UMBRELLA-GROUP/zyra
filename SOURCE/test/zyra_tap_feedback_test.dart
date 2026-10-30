import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profiles_components.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';

void main() {
  final pulses = <Object?>[];
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInteractionStyle.restoreDefaults();
    pulses.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            pulses.add(call.arguments);
          }
          return null;
        });
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'shared request pill obeys live level, disabled and revoked state',
    (tester) async {
      var level = ZyraHapticLevel.subtle;
      var allowed = true;
      var requests = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ZyraTapFeedback(
            level: () => level,
            canAct: () => allowed,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 380,
                  child: ZyraProfilesRequestRow(
                    actionKey: const ValueKey('request'),
                    label: 'Request a Journey',
                    labels: const ['Request a Journey'],
                    sent: false,
                    onPrevious: null,
                    onRequest: () => requests++,
                    onNext: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('request')));
      await tester.pump();
      expect(pulses, ['HapticFeedbackType.selectionClick']);
      expect(requests, 1);
      pulses.clear();
      await tester.tap(find.byKey(const ValueKey('concept_previous_profile')));
      expect(pulses, isEmpty);
      level = ZyraHapticLevel.off;
      await tester.tap(find.byKey(const ValueKey('request')));
      expect(requests, 2);
      expect(pulses, isEmpty);
      level = ZyraHapticLevel.medium;
      await tester.tap(find.byKey(const ValueKey('request')));
      await tester.pump();
      expect(pulses, ['HapticFeedbackType.mediumImpact']);
      pulses.clear();
      allowed = false;
      await tester.tap(find.byKey(const ValueKey('request')));
      expect(requests, 3);
      expect(pulses, isEmpty);
    },
  );

  testWidgets('captured sheet reads the live scope and typing stays silent', (
    tester,
  ) async {
    var level = ZyraHapticLevel.light;
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraTapFeedback(
          level: () => level,
          canAct: () => true,
          child: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  const TextField(key: ValueKey('typing')),
                  TextButton(
                    onPressed: ZyraTapFeedback.onTap(context, () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => TextButton(
                          key: const ValueKey('sheet-action'),
                          onPressed: ZyraTapFeedback.onTap(context, () {}),
                          child: const Text('Choose'),
                        ),
                      );
                    }),
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('typing')), 'Sample');
    expect(pulses, isEmpty);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(pulses, ['HapticFeedbackType.lightImpact']);
    pulses.clear();
    level = ZyraHapticLevel.strong;
    await tester.tap(find.byKey(const ValueKey('sheet-action')));
    await tester.pump();
    expect(pulses, ['HapticFeedbackType.heavyImpact']);
    pulses.clear();
    level = ZyraHapticLevel.off;
    await tester.tap(find.byKey(const ValueKey('sheet-action')));
    expect(pulses, isEmpty);
  });

  test('nested and asynchronous delegated feedback stays one pulse', () async {
    Future<void>? pending;
    ZyraInteractionStyle.performSelectionTap(() {
      ZyraInteractionStyle.performSelectionTap(() {
        pending = Future<void>(() async {
          await ZyraInteractionStyle.emitSelectionHaptic();
        });
      });
    });
    await pending;
    expect(pulses, ['HapticFeedbackType.selectionClick']);
    pulses.clear();
    ZyraInteractionStyle.performSelectionTap(() {
      ZyraInteractionStyle.cancelSelectionTap();
    });
    expect(pulses, isEmpty);
  });
}
