// LOCK16 V2: real route focus, owned-modal admission, and stale person actions.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_draft_journey_block_hide_sheet.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

const _owner = 'block-hide-v2-owner';
const _sara = 'draft-sara';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/'
    'LOCK16_JOURNEY_BLOCK_HIDE_V2_2026-10-31';

Finder _key(String value) => find.byKey(ValueKey(value));

ViewRequestDraftModel _fixture({int capacity = 3, bool preparing = false}) {
  final model = ViewRequestDraftModel(
    capacity: capacity,
    clock: () => DateTime.utc(2026, 10, 31, 16),
  );
  if (preparing) {
    expect(model.request(_sara), isTrue);
    expect(model.simulateRecipientAccept(_sara), isTrue);
  } else {
    expect(model.seedJourneys(capacity), isTrue);
  }
  return model;
}

Map<String, Object?> _facts(ViewRequestDraftSnapshot value) => {
  'capacity': value.capacity,
  'states': value.states,
  'busy': value.busyPeers,
  'hidden': value.hiddenPeers,
  'blocked': value.blockedPeers,
  'attempts': value.attemptRevisions,
  'attemptSequence': value.attemptSequence,
  'waiting': value.waitingAcceptances,
  'waitingSequence': value.acceptanceIntentSequence,
  'endedIds': value.currentEndedAttemptIds,
  'endedAttempts': value.endedAttempts.map((a) => a.id).toList(),
  'pastRequests': value.pastRequests.map((a) => a.id).toList(),
  'guardianAccess': value.guardianAccess,
  'requiredPaidGuardianAccess': value.requiredPaidGuardianAccess,
  'progress': value.progress,
  'requestedAt': value.pendingRequestedAt,
  'journeyStartedAt': value.journeyStartedAt,
  'journeyLastActivityAt': value.journeyLastActivityAt,
  'acceptedAt': value.outgoingRequestAcceptedAt,
  'acceptedRevisions': value.outgoingRequestAcceptedRevisions,
  'pastRequestSequence': value.pastRequestSequence,
  'guardianMemberships': value.guardianMemberships,
  'peerMainGuardianOverrides': value.peerMainGuardianOverrides,
  'ownMainGuardianPresent': value.ownMainGuardianPresent,
  'peerMainGuardianPresent': value.peerMainGuardianPresent,
};

class _GuardHarness {
  _GuardHarness(this.tester);
  final WidgetTester tester;
  final navigator = GlobalKey<NavigatorState>();
  bool ownerAdmitted = true;
  late BuildContext routeContext;
  late ZyraPreviewNavigationCheckpoint latest;

  ViewRequestDraftModel get model =>
      ViewRequestDraftModel.fromSnapshot(latest.model);

  bool get routeCurrent => ModalRoute.of(routeContext)?.isCurrent == true;

