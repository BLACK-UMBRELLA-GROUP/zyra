// Queue 15: screenshot-only evidence of the current offline Guardian shell.
// Missing Journey readers/reviews are documented rather than reconstructed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import 'baseline_capture_support.dart';

const _enabled = bool.fromEnvironment('ZYRA_BASIC_GUARDIAN_CAPTURE');
const _output =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/BASELINE/SCREENSHOTS/guardian_journey';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/BASIC_GUARDIAN_CAPTURE_2026-10-29';
const _sara = 'draft-sara';
const _hassan = 'draft-guardian-hassan';
const _yusuf = 'draft-guardian-yusuf';
final _scrollAudit = <Map<String, Object?>>[];
final _fixtureAudit = <Map<String, Object?>>[];

DateTime _clock() => DateTime.utc(2026, 10, 29, 12);
ViewRequestDraftModel _active() =>
    ViewRequestDraftModel(capacity: 3, clock: _clock)..seedJourneys(1);

void _next(ViewRequestDraftModel model) {
  final stage = model.stageFor(_sara)!.value;
  if (stage == 'salam_exchange') {
    expect(model.sendSalam(_sara), isTrue);
    expect(model.simulatePeerSalam(_sara), isTrue);
  }
  if (stage == 'compatibility_reveal') {
    expect(model.chooseCompatibilityReveal(_sara), isTrue);
    expect(model.simulatePeerCompatibilityReveal(_sara), isTrue);
    expect(model.chooseStageContinue(_sara), isTrue);
    expect(model.simulatePeerStageContinue(_sara), isTrue);
    expect(model.beginBioStep(_sara), isTrue);
    expect(model.chooseBioReveal(_sara), isTrue);
    expect(model.simulatePeerBioReveal(_sara), isTrue);
    expect(model.chooseBioContinue(_sara), isTrue);
    expect(model.simulatePeerBioContinue(_sara), isTrue);
    expect(model.completeBioStep(_sara), isTrue);
    return;
  }
  expect(model.chooseStageContinue(_sara), isTrue);
  expect(model.simulatePeerStageContinue(_sara), isTrue);
  expect(model.advanceStage(_sara), isTrue);
}

ViewRequestDraftModel _stage(int index) {
  final model = _active();
  for (var count = 0; count < index; count++) {
    _next(model);
  }
  return model;
}

BaselineHarness _harness(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'guardian_journey',
    outputRoot: _output,
    evidenceRoot: _evidence,
    flatOutput: true,
  );
}

Future<void> _mountSeekers(
  BaselineHarness h,
  ViewRequestDraftModel model, {
  bool main = true,
  String plan = 'Guardian One',
}) async {
  await h.mount(
    guardian: true,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: true,
      model: model.snapshot(),
      tab: 2,
      pages: const [],
      guardianJourneyId: _sara,
      mainGuardianId: main ? _hassan : _yusuf,
      guardianMembership: plan,
    ),
  );
  expect(h.latest.guardian, isTrue);
  expect(h.latest.tab, 2);
  expect(h.latest.pages, isEmpty);
  expect(h.latest.guardianMembership, plan);
  expect(h.latest.mainGuardianId, main ? _hassan : _yusuf);
  final projection = h.tester.widget<ZyraOneJourneyGuardianSeekersPresentation>(
    find.byType(ZyraOneJourneyGuardianSeekersPresentation),
  );
  expect(projection.person.id, 'draft-self');
  expect(projection.person.isMain, main);
  final access = model.sampleGuardianAccessFor(_hassan, _sara, isMain: main);
  expect(
    projection.currentJourney != null,
    model.stateFor(_sara) == DraftJourneyState.active && access.view,
  );
}

