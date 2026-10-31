// LOCK17: actual offline Founder Circle counts and read acknowledgement.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_conversation_unread_badge.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _output = '$_root/PRODUCT/APPROVED/UNREAD_BADGE/BUILT';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK17_UNREAD_BADGE_2026-10-31';
const _capture = bool.fromEnvironment('ZYRA_LOCK17_CAPTURE');

BaselineHarness _harness(WidgetTester tester, {double textScale = 1}) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'lock17_$textScale',
    flatOutput: true,
    outputRoot: _output,
    evidenceRoot: _evidence,
    textScale: textScale,
  );
}

void _expectUnread(WidgetTester tester, int count) {
  final badges = tester.widgetList<ZyraConversationUnreadBadge>(
    find.byType(ZyraConversationUnreadBadge),
  );
  if (count > 0) {
    expect(badges, hasLength(1));
    expect(badges.single.unreadCount, count);
  } else {
    expect(badges.every((badge) => badge.unreadCount == 0), isTrue);
  }
}

Future<void> _cap(BaselineHarness harness, String name) async {
  if (!_capture) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(
      harness.tester.renderObject(
        find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
      ),
    );
    await harness.tester.pump();
    await harness.capture(
      'unread_badge',
      name,
      name,
      'Actual admitted offline Founder shell and existing local Circle data.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = previous;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          zyraPhoneAccessChannel,
          (call) async => call.method == 'status'
              ? {
                  'notifications': 'allowed',
                  'location': 'allowed',
                  'photos': 'limited',
                  'camera': 'notDetermined',
                  'faceID': 'notDetermined',
                }
              : null,
        );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraPhoneAccessChannel, null),
  );

  testWidgets(
    'LOCK17 u01 u02: existing Circle unread clears only when opened',
    (tester) async {
      final h = _harness(tester);
      await h.mount(tab: 3);
      _expectUnread(tester, 1);
      await _cap(h, 'u01_guardian_tab_circle_unread');
      await h.tap('guardian-family-messages-top');
      h.assertPage('guardian_circle');
      final circle = tester.widget<ZyraGuardianCircleScreen>(
        find.byType(ZyraGuardianCircleScreen),
      );
      expect(circle.previewData, isNotNull);
      expect(circle.previewData!.messages, isNotEmpty);
      expect(
        circle.previewData!.messages.every((message) => !message.unreadForMe),
        isTrue,
      );
      await returnZyraPreviewPage(tester);
      await h.flush();
      _expectUnread(tester, 0);
      await _cap(h, 'u02_guardian_tab_circle_read');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK17 u03: no linked Guardian has no Circle unread bubble',
    (tester) async {
      final h = _harness(tester);
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel().snapshot(),
          tab: 3,
          pages: [],
          removedGuardians: draftGuardians.map((guardian) => guardian.id),
        ),
      );
      _expectUnread(tester, 0);
      await _cap(h, 'u03_no_guardian');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK17 u04: Guardian role adds no unsupported count',
    (tester) async {
      final h = _harness(tester);
      await h.mount(guardian: true, tab: 3);
      expect(find.byType(ZyraConversationUnreadBadge), findsNothing);
      await _cap(h, 'u04_guardian');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK17 u05: actual Guardian tab at 430 and text scale 1.3',
    (tester) async {
      final h = _harness(tester, textScale: 1.3);
      await h.mount(tab: 3);
      _expectUnread(tester, 1);
      await _cap(h, 'u05_guardian_tab_text_scale_1_3');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK17 isolated component count boundaries and external ring',
    (tester) async {
      final h = _harness(tester);
      await h.mountPresentation(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel().snapshot(),
          tab: 3,
          pages: [],
        ),
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Component fixtures: 0 / 1 / 9 / 10'),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final count in [0, 1, 9, 10])
                      ZyraConversationUnreadBadge(
                        key: ValueKey('component-count-$count'),
                        unreadCount: count,
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.forum_outlined),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('9+'), findsOneWidget);
      for (final count in [1, 9, 10]) {
        final box = find.descendant(
          of: find.byKey(ValueKey('component-count-$count')),
          matching: find.byType(DecoratedBox),
        );
        expect(tester.getSize(box).height, 16);
        final decoration =
            tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
        expect(decoration.border, isNull);
        expect(decoration.boxShadow!.single.spreadRadius, 2);
      }
      await _cap(h, 'u06_component_count_boundaries');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
