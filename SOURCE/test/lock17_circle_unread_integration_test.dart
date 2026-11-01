// LOCK17: existing Circle fixture reads belong to the current viewer only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_conversation_unread_badge.dart';
import 'package:zyra/dev/zyra_circle_topics_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/'
    'LOCK17_UNREAD_BADGE_2026-10-31';
const _readKey =
    'draft-self:draft-self:draft-circle-response:draft-guardian-hassan';
const _otherReadKey =
    'draft-linked-yusuf:draft-guardian-hassan:other:other-sender';
const _circleFocus = 'circle:response:draft-guardian-hassan';

BaselineHarness _h(WidgetTester t) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(t, group: 'lock17', evidenceRoot: _evidence);
}

ZyraOneJourneyGuardianCards _page(WidgetTester t) =>
    t.widget<ZyraOneJourneyGuardianCards>(
      find.byType(ZyraOneJourneyGuardianCards),
    );
int _count(WidgetTester t) => t
    .widget<ZyraConversationUnreadBadge>(
      find.byType(ZyraConversationUnreadBadge),
    )
    .unreadCount;

Future<void> _tab(BaselineHarness h, int index) async {
  h.tester
      .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
      .onTap(index);
  await h.flush();
}

Future<void> _back(BaselineHarness h) async {
  await returnZyraPreviewPage(h.tester);
  await h.flush();
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize('lock17-owner-a');
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
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
    'badge entry preserves the actual Circle composer and local send',
    (t) async {
      final h = _h(t);
      await h.mount(tab: 3);
      await h.tap('guardian-family-messages-top');
      h.assertPage('guardian_circle');
      expect(find.byType(ZyraCircleTopicsPresentation), findsOneWidget);
      final field = find.byKey(const ValueKey('circle_topics_composer'));
      expect(field, findsOneWidget);
      final reader = t.widget<ZyraGuardianCircleScreen>(
        find.byType(ZyraGuardianCircleScreen),
      );
      final controller = t.widget<TextField>(field).controller;
      await t.enterText(field, 'One scoped local Circle message.');
      await h.flush();
      expect(t.widget<TextField>(field).controller, same(controller));
      expect(
        t
            .widget<ZyraGuardianCircleScreen>(
              find.byType(ZyraGuardianCircleScreen),
            )
            .previewData,
        same(reader.previewData),
      );
      await t.tap(find.byKey(const ValueKey('circle_topics_send')));
      await h.flush();
      expect(find.text('One scoped local Circle message.'), findsOneWidget);
      expect(h.latest.circleReadMessageKeys, {_readKey});
      await _back(h);
      expect(_count(t), 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'real Circle count clears only its own read facts and survives restore',
    (t) async {
      final h = _h(t);
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel().snapshot(),
          tab: 3,
          pages: [],
          circleReadMessageKeys: const [_otherReadKey],
        ),
      );
      expect(_count(t), 1);
      final requestsBefore = h.latest.model.acknowledgedReceivedRequestIds;
      await h.tap('guardian-family-messages-top');
      h.assertPage('guardian_circle');
      final reader = t.widget<ZyraGuardianCircleScreen>(
        find.byType(ZyraGuardianCircleScreen),
      );
      expect(reader.previewData!.messages, hasLength(2));
      expect(reader.previewData!.messages.every((m) => !m.unreadForMe), isTrue);
      expect(h.latest.circleReadMessageKeys, {_readKey, _otherReadKey});
      expect(h.latest.model.acknowledgedReceivedRequestIds, requestsBefore);
      await _back(h);
      expect(_count(t), 0);
      await h.mount(checkpoint: h.latest);
      expect(_count(t), 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Focus consumption cannot mark a Circle message read',
    (t) async {
      final h = _h(t);
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel().snapshot(),
          tab: 3,
          pages: [],
          myZyraConsumedFocusTokens: const [_circleFocus],
        ),
      );
      expect(_count(t), 1);
      expect(h.latest.circleReadMessageKeys, isEmpty);
      await h.tap('guardian-family-messages-top');
      expect(h.latest.circleReadMessageKeys, {_readKey});
      expect(h.latest.myZyraConsumedFocusTokens, contains(_circleFocus));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'opening from Focus also clears the current Circle only',
    (t) async {
      final h = _h(t);
      await h.mount(tab: 2);
      await h.tap('focus-dot-target-1');
      await h.tap('focus-open-guardian_circle');
      h.assertPage('guardian_circle');
      expect(h.latest.circleReadMessageKeys, {_readKey});
      await _back(h);
      await _tab(h, 3);
      expect(_count(t), 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'no current Guardian link means zero, regardless of Focus fixture',
    (t) async {
      final h = _h(t);
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel().snapshot(),
          tab: 3,
          pages: [],
          removedGuardians: draftGuardians.map((g) => g.id),
        ),
      );
      expect(_count(t), 0);
      _page(t).onCircle();
      await h.flush();
      expect(find.byType(ZyraGuardianCircleScreen), findsNothing);
      expect(h.latest.circleReadMessageKeys, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'an already-read different sender cannot clear current sender',
    (t) async {
      final h = _h(t);
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel().snapshot(),
          tab: 3,
          pages: [],
          circleReadMessageKeys: const [
            'draft-self:draft-self:draft-circle-response:unrelated-guardian',
          ],
        ),
      );
      expect(_count(t), 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  for (final scenario in [
    'controls',
    'navigation',
    'role',
    'account',
    'link',
  ]) {
    testWidgets(
      'retained Circle callback expires after $scenario changes',
      (t) async {
        final h = _h(t);
        await h.mount(tab: 3);
        final retained = _page(t).onCircle;
        switch (scenario) {
          case 'controls':
            await h.controls();
            await h.closeControls();
          case 'navigation':
            await _tab(h, 2);
            await _tab(h, 3);
          case 'role':
            await h.controls();
            await h.tap('draft_role_guardian');
            await h.controls();
            await h.tap('draft_role_seeker');
            await _tab(h, 3);
          case 'account':
            await t.runAsync(() async {
              await ZyraAccountState.synchronize('lock17-owner-b');
              await ZyraAccountState.synchronize('lock17-owner-a');
            });
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          case 'link':
            expect(await _page(t).remove('draft-guardian-hassan'), isNull);
            await h.flush();
        }
        final before = h.latest;
        retained();
        await h.flush();
        expect(h.latest.pages, before.pages);
        expect(h.latest.tab, before.tab);
        expect(h.latest.circleReadMessageKeys, isEmpty);
        expect(
          h.latest.myZyraConsumedFocusTokens,
          before.myZyraConsumedFocusTokens,
        );
        if (scenario != 'account') {
          expect(_count(t), 1);
          // A newly issued callback remains usable.
          _page(t).onCircle();
          await h.flush();
          h.assertPage('guardian_circle');
          expect(h.latest.circleReadMessageKeys, hasLength(1));
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets(
    'restoring an open reader clears its messages, without another account fact',
    (t) async {
      final h = _h(t);
      await h.mount(pages: ['guardian_circle'], tab: 3);
      h.assertPage('guardian_circle');
      expect(h.latest.circleReadMessageKeys, {_readKey});
      // Fresh owner/checkpoint starts from the actual unread fixture again.
      await t.runAsync(() => ZyraAccountState.synchronize('lock17-owner-b'));
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await h.mount(tab: 3);
      expect(_count(t), 1);
      expect(h.latest.circleReadMessageKeys, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
