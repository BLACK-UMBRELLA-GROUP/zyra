// LOCK 5: a tab visit consumes only tab attention in the fictional preview.
// Individual request acknowledgements and member data remain independent.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsTabAttentionIntegration';
const _requestId = 'draft-amira';
const _leadId = 'concept-request-$_requestId';
const _groupId = 'concept-my-requests';

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Tab attention fixtures must stay offline.');
  }
}

ZyraPreviewNavigationCheckpoint _seed({
  ViewRequestDraftModel? model,
  bool guardian = false,
  int tab = 0,
  int lastOpened = 0,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: guardian,
  model: (model ?? ViewRequestDraftModel(capacity: 3)).snapshot(),
  tab: tab,
  pages: const [],
  myZyraLastOpenedRevision: lastOpened,
);

class _Owner {
  bool allowed = true;
  int exits = 0;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    required ZyraPreviewNavigationCheckpoint checkpoint,
    bool restoreLocation = true,
  }) async {
    final ready = Completer<void>();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final theme = ThemeData.dark();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [ZyraPreviewRouteObserver()],
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: _font),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: ZyraOneJourneyConceptShell(
          fixture: ZyraShellTestFixture().fixture,
          key: UniqueKey(),
          canAct: () => allowed,
          onExit: () => exits++,
          initialGuardianRole: checkpoint.guardian,
          initialCheckpoint: checkpoint,
          restoreLocation: restoreLocation,
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    // Wait for the actual bundled photo preparation rather than substitute
    // a screen or manually signal that the shell is ready.
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
    expect(exits, 0);
  }
}

ZyraShellNavigation _navigation(WidgetTester tester) =>
    tester.widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation));

bool _hasTabAttention(WidgetTester tester) {
  final navigation = _navigation(tester);
  final item = navigation.items.singleWhere((item) => item.label == 'My ZYRA');
  return item.dot;
}

Future<void> _nav(WidgetTester tester, String label) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final root = find.byType(ZyraShellNavigation);
  expect(root, findsOneWidget);
  final navigation = _navigation(tester);
  final index = navigation.items.indexWhere((item) => item.label == label);
  expect(index, greaterThanOrEqualTo(0));
  final item = navigation.items[index];
  final icon = find.descendant(
    of: root,
    matching: item.useJourneyGlyph
        ? find.byType(ZyraJourneyIcon)
        : find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  // The floating navigation detector owns the physical destination cell;
  // icons are intentionally IgnorePointer children.
  final detector = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  final point = tester.getCenter(icon);
  expect(detector.hitTestable(), findsOneWidget);
  expect(tester.getRect(detector).contains(point), isTrue);
  await tester.tapAt(point);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(_navigation(tester).currentIndex, index);
}

Future<void> _tapControl(WidgetTester tester, String key) async {
  if (await pressZyraDevControlKey(tester, key)) return;
  final target = _key(key);
  if (target.evaluate().isEmpty) {
    final scrollable = find.descendant(
      of: _key('dev_controls_scroll'),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsWidgets);
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: scrollable.first,
      maxScrolls: 80,
    );
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .4);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectPendingUnacknowledged(ZyraPreviewNavigationCheckpoint checkpoint) {
  expect(checkpoint.model.states[_requestId], DraftJourneyState.received);
  expect(checkpoint.model.acknowledgedReceivedRequestIds, isEmpty);
  expect(checkpoint.model.capacity, 3);
  expect(checkpoint.model.progress, isEmpty);
}

