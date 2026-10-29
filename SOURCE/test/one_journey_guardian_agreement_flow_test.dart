// New-Journey paid Additional Guardian consent through the admitted UI host.
// Offline fixtures only: this does not activate live access or entitlements.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_draft_compatibility_access_store.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _amira = 'draft-amira';
const _sara = 'draft-sara';
const _yusuf = 'draft-guardian-yusuf';
Finder _key(String id) => find.byKey(ValueKey(id));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Guardian consent review must remain offline.');
  }
}

ViewRequestDraftModel _preparing({bool basic = false}) {
  final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
  expect(
    model.setSampleGuardianJourneyAccess(
      _yusuf,
      _sara,
      viewEnabled: false,
      chatEnabled: false,
    ),
    isTrue,
  );
  if (basic) {
    expect(
      model.setSampleGuardianMembership(_yusuf, DraftGuardianMembership.basic),
      isTrue,
    );
  }
  expect(model.acceptReceived(_amira), isTrue);
  expect(model.markReady(_amira), isTrue);
  expect(model.simulatePeerReady(_amira), isTrue);
  return model;
}

class _Owner {
  final navigator = GlobalKey<NavigatorState>();
  final observer = ZyraDevControlsRouteObserver();
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  late final access = ZyraDraftCompatibilityAccessStore(canAct: () => true);
  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;
  ViewRequestDraftModel get model =>
      ViewRequestDraftModel.fromSnapshot(latest.model);

