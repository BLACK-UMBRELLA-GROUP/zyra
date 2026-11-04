import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_draft_safety_advice_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK22_GUARDIAN_SAFETY_ADVICE_V6_2026-10-31';
const _tips = [
  (
    "Support, don't decide",
    'You are part of every Journey a Seeker you support begins. They choose whether to continue; share your view in the Guardian Circle.',
  ),
  (
    'Be there when they meet',
    'First meetings should be in a public place, with you or another family member present.',
  ),
  (
    'Never send money',
    'No one on ZYRA should ask you or the Seeker for money, gifts or bank details. If they do, report them.',
  ),
  (
    'Protect family details',
    'Keep your home address, work and family finances private until both families have met and feel sure.',
  ),
  (
    'Speak up early',
    'If something worries you, talk to the Seeker first, and report the profile if you need to.',
  ),
];

BaselineHarness _h(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'guardian_safety_v6_contract',
    evidenceRoot: _evidence,
  );
}

ZyraPreviewNavigationCheckpoint _checkpoint({
  required bool one,
  int tab = 4,
  List<String> pages = const [],
  String? personId,
}) {
  final model = ViewRequestDraftModel(capacity: one ? 3 : 1);
  if (!one) {
    model.setSampleGuardianMembership(
      'draft-guardian-hassan',
      DraftGuardianMembership.basic,
    );
  }
  return ZyraPreviewNavigationCheckpoint(
    guardian: true,
    model: model.snapshot(),
    tab: tab,
    pages: pages,
    personId: personId,
    seekerMembership: one ? 'Seeker One' : 'Seeker Basic',
    guardianMembership: one ? 'Guardian One' : 'Guardian Basic',
  );
}

Future<void> _mount(
  BaselineHarness h, {
  required bool one,
  ZyraPreviewNavigationCheckpoint? checkpoint,
  bool Function()? canAct,
}) async {
  var ready = false;
  final initial = checkpoint ?? _checkpoint(one: one);
  await h.mountPresentation(
    checkpoint: initial,
    child: ZyraOneJourneyConceptShell(
      fixture: ZyraShellTestFixture().fixture,
      key: UniqueKey(),
      canAct: canAct ?? () => true,
      onExit: () => fail('Guardian safety must remain local.'),
      initialGuardianRole: true,
      initialGuardianBasic: !one,
      initialSeekerBasic: !one,
      initialCheckpoint: initial,
      previewClock: () => DateTime.utc(2026, 10, 29, 12),
      onCheckpoint: h.checkpoints.add,
      onPresentationReady: () => ready = true,
    ),
  );
  for (var frame = 0; frame < 150 && !ready; frame++) {
    await h.tester.pump(const Duration(milliseconds: 20));
    await h.tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  expect(ready, isTrue, reason: 'Bundled local photos must prepare.');
  await h.flush();
  expect(h.latest.guardian, isTrue);
  expect(h.latest.guardianMembership, one ? 'Guardian One' : 'Guardian Basic');
}

Future<void> _back(BaselineHarness h) async {
  await returnZyraPreviewPage(h.tester);
  await h.flush();
}

Future<void> _tab(BaselineHarness h, String label) async {
  await expandZyraPreviewTabBarIfIdle(h.tester);
  final nav = find.byType(ZyraShellNavigation);
  expect(nav, findsOneWidget);
  final item = h.tester
      .widget<ZyraShellNavigation>(nav)
      .items
      .singleWhere((item) => item.label == label);
  final icon = find.descendant(of: nav, matching: find.byIcon(item.icon));
  expect(icon, findsOneWidget);
  await h.tester.tapAt(h.tester.getCenter(icon));
  await h.tester.pumpAndSettle();
  await h.flush();
}

ZyraDraftSafetyAdvicePresentation _advice(WidgetTester tester) =>
    tester.widget(find.byType(ZyraDraftSafetyAdvicePresentation));

VoidCallback _rowTap(WidgetTester tester, String key) => tester
    .widget<InkWell>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(InkWell),
      ),
    )
    .onTap!;

void _expectGuardianCopy(WidgetTester tester) {
  expect(_advice(tester).guardian, isTrue);
  expect(find.text('Support a safe Journey'), findsOneWidget);
  expect(find.text('ZYRA SAFETY · GUARDIANS'), findsOneWidget);
  for (final (title, copy) in _tips) {
    expect(find.text(title), findsOneWidget);
    expect(find.text(copy), findsOneWidget);
  }
  for (final title in [
    'Keep your family close',
    'Meet safely',
    'Protect your details',
    'Trust how you feel',
    'Stay safe on your Journey',
  ]) {
    expect(find.text(title), findsNothing);
  }
  expect(find.text('Report a profile'), findsOneWidget);
  expect(find.text('Open their profile and choose Report'), findsOneWidget);
  expect(find.text('Help & support'), findsOneWidget);
  expect(
    find.text(
      'In danger right now? Call your local emergency number (999 in the UK).',
    ),
    findsOneWidget,
  );
  expect(
    tester.getSize(find.byKey(const ValueKey('draft_safety_advice_monogram'))),
    const Size(88, 88),
  );
  expect(find.byIcon(Icons.favorite), findsNothing);
  expect(find.byIcon(Icons.favorite_border), findsNothing);
}

void _expectReportInstructions() {
  expect(find.byType(ZyraDraftReportPresentation), findsOneWidget);
  expect(find.text('Choose a profile to report'), findsOneWidget);
  expect(
    find.text(
      "Open the person’s profile and choose Report. You can then pick the reason that fits best.",
    ),
    findsOneWidget,
  );
  expect(find.byKey(const ValueKey('draft_report_target')), findsNothing);
  expect(find.text('Submit report'), findsNothing);
}

