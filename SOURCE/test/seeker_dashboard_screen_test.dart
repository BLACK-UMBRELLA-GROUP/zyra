import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/screens/home/seeker_dashboard_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_profile_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_fade_edges.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';
import 'package:zyra/widgets/zyra_segmented_toggle.dart';

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);

  setUp(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.resetDashboardLab();
    SupportiveDashboardPreview.instance.reset();
    ZyraColors.selectAppSurfaceStyle(ZyraColors.currentDefaultSurfaceStyle);
    AppState.instance.plan = ZyraPlan.one;
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.resetDashboardLab();
    SupportiveDashboardPreview.instance.reset();
    AppState.instance.plan = ZyraPlan.basic;
  });

  DashboardSnapshot snapshot({
    List<DashboardSignal> onboarding = const [],
    List<DashboardSignal> journeySignals = const [],
    List<DashboardSignal> updates = const [],
    List<DashboardSignal> invitations = const [],
    List<DashboardSignal> insights = const [],
    List<DashboardAdvisory> advisories = const [],
    DashboardJourneyKind journeyKind = DashboardJourneyKind.searching,
    DashboardSource<List<DashboardSignal>>? updatesSource,
    DashboardSource<List<DashboardSignal>>? insightsSource,
    DashboardStableState? stableState,
    String? latestCompletedStage,
    String? nextMilestone,
    String? momentum,
  }) => DashboardSnapshot(
    role: DashboardRole.seeker,
    onboarding: DashboardSource.available(onboarding),
    journeys: DashboardSource.available(
      DashboardJourneyState(
        summary: DashboardJourneySummary(
          id: 'journey',
          kind: journeyKind,
          title: journeyKind == DashboardJourneyKind.active
              ? 'You & Adam'
              : 'Ready for introductions',
          detail: journeyKind == DashboardJourneyKind.active
              ? 'Faith & Values · Stage 4 of 8'
              : 'New introductions will appear here.',
          progress: journeyKind == DashboardJourneyKind.active ? 0.5 : null,
          latestCompletedStage: latestCompletedStage,
          nextMilestone: nextMilestone,
          momentum: momentum,
        ),
        signals: journeySignals,
      ),
    ),
    updates: updatesSource ?? DashboardSource.available(updates),
    guardianInvitations: DashboardSource.available(invitations),
    insights: insightsSource ?? DashboardSource.available(insights),
    advisories: DashboardSource.available(advisories),
    stableState:
        stableState ??
        const DashboardStableState(
          family: DashboardSource.available(
            DashboardFamilyStatus(
              kind: DashboardFamilyKind.notConnected,
              title: 'No Guardian connected',
              detail: 'Add a Guardian when you are ready.',
              actionLabel: 'Add Guardian',
            ),
          ),
        ),
  );

  Widget subject({
    int unread = 0,
    DashboardSnapshot? dashboard,
    Future<DashboardSnapshot> Function()? loadDashboard,
    VoidCallback? onConnections,
    VoidCallback? onGuardian,
    VoidCallback? onNotificationsChanged,
    VoidCallback? onResumeOnboarding,
  }) => MaterialApp(
    home: SeekerDashboardScreen(
      unreadCount: unread,
      onOpenConnections: onConnections ?? () {},
      onOpenGuardian: onGuardian ?? () {},
      onNotificationsChanged: onNotificationsChanged,
      onResumeOnboarding: onResumeOnboarding,
      loadDashboard: loadDashboard ?? () async => dashboard ?? snapshot(),
    ),
  );

  testWidgets(
    'production Dashboard uses Quiet Index with real current status',
    (tester) async {
      await tester.pumpWidget(subject(unread: 3));
      await tester.pump();

      expect(find.text('My ZYRA'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('my-zyra-quiet-dashboard')),
        findsOneWidget,
      );
      expect(find.text('No Guardian connected yet'), findsOneWidget);
      expect(find.text('You’re all caught up'), findsNothing);
      expect(find.text('Ready for introductions'), findsNothing);
      expect(
        find.byKey(const ValueKey('dashboard-notifications-utility')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('quiet-index-mark-read')), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(find.text('Notifications'), findsNothing);
      expect(find.text('What Needs You'), findsNothing);
      expect(find.text('Where You Stand'), findsNothing);
    },
  );

  testWidgets('scrolling cards fade cleanly before the floating navigation', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pump();

    final fadeFinder = find.byKey(
      const ValueKey('dashboard-nav-scroll-fade-now'),
    );
    expect(fadeFinder, findsOneWidget);
    final fade = tester.widget<ZyraFadeEdges>(fadeFinder);
    expect(fade.top, 0);
    expect(
      fade.bottom,
      ZyraNavBarMetrics.restingHeight + ZyraNavBarMetrics.bottomInset + 10,
    );
    expect(
      find.descendant(of: fadeFinder, matching: find.byType(ListView)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('my-zyra-insights-tab')));
    await tester.pumpAndSettle();
    final insightsFade = tester.widget<ZyraFadeEdges>(
      find.byKey(const ValueKey('dashboard-nav-scroll-fade-insights')),
    );
    expect(insightsFade.top, 0);
    expect(insightsFade.bottom, fade.bottom);
  });

  testWidgets('a count alone grants no bulk read action or header bell', (
    tester,
  ) async {
    await tester.pumpWidget(subject(unread: 2));
    await tester.pump();

    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Mark all read'), findsNothing);
    expect(
      find.byKey(const ValueKey('dashboard-notifications-utility')),
      findsNothing,
    );
  });

  testWidgets(
    'fixture failures do not offer an inert Retry in the shared renderer',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      SupportiveDashboardPreview.instance.selectScenario(
        SupportivePreviewScenario.failed,
      );
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
            .onRetry,
        isNull,
      );
      expect(find.byKey(const ValueKey('my-zyra-retry')), findsNothing);
    },
  );

  testWidgets('My ZYRA swipes between Now and Insights in both directions', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('No Guardian connected yet'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('my-zyra-pages')),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('my-zyra-insights-empty')),
      findsOneWidget,
    );
    expect(find.text('No Guardian connected yet'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('my-zyra-pages')),
      const Offset(700, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('No Guardian connected yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-zyra-insights-empty')), findsNothing);
  });

  testWidgets('an initial Insights page selects the matching pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraQuietDashboard(
          resolution: const DashboardResolver().resolve(snapshot()),
          firstName: 'Maryam',
          onNavigate: (_) {},
          onRetry: () {},
          selectedTabIndex: 1,
        ),
      ),
    );
    await tester.pump();

    final selector = tester.widget<ZyraSegmentedToggle>(
      find.byType(ZyraSegmentedToggle),
    );
    expect(selector.labels, const ['Now', 'Insights']);
    expect(selector.position, 1);
    expect(
      find.byKey(const ValueKey('my-zyra-insights-empty')),
      findsOneWidget,
    );
  });

  testWidgets('long counts do not acknowledge unidentified unseen rows', (
    tester,
  ) async {
    await tester.pumpWidget(subject(unread: 120));
    await tester.pump();

    expect(find.text('120'), findsNothing);
    expect(find.text('Mark all read'), findsNothing);
    expect(find.text('120 updates are waiting.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actual shown unread notification IDs enable the bulk action', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        dashboard: snapshot(
          updates: const [
            DashboardSignal(
              id: 'update:notification.new_message:00000000-0000-4000-8000-000000009111',
              kind: DashboardSignalKind.meaningfulMovement,
              title: 'A recorded message update',
              isUnread: true,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('A recorded message update'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
    expect(
      tester
          .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
          .onMarkAllNotificationsRead,
      isNotNull,
    );
  });

  testWidgets(
    'a domain event with unread-looking metadata is not a notification ID',
    (tester) async {
      await tester.pumpWidget(
        subject(
          unread: 3,
          dashboard: snapshot(
            updates: const [
              DashboardSignal(
                id: 'update:journey.started:00000000-0000-4000-8000-000000009111',
                kind: DashboardSignalKind.meaningfulMovement,
                title: 'A recorded domain event',
                isUnread: true,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('A recorded domain event'), findsOneWidget);
      expect(find.text('Mark all read'), findsNothing);
    },
  );

  testWidgets('incomplete onboarding is the answer and opens setup', (
    tester,
  ) async {
    var resumes = 0;
    final incomplete = snapshot(
      onboarding: const [
        DashboardSignal(
          id: 'onboarding-profile-gate',
          kind: DashboardSignalKind.blockingGate,
          title: '35 of 175 answers saved',
          detail: 'Journeys remain locked until setup is complete.',
          actionLabel: 'Continue setup',
          target: ZyraDashboardTarget.onboarding,
        ),
      ],
    );
    await tester.pumpWidget(
      subject(dashboard: incomplete, onResumeOnboarding: () => resumes++),
    );
    await tester.pump();

    expect(find.text('35 of 175 answers saved'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('my-zyra-route-onboarding-profile-gate')),
    );
    expect(resumes, 1);
  });

  testWidgets(
    'protected first-use Seeker landing shows unfinished setup without server reads or stale lab content',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
      AppState.instance.name = 'Aaliyah';
      SupportiveDashboardPreview.instance.selectScenario(
        SupportivePreviewScenario.allNow,
      );
      var loads = 0;
      var resumes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SeekerDashboardScreen(
            unreadCount: 0,
            initialOnboardingProgress: const ZyraOnboardingProgress(
              complete: false,
              due: 0,
              missing: 0,
              hasChapter2: false,
              basicProfile: false,
            ),
            onboardingEntryPreview: true,
            onOpenConnections: () {},
            onOpenGuardian: () {},
            onResumeOnboarding: () => resumes++,
            loadDashboard: () async {
              loads++;
              return snapshot();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loads, 0);
      expect(AppState.instance.name, 'Aaliyah');
      expect(find.text('Continue your profile'), findsOneWidget);
      expect(
        find.text(
          'Your profile stays hidden and Journeys remain locked until setup is complete.',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('my-zyra-route-onboarding-profile-gate')),
      );
      expect(resumes, 1);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('seeker_onboarding_preview_denied')),
        findsOneWidget,
      );
      expect(loads, 0);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpAndSettle();
      expect(find.text('Continue your profile'), findsOneWidget);
      expect(loads, 0);
    },
  );

  testWidgets('unlatched first-use preview never falls through to live reads', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SeekerDashboardScreen(
          unreadCount: 0,
          initialOnboardingProgress: const ZyraOnboardingProgress(
            complete: false,
            due: 0,
            missing: 0,
            hasChapter2: false,
            basicProfile: false,
          ),
          onboardingEntryPreview: true,
          onOpenConnections: () {},
          onOpenGuardian: () {},
          loadDashboard: () async {
            loads++;
            return snapshot();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('seeker_onboarding_preview_denied')),
      findsOneWidget,
    );
    expect(loads, 0);
  });

  testWidgets('partial action-source failure never renders a calm day', (
    tester,
  ) async {
    var loads = 0;
    final unavailable = snapshot(
      updatesSource: const DashboardSource.unavailable(
        DashboardFailure(code: 'updates_unavailable'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SeekerDashboardScreen(
          unreadCount: 0,
          onOpenConnections: () {},
          onOpenGuardian: () {},
          loadDashboard: () async {
            loads++;
            return unavailable;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Some information is unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-zyra-quiet')), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('my-zyra-source-gap')),
        matching: find.text('Check again'),
      ),
    );
    await tester.pump();
    expect(loads, 2);
  });

  testWidgets(
    'Quiet Index shows relevant actions and changes without inventory',
    (tester) async {
      final home = snapshot(
        journeyKind: DashboardJourneyKind.active,
        onboarding: const [
          DashboardSignal(
            id: 'complete-profile',
            kind: DashboardSignalKind.blockingGate,
            title: 'Complete your profile',
            actionLabel: 'Continue setup',
            target: ZyraDashboardTarget.onboarding,
          ),
        ],
        updates: const [
          DashboardSignal(
            id: 'recent-movement',
            kind: DashboardSignalKind.meaningfulMovement,
            title: 'Your Journey moved forward',
            target: ZyraDashboardTarget.notifications,
          ),
        ],
        insights: const [
          DashboardSignal(
            id: 'governed-insight',
            kind: DashboardSignalKind.governedInsight,
            title: 'Faith & Values remains a strong area',
            target: ZyraDashboardTarget.preferences,
          ),
        ],
        latestCompletedStage: 'Latest: Compatibility Reveal completed',
        nextMilestone: 'Next: Faith & Values',
        momentum: 'Your Journey moved forward this week.',
        stableState: const DashboardStableState(
          orientationItems: DashboardSource.available([
            DashboardOrientationItem(
              id: 'saved',
              kind: DashboardOrientationKind.saved,
              title: 'Saved',
              valueLabel: '2',
            ),
            DashboardOrientationItem(
              id: 'unread',
              kind: DashboardOrientationKind.unread,
              title: 'New activity',
              valueLabel: '3',
            ),
          ]),
          family: DashboardSource.available(
            DashboardFamilyStatus(
              kind: DashboardFamilyKind.connected,
              title: 'Dad · Guardian connected',
              linkedCount: 1,
            ),
          ),
        ),
      );

      await tester.pumpWidget(subject(dashboard: home, unread: 3));
      await tester.pump();

      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Updates'), findsNothing);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('Your Journey moved forward'), findsOneWidget);
      expect(find.text('What Needs You'), findsNothing);
      expect(find.text('Where You Stand'), findsNothing);
      expect(find.text('What Changed'), findsNothing);
      expect(find.text('YOUR PROGRESS'), findsNothing);
      expect(find.text('2 saved profiles'), findsNothing);
      expect(find.text('Dad · Guardian connected'), findsNothing);
      expect(find.text('You & Adam'), findsNothing);
      expect(find.text('Latest: Compatibility Reveal completed'), findsNothing);
      expect(find.text('Next: Faith & Values'), findsNothing);
      expect(find.text('Your Journey moved forward this week.'), findsNothing);
      final divider = tester.widget<Divider>(
        find.byKey(const ValueKey('quiet-index-group-rule-1')),
      );
      expect(divider.thickness, .7);
      expect(
        find.byKey(const ValueKey('dashboard-view-all-notifications')),
        findsNothing,
      );
      expect(find.textContaining('Since your last visit'), findsNothing);
      expect(find.textContaining('This Week'), findsNothing);

      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      // A resolver summary has no evidence provenance and must not become an
      // account Insight merely because the old view displayed it.
      expect(find.text('Faith & Values remains a strong area'), findsNothing);
      expect(
        find.byKey(const ValueKey('my-zyra-insights-empty')),
        findsOneWidget,
      );
    },
  );

  testWidgets('a real future Guardian invitation expiry opens its owner', (
    tester,
  ) async {
    var guardianRoutes = 0;
    final pending = snapshot(
      stableState: DashboardStableState(
        family: DashboardSource.available(
          DashboardFamilyStatus(
            kind: DashboardFamilyKind.invitationPending,
            title: '2 Guardian invitations pending',
            detail: 'Earliest invitation expires in 2 days.',
            pendingInvitationCount: 2,
            expiresAt: DateTime.now().add(const Duration(days: 2)),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      subject(dashboard: pending, onGuardian: () => guardianRoutes++),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('my-zyra-item-guardian:invitation-expiry')),
      260,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.text('Your Guardian invitation has an expiry date'),
      findsOneWidget,
    );
    expect(find.text('2 Guardian invitations pending'), findsNothing);
    expect(find.text('View invitation'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('View'), findsNothing);
    expect(
      find.byKey(const ValueKey('dashboard-guardian-invitations-seeker')),
      findsNothing,
    );

    await tester.ensureVisible(find.text('View invitation'));
    await tester.pump();
    await tester.tap(find.text('View invitation'));
    expect(guardianRoutes, 1);
  });

  testWidgets(
    'an invitation summary without a real future expiry invents no date',
    (tester) async {
      for (final expiresAt in <DateTime?>[
        null,
        DateTime.now().subtract(const Duration(days: 1)),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          subject(
            dashboard: snapshot(
              stableState: DashboardStableState(
                family: DashboardSource.available(
                  DashboardFamilyStatus(
                    kind: DashboardFamilyKind.invitationPending,
                    title: 'Guardian invitation pending',
                    detail: 'Earliest invitation expires in 2 days.',
                    pendingInvitationCount: 1,
                    expiresAt: expiresAt,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('my-zyra-item-guardian:invitation-expiry')),
          findsNothing,
        );
        expect(
          find.text('Earliest invitation expires in 2 days.'),
          findsNothing,
        );
        expect(find.text('No Guardian connected yet'), findsNothing);
      }
    },
  );

  testWidgets(
    'Guardian-status failure retries without guessing a missing Guardian',
    (tester) async {
      var guardianRoutes = 0;
      var loads = 0;
      final unavailable = snapshot(
        stableState: const DashboardStableState(
          family: DashboardSource.unavailable(
            DashboardFailure(code: 'guardian_status_unavailable'),
          ),
        ),
      );

      await tester.pumpWidget(
        subject(
          loadDashboard: () async {
            loads++;
            return unavailable;
          },
          onGuardian: () => guardianRoutes++,
        ),
      );
      await tester.pump();
      expect(find.text('Some information is unavailable'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
      expect(find.text('No Guardian connected yet'), findsNothing);
      expect(find.byKey(const ValueKey('my-zyra-quiet')), findsNothing);
      await tester.tap(find.text('Check again'));
      await tester.pump();
      expect(loads, 2);
      expect(guardianRoutes, 0);
    },
  );

  testWidgets('Now retains a real missing-Guardian route across tab changes', (
    tester,
  ) async {
    var guardianRoutes = 0;
    await tester.pumpWidget(subject(onGuardian: () => guardianRoutes++));
    await tester.pump();
    expect(find.text('No Guardian connected yet'), findsOneWidget);
    expect(find.text('No meaningful updates yet'), findsNothing);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('my-zyra-insights-empty')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'ZYRA will only show an Insight when reliable information',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Now'));
    await tester.pumpAndSettle();
    expect(find.text('No Guardian connected yet'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('my-zyra-route-guardian:not-connected')),
    );
    expect(guardianRoutes, 1);
  });

  testWidgets('a complete quiet snapshot shows the honest caught-up state', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        dashboard: snapshot(
          stableState: const DashboardStableState(
            family: DashboardSource.available(
              DashboardFamilyStatus(
                kind: DashboardFamilyKind.connected,
                title: 'Guardian connected',
                linkedCount: 1,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('my-zyra-quiet')), findsOneWidget);
    expect(find.text('You’re all caught up'), findsOneWidget);
    expect(
      find.text('Nothing needs your attention right now.'),
      findsOneWidget,
    );
    expect(find.text('Guardian connected'), findsNothing);
    expect(find.byKey(const ValueKey('my-zyra-source-gap')), findsNothing);
  });

  testWidgets('Updates failure never renders the successful empty state', (
    tester,
  ) async {
    const failure = DashboardFailure(code: 'updates_failed');
    final failed = snapshot(
      updatesSource: const DashboardSource.unavailable(failure),
    );

    await tester.pumpWidget(subject(dashboard: failed));
    await tester.pump();
    expect(find.byKey(const ValueKey('my-zyra-source-gap')), findsOneWidget);
    expect(find.text('Some information is unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-zyra-quiet')), findsNothing);
    expect(find.text('You’re all caught up'), findsNothing);
    expect(find.text('No meaningful updates yet'), findsNothing);
  });

  testWidgets('failed refresh visibly retains the last-known Updates rows', (
    tester,
  ) async {
    var calls = 0;
    final available = snapshot(
      updates: const [
        DashboardSignal(
          id: 'update:notification:last-known',
          kind: DashboardSignalKind.meaningfulMovement,
          title: 'A Journey update is waiting',
          target: ZyraDashboardTarget.notifications,
          isUnread: true,
        ),
      ],
    );
    final unavailable = snapshot(
      updatesSource: const DashboardSource.unavailable(
        DashboardFailure(code: 'updates_unavailable'),
      ),
    );

    await tester.pumpWidget(
      subject(
        loadDashboard: () async => calls++ == 0 ? available : unavailable,
      ),
    );
    await tester.pump();
    expect(find.text('A Journey update is waiting'), findsOneWidget);
    final refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator).first)
        .show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await refresh;
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const ValueKey('my-zyra-last-known')), findsOneWidget);
    expect(find.text('Last known · refresh needed'), findsOneWidget);
    expect(find.text('Last known · not current'), findsOneWidget);
    expect(find.text('A Journey update is waiting'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-zyra-quiet')), findsNothing);
    expect(find.text('No meaningful updates yet'), findsNothing);
  });

  testWidgets('only TRUE unread rows receive an unread affordance', (
    tester,
  ) async {
    final dashboard = snapshot(
      updates: const [
        DashboardSignal(
          id: 'update:notification:true',
          kind: DashboardSignalKind.meaningfulMovement,
          title: 'Unread notification',
          target: ZyraDashboardTarget.notifications,
          isUnread: true,
        ),
        DashboardSignal(
          id: 'update:notification:false',
          kind: DashboardSignalKind.meaningfulMovement,
          title: 'Read notification',
          target: ZyraDashboardTarget.notifications,
          isUnread: false,
        ),
        DashboardSignal(
          id: 'update:domain:null',
          kind: DashboardSignalKind.meaningfulMovement,
          title: 'Domain milestone',
          target: ZyraDashboardTarget.connectionsJourneys,
        ),
      ],
    );

    await tester.pumpWidget(subject(dashboard: dashboard));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('my-zyra-item-update:notification:true')),
        matching: find.text('Unread'),
      ),
      findsOneWidget,
    );
    for (final id in ['update:notification:false', 'update:domain:null']) {
      final card = find.byKey(ValueKey('my-zyra-item-$id'));
      await tester.scrollUntilVisible(
        card,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('Unread')),
        findsNothing,
      );
    }
  });

  testWidgets('Insights failure never renders the honest-empty state', (
    tester,
  ) async {
    const failure = DashboardFailure(code: 'insights_failed');
    final failed = snapshot(
      insightsSource: const DashboardSource.unavailable(failure),
    );

    await tester.pumpWidget(subject(dashboard: failed));
    await tester.pump();
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Insights could not be refreshed'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-zyra-insights-empty')), findsNothing);
  });

  testWidgets(
    'unentitled Insights stays visible with a lock and upgrade route',
    (tester) async {
      AppState.instance.plan = ZyraPlan.basic;
      await tester.pumpWidget(
        subject(
          dashboard: snapshot(
            insights: const [
              DashboardSignal(
                id: 'private-insight',
                kind: DashboardSignalKind.governedInsight,
                title: 'Restricted insight content',
                target: ZyraDashboardTarget.none,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();

      expect(find.text('Insights are part of Seeker One'), findsOneWidget);
      expect(find.text('Restricted insight content'), findsNothing);
      expect(
        find.byKey(const ValueKey('seeker-insights-content-lock')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('segmented-Insights-lock')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('seeker-insights-upgrade')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('quiet-index-insights-locked')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my-zyra-insights-empty')),
        findsNothing,
      );
    },
  );

  testWidgets('a calm advisory does not become personalised account content', (
    tester,
  ) async {
    var preferenceReviews = 0;
    final calm = snapshot(
      advisories: const [
        DashboardAdvisory(
          id: 'review-preferences',
          title: 'Review your preferences',
          detail: 'A quick review can keep your search focused.',
          why: 'Your profile is complete and no Journey is active.',
          actionLabel: 'Review',
          target: ZyraDashboardTarget.preferences,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SeekerDashboardScreen(
          unreadCount: 0,
          onOpenConnections: () {},
          onOpenGuardian: () {},
          onReviewPreferences: () => preferenceReviews++,
          loadDashboard: () async => calm,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Review your preferences'), findsNothing);
    expect(
      find.text('Why: Your profile is complete and no Journey is active.'),
      findsNothing,
    );
    expect(preferenceReviews, 0);
  });

  testWidgets(
    'legacy Dashboard Lab state cannot bypass the blank developer default',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDevScenario.instance.setDashboardLabEnabled(true);
      await tester.pumpWidget(subject(unread: 3));
      await tester.pump(const Duration(milliseconds: 650));

      expect(
        find.byKey(const ValueKey('seeker-dashboard-dev-preview')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('seeker-production-dashboard')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
            .blankUntilDeveloperSelection,
        isTrue,
      );
      expect(find.text('No Guardian connected yet'), findsNothing);

      ZyraDevScenario.instance.setDashboardLabEnabled(false);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('seeker-dashboard-dev-preview')),
        findsNothing,
      );
      expect(
        tester
            .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
            .blankUntilDeveloperSelection,
        isTrue,
      );

      SupportiveDashboardPreview.instance.selectScenario(
        SupportivePreviewScenario.noGuardian,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
            .blankUntilDeveloperSelection,
        isFalse,
      );
      expect(find.text('No Guardian connected yet'), findsOneWidget);
    },
  );

  for (final surface in ZyraAppSurfaceStyle.values) {
    testWidgets(
      'production Dashboard fits compact large-text viewport with ${surface.name}',
      (tester) async {
        ZyraColors.selectAppSurfaceStyle(surface);
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final busy = snapshot(
          journeyKind: DashboardJourneyKind.active,
          onboarding: const [
            DashboardSignal(
              id: 'setup',
              kind: DashboardSignalKind.blockingGate,
              title: 'Complete your profile',
              detail: 'A few answers are still needed before a Journey.',
              actionLabel: 'Continue setup',
              target: ZyraDashboardTarget.onboarding,
            ),
          ],
          journeySignals: const [
            DashboardSignal(
              id: 'journey-choice',
              kind: DashboardSignalKind.ownJourneyMove,
              title: 'Your Journey is ready for you',
              detail: 'Review the latest stage before moving forward.',
              actionLabel: 'Open Journey',
              target: ZyraDashboardTarget.connectionsJourneys,
            ),
          ],
          invitations: const [
            DashboardSignal(
              id: 'guardian-invite',
              kind: DashboardSignalKind.addressedDecision,
              title: 'Guardian invitation waiting',
              detail: 'Review the invitation when you are ready.',
              actionLabel: 'Review',
              target: ZyraDashboardTarget.guardian,
            ),
          ],
          updates: const [
            DashboardSignal(
              id: 'movement',
              kind: DashboardSignalKind.meaningfulMovement,
              title: 'Something changed in your Journey',
              detail: 'Review the recorded update here in Now.',
              actionLabel: 'View update',
              target: ZyraDashboardTarget.notifications,
            ),
          ],
          insights: const [
            DashboardSignal(
              id: 'insight',
              kind: DashboardSignalKind.governedInsight,
              title: 'A positive pattern is forming',
              detail: 'Faith and Values has aligned consistently.',
              target: ZyraDashboardTarget.preferences,
            ),
          ],
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: subject(dashboard: busy, unread: 120),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        final list = find.byType(ListView);
        for (var index = 0; index < 4; index++) {
          await tester.drag(list, const Offset(0, -250));
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow after compact scroll $index',
          );
        }
      },
    );
  }
}
