import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/link_guardian_panel.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_guardian_invitation_dashboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = true;
    ZyraColors.restoreAppSurfaceStyle(null);
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = false;
  });

  Widget subject(
    ZyraGuardianInvitationAudience audience, {
    double textScale = 1,
    GuardianPendingInvitesLoader? pendingInvitesLoader,
    ZyraGuardianInvitationSurface surface =
        ZyraGuardianInvitationSurface.dashboard,
    DateTime? comparisonNow,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ZyraGuardianInvitationDashboard(
              audience: audience,
              surface: surface,
              comparisonNow: comparisonNow,
              pendingInvitesLoader: pendingInvitesLoader,
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('no-invitation state collapses the Dashboard module', (
    tester,
  ) async {
    await tester.pumpWidget(subject(ZyraGuardianInvitationAudience.seeker));
    await tester.pump();

    expect(find.text('GUARDIAN INVITATIONS'), findsNothing);
    expect(find.text('Have a Guardian invite code?'), findsNothing);
    expect(
      find.byKey(const ValueKey('dashboard-guardian-invitations-seeker-empty')),
      findsOneWidget,
    );
    expect(find.textContaining('invited you'), findsNothing);
    expect(find.textContaining('Awaiting response'), findsNothing);
  });

  testWidgets('live successful empty stays distinct from unavailable', (
    tester,
  ) async {
    ZyraDevScenario.instance.setUseLiveGuardianData(true);
    await tester.pumpWidget(
      subject(
        ZyraGuardianInvitationAudience.seeker,
        pendingInvitesLoader: () async =>
            const ZyraSourceResult.available(<PendingInvite>[]),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard-guardian-invitations-seeker-empty')),
      findsOneWidget,
    );
    expect(
      find.text('Guardian invitations could not be refreshed.'),
      findsNothing,
    );
  });

  testWidgets('live unavailable state offers Retry instead of false empty', (
    tester,
  ) async {
    ZyraDevScenario.instance.setUseLiveGuardianData(true);
    var calls = 0;
    await tester.pumpWidget(
      subject(
        ZyraGuardianInvitationAudience.seeker,
        pendingInvitesLoader: () async {
          calls += 1;
          if (calls == 1) {
            return const ZyraSourceResult.unavailable(
              ZyraSourceFailure.requestFailed,
            );
          }
          return const ZyraSourceResult.available(<PendingInvite>[]);
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Guardian invitations could not be refreshed.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-guardian-invitations-seeker-empty')),
      findsNothing,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(
      find.text('Guardian invitations could not be refreshed.'),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dashboard-guardian-invitations-seeker-empty')),
      findsOneWidget,
    );
  });

  testWidgets('failed refresh preserves last-known pending invitation', (
    tester,
  ) async {
    ZyraDevScenario.instance.setUseLiveGuardianData(true);
    final invite = PendingInvite(
      token: 'LIVE1234',
      label: 'Dad',
      createdAt: DateTime(2026, 8, 28),
    );
    var calls = 0;
    await tester.pumpWidget(
      subject(
        ZyraGuardianInvitationAudience.seeker,
        pendingInvitesLoader: () async {
          calls += 1;
          if (calls == 1) return ZyraSourceResult.available([invite]);
          if (calls == 2) {
            return const ZyraSourceResult.unavailable(
              ZyraSourceFailure.requestFailed,
            );
          }
          return const ZyraSourceResult.available(<PendingInvite>[]);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dad'), findsOneWidget);

    ZyraWaliLinkService.invitationRevision.value += 1;
    await tester.pumpAndSettle();

    expect(find.text('Dad'), findsOneWidget);
    expect(
      find.text('Guardian invitations could not be refreshed.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(calls, 3);
    expect(find.text('Dad'), findsNothing);
    expect(
      find.byKey(const ValueKey('dashboard-guardian-invitations-seeker-empty')),
      findsOneWidget,
    );
  });

  testWidgets('received preview can be reviewed and accepted', (tester) async {
    ZyraDevScenario.instance.setReceivedInvites(1);
    await tester.pumpWidget(subject(ZyraGuardianInvitationAudience.seeker));
    await tester.pump();

    expect(find.text('Abdul invited you'), findsOneWidget);
    expect(find.textContaining('Father · Today · Preview'), findsOneWidget);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('wants to be your Guardian'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(ZyraDevScenario.instance.receivedInviteCount, 0);
    expect(find.text('Abdul invited you'), findsNothing);
  });

  testWidgets('received preview can be declined', (tester) async {
    ZyraDevScenario.instance.setReceivedInvites(1);
    await tester.pumpWidget(subject(ZyraGuardianInvitationAudience.seeker));
    await tester.pump();

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline invitation'));
    await tester.pumpAndSettle();

    expect(ZyraDevScenario.instance.receivedInviteCount, 0);
    expect(find.text('Abdul invited you'), findsNothing);
  });

  testWidgets('Seeker manager owns pending invitation cancellation', (
    tester,
  ) async {
    ZyraDevScenario.instance.setPendingInvites(1);
    await tester.pumpWidget(
      subject(
        ZyraGuardianInvitationAudience.seeker,
        surface: ZyraGuardianInvitationSurface.manager,
      ),
    );
    await tester.pump();

    expect(find.textContaining('Awaiting response'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel invitation'));
    await tester.pumpAndSettle();

    expect(ZyraDevScenario.instance.pendingInviteCount, 0);
    expect(find.textContaining('Awaiting response'), findsNothing);
  });

  testWidgets('Guardian manager owns sent invitation cancellation', (
    tester,
  ) async {
    ZyraDevScenario.instance.setWaliSentInvites(1);
    await tester.pumpWidget(
      subject(
        ZyraGuardianInvitationAudience.guardian,
        surface: ZyraGuardianInvitationSurface.manager,
      ),
    );
    await tester.pump();

    expect(find.text('Have a Seeker invite code?'), findsNothing);
    expect(find.textContaining('Awaiting response'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel invitation'));
    await tester.pumpAndSettle();

    expect(ZyraDevScenario.instance.waliSentInvites, 0);
  });

  testWidgets('multiple invitation states fit a 320px phone at 130% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ZyraDevScenario.instance.setReceivedInvites(5);
    ZyraDevScenario.instance.setPendingInvites(5);

    await tester.pumpWidget(
      subject(ZyraGuardianInvitationAudience.seeker, textScale: 1.3),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guardian page plus owns permanent-code request entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LinkGuardianScreen(onLinked: () {}, gender: 'Male'),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Scan code'), findsOneWidget);
    expect(find.text('Enter code'), findsOneWidget);
    await tester.tap(find.text('Enter code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter ZYRA Code'), findsNothing);
    expect(
      find.byKey(const ValueKey('inline-zyra-code-entry')),
      findsOneWidget,
    );
    expect(find.text('ZYRA-XXXX-XXXX-XXXX-XXXX-XXXX'), findsOneWidget);

    await tester.tap(find.text('Enter code'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inline-zyra-code-entry')), findsNothing);
  });

  testWidgets('manager owns pending expiry, detail and cancel entry', (
    tester,
  ) async {
    ZyraDevScenario.instance.setUseLiveGuardianData(true);
    final invite = PendingInvite(
      token: 'LIVE1234',
      label: 'Dad',
      createdAt: DateTime.utc(2026, 8, 28),
      expiresAt: DateTime.utc(2026, 9, 2),
    );
    await tester.pumpWidget(
      subject(
        ZyraGuardianInvitationAudience.seeker,
        surface: ZyraGuardianInvitationSurface.manager,
        comparisonNow: DateTime.utc(2026, 8, 30),
        pendingInvitesLoader: () async => ZyraSourceResult.available([invite]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Awaiting response · 3 days left'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-invite-detail-LIVE1234')),
      findsOneWidget,
    );
    expect(find.text('LIVE1234'), findsOneWidget);
    expect(find.text('28 Aug 2026'), findsOneWidget);
    expect(find.text('2 Sep 2026'), findsOneWidget);
  });

  test('production Dashboards hand invitation ownership to manager pages', () {
    final seekerManager = File(
      'lib/screens/wali/seeker_guardian_designs.dart',
    ).readAsStringSync();
    final guardianManager = File(
      'lib/screens/wali/wali_invite_seeker_screen.dart',
    ).readAsStringSync();
    final seekerDashboard = File(
      'lib/widgets/zyra_quiet_dashboard.dart',
    ).readAsStringSync();
    final guardianDashboard = File(
      'lib/screens/wali/wali_dashboard_screen.dart',
    ).readAsStringSync();
    final linkPanel = File(
      'lib/screens/wali/link_guardian_panel.dart',
    ).readAsStringSync();

    expect(seekerManager, contains('ZyraGuardianInvitationDashboard'));
    expect(seekerManager, contains('ZyraGuardianInvitationSurface.manager'));
    expect(guardianManager, contains('ZyraCodeScreen'));
    expect(seekerDashboard, isNot(contains('ZyraGuardianInvitationDashboard')));
    expect(
      guardianDashboard,
      isNot(contains('ZyraGuardianInvitationDashboard')),
    );
    expect(linkPanel, contains('ZyraCodeScreen'));
  });
}
