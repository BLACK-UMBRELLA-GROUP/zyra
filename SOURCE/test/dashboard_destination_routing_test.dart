import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/screens/connections/connections_section_controller.dart';
import 'package:zyra/screens/home/seeker_dashboard_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance
      ..resetDashboardLab()
      ..setUseLiveGuardianData(false);
    ZyraColors.selectAppSurfaceStyle(ZyraAppSurfaceStyle.glassSignals);
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.resetDashboardLab();
  });

  Widget seekerDashboard({
    required VoidCallback onJourneys,
    required VoidCallback onActivity,
    required VoidCallback onNotifications,
    required DashboardSnapshot snapshot,
  }) => MaterialApp(
    home: SeekerDashboardScreen(
      unreadCount: 2,
      onOpenConnections: onJourneys,
      onOpenConnectionsActivity: onActivity,
      onOpenGuardian: () {},
      onNotificationsChanged: onNotifications,
      onOpenDiscovery: () {},
      onOpenProfile: () {},
      onReviewPreferences: () {},
      onResumeOnboarding: () {},
      loadDashboard: () async => snapshot,
    ),
  );

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'confirmed Journey change opens Connections Journeys after explicit disclosure',
    (tester) async {
      final section = ZyraConnectionsSectionController(
        initialSection: ZyraConnectionsSection.introductions,
      );
      var notifications = 0;
      var activity = 0;

      // Exercise the ordinary account route. A developer fixture must never
      // open a live Journey, so it cannot prove production destination routing.
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      final snapshot = DashboardSnapshot(
        role: DashboardRole.seeker,
        onboarding: const DashboardSource.available([]),
        journeys: const DashboardSource.available(
          DashboardJourneyState(
            summary: DashboardJourneySummary(
              id: 'journey-active',
              kind: DashboardJourneyKind.active,
              title: 'You & Adam',
            ),
          ),
        ),
        updates: DashboardSource.available([
          DashboardSignal(
            id: 'update:journey.timeline_milestone:resumed',
            kind: DashboardSignalKind.meaningfulMovement,
            title: 'Your Journey with Adam has resumed',
            detail: 'The Journey continued.',
            actionLabel: 'Open Journey',
            target: ZyraDashboardTarget.connectionsJourneys,
            eventAt: DateTime.utc(2026, 9, 16, 12),
          ),
        ]),
        guardianInvitations: const DashboardSource.available([]),
        insights: const DashboardSource.available([]),
        stableState: const DashboardStableState(
          family: DashboardSource.available(
            DashboardFamilyStatus(
              kind: DashboardFamilyKind.connected,
              title: 'Guardian connected',
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        seekerDashboard(
          onJourneys: () => section.open(ZyraConnectionsSection.journeys),
          onActivity: () {
            activity++;
            section.open(ZyraConnectionsSection.activity);
          },
          onNotifications: () => notifications++,
          snapshot: snapshot,
        ),
      );
      await tester.pump(const Duration(milliseconds: 650));
      await openTab(tester, 'Now');

      expect(find.text('Your Journey with Adam has resumed'), findsOneWidget);
      expect(
        section.section,
        ZyraConnectionsSection.introductions,
        reason: 'The regression starts from a retained non-Journeys section.',
      );

      const changeId = 'update:journey.timeline_milestone:resumed';
      final disclosure = find.byKey(
        const ValueKey('quiet-index-disclosure-$changeId'),
      );
      final route = find.byKey(const ValueKey('my-zyra-route-$changeId'));
      expect(route, findsNothing);
      await tester.ensureVisible(disclosure);
      await tester.tap(disclosure);
      await tester.pump();
      expect(section.section, ZyraConnectionsSection.introductions);
      expect(notifications, 0, reason: 'Reading details must not mark read.');
      expect(route, findsOneWidget);
      await tester.ensureVisible(route);
      await tester.tap(route);
      await tester.pump();

      expect(section.section, ZyraConnectionsSection.journeys);
      expect(activity, 0);
      expect(notifications, 0);
    },
  );

  test('Connections section controller preserves explicit shell intent', () {
    final controller = ZyraConnectionsSectionController(
      initialSection: ZyraConnectionsSection.introductions,
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.open(ZyraConnectionsSection.journeys);
    expect(controller.section, ZyraConnectionsSection.journeys);
    expect(notifications, 1);

    controller.open(ZyraConnectionsSection.journeys);
    expect(
      notifications,
      2,
      reason: 'A same-section deep link must still restore the visible pager.',
    );

    controller.synchroniseFromPage(ZyraConnectionsSection.activity);
    expect(controller.section, ZyraConnectionsSection.activity);
    expect(
      notifications,
      2,
      reason: 'A user swipe records state without animating the pager again.',
    );

    final beforeCollapse = controller.collapseRevision;
    controller.collapseCards();
    expect(controller.collapseRevision, beforeCollapse + 1);
    expect(
      notifications,
      3,
      reason: 'Leaving Connections must notify the kept-alive page to retract.',
    );
  });

  test('Connections page numbers map to stable named destinations', () {
    expect(ZyraConnectionsSection.values.map((section) => section.page), [
      0,
      1,
      2,
    ]);
    expect(ZyraConnectionsSection.fromPage(0), ZyraConnectionsSection.journeys);
    expect(ZyraConnectionsSection.fromPage(1), ZyraConnectionsSection.activity);
    expect(
      ZyraConnectionsSection.fromPage(2),
      ZyraConnectionsSection.introductions,
    );
    expect(
      ZyraConnectionsSection.fromPage(99),
      ZyraConnectionsSection.journeys,
    );
  });
}
