import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE81_PROFILES_CAPTURE_DIR');
const _card = ValueKey('concept_browse_portrait_card');

ZyraOneJourneyBrowseDesigns _browse(WidgetTester tester) =>
    tester.widget(find.byType(ZyraOneJourneyBrowseDesigns));

String _selectedId(WidgetTester tester) {
  final view = _browse(tester);
  return view.profiles[view.selectedIndex].id;
}

Finder _request(String id) => find.byKey(ValueKey('draft_profile_$id'));

ZyraPreviewNavigationCheckpoint _savedBasic({
  ZyraBrowseFilter filter = const ZyraBrowseFilter(),
}) => ZyraPreviewNavigationCheckpoint(
  guardian: false,
  model: ViewRequestDraftModel(capacity: 1).snapshot(),
  tab: 0,
  pages: const [],
  seekerMembership: 'Seeker Basic',
  browseId: 'draft-aisha',
  browseHistory: const ['draft-sara', 'draft-aisha', 'draft-maryam'],
  browseCursor: 1,
  seenBrowseProfiles: const {'draft-hana'},
  browseFilter: filter,
);

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final viewport in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final (size, padding) = viewport;
    final dimensions = '${size.width.round()}x${size.height.round()}';
    testWidgets(
      'Profiles locked geometry and first-page action at $dimensions',
      (tester) async {
        final harness = BaselineHarness(
          tester,
          group: 'line81_profiles_$dimensions',
          outputRoot: _captures,
          evidenceRoot: _captures,
          flatOutput: true,
          logicalSize: size,
          safePadding: padding,
          reduceMotion: true,
        );
        await harness.mount();
        final id = _selectedId(tester);
        final card = tester.getRect(find.byKey(_card));
        Rect tile(String label) =>
            tester.getRect(harness.key('profile-detail-tile-$label'));
        final age = tile('AGE');
        final location = tile('LOCATION');
        final nationality = tile('NATIONALITY');
        final ethnicity = tile('ETHNICITY');
        final request = tester.getRect(_request(id));
        final value = tester.widget<Text>(find.text('Birmingham'));
        expect(age.height, greaterThanOrEqualTo(88));
        expect(age.height, closeTo(nationality.height, .01));
        expect(age.height, closeTo(location.height, .01));
        expect(age.height, closeTo(ethnicity.height, .01));
        expect(location.left - age.right, closeTo(12, .01));
        expect(nationality.top - age.bottom, closeTo(12, .01));
        final minimumGrid = math.max(196.0, card.height * .4);
        expect(
          ethnicity.bottom - age.top,
          inInclusiveRange(minimumGrid - .01, minimumGrid + 11),
        );
        expect(value.style!.fontSize, 18);
        expect(value.style!.height, 1.2);
        expect(request.left, age.left);
        expect(request.right, location.right);
        expect(request.top - ethnicity.bottom, closeTo(12, .01));
        expect(request.height, 52);
        expect(
          tester.getSize(harness.key('concept_browse_details_avatar_$id')),
          const Size.square(124),
        );
        expect(
          tester.getRect(find.byType(FloatingNavBar)).top - card.bottom,
          closeTo(16, .01),
        );
        expect(harness.key('concept_previous_profile'), findsNothing);
        expect(harness.key('concept_next_profile'), findsNothing);
        if (_captures.isNotEmpty) {
          await harness.capture(
            'profiles',
            'profiles',
            'first_page_$dimensions',
            'Admitted Founder Profiles route, first gallery page',
          );
        }
        final retainedRequest = tester.widget<InkWell>(_request(id)).onTap!;
        await harness.tap('concept_browse_dot_target_1');
        expect(_request(id).hitTestable(), findsNothing);
        retainedRequest();
        await harness.flush();
        expect(find.text('Request sent'), findsNothing);
        if (_captures.isNotEmpty) {
          await harness.capture(
            'profiles',
            'profiles',
            'photo_page_$dimensions',
            'Admitted Founder Profiles route, first photo via header dot',
          );
        }
        await harness.tap('concept_browse_dot_target_0');
        final action = _request(id);
        await tester.ensureVisible(action);
        await tester.pump();
        expect(action.hitTestable(), findsOneWidget);
        if (_captures.isNotEmpty && size.height < 700) {
          await harness.capture(
            'profiles',
            'profiles',
            'first_page_scrolled_$dimensions',
            'Admitted Founder Profiles route scrolled to the request action',
          );
        }
        await tester.tap(action);
        await harness.flush();
        expect(find.text('Request sent'), findsOneWidget);
        if (_captures.isNotEmpty && size.width == 430) {
          await harness.capture(
            'profiles',
            'profiles',
            'sent_page_$dimensions',
            'Admitted Founder Profiles route after tapping the in-card action',
          );
        }
        await tester.tap(action);
        await harness.flush();
        expect(find.text('Request a Journey'), findsOneWidget);
      },
    );
  }

  testWidgets('Profiles drags show the next card before committing selection', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final harness = BaselineHarness(tester, group: 'line81_profile_drag');
    await harness.mount();
    final start = _selectedId(tester);
    final next = _browse(tester).profileSwipe!.nextIndex!;
    final nextId = _browse(tester).profiles[next].id;
    final nextDetails = harness.key('concept_browse_details_$nextId');
    final card = find.byKey(_card);
    final frame = tester.getRect(card);
    final gesture = await tester.startGesture(
      tester.getCenter(_request(start)),
    );
    await gesture.moveBy(const Offset(-155, 0));
    await tester.pump();
    expect(_selectedId(tester), start);
    expect(nextDetails, findsOneWidget);
    expect(tester.getRect(nextDetails).intersect(frame).width, greaterThan(0));
    expect(_request(nextId).hitTestable(), findsNothing);
    expect(find.bySemanticsLabel('Request a Journey'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_selectedId(tester), start);
    await harness.flush();
    expect(_selectedId(tester), nextId);
    expect(_request(nextId).hitTestable(), findsOneWidget);
    await tester.drag(card, const Offset(150, 0));
    await harness.flush();
    expect(_selectedId(tester), start);
    expect(find.text('Request sent'), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'Basic backward swipe opens the upgrade sheet without changing profile',
    (tester) async {
      final harness = BaselineHarness(
        tester,
        group: 'line81_profiles_basic',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        reduceMotion: true,
      );
      await harness.mount(
        initialSeekerBasic: true,
        seekerMembership: 'Seeker Basic',
      );
      final card = find.byKey(_card);
      final start = _selectedId(tester);
      await tester.drag(card, const Offset(-160, 0));
      await tester.pump();
      final viewed = _selectedId(tester);
      expect(
        viewed,
        isNot(start),
        reason: 'Reduce Motion settles without a slide.',
      );
      await tester.drag(card, const Offset(120, 0));
      await harness.flush();
      expect(_selectedId(tester), viewed);
      expect(find.text('Going back comes with Seeker One'), findsOneWidget);
      if (_captures.isNotEmpty) {
        await harness.capture(
          'profiles',
          'profiles',
          'basic_back_sheet_430x932',
          'Seeker Basic swiped backwards from the next admitted profile',
        );
      }
      await tester.tap(find.text('Not now'));
      await harness.flush();
      expect(_selectedId(tester), viewed);
      expect(find.text('Going back comes with Seeker One'), findsNothing);
      await tester.drag(card, const Offset(120, 0));
      await harness.flush();
      await tester.tap(find.text('See Seeker One'));
      await harness.flush();
      expect(find.byType(ZyraOneUpgradePage), findsOneWidget);
    },
  );

  for (final restore in [true, false]) {
    testWidgets(
      'Basic checkpoint keeps seen people after location restore=$restore',
      (tester) async {
        final harness = BaselineHarness(
          tester,
          group: 'line81_basic_restore_$restore',
          reduceMotion: true,
        );
        await harness.mount(
          checkpoint: _savedBasic(),
          restoreLocation: restore,
        );
        if (restore) {
          expect(_selectedId(tester), 'draft-aisha');
          await tester.drag(find.byKey(_card), const Offset(-160, 0));
          await harness.flush();
        } else {
          await harness.tap('floating-nav-item-0');
        }
        final selected = _selectedId(tester);
        expect(
          selected,
          isNot(
            isIn(['draft-sara', 'draft-aisha', 'draft-maryam', 'draft-hana']),
          ),
        );
        await tester.drag(find.byKey(_card), const Offset(110, 0));
        await harness.flush();
        expect(_selectedId(tester), selected);
        expect(find.text('Going back comes with Seeker One'), findsOneWidget);
      },
    );
  }

  testWidgets('Basic clearing an empty filter does not revive a seen person', (
    tester,
  ) async {
    final harness = BaselineHarness(
      tester,
      group: 'line81_basic_filter',
      reduceMotion: true,
    );
    await harness.mount(
      checkpoint: _savedBasic(
        filter: const ZyraBrowseFilter(minAge: 26, maxAge: 26),
      ),
    );
    expect(find.text('No profiles in this view.'), findsOneWidget);
    await harness.tap('concept_clear_filters');
    expect(
      _selectedId(tester),
      isNot(isIn(['draft-sara', 'draft-aisha', 'draft-maryam', 'draft-hana'])),
    );
  });
}