  Future<void> flush() async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  }

  Future<void> mount(ViewRequestDraftModel model) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    final ready = Completer<void>();
    latest = ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: model.snapshot(),
      tab: 1,
      pages: const ['profile'],
      personId: _sara,
      seekerMembership: model.capacity == 1 ? 'Seeker Basic' : 'Seeker One',
    );
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [ZyraDevControlsRouteObserver()],
        theme: ThemeData(platform: TargetPlatform.iOS),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            routeContext = context;
            return ZyraOneJourneyConceptShell(
              canAct: () => ownerAdmitted && routeCurrent,
              canActInOwnedDialog: () => ownerAdmitted,
              onExit: () => fail('Safety action must remain in the preview.'),
              initialCheckpoint: latest,
              previewClock: () => DateTime.utc(2026, 10, 31, 16),
              onCheckpoint: (value) => latest = value,
              onPresentationReady: () {
                if (!ready.isCompleted) ready.complete();
              },
            );
          },
        ),
      ),
    );
    for (var frame = 0; frame < 150 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue);
    await flush();
    expect(routeCurrent, isTrue);
    await tap('draft_safety');
    expect(latest.pages.last, 'safety');
    expect(
      tester.widget<OutlinedButton>(_key('draft_report_submit')).onPressed,
      isNull,
    );
  }

  Future<void> tap(String id) async {
    final target = _key(id);
    expect(target, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await flush();
    expect(target.hitTestable(), findsOneWidget);
    await tester.tap(target);
    await flush();
  }

  Future<VoidCallback> show({required bool hide}) async {
    await tap(hide ? 'draft_safety_hide' : 'draft_safety_block');
    expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsOneWidget);
    expect(routeCurrent, isFalse, reason: 'The actual modal covers its owner.');
    return tester
        .widget<ZyraDraftJourneyBlockHideSheet>(
          find.byType(ZyraDraftJourneyBlockHideSheet),
        )
        .onConfirm;
  }

  VoidCallback reportAction(bool hide) {
    final report = tester.widget<ZyraDraftReportPresentation>(
      find.byType(ZyraDraftReportPresentation),
    );
    return (hide ? report.onHide : report.onBlock)!;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize(_owner);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });

  for (final hide in [false, true]) {
    final action = hide ? 'hide' : 'block';
    for (final capacity in [1, 3]) {
      for (final preparing in [false, true]) {
        testWidgets(
          '$action owned modal ends exact ${preparing ? 'preparing' : 'active'} '
          'Journey with $capacity places',
          (tester) async {
            final h = _GuardHarness(tester);
            await h.mount(_fixture(capacity: capacity, preparing: preparing));
            final occupied = h.model.occupiedCount;
            final attempt = h.model.attemptRevisionFor(_sara);
            final confirm = await h.show(hide: hide);
            await h.tap('journey_person_safety_confirm');
            expect(h.routeCurrent, isTrue);
            expect(h.model.stateFor(_sara), DraftJourneyState.ended);
            expect(h.model.occupiedCount, occupied - 1);
            expect(h.model.endedAttemptsFor(_sara), hasLength(1));
            expect(h.model.attemptRevisionFor(_sara), attempt);
            expect(h.model.isHidden(_sara), hide);
            expect(h.model.isBlocked(_sara), !hide);
            expect(h.latest.tab, 1);
            expect(h.latest.pages, isEmpty);
            expect(
              find.text(
                hide
                    ? "Your Journey with Sara has ended. Sara won't appear again."
                    : 'Your Journey with Sara has ended and Sara is blocked.',
              ),
              findsOneWidget,
            );
            final committed = _facts(h.latest.model);
            confirm();
            confirm();
            await h.flush();
            expect(_facts(h.latest.model), committed);
          },
        );
      }
    }

    for (final dismiss in [false, true]) {
      testWidgets('$action ${dismiss ? 'barrier dismissal' : 'Keep'} preserves '
          'Journey and rejects retained confirmation', (tester) async {
        final h = _GuardHarness(tester);
        await h.mount(_fixture());
        final before = _facts(h.latest.model);
        final confirm = await h.show(hide: hide);
        if (dismiss) {
          await tester.tapAt(const Offset(8, 80));
          await h.flush();
        } else {
          await h.tap('journey_person_safety_keep');
        }
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
        confirm();
        confirm();
        await h.flush();
        expect(_facts(h.latest.model), before);
        expect(h.latest.pages.last, 'safety');
        expect(
          tester.widget<OutlinedButton>(_key('draft_report_submit')).onPressed,
          isNull,
        );
      });
    }

    for (final stale in ['account ABA', 'owner revoked', 'navigator ABA']) {
      testWidgets('$action pending owned modal rejects $stale and replay', (
        tester,
      ) async {
        final h = _GuardHarness(tester);
        await h.mount(_fixture());
        final before = _facts(h.latest.model);
        final confirm = await h.show(hide: hide);
        if (stale == 'account ABA') {
          await tester.runAsync(() async {
            await ZyraAccountState.synchronize('other-block-hide-owner');
            await ZyraAccountState.synchronize(_owner);
          });
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
          await h.flush();
        } else if (stale == 'owner revoked') {
          h.ownerAdmitted = false;
          await h.flush();
        } else {
          unawaited(
            h.navigator.currentState!.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Unrelated page')),
              ),
            ),
          );
          await h.flush();
          confirm();
          await h.flush();
          expect(find.text('Unrelated page'), findsOneWidget);
          h.navigator.currentState!.pop();
          await h.flush();
        }
        confirm();
        confirm();
        await h.flush();
        expect(_facts(h.latest.model), before);
        expect(h.latest.pages.last, 'safety');
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
        h.ownerAdmitted = true;
        confirm();
        await h.flush();
        expect(_facts(h.latest.model), before);
      });
    }

    for (final stale in ['controls ABA', 'role', 'reset']) {
      testWidgets('$action retained report entry rejects $stale', (
        tester,
      ) async {
        final h = _GuardHarness(tester);
        await h.mount(_fixture());
        final retained = h.reportAction(hide);
        await openZyraDevControls(tester);
        if (stale == 'controls ABA') {
          await closeZyraDevControls(tester);
        } else {
          await h.tap(stale == 'role' ? 'draft_role_guardian' : 'draft_reset');
        }
        final before = _facts(h.latest.model);
        retained();
        retained();
        await h.flush();
        expect(_facts(h.latest.model), before);
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
        expect(h.model.isHidden(_sara), isFalse);
        expect(h.model.isBlocked(_sara), isFalse);
        if (stale == 'role') expect(h.latest.guardian, isTrue);
      });
    }
  }

  for (final hide in [false, true]) {
    for (final stale in ['owner revoked', 'account ABA']) {
      final action = hide ? 'hide' : 'block';
      testWidgets(
        '$action stale physical confirm emits no haptic after $stale',
        (tester) async {
          final calls = <MethodCall>[];
          List<Object?> vibrations() => calls
              .where((call) => call.method == 'HapticFeedback.vibrate')
              .map((call) => call.arguments)
              .toList();
          final previousLevel = ZyraInteractionStyle.hapticLevel;
          ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.subtle);
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, (call) async {
                calls.add(call);
                return null;
              });
          addTearDown(() {
            ZyraInteractionStyle.selectHapticLevel(previousLevel);
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(
                  SystemChannels.platform,
                  (_) async => null,
                );
          });

          // Establish the real confirm control's feedback with a fresh owner.
          final admitted = _GuardHarness(tester);
          await admitted.mount(_fixture());
          await admitted.show(hide: hide);
          calls.clear();
          await admitted.tap('journey_person_safety_confirm');
          expect(vibrations(), ['HapticFeedbackType.selectionClick']);
          expect(admitted.model.stateFor(_sara), DraftJourneyState.ended);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          final h = _GuardHarness(tester);
          await h.mount(_fixture());
          final before = _facts(h.latest.model);
          await h.show(hide: hide);
          if (stale == 'owner revoked') {
            h.ownerAdmitted = false;
          } else {
            await tester.runAsync(() async {
              await ZyraAccountState.synchronize('other-physical-safety-owner');
              await ZyraAccountState.synchronize(_owner);
            });
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          }
          await h.flush();
          calls.clear();
          // Tap the actual visible button, including its feedback wrapper.
          await h.tap('journey_person_safety_confirm');
          expect(vibrations(), isEmpty);
          expect(_facts(h.latest.model), before);
          expect(h.model.stateFor(_sara), DraftJourneyState.active);
          expect(h.model.isHidden(_sara), isFalse);
          expect(h.model.isBlocked(_sara), isFalse);
          h.navigator.currentState!.pop();
          await h.flush();
        },
      );
    }
  }
}
