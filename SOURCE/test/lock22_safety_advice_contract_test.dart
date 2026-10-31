import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_safety_advice_presentation.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK22_SAFETY_ADVICE_V5_2026-10-31';

BaselineHarness _h(WidgetTester t) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(
    t,
    group: 'safety_v5_contract',
    evidenceRoot: _evidence,
  );
}

Future<void> _back(BaselineHarness h) async {
  await returnZyraPreviewPage(h.tester);
  await h.flush();
}

ZyraDraftSafetyAdvicePresentation _advice(WidgetTester t) =>
    t.widget(find.byType(ZyraDraftSafetyAdvicePresentation));

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  for (final one in [true, false]) {
    testWidgets(
      'V5 Seeker ${one ? "One" : "Basic"}: entry, report, Help and back stack',
      (t) async {
        final h = _h(t);
        await h.mount(
          tab: 4,
          initialSeekerBasic: !one,
          seekerMembership: one ? 'Seeker One' : 'Seeker Basic',
        );
        await h.tap('concept_safety_advice');
        h.assertPage('safety_advice');
        expect(h.latest.personId, isNull);
        expect(find.text('Stay safe on your Journey'), findsOneWidget);
        expect(find.text('ZYRA SAFETY'), findsOneWidget);
        for (final title in [
          'Keep your family close',
          'Meet safely',
          'Never send money',
          'Protect your details',
          'Trust how you feel',
        ]) {
          expect(find.text(title), findsOneWidget);
        }
        expect(find.byIcon(Icons.favorite), findsNothing);
        expect(find.byIcon(Icons.favorite_border), findsNothing);
        await h.tap('draft_safety_advice_report');
        h.assertPage('safety');
        expect(h.latest.pages, ['safety_advice', 'safety']);
        expect(find.text('Choose a profile to report'), findsOneWidget);
        expect(find.byKey(const ValueKey('draft_report_target')), findsNothing);
        expect(find.text('Submit report'), findsNothing);
        await _back(h);
        h.assertPage('safety_advice');
        await h.tap('draft_safety_advice_help');
        h.assertPage('help_support');
        expect(find.byType(HelpSupportScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('support-safety-case-status')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('help-support-email-action')),
          findsNothing,
        );
        await _back(h);
        h.assertPage('safety_advice');
        await _back(h);
        expect(h.latest.pages, isEmpty);
        expect(h.latest.tab, 4);
      },
    );
    testWidgets(
      'V5 Guardian ${one ? "One" : "Basic"} keeps original Safety instructions',
      (t) async {
        final h = _h(t);
        await h.mount(
          tab: 4,
          guardian: true,
          initialGuardianBasic: !one,
          guardianMembership: one ? 'Guardian One' : 'Guardian Basic',
        );
        await h.tap('concept_safety_advice');
        h.assertPage('safety');
        expect(find.byType(ZyraDraftReportPresentation), findsOneWidget);
        expect(find.byType(ZyraDraftSafetyAdvicePresentation), findsNothing);
        expect(find.text('Choose a profile to report'), findsOneWidget);
      },
    );
  }
  for (final change in [
    'route',
    'account',
    'controls',
    'role',
    'disposal',
    'admission',
  ]) {
    testWidgets('V5 saved advice callbacks reject $change change', (t) async {
      final h = _h(t);
      var allowed = true;
      if (change == 'admission') {
        var ready = false;
        await h.mountPresentation(
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: false,
            model: ViewRequestDraftModel().snapshot(),
            tab: 4,
            pages: const [],
          ),
          child: ZyraOneJourneyConceptShell(
            key: UniqueKey(),
            canAct: () => allowed,
            onExit: () => fail('Must remain local'),
            initialCheckpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: ViewRequestDraftModel().snapshot(),
              tab: 4,
              pages: const [],
            ),
            onCheckpoint: h.checkpoints.add,
            onPresentationReady: () => ready = true,
          ),
        );
        for (var i = 0; i < 150 && !ready; i++) {
          await t.pump(const Duration(milliseconds: 20));
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        }
        expect(ready, isTrue);
      } else {
        await h.mount(tab: 4);
      }
      await h.tap('concept_safety_advice');
      final saved = _advice(t);
      if (change == 'route') await h.tap('draft_safety_advice_help');
      if (change == 'account') ZyraAccountState.resetForTesting();
      if (change == 'controls') await h.controls();
      if (change == 'role') {
        await _back(h);
        expect(await pressZyraDevControlKey(t, 'draft_role_guardian'), isTrue);
        await expandZyraPreviewTabBarIfIdle(t);
        final nav = find.byType(ZyraShellNavigation);
        final item = t
            .widget<ZyraShellNavigation>(nav)
            .items
            .singleWhere((item) => item.label == 'Profile');
        final icon = find.descendant(of: nav, matching: find.byIcon(item.icon));
        await t.tapAt(t.getCenter(icon));
        await t.pumpAndSettle();
        expect(await pressZyraDevControlKey(t, 'draft_role_seeker'), isTrue);
      }
      if (change == 'disposal') await t.pumpWidget(const SizedBox());
      if (change == 'admission') allowed = false;
      final checkpoint = h.latest;
      expect(saved.canAct(), isFalse);
      saved.onReport();
      saved.onHelp();
      await t.pump();
      expect(h.latest, same(checkpoint));
      expect(t.takeException(), isNull);
      if (change == 'controls') await h.closeControls();
    });
  }
  for (final leaf in ['', 'safety', 'help_support']) {
    testWidgets(
      'V5 restores fresh advice ${leaf.isEmpty ? "root" : leaf} stack without peer target',
      (t) async {
        final h = _h(t);
        await h.mount(
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: false,
            model: ViewRequestDraftModel().snapshot(),
            tab: 4,
            pages: ['safety_advice', if (leaf.isNotEmpty) leaf],
            personId: 'draft-sara',
          ),
        );
        h.assertPage(leaf.isEmpty ? 'safety_advice' : leaf);
        expect(h.latest.personId, isNull);
        if (leaf.isNotEmpty) await _back(h);
        expect(find.byType(ZyraDraftSafetyAdvicePresentation), findsOneWidget);
      },
    );
  }
  for (final guardian in [true, false]) {
    testWidgets(
      'V5 rejects advice checkpoint outside Seeker Profile: guardian=$guardian',
      (t) async {
        final h = _h(t);
        await h.mount(
          guardian: guardian,
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: ViewRequestDraftModel().snapshot(),
            tab: guardian ? 4 : 0,
            pages: const ['safety_advice', 'help_support'],
          ),
        );
        expect(find.byType(ZyraDraftSafetyAdvicePresentation), findsNothing);
        expect(h.latest.pages, isEmpty);
      },
    );
  }
}