  Future<void> mount(
    WidgetTester tester, {
    bool basic = false,
    bool guardianPanel = false,
    Size size = const Size(393, 852),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    final ready = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [observer],
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: ViewRequestDraftScreen(
          ownerGeneration: ZyraAccountState.generation,
          ownerId: ZyraAccountState.userId,
          initialCheckpoint: ZyraPreviewNavigationCheckpoint(
            guardian: false,
            model: _preparing(basic: basic).snapshot(),
            tab: guardianPanel ? 3 : 1,
            pages: guardianPanel ? const [] : const ['journey'],
            guardianPage: guardianPanel ? 1 : 0,
            personId: _amira,
          ),
          compatibilityAccess: access,
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
    if (guardianPanel) {
      expect(find.byType(SeekerGuardianPage), findsOneWidget);
    } else {
      expect(_key('draft_begin_$_amira'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  }

  void close() {
    access.close();
    observer.dispose();
  }
}

Future<void> _press(WidgetTester tester, String id) async {
  final target = _key(id);
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.descendant(
        of: _key('dev_controls_scroll'),
        matching: find.byType(Scrollable),
      ),
    );
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

VoidCallback _agree(WidgetTester tester) => tester
    .widget<OutlinedButton>(_key('draft_agree_guardian_access_$_amira'))
    .onPressed!;

VoidCallback _begin(WidgetTester tester) =>
    tester.widget<OutlinedButton>(_key('draft_begin_$_amira')).onPressed!;

Map<String, Object?> _data(ViewRequestDraftSnapshot value) => {
  'capacity': value.capacity,
  'states': value.states,
  'busy': value.busyPeers,
  'hidden': value.hiddenPeers,
  'blocked': value.blockedPeers,
  'acknowledged': value.acknowledgedReceivedRequestIds,
  'progress': value.progress,
  'peerMain': value.peerMainGuardianOverrides,
  'memberships': value.guardianMemberships,
  'permissions': value.guardianAccess,
  'requiredPaid': value.requiredPaidGuardianAccess,
  'ownMain': value.ownMainGuardianPresent,
  'otherMain': value.peerMainGuardianPresent,
};

void _expectPending(_Owner current, Map<String, Object?> before) {
  expect(_data(current.latest.model), before);
  expect(current.model.stateFor(_amira), DraftJourneyState.preparing);
  expect(current.model.hasRequiredPaidGuardianAccess(_yusuf, _amira), isFalse);
  expect(current.access.balance, 1);
  expect(AppState.instance.activeJourneys, isEmpty);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final owners = <_Owner>[];
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldStubs;
  late ZyraHapticLevel oldHaptics;
  final oldFatal = WidgetController.hitTestWarningShouldBeFatal;
  _Owner owner() {
    final value = _Owner();
    owners.add(value);
    return value;
  }

  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraAccountState.clearImagesForTesting = () async {};
    AppState.instance.resetForAccountChange();
    final gold = ZyraDevAppGold.instance;
    gold.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: gold.revision,
    );
    oldStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
    oldHaptics = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    for (final value in owners) {
      value.close();
    }
    owners.clear();
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldStubs;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = oldFatal);

  for (final viewport in [
    (size: const Size(393, 852), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
  ]) {
    testWidgets('paid consent is explicit and scroll reachable at '
        '${viewport.size} ${viewport.scale}x; legacy pair remains unchanged', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester, size: viewport.size, scale: viewport.scale);
      final before = _data(current.latest.model);
      final legacy = current.latest.model.guardianAccess['$_yusuf|$_sara'];
      await _press(tester, 'draft_begin_$_amira');
      expect(_key('draft_guardian_access_agreement'), findsOneWidget);
      expect(find.text('Yusuf'), findsOneWidget);
      expect(find.text('Agree and begin'), findsOneWidget);
      expect(
        find.textContaining(
          'Existing Journeys and old conversations '
          'are not changed.',
        ),
        findsOneWidget,
      );
      _expectPending(current, before);
      await returnZyraPreviewPage(tester);
      _expectPending(current, before);
      await _press(tester, 'draft_begin_$_amira');
      await _press(tester, 'draft_agree_guardian_access_$_amira');
      expect(_key('draft_guardian_access_agreement'), findsNothing);
      expect(current.model.stateFor(_amira), DraftJourneyState.active);
      expect(
        current.model.hasRequiredPaidGuardianAccess(_yusuf, _amira),
        isTrue,
      );
      expect(current.model.sampleGuardianAccessFor(_yusuf, _amira), (
        view: true,
        chat: true,
      ));
      expect(current.latest.model.guardianAccess['$_yusuf|$_sara'], legacy);
      expect(
        current.model.hasRequiredPaidGuardianAccess(_yusuf, _sara),
        isFalse,
      );
      expect(current.access.balance, 1);
      expect(current.access.isUnlocked(_amira), isFalse);
      expect(AppState.instance.activeJourneys, isEmpty);
    });
  }

  testWidgets('Basic Additional Guardian does not acquire Chat or require '
      'a paid-access agreement', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    await current.mount(tester, basic: true);
    await _press(tester, 'draft_begin_$_amira');
    expect(_key('draft_guardian_access_agreement'), findsNothing);
    expect(current.model.stateFor(_amira), DraftJourneyState.active);
    expect(
      current.model.hasRequiredPaidGuardianAccess(_yusuf, _amira),
      isFalse,
    );
    expect(current.model.sampleGuardianAccessFor(_yusuf, _amira).chat, isFalse);
    expect(current.access.balance, 1);
  });

  for (final native in [false, true]) {
    testWidgets(
      'retained Basic Begin is denied across '
      '${native ? 'native-route' : 'Page options'} ABA; fresh Begin still works',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final current = owner();
        await current.mount(tester, basic: true);
        final before = _data(current.latest.model);
        final stale = _begin(tester);
        if (native) {
          unawaited(
            current.navigator.currentState!.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Native cover')),
              ),
            ),
          );
          await tester.pumpAndSettle();
        } else {
          await openZyraDevControls(tester);
        }
        stale();
        await tester.pumpAndSettle();
        _expectPending(current, before);
        if (native) {
          current.navigator.currentState!.pop();
          await tester.pumpAndSettle();
        } else {
          await closeZyraDevControls(tester);
        }
        stale();
        await tester.pumpAndSettle();
        _expectPending(current, before);
        await _press(tester, 'draft_begin_$_amira');
        expect(current.model.stateFor(_amira), DraftJourneyState.active);
        expect(_key('draft_guardian_access_agreement'), findsNothing);
        expect(
          current.model.sampleGuardianAccessFor(_yusuf, _amira).chat,
          isFalse,
        );
      },
    );

    testWidgets(
      'Additional Guardian loader rejects retained writes across '
      '${native ? 'native-route' : 'Page options'} ABA and admits fresh writes',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final current = owner();
        await current.mount(tester, basic: true, guardianPanel: true);
        final stale = tester
            .widget<SeekerGuardianPage>(find.byType(SeekerGuardianPage))
            .journeyAccessLoader!;
        final before = _data(current.latest.model);
        if (native) {
          unawaited(
            current.navigator.currentState!.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Native cover')),
              ),
            ),
          );
          await tester.pumpAndSettle();
        } else {
          await openZyraDevControls(tester);
        }
        final covered = await stale(
          guardianId: _yusuf,
          attemptId: 'draft-attempt-$_sara',
          enabled: true,
        );
        expect(covered.isUnavailable, isTrue);
        expect(_data(current.latest.model), before);
        if (native) {
          current.navigator.currentState!.pop();
          await tester.pumpAndSettle();
        } else {
          await closeZyraDevControls(tester);
        }
        final returned = await stale(
          guardianId: _yusuf,
          attemptId: 'draft-attempt-$_sara',
          enabled: true,
        );
        expect(returned.isUnavailable, isTrue);
        expect(_data(current.latest.model), before);
        final fresh = tester
            .widget<SeekerGuardianPage>(find.byType(SeekerGuardianPage))
            .journeyAccessLoader!;
        final read = await fresh(guardianId: _yusuf);
        expect(read.isAvailable, isTrue);
        expect(read.valueOrNull!.first.included, isFalse);
        final updated = await fresh(
          guardianId: _yusuf,
          attemptId: 'draft-attempt-$_sara',
          enabled: true,
        );
        expect(updated.isAvailable, isTrue);
        await tester.pumpAndSettle();
        expect(current.model.sampleGuardianAccessFor(_yusuf, _sara), (
          view: true,
          chat: false,
        ));
        expect(
          current.model.hasRequiredPaidGuardianAccess(_yusuf, _sara),
          isFalse,
        );
        expect(current.access.balance, 1);
      },
    );
  }

  testWidgets(
    'Back and a newer agreement invalidate the earlier Agree callback',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester);
      final before = _data(current.latest.model);
      await _press(tester, 'draft_begin_$_amira');
      final stale = _agree(tester);
      await returnZyraPreviewPage(tester);
      stale();
      await tester.pumpAndSettle();
      _expectPending(current, before);
      await _press(tester, 'draft_begin_$_amira');
      stale();
      await tester.pumpAndSettle();
      _expectPending(current, before);
      await _press(tester, 'draft_agree_guardian_access_$_amira');
      expect(current.model.stateFor(_amira), DraftJourneyState.active);
    },
  );

  testWidgets('a changed plan cannot reuse a retained paid agreement', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    await current.mount(tester);
    await _press(tester, 'draft_begin_$_amira');
    final stale = _agree(tester);
    await returnZyraPreviewPage(tester);
    await returnZyraPreviewPage(tester);
    await tester.tapAt(tester.getCenter(_key('floating-nav-item-3')));
    await tester.pumpAndSettle();
    await openZyraDevControls(tester);
    await _press(tester, 'concept_guardian_plan_${_yusuf}_0');
    await closeZyraDevControls(tester);
    final afterPlan = _data(current.latest.model);
    stale();
    await tester.pumpAndSettle();
    _expectPending(current, afterPlan);
    expect(
      current.model.sampleGuardianMembershipFor(_yusuf),
      DraftGuardianMembership.basic,
    );
    expect(current.model.sampleGuardianAccessFor(_yusuf, _sara).chat, isFalse);
    expect(
      current.model.hasRequiredPaidGuardianAccess(_yusuf, _amira),
      isFalse,
    );
  });

  testWidgets(
    'native route roundtrip and Guardian role change invalidate Agree',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester);
      final before = _data(current.latest.model);
      await _press(tester, 'draft_begin_$_amira');
      final stale = _agree(tester);
      unawaited(
        current.navigator.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Native cover')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      _expectPending(current, before);
      current.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      _expectPending(current, before);
      await openZyraDevControls(tester);
      await _press(tester, 'draft_role_guardian');
      stale();
      await tester.pumpAndSettle();
      expect(current.latest.guardian, isTrue);
      expect(current.latest.pages, isEmpty);
      _expectPending(current, before);
    },
  );
}
