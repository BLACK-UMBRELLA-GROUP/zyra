// LOCK19 V3: actual admitted local shell. Fixture offers are labelled in captures.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_guardian_family_preview.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_action.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'baseline_capture_support.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';

const output =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/GUARDIAN_CARD/BUILT/V3';
const scratch =
    '/Users/shakeelahmad/Documents/Codex/2026-10-31/zyra-queue67-family-place-acceptance-v3/work/raw';
const capture = bool.fromEnvironment('ZYRA_LOCK19_V3_CAPTURE');
const hassan = 'draft-guardian-hassan';
final sent = DateTime.utc(2026, 10, 31, 12);
Finder key(String id) => find.byKey(ValueKey(id));
ZyraGuardianTabsPresentation view(WidgetTester t) =>
    t.widget(find.byType(ZyraGuardianTabsPresentation));
Future<void> nav(BaselineHarness h, int tab) async {
  for (var i = 0; i < 4 && h.latest.pages.isNotEmpty; i++) {
    await returnZyraPreviewPage(h.tester);
    await h.flush();
  }
  h.tester
      .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
      .onTap(tab);
  await h.flush();
}

Future<BaselineHarness> mount(
  WidgetTester t, {
  double scale = 1,
  ZyraGuardianFamilyPreview? family,
  DateTime Function()? clock,
  bool linked = true,
}) async {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final offers = family ?? ZyraGuardianFamilyPreview();
  if (family == null) {
    offers.send(
      guardianId: hassan,
      guardianName: 'Hassan',
      seekerId: 'draft-self',
      seekerName: 'Adam',
      seekerGender: 'male',
      relationship: 'Father',
      main: true,
      now: sent,
    );
  }
  final model = ViewRequestDraftModel(capacity: 3, clock: clock ?? () => sent)
    ..seedJourneys(2)
    ..setSampleGuardianMembership(hassan, DraftGuardianMembership.basic);
  final h = BaselineHarness(
    t,
    group: 'lock19_v3',
    outputRoot: output,
    evidenceRoot: scratch,
    flatOutput: true,
    textScale: scale,
  );
  await h.mount(
    guardian: true,
    previewClock: clock ?? () => sent,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: true,
      tab: 2,
      pages: const [],
      model: model.snapshot(),
      guardianMembership: 'Guardian Basic',
      guardianFamily: offers.snapshot,
      removedGuardians: linked ? const [] : const [hassan],
    ),
  );
  if (scale > 1) {
    t.view.physicalSize = const Size(1170, 2532);
    await h.flush();
  }
  return h;
}

Future<void> cap(
  BaselineHarness h,
  String name,
  double scale, {
  bool fixture = true,
}) async {
  if (!capture) return;
  await h.flush();
  await h.tester.runAsync(() async {
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      key('zyra-founder-baseline-boundary'),
    );
    final img = await boundary.toImage(pixelRatio: 3);
    try {
      final f = File('$output/$name.png');
      await f.parent.create(recursive: true);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      await f.writeAsBytes(bytes!.buffer.asUint8List());
      await File('$output/$name.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'file': '$name.png',
          'width': img.width,
          'height': img.height,
          'text_scale': scale,
          'route': h.latest.pages,
          'tab': h.latest.tab,
          'reached':
              'Actual admitted offline Founder shell; ${fixture ? 'explicit dated k20-k22 local invite fixture' : 'actual Seeker sheet invite and role switch'}; no charge or server call.',
        }),
      );
    } finally {
      img.dispose();
    }
  });
}

Future<void> verify(BaselineHarness h) async {
  await h.tap('guardian_family_accept');
  h.assertPage('guardian_family_identity');
  expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
  expect(h.latest.guardianMembership, 'Guardian Basic');
  await h.tap('identity-consent-agree');
  await h.tester.scrollUntilVisible(
    key('identity-dev-verified'),
    160,
    scrollable: find
        .descendant(
          of: find.byType(InitialIdentityCheckScreen),
          matching: find.byType(Scrollable),
        )
        .last,
    maxScrolls: 30,
  );
  await h.tap('identity-dev-verified');
  await h.tap('identity-continue');
  expect(h.latest.guardianMembership, 'Guardian One');
  expect(h.latest.pages, isEmpty);
}

