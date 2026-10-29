// Actual local-shell route coverage. Back uses only the existing caller-owned
// return, without granting navigation, disclosure or member-data access.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_circle_discussion_archive.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _sara = 'draft-sara';
// Optional evidence uses the existing assertions/routes, never skipped tests.
// Supply a fresh NONEXISTENT absolute folder; existing evidence is not replaced.
const _captureDirectory = String.fromEnvironment(
  'ZYRA_BOTTOM_CUE_ROUTE_CAPTURE_DIR',
);
const _captureFont = 'PoppinsBottomCueRoutes';
const _captureKey = ValueKey('bottom-cue-route-capture');
Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _back => _key('zyra_visible_back_button');

void _expectNoException(WidgetTester tester) {
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: exception is FlutterError
        ? exception.diagnostics.map((node) => node.toStringDeep()).join('\n')
        : null,
  );
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Bottom-close route fixtures must remain offline.');
  }
}

class _Owner {
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    int tab = 0,
    List<String> pages = const [],
    bool guardian = false,
    Size size = const Size(393, 852),
    double scale = 1,
  }) async {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(3);
    final ready = Completer<void>();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(
              top: size.height < 700 ? 44 : 59,
              bottom: 34,
            ),
            viewPadding: EdgeInsets.only(
              top: size.height < 700 ? 44 : 59,
              bottom: 34,
            ),
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: RepaintBoundary(key: _captureKey, child: child!),
        ),
        home: ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => true,
          onExit: () => fail('A page return must not exit the shell.'),
          initialGuardianRole: guardian,
          initialCheckpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: model.snapshot(),
            tab: tab,
            pages: pages,
            personId: _sara,
          ),
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    // Bundled JPEG decoding is a real asynchronous operation, not fake-clock
    // time. Wait for the shell's existing prepared first-frame publication.
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue);
    await tester.pumpAndSettle();
    _expectNoException(tester);
    expect(checkpoints, isNotEmpty);
  }
}

Future<void> _pressFinder(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  _expectNoException(tester);
}

Future<void> _press(WidgetTester tester, String id) =>
    _pressFinder(tester, _key(id));

Future<void> _nav(WidgetTester tester, int index) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final nav = find.byType(ZyraShellNavigation);
  expect(nav, findsOneWidget);
  final navigation = tester.widget<ZyraShellNavigation>(nav);
  final item = navigation.items[index];
  final icon = find.descendant(
    of: nav,
    matching: item.useJourneyGlyph
        ? find.byType(ZyraJourneyIcon)
        : find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  final bar = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(bar.hitTestable(), findsOneWidget);
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  _expectNoException(tester);
}

void _oneBack(WidgetTester tester) {
  expect(_back, findsNothing);
  expect(find.text('Back'), findsNothing);
  expect(_key('zyra_back_header_space'), findsNothing);
  // A Navigator leaf may expose its ancestor's guarded return through an
  // inherited accessibility bridge. Those nodes share one authority; the
  // physical edge remains singular and the admitted leaf action is present.
  expect(_key('zyra_pull_down_back_semantics'), findsWidgets);
  expect(captureZyraAccessibleBack(tester), isA<VoidCallback>());
  expect(_key('zyra_back_swipe_edge'), findsOneWidget);
  expect(_key('zyra_pull_down_bottom_cue'), findsNothing);
  expect(_key('zyra_pull_down_close_hint'), findsNothing);
  final bounds = tester.getRect(_key('zyra_back_swipe_edge'));
  final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(bounds.width, greaterThan(0));
  expect(bounds.height, greaterThan(0));
  expect(bounds.left, greaterThanOrEqualTo(0));
  expect(bounds.right, lessThanOrEqualTo(viewport.width));
  expect(bounds.top, greaterThanOrEqualTo(0));
  expect(bounds.bottom, lessThanOrEqualTo(viewport.height));
}

