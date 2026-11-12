import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_score_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/services/zyra_account_state.dart';

import 'baseline_capture_support.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _hassan = 'draft-guardian-hassan';
const _otherGuardian = 'draft-guardian-yusuf';
const _activeRow = 'draft_guardian_compatibility_$_sara';
const _next = 'draft_compatibility_score_next';
const _cta = 'draft_compatibility_topic_action';
const _captures = String.fromEnvironment(
  'ZYRA_LINE88_COMPATIBILITY_CAPTURE_DIR',
);
const _topics = [
  'Lifestyle',
  'Work & Education',
  'Family Values',
  'Marriage Goals',
  'Personality',
  'Deen',
];

DateTime _endedAt() => DateTime.utc(2026, 10, 29, 12);

ViewRequestDraftModel _model({int count = 1, DateTime? date}) {
  final model = ViewRequestDraftModel(
    capacity: 3,
    clock: () => date ?? _endedAt(),
  );
  expect(model.seedJourneys(count), isTrue);
  return model;
}

void _reveal(
  ViewRequestDraftModel model,
  String subject, {
  bool mutual = true,
}) {
  expect(model.sendSalam(subject), isTrue);
  expect(model.simulatePeerSalam(subject), isTrue);
  expect(model.chooseStageContinue(subject), isTrue);
  expect(model.simulatePeerStageContinue(subject), isTrue);
  expect(model.advanceStage(subject), isTrue);
  expect(model.chooseCompatibilityReveal(subject), isTrue);
  if (mutual) expect(model.simulatePeerCompatibilityReveal(subject), isTrue);
}

