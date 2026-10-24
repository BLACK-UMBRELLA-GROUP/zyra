import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/screens/home/seeker_dashboard_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);
  setUp(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));

  DashboardSnapshot withSignals(
    List<DashboardSignal> signals, {
    DashboardJourneyKind kind = DashboardJourneyKind.active,
  }) => DashboardSnapshot(
    role: DashboardRole.seeker,
    onboarding: DashboardSource.available(signals),
    journeys: DashboardSource.available(
      DashboardJourneyState(
        summary: DashboardJourneySummary(
          id: 'journey',
          kind: kind,
          title: kind == DashboardJourneyKind.searching
              ? 'Ready for introductions'
              : kind == DashboardJourneyKind.paused
              ? 'Your Journey with Adam is paused'
              : 'You & Adam',
          detail: 'Current server state',
        ),
      ),
    ),
    updates: const DashboardSource.available(<DashboardSignal>[]),
    guardianInvitations: const DashboardSource.available(<DashboardSignal>[]),
    insights: const DashboardSource.available(<DashboardSignal>[]),
    stableState: const DashboardStableState(
      family: DashboardSource.available(
        DashboardFamilyStatus(
          kind: DashboardFamilyKind.connected,
          title: 'Guardian connected',
        ),
      ),
    ),
  );

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('my-zyra-quiet-scroll-0')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
  }

  final routeCases = <({String name, ZyraDashboardTarget target})>[
    (name: 'Discovery', target: ZyraDashboardTarget.discovery),
    (name: 'Journeys', target: ZyraDashboardTarget.connectionsJourneys),
    (
      name: 'Connections activity',
      target: ZyraDashboardTarget.connectionsActivity,
    ),
    (name: 'Guardian', target: ZyraDashboardTarget.guardian),
    (name: 'Profile', target: ZyraDashboardTarget.profile),
    (name: 'Preferences', target: ZyraDashboardTarget.preferences),
    (name: 'Onboarding', target: ZyraDashboardTarget.onboarding),
  ];

  for (final routeCase in routeCases) {
    testWidgets(
      '${routeCase.name} signal opens only its intended destination',
      (tester) async {
        final counts = {
          for (final target in ZyraDashboardTarget.values) target: 0,
        };
        final signal = DashboardSignal(
          id: 'route-${routeCase.target.name}',
          kind: DashboardSignalKind.blockingGate,
          title: 'Route ${routeCase.name}',
          actionLabel: 'Open',
          target: routeCase.target,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SeekerDashboardScreen(
              unreadCount: 0,
              onOpenDiscovery: () => counts[ZyraDashboardTarget.discovery] = 1,
              onOpenConnections: () =>
                  counts[ZyraDashboardTarget.connectionsJourneys] = 1,
              onOpenConnectionsActivity: () =>
                  counts[ZyraDashboardTarget.connectionsActivity] = 1,
              onOpenGuardian: () => counts[ZyraDashboardTarget.guardian] = 1,
              onOpenProfile: () => counts[ZyraDashboardTarget.profile] = 1,
              onReviewPreferences: () =>
                  counts[ZyraDashboardTarget.preferences] = 1,
              onResumeOnboarding: () =>
                  counts[ZyraDashboardTarget.onboarding] = 1,
              loadDashboard: () async => withSignals([signal]),
            ),
          ),
        );
        await tester.pump();

        final route = find.byKey(ValueKey('my-zyra-route-${signal.id}'));
        await reveal(tester, route);
        await tester.tap(route);
        expect(counts[routeCase.target], 1);
        expect(
          counts.entries
              .where((entry) => entry.key != routeCase.target)
              .fold<int>(0, (sum, entry) => sum + entry.value),
          0,
        );
      },
    );
  }

  for (final kind in const [
    DashboardJourneyKind.searching,
    DashboardJourneyKind.potential,
    DashboardJourneyKind.active,
    DashboardJourneyKind.ended,
  ]) {
    testWidgets(
      '$kind passive summary does not invent a permanent route card',
      (tester) async {
        var discovery = 0;
        var journeys = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: SeekerDashboardScreen(
              unreadCount: 0,
              onOpenDiscovery: () => discovery++,
              onOpenConnections: () => journeys++,
              onOpenGuardian: () {},
              loadDashboard: () async => withSignals(const [], kind: kind),
            ),
          ),
        );
        await tester.pump();

        // The selected Quiet Index lists eligible obligations, stable notices
        // and changes. Passive inventory remains on its canonical owner page.
        expect(
          find.byKey(const ValueKey('my-zyra-quiet-dashboard')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('my-zyra-route-journey')),
          findsNothing,
        );
        expect(find.text('You’re all caught up'), findsOneWidget);
        expect(journeys, 0);
        expect(discovery, 0);
      },
    );
  }

  testWidgets('paused Journey notice routes to Connections Journeys', (
    tester,
  ) async {
    var discovery = 0;
    var journeys = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SeekerDashboardScreen(
          unreadCount: 0,
          onOpenDiscovery: () => discovery++,
          onOpenConnections: () => journeys++,
          onOpenGuardian: () {},
          loadDashboard: () async =>
              withSignals(const [], kind: DashboardJourneyKind.paused),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Your Journey with Adam is paused'), findsOneWidget);
    final route = find.byKey(const ValueKey('my-zyra-route-journey'));
    await reveal(tester, route);
    await tester.tap(route);
    expect(journeys, 1);
    expect(discovery, 0);
  });

  for (final target in [
    ZyraDashboardTarget.none,
    ZyraDashboardTarget.notifications,
  ]) {
    testWidgets('$target cannot acquire a fabricated owner route', (
      tester,
    ) async {
      var navigationCalls = 0;
      final signal = DashboardSignal(
        id: 'non-route-${target.name}',
        kind: DashboardSignalKind.blockingGate,
        title: 'No supported destination',
        actionLabel: 'Open',
        target: target,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SeekerDashboardScreen(
            unreadCount: 0,
            onOpenConnections: () => navigationCalls++,
            onOpenGuardian: () => navigationCalls++,
            onOpenDiscovery: () => navigationCalls++,
            onOpenProfile: () => navigationCalls++,
            loadDashboard: () async => withSignals([signal]),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(ValueKey('my-zyra-route-${signal.id}')), findsNothing);
      expect(navigationCalls, 0);
    });
  }

  testWidgets('secondary obligations are retained behind explicit disclosure', (
    tester,
  ) async {
    final actions = List.generate(
      4,
      (index) => DashboardSignal(
        id: 'action-$index',
        kind: DashboardSignalKind.addressedDecision,
        title: 'Action $index',
        actionLabel: 'Review',
        target: ZyraDashboardTarget.connectionsJourneys,
        eventAt: DateTime.utc(2026, 1, index + 1),
      ),
    );
    var journeys = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SeekerDashboardScreen(
          unreadCount: 0,
          onOpenConnections: () => journeys++,
          onOpenGuardian: () {},
          loadDashboard: () async => withSignals(actions),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Action 0'), findsOneWidget);
    final disclosure = find.byKey(const ValueKey('my-zyra-more-actions'));
    await reveal(tester, disclosure);
    expect(find.text('Action 1'), findsOneWidget);
    expect(find.text('Action 2'), findsOneWidget);
    expect(find.text('Action 3'), findsNothing);
    expect(find.text('1 more to review'), findsOneWidget);
    await tester.tap(disclosure);
    await tester.pump();
    expect(find.text('Action 3'), findsOneWidget);
    expect(journeys, 0, reason: 'Disclosure is not navigation.');
    final route = find.byKey(const ValueKey('my-zyra-route-action-3'));
    await reveal(tester, route);
    await tester.tap(route);
    expect(journeys, 1);
  });
}