void _expectItemAttention(WidgetTester tester) {
  final dashboard = tester.widget<ZyraQuietDashboard>(
    find.byType(ZyraQuietDashboard),
  );
  expect(dashboard.permanentNavigation, isTrue);
  for (final id in [_leadId, _groupId]) {
    expect(
      dashboard.fixtureCards
          .singleWhere((card) => card.id == id)
          .hasNewActivity,
      isTrue,
    );
  }
  expect(_key('my-zyra-new-activity-heading'), findsOneWidget);
  expect(_key('my-zyra-route-$_leadId'), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMember;
  late bool oldFontStubs;
  late String? oldReadingFont;

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
    final reading = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'tab-attention-sentinel': 'keep'});
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    beforePreferences = preferenceState();
    beforeMember = memberState();
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    oldFontStubs = ZyraText.useTestFontStubs;
    oldReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    final fatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = fatal);
  });

  tearDown(() {
    expect(network.attempts, 0);
    expect(preferenceState(), beforePreferences);
    expect(memberState(), beforeMember);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraText.testReadingFontFamily = oldReadingFont;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'opening My ZYRA clears only tab attention and preserves pending New activity',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      expect(_navigation(tester).currentIndex, 0);
      expect(_hasTabAttention(tester), isTrue);
      expect(owner.latest.myZyraLastOpenedRevision, 0);
      _expectPendingUnacknowledged(owner.latest);
      final before = owner.latest.model;

      await _nav(tester, 'My ZYRA');
      expect(_hasTabAttention(tester), isFalse);
      expect(
        owner.latest.myZyraLastOpenedRevision,
        before.receivedActivityRevision,
      );
      _expectPendingUnacknowledged(owner.latest);
      expect(owner.latest.model.states, before.states);
      expect(
        owner.latest.model.receivedRequestRevisions,
        before.receivedRequestRevisions,
      );
      _expectItemAttention(tester);

      await _nav(tester, 'Profiles');
      expect(_hasTabAttention(tester), isFalse);
      _expectPendingUnacknowledged(owner.latest);
      await _nav(tester, 'My ZYRA');
      expect(_hasTabAttention(tester), isFalse);
      _expectItemAttention(tester);
      _expectPendingUnacknowledged(owner.latest);
    },
  );

  testWidgets(
    'a newer arrival from the same peer restores gold tab attention',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      await _nav(tester, 'My ZYRA');
      final opened = owner.latest.myZyraLastOpenedRevision;
      expect(_hasTabAttention(tester), isFalse);
      _expectItemAttention(tester);

      await openZyraDevControls(tester);
      await _tapControl(tester, 'draft_reset');
      if (zyraShellFixtureFor(tester).setupScopeOpen) {
        await closeZyraDevControls(tester);
      }
      expect(_navigation(tester).currentIndex, 0);
      expect(owner.latest.model.receivedActivityRevision, greaterThan(opened));
      expect(
        owner.latest.model.receivedRequestRevisions[_requestId],
        greaterThan(opened),
      );
      expect(_hasTabAttention(tester), isTrue);
      _expectPendingUnacknowledged(owner.latest);

      await _nav(tester, 'My ZYRA');
      expect(_hasTabAttention(tester), isFalse);
      expect(
        owner.latest.myZyraLastOpenedRevision,
        owner.latest.model.receivedActivityRevision,
      );
      _expectItemAttention(tester);
      _expectPendingUnacknowledged(owner.latest);
    },
  );

  testWidgets(
    'a fresh shell restores the consumed marker without reading items',
    (tester) async {
      final first = _Owner();
      await first.mount(tester, checkpoint: _seed());
      await _nav(tester, 'My ZYRA');
      await _nav(tester, 'Profiles');
      final saved = first.latest;
      _expectPendingUnacknowledged(saved);

      final resumed = _Owner();
      await resumed.mount(tester, checkpoint: saved);
      expect(_navigation(tester).currentIndex, 0);
      expect(_hasTabAttention(tester), isFalse);
      expect(
        resumed.latest.myZyraLastOpenedRevision,
        saved.myZyraLastOpenedRevision,
      );
      expect(
        resumed.latest.model.receivedActivityRevision,
        saved.model.receivedActivityRevision,
      );
      _expectPendingUnacknowledged(resumed.latest);
      await _nav(tester, 'My ZYRA');
      _expectItemAttention(tester);
      expect(_hasTabAttention(tester), isFalse);
    },
  );

  testWidgets('resuming directly on My ZYRA consumes tab attention alone', (
    tester,
  ) async {
    final owner = _Owner();
    final checkpoint = _seed(tab: 2);
    expect(checkpoint.myZyraLastOpenedRevision, 0);
    await owner.mount(tester, checkpoint: checkpoint);
    expect(_navigation(tester).currentIndex, 2);
    expect(_hasTabAttention(tester), isFalse);
    expect(
      owner.latest.myZyraLastOpenedRevision,
      checkpoint.model.receivedActivityRevision,
    );
    _expectPendingUnacknowledged(owner.latest);
    _expectItemAttention(tester);
    await _nav(tester, 'Profiles');
    expect(_hasTabAttention(tester), isFalse);
  });

  testWidgets(
    'long absence opens My ZYRA and clears the marker without item ack',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3);
      final earlierArrival = model.receivedActivityRevision;
      expect(model.declineReceived(_requestId), isTrue);
      expect(model.seedReceived(_requestId), isTrue);
      expect(model.receivedActivityRevision, greaterThan(earlierArrival));
      final checkpoint = _seed(model: model, lastOpened: earlierArrival);
      final owner = _Owner();
      await owner.mount(tester, checkpoint: checkpoint, restoreLocation: false);
      expect(_navigation(tester).currentIndex, 2);
      expect(_hasTabAttention(tester), isFalse);
      expect(
        owner.latest.myZyraLastOpenedRevision,
        model.receivedActivityRevision,
      );
      _expectItemAttention(tester);
      _expectPendingUnacknowledged(owner.latest);
      await _nav(tester, 'Profiles');
      expect(_hasTabAttention(tester), isFalse);
    },
  );

  testWidgets('Guardian navigation never consumes Seeker tab attention', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(tester, checkpoint: _seed(guardian: true));
    expect(_navigation(tester).items, hasLength(5));
    expect(_navigation(tester).items[2].dot, isTrue);
    expect(owner.latest.myZyraLastOpenedRevision, 0);
    _expectPendingUnacknowledged(owner.latest);
    final otherTab = _navigation(tester).items[1].label;
    await _nav(tester, otherTab);
    await _nav(tester, 'My ZYRA');
    expect(_navigation(tester).items.every((item) => !item.dot), isTrue);
    expect(owner.latest.myZyraLastOpenedRevision, 0);
    _expectPendingUnacknowledged(owner.latest);
  });

  testWidgets(
    'an old arrival counter without a current received item stays plain',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.receivedActivityRevision, greaterThan(0));
      expect(model.declineReceived(_requestId), isTrue);
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed(model: model));
      expect(_hasTabAttention(tester), isFalse);
      expect(owner.latest.myZyraLastOpenedRevision, 0);
      await _nav(tester, 'My ZYRA');
      expect(_hasTabAttention(tester), isFalse);
      expect(owner.latest.model.states.containsKey(_requestId), isFalse);
      expect(owner.latest.model.acknowledgedReceivedRequestIds, isEmpty);
      expect(_key('my-zyra-new-activity-heading'), findsNothing);
    },
  );

  testWidgets(
    'a retained tab callback cannot consume attention after navigation',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final retained = _navigation(tester).onTap;
      await _nav(tester, 'Profile');
      final current = owner.latest;
      retained(2);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_navigation(tester).currentIndex, 4);
      expect(owner.latest, same(current));
      expect(owner.latest.myZyraLastOpenedRevision, 0);
      expect(_hasTabAttention(tester), isTrue);
      _expectPendingUnacknowledged(owner.latest);
      await _nav(tester, 'My ZYRA');
      expect(_hasTabAttention(tester), isFalse);
      _expectPendingUnacknowledged(owner.latest);
    },
  );

  testWidgets(
    'a revoked owner cannot consume attention through its tab callback',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final retained = _navigation(tester).onTap;
      final current = owner.latest;
      owner.allowed = false;
      retained(2);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(owner.latest, same(current));
      expect(owner.latest.myZyraLastOpenedRevision, 0);
      expect(_navigation(tester).currentIndex, 0);
      expect(_hasTabAttention(tester), isTrue);
      _expectPendingUnacknowledged(owner.latest);
    },
  );

  testWidgets('a retained tab callback stays stale after the controls close', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(tester, checkpoint: _seed());
    final retained = _navigation(tester).onTap;
    await openZyraDevControls(tester);
    final whileCovered = owner.latest;
    retained(2);
    await tester.pump();
    expect(_key('dev_controls_page'), findsNothing);
    expect(owner.latest, same(whileCovered));
    expect(owner.latest.myZyraLastOpenedRevision, 0);
    await closeZyraDevControls(tester);
    final afterClose = owner.latest;
    retained(2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(owner.latest, same(afterClose));
    expect(_navigation(tester).currentIndex, 0);
    expect(_hasTabAttention(tester), isTrue);
    _expectPendingUnacknowledged(owner.latest);
    await _nav(tester, 'My ZYRA');
    expect(_hasTabAttention(tester), isFalse);
  });
}
