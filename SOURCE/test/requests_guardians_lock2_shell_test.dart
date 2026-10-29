// Corrected LOCK 2: actual sample-shell actions, detached checkpoints and no
// member/backend admission. Individual model invariants have their own suite.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/seeker_guardian_designs.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsRequestsGuardiansLock2';
const _hassan = 'draft-guardian-hassan';
const _yusuf = 'draft-guardian-yusuf';
Finder _key(String value) => find.byKey(ValueKey(value));
Finder _guardian(String id, String key) => find.descendant(
  of: _key('guardian-quiet-sections-$id'),
  matching: _key(key),
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('LOCK 2 sample shell must remain offline.');
  }
}

class _Owner {
  bool allowed = true;
  DateTime now = DateTime.utc(2026, 10, 29, 12);
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    ViewRequestDraftModel? model,
    ZyraPreviewNavigationCheckpoint? checkpoint,
    int tab = 2,
    List<String> pages = const ['requests'],
    int requestsTab = 0,
    int guardianPage = 0,
    Size size = const Size(430, 932),
    double textScale = 1,
  }) async {
    final ready = Completer<void>();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final theme = ThemeData.dark();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: _font),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => allowed,
          onExit: () => fail('LOCK 2 actions must stay in their sample owner.'),
          initialGuardianRole: checkpoint?.guardian ?? false,
          initialCheckpoint:
              checkpoint ??
              ZyraPreviewNavigationCheckpoint(
                guardian: false,
                model:
                    (model ??
                            ViewRequestDraftModel(
                              capacity: 3,
                              clock: () => now,
                            ))
                        .snapshot(),
                tab: tab,
                pages: pages,
                requestsTab: requestsTab,
                guardianPage: guardianPage,
              ),
          previewClock: () => now,
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
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
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
  }
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  final scrolls = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scrolls.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .4);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tapAt(tester.getCenter(target));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  final cell = _key('floating-nav-item-$index');
  expect(cell, findsOneWidget);
  final detector = find
      .ancestor(
        of: cell,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  final point = tester.getCenter(cell);
  expect(detector.hitTestable(), findsOneWidget);
  expect(tester.getRect(detector).contains(point), isTrue);
  await tester.tapAt(point);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(
    tester
        .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
        .currentIndex,
    index,
  );
}

ZyraRequestActivityPresentation _requests(WidgetTester tester) =>
    tester.widget(_key('concept_activity_requests'));
SeekerGuardianPage _guardians(WidgetTester tester) =>
    tester.widget(find.byType(SeekerGuardianPage));

VoidCallback _buttonAction(WidgetTester tester, String key) {
  final widget = tester.widget(_key(key));
  if (widget is OutlinedButton) return widget.onPressed!;
  if (widget is FilledButton) return widget.onPressed!;
  if (widget is TextButton) return widget.onPressed!;
  if (widget is InkWell) return widget.onTap!;
  throw StateError('Unknown actual button ${widget.runtimeType}.');
}

Future<void> _makeMain(WidgetTester tester, String id) async {
  await _tap(tester, _guardian(id, 'guardian-make-main'));
  await _tap(
    tester,
    find.descendant(
      of: _guardian(id, 'guardian-make-main-confirmation'),
      matching: find.text('Confirm'),
    ),
  );
}

Future<void> _nextGuardian(WidgetTester tester, String id) async {
  final pager = _key('guardian-page-view');
  await tester.drag(pager, const Offset(-340, 0));
  await tester.pumpAndSettle();
  expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
  final action = _guardian(id, 'guardian-make-main');
  await Scrollable.ensureVisible(tester.element(action), alignment: .4);
  await tester.pumpAndSettle();
  expect(action.hitTestable(), findsOneWidget);
}