void _expectHelp() {
  expect(find.byType(HelpSupportScreen), findsOneWidget);
  expect(
    find.byKey(const ValueKey('support-safety-case-status')),
    findsNothing,
  );
  expect(find.byKey(const ValueKey('help-support-email-action')), findsNothing);
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);

  for (final one in [true, false]) {
    final plan = one ? 'One' : 'Basic';
    testWidgets(
      'V6 Guardian $plan: entry, exact tips, targets and back stack',
      (tester) async {
        final h = _h(tester);
        await _mount(h, one: one);
        await h.tap('concept_safety_advice');
        h.assertPage('safety_advice');
        expect(h.latest.pages, ['safety_advice']);
        expect(h.latest.personId, isNull);
        _expectGuardianCopy(tester);

        await h.tap('draft_safety_advice_report');
        h.assertPage('safety');
        expect(h.latest.pages, ['safety_advice', 'safety']);
        expect(h.latest.personId, isNull);
        _expectReportInstructions();
        await _back(h);
        h.assertPage('safety_advice');
        _expectGuardianCopy(tester);

        await h.tap('draft_safety_advice_help');
        h.assertPage('help_support');
        expect(h.latest.pages, ['safety_advice', 'help_support']);
        expect(h.latest.personId, isNull);
        _expectHelp();
        await _back(h);
        h.assertPage('safety_advice');
        await _back(h);
        expect(h.latest.pages, isEmpty);
        expect(h.latest.tab, 4);
        expect(
          find.byKey(const ValueKey('concept_profile_title')),
          findsOneWidget,
        );
      },
    );

    for (final leaf in ['', 'safety', 'help_support']) {
      testWidgets(
        'V6 Guardian $plan restores ${leaf.isEmpty ? "advice root" : leaf} and clears peer',
        (tester) async {
          final h = _h(tester);
          await _mount(
            h,
            one: one,
            checkpoint: _checkpoint(
              one: one,
              pages: ['safety_advice', if (leaf.isNotEmpty) leaf],
              personId: 'draft-sara',
            ),
          );
          h.assertPage(leaf.isEmpty ? 'safety_advice' : leaf);
          expect(h.latest.personId, isNull);
          if (leaf == 'safety') _expectReportInstructions();
          if (leaf == 'help_support') _expectHelp();
          if (leaf.isNotEmpty) await _back(h);
          h.assertPage('safety_advice');
          _expectGuardianCopy(tester);
          await _back(h);
          expect(h.latest.pages, isEmpty);
          expect(h.latest.tab, 4);
        },
      );
    }

    for (final tab in [0, 1, 2, 3]) {
      testWidgets(
        'V6 Guardian $plan rejects advice restore outside Profile $tab',
        (tester) async {
          final h = _h(tester);
          await _mount(
            h,
            one: one,
            checkpoint: _checkpoint(
              one: one,
              tab: tab,
              pages: const ['safety_advice', 'help_support'],
              personId: 'draft-sara',
            ),
          );
          expect(h.latest.pages, isEmpty);
          expect(h.latest.tab, tab);
          expect(find.byType(ZyraDraftSafetyAdvicePresentation), findsNothing);
          expect(find.byType(HelpSupportScreen), findsNothing);
        },
      );
    }

    for (final change in [
      'route',
      'route return',
      'tab return',
      'account',
      'controls',
      'controls return',
      'role return',
      'disposal',
      'admission revocation',
    ]) {
      testWidgets('V6 Guardian $plan saved advice callbacks reject $change', (
        tester,
      ) async {
        final h = _h(tester);
        var allowed = true;
        await _mount(h, one: one, canAct: () => allowed);
        await h.tap('concept_safety_advice');
        final saved = _advice(tester);
        final savedRowTaps = [
          _rowTap(tester, 'draft_safety_advice_report'),
          _rowTap(tester, 'draft_safety_advice_help'),
        ];
        expect(saved.canAct(), isTrue);

        if (change == 'route' || change == 'route return') {
          await h.tap('draft_safety_advice_help');
          if (change == 'route return') await _back(h);
        }
        if (change == 'tab return') {
          await _back(h);
          await _tab(h, 'My ZYRA');
          await _tab(h, 'Profile');
          await h.tap('concept_safety_advice');
        }
        if (change == 'account') ZyraAccountState.resetForTesting();
        if (change == 'controls' || change == 'controls return') {
          await h.controls();
          if (change == 'controls return') await h.closeControls();
        }
        if (change == 'role return') {
          await _back(h);
          expect(
            await pressZyraDevControlKey(tester, 'draft_role_seeker'),
            isTrue,
          );
          expect(h.latest.guardian, isFalse);
          await _tab(h, 'Profile');
          expect(
            await pressZyraDevControlKey(tester, 'draft_role_guardian'),
            isTrue,
          );
          expect(h.latest.guardian, isTrue);
          await _tab(h, 'Profile');
          await h.tap('concept_safety_advice');
        }
        if (change == 'disposal') await tester.pumpWidget(const SizedBox());
        if (change == 'admission revocation') allowed = false;

        final before = h.latest;
        expect(saved.canAct(), isFalse);
        saved.onReport();
        saved.onHelp();
        for (final onTap in savedRowTaps) {
          onTap();
        }
        await tester.pump();
        expect(h.latest, same(before));
        expect(tester.takeException(), isNull);

        if (change == 'controls') await h.closeControls();
        if ([
          'route return',
          'tab return',
          'controls return',
          'role return',
        ].contains(change)) {
          h.assertPage('safety_advice');
          _expectGuardianCopy(tester);
          expect(_advice(tester).canAct(), isTrue);
          await h.tap('draft_safety_advice_report');
          h.assertPage('safety');
          _expectReportInstructions();
        }
      });
    }
  }
}
