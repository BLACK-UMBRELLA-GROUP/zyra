import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_draft_journey_block_hide_sheet.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

const _owner = 'guardian-chat-v4-owner';
const _ownMessage = 'A local message from this Main Guardian.';
const _draft = 'An unfinished private Guardian message';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/'
    'LOCK8_GUARDIAN_CHAT_V4_2026-10-31';

Finder _key(String id) => find.byKey(ValueKey(id));

Map<String, Object?> _modelFacts(ViewRequestDraftSnapshot value) => {
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

Map<String, Object?> _facts(ZyraPreviewNavigationCheckpoint value) => {
  'model': _modelFacts(value.model),
  'guardian': value.guardian,
  'membership': value.guardianMembership,
  'main': value.mainGuardianId,
  'tab': value.tab,
  'pages': value.pages,
  'connection': value.guardianTabs.connection,
  'seeker': value.guardianTabs.seeker,
  'review': value.guardianTabs.review,
  'sent': value.guardianTabs.sent,
  'introduced': value.guardianTabs.introduced,
};

class _ChatHarness {
  _ChatHarness(this.tester);
  final WidgetTester tester;
  final navigator = GlobalKey<NavigatorState>();
  bool ownerAdmitted = true;
  bool sheetAdmitted = true;
  late BuildContext routeContext;
  late ZyraPreviewNavigationCheckpoint latest;

  bool get routeCurrent => ModalRoute.of(routeContext)?.isCurrent == true;
  ZyraGuardianPrivateChat get chat =>
      tester.widget(find.byType(ZyraGuardianPrivateChat));
  ZyraGuardianChatOptions get options =>
      tester.widget(find.byType(ZyraGuardianChatOptions));
  TextEditingController get controller =>
      tester.widget<TextField>(find.byType(TextField)).controller!;

  Future<void> flush() async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  }

  Future<void> mount({
    String membership = 'Guardian One',
    String mainGuardianId = 'draft-guardian-hassan',
    ZyraGuardianConnection connection = ZyraGuardianConnection.accepted,
    bool hasMainGuardian = true,
    int seeker = 0,
    int networkIndex = 0,
  }) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    final model = ViewRequestDraftModel(
      capacity: 3,
      clock: () => DateTime.utc(2026, 10, 31, 16),
    );
    expect(model.seedJourneys(2), isTrue);
    model.setOwnMainGuardianPresent(hasMainGuardian);
    final ready = Completer<void>();
    latest = ZyraPreviewNavigationCheckpoint(
      guardian: true,
      model: model.snapshot(),
      tab: 2,
      pages: const ['guardian_connect', 'guardian_private_chat'],
      personId: 'draft-sara',
      mainGuardianId: mainGuardianId,
      guardianMembership: membership,
      guardianTabs: ZyraGuardianTabsSnapshot(
        connection: connection,
        connectReceived: true,
        seeker: seeker,
        networkIndex: networkIndex,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [ZyraPreviewRouteObserver()],
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
              fixture: ZyraShellTestFixture().fixture,
              canAct: () => ownerAdmitted && routeCurrent,
              canActInOwnedDialog: () => ownerAdmitted && sheetAdmitted,
              initialGuardianRole: true,
              onExit: () => fail('Guardian chat stays in the local preview.'),
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
  }

  Future<void> tap(String id) async {
    if (await pressZyraDevControlKey(tester, id)) return;
    final target = _key(id);
    expect(target, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await flush();
    expect(target.hitTestable(), findsOneWidget);
    await tester.tap(target);
    await flush();
  }

  Future<void> openOptions() async {
    await tap('guardian_chat_options');
    expect(find.byType(ZyraGuardianChatOptions), findsOneWidget);
    expect(routeCurrent, isFalse);
  }

  Future<void> send([String message = _ownMessage]) async {
    await tester.enterText(find.byType(TextField), message);
    await tap('circle_send_action');
    expect(find.text(message), findsOneWidget);
    expect(controller.text, isEmpty);
  }

  Map<String, VoidCallback> retainChatControls({bool sent = false}) => {
    'shell send': chat.onSend,
    'shell report': chat.onReport,
    'shell options': chat.onOptions,
    'composer send': tester
        .widget<ZyraFamilyMessageComposer>(
          find.byType(ZyraFamilyMessageComposer),
        )
        .onSend,
    'physical send': tester.widget<InkWell>(_key('circle_send_action')).onTap!,
    'semantic send': tester
        .widget<Semantics>(_key('circle_send_button'))
        .properties
        .onTap!,
    'physical options': tester
        .widget<IconButton>(_key('guardian_chat_options'))
        .onPressed!,
    'long press': tester
        .widget<GestureDetector>(
          sent
              ? find
                    .ancestor(
                      of: find.text(_ownMessage),
                      matching: find.byWidgetPredicate(
                        (w) => w is GestureDetector && w.onLongPress != null,
                      ),
                    )
                    .first
              : _key('guardian_chat_report'),
        )
        .onLongPress!,
  };

  Map<String, VoidCallback> retainOptionsControls() => {
    'report delegate': options.onReport,
    'block delegate': options.onBlock,
    'done delegate': options.onDone,
    'report physical': tester
        .widget<ListTile>(_key('guardian_chat_options_report'))
        .onTap!,
    'block physical': tester
        .widget<ListTile>(_key('guardian_chat_options_block'))
        .onTap!,
    'done physical': tester
        .widget<FilledButton>(_key('guardian_chat_options_done'))
        .onPressed!,
  };

  Future<void> cover({bool pop = true}) async {
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Unrelated owner route')),
        ),
      ),
    );
    await flush();
    expect(find.text('Unrelated owner route'), findsOneWidget);
    expect(routeCurrent, isFalse);
    if (pop) {
      navigator.currentState!.pop();
      await flush();
    }
  }

  Future<void> expire(String reason, {bool optionsOpen = false}) async {
    switch (reason) {
      case 'owner revoked':
        ownerAdmitted = false;
      case 'owned admission revoked':
        sheetAdmitted = false;
      case 'account ABA':
        await tester.runAsync(() async {
          await ZyraAccountState.synchronize('other-guardian-chat-v4-owner');
          await ZyraAccountState.synchronize(_owner);
        });
        ZyraDeveloperAccess.setAuthorizedForTesting(true);
      case 'navigator ABA':
        await cover();
      case 'route covered':
        await cover(pop: false);
      case 'controls ABA' || 'role' || 'reset':
        if (optionsOpen) {
          navigator.currentState!.pop();
          await flush();
        }
        await openZyraDevControls(tester);
        if (reason == 'controls ABA') {
          await closeZyraDevControls(tester);
        } else {
          await tap(reason == 'role' ? 'draft_role_seeker' : 'draft_reset');
        }
      case 'connection blocked':
        if (!optionsOpen) await openOptions();
        await tap('guardian_chat_options_block');
        expect(latest.guardianTabs.connection, ZyraGuardianConnection.blocked);
      case 'UI revision':
        chat.onSend();
        await flush();
      case 'disposal':
        await tester.pumpWidget(const SizedBox.shrink());
    }
    await flush();
  }
}

