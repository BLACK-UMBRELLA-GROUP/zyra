import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_guardian_family_preview.dart';
import 'package:zyra/dev/zyra_membership_preview.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _root = 'build/line136';
const _capture = bool.fromEnvironment('ZYRA_LINE136_CAPTURE');
Finder _key(String id) => find.byKey(ValueKey(id));

ZyraPreviewNavigationCheckpoint _covered({
  String name = 'Adam',
  String gender = 'male',
}) => ZyraPreviewNavigationCheckpoint(
  guardian: true,
  model: ViewRequestDraftModel(capacity: 3).snapshot(),
  tab: 4,
  pages: const [],
  guardianFamily: ZyraGuardianFamilyPreviewSnapshot(
    freePlaces: 0,
    sequence: 1,
    invites: [
      ZyraGuardianFamilyInvite(
        revision: 1,
        guardianId: 'draft-guardian-hassan',
        guardianName: 'Hassan',
        seekerId: 'local-payer',
        seekerName: name,
        seekerGender: gender,
        relationship: 'Father',
        main: true,
        sentAt: DateTime(2026, 11, 24),
        status: ZyraGuardianFamilyInviteStatus.accepted,
      ),
    ],
  ),
);

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  BaselineHarness harness(
    WidgetTester t,
    String name, {
    Size size = const Size(430, 932),
    double scale = 1,
  }) {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    return BaselineHarness(
      t,
      group: 'line136_$name',
      logicalSize: size,
      textScale: scale,
      outputRoot: '$_root/screens',
      evidenceRoot: '$_root/screens',
      flatOutput: true,
      safePadding: size.width == 375
          ? const EdgeInsets.only(top: 20)
          : const EdgeInsets.only(top: 59, bottom: 34),
    );
  }

  Future<void> check(BaselineHarness h, String name) async {
    final previousShadows = debugDisableShadows;
    try {
      debugDisableShadows = false;
      await h.tester.pump(const Duration(milliseconds: 2600));
      final boundary = h.tester.renderObject<RenderRepaintBoundary>(
        _key('zyra-founder-baseline-boundary'),
      );
      final result = await auditZyraRenderedText(h.tester, boundary);
      await h.tester.runAsync(() async {
        final file = File('$_root/audit/$name.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(result.toJson()));
      });
      expect(result.failures, isEmpty, reason: '$name ${result.toJson()}');
      void repaint(RenderObject object) {
        object.visitChildren(repaint);
        object.markNeedsPaint();
      }

      repaint(boundary);
      await h.tester.pump();
      await h.capture(
        'membership',
        name,
        'normal',
        name,
        fileName: '$name.png',
      );
    } finally {
      debugDisableShadows = previousShadows;
    }
  }

  for (final variant in [
    ('mb01_seeker_one', false, false, false),
    ('mb02_seeker_one__free_trial', false, true, false),
    ('mb03_guardian_one', true, false, false),
    ('mb04_guardian_one__free_trial', true, true, false),
    ('mb05_guardian_one__family_paid', true, false, true),
  ]) {
    testWidgets('LOCK42 master ${variant.$1} actual Profile route', (t) async {
      final h = harness(t, variant.$1);
      await h.mount(
        guardian: variant.$2,
        tab: 4,
        checkpoint: variant.$4 ? _covered() : null,
        membershipRecords: {
          for (final role in ZyraWalletRole.values)
            role: ZyraMembershipPreviewRecord(
              date: DateTime(2026, 12, 6),
              trial: variant.$3,
            ),
        },
      );
      await h.tap('concept_membership');
      h.assertPage('membership');
      expect(_key('membership_paid_page'), findsOneWidget);
      expect(_key('floating-nav-item-0'), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      if (variant.$4) {
        expect(_key('concept_cancel_membership'), findsNothing);
        expect(find.text('Paid by Adam · ZYRA Family'), findsOneWidget);
      }
      await check(h, variant.$1);
    }, skip: !_capture);
  }

  for (final guardian in [false, true]) {
    testWidgets(
      'LOCK42 ${guardian ? 'Guardian' : 'Seeker'} actions and owner expiry',
      (t) async {
        final h = harness(t, 'actions_$guardian');
        await h.mount(guardian: guardian, tab: 4);
        await h.tap('concept_membership');
        final page = t.widget<ZyraMembershipPreview>(
          find.byType(ZyraMembershipPreview),
        );
        await h.tap('membership_more_restore');
        expect(
          find.text('ZYRA checks your Apple ID for earlier purchases.'),
          findsOneWidget,
        );
        if (guardian) {
          await h.tap('membership_more_covered');
          expect(
            find.text(
              'A Seeker can cover you with a place in their ZYRA Family. You pay nothing.',
            ),
            findsOneWidget,
          );
        } else {
          await h.tap('membership_more_family');
          expect(find.text('Opens ZYRA Family.'), findsOneWidget);
          await h.tap('membership_more_unlocks');
          h.assertPage('compatibility_store');
          await t.binding.handlePopRoute();
          await h.flush();
        }
        await h.tap('membership_more_compare');
        h.assertPage('one_upgrade');
        page.onRestore();
        page.onCancel();
        page.onUnlocks();
        await h.flush();
        h.assertPage('one_upgrade');
        expect(
          find.text('ZYRA checks your Apple ID for earlier purchases.'),
          findsNothing,
        );
        await t.binding.handlePopRoute();
        await h.flush();
        h.assertPage('membership');
        await t.binding.handlePopRoute();
        await h.flush();
        expect(h.latest.pages, isEmpty);
        expect(_key('concept_membership'), findsOneWidget);
      },
    );
  }

  testWidgets('LOCK42 cancel uses existing App Store subscriptions action', (
    t,
  ) async {
    final launches = <String>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') {
        launches.add((call.arguments as Map)['url'] as String);
        return true;
      }
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final h = harness(t, 'cancel');
    await h.mount(tab: 4);
    await h.tap('concept_membership');
    await h.tap('concept_cancel_membership');
    await t.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    expect(launches, ['https://apps.apple.com/account/subscriptions']);
    h.assertPage('membership');
  });

  testWidgets(
    'LOCK42 accepted Family payer keeps female pronoun and no cancel',
    (t) async {
      final h = harness(t, 'family_female');
      await h.mount(
        guardian: true,
        tab: 4,
        checkpoint: _covered(name: 'Maryam', gender: 'female'),
      );
      await h.tap('concept_membership');
      await h.tap('membership_more_covered');
      expect(
        find.text(
          'Maryam covers you with a place in her ZYRA Family. You pay nothing.',
        ),
        findsOneWidget,
      );
      expect(_key('concept_cancel_membership'), findsNothing);
    },
  );

  for (final guardian in [false, true]) {
    testWidgets(
      'LOCK42 no purchase record uses reasoned loading/error fallback $guardian',
      (t) async {
        final h = harness(t, 'no_record_$guardian');
        await h.mount(guardian: guardian, tab: 4, membershipRecords: const {});
        await h.tap('concept_membership');
        expect(find.textContaining('6 Dec'), findsNothing);
        expect(find.textContaining('Free trial'), findsNothing);
        expect(find.text('Turn off renewal in App Store.'), findsOneWidget);
        if (_capture) await check(h, 'no_record_$guardian');
      },
    );
  }

  for (final guardian in [false, true]) {
    testWidgets(
      'LOCK42 narrow Larger Text scroll and rendered text $guardian',
      (t) async {
        final h = harness(
          t,
          'larger_$guardian',
          size: const Size(375, 667),
          scale: 1.3,
        );
        await h.mount(guardian: guardian, tab: 4);
        await h.tap('concept_membership');
        await check(h, 'larger_${guardian}_top');
        await t.drag(_key('membership_paid_scroll'), const Offset(0, -900));
        await h.flush();
        expect(_key('concept_cancel_membership').hitTestable(), findsOneWidget);
        await check(h, 'larger_${guardian}_bottom');
      },
      skip: !_capture,
    );
  }
}
