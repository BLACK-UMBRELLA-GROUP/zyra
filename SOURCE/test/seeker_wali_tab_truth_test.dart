import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/seeker_wali_tab.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final linkedGuardian = WaliLinkedPerson(
    id: 'guardian-1',
    firstName: 'Abdul',
    relationship: 'father',
    isMain: true,
    linkedAt: DateTime.utc(2026, 7, 12),
  );
  GuardianHistoryConsentState consent(bool enabled) =>
      GuardianHistoryConsentState(
        enabled: enabled,
        activeGuardianLinkId: 'link-1',
        guardianId: linkedGuardian.id,
        guardianIsMain: true,
      );

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = true;
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraDevScenario.instance.setUseLiveGuardianData(true);
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.setUseLiveGuardianData(false);
    ZyraText.useTestFontStubs = false;
  });

  Widget subject({
    required GuardianLinksLoader linksLoader,
    GuardianActivityLoader? activityLoader,
    GuardianHistoryConsentLoader? consentLoader,
    GuardianJourneyAccessLoader? journeyAccessLoader,
  }) => MaterialApp(
    home: Scaffold(
      body: SeekerWaliTab(
        linksLoader: linksLoader,
        activityLoader:
            activityLoader ?? () async => const ZyraSourceResult.available({}),
        historyConsentLoader:
            consentLoader ??
            ({required guardianId, required guardianIsMain, enabled}) async =>
                ZyraSourceResult.available(consent(enabled ?? false)),
        journeyAccessLoader:
            journeyAccessLoader ??
            ({required guardianId, attemptId, enabled, chatEnabled}) async =>
                const ZyraSourceResult.available(
                  <GuardianJourneyAccessState>[],
                ),
        pendingInvitesLoader: () async =>
            const ZyraSourceResult.available(<PendingInvite>[]),
        comparisonNow: DateTime.utc(2026, 8, 30, 18),
      ),
    ),
  );

  Semantics control(WidgetTester tester, Finder finder) =>
      tester.widget<Semantics>(finder);
  InkWell button(WidgetTester tester, Finder finder) => tester.widget<InkWell>(
    find.descendant(of: finder, matching: find.byType(InkWell)),
  );

  Future<void> bringConsentToggleIntoView(WidgetTester tester) async {
    final toggle = find.byKey(
      const ValueKey('guardian-history-consent-toggle'),
    );
    await Scrollable.ensureVisible(
      tester.element(toggle),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('failed link read retries into a truthful successful empty', (
    tester,
  ) async {
    var attempts = 0;
    var activityCalls = 0;
    await tester.pumpWidget(
      subject(
        linksLoader: () async {
          attempts += 1;
          if (attempts == 1) {
            return const ZyraSourceResult.unavailable(
              ZyraSourceFailure.requestFailed,
            );
          }
          return const ZyraSourceResult.available([]);
        },
        activityLoader: () async {
          activityCalls += 1;
          return const ZyraSourceResult.available({});
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guardians could not be refreshed'), findsOneWidget);
    expect(find.byKey(const ValueKey('guardian-add-top')), findsOneWidget);
    expect(find.byKey(const ValueKey('guardian-manager-add')), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Guardians could not be refreshed'), findsNothing);
    expect(find.byKey(const ValueKey('guardian-add-top')), findsOneWidget);
    expect(find.byKey(const ValueKey('guardian-manager-add')), findsNothing);
    expect(
      activityCalls,
      0,
      reason: 'An empty link set needs no activity read',
    );
  });

  testWidgets('Add a Guardian opens permanent code and request paths', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(linksLoader: () async => const ZyraSourceResult.available([])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guardian-add-top')));
    await tester.pumpAndSettle();

    expect(find.text('Add a Guardian'), findsOneWidget);
    expect(find.text('Scan code'), findsOneWidget);
    expect(find.text('Enter code'), findsOneWidget);
    expect(find.text('Generate Invite Code'), findsNothing);
  });

  testWidgets('Main Guardian page does not render Current Obligation state', (
    tester,
  ) async {
    var activityAttempts = 0;
    await tester.pumpWidget(
      subject(
        linksLoader: () async => ZyraSourceResult.available([linkedGuardian]),
        activityLoader: () async {
          activityAttempts += 1;
          if (activityAttempts == 1) {
            return const ZyraSourceResult.unavailable(
              ZyraSourceFailure.requestFailed,
            );
          }
          return const ZyraSourceResult.available({});
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abdul'), findsOneWidget);
    expect(
      find.text('Current Guardian activity could not be refreshed.'),
      findsNothing,
    );
    expect(find.text('CURRENT OBLIGATION'), findsNothing);
    expect(activityAttempts, 1);
  });

  testWidgets('consent changes only after the RPC confirms the new state', (
    tester,
  ) async {
    final write = Completer<ZyraSourceResult<GuardianHistoryConsentState>>();
    var calls = 0;
    await tester.pumpWidget(
      subject(
        linksLoader: () async => ZyraSourceResult.available([linkedGuardian]),
        consentLoader:
            ({required guardianId, required guardianIsMain, enabled}) {
              calls += 1;
              if (enabled == null) {
                return Future.value(ZyraSourceResult.available(consent(false)));
              }
              return write.future;
            },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-history-consent')),
      findsOneWidget,
    );
    expect(calls, 1);

    Switch toggle() => tester.widget<Switch>(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
    );
    await bringConsentToggleIntoView(tester);
    expect(toggle().value, isFalse);
    await tester.tap(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
    );
    await tester.pump();

    expect(toggle().value, isFalse, reason: 'No optimistic state is allowed');
    expect(find.text('Confirming with ZYRA…'), findsOneWidget);
    write.complete(ZyraSourceResult.available(consent(true)));
    await tester.pumpAndSettle();

    expect(toggle().value, isTrue);
    expect(calls, 2);
  });

  testWidgets('failed consent write retains and labels last confirmed state', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        linksLoader: () async => ZyraSourceResult.available([linkedGuardian]),
        consentLoader:
            ({required guardianId, required guardianIsMain, enabled}) async =>
                enabled == null
                ? ZyraSourceResult.available(consent(false))
                : const ZyraSourceResult.unavailable(
                    ZyraSourceFailure.requestFailed,
                  ),
      ),
    );
    await tester.pumpAndSettle();
    await bringConsentToggleIntoView(tester);
    await tester.tap(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
    );
    await tester.pumpAndSettle();

    final toggle = tester.widget<Switch>(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
    );
    expect(toggle.value, isFalse);
    expect(
      find.textContaining('Showing the last server-confirmed state'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Additional Guardian gets per-Journey access, not a limited label',
    (tester) async {
      final additional = WaliLinkedPerson(
        id: 'guardian-2',
        firstName: 'Hassan',
        relationship: 'brother',
        linkedAt: DateTime.utc(2026, 8, 1),
      );
      var consentReads = 0;
      var accessReads = 0;
      await tester.pumpWidget(
        subject(
          linksLoader: () async => ZyraSourceResult.available([additional]),
          consentLoader:
              ({required guardianId, required guardianIsMain, enabled}) async {
                consentReads += 1;
                return ZyraSourceResult.available(
                  GuardianHistoryConsentState(
                    enabled: false,
                    activeGuardianLinkId: 'link-additional',
                    guardianId: guardianId,
                    guardianIsMain: false,
                  ),
                );
              },
          journeyAccessLoader:
              ({required guardianId, attemptId, enabled, chatEnabled}) async {
                accessReads += 1;
                return ZyraSourceResult.available([
                  GuardianJourneyAccessState(
                    attemptId: 'attempt-1',
                    matchId: 'match-1',
                    counterpartFirstName: 'Maryam',
                    included: enabled ?? true,
                    canChange: true,
                    guardianIsMain: false,
                  ),
                ]);
              },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('guardian-history-consent')),
        findsOneWidget,
      );
      expect(consentReads, 1);
      expect(find.text('Limited Journey summary'), findsNothing);
      expect(find.text('Journey with Maryam'), findsOneWidget);
      expect(find.text('CAN VIEW'), findsNothing);
      expect(find.text('MAIN GUARDIAN LEADS'), findsNothing);
      expect(find.text('LEADS'), findsNothing);
      expect(accessReads, 1);
      expect(
        find.byKey(const ValueKey('guardian-history-consent')),
        findsOneWidget,
      );
      expect(consentReads, 1);
    },
  );

  testWidgets(
    'Additional Journey access changes only after server confirmation',
    (tester) async {
      final additional = WaliLinkedPerson(
        id: 'guardian-2',
        firstName: 'Hassan',
        relationship: 'brother',
        linkedAt: DateTime.utc(2026, 8, 1),
      );
      final write =
          Completer<ZyraSourceResult<List<GuardianJourneyAccessState>>>();
      var calls = 0;
      GuardianJourneyAccessState state(bool included) =>
          GuardianJourneyAccessState(
            attemptId: 'attempt-1',
            matchId: 'match-1',
            counterpartFirstName: 'Maryam',
            included: included,
            canChange: true,
            guardianIsMain: false,
          );

      await tester.pumpWidget(
        subject(
          linksLoader: () async => ZyraSourceResult.available([additional]),
          journeyAccessLoader:
              ({required guardianId, attemptId, enabled, chatEnabled}) {
                calls += 1;
                if (enabled == null) {
                  return Future.value(
                    ZyraSourceResult.available([state(false)]),
                  );
                }
                return write.future;
              },
        ),
      );
      await tester.pumpAndSettle();

      final circleFinder = find.byKey(
        const ValueKey('guardian-journey-access-toggle-attempt-1'),
      );
      expect(control(tester, circleFinder).properties.toggled, isFalse);
      await tester.tap(circleFinder);
      await tester.pump();

      expect(
        control(tester, circleFinder).properties.toggled,
        isFalse,
        reason: 'No optimistic access state is allowed',
      );
      expect(
        control(tester, circleFinder).properties.enabled,
        isFalse,
        reason: 'A second change is blocked while ZYRA confirms the first',
      );
      expect(
        button(tester, circleFinder).onTap,
        isNull,
        reason: 'A second change is blocked while ZYRA confirms the first',
      );
      write.complete(ZyraSourceResult.available([state(true)]));
      await tester.pumpAndSettle();

      expect(control(tester, circleFinder).properties.toggled, isTrue);
      expect(calls, 2);
    },
  );

  testWidgets(
    'failed Additional Journey write keeps the last confirmed state',
    (tester) async {
      final additional = WaliLinkedPerson(
        id: 'guardian-2',
        firstName: 'Hassan',
        relationship: 'brother',
        linkedAt: DateTime.utc(2026, 8, 1),
      );
      final state = GuardianJourneyAccessState(
        attemptId: 'attempt-1',
        matchId: 'match-1',
        counterpartFirstName: 'Maryam',
        included: true,
        canChange: true,
        guardianIsMain: false,
      );

      await tester.pumpWidget(
        subject(
          linksLoader: () async => ZyraSourceResult.available([additional]),
          journeyAccessLoader:
              ({required guardianId, attemptId, enabled, chatEnabled}) async =>
                  enabled == null
                  ? ZyraSourceResult.available([state])
                  : const ZyraSourceResult.unavailable(
                      ZyraSourceFailure.requestFailed,
                    ),
        ),
      );
      await tester.pumpAndSettle();

      final circleFinder = find.byKey(
        const ValueKey('guardian-journey-access-toggle-attempt-1'),
      );
      expect(control(tester, circleFinder).properties.toggled, isTrue);
      await tester.tap(circleFinder);
      await tester.pumpAndSettle();

      expect(control(tester, circleFinder).properties.toggled, isTrue);
      expect(
        find.textContaining('Showing the last confirmed Journey access'),
        findsOneWidget,
      );
      expect(find.text('Journey access could not be refreshed.'), findsNothing);
    },
  );

  testWidgets('mismatched consent response fails closed and retries', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      subject(
        linksLoader: () async => ZyraSourceResult.available([linkedGuardian]),
        consentLoader:
            ({required guardianId, required guardianIsMain, enabled}) async {
              calls += 1;
              if (calls == 1) {
                return const ZyraSourceResult.available(
                  GuardianHistoryConsentState(
                    enabled: true,
                    activeGuardianLinkId: 'wrong-link',
                    guardianId: 'another-guardian',
                    guardianIsMain: true,
                  ),
                );
              }
              return ZyraSourceResult.available(consent(false));
            },
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);

    expect(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
      findsNothing,
    );
    expect(
      find.text('Past-summary permission could not be refreshed.'),
      findsOneWidget,
    );
    await Scrollable.ensureVisible(
      tester.element(
        find.text('Past-summary permission could not be refreshed.'),
      ),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
      findsOneWidget,
    );
    expect(calls, 2);
  });

  testWidgets('preview consent stays local on the one-page view', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance
      ..setUseLiveGuardianData(false)
      ..setMainGuardian(true)
      ..setAdditionalGuardians(0);
    var consentCalls = 0;
    await tester.pumpWidget(
      subject(
        linksLoader: () async => const ZyraSourceResult.available([]),
        consentLoader:
            ({required guardianId, required guardianIsMain, enabled}) async {
              consentCalls += 1;
              return ZyraSourceResult.available(consent(enabled ?? false));
            },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guardian-history-consent')),
      findsOneWidget,
    );
    await bringConsentToggleIntoView(tester);

    final toggle = tester.widget<Switch>(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
    );
    expect(toggle.value, isFalse);
    await tester.tap(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
    );
    await tester.pump();
    expect(consentCalls, 0);
    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('guardian-history-consent-toggle')),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('preview management confirms mutate the Guardian cards', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ZyraDevScenario.instance
      ..setUseLiveGuardianData(false)
      ..setMainGuardian(true)
      ..setAdditionalGuardians(1);

    await tester.pumpWidget(
      subject(linksLoader: () async => const ZyraSourceResult.available([])),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('guardian-page-view')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hassan'), findsOneWidget);

    final makeMain = find.byKey(const ValueKey('guardian-make-main'));
    await tester.ensureVisible(makeMain);
    await tester.tap(makeMain);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Hassan'), findsOneWidget);
    expect(find.byKey(const ValueKey('guardian-clear-main')), findsOneWidget);

    final clearMain = find.byKey(const ValueKey('guardian-clear-main'));
    await tester.ensureVisible(clearMain);
    await tester.tap(clearMain);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('guardian-clear-main')), findsNothing);

    final removeGuardian = find.byKey(const ValueKey('guardian-remove'));
    await tester.ensureVisible(removeGuardian);
    await tester.tap(removeGuardian);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Hassan'), findsNothing);
    expect(find.text('Abdul'), findsOneWidget);
  });
}
