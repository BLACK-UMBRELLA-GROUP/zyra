// LOCK 7 uses the actual admitted sample shell, current LOCK4 card and LOCK6 nav.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import 'baseline_capture_support.dart';

const _enabled = bool.fromEnvironment('ZYRA_LOCK7_CAPTURE');
const _output =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/REQUEST_ROW/BUILT';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK7_REQUEST_ROW_2026-10-30';
DateTime _clock() => DateTime.utc(2026, 10, 29, 12);
Finder _key(String value) => find.byKey(ValueKey(value));

Map<String, double> _rect(Rect value) => {
  'left': value.left,
  'top': value.top,
  'width': value.width,
  'height': value.height,
};

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);

  for (final (state, id, history) in [
    (
      'not_requested',
      'draft-aisha',
      ['draft-amira', 'draft-sara', 'draft-aisha'],
    ),
    ('sent', 'draft-sara', ['draft-amira', 'draft-sara']),
    ('first_profile', 'draft-amira', ['draft-amira']),
  ]) {
    testWidgets(
      'LOCK 7 actual Profiles $state',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = BaselineHarness(
          tester,
          group: 'lock7_$state',
          outputRoot: _output,
          evidenceRoot: _evidence,
          flatOutput: true,
        );
        final model = ViewRequestDraftModel(capacity: 3, clock: _clock);
        if (state == 'first_profile') {
          // Real local decline leaves Amira discoverable, with no active request.
          expect(model.declineReceived(id), isTrue);
        }
        await h.mount(
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: false,
            model: model.snapshot(),
            tab: 0,
            pages: const [],
            browseId: id,
            browseHistory: history,
            browseCursor: history.length - 1,
          ),
        );
        expect(h.latest.browseId, id);
        expect(h.latest.pages, isEmpty);
        final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
          find.byType(ZyraOneJourneyBrowseDesigns),
        );
        expect(browse.requestRowLabels, isNotNull);
        expect(browse.profiles[browse.selectedIndex].id, id);
        final request = _key('draft_profile_$id');
        expect(find.text('Request a Journey'), findsOneWidget);
        if (state == 'sent') {
          await tester.tap(request);
          await h.flush();
          expect(h.latest.model.states[id], DraftJourneyState.sent);
          expect(find.text('Request sent'), findsOneWidget);
        }
        final surface = _key('concept_request_row_surface');
        expect(tester.getSize(surface), const Size(390, 56));
        expect(
          tester.getSize(_key('concept_previous_profile')),
          const Size(68, 56),
        );
        expect(
          tester.getSize(_key('concept_next_profile')),
          const Size(68, 56),
        );
        expect(browse.onPrevious == null, state == 'first_profile');
        await h.capture(
          'browse_and_requests',
          'request_row',
          state,
          'Actual Founder Seeker root; validated local browse checkpoint for $id; ${state == 'sent'
              ? 'real send tap'
              : state == 'first_profile'
              ? 'local received decline removes the request before browsing'
              : 'unsent state'}; current LOCK4 photo and LOCK6 navigation',
        );
        final geometry = {
          'state': state,
          'profile': id,
          'pill': _rect(tester.getRect(surface)),
          'previous': _rect(tester.getRect(_key('concept_previous_profile'))),
          'request': _rect(tester.getRect(request)),
          'next': _rect(tester.getRect(_key('concept_next_profile'))),
          'previous_enabled': browse.onPrevious != null,
          'logical_size': [430, 932],
          'pixel_ratio': 3,
        };
        if (state == 'sent') {
          await tester.tap(request);
          await h.flush();
          expect(h.latest.model.states[id], isNull);
          expect(
            h.latest.model.pastRequests.last.outcome,
            DraftPastRequestOutcome.cancelled,
          );
          expect(find.text('Request a Journey'), findsOneWidget);
        }
        await tester.runAsync(
          () => File(
            '$_evidence/geometry_$state.json',
          ).writeAsString(const JsonEncoder.withIndent('  ').convert(geometry)),
        );
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpWidget(const SizedBox());
      },
      skip: !_enabled,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}
