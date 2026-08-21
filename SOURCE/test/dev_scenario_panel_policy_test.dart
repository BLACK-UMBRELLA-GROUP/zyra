import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/auth_gate.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/state/app_state.dart';

const _realProfile = SeekerProfile(
  id: 'real-profile',
  firstName: 'Arif',
  age: 36,
  city: 'Derby',
  photos: ['https://example.invalid/arif.jpg'],
  gender: 'male',
);

const _realActive = JourneyMatch(
  matchId: 'real-match',
  profile: _realProfile,
  status: 'active',
  journeyStage: 'salam_exchange',
);

void main() {
  final scenario = ZyraDevScenario.instance;

  setUp(scenario.reset);
  tearDown(scenario.reset);

  test('zero preview counts never hide a real Journey', () {
    final rows = ZyraDevScenario.composeJourneys(
      viewerGender: 'female',
      currentUserId: 'me',
      viewerPlan: ZyraPlan.basic,
      realActive: const [_realActive],
    );

    expect(rows, contains(same(_realActive)));
    expect(rows.where((row) => row.isMock), isEmpty);
  });

  test('preview counts add cards without replacing real account truth', () {
    scenario.setQueuedJourneys(1);

    final rows = ZyraDevScenario.composeJourneys(
      viewerGender: 'female',
      currentUserId: 'me',
      viewerPlan: ZyraPlan.basic,
      realActive: const [_realActive],
      realPotential: const [
        JourneyMatch(
          matchId: 'real-potential',
          profile: _realProfile,
          status: 'potential',
        ),
      ],
    );

    expect(rows.where((row) => !row.isMock), hasLength(2));
    expect(rows.where((row) => row.isMock), hasLength(1));
  });

  test('clean panel migration removes invisible legacy switches', () {
    scenario.setActiveJourneys(1);
    scenario.setBusyPotential(2);
    scenario.setBusyPaused(2);
    scenario.setBusyEnded(2);
    scenario.setAdsOnEveryProfile(true);

    scenario.migrateToCleanSeekerPanel();

    expect(scenario.activeJourneys, 0);
    expect(scenario.busyPotential, 0);
    expect(scenario.busyPaused, 0);
    expect(scenario.busyEnded, 0);
    expect(scenario.adsOnEveryProfile, isFalse);
  });

  test('one pause ownership choice cannot create contradictory controls', () {
    scenario.setPausePreviewOwner(2);
    expect(scenario.pausedJourneys, 1);
    expect(scenario.pausePreviewOwner, 2);
    expect(scenario.pausedByYou, 0);
    expect(scenario.mirroredPaused, 1);

    scenario.setPausePreviewOwner(1);
    expect(scenario.pausePreviewOwner, 1);
    expect(scenario.pausedByYou, 1);
    expect(scenario.mirroredPaused, 0);
  });

  testWidgets('toggle exposes Home, sign-up and all error previews', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: [DevScenarioPanelV2(onOpenPage: (_) {})]),
        ),
      ),
    );

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('Open Home'), findsOneWidget);
    expect(find.text('SIGN UP'), findsOneWidget);
    expect(find.text('Sign Up — Seeker'), findsOneWidget);
    expect(find.text('Sign Up — Guardian'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    final panelList = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('ERROR PAGES'),
      220,
      scrollable: panelList,
    );
    expect(find.text('ERROR PAGES'), findsOneWidget);
    expect(find.text('Page error'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('ZYRA unavailable'), findsOneWidget);
    expect(find.text('Session expired'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open Home'),
      -220,
      scrollable: panelList,
    );
    final homeAction = find
        .ancestor(of: find.text('Open Home'), matching: find.byType(InkWell))
        .hitTestable();
    expect(homeAction, findsOneWidget);
    tester.widget<InkWell>(homeAction).onTap!();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AuthGate, skipOffstage: false), findsOneWidget);
    expect(find.byType(SplashScreen, skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
