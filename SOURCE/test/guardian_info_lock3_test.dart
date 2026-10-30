// LOCK 3 end-to-end sample shell: no live member data or transport.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_info_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'visual/baseline_capture_support.dart';

const _hassan = 'draft-guardian-hassan';
const _yusuf = 'draft-guardian-yusuf';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK3_GUARDIAN_INFO_2026-10-30';
const _output =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/GUARDIAN_INFO/BUILT';
const _capture = bool.fromEnvironment('ZYRA_LOCK3_CAPTURE');
Finder _key(String id) => find.byKey(ValueKey(id));
BaselineHarness _h(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'lock3',
    outputRoot: _output,
    evidenceRoot: _evidence,
    flatOutput: true,
  );
}

ZyraPreviewNavigationCheckpoint _checkpoint({
  bool guardian = false,
  int tab = 3,
  List<String> pages = const [],
  Map<String, bool> history = const {},
  Set<String> removed = const {},
  bool noMain = false,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: guardian,
  model: (ViewRequestDraftModel()..setOwnMainGuardianPresent(!noMain))
      .snapshot(),
  tab: tab,
  pages: pages,
  guardianHistory: history,
  removedGuardians: removed,
);
ZyraGuardianCircleScreen _circle(WidgetTester tester) =>
    tester.widget(find.byType(ZyraGuardianCircleScreen));
Future<void> _openGuardianCircle(
  BaselineHarness h, {
  Map<String, bool> history = const {},
}) async {
  await h.mount(
    guardian: true,
    checkpoint: _checkpoint(
      guardian: true,
      tab: 2,
      pages: ['guardian_circle'],
      history: history,
    ),
  );
  h.assertPage('guardian_circle');
}

void main() {
  setUp(() => baselineSetUp(evidenceRoot: _evidence));
  tearDown(baselineTearDown);
  testWidgets(
    'Seeker first safety row, NEW persists after opening and Manage opens Guardian tab; all masters',
    (tester) async {
      final h = _h(tester);
      await h.mount(tab: 4);
      final row = _key('concept_guardian_info');
      await Scrollable.ensureVisible(tester.element(row), alignment: .5);
      await h.flush();
      expect(
        tester.getTopLeft(row).dy,
        lessThan(tester.getTopLeft(_key('concept_safety_advice')).dy),
      );
      expect(_key('guardian_info_new'), findsOneWidget);
      if (_capture) {
        await h.capture(
          'profile',
          'profile_tab',
          'what_guardians_can_do_row',
          'Actual Seeker Profile, scrolled to first Safety & Sharing row',
        );
      }
      await h.tap('concept_guardian_info');
      h.assertPage('guardian_info');
      expect(find.text('Hassan · Father'), findsOneWidget);
      final semantics = tester.ensureSemantics();

      const names = [
        '1_your_main_guardian',
        '2_your_additional_guardians',
        '3_other_seekers_guardians',
        '4_no_guardian_ever_sees',
      ];
      const titles = [
        'Your Main Guardian',
        'Your Additional Guardians',
        'Other Seekers’ Guardians',
        'No Guardian ever sees',
      ];
      for (var i = 0; i < 4; i++) {
        expect(
          find.bySemanticsLabel('${titles[i]}, card ${i + 1} of 4'),
          findsOneWidget,
        );
        if (_capture) {
          await h.capture(
            'profile',
            'what_guardians_can_do',
            names[i],
            'Actual Profile entry, card ${i + 1} of 4; shared Profiles card and pills',
          );
        }
        if (i < 3) {
          await h.tap('guardian_info_next');
          await tester.pumpAndSettle();
        }
      }
      semantics.dispose();
      expect(tester.widget<InkWell>(_key('guardian_info_next')).onTap, isNull);
      await h.tap('guardian_info_manage');
      expect(h.latest.tab, 3);
      expect(h.latest.pages, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('zyra_preview_guardian_info_seen_v1'), isTrue);
      await h.mount(tab: 4);
      expect(_key('guardian_info_new'), findsNothing);
      await h.mount(guardian: true, tab: 3);
      expect(row, findsNothing);
    },
  );

  testWidgets(
    'Tap halves, swipe, back arrow and endpoints never wrap; no Main wording',
    (tester) async {
      final h = _h(tester);
      await h.mount(
        checkpoint: _checkpoint(tab: 4, pages: ['guardian_info'], noMain: true),
      );
      expect(find.text('You have no Main Guardian yet'), findsOneWidget);
      expect(
        tester.widget<InkWell>(_key('guardian_info_previous')).onTap,
        isNull,
      );
      final cards = _key('guardian_info_cards');
      var rect = tester.getRect(cards);
      await tester.tapAt(Offset(rect.left + 30, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Your Main Guardian'), findsOneWidget);
      await tester.tapAt(Offset(rect.right - 30, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Your Additional Guardians'), findsOneWidget);
      await tester.drag(cards, const Offset(-360, 0));
      await tester.pumpAndSettle();
      expect(find.text('Other Seekers’ Guardians'), findsOneWidget);
      await h.tap('guardian_info_previous');
      await tester.pumpAndSettle();
      expect(find.text('Your Additional Guardians'), findsOneWidget);
      await tester.drag(cards, const Offset(360, 0));
      await tester.pumpAndSettle();
      expect(find.text('Your Main Guardian'), findsOneWidget);
      await h.tap('guardian_info_next');
      await tester.pumpAndSettle();
      await h.tap('guardian_info_next');
      await tester.pumpAndSettle();
      await h.tap('guardian_info_next');
      await tester.pumpAndSettle();
      rect = tester.getRect(cards);
      await tester.tapAt(Offset(rect.right - 30, rect.center.dy));
      await tester.pumpAndSettle();
      expect(tester.widget<InkWell>(_key('guardian_info_next')).onTap, isNull);
      expect(find.text('No Guardian ever sees'), findsOneWidget);
    },
  );

  testWidgets(
    'Guardian sharing defaults off and is per person; on exposes only names/dates and safe archive',
    (tester) async {
      final h = _h(tester);
      await _openGuardianCircle(h);
      expect(_circle(tester).previewPastTopics, isEmpty);
      await _openGuardianCircle(h, history: {_yusuf: true});
      expect(_circle(tester).previewPastTopics, isEmpty);
      await _openGuardianCircle(h, history: {_hassan: true});
      final circle = _circle(tester);
      final topics = circle.previewPastTopics;
      expect(topics.length, 12);
      final hafsa = topics.singleWhere((topic) => topic.firstName == 'Hafsa');
      expect(hafsa.sharedSummaryLabel, 'Adam & Hafsa · 20 Aug–10 Sep 2026');
      final archive = circle.previewDiscussionArchiveFor!(hafsa)!;
      expect(archive.sharedSummaryLabel, hafsa.sharedSummaryLabel);
      expect(circle.previewDiscussionProfileFor, isNull);
      // Captured archive capability ends when its admitted shell is replaced.
      await _openGuardianCircle(h);
      expect(_circle(tester).previewPastTopics, isEmpty);
      expect(circle.previewDiscussionArchiveFor!(hafsa), isNull);
    },
  );

  testWidgets(
    'Actual consent writes off/on/off, removal clears grant, removed-link checkpoint cannot restore it',
    (tester) async {
      final h = _h(tester);
      await h.mount(tab: 3);
      SeekerGuardianPage page() =>
          tester.widget(find.byType(SeekerGuardianPage));
      Future<bool> consent({bool? enabled}) async =>
          (await page().historyConsentLoader!(
            guardianId: _hassan,
            guardianIsMain: true,
            enabled: enabled,
          )).valueOrNull!.enabled;
      expect(await consent(), isFalse);
      expect(await consent(enabled: true), isTrue);
      expect(h.latest.guardianHistory[_hassan], isTrue);
      expect(await consent(enabled: false), isFalse);
      expect(h.latest.guardianHistory[_hassan], isFalse);
      expect(await consent(enabled: true), isTrue);
      expect(await page().removeGuardian!(_hassan), isNull);
      await h.flush();
      expect(h.latest.removedGuardians, contains(_hassan));
      expect(h.latest.guardianHistory.containsKey(_hassan), isFalse);
      await h.mount(
        checkpoint: _checkpoint(history: {_hassan: true}, removed: {_hassan}),
      );
      expect(h.latest.guardianHistory.containsKey(_hassan), isFalse);
      // A fresh re-link/sample seed starts with no consent.
      await h.mount(tab: 3);
      expect(await consent(), isFalse);
    },
  );

  testWidgets(
    'Seeker Circle catalog and archive presentation stay unchanged with sharing off',
    (tester) async {
      final h = _h(tester);
      await h.mount(tab: 3, pages: ['guardian_circle']);
      final circle = _circle(tester);
      expect(circle.previewPastTopics.length, 12);
      final topic = circle.previewPastTopics.first;
      expect(topic.firstName, 'Elif');
      expect(topic.sharedSummaryLabel, isNull);
      final archive = circle.previewDiscussionArchiveFor!(topic)!;
      expect(archive.sharedSummaryLabel, isNull);
      expect(archive.startedOn, DateTime.utc(2026, 9, 19));
      expect(archive.endedOn, DateTime.utc(2026, 10, 10));
    },
  );

  testWidgets(
    'Larger text cards scroll without overflow and revoked presenter callbacks cannot navigate',
    (tester) async {
      var allowed = true;
      var managed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: SizedBox(
              width: 320,
              height: 568,
              child: ZyraGuardianInfoPresentation(
                mainGuardian: 'Hassan · Father',
                canAct: () => allowed,
                onManage: () => managed++,
                onMove: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      allowed = false;
      await tester.tap(_key('guardian_info_manage'));
      await tester.pumpAndSettle();
      expect(managed, 0);
    },
  );
}