ZyraPreviewNavigationCheckpoint _checkpoint(
  ViewRequestDraftModel model, {
  bool guardian = true,
  bool basic = true,
  String? plan,
  bool main = true,
  bool share = false,
  bool linked = true,
  int seeker = 0,
  int tab = 1,
  List<String> pages = const [],
  String? subject,
  int? attempt,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: guardian,
  model: model.snapshot(),
  tab: tab,
  pages: pages,
  guardianJourneyId: subject,
  guardianJourneyAttemptRevision: attempt,
  guardianMembership: plan ?? (basic ? 'Guardian Basic' : 'Guardian One'),
  mainGuardianId: main ? _hassan : _otherGuardian,
  removedGuardians: linked ? const [] : const [_hassan],
  guardianHistory: share ? const {_hassan: true} : const {},
  guardianTabs: ZyraGuardianTabsSnapshot(seeker: seeker),
);

Future<void> _mount(
  BaselineHarness harness,
  ZyraPreviewNavigationCheckpoint checkpoint, {
  DateTime Function()? clock,
}) => harness.mount(
  guardian: checkpoint.guardian,
  checkpoint: checkpoint,
  previewClock: clock ?? _endedAt,
);

Future<void> _back(BaselineHarness harness) async {
  await harness.tester.binding.handlePopRoute();
  await harness.flush();
}

Future<void> _openJourney(
  BaselineHarness harness, {
  bool workspace = false,
}) async {
  if (workspace) {
    await harness.tap('guardian_seeker_0');
    harness.assertPage('guardian_seeker');
  }
  await harness.tap('guardian_journey');
  harness.assertPage('guardian');
  expect(find.text('Adam & Sara'), findsOneWidget);
}

Finder get _reader => find.byType(ZyraCompatibilityScoreReader);

String _pastRow(DraftEndedJourneyAttempt attempt) =>
    'draft_guardian_past_compatibility_${attempt.profileId}_${attempt.id}';

VoidCallback _rowTap(BaselineHarness harness) {
  final control = find
      .ancestor(
        of: find.text('Compatibility score'),
        matching: find.byWidgetPredicate(
          (widget) => widget is InkWell || widget is TextButton,
        ),
      )
      .first;
  final widget = harness.tester.widget(control);
  return widget is InkWell ? widget.onTap! : (widget as TextButton).onPressed!;
}

Future<void> _capture(
  BaselineHarness harness,
  String state,
  String reached,
) async {
  if (_captures.isEmpty) return;
  await harness.capture(
    'compatibility',
    'guardian_compatibility',
    state,
    reached,
  );
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final viewport in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34), false),
    (const Size(375, 667), const EdgeInsets.only(top: 20), true),
  ]) {
    final (size, safePadding, workspace) = viewport;
    final dimensions = '${size.width.round()}x${size.height.round()}';
    testWidgets('Guardian Basic locked topics through Journey at $dimensions', (
      tester,
    ) async {
      final harness = BaselineHarness(
        tester,
        group: 'line88_guardian_compatibility_$dimensions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: safePadding,
        reduceMotion: true,
      );
      final model = _model();
      _reveal(model, _sara, mutual: false);
      await _mount(harness, _checkpoint(model, tab: workspace ? 3 : 1));
      await _openJourney(harness, workspace: workspace);
      expect(harness.key(_activeRow), findsNothing);
      expect(_reader, findsNothing);
      await _capture(
        harness,
        'one_reveal_$dimensions',
        'Guardian Journey after one reveal',
      );

      final fixture = harness.shellFixture;
      final access = fixture.compatibilityAccess!;
      expect(access.unlock(_sara), isTrue);
      expect(fixture.model.simulatePeerCompatibilityReveal(_sara), isTrue);
      expect(fixture.refresh(), isTrue);
      await harness.flush();
      expect(harness.key(_activeRow), findsOneWidget);
      await _capture(
        harness,
        'both_reveals_$dimensions',
        'Guardian Journey after both reveals',
      );
      await harness.tap(_activeRow);
      expect(_reader, findsOneWidget);
      expect(find.text('1 / 7'), findsOneWidget);
      expect(harness.key('draft_compatibility_overall_score'), findsOneWidget);
      await _capture(
        harness,
        'basic_overall_$dimensions',
        'Guardian Basic Overall after both reveals',
      );

      await tester.drag(
        harness.key('draft_compatibility_score_pages'),
        const Offset(-240, 0),
      );
      await harness.flush();
      for (var topic = 1; topic <= _topics.length; topic++) {
        expect(find.text('${topic + 1} / 7'), findsOneWidget);
        expect(find.text(_topics[topic - 1]), findsOneWidget);
        expect(
          harness.key('draft_compatibility_locked_topic_$topic'),
          findsOneWidget,
        );
        expect(
          harness.key('draft_compatibility_category_score_$topic'),
          findsNothing,
        );
        expect(
          find.text('Every topic comes with Guardian One'),
          findsOneWidget,
        );
        expect(find.text('See Guardian One'), findsOneWidget);
        expect(find.textContaining('Unlock'), findsNothing);
        final reader = tester.widget<ZyraCompatibilityScoreReader>(_reader);
        expect(reader.topicScores, isNull);
        final gate = reader.topicGate;
        expect(gate?.onUnlock, isNull);
        expect(gate?.onBuyMore, isNull);
        expect(gate?.balance, 0);
        if (topic == 1) {
          await _capture(
            harness,
            'basic_locked_$dimensions',
            'Guardian Basic locked Lifestyle page',
          );
        }
        await harness.tap(_next);
      }
      expect(find.text('1 / 7'), findsOneWidget);
      await harness.tap(_next);
      final stale = tester.widget<FilledButton>(harness.key(_cta)).onPressed!;
      await harness.tap(_cta);
      expect(find.byType(ZyraOneUpgradePage), findsOneWidget);
      expect(find.text('Guardian One'), findsWidgets);
      await harness.tapText('Not now');
      stale();
      await harness.flush();
      expect(find.byType(ZyraOneUpgradePage), findsNothing);
      expect(_reader, findsOneWidget);
      expect(access.balance, 0);
      expect(access.isUnlocked(_sara), isTrue);
    });
  }

  testWidgets('Guardian One reads all seven pages for the selected Journey', (
    tester,
  ) async {
    final harness = BaselineHarness(
      tester,
      group: 'line88_guardian_one',
      outputRoot: _captures,
      evidenceRoot: _captures,
      flatOutput: true,
      reduceMotion: true,
    );
    final model = _model(count: 2);
    _reveal(model, _sara);
    await _mount(harness, _checkpoint(model, basic: false, subject: _sara));
    await _openJourney(harness);
    final oldRow = _rowTap(harness);
    await harness.tap('concept_guardian_journey_$_aisha');
    expect(find.text('Adam & Aisha'), findsOneWidget);
    expect(find.text('Compatibility score'), findsNothing);
    oldRow();
    await harness.flush();
    expect(_reader, findsNothing);
    await harness.tap('concept_guardian_journey_$_sara');
    await harness.tap(_activeRow);
    expect(find.text('1 / 7'), findsOneWidget);
    final result = tester.widget<ZyraCompatibilityScoreReader>(_reader);
    expect(result.topicScores?.map((topic) => topic.name), _topics);
    for (var topic = 1; topic <= _topics.length; topic++) {
      await harness.tap(_next);
      expect(find.text('${topic + 1} / 7'), findsOneWidget);
      expect(find.text(_topics[topic - 1]), findsOneWidget);
      expect(
        harness.key('draft_compatibility_category_score_$topic'),
        findsOneWidget,
      );
      expect(find.text('See Guardian One'), findsNothing);
      if (topic == 1) {
        await _capture(
          harness,
          'one_lifestyle_430x932',
          'Guardian One admitted Lifestyle score',
        );
      }
    }
  });

  testWidgets('Additional Guardian View must be current and attempt scoped', (
    tester,
  ) async {
    final harness = BaselineHarness(tester, group: 'line88_attempt_view');
    final model = _model(count: 2);
    _reveal(model, _sara);
    _reveal(model, _aisha);
    expect(
      model.setSampleGuardianJourneyAccess(_hassan, _aisha, viewEnabled: true),
      isTrue,
    );
    await _mount(harness, _checkpoint(model, main: false, subject: _sara));
    await _openJourney(harness);
    expect(harness.key(_activeRow), findsNothing);
    final fixture = harness.shellFixture;
    expect(
      fixture.model.setSampleGuardianJourneyAccess(
        _hassan,
        _sara,
        viewEnabled: true,
      ),
      isTrue,
    );
    expect(fixture.refresh(), isTrue);
    await harness.flush();
    final oldRow = _rowTap(harness);
    expect(
      fixture.model.setSampleGuardianJourneyAccess(
        _hassan,
        _sara,
        viewEnabled: false,
      ),
      isTrue,
    );
    oldRow();
    await harness.flush();
    expect(_reader, findsNothing);
    expect(fixture.refresh(), isTrue);
    await harness.flush();
    expect(harness.key(_activeRow), findsNothing);
  });

  testWidgets(
    'Reader CTA expires on plan, role, account and linked Seeker changes',
    (tester) async {
      final harness = BaselineHarness(
        tester,
        group: 'line88_reader_ownership',
        reduceMotion: true,
      );
      final model = _model();
      _reveal(model, _sara);
      await _mount(harness, _checkpoint(model));
      await _openJourney(harness);
      final oldRow = _rowTap(harness);
      await harness.tap(_activeRow);
      await harness.tap(_next);
      final oldCta = tester.widget<FilledButton>(harness.key(_cta)).onPressed!;
      final fixture = harness.shellFixture;
      expect(fixture.setGuardianBasic(_hassan, false), isTrue);
      oldCta();
      await harness.flush();
      expect(find.byType(ZyraOneUpgradePage), findsNothing);
      expect(find.text('See Guardian One'), findsNothing);

      await _back(harness);
      await _back(harness);
      await harness.tap('guardian_seeker');
      oldRow();
      await harness.flush();
      expect(_reader, findsNothing);
      expect(find.textContaining('for Yusuf'), findsOneWidget);
      expect(harness.key('guardian_journey'), findsNothing);
      await harness.tap('guardian_seeker');
      await _openJourney(harness);
      final accountRow = _rowTap(harness);
      final account = ZyraAccountState.userId;
      ZyraAccountState.synchronize('line88-other-fixture-owner');
      ZyraAccountState.synchronize(account);
      accountRow();
      await harness.flush();
      expect(_reader, findsNothing);

      await _mount(harness, _checkpoint(model));
      await _openJourney(harness);
      final roleRow = _rowTap(harness);
      expect(harness.shellFixture.selectRole(false), isTrue);
      roleRow();
      await harness.flush();
      expect(_reader, findsNothing);
    },
  );

  testWidgets('Unrecognized Guardian plans do not admit a result', (
    tester,
  ) async {
    final harness = BaselineHarness(tester, group: 'line88_unknown_plan');
    final model = _model();
    _reveal(model, _sara);

    await _mount(harness, _checkpoint(model, plan: 'Seeker One'));
    await _openJourney(harness);
    expect(harness.key(_activeRow), findsNothing);

    await _mount(harness, _checkpoint(model, basic: false));
    await _openJourney(harness);
    await harness.tap(_activeRow);
    expect(_reader, findsOneWidget);
    expect(
      harness.shellFixture.refresh(
        state: const ZyraOneJourneyShellFixtureState(
          guardianMembership: 'Inactive',
        ),
      ),
      isTrue,
    );
    await harness.flush();
    expect(_reader, findsNothing);
    expect(find.byType(ZyraOneUpgradePage), findsNothing);
    await _back(harness);
    expect(harness.key(_activeRow), findsNothing);
  });

  testWidgets(
    'Restoration cannot revive a reader or substitute a newer attempt',
    (tester) async {
      final harness = BaselineHarness(tester, group: 'line88_restore');
      final model = _model();
      _reveal(model, _sara);
      await _mount(harness, _checkpoint(model));
      await _openJourney(harness);
      await harness.tap(_activeRow);
      final saved = harness.latest;
      await _mount(harness, saved);
      expect(_reader, findsNothing);

      final previous = model.attemptRevisionFor(_sara);
      expect(model.seedJourneys(1), isTrue);
      _reveal(model, _sara);
      expect(model.attemptRevisionFor(_sara), isNot(previous));
      await _mount(
        harness,
        _checkpoint(
          model,
          pages: const ['guardian'],
          subject: _sara,
          attempt: previous,
        ),
      );
      expect(harness.key(_activeRow), findsNothing);
      expect(_reader, findsNothing);
    },
  );

  testWidgets('A linked Seeker Circle opens its exact current Journey', (
    tester,
  ) async {
    final harness = BaselineHarness(tester, group: 'line88_circle_journey');
    final model = _model(count: 2);
    _reveal(model, _sara);
    await _mount(harness, _checkpoint(model, tab: 3));
    await harness.tap('guardian_seeker_0');
    await harness.tap('guardian_circle');
    await harness.tap('circle_topics_topic_$_sara');
    await harness.tap('circle_topics_view_journey');
    expect(harness.latest.pages, [
      'guardian_seeker',
      'guardian_circle',
      'guardian',
    ]);
    expect(harness.latest.guardianJourneyId, _sara);
    expect(find.text('Adam & Sara'), findsOneWidget);
    await harness.tap(_activeRow);
    expect(_reader, findsOneWidget);
    expect(find.text('1 / 7'), findsOneWidget);
  });

  for (final denied in [
    'share',
    'archive View',
    'mutual reveal',
    'safety',
    'link',
  ]) {
    testWidgets('Past Compatibility requires $denied', (tester) async {
      final harness = BaselineHarness(tester, group: 'line88_past_denied');
      final model = _model();
      _reveal(model, _sara, mutual: denied != 'mutual reveal');
      expect(
        model.end(
          _sara,
          mainGuardianId: denied == 'archive View' ? _otherGuardian : _hassan,
        ),
        isTrue,
      );
      if (denied == 'safety') expect(model.block(_sara), isTrue);
      await _mount(
        harness,
        _checkpoint(model, share: denied != 'share', linked: denied != 'link'),
      );
      if (denied != 'link') await harness.tap('guardian_ended');
      expect(
        harness.key(_pastRow(model.currentEndedAttemptFor(_sara)!)),
        findsNothing,
      );
      expect(_reader, findsNothing);
    });
  }

  testWidgets(
    'Past uses View and mutual reveal from each exact archived attempt',
    (tester) async {
      final harness = BaselineHarness(tester, group: 'line88_archive_attempt');
      final earlier = _model(date: DateTime.utc(2026, 10, 10));
      _reveal(earlier, _sara);
      expect(
        earlier.setSampleGuardianJourneyAccess(
          _hassan,
          _sara,
          viewEnabled: true,
        ),
        isTrue,
      );
      expect(earlier.end(_sara, mainGuardianId: _otherGuardian), isTrue);
      final olderAttempt = earlier.currentEndedAttemptFor(_sara)!;
      final newer = _model();
      _reveal(newer, _sara);
      expect(newer.end(_sara, mainGuardianId: _otherGuardian), isTrue);
      final latestAttempt = newer.currentEndedAttemptFor(_sara)!;
      final pair = ViewRequestDraftModel.fromSnapshot(
        newer.snapshot(),
        earlierAttempts: [olderAttempt],
      );
      // Today's Main View cannot retroactively open the newer archived attempt.
      expect(olderAttempt.guardiansWithView, contains(_hassan));
      expect(latestAttempt.guardiansWithView, isNot(contains(_hassan)));
      await _mount(harness, _checkpoint(pair, share: true));
      await harness.tap('guardian_ended');
      final row = find.text('Compatibility score');
      expect(row, findsOneWidget);
      await harness.tapFinder(row);
      expect(_reader, findsOneWidget);

      // An earlier readable attempt can expire independently of the latest one.
      final olderDeadline = DraftEndedJourneyReadWindow.expiresAt(
        olderAttempt.endedAt,
      )!;
      await _mount(
        harness,
        _checkpoint(pair, share: true),
        clock: () => olderDeadline,
      );
      await harness.tap('guardian_ended');
      expect(row, findsNothing);
      expect(_reader, findsNothing);
    },
  );

  for (final openReader in [false, true]) {
    testWidgets(
      'Past ${openReader ? 'reader' : 'row'} expires on the calendar deadline',
      (tester) async {
        final harness = BaselineHarness(
          tester,
          group: 'line88_guardian_past',
          outputRoot: _captures,
          evidenceRoot: _captures,
          flatOutput: true,
          reduceMotion: true,
        );
        final model = _model();
        _reveal(model, _sara);
        expect(model.end(_sara, mainGuardianId: _hassan), isTrue);
        final attempt = model.currentEndedAttemptFor(_sara)!;
        final rowKey = _pastRow(attempt);
        final deadline = DraftEndedJourneyReadWindow.expiresAt(
          attempt.endedAt,
        )!;
        expect(deadline, DateTime.utc(2027, 1, 29, 12));
        var now = deadline.subtract(const Duration(seconds: 30));
        await _mount(
          harness,
          _checkpoint(model, share: true),
          clock: () => now,
        );
        await harness.tap('guardian_ended');
        expect(harness.key(rowKey), findsOneWidget);
        VoidCallback? stale;
        if (openReader) {
          await harness.tap(rowKey);
          expect(find.text('1 / 7'), findsOneWidget);
          await harness.tap(_next);
          expect(
            find.text('Every topic comes with Guardian One'),
            findsOneWidget,
          );
          expect(find.textContaining('Unlock'), findsNothing);
          stale = tester.widget<FilledButton>(harness.key(_cta)).onPressed!;
          await _capture(
            harness,
            'past_basic_locked_430x932',
            'Guardian Basic reads a shared archived Journey before expiry',
          );
        } else {
          stale = _rowTap(harness);
          await _capture(
            harness,
            'past_row_430x932',
            'Guardian Ended Journeys showing the authorized compatibility row',
          );
        }

        now = deadline;
        await tester.pump(const Duration(seconds: 30));
        await harness.flush();
        expect(harness.key(rowKey), findsNothing);
        expect(_reader, findsNothing);
        stale();
        await harness.flush();
        expect(find.byType(ZyraOneUpgradePage), findsNothing);
        expect(
          harness.shellFixture.model.currentEndedAttemptFor(_sara)?.id,
          attempt.id,
        );
        expect(
          harness.shellFixture.model.endedAttemptsFor(_sara),
          hasLength(1),
        );
        await _capture(
          harness,
          'past_${openReader ? 'reader' : 'row'}_expired_430x932',
          'Guardian Past at the exact read deadline',
        );
      },
    );
  }
}
