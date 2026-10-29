// Protected, disposable My ZYRA attention integration. No live account,
// provider, member request, credit, or network path is admitted here.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsMyZyraAttentionIntegration';
const _captureDir = String.fromEnvironment(
  'ZYRA_MY_ZYRA_ATTENTION_CAPTURE_DIR',
);
const _captureKey = ValueKey('my-zyra-attention-capture');
const _requestId = 'draft-amira';
const _leadId = 'concept-request-$_requestId';
const _groupId = 'concept-my-requests';

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('My ZYRA attention preview must stay offline.');
  }
}

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  double textScale = 1,
  ZyraPreviewNavigationCheckpoint? checkpoint,
  bool restoreLocation = true,
  ValueChanged<ZyraPreviewNavigationCheckpoint>? onCheckpoint,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final theme = ThemeData.dark();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [ZyraDevControlsRouteObserver()],
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: _font),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 44, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: ViewRequestDraftScreen(
        ownerGeneration: ZyraAccountState.generation,
        ownerId: ZyraAccountState.userId,
        onExit: () => fail('An in-app request return must not exit its owner.'),
        initialCheckpoint: checkpoint,
        restoreLocation: restoreLocation,
        onCheckpoint: onCheckpoint,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  if (target.evaluate().isEmpty) {
    final owner = [
      'dev_controls_scroll',
      'my-zyra-quiet-scroll-0',
      'draft_scroll',
    ].map(_key).firstWhere((finder) => finder.evaluate().isNotEmpty);
    final scrollable = find.descendant(
      of: owner,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsWidgets);
    await tester.scrollUntilVisible(target, 180, scrollable: scrollable.first);
  }
  expect(target, findsOneWidget);
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .4);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

ZyraShellNavigation _navigation(WidgetTester tester) =>
    tester.widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation));

bool _myZyraUnread(WidgetTester tester) => _navigation(tester).items[2].dot;

Future<void> _nav(WidgetTester tester, String label) async {
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
  // The current floating bar owns touch on one detector; icons intentionally
  // IgnorePointer. Keep this a physical tap on the real destination cell.
  final touchBar = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(touchBar.hitTestable(), findsOneWidget);
  final point = tester.getCenter(icon);
  expect(tester.getRect(touchBar).contains(point), isTrue);
  await tester.tapAt(point);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  if (label == 'Report') {
    // Report is a full-page leaf: a successful physical action intentionally
    // removes the navigation bar until Back returns to Browse.
    expect(find.byType(ZyraShellNavigation), findsNothing);
    expect(_key('draft_safety_block'), findsOneWidget);
  } else {
    expect(_navigation(tester).currentIndex, index);
  }
}

Future<void> _viewRequest(WidgetTester tester) async {
  await _tap(tester, 'concept_request_${_requestId}_header');
  await _tap(tester, 'concept_request_profile_$_requestId');
  await returnZyraPreviewPage(tester);
}

ZyraQuietDashboard _dashboard(WidgetTester tester) =>
    tester.widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard));

SupportiveCard _card(WidgetTester tester, String id) =>
    _dashboard(tester).fixtureCards.singleWhere((card) => card.id == id);

void _expectNew(WidgetTester tester, {bool groupMounted = true}) {
  expect(_dashboard(tester).permanentNavigation, isTrue);
  // The actual My ZYRA visit consumes tab attention independently of these
  // unopened request cards and their internal New activity treatment.
  expect(_myZyraUnread(tester), isFalse);
  expect(_card(tester, _leadId).hasNewActivity, isTrue);
  expect(_card(tester, _groupId).hasNewActivity, isTrue);
  expect(_card(tester, 'concept-my-introductions').hasNewActivity, isFalse);
  expect(_card(tester, 'concept-my-ended').hasNewActivity, isFalse);
  expect(_key('my-zyra-activity-$_leadId'), findsOneWidget);
  expect(_key('my-zyra-new-$_leadId'), findsNothing);
  if (groupMounted) {
    expect(_key('my-zyra-activity-$_groupId'), findsOneWidget);
  }
  expect(_key('my-zyra-new-$_groupId'), findsNothing);
  expect(_key('my-zyra-new-concept-my-introductions'), findsNothing);
  expect(_key('my-zyra-new-concept-my-ended'), findsNothing);
}