void main() {
  final calls = <MethodCall>[];
  List<Object?> vibrations() => calls
      .where((call) => call.method == 'HapticFeedback.vibrate')
      .map((call) => call.arguments)
      .toList();
  late ZyraHapticLevel oldHapticLevel;

  Future<void> deniedOldActions(
    _ChatHarness h,
    Map<String, VoidCallback> retained,
  ) async {
    final before = _facts(h.latest);
    calls.clear();
    for (final action in retained.values) {
      action();
      action();
    }
    await h.flush();
    expect(vibrations(), isEmpty);
    expect(_facts(h.latest), before);
    expect(h.controller.text, isEmpty);
    expect(find.text(_ownMessage), findsNothing);
    expect(find.text('A private chat'), findsOneWidget);
    expect(find.byType(ZyraGuardianChatOptions), findsNothing);
    expect(find.byType(ZyraDraftReportPresentation), findsNothing);
  }

  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize(_owner);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    oldHapticLevel = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.subtle);
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(() {
    ZyraInteractionStyle.selectHapticLevel(oldHapticLevel);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  testWidgets(
    'V4 actual sent text replaces the empty state and reuses composer',
    (tester) async {
      final h = _ChatHarness(tester);
      await h.mount(networkIndex: 0, seeker: 1);
      final composer = tester.widget<ZyraFamilyMessageComposer>(
        find.byType(ZyraFamilyMessageComposer),
      );
      expect(composer.hint, 'Message Noor’s Main Guardian');
      expect(composer.privateGuardian, isTrue);
      expect(composer.contextEnabled, isFalse);
      expect(find.text('ABOUT ADAM AND NOOR'), findsOneWidget);
      expect(find.text('Noor’s Main Guardian'), findsOneWidget);
      expect(find.text('A private chat'), findsOneWidget);
      final before = _facts(h.latest);
      await tester.enterText(find.byType(TextField), '  $_ownMessage  ');
      calls.clear();
      await h.tap('circle_send_action');
      expect(vibrations(), ['HapticFeedbackType.selectionClick']);
      expect(find.text(_ownMessage), findsOneWidget);
      expect(find.text('A private chat'), findsNothing);
      expect(h.controller.text, isEmpty);
      expect(_facts(h.latest), before);
      expect(find.text('Messages send in the app.'), findsNothing);
    },
  );

  for (final action in ['report', 'block', 'done']) {
    testWidgets(
      'V4 fresh physical options $action has one feedback and exact effect',
      (tester) async {
        final h = _ChatHarness(tester);
        await h.mount();
        await tester.enterText(find.byType(TextField), _draft);
        final before = _modelFacts(h.latest.model);
        await h.openOptions();
        expect(find.byType(ListTile), findsNWidgets(2));
        expect(find.text('Report a message'), findsOneWidget);
        expect(find.text('Block Noor’s Main Guardian'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
        final retained = h.retainOptionsControls();
        calls.clear();
        await h.tap('guardian_chat_options_$action');
        expect(vibrations(), ['HapticFeedbackType.selectionClick']);
        expect(find.byType(ZyraGuardianChatOptions), findsNothing);
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
        expect(_modelFacts(h.latest.model), before);
        if (action == 'report') {
          final report = tester.widget<ZyraDraftReportPresentation>(
            find.byType(ZyraDraftReportPresentation),
          );
          expect(report.profile?.id, 'local-noor-guardian');
          expect(report.profile?.firstName, 'Noor’s Main Guardian');
          expect(report.canSelect!(), isTrue);
          expect(h.latest.pages.last, 'guardian_chat_report');
          expect(
            h.latest.guardianTabs.connection,
            ZyraGuardianConnection.accepted,
          );
        } else if (action == 'block') {
          expect(
            h.latest.guardianTabs.connection,
            ZyraGuardianConnection.blocked,
          );
          expect(h.latest.pages, ['guardian_connect']);
          expect(find.byType(ZyraGuardianPrivateChat), findsNothing);
          expect(find.textContaining('Your Journey with'), findsNothing);
        } else {
          expect(
            h.latest.guardianTabs.connection,
            ZyraGuardianConnection.accepted,
          );
          expect(h.latest.pages.last, 'guardian_private_chat');
          expect(h.controller.text, _draft);
        }
        final committed = _facts(h.latest);
        calls.clear();
        for (final callback in retained.values) {
          callback();
          callback();
        }
        await h.flush();
        expect(vibrations(), isEmpty);
        expect(_facts(h.latest), committed);
        expect(find.byType(ZyraGuardianChatOptions), findsNothing);
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
      },
    );
  }

  for (final sent in [false, true]) {
    for (final options in [false, true]) {
      testWidgets(
        'V4 ${options ? 'options' : 'press hold'} report keeps Guardian target '
        'with ${sent ? 'own message only' : 'empty conversation'}',
        (tester) async {
          final h = _ChatHarness(tester);
          await h.mount(networkIndex: 0, seeker: 1);
          if (sent) await h.send();
          if (options) {
            await h.openOptions();
            await h.tap('guardian_chat_options_report');
          } else {
            await tester.longPress(
              sent ? find.text(_ownMessage) : _key('guardian_chat_report'),
            );
            await h.flush();
          }
          final report = tester.widget<ZyraDraftReportPresentation>(
            find.byType(ZyraDraftReportPresentation),
          );
          expect(report.profile?.id, 'local-noor-guardian');
          expect(report.profile?.firstName, 'Noor’s Main Guardian');
          expect(report.profile?.firstName, isNot('Sara'));
          expect(report.canSelect!(), isTrue);
          expect(
            tester
                .widget<OutlinedButton>(_key('draft_report_submit'))
                .onPressed,
            isNull,
          );
          final before = _modelFacts(h.latest.model);
          report.onBlock!();
          await h.flush();
          expect(
            h.latest.guardianTabs.connection,
            ZyraGuardianConnection.blocked,
          );
          expect(h.latest.pages, ['guardian_connect']);
          expect(_modelFacts(h.latest.model), before);
          expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
          report.onBlock!();
          await h.flush();
          expect(_modelFacts(h.latest.model), before);
        },
      );
    }
  }

  testWidgets(
    'V4 options preserve sent text and draft while route departure clears both',
    (tester) async {
      final h = _ChatHarness(tester);
      await h.mount();
      await h.send();
      await tester.enterText(find.byType(TextField), _draft);
      final controller = h.controller;
      await h.openOptions();
      await h.tap('guardian_chat_options_done');
      expect(h.controller, same(controller));
      expect(h.controller.text, _draft);
      expect(find.text(_ownMessage), findsOneWidget);
      await h.openOptions();
      await h.tap('guardian_chat_options_report');
      await returnZyraPreviewPage(tester);
      await h.flush();
      expect(find.byType(ZyraGuardianPrivateChat), findsOneWidget);
      expect(h.controller, isNot(same(controller)));
      expect(h.controller.text, isEmpty);
      expect(find.text(_ownMessage), findsNothing);
      expect(find.text('A private chat'), findsOneWidget);
    },
  );

  testWidgets('V4 account ABA rebuild isolates actual transcript and draft', (
    tester,
  ) async {
    final h = _ChatHarness(tester);
    await h.mount();
    await h.send();
    await tester.enterText(find.byType(TextField), _draft);
    final controller = h.controller;
    final retained = h.retainChatControls(sent: true);
    await tester.runAsync(() async {
      await ZyraAccountState.synchronize('replacement-private-chat-owner');
      await ZyraAccountState.synchronize(_owner);
    });
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    tester.element(find.byType(ZyraOneJourneyConceptShell)).markNeedsBuild();
    await h.flush();
    expect(h.controller, isNot(same(controller)));
    expect(h.controller.text, isEmpty);
    expect(find.text(_ownMessage), findsNothing);
    expect(find.text('ABOUT ADAM AND NOOR'), findsOneWidget);
    await deniedOldActions(h, retained);
  });

  testWidgets(
    'V4 replacement connection and same-host reset isolate chat state',
    (tester) async {
      final old = _ChatHarness(tester);
      await old.mount();
      await old.send();
      await tester.enterText(find.byType(TextField), _draft);
      final retained = old.retainChatControls(sent: true);
      await old.openOptions();
      await old.tap('guardian_chat_options_block');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final h = _ChatHarness(tester);
      await h.mount(seeker: 1, networkIndex: 0);
      expect(h.latest.guardianTabs.seeker, 1);
      expect(h.latest.guardianTabs.networkIndex, 0);
      expect(find.text('ABOUT ADAM AND NOOR'), findsOneWidget);
      expect(find.text('Noor’s Main Guardian'), findsOneWidget);
      await deniedOldActions(h, retained);
      await h.send();
      await tester.enterText(find.byType(TextField), _draft);
      final beforeReset = h.retainChatControls(sent: true);
      final shell = tester.state(find.byType(ZyraOneJourneyConceptShell));
      await openZyraDevControls(tester);
      await h.tap('draft_reset');
      await openZyraDevControls(tester);
      await h.tap('draft_role_guardian');
      await h.tap('guardian_connect');
      await h.tap('guardian_connect_tab_1');
      await h.tap('guardian_chat');
      expect(
        tester.state(find.byType(ZyraOneJourneyConceptShell)),
        same(shell),
      );
      expect(find.text('ABOUT ADAM AND NOOR'), findsOneWidget);
      await deniedOldActions(h, beforeReset);
    },
  );

  for (final reason in ['owner revoked', 'account ABA']) {
    for (final action in ['send', 'options', 'press hold']) {
      testWidgets('V4 physical $action checks $reason before feedback', (
        tester,
      ) async {
        final h = _ChatHarness(tester);
        await h.mount();
        await tester.enterText(find.byType(TextField), _draft);
        final before = _facts(h.latest);
        if (reason == 'owner revoked') {
          h.ownerAdmitted = false;
        } else {
          await tester.runAsync(() async {
            await ZyraAccountState.synchronize('physical-guardian-chat-other');
            await ZyraAccountState.synchronize(_owner);
          });
          ZyraDeveloperAccess.setAuthorizedForTesting(true);
        }
        calls.clear();
        if (action == 'press hold') {
          await tester.longPress(_key('guardian_chat_report'));
        } else {
          await tester.tap(
            _key(
              action == 'send' ? 'circle_send_action' : 'guardian_chat_options',
            ),
          );
        }
        await h.flush();
        expect(vibrations(), isEmpty);
        expect(_facts(h.latest), before);
        expect(find.byType(ZyraGuardianChatOptions), findsNothing);
        expect(find.byType(ZyraDraftReportPresentation), findsNothing);
        expect(find.text('Messages send in the app.'), findsNothing);
        if (find.byType(TextField).evaluate().isNotEmpty) {
          expect(h.controller.text, _draft);
        }
      });
    }
  }

  for (final reason in [
    'owner revoked',
    'account ABA',
    'navigator ABA',
    'route covered',
    'controls ABA',
    'role',
    'reset',
    'connection blocked',
    'UI revision',
    'disposal',
  ]) {
    testWidgets('V4 retained composer and header callbacks reject $reason', (
      tester,
    ) async {
      final h = _ChatHarness(tester);
      await h.mount();
      await tester.enterText(find.byType(TextField), _draft);
      final retained = h.retainChatControls();
      await h.expire(reason);
      final before = _facts(h.latest);
      final optionsBefore = find
          .byType(ZyraGuardianChatOptions)
          .evaluate()
          .length;
      final reportBefore = find
          .byType(ZyraDraftReportPresentation)
          .evaluate()
          .length;
      calls.clear();
      for (final entry in retained.entries) {
        entry.value();
        entry.value();
        await h.flush();
        expect(vibrations(), isEmpty, reason: entry.key);
        expect(_facts(h.latest), before, reason: entry.key);
        expect(
          find.byType(ZyraGuardianChatOptions).evaluate().length,
          optionsBefore,
          reason: entry.key,
        );
        expect(
          find.byType(ZyraDraftReportPresentation).evaluate().length,
          reportBefore,
          reason: entry.key,
        );
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
      }
    });
  }

  testWidgets(
    'V4 denied chat callbacks cannot revive when owner admission returns',
    (tester) async {
      final h = _ChatHarness(tester);
      await h.mount();
      await tester.enterText(find.byType(TextField), _draft);
      final controller = h.controller;
      final retained = h.retainChatControls();
      final before = _facts(h.latest);
      calls.clear();
      h.ownerAdmitted = false;
      for (final callback in retained.values) {
        callback();
      }
      expect(vibrations(), isEmpty);
      expect(_facts(h.latest), before);
      expect(controller.text, _draft);

      h.ownerAdmitted = true;
      for (final callback in retained.values) {
        callback();
        callback();
      }
      await h.flush();
      expect(vibrations(), isEmpty);
      expect(_facts(h.latest), before);
      expect(h.controller, same(controller));
      expect(controller.text, _draft);
      expect(find.byType(ZyraGuardianChatOptions), findsNothing);
      expect(find.byType(ZyraDraftReportPresentation), findsNothing);
      expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
      expect(find.text('A private chat'), findsOneWidget);
    },
  );

  testWidgets(
    'V4 denied sheet callbacks cannot revive when owned admission returns',
    (tester) async {
      for (final ownedAdmission in [false, true]) {
        final h = _ChatHarness(tester);
        await h.mount();
        await tester.enterText(find.byType(TextField), _draft);
        final controller = h.controller;
        await h.openOptions();
        final retained = h.retainOptionsControls();
        final before = _facts(h.latest);
        calls.clear();
        if (ownedAdmission) {
          h.sheetAdmitted = false;
        } else {
          h.ownerAdmitted = false;
        }
        for (final callback in retained.values) {
          callback();
        }
        expect(vibrations(), isEmpty);
        expect(_facts(h.latest), before);
        expect(controller.text, _draft);

        h.ownerAdmitted = true;
        h.sheetAdmitted = true;
        for (final callback in retained.values) {
          callback();
          callback();
        }
        await h.flush();
        expect(vibrations(), isEmpty);
        expect(_facts(h.latest), before);
        expect(controller.text, _draft);
        expect(find.byType(ZyraGuardianChatOptions), findsOneWidget);
        expect(find.byType(ZyraDraftReportPresentation), findsNothing);
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
      }
    },
  );

  for (final reason in ['owner revoked', 'owned admission revoked']) {
    for (final action in ['report', 'block', 'done']) {
      testWidgets('V4 physical sheet $action checks $reason before feedback', (
        tester,
      ) async {
        final h = _ChatHarness(tester);
        await h.mount();
        await h.openOptions();
        final before = _facts(h.latest);
        if (reason == 'owner revoked') {
          h.ownerAdmitted = false;
        } else {
          h.sheetAdmitted = false;
        }
        calls.clear();
        await tester.tap(_key('guardian_chat_options_$action'));
        await h.flush();
        expect(vibrations(), isEmpty);
        expect(_facts(h.latest), before);
        expect(find.byType(ZyraGuardianChatOptions), findsOneWidget);
        expect(find.byType(ZyraDraftReportPresentation), findsNothing);
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
      });
    }
  }

  for (final reason in [
    'owner revoked',
    'owned admission revoked',
    'account ABA',
    'navigator ABA',
    'route covered',
    'controls ABA',
    'role',
    'reset',
    'connection blocked',
    'disposal',
  ]) {
    testWidgets('V4 retained sheet callbacks reject $reason and replay', (
      tester,
    ) async {
      final h = _ChatHarness(tester);
      await h.mount();
      await h.openOptions();
      final retained = h.retainOptionsControls();
      await h.expire(reason, optionsOpen: true);
      final before = _facts(h.latest);
      final optionsBefore = find
          .byType(ZyraGuardianChatOptions)
          .evaluate()
          .length;
      calls.clear();
      for (final entry in retained.entries) {
        entry.value();
        entry.value();
        await h.flush();
        expect(vibrations(), isEmpty, reason: entry.key);
        expect(_facts(h.latest), before, reason: entry.key);
        expect(
          find.byType(ZyraGuardianChatOptions).evaluate().length,
          optionsBefore,
          reason: entry.key,
        );
        expect(find.byType(ZyraDraftReportPresentation), findsNothing);
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
      }
    });
  }

  for (final denied in [
    'Basic',
    'Additional',
    'missing Main',
    'pending',
    'dismissed',
    'blocked',
  ]) {
    testWidgets('V4 private route remains unavailable for $denied', (
      tester,
    ) async {
      final h = _ChatHarness(tester);
      await h.mount(
        membership: denied == 'Basic' ? 'Guardian Basic' : 'Guardian One',
        mainGuardianId: denied == 'Additional'
            ? 'draft-guardian-yusuf'
            : 'draft-guardian-hassan',
        hasMainGuardian: denied != 'missing Main',
        connection: switch (denied) {
          'pending' => ZyraGuardianConnection.pending,
          'dismissed' => ZyraGuardianConnection.dismissed,
          'blocked' => ZyraGuardianConnection.blocked,
          _ => ZyraGuardianConnection.accepted,
        },
      );
      expect(find.byType(ZyraGuardianPrivateChat), findsNothing);
      expect(find.byType(ZyraGuardianChatOptions), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(ZyraDraftReportPresentation), findsNothing);
      expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
    });
  }
}