Future<void> _downwardHeader(WidgetTester tester) async {
  final scope = find.byType(ZyraPullDownBackScope).last;
  expect(scope, findsOneWidget);
  final rect = tester.getRect(scope);
  await tester.timedDragFrom(
    Offset(rect.left + 80, rect.top + 100),
    const Offset(0, 230),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  _expectNoException(tester);
}

Future<void> _returnHeader(WidgetTester tester) async {
  final scope = find.byType(ZyraPullDownBackScope).last;
  expect(scope, findsOneWidget);
  if (!tester.widget<ZyraPullDownBackScope>(scope).enabled) {
    expect(_back, findsNothing);
    await _downwardHeader(tester);
    return;
  }
  await swipeZyraBack(tester);
}

Future<void> _selectCircleTopic(
  WidgetTester tester,
  String id, {
  bool past = false,
}) async {
  await _pressFinder(tester, _key('circle_discuss_floatingButton'));
  expect(find.byType(ZyraCircleTopicPicker), findsOneWidget);
  await _press(tester, 'circle_topic_tab_${past ? 1 : 0}');
  await _press(tester, 'circle_topic_$id');
  expect(find.byType(ZyraCircleTopicPicker), findsNothing);
  expect(_key('circle_pending_discussion_topic_$id'), findsOneWidget);
  expect(_key('circle_discussion_bubble_$id'), findsNothing);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _mountCompletedHistory(
  WidgetTester tester, {
  required Size size,
  required double scale,
  required VoidCallback onBack,
  required VoidCallback onTimeline,
  bool reduce = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: EdgeInsets.only(
            top: size.height < 700 ? 44 : 59,
            bottom: 34,
          ),
          viewPadding: EdgeInsets.only(
            top: size.height < 700 ? 44 : 59,
            bottom: 34,
          ),
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduce,
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: Scaffold(
        backgroundColor: ZyraColors.luxuryDarkPurple,
        body: ZyraPullDownBackScope(
          routeIdentity: ('completed-history', size, scale),
          onBack: onBack,
          child: ZyraConceptJourneyPresentation(
            firstName: 'Sara',
            stage: ZyraJourneyStages.of('compatibility_reveal')!,
            localActionBody: const SizedBox.shrink(),
            showBackButton: false,
            onBack: onBack,
            onTimeline: onTimeline,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  _expectNoException(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late String? oldReadingFont;
  late ZyraHapticLevel oldHaptics;
  late List<Object?> beforeMember;

  List<Object?> memberState() => [
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.photos),
    AppState.instance.plan,
  ];

  setUpAll(() async {
    if (_captureDirectory.isNotEmpty) {
      if (!_captureDirectory.startsWith('/') ||
          FileSystemEntity.typeSync(_captureDirectory, followLinks: false) !=
              FileSystemEntityType.notFound) {
        throw StateError(
          'Bottom-cue route captures require a fresh nonexistent absolute folder.',
        );
      }
      Directory(_captureDirectory).createSync(recursive: true);
    }
    // The compact readability cases use actual bundled metrics even without
    // screenshot output; Ahem can make a long heading taller than its viewport.
    final reading = FontLoader(_captureFont);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = () async {};
    final gold = ZyraDevAppGold.instance;
    gold.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: gold.revision,
    );
    oldFontStubs = ZyraText.useTestFontStubs;
    oldReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    if (_captureDirectory.isNotEmpty) {
      ZyraText.testReadingFontFamily = _captureFont;
    }
    oldHaptics = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    beforeMember = memberState();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    expect(network.attempts, 0);
    expect(memberState(), beforeMember);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraText.testReadingFontFamily = oldReadingFont;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} root tabs have no Back return',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, guardian: guardian);
        for (var tab = 0; tab < (guardian ? 4 : 5); tab++) {
          await _nav(tester, tab);
          expect(owner.latest.pages, isEmpty);
          expect(_back, findsNothing);
          expect(find.byType(ZyraPullDownBackScope), findsNothing);
        }
      },
    );
  }

  testWidgets('expanded inline Journey options do not claim full-page close', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(tester, tab: 1);
    await _press(tester, 'draft_journey_options_$_sara');
    expect(find.byType(ZyraConceptJourneyOptions), findsOneWidget);
    expect(_key('concept_expanded_journey_$_sara'), findsOneWidget);
    expect(find.byType(ZyraShellNavigation), findsOneWidget);
    expect(find.byType(ZyraPullDownBackScope), findsOneWidget);
    expect(_back, findsNothing);
    await _press(tester, 'draft_journey_options_$_sara');
    expect(find.byType(ZyraConceptJourneyOptions), findsNothing);
    expect(_back, findsNothing);
  });

  for (final route in [
    (page: 'settings', tab: 4),
    (page: 'personalisation', tab: 4),
    (page: 'own_profile_preview', tab: 4),
    (page: 'requests', tab: 2),
    (page: 'timeline', tab: 1),
    (page: 'journey_guardians', tab: 1),
  ]) {
    testWidgets('${route.page} has one edge return without a Back button', (
      tester,
    ) async {
      final owner = _Owner();
      await owner.mount(tester, tab: route.tab, pages: [route.page]);
      expect(owner.latest.pages, [route.page]);
      expect(find.byType(ZyraShellNavigation), findsNothing);
      _oneBack(tester);
      if (route.page == 'timeline' || route.page == 'own_profile_preview') {
        await _capture(tester, route.page);
      }
      await _downwardHeader(tester);
      expect(owner.latest.pages, [route.page]);
      _oneBack(tester);
      await _returnHeader(tester);
      expect(owner.latest.pages, isEmpty);
      expect(find.byType(ZyraShellNavigation), findsOneWidget);
      expect(_back, findsNothing);
    });
  }

  for (final option in ['bio', 'compatibility']) {
    testWidgets(
      'locked $option explanation inherits one edge return without disclosure',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, tab: 1);
        await _press(tester, 'draft_journey_options_$_sara');
        await _press(tester, 'draft_options_${option}_$_sara');
        final page = option == 'bio' ? 'bio' : 'journey_compatibility';
        expect(_key('draft_${page}_locked_$_sara'), findsOneWidget);
        expect(owner.latest.pages, ['${page}_locked']);
        expect(_key('draft_journey_bio_about'), findsNothing);
        expect(_key('draft_journey_compatibility_$_sara'), findsNothing);
        _oneBack(tester);
        if (option == 'bio') await _capture(tester, 'locked_bio');
        await _returnHeader(tester);
        expect(owner.latest.pages, isEmpty);
        expect(_back, findsNothing);
      },
    );
  }

  testWidgets(
    'sensitive End Journey confirmation has no Back return or pull grant',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, tab: 1);
      await _press(tester, 'draft_journey_options_$_sara');
      await _press(tester, 'draft_options_end_$_sara');
      expect(_key('draft_journey_action_$_sara'), findsOneWidget);
      expect(_back, findsNothing);
      expect(
        tester
            .widget<ZyraPullDownBackScope>(find.byType(ZyraPullDownBackScope))
            .enabled,
        isFalse,
      );
      await _returnHeader(tester);
      expect(_key('draft_journey_action_$_sara'), findsOneWidget);
      expect(_back, findsNothing);
      await _press(tester, 'draft_cancel_end_$_sara');
      expect(_key('draft_journey_action_$_sara'), findsNothing);
      expect(
        find.byType(ZyraOneJourneyConnectionsActiveCard),
        findsNWidgets(3),
      );
      expect(_back, findsNothing);
    },
  );

  for (final past in [false, true]) {
    testWidgets(
      'Circle ${past ? 'archive' : 'profile'} child keeps one edge return with an accessible bridge',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, tab: 3, pages: ['guardian_circle']);
        expect(find.byType(ZyraGuardianCircleScreen), findsOneWidget);
        final circle = tester.state(find.byType(ZyraGuardianCircleScreen));
        _oneBack(tester);
        if (!past) await _capture(tester, 'circle_composer');
        final topic = past ? 'draft-circle-past-0' : _sara;
        await _selectCircleTopic(tester, topic, past: past);
        final composer = find.descendant(
          of: _key('guardian-circle-composer'),
          matching: find.byType(TextField),
        );
        final sentBody =
            'A sent discussion before viewing the ${past ? 'archive' : 'profile'}';
        await tester.enterText(composer, sentBody);
        await _pressFinder(tester, find.byTooltip('Send message'));
        expect(_key('circle_pending_discussion_topic'), findsNothing);
        expect(_key('circle_discussion_bubble_$topic'), findsOneWidget);
        expect(find.text(sentBody), findsOneWidget);
        _oneBack(tester);
        await _press(
          tester,
          'circle_discussion_${past ? 'journey' : 'profile'}_$topic',
        );
        expect(
          past
              ? find.byType(ZyraCircleDiscussionArchiveView)
              : find.byType(SeekerProfileScreen),
          findsOneWidget,
        );
        _oneBack(tester);
        await _capture(tester, past ? 'circle_archive' : 'circle_profile');
        await _returnHeader(tester);
        expect(find.byType(ZyraCircleDiscussionArchiveView), findsNothing);
        expect(find.byType(SeekerProfileScreen), findsNothing);
        expect(
          tester.state(find.byType(ZyraGuardianCircleScreen)),
          same(circle),
        );
        expect(owner.latest.pages, ['guardian_circle']);
        _oneBack(tester);
        await _returnHeader(tester);
        expect(owner.latest.pages, isEmpty);
        expect(_back, findsNothing);
      },
    );
  }

  testWidgets(
    'compact double-text standalone Introductions has no Back strip and keeps its title readable',
    (tester) async {
      ZyraText.testReadingFontFamily = _captureFont;
      final owner = _Owner();
      await owner.mount(
        tester,
        tab: 2,
        pages: ['introductions'],
        size: const Size(320, 568),
        scale: 2,
      );
      _oneBack(tester);
      final requests = tester.widget<ZyraRequestActivityPresentation>(
        _key('concept_activity_introductions'),
      );
      expect(requests.selectedIndex, 0);
      expect(requests.title, 'Introductions');
      expect(requests.pages, hasLength(1));
      expect(find.byType(PageView), findsNothing);
      expect(owner.latest.requestsTab, 0);
      expect(owner.latest.pages, ['introductions']);
      final title = find.text('No introductions yet');
      expect(title, findsOneWidget);
      await Scrollable.ensureVisible(tester.element(title), alignment: .5);
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(title.hitTestable(), findsOneWidget);
      expect(
        find.text('People your Guardians put forward will appear here.'),
        findsOneWidget,
      );
      _oneBack(tester);
      final titleRect = tester.getRect(title);
      await _capture(tester, 'compact_intro');
      expect(titleRect.left, greaterThanOrEqualTo(20));
      expect(titleRect.right, lessThanOrEqualTo(300));
      expect(titleRect.top, greaterThanOrEqualTo(44));
      expect(_key('zyra_back_header_space'), findsNothing);
      await _returnHeader(tester);
      expect(owner.latest.pages, isEmpty);
      expect(_back, findsNothing);
    },
  );

  testWidgets(
    'compact double-text locked Bio continues to the real Salam arrival without overflow',
    (tester) async {
      ZyraText.testReadingFontFamily = _captureFont;
      final owner = _Owner();
      await owner.mount(tester, tab: 1, size: const Size(320, 568), scale: 2);
      await _press(tester, 'draft_journey_options_$_sara');
      await _press(tester, 'draft_options_bio_$_sara');
      expect(_key('draft_bio_locked_$_sara'), findsOneWidget);
      expect(_key('draft_journey_bio_about'), findsNothing);
      _oneBack(tester);
      await _press(tester, 'draft_disclosure_continue_$_sara');
      expect(owner.latest.pages, ['bio_locked', 'journey']);
      expect(_key('draft_bio_locked_$_sara'), findsNothing);
      final journey = tester.widget<ZyraConceptJourneyPresentation>(
        find.byType(ZyraConceptJourneyPresentation),
      );
      expect(journey.stage.value, 'salam_exchange');
      expect(
        tester
            .widget<PageView>(_key('concept_current_journey_pages'))
            .controller!
            .page,
        closeTo(0, .01),
      );
      expect(_key('concept_journey_arrival_body'), findsOneWidget);
      final title = find.text('Let’s begin');
      expect(title, findsOneWidget);
      await Scrollable.ensureVisible(tester.element(title), alignment: .5);
      await tester.pumpAndSettle();
      _expectNoException(tester);
      final body = _key('concept_journey_arrival_body');
      final bodyBounds = tester.getRect(body);
      final titleBounds = tester.getRect(title);
      expect(titleBounds.top, greaterThanOrEqualTo(bodyBounds.top));
      expect(titleBounds.bottom, lessThanOrEqualTo(bodyBounds.bottom));
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: body, matching: find.byType(Scrollable)).first,
      );
      final titleOffset = scrollable.position.pixels;
      await _capture(tester, 'compact_salam_arrival');
      expect(title.hitTestable(), findsOneWidget);
      expect(_key('draft_journey_bio_about'), findsNothing);
      _oneBack(tester);
      // In the compact natural reader, title and next-stage control remain
      // independently reachable by scrolling; no tiny clipped reading window.
      final continueCue = _key('concept_journey_arrival_continue');
      expect(
        find.descendant(of: body, matching: continueCue),
        findsOneWidget,
        reason: 'Compact reading and Continue must share the natural reader.',
      );
      await Scrollable.ensureVisible(tester.element(continueCue), alignment: 1);
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(continueCue.hitTestable(), findsOneWidget);
      final downCue = tester.getRect(_key('concept_journey_arrival_continue'));
      expect(downCue.top, greaterThanOrEqualTo(bodyBounds.top));
      expect(downCue.bottom, lessThanOrEqualTo(bodyBounds.bottom));
      expect(_key('zyra_back_header_space'), findsNothing);
      expect(scrollable.position.pixels, greaterThan(titleOffset + 20));
      await _capture(tester, 'compact_salam_continue');
      final startingOffset = scrollable.position.pixels;
      expect(
        startingOffset,
        greaterThan(scrollable.position.minScrollExtent + .5),
        reason: 'This regression must begin inside the scrolled arrival body.',
      );
      await tester.timedDragFrom(
        Offset(bodyBounds.left + 20, bodyBounds.center.dy),
        const Offset(0, 60),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(owner.latest.pages, ['bio_locked', 'journey']);
      expect(
        ViewRequestDraftModel.fromSnapshot(
          owner.latest.model,
        ).stageFor(_sara)?.value,
        'salam_exchange',
      );
      expect(
        tester
            .widget<PageView>(_key('concept_current_journey_pages'))
            .controller!
            .page,
        closeTo(0, .01),
      );
      expect(scrollable.position.pixels, lessThanOrEqualTo(startingOffset));
      _oneBack(tester);
      await _returnHeader(tester);
      expect(owner.latest.pages, ['bio_locked']);
      expect(_key('draft_bio_locked_$_sara'), findsOneWidget);
      _oneBack(tester);
    },
  );

  testWidgets(
    'compact completed-history reading stays in its stage until a real bottom pull',
    (tester) async {
      ZyraText.testReadingFontFamily = _captureFont;
      var returns = 0;
      var timelineOpens = 0;
      await _mountCompletedHistory(
        tester,
        size: const Size(320, 568),
        scale: 2,
        onBack: () => returns++,
        onTimeline: () => timelineOpens++,
      );
      final visualPageController = tester
          .widget<PageView>(_key('concept_current_journey_pages'))
          .controller!;
      visualPageController.jumpToPage(0);
      await tester.pumpAndSettle();
      _expectNoException(tester);
      final reader = _key('concept_completed_stage_reader_salam_exchange');
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: reader, matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(100));
      scrollable.position.jumpTo(20);
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(scrollable.position.pixels, closeTo(20, .01));
      expect(
        scrollable.position.maxScrollExtent - scrollable.position.pixels,
        greaterThan(80),
      );
      final readerBounds = tester.getRect(reader);
      final finger = await tester.startGesture(
        Offset(readerBounds.left + 20, readerBounds.center.dy),
      );
      // A real slow reading gesture, with a resting release to avoid a fling
      // accidentally reaching the bottom and exercising a different contract.
      for (var step = 0; step < 6; step++) {
        await finger.moveBy(const Offset(0, -10));
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.pump(const Duration(milliseconds: 200));
      await finger.up();
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(scrollable.position.pixels, greaterThan(20));
      expect(
        scrollable.position.pixels,
        lessThan(scrollable.position.maxScrollExtent),
      );
      expect(visualPageController.page, closeTo(0, .01));
      expect(
        tester
            .widget<ZyraConceptJourneyPresentation>(
              find.byType(ZyraConceptJourneyPresentation),
            )
            .stage
            .value,
        'compatibility_reveal',
      );
      expect(returns, 0);
      expect(timelineOpens, 0);
      _oneBack(tester);
      // Only a genuine upward pull begun at the actual end hands traversal
      // back to the existing boundary-aware stage pager. No grant is created.
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(visualPageController.page, closeTo(0, .01));
      expect(returns, 0);
      expect(timelineOpens, 0);
      expect(
        scrollable.position.pixels,
        closeTo(scrollable.position.maxScrollExtent, .01),
      );
      await tester.timedDragFrom(
        Offset(readerBounds.left + 20, readerBounds.center.dy),
        const Offset(0, -120),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(visualPageController.page, closeTo(1, .01));
      expect(
        tester
            .widget<ZyraConceptJourneyPresentation>(
              find.byType(ZyraConceptJourneyPresentation),
            )
            .stage
            .value,
        'compatibility_reveal',
      );
      expect(returns, 0);
      expect(timelineOpens, 0);
      _oneBack(tester);
    },
  );

  for (final reduce in [false, true]) {
    testWidgets(
      'fitting history still physically advances after action-page return reduce=$reduce',
      (tester) async {
        ZyraText.testReadingFontFamily = _captureFont;
        var returns = 0;
        var timelineOpens = 0;
        await _mountCompletedHistory(
          tester,
          size: const Size(393, 852),
          scale: 1,
          reduce: reduce,
          onBack: () => returns++,
          onTimeline: () => timelineOpens++,
        );
        final visualPageController = tester
            .widget<PageView>(_key('concept_current_journey_pages'))
            .controller!;
        await _press(tester, 'concept_journey_arrival_continue');
        expect(visualPageController.page, closeTo(2, .01));
        // Return the disposable visual controller to completed history; this
        // does not alter the supplied stage or establish any model permission.
        visualPageController.jumpToPage(0);
        await tester.pumpAndSettle();
        _expectNoException(tester);
        final reader = _key('concept_completed_stage_reader_salam_exchange');
        final scrollable = tester.state<ScrollableState>(
          find.descendant(of: reader, matching: find.byType(Scrollable)).first,
        );
        expect(scrollable.position.maxScrollExtent, closeTo(0, .01));
        final bounds = tester.getRect(reader);
        await tester.timedDragFrom(
          Offset(bounds.left + 20, bounds.center.dy),
          const Offset(0, -180),
          const Duration(milliseconds: 160),
        );
        await tester.pumpAndSettle();
        _expectNoException(tester);
        expect(visualPageController.page, closeTo(1, .01));
        expect(
          tester
              .widget<ZyraConceptJourneyPresentation>(
                find.byType(ZyraConceptJourneyPresentation),
              )
              .stage
              .value,
          'compatibility_reveal',
        );
        expect(returns, 0);
        expect(timelineOpens, 0);
        _oneBack(tester);
      },
    );
  }

  for (final viewport in const [
    (size: Size(393, 852), scale: 1.0, suffix: ''),
    (size: Size(320, 568), scale: 2.0, suffix: '_compact'),
  ]) {
    testWidgets(
      'completed history traversal stays clear of Back${viewport.suffix}',
      (tester) async {
        ZyraText.testReadingFontFamily = _captureFont;
        var returns = 0;
        var timelineOpens = 0;
        await _mountCompletedHistory(
          tester,
          size: viewport.size,
          scale: viewport.scale,
          onBack: () => returns++,
          onTimeline: () => timelineOpens++,
        );
        final pages = _key('concept_current_journey_pages');
        final visualPageController = tester.widget<PageView>(pages).controller!;
        expect(visualPageController.page, closeTo(1, .01));
        // This changes visual history position only. There is no DraftModel,
        // disclosure grant, stage completion or live Journey adapter here.
        visualPageController.jumpToPage(0);
        await tester.pumpAndSettle();
        _expectNoException(tester);
        expect(visualPageController.page, closeTo(0, .01));
        expect(
          tester
              .widget<ZyraConceptJourneyPresentation>(
                find.byType(ZyraConceptJourneyPresentation),
              )
              .stage
              .value,
          'compatibility_reveal',
        );
        expect(find.text('Salam exchanged.'), findsOneWidget);
        final label = find.text('Stage 2 below');
        expect(label, findsOneWidget);
        final traversal = find
            .ancestor(of: label, matching: find.byType(InkWell))
            .first;
        expect(traversal.hitTestable(), findsOneWidget);
        _oneBack(tester);
        final labelRect = tester.getRect(label);
        final traversalRect = tester.getRect(traversal);
        expect(labelRect.top, greaterThanOrEqualTo(0));
        expect(traversalRect.top, greaterThanOrEqualTo(0));
        expect(_key('zyra_back_header_space'), findsNothing);
        expect(returns, 0);
        expect(timelineOpens, 0);
        await _capture(tester, 'completed_history${viewport.suffix}');
        // The existing stage-history control still advances only the view.
        await _pressFinder(tester, traversal);
        expect(visualPageController.page, closeTo(1, .01));
        expect(returns, 0);
        expect(timelineOpens, 0);
        _oneBack(tester);
      },
    );
  }

  testWidgets(
    'small double-text Settings keeps edge return without a Back strip',
    (tester) async {
      final owner = _Owner();
      await owner.mount(
        tester,
        tab: 4,
        pages: ['settings'],
        size: const Size(320, 568),
        scale: 2,
      );
      _oneBack(tester);
      await _capture(tester, 'compact_double_text_settings');
      await _returnHeader(tester);
      expect(owner.latest.pages, isEmpty);
      expect(_back, findsNothing);
    },
  );
}
