import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';
import 'package:zyra/widgets/zyra_segmented_toggle.dart';

const _retiredSources = <String>[
  'lib/dev/zyra_my_zyra_designs.dart',
  'lib/dev/zyra_my_zyra_editorial_designs.dart',
  'lib/dev/zyra_my_zyra_spatial_designs.dart',
  'lib/dev/zyra_my_zyra_design_kit.dart',
  'lib/widgets/zyra_supportive_dashboard.dart',
  'lib/widgets/zyra_resolved_dashboard.dart',
  'lib/widgets/zyra_dashboard_experience.dart',
  'lib/dev/zyra_dashboard_dev_adapter.dart',
];

DashboardResolution _resolution() => const DashboardResolver().resolve(
  const DashboardSnapshot(
    role: DashboardRole.seeker,
    onboarding: DashboardSource.available([
      DashboardSignal(
        id: 'setup-owner',
        kind: DashboardSignalKind.blockingGate,
        title: 'Continue your profile setup',
        actionLabel: 'View account setup',
        target: ZyraDashboardTarget.onboarding,
      ),
    ]),
    journeys: DashboardSource.available(
      DashboardJourneyState(
        summary: DashboardJourneySummary(
          id: 'searching',
          kind: DashboardJourneyKind.searching,
          title: 'Ready for introductions',
        ),
      ),
    ),
    updates: DashboardSource.available([]),
    guardianInvitations: DashboardSource.available([]),
    insights: DashboardSource.available([]),
    stableState: DashboardStableState(
      family: DashboardSource.available(
        DashboardFamilyStatus(
          kind: DashboardFamilyKind.connected,
          title: 'Guardian connected',
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    SupportiveDashboardPreview.instance.reset();
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    SupportiveDashboardPreview.instance.reset();
  });

  test(
    'retired renderers and design-only fixtures are outside active source',
    () {
      for (final path in [
        ..._retiredSources,
        'test/zyra_my_zyra_designs_test.dart',
        'test/visual/zyra_my_zyra_designs_visual_test.dart',
        'test/visual/zyra_supportive_dashboard_visual_test.dart',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }
    },
  );

  test('live dashboard consumers have no retired selector or import', () {
    expect(
      File('lib/dev/zyra_dashboard_lab_controls.dart').existsSync(),
      isFalse,
    );
    for (final path in [
      'lib/screens/home/seeker_dashboard_screen.dart',
      'lib/dev/zyra_supportive_dashboard_preview.dart',
    ]) {
      final source = File(path).readAsStringSync();
      for (final retired in [
        'MyZyraDesign',
        'selectDesign',
        'SupportiveDashboardControls',
        'ZyraMyZyraDesignDashboard',
        'zyra_my_zyra_designs.dart',
        'Personal Briefing',
        'Focus + Timeline',
        'Compact Bento',
      ]) {
        expect(source, isNot(contains(retired)), reason: '$path: $retired');
      }
    }
  });

  test(
    'current single-page and ordinary member dashboards share one renderer',
    () {
      final shell = File(
        'lib/dev/zyra_one_journey_concept_shell.dart',
      ).readAsStringSync();
      final ordinary = File(
        'lib/screens/home/seeker_dashboard_screen.dart',
      ).readAsStringSync();
      expect(shell, contains('return ZyraQuietDashboard('));
      expect(shell, contains('singlePage: true'));
      expect(ordinary, contains('child: ZyraQuietDashboard('));
      for (final path in [
        'lib/widgets/zyra_quiet_dashboard.dart',
        'lib/widgets/zyra_my_zyra_design_kit.dart',
        'lib/models/zyra_supportive_dashboard.dart',
        'lib/models/zyra_dashboard_resolution.dart',
        'lib/services/zyra_dashboard_adapter.dart',
        'lib/services/zyra_dashboard_updates_service.dart',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    },
  );

  test(
    'retirement does not delete ordinary auth or role-owned home routes',
    () {
      final auth = File('lib/screens/auth_gate.dart').readAsStringSync();
      final router = File(
        'lib/services/zyra_session_router.dart',
      ).readAsStringSync();
      expect(auth, contains('ZyraSessionRouter.resolveHome()'));
      expect(
        router,
        contains("if (role == 'wali') return const WaliHomeShell();"),
      );
      expect(router, contains('return HomeShell(initialTab: 2'));
      expect(router, contains('authorization.founderAuthorized'));
      expect(router, contains('return ZyraFounderLaunchScreen('));
      expect(
        File('lib/services/zyra_journey_service.dart').existsSync(),
        isTrue,
      );
    },
  );

  test(
    'retained scenario admission still denies release and unauthorized use',
    () {
      for (final release in [true, false]) {
        for (final authorized in [true, false]) {
          expect(
            supportivePreviewAllowed(
              isRelease: release,
              developerAuthorized: authorized,
            ),
            !release && authorized,
          );
        }
      }
    },
  );

  testWidgets('current single-page renderer keeps the source owner action', (
    tester,
  ) async {
    final opened = <SupportiveCard>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraQuietDashboard(
          resolution: _resolution(),
          singlePage: true,
          comparisonClock: DateTime.utc(2026, 10, 11),
          onNavigate: opened.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My ZYRA'), findsOneWidget);
    expect(find.text('Continue your profile setup'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(ZyraSegmentedToggle), findsNothing);
    final route = find.byKey(const ValueKey('my-zyra-route-setup-owner'));
    await tester.ensureVisible(route);
    await tester.tap(route);
    expect(opened.single.id, 'setup-owner');
    expect(opened.single.target, ZyraDashboardTarget.onboarding);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'revocation retracts the retained local fixture and its callback',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ZyraQuietDashboard(
            resolution: _resolution(),
            fixtureMode: true,
            singlePage: true,
            onNavigate: (_) => opened++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final route = find.byKey(const ValueKey('my-zyra-route-setup-owner'));
      final stale = tester.widget<TextButton>(route).onPressed!;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      stale();
      expect(opened, 0);
      expect(find.text('Continue your profile setup'), findsNothing);
      expect(
        find.byKey(const ValueKey('quiet-index-fixture-denied')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
