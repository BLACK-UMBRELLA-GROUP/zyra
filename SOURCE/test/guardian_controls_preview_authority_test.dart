import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';

const _person = WaliLinkedPerson(
  id: 'synthetic-additional',
  firstName: 'Synthetic Guardian',
  relationship: 'brother',
);
const _state = GuardianJourneyAccessState(
  attemptId: 'synthetic-attempt',
  matchId: 'synthetic-match',
  counterpartFirstName: 'Synthetic counterpart',
  included: true,
  canChange: true,
  guardianIsMain: false,
  chatAvailable: true,
  chatEnabled: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final scenario = ZyraDevScenario.instance;
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    scenario.reset();
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    scenario.reset();
    ZyraAccountState.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  Widget subject({
    bool preview = true,
    int previewActiveJourneyCount = 1,
    GuardianPageJourneyAccessLoader? journeyAccessLoader,
    GuardianPageHistoryConsentLoader? historyConsentLoader,
  }) => MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: SeekerGuardianPage(
          people: const [_person],
          activity: const {},
          linksAvailable: true,
          activityAvailable: true,
          onRetry: () {},
          onAdd: () {},
          historyConsentPreview: preview,
          previewActiveJourneyCount: previewActiveJourneyCount,
          journeyAccessLoader: journeyAccessLoader,
          historyConsentLoader: historyConsentLoader,
        ),
      ),
    ),
  );

  Future<ZyraSourceResult<GuardianHistoryConsentState>> history({
    required String guardianId,
    required bool guardianIsMain,
    bool? enabled,
  }) async => ZyraSourceResult.available(
    GuardianHistoryConsentState(
      enabled: enabled ?? false,
      activeGuardianLinkId: 'synthetic-link',
      guardianId: guardianId,
      guardianIsMain: guardianIsMain,
    ),
  );

  void size(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Switch toggle(WidgetTester tester, String key) =>
      tester.widget<Switch>(find.byKey(ValueKey(key)));

  Semantics permission(WidgetTester tester, String key) =>
      tester.widget<Semantics>(find.byKey(ValueKey(key)));

  ValueChanged<bool> permissionChange(WidgetTester tester, String key) {
    final target = find.byKey(ValueKey(key));
    final state = permission(tester, key).properties;
    expect(state.enabled, isTrue);
    expect(state.toggled, isNotNull);
    final capturedValue = state.toggled!;
    final capturedTap = tester
        .widget<InkWell>(
          find.descendant(of: target, matching: find.byType(InkWell)),
        )
        .onTap!;
    // A circle can only request its captured opposite value. Retain the real
    // tap closure so withdrawal/rebinding still exercises its original guard.
    return (next) {
      expect(next, !capturedValue);
      capturedTap();
    };
  }

  testWidgets('requested raw preview cannot seed Journey or consent grants', (
    tester,
  ) async {
    size(tester);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('Journey with Maryam'), findsNothing);
    expect(
      find.byKey(const ValueKey('guardian-history-consent-toggle')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('guardian-journey-access-toggle-dev-active-journey'),
      ),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
  });

  for (final revoke in ['authorization', 'live', 'generation']) {
    testWidgets('retained preview controls deny $revoke withdrawal pre-frame', (
      tester,
    ) async {
      size(tester);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      final view = permissionChange(
        tester,
        'guardian-journey-access-toggle-dev-active-journey',
      );
      final chat = permissionChange(
        tester,
        'guardian-journey-chat-toggle-dev-active-journey',
      );
      final consent = toggle(
        tester,
        'guardian-history-consent-toggle',
      ).onChanged!;
      if (revoke == 'authorization') {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
      } else if (revoke == 'live') {
        scenario.setUseLiveGuardianData(true);
      } else {
        ZyraAccountState.resetForTesting();
        scenario.reset();
      }
      view(false);
      chat(false);
      consent(true);
      await tester.pump();
      expect(find.text('Journey with Maryam'), findsNothing);
      expect(
        find.byKey(const ValueKey('guardian-history-consent-toggle')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('guardian-journey-access-toggle-dev-active-journey'),
        ),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'opened consent explanation closes and stale info cannot reopen',
    (tester) async {
      size(tester);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      final button = find.byKey(
        const ValueKey('guardian-history-consent-details-toggle'),
      );
      final oldInfo = tester.widget<IconButton>(button).onPressed!;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('guardian-history-consent-explanation')),
        findsOneWidget,
      );
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      oldInfo();
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('guardian-history-consent-explanation')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('guardian-history-consent-toggle')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('older live read cannot overwrite the replacement source', (
    tester,
  ) async {
    size(tester);
    final older =
        Completer<ZyraSourceResult<List<GuardianJourneyAccessState>>>();
    Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> oldLoader({
      required String guardianId,
      String? attemptId,
      bool? enabled,
      bool? chatEnabled,
    }) => older.future;
    Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> newLoader({
      required String guardianId,
      String? attemptId,
      bool? enabled,
      bool? chatEnabled,
    }) async => const ZyraSourceResult.available([_state]);
    await tester.pumpWidget(
      subject(
        preview: false,
        journeyAccessLoader: oldLoader,
        historyConsentLoader: history,
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      subject(
        preview: false,
        journeyAccessLoader: newLoader,
        historyConsentLoader: history,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Journey with Synthetic counterpart'), findsOneWidget);
    older.complete(
      const ZyraSourceResult.available(<GuardianJourneyAccessState>[]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Journey with Synthetic counterpart'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('live write result cannot refill permission after owner reset', (
    tester,
  ) async {
    size(tester);
    final write =
        Completer<ZyraSourceResult<List<GuardianJourneyAccessState>>>();
    Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> loader({
      required String guardianId,
      String? attemptId,
      bool? enabled,
      bool? chatEnabled,
    }) async => attemptId == null
        ? const ZyraSourceResult.available([_state])
        : write.future;
    await tester.pumpWidget(
      subject(
        preview: false,
        journeyAccessLoader: loader,
        historyConsentLoader: history,
      ),
    );
    await tester.pumpAndSettle();
    permissionChange(
      tester,
      'guardian-journey-access-toggle-synthetic-attempt',
    )(false);
    ZyraAccountState.resetForTesting();
    scenario.reset();
    write.complete(const ZyraSourceResult.available([_state]));
    await tester.pumpAndSettle();
    expect(find.text('Journey with Synthetic counterpart'), findsNothing);
    expect(
      find.byKey(
        const ValueKey('guardian-journey-access-toggle-synthetic-attempt'),
      ),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('old preview circle cannot write into a replacement binding', (
    tester,
  ) async {
    size(tester);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final oldView = permissionChange(
      tester,
      'guardian-journey-access-toggle-dev-active-journey',
    );
    await tester.pumpWidget(subject(previewActiveJourneyCount: 2));
    await tester.pumpAndSettle();
    oldView(false);
    await tester.pump();
    expect(
      permission(
        tester,
        'guardian-journey-access-toggle-dev-active-journey',
      ).properties.toggled,
      isTrue,
    );
    expect(
      permission(
        tester,
        'guardian-journey-access-toggle-dev-active-journey-2',
      ).properties.toggled,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('old consent switch cannot write into a replacement source', (
    tester,
  ) async {
    size(tester);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final oldConsent = toggle(
      tester,
      'guardian-history-consent-toggle',
    ).onChanged!;
    await tester.pumpWidget(subject(historyConsentLoader: history));
    await tester.pumpAndSettle();
    oldConsent(true);
    await tester.pump();
    expect(toggle(tester, 'guardian-history-consent-toggle').value, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('removing permission owner closes its separate consent sheet', (
    tester,
  ) async {
    size(tester);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Unaffected permission owner')),
      ),
    );
    final owner = MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: SafeArea(
          child: SeekerGuardianPage(
            people: const [_person],
            activity: const {},
            linksAvailable: true,
            activityAvailable: true,
            onRetry: () {},
            onAdd: () {},
            historyConsentPreview: true,
            previewActiveJourneyCount: 1,
          ),
        ),
      ),
    );
    navigator.currentState!.push(owner);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('guardian-history-consent-details-toggle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('guardian-history-consent-explanation')),
      findsOneWidget,
    );
    navigator.currentState!.removeRoute(owner);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('guardian-history-consent-explanation')),
      findsNothing,
    );
    expect(find.text('Unaffected permission owner'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