void _expectNotice(WidgetTester tester, _Owner owner, String id, String name) {
  expect(_key('concept_main_guardian_notice'), findsOneWidget);
  expect(find.text('$name will be your Main Guardian'), findsOneWidget);
  expect(
    find.text(
      "$name is part of every Journey you begin. $name will also see your Journey requests — the ones you send and the ones you receive — and who each is with. $name sees that person's profile as anyone browsing would. Nothing more.",
    ),
    findsOneWidget,
  );
  expect(owner.latest.mainGuardianId, id);
  expect(owner.latest.pendingMainGuardianNoticeId, id);
  expect(owner.latest.pages.last, 'guardian_main_notice');
  expect(_key('concept_main_guardian_continue'), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMember;
  Map<String, Object?> preferenceState() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  List<Object?> memberState() => [
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.photos),
    AppState.instance.plan,
  ];
  setUpAll(() async {
    final font = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({'lock2-sentinel': 'keep'});
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    beforePreferences = preferenceState();
    beforeMember = memberState();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    expect(network.attempts, 0);
    expect(preferenceState(), beforePreferences);
    expect(memberState(), beforeMember);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'Requests has three equal pills and the default Past stays empty',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      expect(_requests(tester).labels, ['Received', 'Sent', 'Past']);
      expect(_requests(tester).pages, hasLength(3));
      final rectangles = [
        for (var i = 0; i < 3; i++) tester.getRect(_key('draft_requests_$i')),
      ];
      expect(rectangles[1].width, closeTo(rectangles[0].width, .01));
      expect(rectangles[2].width, closeTo(rectangles[0].width, .01));
      expect(rectangles.map((rect) => rect.top).toSet(), hasLength(1));
      await _tap(tester, _key('draft_requests_2'));
      expect(owner.latest.requestsTab, 2);
      expect(find.text('No past requests.'), findsOneWidget);
      expect(
        find.text(
          'Requests that were declined, expired or cancelled stay here.',
        ),
        findsOneWidget,
      );
      final empty = _requests(
        tester,
      ).pages[2].whereType<ZyraRequestActivityEmpty>().single;
      expect(empty.icon, Icons.history_rounded);
      expect(owner.latest.model.pastRequests, isEmpty);
      expect(find.textContaining('listed until'), findsNothing);
    },
  );

  testWidgets(
    'Past stays selected when its real developer controls open and close',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, requestsTab: 2);
      await openZyraDevControls(tester);
      expect(_key('concept_requests_controls_2'), findsOneWidget);
      expect(owner.latest.requestsTab, 2);
      await closeZyraDevControls(tester);
      expect(_requests(tester).selectedIndex, 2);
      expect(find.text('No past requests.'), findsOneWidget);
      expect(owner.latest.model.pastRequests, isEmpty);
    },
  );

  testWidgets(
    'Past shows full names original dates and newest moves first for years',
    (tester) async {
      final owner = _Owner();
      final model = ViewRequestDraftModel(capacity: 3, clock: () => owner.now);
      expect(
        model.seedPastRequest(
          profileId: 'draft-sara',
          outcome: DraftPastRequestOutcome.notTakenUp,
          requestedAt: DateTime.utc(2026, 10, 5),
          movedAt: DateTime.utc(2026, 10, 7),
        ),
        isTrue,
      );
      expect(
        model.seedPastRequest(
          profileId: 'draft-aisha',
          outcome: DraftPastRequestOutcome.youDeclined,
          requestedAt: DateTime.utc(2026, 10, 8),
          movedAt: DateTime.utc(2026, 10, 9),
        ),
        isTrue,
      );
      await owner.mount(tester, model: model, requestsTab: 2);
      expect(find.text('Aisha Khan'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Aisha Khan')).dy,
        lessThan(tester.getTopLeft(find.text('Sara Ahmed')).dy),
      );
      expect(find.text('Not taken up'), findsOneWidget);
      expect(find.text('You declined'), findsOneWidget);
      expect(find.text('Declined'), findsNothing);
      final dates = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where(
            (text) => text.startsWith('Sent ') || text.startsWith('Received '),
          )
          .toList();
      expect(dates, unorderedEquals(['Sent 5 Oct', 'Received 8 Oct']));
      expect(
        owner.latest.model.pastRequests.every(
          (entry) => entry.requestedAt.year == 2026,
        ),
        isTrue,
      );
      expect(find.byType(ZyraOneJourneyConnectionsActionButton), findsNothing);
      final saved = owner.latest;
      await tester.tapAt(tester.getCenter(find.text('Sara Ahmed')));
      await tester.pumpAndSettle();
      expect(owner.latest, same(saved));
      expect(_key('concept_request_draft-sara_header'), findsNothing);
      expect(_key('concept_request_profile_draft-sara'), findsNothing);
      expect(_key('draft_cancel_draft-sara'), findsNothing);
      owner.now = DateTime.utc(2036, 10, 29);
      final resumed = _Owner()..now = owner.now;
      await resumed.mount(tester, checkpoint: saved);
      expect(find.text('Aisha Khan'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      for (final date in dates) {
        expect(find.text(date), findsOneWidget);
      }
      expect(
        resumed.latest.model.pastRequests.map((entry) => entry.id),
        saved.model.pastRequests.map((entry) => entry.id),
      );
      expect(find.textContaining('listed until'), findsNothing);
    },
  );

  testWidgets(
    'actual decline and cancellation move only those requests to Past',
    (tester) async {
      final owner = _Owner();
      final model = ViewRequestDraftModel(capacity: 3, clock: () => owner.now);
      expect(model.request('draft-sara'), isTrue);
      await owner.mount(tester, model: model);
      final requested = owner.latest.model.pendingRequestedAt;
      await _tap(tester, _key('concept_request_draft-amira_header'));
      owner.now = owner.now.add(const Duration(days: 1));
      await _tap(tester, _key('draft_decline_draft-amira'));
      expect(owner.latest.model.states.containsKey('draft-amira'), isFalse);
      expect(
        owner.latest.model.pastRequests.single.outcome,
        DraftPastRequestOutcome.youDeclined,
      );
      await _tap(tester, _key('draft_requests_1'));
      await _tap(tester, _key('concept_request_draft-sara_header'));
      owner.now = owner.now.add(const Duration(days: 1));
      await _tap(tester, _key('draft_cancel_draft-sara'));
      await _tap(tester, _key('draft_requests_2'));
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('You declined'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Sara Ahmed')).dy,
        lessThan(tester.getTopLeft(find.text('Amira Rahman')).dy),
      );
      expect(owner.latest.model.pastRequests, hasLength(2));
      for (final entry in owner.latest.model.pastRequests) {
        expect(entry.requestedAt, requested[entry.profileId]);
      }
      expect(owner.latest.model.endedAttempts, isEmpty);
    },
  );

  testWidgets(
    'Keep my Journeys returns to Received without declining the request',
    (tester) async {
      final owner = _Owner();
      final model = ViewRequestDraftModel(capacity: 3, clock: () => owner.now)
        ..seedJourneys(3);
      await owner.mount(tester, model: model);
      final before = owner.latest.model;
      await _tap(tester, _key('concept_request_draft-amira_header'));
      await _tap(tester, _key('draft_accept_draft-amira'));
      expect(_key('request_capacity_choice'), findsOneWidget);
      expect(find.text('End & accept request'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(_key('request_capacity_continue'))
            .onPressed,
        isNull,
      );
      expect(
        find.text(
          'Choose a Journey to end before beginning with Amira, or keep your Journeys and leave the request for now.',
        ),
        findsOneWidget,
      );
      await _tap(tester, _key('request_capacity_cancel'));
      expect(owner.latest.pages, ['requests']);
      expect(owner.latest.requestsTab, 0);
      expect(owner.latest.model.states, before.states);
      expect(
        owner.latest.model.states['draft-amira'],
        DraftJourneyState.received,
      );
      expect(owner.latest.model.pastRequests, isEmpty);
      expect(owner.latest.model.endedAttempts, isEmpty);
      expect(_key('concept_request_draft-amira_header'), findsOneWidget);
    },
  );

  testWidgets(
    'Founder profile button says Request sent and second tap cancels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var semanticsDisposed = false;
      void disposeSemantics() {
        if (semanticsDisposed) return;
        semantics.dispose();
        semanticsDisposed = true;
      }

      addTearDown(disposeSemantics);
      try {
        final owner = _Owner();
        await owner.mount(tester, tab: 0, pages: const []);
        final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
          find.byType(ZyraOneJourneyBrowseDesigns),
        );
        final id = browse.profiles[browse.selectedIndex].id;
        expect(find.text('Request a Journey'), findsOneWidget);
        await _tap(tester, _key('draft_profile_$id'));
        expect(find.text('Request sent'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Request sent. Tap to cancel request'),
          findsOneWidget,
        );
        expect(find.text('Journey invitation sent'), findsNothing);
        expect(owner.latest.model.states[id], DraftJourneyState.sent);
        await _tap(tester, _key('draft_profile_$id'));
        expect(find.text('Request a Journey'), findsOneWidget);
        expect(owner.latest.model.states.containsKey(id), isFalse);
        expect(
          owner.latest.model.pastRequests.single.outcome,
          DraftPastRequestOutcome.cancelled,
        );
      } finally {
        disposeSemantics();
      }
    },
  );

  testWidgets(
    'Main notice appears once for each effective H to Y to H change',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, tab: 3, pages: const []);
      expect(_key('concept_main_guardian_notice'), findsNothing);
      final alreadyMain = _guardians(tester).makeMainGuardian!;
      await alreadyMain(_hassan);
      await tester.pumpAndSettle();
      expect(_key('concept_main_guardian_notice'), findsNothing);
      expect(owner.latest.pendingMainGuardianNoticeId, isNull);
      await _nextGuardian(tester, _yusuf);
      await _makeMain(tester, _yusuf);
      _expectNotice(tester, owner, _yusuf, 'Yusuf');
      final retainedContinue = _buttonAction(
        tester,
        'concept_main_guardian_continue',
      );
      await _tap(tester, _key('concept_main_guardian_continue'));
      expect(owner.latest.pendingMainGuardianNoticeId, isNull);
      expect(_key('concept_main_guardian_notice'), findsNothing);
      await _nextGuardian(tester, _hassan);
      await _makeMain(tester, _hassan);
      _expectNotice(tester, owner, _hassan, 'Hassan');
      final pending = owner.latest;
      retainedContinue();
      await tester.pumpAndSettle();
      expect(owner.latest, same(pending));
      _expectNotice(tester, owner, _hassan, 'Hassan');
      await _tap(tester, _key('concept_main_guardian_continue'));
      await _nav(tester, 0);
      await _nav(tester, 3);
      expect(_key('concept_main_guardian_notice'), findsNothing);
      expect(owner.latest.mainGuardianId, _hassan);
      expect(owner.latest.pendingMainGuardianNoticeId, isNull);
    },
  );

  testWidgets(
    'a pending Main notice resumes for its exact subject then stays consumed',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, tab: 3, pages: const []);
      await _nextGuardian(tester, _yusuf);
      await _makeMain(tester, _yusuf);
      final pending = owner.latest;
      final resumed = _Owner();
      await resumed.mount(tester, checkpoint: pending);
      _expectNotice(tester, resumed, _yusuf, 'Yusuf');
      expect(find.text('Hassan will be your Main Guardian'), findsNothing);
      await _tap(tester, _key('concept_main_guardian_continue'));
      final consumed = resumed.latest;
      final after = _Owner();
      await after.mount(tester, checkpoint: consumed);
      expect(_key('concept_main_guardian_notice'), findsNothing);
      expect(after.latest.mainGuardianId, _yusuf);
      expect(after.latest.pendingMainGuardianNoticeId, isNull);
    },
  );

  for (final revoked in [false, true]) {
    testWidgets(
      'a ${revoked ? 'revoked' : 'stale'} Make Main callback cannot create a notice',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, tab: 3, pages: const []);
        await _nextGuardian(tester, _yusuf);
        final retained = _guardians(tester).makeMainGuardian!;
        if (revoked) {
          owner.allowed = false;
        } else {
          await _nav(tester, 4);
        }
        final before = owner.latest;
        expect(await retained(_yusuf), isFalse);
        await tester.pumpAndSettle();
        expect(owner.latest, same(before));
        expect(owner.latest.mainGuardianId, _hassan);
        expect(owner.latest.pendingMainGuardianNoticeId, isNull);
        expect(_key('concept_main_guardian_notice'), findsNothing);
      },
    );
  }

  testWidgets(
    'a stale pending notice cannot retarget a restored Main Guardian',
    (tester) async {
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel(
            capacity: 3,
            clock: () => owner.now,
          ).snapshot(),
          tab: 3,
          pages: const ['guardian_main_notice'],
          mainGuardianId: _hassan,
          pendingMainGuardianNoticeId: _yusuf,
        ),
      );
      expect(owner.latest.mainGuardianId, _hassan);
      expect(owner.latest.pendingMainGuardianNoticeId, isNull);
      expect(_key('concept_main_guardian_notice'), findsNothing);
      expect(find.text('Hassan will be your Main Guardian'), findsNothing);
      expect(find.text('Yusuf will be your Main Guardian'), findsNothing);
    },
  );

  testWidgets(
    'Past keeps full identity and natural type at compact 200 percent',
    (tester) async {
      final owner = _Owner();
      final model = ViewRequestDraftModel(capacity: 3, clock: () => owner.now);
      expect(
        model.seedPastRequest(
          profileId: 'draft-aisha',
          outcome: DraftPastRequestOutcome.notTakenUp,
          requestedAt: DateTime.utc(2026, 10, 12),
          movedAt: DateTime.utc(2026, 10, 20),
        ),
        isTrue,
      );
      await owner.mount(
        tester,
        model: model,
        requestsTab: 2,
        size: const Size(320, 568),
        textScale: 2,
      );
      expect(_requests(tester).labels, ['Received', 'Sent', 'Past']);
      final card = find.byType(ZyraPastRequestActivityCard);
      expect(card, findsOneWidget);
      final name = find.descendant(of: card, matching: find.text('Aisha Khan'));
      expect(name, findsOneWidget);
      final text = tester.widget<Text>(name);
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      expect(
        MediaQuery.textScalerOf(
          tester.element(name),
        ).scale(text.style!.fontSize!),
        42,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Not taken up')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      expect(find.text('Not taken up').hitTestable(), findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Main message remains readable with Continue at compact 200 percent',
    (tester) async {
      final owner = _Owner();
      final model = ViewRequestDraftModel(capacity: 3, clock: () => owner.now);
      await owner.mount(
        tester,
        size: const Size(320, 568),
        textScale: 2,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: model.snapshot(),
          tab: 3,
          pages: const ['guardian_main_notice'],
          mainGuardianId: _yusuf,
          pendingMainGuardianNoticeId: _yusuf,
        ),
      );
      _expectNotice(tester, owner, _yusuf, 'Yusuf');
      final title = tester.widget<Text>(
        find.text('Yusuf will be your Main Guardian'),
      );
      expect(title.maxLines, isNull);
      expect(title.overflow, isNull);
      await _tap(tester, _key('concept_main_guardian_continue'));
      expect(owner.latest.pendingMainGuardianNoticeId, isNull);
      expect(_key('concept_main_guardian_notice'), findsNothing);
    },
  );

  testWidgets('Guardian-role restoration never opens the Seeker Main notice', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(
      tester,
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: true,
        model: ViewRequestDraftModel(
          capacity: 3,
          clock: () => owner.now,
        ).snapshot(),
        tab: 0,
        pages: const ['guardian_main_notice'],
        mainGuardianId: _hassan,
        pendingMainGuardianNoticeId: _hassan,
      ),
    );
    expect(owner.latest.guardian, isTrue);
    expect(owner.latest.pendingMainGuardianNoticeId, isNull);
    expect(_key('concept_main_guardian_notice'), findsNothing);
    expect(find.text('Hassan will be your Main Guardian'), findsNothing);
  });
}