Future<void> _openJourney(BaselineHarness h) async {
  await h.tapText('Open current Journey');
  h.assertPage('guardian');
  expect(find.text('Adam & Sara'), findsOneWidget);
  expect(h.latest.guardianJourneyId, _sara);
  // The genuine current Guardian Journey page is a narrow summary. The
  // Seeker's readers and stage controls must never be substituted for it.
  for (final key in [
    'draft_begin_$_sara',
    'draft_salam_$_sara',
    'draft_continue_$_sara',
    'concept_current_journey_pages',
  ]) {
    expect(h.key(key), findsNothing);
  }
}

Future<void> _capture(
  BaselineHarness h,
  String page,
  String state,
  String reached, {
  required String plan,
  required String role,
  required bool? view,
  required bool? chat,
}) async {
  await h.capture('guardian_journey', page, state, reached);
  void annotate(String name) {
    final row = h.rows.singleWhere(
      (row) => row['file'] == '${page}__$name.png',
    );
    row['plan'] = plan;
    row['guardian_role'] = role;
    row['sample_view_grant'] = view;
    row['sample_chat_grant'] = chat;
  }

  annotate(state);
  final scrollOwner = page == 'journey'
      ? h.key('draft_scroll')
      : find.byKey(
          const PageStorageKey('guardian-seeker-page-scroll-draft-self'),
        );
  final scroll = find.descendant(
    of: scrollOwner,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  if (scroll.evaluate().isEmpty) {
    _scrollAudit.add({
      'page': page,
      'state': state,
      'scrolled_capture': false,
      'reason': 'No vertical Scrollable in this current presentation.',
    });
    return;
  }
  expect(scroll, findsOneWidget);
  final position = h.tester.state<ScrollableState>(scroll).position;
  final maximum = position.maxScrollExtent;
  final startsAt = position.pixels;
  var ordinal = 0;
  while (position.pixels < position.maxScrollExtent - 1) {
    final before = position.pixels;
    await h.tester.drag(scroll, Offset(0, -position.viewportDimension * .72));
    await h.flush();
    expect(position.pixels, greaterThan(before));
    ordinal++;
    expect(ordinal, lessThanOrEqualTo(12));
    final scrolled = '${state}_scrolled_${ordinal.toString().padLeft(2, '0')}';
    await h.capture(
      'guardian_journey',
      page,
      scrolled,
      '$reached; actual vertical drag $ordinal to ${position.pixels.toStringAsFixed(1)} of ${position.maxScrollExtent.toStringAsFixed(1)} logical points',
    );
    annotate(scrolled);
  }
  _scrollAudit.add({
    'page': page,
    'state': state,
    'starts_at': startsAt,
    'max_scroll_extent': maximum,
    'ends_at': position.pixels,
    'scrolled_captures': ordinal,
    if (maximum <= 1)
      'reason': 'Whole current page fits; no invented scrolled duplicate.',
  });
}

Future<void> _writeEvidence(BaselineHarness h) async {
  await h.tester.runAsync(() async {
    final files = <String, Object?>{
      'rows_guardian_journey.json': h.rows,
      'guardian_journey_scroll_audit.json': _scrollAudit,
      'guardian_journey_fixture_audit.json': _fixtureAudit,
      'guardian_journey_not_in_preview.json': {
        'scope': 'Brief step 4, actual current Founder Guardian shell only',
        'source_paths': [
          'SOURCE/lib/dev/zyra_one_journey_concept_shell.dart::_guardianPermittedJourney',
          'SOURCE/lib/dev/zyra_one_journey_concept_shell.dart::_guardianSeekers',
          'SOURCE/lib/dev/zyra_one_journey_concept_shell.dart::_guardianJourneys',
          'SOURCE/lib/dev/zyra_one_journey_guardian_presentation.dart::ZyraOneJourneyGuardianSeekersPresentation',
          'SOURCE/lib/screens/wali/wali_seeker_workspace_screen.dart::GuardianSeekerWorkspaceView',
        ],
        'not_in_preview': [
          for (final reader in [
            'Chat',
            'Timeline',
            'Bio',
            'Compatibility',
            'Guardians',
          ])
            {
              'state': 'Guardian Journey $reader',
              'status': 'not in preview',
              'reason':
                  'The actual Guardian Journey route contains a linked-Seeker profile card, counterpart first name and stage label only. No $reader action or reader is exposed. Seeker readers are role-restricted and are not a Guardian substitute.',
            },
          for (final review in ['to decide', 'paused', 'timed out'])
            {
              'state': '48-hour Family Review: $review',
              'status': 'not in preview',
              'reason':
                  'The local model advances sample stages without a timed Family Review state machine. The Guardian dashboard passes openReviewIds={} and the current Guardian Journey summary exposes no review controls or timer. No review is invented.',
            },
          {
            'state': 'Journey ended detail',
            'status': 'not in preview',
            'reason':
                'Ending the local Sara attempt removes it from the active-only Guardian projection. The genuine remaining Seekers/No current Journey boundary is captured; there is no Guardian ended-detail entry.',
          },
          for (final consent in ['shared', 'not shared'])
            {
              'state': 'Past Journey summary $consent',
              'status': 'not in preview',
              'reason':
                  'The Founder Seekers presenter supplies no attempt-summary rows or summary loader, so the workspace displays No Journey summaries are available. The Guardian Circle has separate named fictional past topics, but they are not bound to this Journey or per-subject past-summary consent; queue 13 failed the DR-ZYRA-233 identity/consent preflight. Those fixtures cannot demonstrate a shared/not-shared Journey-summary boundary.',
            },
          {
            'state': 'Additional Guardian Chat on versus off: message composer',
            'status': 'not in preview',
            'reason':
                'The admitted local model carries independent View/Chat grants and both actual visible summaries are captured. The Guardian Journey route has no Journey-chat composer in either grant state, so screenshots cannot prove messaging capability.',
          },
        ],
      },
    };
    for (final entry in files.entries) {
      final file = File('$_evidence/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(entry.value),
        flush: true,
      );
    }
  });
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);

  testWidgets(
    'Guardian One Main actual Journey summary at every canonical stage',
    (tester) async {
      final h = _harness(tester);
      expect(ZyraJourneyStages.all, hasLength(8));
      for (var index = 0; index < ZyraJourneyStages.all.length; index++) {
        final stage = ZyraJourneyStages.all[index];
        final model = _stage(index);
        expect(model.stageFor(_sara)?.value, stage.value);
        await _mountSeekers(h, model);
        await _openJourney(h);
        expect(find.text(stage.label), findsOneWidget);
        final before = h.latest.model;
        await _capture(
          h,
          'journey',
          'main_one_${stage.value}',
          'Guardian One Main Hassan; detached sample model at ${stage.label}; actual Seekers > Open current Journey',
          plan: 'Guardian One',
          role: 'Main Guardian',
          view: true,
          chat: true,
        );
        expect(h.latest.model.states, before.states);
        expect(h.latest.model.progress, before.progress);
        _fixtureAudit.add({
          'state': 'main_one_${stage.value}',
          'role': 'Main Guardian',
          'plan': 'Guardian One',
          'stage': stage.value,
          'entry': 'actual Seekers > Open current Journey',
          'presentation': 'current Guardian summary, not Seeker stage content',
        });
      }
      await _writeEvidence(h);
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 8)),
  );

  testWidgets(
    'Additional Guardian independent View and Chat grants and no-access boundary',
    (tester) async {
      final h = _harness(tester);
      for (final chat in [false, true]) {
        final model = _stage(7);
        expect(
          model.setSampleGuardianJourneyAccess(
            _hassan,
            _sara,
            viewEnabled: true,
            chatEnabled: chat,
          ),
          isTrue,
        );
        expect(model.sampleGuardianAccessFor(_hassan, _sara), (
          view: true,
          chat: chat,
        ));
        await _mountSeekers(h, model, main: false);
        expect(find.text('Additional Guardian'), findsWidgets);
        await _openJourney(h);
        final state = chat
            ? 'additional_view_on_chat_on'
            : 'additional_view_on_chat_off';
        await _capture(
          h,
          'journey',
          state,
          'Guardian One Hassan is Additional (Main=Yusuf); explicit existing local View=true/Chat=$chat grant; actual Seekers > Open current Journey',
          plan: 'Guardian One',
          role: 'Additional Guardian',
          view: true,
          chat: chat,
        );
        _fixtureAudit.add({
          'state': state,
          'role': 'Additional Guardian',
          'plan': 'Guardian One',
          'view': true,
          'chat': chat,
          'visible_chat_composer': false,
        });
      }
      final denied = _active();
      expect(
        denied.setSampleGuardianJourneyAccess(
          _hassan,
          _sara,
          viewEnabled: false,
          chatEnabled: false,
        ),
        isTrue,
      );
      await _mountSeekers(h, denied, main: false);
      expect(find.text('Open current Journey'), findsNothing);
      expect(find.text('No current Journey'), findsWidgets);
      await _capture(
        h,
        'seekers',
        'additional_view_off_chat_off',
        'Guardian One Additional Hassan; existing local View=false/Chat=false grant; actual Seekers workspace excludes the current Journey and its entry',
        plan: 'Guardian One',
        role: 'Additional Guardian',
        view: false,
        chat: false,
      );
      expect(h.latest.pages, isEmpty);
      expect(h.latest.model.states[_sara], DraftJourneyState.active);
      _fixtureAudit.add({
        'state': 'additional_view_off_chat_off',
        'role': 'Additional Guardian',
        'plan': 'Guardian One',
        'view': false,
        'chat': false,
        'journey_still_active': true,
        'open_current_journey_entry': false,
      });
      await _writeEvidence(h);
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 6)),
  );

  testWidgets(
    'Guardian Basic view-only and the genuine boundary after a Journey ends',
    (tester) async {
      final h = _harness(tester);
      final basic = _stage(7);
      expect(
        basic.setSampleGuardianMembership(
          _hassan,
          DraftGuardianMembership.basic,
        ),
        isTrue,
      );
      expect(basic.sampleGuardianAccessFor(_hassan, _sara, isMain: true), (
        view: true,
        chat: false,
      ));
      await _mountSeekers(h, basic, plan: 'Guardian Basic');
      await _openJourney(h);
      expect(find.byType(TextField), findsNothing);
      await _capture(
        h,
        'journey',
        'main_basic_view_only',
        'Existing local Hassan Guardian Basic membership, Main role; actual Seekers > Open current Journey; View=true/Chat=false',
        plan: 'Guardian Basic',
        role: 'Main Guardian',
        view: true,
        chat: false,
      );
      _fixtureAudit.add({
        'state': 'main_basic_view_only',
        'role': 'Main Guardian',
        'plan': 'Guardian Basic',
        'view': true,
        'chat': false,
        'visible_chat_composer': false,
      });

      final ended = _stage(7);
      expect(ended.end(_sara), isTrue);
      await _mountSeekers(h, ended);
      expect(h.latest.model.endedAttempts, hasLength(1));
      expect(find.text('Open current Journey'), findsNothing);
      expect(find.text('No current Journey'), findsWidgets);
      expect(find.text('No Journey summaries are available.'), findsOneWidget);
      await _capture(
        h,
        'seekers',
        'main_one_after_journey_ended',
        'Existing sample end(Sara) after Open Conversation; actual Main Guardian Seekers workspace has no current Journey and no supplied past-summary rows',
        plan: 'Guardian One',
        role: 'Main Guardian',
        view: null,
        chat: null,
      );
      _fixtureAudit.add({
        'state': 'main_one_after_journey_ended',
        'role': 'Main Guardian',
        'plan': 'Guardian One',
        'ended_attempts': h.latest.model.endedAttempts.length,
        'open_current_journey_entry': false,
        'past_summary_rows_supplied_by_preview': 0,
      });
      await _writeEvidence(h);
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
