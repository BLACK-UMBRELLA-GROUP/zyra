import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/connections/connections_section_controller.dart';
import 'package:zyra/screens/connections/zyra_sample_activity.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE98_INTRO_CAPTURE_DIR');
final _samples = ZyraDeveloperSamples.instance;

Widget _frame(Widget child, {bool guardian = false}) => Scaffold(
  backgroundColor: Colors.transparent,
  body: Stack(
    children: [
      Positioned.fill(child: child),
      ZyraShellNavigation(
        lockedTabBar: true,
        contentEdgeInset: 20,
        currentIndex: 2,
        onTap: (_) {},
        items: [
          for (final (index, label)
              in (guardian
                      ? ['Network', 'Journeys', 'My ZYRA', 'Seekers', 'Profile']
                      : [
                          'Profiles',
                          'Journey',
                          'My ZYRA',
                          'Guardian',
                          'Profile',
                        ])
                  .indexed)
            FloatingNavItem(
              icon: const [
                Icons.search,
                Icons.route_outlined,
                Icons.dashboard_outlined,
                Icons.gpp_good_outlined,
                Icons.person_outline,
              ][index],
              label: label,
              useJourneyGlyph: index == 1,
            ),
        ],
      ),
    ],
  ),
);

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);
  tearDown(() {
    _samples.clear();
    _samples.unbind();
  });

  for (final (size, padding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('LOCK 2 V4 Introductions and Guardian states at $dimensions', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = BaselineHarness(
        tester,
        group: 'line98_introductions_$dimensions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: padding,
        reduceMotion: true,
      );
      await tester.runAsync(() async {
        await ZyraAccountState.synchronize('line98-introductions-capture');
        _samples.bind(
          authorized: () => true,
          capacity: () => 3,
          isSeekerOne: () => true,
          clock: () => DateTime(2026, 11, 19, 12),
        );
        _samples.recordRealCounts(
          ZyraAccountState.userId,
          ZyraAccountState.generation,
          active: 0,
        );
      });
      Future<void> mount({Widget? child, bool guardian = false}) =>
          h.mountPresentation(
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: guardian,
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
              tab: 2,
              pages: const ['introductions'],
            ),
            child: _frame(
              child ??
                  ZyraSampleIntroductionsList(
                    key: UniqueKey(),
                    wrapTitle: (title) => title,
                    tabClearance: true,
                  ),
              guardian: guardian,
            ),
            backdrop: BoxDecoration(gradient: ZyraColors.genderGradient(null)),
          );
      Future<void> capture(String state) async {
        if (_captures.isEmpty) return;
        await h.capture(
          'introductions',
          'line98',
          state,
          state,
          fileName: '${state}_$dimensions.png',
        );
      }

      _samples.setIntroductions(3);
      await mount();
      expect(find.byType(ZyraRequestActivityCard), findsNWidgets(3));
      await capture('introductions__received');
      await h.tap('sample-introduction-draft-noor-header');
      expect(find.text('View profile'), findsOneWidget);
      await capture('introductions__received_open');
      final noor = _samples.introductionRows!.first;
      final hana = _samples.introductionRows![1];
      expect(_samples.requestIntroduction(hana), isTrue);
      expect(_samples.declineIntroduction(noor), isTrue);
      await h.flush();
      await tester.tap(find.text('Past'));
      await h.flush();
      expect(find.text('You declined'), findsOneWidget);
      expect(find.text('Journey requested'), findsOneWidget);
      await capture('introductions__past');
      _samples.setIntroductions(0);
      await tester.tap(find.text('Received'));
      await h.flush();
      expect(find.text('No introductions yet'), findsOneWidget);
      await capture('introductions__received_empty');
      _samples.clear();
      _samples.setIntroductions(0);
      await tester.tap(find.text('Past'));
      await h.flush();
      expect(find.text('No past introductions.'), findsOneWidget);
      await capture('introductions__past_empty');

      _samples.setIntroductions(1);
      _samples.declineIntroduction(_samples.introductionRows!.single);
      await mount(
        guardian: true,
        child: ZyraGuardianTabsPresentation(
          state: ZyraGuardianTabsState(
            const ZyraGuardianTabsSnapshot(introduced: {'adam:aisha'}),
          ),
          page: 'introductions',
          onAction: (_) {},
          photoFor: (id) => _samples
              .profileFor(
                draftProfiles.firstWhere((person) => person.id == 'draft-$id'),
              )
              .photoUrl,
          seekerGender: 'male',
          tabClearance: true,
          introductionDeclined: _samples.hasDeclinedIntroduction,
          madeIntroductions: _samples.guardianIntroductions(
            'draft-guardian-hassan',
          ),
        ),
      );
      expect(find.text('Not taken forward'), findsOneWidget);
      expect(find.text('Suggested to Adam'), findsOneWidget);
      await capture('guardian_introductions_made__not_taken_forward');
      _samples.clear();
      _samples.setEnded(3);
      final expansion = ZyraConnectionsExpansionController();
      addTearDown(expansion.dispose);
      var archiveOpened = false;
      await mount(
        child: ZyraRequestActivityPresentation(
          title: 'Ended Journeys',
          labels: const ['Ended Journeys'],
          selectedIndex: 0,
          onChanged: (_) {},
          tabClearance: true,
          pages: [
            [
              for (final row in _samples.endedRows!)
                ZyraSampleEndedJourneyCard(
                  row: row,
                  controller: expansion,
                  onViewArchive: () => archiveOpened = true,
                ),
            ],
          ],
        ),
      );
      expect(find.text('Zainab Malik'), findsOneWidget);
      await capture('sample_ended_journeys__list');
      final firstId = _samples.endedRows!.first.id;
      await h.tap('sample-ended-$firstId-header');
      expect(find.text('View Timeline'), findsOneWidget);
      await capture('sample_ended_journeys__open');
      await tester.ensureVisible(find.text('View Timeline'));
      await tester.tap(find.text('View Timeline'));
      await h.flush();
      expect(archiveOpened, isTrue);
      await mount(
        child: ZyraSampleEndedJourneyArchive(
          row: _samples.endedRows!.first,
          wrapTitle: (title) => title,
          tabClearance: true,
        ),
      );
      expect(find.text('Journey with Zainab'), findsOneWidget);
      await capture('sample_ended_journeys__view_timeline_read_only');
      expect(tester.takeException(), isNull);
    });
  }
}