void _expectAcknowledged(WidgetTester tester) {
  expect(_myZyraUnread(tester), isFalse);
  expect(_key('my-zyra-new-activity-heading'), findsNothing);
  expect(
    _dashboard(tester).fixtureCards.map((card) => card.id),
    unorderedEquals([_groupId, 'concept-my-introductions', 'concept-my-ended']),
  );
  expect(_dashboard(tester).resolution.answer.item?.signal.id, isNot(_leadId));
  expect(
    _dashboard(tester).resolution.otherActions.map((item) => item.signal.id),
    isNot(contains(_leadId)),
  );
  expect(_dashboard(tester).permanentNavigation, isTrue);
  expect(find.text('Quick access'), findsOneWidget);
  expect(find.text('Journey request from Amira'), findsNothing);
  expect(_key('my-zyra-route-$_leadId'), findsNothing);
  expect(_card(tester, _groupId).hasNewActivity, isFalse);
  expect(_card(tester, _groupId).detail, '1 received · 0 sent');
  expect(_card(tester, 'concept-my-introductions').detail, '0 introductions');
  expect(_card(tester, 'concept-my-ended').detail, '0 ended');
  expect(_key('my-zyra-new-$_leadId'), findsNothing);
  expect(_key('my-zyra-new-$_groupId'), findsNothing);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDir.isEmpty) return;
  for (final element
      in find
          .descendant(of: find.byKey(_captureKey), matching: find.byType(Image))
          .evaluate()
          .toList()) {
    Object? decodeError;
    await tester.runAsync(
      () => precacheImage(
        (element.widget as Image).image,
        element,
        onError: (error, _) => decodeError = error,
      ).timeout(const Duration(seconds: 5)),
    );
    expect(decodeError, isNull);
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDir/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
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
    if (_captureDir.isNotEmpty &&
        (!_captureDir.startsWith('/') ||
            FileSystemEntity.typeSync(_captureDir, followLinks: false) !=
                FileSystemEntityType.directory ||
            Directory(_captureDir).resolveSymbolicLinksSync() !=
                Directory(_captureDir).path)) {
      throw StateError(
        'Captures need an existing absolute nonlinked directory.',
      );
    }
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
    SharedPreferences.setMockInitialValues({
      'my-zyra-attention-sentinel': 'keep',
    });
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    beforePreferences = preferenceState();
    beforeMember = memberState();
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
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
    HttpOverrides.global = previousNetwork;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'canonical soft destinations and controls never acknowledge an unopened request',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      await _nav(tester, 'My ZYRA');
      final states = Map.of(checkpoint!.model.states);
      expect(_dashboard(tester).permanentNavigation, isTrue);
      await openZyraDevControls(tester);
      await closeZyraDevControls(tester);
      _expectNew(tester);
      expect(checkpoint!.model.states, states);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await _tap(tester, 'my-zyra-route-concept-my-introductions');
      final page = tester.widget<ZyraRequestActivityPresentation>(
        _key('concept_activity_introductions'),
      );
      expect(page.selectedIndex, 0);
      expect(page.title, 'Introductions');
      expect(page.pages, hasLength(1));
      expect(find.byType(PageView), findsNothing);
      await _capture(tester, '05-introductions-shell-393');
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await returnZyraPreviewPage(tester);
      _expectNew(tester);
      await _tap(tester, 'my-zyra-route-$_groupId');
      expect(checkpoint!.model.states, states);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await _capture(tester, '06-requests-shell-393');
      await _tap(tester, 'concept_request_${_requestId}_header');
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await _capture(tester, '07-expanded-request-shell-393');
      await _tap(tester, 'concept_request_profile_$_requestId');
      await returnZyraPreviewPage(tester);
      expect(checkpoint!.model.states, states);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
      await returnZyraPreviewPage(tester);
      _expectAcknowledged(tester);
    },
  );

  testWidgets(
    'exact new-request highlight opens Received and dismisses immediately',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      expect(_myZyraUnread(tester), isTrue);
      await _nav(tester, 'My ZYRA');
      _expectNew(tester);
      expect(checkpoint!.model.states[_requestId], DraftJourneyState.received);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await _capture(tester, '01-new-393');

      await openZyraDevControls(tester);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await closeZyraDevControls(tester);
      _expectNew(tester);

      await _tap(tester, 'my-zyra-route-$_leadId');
      expect(_key('concept_activity_requests'), findsOneWidget);
      expect(checkpoint!.requestsTab, 0);
      expect(checkpoint!.model.states[_requestId], DraftJourneyState.received);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
      expect(_key('concept_request_${_requestId}_header'), findsOneWidget);
      // Acknowledging this temporary highlight neither answers nor removes
      // the request. Opening its exact profile remains safe and idempotent.
      await _viewRequest(tester);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
      expect(checkpoint!.model.capacity, 3);
      expect(checkpoint!.model.progress, isEmpty);
      await returnZyraPreviewPage(tester);
      _expectAcknowledged(tester);
      expect(_card(tester, _groupId).detail, '1 received · 0 sent');
      await _capture(tester, '02-acknowledged-393');
      await _nav(tester, 'Profiles');
      expect(_myZyraUnread(tester), isFalse);
      await _nav(tester, 'My ZYRA');
      _expectAcknowledged(tester);
    },
  );

  testWidgets(
    'a consumed highlight callback cannot reopen or mutate a request',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      await _nav(tester, 'My ZYRA');
      final retained = _dashboard(tester).onNavigate!;
      final addressed = _card(tester, _leadId);
      final before = checkpoint!.model;
      await _tap(tester, 'my-zyra-route-$_leadId');
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
      expect(checkpoint!.model.states, before.states);
      expect(checkpoint!.model.capacity, before.capacity);
      expect(checkpoint!.model.progress, before.progress);
      expect(checkpoint!.model.hiddenPeers, before.hiddenPeers);
      expect(checkpoint!.model.blockedPeers, before.blockedPeers);
      final opened = checkpoint!;
      retained(addressed);
      await tester.pumpAndSettle();
      expect(checkpoint, same(opened));
      expect(_key('concept_activity_requests'), findsOneWidget);
      await returnZyraPreviewPage(tester);
      _expectAcknowledged(tester);
      final returned = checkpoint!;
      retained(addressed);
      await tester.pumpAndSettle();
      expect(checkpoint, same(returned));
      _expectAcknowledged(tester);
      await _tap(tester, 'my-zyra-route-$_groupId');
      expect(_key('concept_request_${_requestId}_header'), findsOneWidget);
      expect(checkpoint!.model.states, before.states);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
    },
  );

  testWidgets(
    'a dismissed highlight stays absent after short and long restore',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      await _nav(tester, 'My ZYRA');
      await _tap(tester, 'my-zyra-route-$_leadId');
      final opened = checkpoint!;
      expect(opened.model.acknowledgedReceivedRequestIds, {_requestId});
      await tester.pumpWidget(const SizedBox.shrink());
      await _mount(
        tester,
        checkpoint: opened,
        onCheckpoint: (value) => checkpoint = value,
      );
      expect(_key('concept_activity_requests'), findsOneWidget);
      expect(_key('concept_request_${_requestId}_header'), findsOneWidget);
      await returnZyraPreviewPage(tester);
      _expectAcknowledged(tester);
      final returned = checkpoint!;
      await tester.pumpWidget(const SizedBox.shrink());
      await _mount(
        tester,
        checkpoint: returned,
        restoreLocation: false,
        onCheckpoint: (value) => checkpoint = value,
      );
      expect(_navigation(tester).currentIndex, 2);
      _expectAcknowledged(tester);
      await _tap(tester, 'my-zyra-route-$_groupId');
      expect(checkpoint!.model.states[_requestId], DraftJourneyState.received);
      expect(_key('concept_request_${_requestId}_header'), findsOneWidget);
    },
  );

  testWidgets(
    'unknown and mismatched request subjects never dismiss the hero',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      await _nav(tester, 'My ZYRA');
      final navigate = _dashboard(tester).onNavigate!;
      final before = checkpoint!;
      for (final id in [
        'concept-request-unknown',
        'concept-request-draft-sara',
        'concept-request-',
        'concept-request-$_requestId-other',
      ]) {
        navigate(
          SupportiveCard(
            id: id,
            section: SupportiveSection.needsYou,
            title: 'Journey request from Amira',
            target: ZyraDashboardTarget.connectionsActivity,
          ),
        );
        await tester.pumpAndSettle();
        expect(checkpoint, same(before));
        expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
        expect(_key('concept_activity_requests'), findsNothing);
        _expectNew(tester);
      }
    },
  );

  for (final departure in [
    'controls round trip',
    'covered round trip',
    'tab round trip',
    'owner generation change',
    'disposal',
  ]) {
    testWidgets('retained request highlight refuses after $departure', (
      tester,
    ) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      final navigator = GlobalKey<NavigatorState>();
      await _mount(
        tester,
        navigatorKey: navigator,
        onCheckpoint: (value) => checkpoint = value,
      );
      await _nav(tester, 'My ZYRA');
      final retained = _dashboard(tester).onNavigate!;
      final addressed = _card(tester, _leadId);
      switch (departure) {
        case 'controls round trip':
          await openZyraDevControls(tester);
          retained(addressed);
          await tester.pump();
          expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
          await closeZyraDevControls(tester);
        case 'covered round trip':
          unawaited(
            navigator.currentState!.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Unrelated cover')),
              ),
            ),
          );
          await tester.pumpAndSettle();
          retained(addressed);
          await tester.pumpAndSettle();
          expect(find.text('Unrelated cover'), findsOneWidget);
          expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
        case 'tab round trip':
          await _nav(tester, 'Profiles');
          await _nav(tester, 'My ZYRA');
        case 'owner generation change':
          ZyraAccountState.resetForTesting();
        case 'disposal':
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
      }
      final latest = checkpoint!;
      retained(addressed);
      await tester.pumpAndSettle();
      expect(checkpoint, same(latest));
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      expect(checkpoint!.model.states[_requestId], DraftJourneyState.received);
      expect(_key('concept_activity_requests'), findsNothing);
      if (departure != 'disposal') _expectNew(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Intro, Ended and Received list arrival do not acknowledge an item',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      await _nav(tester, 'My ZYRA');
      await _tap(tester, 'my-zyra-route-concept-my-introductions');
      expect(_key('concept_activity_introductions'), findsOneWidget);
      expect(_key('concept_activity_requests'), findsNothing);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await returnZyraPreviewPage(tester);
      _expectNew(tester);
      await _tap(tester, 'my-zyra-route-concept-my-ended');
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await _capture(tester, '08-ended-shell-393');
      await returnZyraPreviewPage(tester);
      _expectNew(tester);

      await _tap(tester, 'my-zyra-route-concept-my-introductions');
      await returnZyraPreviewPage(tester);
      await _tap(tester, 'my-zyra-route-$_groupId');
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await _viewRequest(tester);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
      expect(checkpoint!.model.states[_requestId], DraftJourneyState.received);
      await returnZyraPreviewPage(tester);
      _expectAcknowledged(tester);
    },
  );

  testWidgets(
    'controls and X reveal Received without acknowledging unopened items',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      await _nav(tester, 'My ZYRA');
      await _tap(tester, 'my-zyra-route-$_groupId');
      await _tap(tester, 'draft_requests_1');
      expect(checkpoint!.requestsTab, 1);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await openZyraDevControls(tester);
      await _tap(tester, 'concept_requests_controls_0');
      expect(_key('dev_controls_page'), findsOneWidget);
      expect(checkpoint!.requestsTab, 0);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await closeZyraDevControls(tester);
      expect(_key('concept_activity_requests'), findsOneWidget);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await _viewRequest(tester);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
      await returnZyraPreviewPage(tester);
      _expectAcknowledged(tester);
    },
  );

  testWidgets(
    'restored Received keeps item attention while My ZYRA consumes tab attention',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      final browse = checkpoint!;
      expect(browse.model.acknowledgedReceivedRequestIds, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await _mount(
        tester,
        checkpoint: browse,
        onCheckpoint: (value) => checkpoint = value,
      );
      expect(_myZyraUnread(tester), isTrue);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      final shortBrowse = checkpoint!;
      await tester.pumpWidget(const SizedBox.shrink());
      await _mount(
        tester,
        checkpoint: shortBrowse,
        restoreLocation: false,
        onCheckpoint: (value) => checkpoint = value,
      );
      expect(_navigation(tester).currentIndex, 2);
      expect(_myZyraUnread(tester), isFalse);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);

      await _nav(tester, 'My ZYRA');
      await _tap(tester, 'my-zyra-route-$_groupId');
      await _tap(tester, 'draft_requests_1');
      await openZyraDevControls(tester);
      await _tap(tester, 'concept_requests_controls_0');
      expect(checkpoint!.requestsTab, 0);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      final visibleReceived = checkpoint!;
      await tester.pumpWidget(const SizedBox.shrink());
      await _mount(
        tester,
        checkpoint: visibleReceived,
        onCheckpoint: (value) => checkpoint = value,
      );
      expect(_key('concept_activity_requests'), findsOneWidget);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await _viewRequest(tester);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
      await returnZyraPreviewPage(tester);
      _expectAcknowledged(tester);
    },
  );

  testWidgets('item-specific acknowledgment survives short and long restore', (
    tester,
  ) async {
    ZyraPreviewNavigationCheckpoint? checkpoint;
    await _mount(tester, onCheckpoint: (value) => checkpoint = value);
    await _nav(tester, 'My ZYRA');
    await _tap(tester, 'my-zyra-route-$_groupId');
    expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
    await _viewRequest(tester);
    expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
    final saved = checkpoint!;
    await tester.pumpWidget(const SizedBox.shrink());
    await _mount(
      tester,
      checkpoint: saved,
      onCheckpoint: (value) => checkpoint = value,
    );
    expect(_key('concept_activity_requests'), findsOneWidget);
    await returnZyraPreviewPage(tester);
    _expectAcknowledged(tester);

    final later = checkpoint!;
    await tester.pumpWidget(const SizedBox.shrink());
    await _mount(
      tester,
      checkpoint: later,
      restoreLocation: false,
      onCheckpoint: (value) => checkpoint = value,
    );
    expect(_navigation(tester).currentIndex, 2);
    expect(_myZyraUnread(tester), isFalse);
    expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
    await _nav(tester, 'My ZYRA');
    _expectAcknowledged(tester);
  });

  testWidgets(
    'Reset/reseed is new; hidden Browse request stays visible and block filters it',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      await _nav(tester, 'My ZYRA');
      await _tap(tester, 'my-zyra-route-$_groupId');
      await _viewRequest(tester);
      await returnZyraPreviewPage(tester);
      _expectAcknowledged(tester);

      await openZyraDevControls(tester);
      await _tap(tester, 'draft_reset');
      if (_key('dev_controls_page').evaluate().isNotEmpty) {
        await closeZyraDevControls(tester);
      }
      expect(_myZyraUnread(tester), isTrue);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await _nav(tester, 'My ZYRA');
      _expectNew(tester);

      // The Journey preview control reseeds this disposable model. Its new
      // sample invitation must restore the same sourced navigation attention.
      await _nav(tester, 'Journey');
      await openZyraDevControls(tester);
      await _tap(tester, 'concept_journey_preview_1');
      if (_key('dev_controls_page').evaluate().isNotEmpty) {
        await closeZyraDevControls(tester);
      }
      expect(_myZyraUnread(tester), isTrue);
      await _nav(tester, 'My ZYRA');
      _expectNew(tester);
      await _nav(tester, 'Profiles');
      for (var attempt = 0; attempt < 8; attempt++) {
        final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
          find.byType(ZyraOneJourneyBrowseDesigns),
        );
        if (browse.profiles[browse.selectedIndex].id == _requestId) break;
        await _tap(tester, 'concept_next_profile');
      }
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      expect(browse.profiles[browse.selectedIndex].id, _requestId);
      await _tap(tester, 'concept_browse_menu');
      await _nav(tester, 'Report');
      expect(_key('draft_safety_hide'), findsOneWidget);
      await _tap(tester, 'draft_safety_hide');
      await _nav(tester, 'My ZYRA');
      _expectNew(tester);
      expect(_card(tester, _groupId).detail, '1 received · 0 sent');
    },
  );

  testWidgets('blocking filters the request without rewriting its record', (
    tester,
  ) async {
    ZyraPreviewNavigationCheckpoint? checkpoint;
    await _mount(tester, onCheckpoint: (value) => checkpoint = value);
    for (var attempt = 0; attempt < 8; attempt++) {
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      if (browse.profiles[browse.selectedIndex].id == _requestId) break;
      await _tap(tester, 'concept_next_profile');
    }
    final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );
    expect(browse.profiles[browse.selectedIndex].id, _requestId);
    await _tap(tester, 'concept_browse_menu');
    await _nav(tester, 'Report');
    await _tap(tester, 'draft_safety_block');
    expect(checkpoint!.model.states[_requestId], DraftJourneyState.received);
    expect(checkpoint!.model.blockedPeers, contains(_requestId));
    expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
    expect(_myZyraUnread(tester), isFalse);
    await _nav(tester, 'My ZYRA');
    expect(
      _dashboard(tester).fixtureCards.map((card) => card.id),
      isNot(contains(_leadId)),
    );
    expect(_card(tester, _groupId).detail, '0 received · 0 sent');
    expect(_card(tester, 'concept-my-introductions').detail, '0 introductions');
    expect(_card(tester, 'concept-my-ended').detail, '0 ended');
    expect(_key('my-zyra-new-$_groupId'), findsNothing);
    expect(_dashboard(tester).permanentNavigation, isTrue);
    expect(find.text('Quick access'), findsOneWidget);
    // Filtering every request does not remove the three permanent links.
    for (final destination in [
      (id: _groupId, page: 'requests'),
      (id: 'concept-my-introductions', page: 'introductions'),
      (id: 'concept-my-ended', page: 'ended'),
    ]) {
      await _tap(tester, 'my-zyra-route-${destination.id}');
      expect(_key('concept_activity_${destination.page}'), findsOneWidget);
      expect(checkpoint!.model.states[_requestId], DraftJourneyState.received);
      expect(checkpoint!.model.blockedPeers, contains(_requestId));
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await returnZyraPreviewPage(tester);
      expect(_card(tester, _groupId).detail, '0 received · 0 sent');
    }
  });

  testWidgets(
    'covered, role-changed and revoked retained dashboard actions cannot acknowledge',
    (tester) async {
      ZyraPreviewNavigationCheckpoint? checkpoint;
      await _mount(tester, onCheckpoint: (value) => checkpoint = value);
      await _nav(tester, 'My ZYRA');
      final retained = _dashboard(tester).onNavigate!;
      final addressed = _card(tester, _leadId);
      await openZyraDevControls(tester);
      retained(addressed);
      await tester.pump();
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      await closeZyraDevControls(tester);
      _expectNew(tester);

      await openZyraDevControls(tester);
      await _tap(tester, 'draft_role_guardian');
      retained(addressed);
      await tester.pumpAndSettle();
      expect(checkpoint!.guardian, isTrue);
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      retained(addressed);
      await tester.pumpAndSettle();
      expect(checkpoint!.model.acknowledgedReceivedRequestIds, isEmpty);
      expect(_key('concept_activity_requests'), findsNothing);
    },
  );

  testWidgets('compact 200% unread state stays readable without item dots', (
    tester,
  ) async {
    ZyraPreviewNavigationCheckpoint? checkpoint;
    await _mount(
      tester,
      size: const Size(320, 568),
      textScale: 2,
      onCheckpoint: (value) => checkpoint = value,
    );
    await _nav(tester, 'My ZYRA');
    _expectNew(tester, groupMounted: false);
    final scroll = find.descendant(
      of: _key('my-zyra-quiet-scroll-0'),
      matching: find.byType(Scrollable),
    );
    expect(scroll, findsOneWidget);
    await tester.scrollUntilVisible(
      _key('my-zyra-route-$_groupId'),
      150,
      scrollable: scroll,
    );
    await tester.pumpAndSettle();
    expect(_key('my-zyra-route-$_groupId'), findsOneWidget);
    expect(_key('my-zyra-new-$_groupId'), findsNothing);
    expect(_card(tester, _groupId).detail, '1 received · 0 sent');
    await _capture(tester, '03-new-compact-320-200');
    // The upper temporary highlight may have been recycled while reading
    // Quick access. Return through the actual scroll owner before tapping it.
    tester.state<ScrollableState>(scroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(_key('my-zyra-activity-$_leadId'), findsOneWidget);
    expect(_key('my-zyra-new-$_leadId'), findsNothing);
    expect(find.text('Journey request from Amira'), findsOneWidget);
    await _tap(tester, 'my-zyra-route-$_leadId');
    expect(checkpoint!.model.acknowledgedReceivedRequestIds, {_requestId});
    expect(checkpoint!.model.states[_requestId], DraftJourneyState.received);
    expect(checkpoint!.requestsTab, 0);
    await returnZyraPreviewPage(tester);
    _expectAcknowledged(tester);
    await _capture(tester, '04-acknowledged-compact-320-200');
  });
}
