import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/widgets/zyra_guardian_add_card.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

import '../support/guardian_card_driver.dart';
import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE101_CAPTURE_DIR');
const _question = 'What are Past Journey summaries?';
const _answer =
    "When you switch this on for a Guardian, they can see your Journeys "
    "that have ended — the other person's first name and the dates, nothing else. "
    "It is off for every Guardian until you turn it on, and you choose for "
    "each Guardian separately. Turn it on or off any time on that Guardian's "
    "card in the Guardian tab.";

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  test('Guardians follows Matching and Journeys in shared Help', () {
    final titles = zyraHelpCategories
        .map((category) => category.title)
        .toList();
    final guardians =
        zyraHelpCategories[titles.indexOf('Matching and Journeys') + 1];
    expect(guardians.title, 'Guardians');
    expect(guardians.entries.single.question, _question);
    expect(guardians.entries.single.answer, _answer);
  });

  for (final (size, safePadding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';

    BaselineHarness harness(WidgetTester t) {
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      return BaselineHarness(
        t,
        group: 'line101_$dimensions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: safePadding,
        reduceMotion: true,
      );
    }

    Future<void> capture(BaselineHarness h, String state) async {
      if (_captures.isEmpty) return;
      final previous = debugDisableShadows;
      debugDisableShadows = false;
      try {
        final frame = h.tester.renderObject<RenderObject>(
          h.key('zyra-founder-baseline-boundary'),
        );
        void repaint(RenderObject object) {
          object.markNeedsPaint();
          object.visitChildren(repaint);
        }

        repaint(frame);
        await h.capture(
          'guardian_card',
          'line101',
          state,
          state,
          fileName: '${state}_$dimensions.png',
        );
      } finally {
        debugDisableShadows = previous;
      }
    }

    for (final basic in [false, true]) {
      final plan = basic ? 'Seeker Basic' : 'Seeker One';
      for (final empty in [false, true]) {
        final state = 'add_${basic ? 'basic' : 'one'}${empty ? '_empty' : ''}';
        testWidgets('Line 101 $plan Add (empty=$empty) at $dimensions', (
          t,
        ) async {
          ZyraInternalPreviewClient.beginPreview();
          addTearDown(ZyraInternalPreviewClient.finishSignOut);
          final h = harness(t);
          final model = ViewRequestDraftModel(capacity: basic ? 1 : 3)
            ..seedJourneys(1);
          await h.mount(
            initialSeekerBasic: basic,
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: model.snapshot(),
              tab: 3,
              pages: const [],
              seekerMembership: plan,
              removedGuardians: [
                if (empty) ...draftGuardians.map((person) => person.id),
              ],
            ),
          );
          final nav = h.key('compact-nav-surface');
          final addCard = h.key('guardian-card-add');
          final addButton = h.key('guardian-card-add-button');
          Rect? linked;
          if (!empty) {
            linked = t.getRect(h.key('guardian-card-draft-guardian-hassan'));
            final swipes = basic ? 2 : 3;
            for (var i = 0; i < swipes; i++) {
              await swipeGuardianCard(t);
              await h.flush();
            }
          }
          expect(h.key('guardian-card-center'), findsNothing);
          expect(find.text('Add a Guardian'), findsOneWidget);
          expect(addButton.hitTestable(), findsOneWidget);
          expect(t.getSize(addButton), const Size.square(104));
          expect(t.getSemantics(addButton).label, 'Add a Guardian');
          final card = t.getRect(addCard);
          if (linked != null) expect(card, linked);
          expect(t.getRect(nav).top - card.bottom, closeTo(16, .01));
          expect(card.contains(t.getRect(addButton).bottomCenter), isTrue);
          final upgrade = find.text('Seeker One: any 10 Guardians ›');
          expect(upgrade.hitTestable(), basic ? findsOneWidget : findsNothing);
          if (basic) {
            expect(find.text('Guardian Basic place'), findsOneWidget);
            expect(find.text('Guardian One places'), findsOneWidget);
            expect(find.text('Free'), findsOneWidget);
          }
          expect(t.takeException(), isNull);
          await capture(h, state);

          await h.tap('guardian-card-add-button');
          h.assertPage('guardian_invite');
          expect(h.key('zyra_code_local_preview_denied'), findsNothing);
          expect(h.key('zyra-code-main-card'), findsOneWidget);
          expect(find.text('My code'), findsOneWidget);
          expect(find.textContaining('ZYRA · DEMO ·'), findsOneWidget);
          await capture(h, 'invite_$state');
        });
      }
    }

    testWidgets('Line 101 Journey access geometry and switch at $dimensions', (
      t,
    ) async {
      final h = harness(t);
      await h.mount(
        tab: 3,
        model: ViewRequestDraftModel(capacity: 3)..seedJourneys(1),
      );
      final journey = h.key('guardian-card-tile-draft-sara');
      Finder within(Finder parent, Finder child) =>
          find.descendant(of: parent, matching: child);
      final photo = within(journey, find.byType(ZyraProfileImage));
      final name = within(journey, find.text('Sara'));
      expect(t.getSize(photo), const Size.square(42));
      expect(t.getTopLeft(name).dx - t.getTopRight(photo).dx, closeTo(14, .01));

      final free = h.key('guardian-card-free-place-1');
      final circle = within(
        free,
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.foregroundPainter is ZyraGuardianDashedBorder,
        ),
      );
      final freeText = within(free, find.text('Free Journey place'));
      expect(t.getSize(circle), const Size.square(40));
      expect(
        t.getTopLeft(freeText).dx - t.getTopRight(circle).dx,
        closeTo(14, .01),
      );

      final summaries = h.key('guardian-card-summary-row');
      final row = within(summaries, find.byType(Row)).first;
      expect(t.widget<Row>(row).children, hasLength(3));
      expect(within(summaries, find.byType(IconButton)), findsNothing);
      final toggle = h.key('guardian-card-history-draft-guardian-hassan');
      expect(t.widget<Semantics>(toggle).properties.toggled, isFalse);
      expect(t.takeException(), isNull);
      await capture(h, 'linked');
      await h.tap('guardian-card-history-draft-guardian-hassan');
      expect(t.widget<Semantics>(toggle).properties.toggled, isTrue);
    });

    testWidgets('Line 101 Help finds Guardians by summaries at $dimensions', (
      t,
    ) async {
      final h = harness(t);
      await h.mount(tab: 4);
      await h.tap('concept_settings');
      final settingsHelp = h.key('concept_settings_helpSupport');
      if (settingsHelp.evaluate().isEmpty) {
        await t.scrollUntilVisible(
          settingsHelp,
          160,
          scrollable: find.descendant(
            of: h.key('concept-current-settings-scroll'),
            matching: find.byType(Scrollable),
          ),
        );
        await h.flush();
      }
      await h.tap('concept_settings_helpSupport');
      h.assertPage('help_support');
      await t.enterText(find.byType(TextField), 'summaries');
      FocusManager.instance.primaryFocus?.unfocus();
      await h.flush();
      expect(find.text('GUARDIANS'), findsOneWidget);
      await h.tapText(_question);
      expect(find.text(_answer), findsOneWidget);
      expect(t.takeException(), isNull);
      await capture(h, 'faq_summaries');
    });
  }
}
