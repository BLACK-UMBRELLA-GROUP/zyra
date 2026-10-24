// Presentation and existing caller-lifetime rules only; no live access grant.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_text.dart';

const _additional = WaliLinkedPerson(
  id: 'circle-additional',
  firstName: 'Yusuf',
);
const _main = WaliLinkedPerson(
  id: 'circle-main',
  firstName: 'Hassan',
  isMain: true,
);
const _previewAttempt = 'dev-active-journey';
Finder _key(String value) => find.byKey(ValueKey(value));
Finder _view(String attempt) => _key('guardian-journey-access-toggle-$attempt');
Finder _chat(String attempt) => _key('guardian-journey-chat-toggle-$attempt');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Guardian circle controls must remain offline.');
  }
}

Future<ZyraSourceResult<GuardianHistoryConsentState>> _history({
  required String guardianId,
  required bool guardianIsMain,
  bool? enabled,
}) async => ZyraSourceResult.available(
  GuardianHistoryConsentState(
    enabled: enabled ?? false,
    activeGuardianLinkId: 'local-link-$guardianId',
    guardianId: guardianId,
    guardianIsMain: guardianIsMain,
  ),
);

GuardianJourneyAccessState _row({required bool included}) =>
    GuardianJourneyAccessState(
      attemptId: 'confirmed-attempt',
      matchId: 'confirmed-match',
      counterpartFirstName: 'Sara',
      included: included,
      canChange: true,
      guardianIsMain: false,
      chatAvailable: true,
      chatEnabled: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.reset();
    ZyraText.useTestFontStubs = true;
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> mount(
    WidgetTester tester, {
    WaliLinkedPerson person = _additional,
    int count = 1,
    bool preview = true,
    GuardianPageJourneyAccessLoader? loader,
    Set<String> viewOnlyGuardianIds = const {},
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SafeArea(
            child: SeekerGuardianPage(
              people: [person],
              activity: const {},
              linksAvailable: true,
              activityAvailable: true,
              onRetry: () {},
              onAdd: () {},
              historyConsentPreview: preview,
              previewActiveJourneyCount: count,
              viewOnlyGuardianIds: viewOnlyGuardianIds,
              historyConsentLoader: _history,
              journeyAccessLoader: loader,
              pendingInvitesLoader: () async =>
                  const ZyraSourceResult.available(<PendingInvite>[]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Semantics control(WidgetTester tester, Finder finder) =>
      tester.widget<Semantics>(finder);
  InkWell button(WidgetTester tester, Finder finder) => tester.widget<InkWell>(
    find.descendant(of: finder, matching: find.byType(InkWell)),
  );

  for (final person in [_main, _additional]) {
    for (final count in [0, 1]) {
      testWidgets(
        'known Basic ${person.id} has View only with $count Journeys',
        (tester) async {
          await mount(
            tester,
            person: person,
            count: count,
            viewOnlyGuardianIds: {person.id},
          );
          final summary = _key('guardian-journey-access-summary');
          expect(
            find.descendant(of: summary, matching: find.text('View')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: summary, matching: find.text('Chat')),
            findsNothing,
          );
          expect(
            find.byWidgetPredicate((widget) {
              final key = widget.key;
              return key is ValueKey<String> &&
                  (key.value.startsWith('guardian-journey-chat-') ||
                      key.value.startsWith('guardian-journey-pending-chat-'));
            }),
            findsNothing,
          );
          for (final semantics in tester.widgetList<Semantics>(
            find.descendant(of: summary, matching: find.byType(Semantics)),
          )) {
            expect(
              semantics.properties.label?.toLowerCase(),
              isNot(contains('chat')),
            );
          }
          final outer = tester.widget<Semantics>(
            find.ancestor(of: summary, matching: find.byType(Semantics)).first,
          );
          expect(
            outer.properties.label?.toLowerCase(),
            isNot(contains('chat')),
          );
          for (var slot = count; slot < 3; slot++) {
            final pending = _key('guardian-journey-pending-view-$slot');
            expect(control(tester, pending).properties.toggled, isFalse);
            expect(button(tester, pending).onTap, isNull);
          }
          if (count == 1) {
            if (person.isMain) {
              expect(
                _key('guardian-journey-view-required-$_previewAttempt'),
                findsOneWidget,
              );
              expect(_view(_previewAttempt), findsNothing);
            } else {
              expect(
                control(tester, _view(_previewAttempt)).properties.enabled,
                isTrue,
              );
              await tester.tap(_view(_previewAttempt));
              await tester.pumpAndSettle();
              expect(
                control(tester, _view(_previewAttempt)).properties.toggled,
                isFalse,
              );
            }
          }
        },
      );
    }
  }

  testWidgets(
    'known Basic unavailable page omits Chat notes and pending controls',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await mount(
        tester,
        preview: false,
        viewOnlyGuardianIds: {_additional.id},
        loader:
            ({
              required String guardianId,
              String? attemptId,
              bool? enabled,
              bool? chatEnabled,
            }) async => const ZyraSourceResult.unavailable(
              ZyraSourceFailure.requestFailed,
            ),
      );
      expect(find.text('JOURNEY ACCESS UNAVAILABLE'), findsOneWidget);
      expect(find.text('Chat'), findsNothing);
      expect(_key('guardian-journey-chat-unavailable'), findsNothing);
      expect(_key('guardian-journey-pending-chat-0'), findsNothing);
    },
  );

  testWidgets(
    'explicit agreed paid Additional renders fixed View and Chat only on real rows',
    (tester) async {
      var writes = 0;
      await mount(
        tester,
        preview: false,
        loader:
            ({
              required String guardianId,
              String? attemptId,
              bool? enabled,
              bool? chatEnabled,
            }) async {
              if (enabled != null || chatEnabled != null) writes++;
              return const ZyraSourceResult.available([
                GuardianJourneyAccessState(
                  attemptId: 'agreed-new-attempt',
                  matchId: 'agreed-new-match',
                  counterpartFirstName: 'Sara',
                  included: true,
                  canChange: false,
                  guardianIsMain: false,
                  chatAvailable: true,
                  chatEnabled: true,
                  requiredByPaidAgreement: true,
                ),
              ]);
            },
      );
      for (final permission in ['view', 'chat']) {
        final required = _key(
          'guardian-journey-$permission-required-agreed-new-attempt',
        );
        expect(required, findsOneWidget);
        expect(
          find.descendant(of: required, matching: find.byType(InkWell)),
          findsNothing,
        );
        expect(
          control(
            tester,
            _key('guardian-journey-pending-$permission-1'),
          ).properties.toggled,
          isFalse,
        );
      }
      expect(_view('agreed-new-attempt'), findsNothing);
      expect(_chat('agreed-new-attempt'), findsNothing);
      expect(writes, 0);
    },
  );

  testWidgets(
    'known Basic confirmed row keeps optional View without any Chat',
    (tester) async {
      var view = false;
      var viewWrites = 0;
      var chatWrites = 0;
      await mount(
        tester,
        preview: false,
        viewOnlyGuardianIds: {_additional.id},
        loader:
            ({
              required String guardianId,
              String? attemptId,
              bool? enabled,
              bool? chatEnabled,
            }) async {
              if (enabled != null) {
                viewWrites++;
                view = enabled;
              }
              if (chatEnabled != null) chatWrites++;
              return ZyraSourceResult.available([
                GuardianJourneyAccessState(
                  attemptId: 'basic-attempt',
                  matchId: 'basic-match',
                  counterpartFirstName: 'Sara',
                  included: view,
                  canChange: true,
                  guardianIsMain: false,
                ),
              ]);
            },
      );
      expect(
        control(tester, _view('basic-attempt')).properties.toggled,
        isFalse,
      );
      await tester.tap(_view('basic-attempt'));
      await tester.pumpAndSettle();
      expect(
        control(tester, _view('basic-attempt')).properties.toggled,
        isTrue,
      );
      expect(viewWrites, 1);
      expect(chatWrites, 0);
      expect(find.text('Chat'), findsNothing);
      expect(_chat('basic-attempt'), findsNothing);
      expect(_key('guardian-journey-chat-unavailable'), findsNothing);
    },
  );

  testWidgets('membership display change retires an old Chat callback', (
    tester,
  ) async {
    await mount(tester);
    final retainedChat = button(tester, _chat(_previewAttempt)).onTap!;
    await mount(tester, viewOnlyGuardianIds: {_additional.id});
    retainedChat();
    await tester.pumpAndSettle();
    expect(_chat(_previewAttempt), findsNothing);
    expect(control(tester, _view(_previewAttempt)).properties.toggled, isTrue);
    expect(find.text('Chat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final malformed in [
    (
      included: true,
      canChange: false,
      chatAvailable: true,
      chatEnabled: true,
      proof: false,
    ),
    (
      included: true,
      canChange: true,
      chatAvailable: true,
      chatEnabled: true,
      proof: true,
    ),
    (
      included: false,
      canChange: false,
      chatAvailable: true,
      chatEnabled: false,
      proof: true,
    ),
    (
      included: true,
      canChange: false,
      chatAvailable: false,
      chatEnabled: false,
      proof: true,
    ),
    (
      included: true,
      canChange: false,
      chatAvailable: true,
      chatEnabled: false,
      proof: true,
    ),
  ]) {
    testWidgets(
      'Additional immutable/proof malformed state fails closed $malformed',
      (tester) async {
        await mount(
          tester,
          preview: false,
          loader:
              ({
                required String guardianId,
                String? attemptId,
                bool? enabled,
                bool? chatEnabled,
              }) async => ZyraSourceResult.available([
                GuardianJourneyAccessState(
                  attemptId: 'invalid',
                  matchId: 'invalid-match',
                  counterpartFirstName: 'Sara',
                  included: malformed.included,
                  canChange: malformed.canChange,
                  guardianIsMain: false,
                  chatAvailable: malformed.chatAvailable,
                  chatEnabled: malformed.chatEnabled,
                  requiredByPaidAgreement: malformed.proof,
                ),
              ]),
        );
        expect(find.text('JOURNEY ACCESS UNAVAILABLE'), findsOneWidget);
        expect(_key('guardian-journey-view-required-invalid'), findsNothing);
        expect(_key('guardian-journey-chat-required-invalid'), findsNothing);
        expect(_view('invalid'), findsNothing);
        expect(_chat('invalid'), findsNothing);
      },
    );
  }

  testWidgets(
    'Additional circles remain interactive when unticked; Chat needs View',
    (tester) async {
      await mount(tester);
      expect(
        control(tester, _view(_previewAttempt)).properties.toggled,
        isTrue,
      );
      expect(
        control(tester, _view(_previewAttempt)).properties.enabled,
        isTrue,
      );
      expect(
        control(tester, _chat(_previewAttempt)).properties.toggled,
        isTrue,
      );
      expect(tester.getSize(_view(_previewAttempt)), const Size(44, 44));
      expect(
        find.descendant(
          of: _view(_previewAttempt),
          matching: find.byType(Switch),
        ),
        findsNothing,
      );
      await tester.tap(_view(_previewAttempt));
      await tester.pumpAndSettle();
      expect(
        control(tester, _view(_previewAttempt)).properties.toggled,
        isFalse,
      );
      expect(
        control(tester, _view(_previewAttempt)).properties.enabled,
        isTrue,
      );
      expect(button(tester, _view(_previewAttempt)).onTap, isNotNull);
      expect(
        control(tester, _chat(_previewAttempt)).properties.toggled,
        isFalse,
      );
      expect(
        control(tester, _chat(_previewAttempt)).properties.enabled,
        isFalse,
      );
      expect(button(tester, _chat(_previewAttempt)).onTap, isNull);
      await tester.tap(_view(_previewAttempt));
      await tester.pumpAndSettle();
      expect(
        control(tester, _chat(_previewAttempt)).properties.enabled,
        isTrue,
      );
      await tester.tap(_chat(_previewAttempt));
      await tester.pumpAndSettle();
      expect(
        control(tester, _chat(_previewAttempt)).properties.toggled,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Main required circles stay locked and preserve their 26px face',
    (tester) async {
      await mount(tester, person: _main);
      final requiredView = _key(
        'guardian-journey-view-required-$_previewAttempt',
      );
      final requiredChat = _key(
        'guardian-journey-chat-required-$_previewAttempt',
      );
      expect(tester.getSize(requiredView), const Size(26, 26));
      expect(tester.getSize(requiredChat), const Size(26, 26));
      expect(
        find.descendant(of: requiredView, matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(_view(_previewAttempt), findsNothing);
    },
  );

  testWidgets('empty Journey permission slots are dim disabled circles', (
    tester,
  ) async {
    await mount(tester, count: 0);
    for (final slot in [0, 1, 2]) {
      for (final permission in ['view', 'chat']) {
        final target = _key('guardian-journey-pending-$permission-$slot');
        expect(control(tester, target).properties.toggled, isFalse);
        expect(control(tester, target).properties.enabled, isFalse);
        expect(control(tester, target).properties.onTap, isNull);
        expect(button(tester, target).onTap, isNull);
      }
    }
  });

  for (final count in [0, 1, 2]) {
    testWidgets(
      'Main empty slots are unticked and disabled; real access stays required count=$count',
      (tester) async {
        var writes = 0;
        final attempts = [
          for (var index = 0; index < count; index++)
            'confirmed-main-attempt-$index',
        ];
        await mount(
          tester,
          person: _main,
          count: count,
          preview: false,
          loader:
              ({
                required String guardianId,
                String? attemptId,
                bool? enabled,
                bool? chatEnabled,
              }) async {
                if (enabled != null || chatEnabled != null) writes++;
                return ZyraSourceResult.available([
                  for (final attempt in attempts)
                    GuardianJourneyAccessState(
                      attemptId: attempt,
                      matchId: 'match-$attempt',
                      counterpartFirstName: 'Sara',
                      included: true,
                      canChange: false,
                      guardianIsMain: true,
                      chatAvailable: true,
                      chatEnabled: true,
                    ),
                ]);
              },
        );
        for (var slot = count; slot < 3; slot++) {
          for (final permission in ['view', 'chat']) {
            final target = _key('guardian-journey-pending-$permission-$slot');
            expect(tester.getSize(target), const Size(44, 44));
            final pending = control(tester, target).properties;
            expect(pending.toggled, isFalse);
            expect(pending.enabled, isFalse);
            expect(pending.onTap, isNull);
            expect(button(tester, target).onTap, isNull);
            expect(
              find.descendant(
                of: target,
                matching: find.byIcon(Icons.check_rounded),
              ),
              findsNothing,
            );
            final face = find.descendant(
              of: target,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.constraints ==
                        const BoxConstraints.tightFor(width: 26, height: 26),
              ),
            );
            expect(face, findsOneWidget);
            expect(tester.getSize(face), const Size(26, 26));
            await tester.tap(target);
            await tester.pumpAndSettle();
            expect(control(tester, target).properties.toggled, isFalse);
            expect(writes, 0);
          }
        }
        for (final attempt in attempts) {
          for (final permission in ['view', 'chat']) {
            final requiredMark = _key(
              'guardian-journey-$permission-required-$attempt',
            );
            expect(requiredMark, findsOneWidget);
            expect(tester.getSize(requiredMark), const Size(26, 26));
            expect(
              find.descendant(
                of: requiredMark,
                matching: find.byIcon(Icons.check_rounded),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(of: requiredMark, matching: find.byType(InkWell)),
              findsNothing,
            );
            final label = permission == 'view' ? 'View' : 'Chat';
            final mark = tester
                .widgetList<Semantics>(
                  find.ancestor(
                    of: requiredMark,
                    matching: find.byType(Semantics),
                  ),
                )
                .singleWhere(
                  (widget) =>
                      widget.properties.label ==
                      '$label required for Journey with Sara',
                );
            expect(mark.properties.onTap, isNull);
            expect(mark.properties.toggled, isNull);
          }
          expect(_view(attempt), findsNothing);
          expect(_chat(attempt), findsNothing);
        }
        expect(writes, 0);
        expect(find.text('Awaiting a Journey'), findsNWidgets(3 - count));
        expect(find.text('No active Journey in this slot.'), findsNothing);
        expect(
          find.text('View access is required for every active Journey.'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Main unavailable read never paints verified required ticks', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await mount(
      tester,
      person: _main,
      preview: false,
      loader:
          ({
            required String guardianId,
            String? attemptId,
            bool? enabled,
            bool? chatEnabled,
          }) async => const ZyraSourceResult.unavailable(
            ZyraSourceFailure.requestFailed,
          ),
    );
    expect(find.text('JOURNEY ACCESS UNAVAILABLE'), findsOneWidget);
    for (final slot in [0, 1, 2]) {
      for (final permission in ['view', 'chat']) {
        final target = _key('guardian-journey-pending-$permission-$slot');
        expect(control(tester, target).properties.toggled, isFalse);
        expect(control(tester, target).properties.enabled, isFalse);
        expect(button(tester, target).onTap, isNull);
      }
    }
  });

  testWidgets(
    'permission writes keep confirmed state and disable circles while busy',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      final held =
          Completer<ZyraSourceResult<List<GuardianJourneyAccessState>>>();
      int writes = 0;
      Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> loader({
        required String guardianId,
        String? attemptId,
        bool? enabled,
        bool? chatEnabled,
      }) async {
        if (enabled != null) {
          writes++;
          expect(attemptId, 'confirmed-attempt');
          expect(enabled, isTrue);
          return held.future;
        }
        return ZyraSourceResult.available([_row(included: false)]);
      }

      await mount(tester, preview: false, loader: loader);
      await tester.tap(_view('confirmed-attempt'));
      await tester.pump();
      expect(writes, 1);
      expect(
        control(tester, _view('confirmed-attempt')).properties.toggled,
        isFalse,
      );
      expect(
        control(tester, _view('confirmed-attempt')).properties.enabled,
        isFalse,
      );
      expect(button(tester, _view('confirmed-attempt')).onTap, isNull);
      held.complete(ZyraSourceResult.available([_row(included: true)]));
      await tester.pumpAndSettle();
      expect(
        control(tester, _view('confirmed-attempt')).properties.toggled,
        isTrue,
      );
      expect(
        control(tester, _view('confirmed-attempt')).properties.enabled,
        isTrue,
      );
    },
  );

  testWidgets('retained circle callback cannot survive developer withdrawal', (
    tester,
  ) async {
    await mount(tester);
    final retained = button(tester, _view(_previewAttempt)).onTap!;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    retained();
    await tester.pumpAndSettle();
    expect(_view(_previewAttempt), findsNothing);
    expect(find.text('JOURNEY ACCESS UNAVAILABLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'past-summary sharing remains a real Switch with slightly larger visual size',
    (tester) async {
      await mount(tester);
      final history = _key('guardian-history-consent-toggle');
      expect(tester.widget<Switch>(history).onChanged, isNotNull);
      final sized = find.ancestor(
        of: history,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox && widget.width == 48 && widget.height == 32,
        ),
      );
      expect(sized, findsOneWidget);
      expect(tester.widget<Switch>(history).value, isFalse);
      await tester.tap(history);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(history).value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
