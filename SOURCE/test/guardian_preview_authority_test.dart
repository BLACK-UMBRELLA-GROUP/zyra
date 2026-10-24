import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/screens/wali/seeker_wali_tab.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final scenario = ZyraDevScenario.instance;
  const livePerson = WaliLinkedPerson(
    id: 'synthetic-live-guardian',
    firstName: 'Live Guardian',
    isMain: true,
  );

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    scenario.reset();
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    scenario.reset();
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.resetForTesting();
  });

  Widget subject(GuardianLinksLoader loader) => MaterialApp(
    home: Scaffold(
      body: SeekerWaliTab(
        linksLoader: loader,
        activityLoader: () async => const ZyraSourceResult.available(
          <String, List<GuardianActivity>>{},
        ),
        pendingInvitesLoader: () async =>
            const ZyraSourceResult.available(<PendingInvite>[]),
        historyConsentLoader:
            ({required guardianId, required guardianIsMain, enabled}) async =>
                const ZyraSourceResult.unavailable(
                  ZyraSourceFailure.requestFailed,
                ),
        journeyAccessLoader:
            ({required guardianId, attemptId, enabled, chatEnabled}) async =>
                const ZyraSourceResult.available(
                  <GuardianJourneyAccessState>[],
                ),
      ),
    ),
  );
  SeekerGuardianPage page(WidgetTester tester) =>
      tester.widget<SeekerGuardianPage>(find.byType(SeekerGuardianPage));

  test('ordinary launch/reset cannot enable Guardian fixtures', () {
    expect(scenario.useLiveGuardianData, isFalse);
    expect(scenario.guardianOverride, isFalse);
    scenario.setAdditionalGuardians(2);
    scenario.setMainGuardian(true);
    expect(scenario.guardianOverride, isFalse);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    expect(scenario.guardianOverride, isTrue);
    scenario.setUseLiveGuardianData(true);
    expect(scenario.guardianOverride, isFalse);
    scenario.reset();
    expect(scenario.guardianOverride, isTrue);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(scenario.guardianOverride, isFalse);
    scenario.reset();
    expect(scenario.guardianOverride, isFalse);
  });

  testWidgets(
    'ordinary member uses real roster despite default demo preference',
    (tester) async {
      await tester.pumpWidget(
        subject(() async => const ZyraSourceResult.available([livePerson])),
      );
      await tester.pumpAndSettle();
      expect(page(tester).people.single.id, livePerson.id);
      expect(page(tester).historyConsentPreview, isFalse);
    },
  );

  testWidgets('ordinary unavailable does not substitute fake Guardians', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        () async =>
            const ZyraSourceResult.unavailable(ZyraSourceFailure.requestFailed),
      ),
    );
    await tester.pumpAndSettle();
    expect(page(tester).people, isEmpty);
    expect(page(tester).linksAvailable, isFalse);
    expect(page(tester).historyConsentPreview, isFalse);
  });

  testWidgets('revocation withdraws preview and stale local action callbacks', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    scenario.setMainGuardian(true);
    scenario.setAdditionalGuardians(1);
    var liveLoads = 0;
    await tester.pumpWidget(
      subject(() async {
        liveLoads++;
        return const ZyraSourceResult.available([livePerson]);
      }),
    );
    await tester.pumpAndSettle();
    final old = page(tester);
    expect(old.people.every((p) => p.id.startsWith('dev-guardian-')), isTrue);
    expect(old.people, hasLength(2));
    expect(liveLoads, 0);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(await old.makeMainGuardian!('dev-guardian-1'), isFalse);
    expect(await old.clearMainGuardian!('dev-guardian-0'), isFalse);
    expect(await old.removeGuardian!('dev-guardian-1'), isNotNull);
    await tester.pumpAndSettle();
    expect(page(tester).people.single.id, livePerson.id);
    expect(page(tester).historyConsentPreview, isFalse);
    expect(liveLoads, 1);
  });

  testWidgets('late older request cannot overwrite a refreshed roster', (
    tester,
  ) async {
    final old = Completer<ZyraSourceResult<List<WaliLinkedPerson>>>();
    var loads = 0;
    await tester.pumpWidget(
      subject(() {
        if (++loads == 1) return old.future;
        return Future.value(const ZyraSourceResult.available([livePerson]));
      }),
    );
    ZyraWaliLinkService.linkRevision.value++;
    await tester.pumpAndSettle();
    old.complete(const ZyraSourceResult.available(<WaliLinkedPerson>[]));
    await tester.pumpAndSettle();
    expect(page(tester).people.single.id, livePerson.id);
  });

  testWidgets('account generation invalidates a pending member response', (
    tester,
  ) async {
    final pending = Completer<ZyraSourceResult<List<WaliLinkedPerson>>>();
    await tester.pumpWidget(subject(() => pending.future));
    await tester.pump();
    ZyraAccountState.resetForTesting();
    pending.complete(const ZyraSourceResult.available([livePerson]));
    await tester.pump();
    expect(find.byType(SeekerGuardianPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
