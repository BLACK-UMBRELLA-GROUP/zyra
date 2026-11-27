// Q240 / LOCK 4 V5: reserve the gap in the shared production details face.
// The public callers supply the photo and optional introduction data here;
// neither the app widget nor its layout receives a test-only switch.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_full_profile_preview.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_profile_details_page.dart';

import 'visual/baseline_capture_support.dart';

const _id = 'line141-gap-maryam';
const _name = 'Maryam Rahman';
const _byline = 'Hassan · Father';

enum _Caller { profiles, fullProfile, introduction }

SeekerProfile _profile(bool hasPhoto) => SeekerProfile(
  id: _id,
  firstName: 'Maryam',
  surnameLine: 'Rahman',
  age: 28,
  city: 'Manchester',
  publicNationality: 'British',
  publicEthnicity: 'Arab',
  gender: 'female',
  seekerPlan: ZyraPlan.one,
  mainGuardianRelationship: 'Father',
  photos: hasPhoto ? const ['local-admitted-photo'] : const [],
);

Widget _photo(
  BuildContext context,
  String source, {
  required double width,
  required double height,
  required Alignment alignment,
}) => const ColoredBox(color: Color(0xFF87936A));

Widget _presenter(_Caller caller, SeekerProfile profile) => switch (caller) {
  _Caller.profiles => ZyraBrowseDesigns(
    profiles: [profile],
    selectedIndex: 0,
    design: ZyraOneJourneyBrowseDesign.portraitCard,
    photoBuilder: _photo,
    fixedTabFooter: true,
    bottomPadding: 100,
    onRequest: (_) {},
  ),
  _Caller.fullProfile || _Caller.introduction => ZyraFullProfilePreview(
    profile: profile,
    situation: caller == _Caller.introduction
        ? ZyraFullProfileSituation.introduction
        : ZyraFullProfileSituation.general,
    introductionByline: caller == _Caller.introduction ? _byline : null,
    photoBuilder: _photo,
    canAct: () => true,
    onAction: () {},
    onSecondary: () {},
  ),
};

double _assertGap(
  WidgetTester tester, {
  required bool hasByline,
  required String phase,
}) {
  final page = find.byType(ZyraProfileDetailsPage);
  expect(page, findsOneWidget);
  final name = find.descendant(of: page, matching: find.text(_name));
  final byline = find.descendant(
    of: page,
    matching: find.text('Put forward by $_byline'),
  );
  expect(name, findsOneWidget);
  expect(byline, hasByline ? findsOneWidget : findsNothing);
  final blockBottom = tester.getRect(hasByline ? byline : name).bottom;
  final firstTile = find.descendant(
    of: page,
    matching: find.byKey(const ValueKey('profile-detail-tile-AGE')),
  );
  expect(firstTile, findsOneWidget);
  final gap = tester.getRect(firstTile).top - blockBottom;
  expect(
    gap,
    greaterThanOrEqualTo(12 - .001),
    reason: '$phase: tiles must clear the whole final name/byline text box',
  );

  // Spare height may enlarge the visible gap while centering the identity.
  // The reserved spacer itself stays twelve physical layout points even
  // when the card runs out of spare height and begins to scroll.
  final identityAndTiles = tester
      .widgetList<Column>(
        find.ancestor(of: firstTile, matching: find.byType(Column)),
      )
      .where(
        (column) =>
            column.children.length > 2 && column.children.first is Expanded,
      );
  expect(identityAndTiles, hasLength(1));
  final spacerWidget = identityAndTiles.single.children[1];
  expect(spacerWidget, isA<SizedBox>());
  final spacer = spacerWidget as SizedBox;
  expect(spacer.height, 12);
  final spacerFinder = find.byWidget(spacer);
  expect(tester.getSize(spacerFinder).height, closeTo(12, .001));
  return gap;
}

void main() {
  // Named baseline setup loads the bundled Poppins weights, actual app theme,
  // and scroll behavior; no Ahem-only geometry or evidence files are used.
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final size in [const Size(375, 667), const Size(430, 932)]) {
    for (final scale in [1.0, 1.3]) {
      for (final caller in _Caller.values) {
        for (final hasPhoto in [false, true]) {
          final dimensions = '${size.width.round()}x${size.height.round()}';
          final label =
              '${caller.name} $dimensions scale $scale '
              '${hasPhoto ? 'photo' : 'no photo'}';
          testWidgets(
            'Q240 fixed name-to-tiles gap: $label',
            (tester) async {
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final harness = BaselineHarness(
                tester,
                group: 'line141_gap_${caller.name}_${dimensions}_$scale',
                logicalSize: size,
                devicePixelRatio: 1,
                textScale: scale,
                safePadding: size.width == 375
                    ? const EdgeInsets.only(top: 20)
                    : const EdgeInsets.only(top: 59, bottom: 34),
                reduceMotion: true,
              );
              await harness.mountPresentation(
                checkpoint: ZyraPreviewNavigationCheckpoint(
                  guardian: false,
                  model: ViewRequestDraftModel(capacity: 1).snapshot(),
                  tab: 0,
                  pages: const [],
                ),
                child: Scaffold(body: _presenter(caller, _profile(hasPhoto))),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              final details = tester.widget<ZyraProfileDetailsPage>(
                find.byType(ZyraProfileDetailsPage),
              );
              expect(details.firstPhoto, hasPhoto ? isNotNull : isNull);
              expect(details.fixedCard, isTrue);
              final hasByline = caller == _Caller.introduction;
              final gap = _assertGap(
                tester,
                hasByline: hasByline,
                phase: '$label settled',
              );

              final scroll = find.descendant(
                of: find.byKey(
                  const ValueKey('concept_browse_details_scroll_$_id'),
                ),
                matching: find.byType(Scrollable),
              );
              expect(scroll, findsOneWidget);
              final position = tester.state<ScrollableState>(scroll).position;
              if (position.maxScrollExtent > 0) {
                position.jumpTo(math.min(24.0, position.maxScrollExtent));
                await tester.pumpAndSettle();
                expect(
                  _assertGap(
                    tester,
                    hasByline: hasByline,
                    phase: '$label scrolled',
                  ),
                  closeTo(gap, .001),
                  reason: 'Scrolling must preserve the reserved physical gap',
                );
              }
              expect(tester.takeException(), isNull);
            },
            variant: TargetPlatformVariant.only(TargetPlatform.iOS),
          );
        }
      }
    }
  }
}