Future<void> shadows(Future<void> Function() body) async {
  final old = debugDisableShadows;
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = old;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: scratch));
  tearDownAll(baselineTearDown);
  setUp(() {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'k20-k22 actual pending page, verified acceptance and Profile at $scale',
      (t) => shadows(() async {
        final h = await mount(t, scale: scale);
        expect(find.text('Adam has given\nyou Guardian One'), findsOneWidget);
        expect(find.textContaining('Choose by 7 Nov.'), findsOneWidget);
        await cap(h, 'k20_${scale == 1 ? 'normal' : 'larger_top'}', scale);
        if (scale > 1) {
          await Scrollable.ensureVisible(
            t.element(key('guardian_family_view')),
            alignment: .5,
          );
          await cap(h, 'k20_larger_actions', scale);
        }
        await h.tap('guardian_family_view');
        h.assertPage('guardian_family_offer');
        expect(t.getSize(key('guardian_action_monogram')), const Size(96, 96));
        expect(find.text('ZYRA FAMILY PLACE'), findsOneWidget);
        expect(find.text('Choose by 7 Nov'), findsOneWidget);
        expect(
          find.textContaining('You stay Adam’s Father and Main Guardian.'),
          findsOneWidget,
        );
        await cap(h, 'k21_${scale == 1 ? 'normal' : 'larger_top'}', scale);
        if (scale > 1) {
          await Scrollable.ensureVisible(
            t.element(key('guardian_family_decline')),
            alignment: .5,
          );
          await h.flush();
          expect(key('guardian_family_accept').hitTestable(), findsOneWidget);
          expect(key('guardian_family_decline').hitTestable(), findsOneWidget);
          await cap(h, 'k21_larger_actions', scale);
        }
        await verify(h);
        final model = ViewRequestDraftModel.fromSnapshot(h.latest.model);
        for (final p in draftProfiles) {
          expect(
            model.sampleGuardianAccessFor(hassan, p.id, isMain: true).chat,
            isFalse,
          );
        }
        await nav(h, 4);
        expect(find.text('Family place · paid by Adam'), findsOneWidget);
        await cap(h, 'k22_${scale == 1 ? 'normal' : 'larger_top'}', scale);
        if (scale > 1) {
          await Scrollable.ensureVisible(
            t.element(find.text('Family place · paid by Adam')),
            alignment: .5,
          );
          await h.flush();
          await cap(h, 'k22_larger_membership', scale);
        }
        final saved = h.latest;
        await t.pumpWidget(const SizedBox());
        await h.mount(
          guardian: true,
          checkpoint: saved,
          previewClock: () => sent,
        );
        expect(find.text('Family place · paid by Adam'), findsOneWidget);
        final restored = ViewRequestDraftModel.fromSnapshot(h.latest.model);
        expect(
          restored
              .sampleGuardianAccessFor(
                hassan,
                draftProfiles[1].id,
                isMain: true,
              )
              .chat,
          isFalse,
        );
      }),
    );
  }
  testWidgets(
    'actual Seeker invite survives role switch; accept keeps every View and other Guardian fact',
    (t) async {
      final h = BaselineHarness(
        t,
        group: 'lock19_v3_source',
        evidenceRoot: scratch,
      );
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final model = ViewRequestDraftModel(capacity: 3, clock: () => sent)
        ..seedJourneys(2)
        ..setSampleGuardianMembership(hassan, DraftGuardianMembership.basic);
      await h.mount(
        tab: 3,
        model: model,
        guardianMembership: 'Guardian Basic',
        previewClock: () => sent,
      );
      final before = h.latest.model;
      await h.tap('guardian-card-center');
      final cards = t.widget<ZyraOneJourneyGuardianCards>(
        find.byType(ZyraOneJourneyGuardianCards),
      );
      final journey = cards.journeysFor(hassan).first;
      await h.tap('guardian-card-chat-$hassan-${journey.id}');
      await h.tap('guardian-family-introduction-primary');
      await h.tap('guardian-family-price-primary');
      await h.tap('guardian-family-invited-primary');
      expect(h.latest.guardianFamily!.invites.single.guardianName, 'Hassan');
      expect(h.latest.guardianFamily!.invites.single.seekerName, 'Adam');
      await nav(h, 4);
      expect(await pressZyraDevControlKey(t, 'draft_role_guardian'), isTrue);
      await h.flush();
      expect(h.latest.guardian, isTrue);
      await h.tap('guardian_family_view');
      await verify(h);
      expect(h.latest.model.states, before.states);
      expect(
        h.latest.model.ownMainGuardianPresent,
        before.ownMainGuardianPresent,
      );
      expect(
        h.latest.model.guardianMemberships['draft-guardian-yusuf'],
        before.guardianMemberships['draft-guardian-yusuf'],
      );
      await nav(h, 4);
      expect(await pressZyraDevControlKey(t, 'draft_role_seeker'), isTrue);
      await h.flush();
      await nav(h, 3);
      expect(find.text('Guardian One · Family place'), findsOneWidget);
      await h.tap('guardian-card-center');
      final accepted = t.widget<ZyraOneJourneyGuardianCards>(
        find.byType(ZyraOneJourneyGuardianCards),
      );
      expect(
        accepted.journeysFor(hassan).every((p) => !p.chat && p.view),
        isTrue,
      );
      await h.tap('guardian-card-chat-$hassan-${journey.id}');
      final changed = ViewRequestDraftModel.fromSnapshot(h.latest.model);
      expect(
        changed.sampleGuardianAccessFor(hassan, journey.id, isMain: true).chat,
        isTrue,
      );
      expect(
        accepted.journeysFor('draft-guardian-yusuf').map((p) => p.chat),
        everyElement(isFalse),
      );
    },
  );
  testWidgets(
    'decline closes, removes Needs-you, returns Basic and frees one place',
    (t) async {
      final h = await mount(t);
      await h.tap('guardian_family_view');
      await h.tap('guardian_family_decline');
      expect(h.latest.pages, isEmpty);
      expect(h.latest.guardianMembership, 'Guardian Basic');
      expect(h.latest.guardianFamily!.freePlaces, 1);
      expect(
        find.text('Declined. The place stays free for Adam.'),
        findsOneWidget,
      );
      expect(find.text('Adam has given\nyou Guardian One'), findsNothing);
      final saved = h.latest;
      await nav(h, 4);
      expect(await pressZyraDevControlKey(t, 'draft_role_seeker'), isTrue);
      await h.flush();
      await nav(h, 3);
      expect(find.text('Guardian Basic'), findsOneWidget);
      expect(h.latest.model.guardianAccess, saved.model.guardianAccess);
    },
  );
  testWidgets(
    'missing, expired and unlinked offers never become Needs-you items',
    (t) async {
      final none = await mount(t, family: ZyraGuardianFamilyPreview());
      expect(key('guardian_family_view'), findsNothing);
      await t.pumpWidget(const SizedBox());
      var now = sent;
      final h = await mount(t, clock: () => now);
      await h.tap('guardian_family_view');
      final retained = t
          .widget<TextButton>(key('guardian_family_accept'))
          .onPressed!;
      now = sent.add(const Duration(days: 7));
      retained();
      await h.flush();
      expect(find.byType(InitialIdentityCheckScreen), findsNothing);
      await nav(h, 4);
      await nav(h, 2);
      expect(key('guardian_family_view'), findsNothing);
      expect(h.latest.guardianMembership, 'Guardian Basic');
      expect(none.checkpoints, isNotEmpty);
      await t.pumpWidget(const SizedBox());
      await mount(t, linked: false);
      expect(key('guardian_family_view'), findsNothing);
    },
  );
  testWidgets(
    'retained accept/decline deny after navigation and account replacement',
    (t) async {
      final h = await mount(t);
      await h.tap('guardian_family_view');
      final accept = t
          .widget<TextButton>(key('guardian_family_accept'))
          .onPressed!;
      final decline = t
          .widget<TextButton>(key('guardian_family_decline'))
          .onPressed!;
      await nav(h, 4);
      accept();
      decline();
      await h.flush();
      expect(find.byType(InitialIdentityCheckScreen), findsNothing);
      expect(
        h.latest.guardianFamily!.invites.single.status,
        ZyraGuardianFamilyInviteStatus.pending,
      );
      await nav(h, 2);
      await h.tap('guardian_family_view');
      final old = t.widget<ZyraGuardianActionPage>(
        find.byType(ZyraGuardianActionPage),
      );
      ZyraAccountState.resetForTesting();
      old.onAction('family_decline');
      await h.flush();
      expect(h.latest.guardianFamily!.freePlaces, 0);
    },
  );
  testWidgets(
    'existing identity skip and stale verified callback grant nothing',
    (t) async {
      final h = await mount(t);
      await h.tap('guardian_family_view');
      await h.tap('guardian_family_accept');
      final screen = t.widget<InitialIdentityCheckScreen>(
        find.byType(InitialIdentityCheckScreen),
      );
      await screen.onDevSkip!(
        t.element(find.byType(InitialIdentityCheckScreen)),
      );
      await h.flush();
      h.assertPage('guardian_family_offer');
      expect(h.latest.guardianMembership, 'Guardian Basic');
      await screen.onContinue!(t.element(find.byType(ZyraGuardianActionPage)));
      await h.flush();
      expect(h.latest.guardianMembership, 'Guardian Basic');
      expect(
        h.latest.guardianFamily!.invites.single.status,
        ZyraGuardianFamilyInviteStatus.pending,
      );
    },
  );
  testWidgets(
    'Family copy uses the invited Seeker pronoun and denies before haptics',
    (t) async {
      final family = ZyraGuardianFamilyPreview();
      final offer = family.send(
        guardianId: 'mother',
        guardianName: 'Amina',
        seekerId: 'maryam',
        seekerName: 'Maryam',
        seekerGender: 'female',
        relationship: 'Mother',
        main: false,
        now: sent,
      )!;
      var allowed = true;
      final actions = <String>[];
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraGuardianActionPage(
              introduction: false,
              personName: 'Maryam',
              seekerName: 'Maryam',
              seekerGender: 'female',
              familyInvite: offer,
              canAct: () => allowed,
              onAction: actions.add,
            ),
          ),
        ),
      );
      expect(find.textContaining('when she turns it on'), findsOneWidget);
      expect(
        find.textContaining('Mother and Additional Guardian'),
        findsOneWidget,
      );
      final accept = t
          .widget<TextButton>(key('guardian_family_accept'))
          .onPressed!;
      calls.clear();
      allowed = false;
      accept();
      await t.pump();
      expect(actions, isEmpty);
      expect(
        calls.where((call) => call.method == 'HapticFeedback.vibrate'),
        isEmpty,
      );
    },
  );
}
