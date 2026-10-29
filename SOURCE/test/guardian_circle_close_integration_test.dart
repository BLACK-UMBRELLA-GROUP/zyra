// Actual admitted local shell/Circle wiring; no live chat, account or writes.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsCircleCloseIntegration';
const _captures = String.fromEnvironment('ZYRA_CIRCLE_CLOSE_CAPTURE_DIR');
const _captureKey = ValueKey('circle-close-integration-capture');

Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _circle => find.byType(ZyraGuardianCircleScreen);
Finder get _hint => _key('zyra_pull_down_close_hint');
Finder get _composer => find.descendant(
  of: _key('guardian-circle-composer'),
  matching: find.byType(TextField),
);
Finder get _bubbleDropdown =>
    find.byType(DropdownButtonFormField<ZyraCircleBubbleDesign>);
Finder get _backButton => _key('zyra_visible_back_button');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Circle close integration is a bounded offline fixture.');
  }
}

Widget _app(Widget screen, {double scale = 1, bool reduce = true}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: ZyraColors.isLightPalette
            ? Brightness.light
            : Brightness.dark,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduce,
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: screen,
    );

Future<void> _mount(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(393, 852),
  double scale = 1,
  bool reduce = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(screen, scale: scale, reduce: reduce));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _mountShell(
  WidgetTester tester, {
  bool guardian = false,
  Size size = const Size(393, 852),
  double scale = 1,
  bool reduce = true,
}) async {
  await _mount(
    tester,
    ViewRequestDraftScreen(
      ownerGeneration: ZyraAccountState.generation,
      ownerId: ZyraAccountState.userId,
      initialGuardianRole: guardian,
      onExit: () => fail('Circle close must not exit the app preview.'),
    ),
    size: size,
    scale: scale,
    reduce: reduce,
  );
  if (!guardian) {
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final target = find.byType(ZyraOneJourneyBrowseDesigns);
        if (target.evaluate().isNotEmpty) {
          final deck = tester.widget<ZyraOneJourneyBrowseDesigns>(target);
          if (deck.profiles.isNotEmpty &&
              deck.profiles.every((person) => person.photos.isNotEmpty)) {
            return;
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
      }
      fail('The bundled local Browse deck did not prepare.');
    });
    await tester.pumpAndSettle();
  }
}

Future<void> _press(WidgetTester tester, Finder target) async {
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
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final nav = find.byType(FloatingNavBar);
  final cell = _key('floating-nav-item-$index');
  expect(nav, findsOneWidget);
  expect(cell, findsOneWidget);
  final box = tester.renderObject<RenderBox>(nav);
  final point = box.globalToLocal(tester.getCenter(cell));
  expect(
    nav.hitTestable(
      at: Alignment(
        point.dx * 2 / box.size.width - 1,
        point.dy * 2 / box.size.height - 1,
      ),
    ),
    findsOneWidget,
  );
  await tester.tapAt(tester.getCenter(cell));
  await tester.pumpAndSettle();
}

Future<void> _openCircle(WidgetTester tester, {bool guardian = false}) async {
  await _nav(tester, guardian ? 2 : 3);
  await _press(
    tester,
    _key(
      guardian
          ? 'seeker-family-chat-draft-self'
          : 'guardian-family-messages-top',
    ),
  );
  expect(_circle, findsOneWidget);
  final circle = tester.widget<ZyraGuardianCircleScreen>(_circle);
  expect(
    circle.previewData!.validFor('draft-self', viewerIsSeeker: !guardian),
    isTrue,
  );
  expect(circle.viewerIsSeeker, !guardian);
}

ZyraPullDownBackScope _onlyScope(WidgetTester tester) {
  expect(find.byType(ZyraPullDownBackScope), findsOneWidget);
  return tester.widget<ZyraPullDownBackScope>(
    find.byType(ZyraPullDownBackScope),
  );
}

void _expectOneHeaderBack() {
  expect(_backButton, findsNothing);
  expect(_key('zyra_back_swipe_edge'), findsOneWidget);
  expect(find.byType(BackButton), findsNothing);
}

void _expectNoLegacyHint() {
  expect(_hint, findsNothing);
  expect(find.text('Pull down to close'), findsNothing);
  expect(find.text('Release to close'), findsNothing);
}

void _expectNoLegacyControl() {
  expect(find.text('Back navigation'), findsNothing);
  expect(find.text('Close gesture'), findsNothing);
}

void _expectReturn(WidgetTester tester) {
  expect(_onlyScope(tester).enabled, isTrue);
  expect(_backButton, findsNothing);
  expect(_key('zyra_back_swipe_edge'), findsOneWidget);
  expect(_key('zyra_pull_down_bottom_cue'), findsNothing);
  _expectNoLegacyHint();
}

void _expectCircleParent({required bool guardian}) {
  expect(_circle, findsNothing);
  expect(
    _key(
      guardian
          ? 'seeker-family-chat-draft-self'
          : 'guardian-family-messages-top',
    ),
    findsOneWidget,
  );
}

VoidCallback _dismiss(WidgetTester tester) => tester
    .widget<Semantics>(_key('zyra_pull_down_back_semantics'))
    .properties
    .onDismiss!;

Future<void> _openOptions(WidgetTester tester) async {
  await toggleZyraDevControls(tester);
  expect(find.text('Page options'), findsOneWidget);
  expect(
    tester.widget<Text>(_key('concept_page_options_context')).data,
    'Guardian Circle',
  );
}

Future<void> _selectPopup(
  WidgetTester tester,
  Finder dropdown,
  String itemKey,
) async {
  await _press(tester, dropdown);
  final popup = find.byElementPredicate(
    (element) =>
        element.widget is Scrollable &&
        (ModalRoute.of(element)?.isCurrent ?? false),
  );
  expect(popup, findsOneWidget);
  final item = find.descendant(of: popup, matching: _key(itemKey));
  await _press(
    tester,
    find.ancestor(of: item, matching: find.byType(InkWell)).first,
  );
}

Future<void> _setBubbleDesign(
  WidgetTester tester,
  ZyraCircleBubbleDesign design,
) async {
  await _openOptions(tester);
  _expectNoLegacyControl();
  await _selectPopup(
    tester,
    _bubbleDropdown,
    'concept_circle_bubble_design_${design.name}',
  );
  await toggleZyraDevControls(tester);
  expect(find.text('Page options'), findsNothing);
  _expectReturn(tester);
}

Future<TestGesture> _holdEdge(
  WidgetTester tester, {
  double distance = 60,
}) async {
  final rect = tester.getRect(_key('zyra_back_swipe_edge'));
  final finger = await tester.startGesture(
    Offset(rect.left + 8, rect.top + rect.height * .35),
  );
  for (var step = 0; step < 6; step++) {
    await finger.moveBy(Offset(distance / 6, 0));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 200));
  return finger;
}

Future<void> _swipeBack(WidgetTester tester) async {
  final edge = _key('zyra_back_swipe_edge');
  expect(edge, findsOneWidget);
  final rect = tester.getRect(edge);
  final finger = await tester.startGesture(
    Offset(rect.left + 8, rect.top + rect.height * .35),
  );
  await finger.moveBy(const Offset(35, 0));
  await tester.pump(const Duration(milliseconds: 100));
  await finger.moveBy(const Offset(155, 0));
  await tester.pump(const Duration(milliseconds: 200));
  expect(_circle, findsOneWidget);
  _expectNoLegacyHint();
  await finger.up();
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<TestGesture> _holdPull(
  WidgetTester tester, {
  double distance = 60,
}) async {
  final rect = tester.getRect(find.byType(ZyraPullDownBackScope));
  final finger = await tester.startGesture(
    Offset(rect.left + 32, rect.top + 210),
  );
  for (var step = 0; step < 6; step++) {
    await finger.moveBy(Offset(0, distance / 6));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 200));
  return finger;
}

int _transcriptLength(WidgetTester tester) =>
    (tester
                .widget<ListView>(
                  find.descendant(of: _circle, matching: find.byType(ListView)),
                )
                .childrenDelegate
            as SliverChildListDelegate)
        .children
        .length;

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$name.png');
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

class _StandaloneCircle {
  _StandaloneCircle() : layout = ValueNotifier(ZyraCircleBubbleDesign.current);
  final ValueNotifier<ZyraCircleBubbleDesign> layout;
  bool current = true;
  bool _current() => current;
  late final bool Function() canAct = _current;
  final data = ZyraGuardianCirclePreviewData(
    seekerId: 'draft-self',
    senderId: 'draft-self',
    canSend: true,
    participants: const [
      ZyraFamilyCircleParticipant(
        userId: 'draft-self',
        firstName: 'Adam',
        memberRole: 'seeker',
        isMainGuardian: false,
        isCurrentUser: true,
      ),
      ZyraFamilyCircleParticipant(
        userId: 'draft-guardian-hassan',
        firstName: 'Hassan',
        memberRole: 'guardian',
        isMainGuardian: true,
        isCurrentUser: false,
      ),
    ],
    messages: [
      ZyraFamilyMessage(
        id: 'draft-circle-existing',
        senderId: 'draft-self',
        senderFirstName: 'Adam',
        senderRoleLabel: 'Seeker',
        body: 'One unchanged Circle conversation.',
        createdAt: DateTime.utc(2026, 10, 14),
      ),
    ],
    contexts: const [],
  );

  Widget screen(VoidCallback back) => ZyraGuardianCircleScreen(
    seekerId: 'draft-self',
    seekerFirstName: 'Adam',
    viewerIsSeeker: true,
    preview: true,
    previewData: data,
    previewBubbleDesign: layout,
    canAct: canAct,
    onBack: back,
  );
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
    if (_captures.isNotEmpty &&
        (!_captures.startsWith('/') ||
            FileSystemEntity.typeSync(_captures, followLinks: false) !=
                FileSystemEntityType.directory ||
            Directory(_captures).resolveSymbolicLinksSync() !=
                Directory(_captures).path)) {
      throw StateError(
        'Circle close captures require an existing absolute nonlinked directory.',
      );
    }
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'ordinary-member-preference': 'keep',
    });
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    beforePreferences = preferenceState();
    beforeMember = memberState();
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
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    testWidgets(
      '$role starts with fixed floating entry and Back; reset restores interior defaults',
      (tester) async {
        await _mountShell(tester, guardian: guardian);
        await _openCircle(tester, guardian: guardian);
        expect(_key('circle_topic_bar'), findsNothing);
        expect(_key('circle_discuss_floatingButton'), findsOneWidget);
        expect(
          tester
              .widget<ZyraGuardianCircleScreen>(_circle)
              .previewBubbleDesign!
              .value,
          ZyraCircleBubbleDesign.current,
        );
        expect(_key('circle_topic_entry'), findsNothing);
        _expectOneHeaderBack();
        expect(
          _onlyScope(tester).key,
          const ValueKey('concept_pull_down_back_scope'),
        );
        _expectReturn(tester);
        await _capture(tester, 'circle-${role.toLowerCase()}-in-chat-default');
        await _openOptions(tester);
        _expectNoLegacyControl();
        await _selectPopup(
          tester,
          _bubbleDropdown,
          'concept_circle_bubble_design_current',
        );
        await _press(tester, _key('draft_reset'));
        // Reset preview intentionally returns to the existing Seeker role.
        await _openCircle(tester);
        expect(_key('circle_topic_bar'), findsNothing);
        expect(_key('circle_discuss_floatingButton'), findsOneWidget);
        expect(
          tester
              .widget<ZyraGuardianCircleScreen>(_circle)
              .previewBubbleDesign!
              .value,
          ZyraCircleBubbleDesign.current,
        );
        _expectReturn(tester);
        _expectOneHeaderBack();
      },
    );

    testWidgets(
      '$role the selected interior retains the exact conversation, then button and edge return once',
      (tester) async {
        await _mountShell(tester, guardian: guardian);
        await _openCircle(tester, guardian: guardian);
        const sent = 'A retained message in our one Circle.';
        await tester.enterText(_composer, sent);
        await _press(
          tester,
          find.descendant(
            of: _circle,
            matching: find.byTooltip('Send message'),
          ),
        );
        expect(find.text(sent), findsOneWidget);
        await tester.enterText(_composer, 'Keep this unsent Circle draft');
        final state = tester.state(_circle);
        final controller = tester.widget<TextField>(_composer).controller!;
        final data = tester
            .widget<ZyraGuardianCircleScreen>(_circle)
            .previewData;
        final length = _transcriptLength(tester);
        for (final design in ZyraCircleBubbleDesign.values) {
          await _setBubbleDesign(tester, design);
          final ignoredPull = await _holdPull(tester, distance: 240);
          _expectNoLegacyHint();
          expect(tester.state(_circle), same(state));
          await ignoredPull.up();
          await tester.pumpAndSettle();
          expect(tester.state(_circle), same(state));
          expect(
            tester.widget<TextField>(_composer).controller,
            same(controller),
          );
          expect(controller.text, 'Keep this unsent Circle draft');
          expect(
            tester.widget<ZyraGuardianCircleScreen>(_circle).previewData,
            same(data),
          );
          expect(_transcriptLength(tester), length);
          expect(find.text(sent), findsOneWidget);
          _expectOneHeaderBack();
          await _capture(
            tester,
            'circle-${role.toLowerCase()}-${design.name}-retained',
          );
        }
        await _openOptions(tester);
        _expectNoLegacyControl();
        final stale = tester
            .widget<DropdownButtonFormField<ZyraCircleBubbleDesign>>(
              _bubbleDropdown,
            )
            .onChanged!;
        await toggleZyraDevControls(tester);
        final firstReturn = _onlyScope(tester).onBack;
        await swipeZyraBack(tester);
        _expectCircleParent(guardian: guardian);
        firstReturn();
        await tester.pumpAndSettle();
        _expectCircleParent(guardian: guardian);
        await _openCircle(tester, guardian: guardian);
        await _openOptions(tester);
        stale(ZyraCircleBubbleDesign.current);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DropdownButtonFormField<ZyraCircleBubbleDesign>>(
                _bubbleDropdown,
              )
              .initialValue,
          ZyraCircleBubbleDesign.current,
        );
        _expectNoLegacyControl();
        await toggleZyraDevControls(tester);
        _expectReturn(tester);
        final secondReturn = _onlyScope(tester).onBack;
        firstReturn();
        await tester.pump();
        expect(_circle, findsOneWidget);
        await _swipeBack(tester);
        _expectCircleParent(guardian: guardian);
        secondReturn();
        await tester.pumpAndSettle();
        _expectCircleParent(guardian: guardian);
      },
    );

    testWidgets(
      '$role retained interior selector cannot survive authorization ABA',
      (tester) async {
        await _mountShell(tester, guardian: guardian);
        await _openCircle(tester, guardian: guardian);
        await _openOptions(tester);
        _expectNoLegacyControl();
        final stale = tester
            .widget<DropdownButtonFormField<ZyraCircleBubbleDesign>>(
              _bubbleDropdown,
            )
            .onChanged!;
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        ZyraDeveloperAccess.setAuthorizedForTesting(true);
        await tester.pumpAndSettle();
        stale(ZyraCircleBubbleDesign.current);
        await tester.pumpAndSettle();
        expect(_bubbleDropdown, findsNothing);
        _expectNoLegacyControl();
        expect(_circle, findsNothing);
        expect(find.text('Preview closed'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final edge in [false, true]) {
    testWidgets(
      'standalone Circle owns exactly one ${edge ? 'interactive edge' : 'accessible Dismiss'} return',
      (tester) async {
        final fixture = _StandaloneCircle();
        addTearDown(fixture.layout.dispose);
        var backs = 0;
        await _mount(tester, fixture.screen(() => backs++));
        expect(
          _onlyScope(tester).key,
          const ValueKey('circle_pull_down_back_scope'),
        );
        _expectOneHeaderBack();
        _expectReturn(tester);
        final duplicate = _dismiss(tester);
        if (edge) {
          final finger = await _holdEdge(tester);
          _expectNoLegacyHint();
          expect(backs, 0);
          await finger.moveBy(const Offset(180, 0));
          await tester.pump(const Duration(milliseconds: 50));
          _expectNoLegacyHint();
          expect(backs, 0);
          await finger.up();
        } else {
          duplicate();
        }
        await tester.pumpAndSettle();
        expect(backs, 1);
        duplicate();
        await tester.pumpAndSettle();
        expect(backs, 1);
        _expectNoLegacyHint();
      },
    );
  }

  testWidgets(
    'a parent return scope prevents nested Circle recognizers and double return',
    (tester) async {
      final fixture = _StandaloneCircle();
      addTearDown(fixture.layout.dispose);
      var parentBacks = 0;
      var childBacks = 0;
      await _mount(
        tester,
        ZyraPullDownBackScope(
          key: const ValueKey('parent-circle-return'),
          routeIdentity: 'explicit-parent',
          onBack: () => parentBacks++,
          child: fixture.screen(() => childBacks++),
        ),
      );
      expect(_onlyScope(tester).key, const ValueKey('parent-circle-return'));
      final duplicate = _dismiss(tester);
      final finger = await _holdEdge(tester, distance: 240);
      expect(parentBacks, 0);
      expect(childBacks, 0);
      await finger.up();
      await tester.pumpAndSettle();
      duplicate();
      await tester.pumpAndSettle();
      expect(parentBacks, 1);
      expect(childBacks, 0);
    },
  );

  testWidgets(
    'empty Journey slots retain theme and canonical Couple navigation after Circle return',
    (tester) async {
      await _mountShell(tester);
      await _openCircle(tester);
      final finger = await _holdEdge(tester, distance: 240);
      await finger.up();
      await tester.pumpAndSettle();
      _expectCircleParent(guardian: false);
      await _nav(tester, 1);
      ZyraJourneyIconPainter painter(Finder root) => tester
          .widgetList<CustomPaint>(
            find.descendant(of: root, matching: find.byType(CustomPaint)),
          )
          .map((paint) => paint.painter)
          .whereType<ZyraJourneyIconPainter>()
          .single;
      expect(
        painter(_key('floating-nav-item-1')).design,
        ZyraJourneyIconDesign.couple,
      );
      expect(find.text('Awaiting a Journey'), findsNWidgets(3));
      for (var index = 0; index < 3; index++) {
        final slot = _key('concept_journey_capacity_slot_$index');
        expect(slot, findsOneWidget);
        final decoration =
            tester.widget<Container>(slot).decoration! as BoxDecoration;
        expect(decoration.color, ZyraColors.surfaceFill);
        expect(decoration.border, Border.all(color: ZyraColors.surfaceBorder));
        final copy = tester.widget<Text>(
          find.descendant(of: slot, matching: find.byType(Text)),
        );
        expect(copy.style?.fontSize, 14);
        expect(copy.style?.color, ZyraColors.ink(.65));
        expect(
          find.descendant(
            of: slot,
            matching: find.byIcon(Icons.route_outlined),
          ),
          findsNothing,
        );
      }
      await _capture(tester, 'journey-empty-three-slots-canonical-navigation');
    },
  );

  testWidgets(
    'Seeker Guardian access heading is text-only without changing navigation',
    (tester) async {
      await _mountShell(tester);
      await _nav(tester, 3);
      final heading = _key('guardian-journey-access-heading');
      final icon = _key('guardian-journey-access-icon');
      final label = find.descendant(
        of: heading,
        matching: find.text('Active Journey access'),
      );
      expect(heading, findsOneWidget);
      expect(icon, findsNothing);
      expect(label, findsOneWidget);
      ZyraJourneyIconPainter painter(Finder root) => tester
          .widgetList<CustomPaint>(
            find.descendant(of: root, matching: find.byType(CustomPaint)),
          )
          .map((paint) => paint.painter)
          .whereType<ZyraJourneyIconPainter>()
          .single;
      expect(
        painter(_key('floating-nav-item-1')).design,
        ZyraJourneyIconDesign.couple,
      );
      final labelRect = tester.getRect(label);
      expect(labelRect.left, closeTo(tester.getRect(heading).left, .01));
      expect(
        find.descendant(of: heading, matching: find.byType(ZyraJourneyIcon)),
        findsNothing,
      );
      final text = tester.widget<Text>(label);
      expect(text.style, ZyraText.body(size: 13.25));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'guardian-access-text-only');
    },
  );

  for (final compact in [false, true]) {
    testWidgets(
      '${compact ? 'narrow purple 200 percent' : 'current purple'} Circle edge has no legacy hint and closes only once after genuine release',
      (tester) async {
        await _mountShell(
          tester,
          size: Size(compact ? 320 : 393, 852),
          scale: compact ? 2 : 1,
          reduce: false,
        );
        await _openCircle(tester);
        _expectReturn(tester);
        final state = tester.state(_circle);
        final duplicate = _onlyScope(tester).onBack;
        final finger = await _holdEdge(tester);
        _expectNoLegacyHint();
        expect(
          tester
              .widget<Transform>(_key('zyra_back_swipe_translation'))
              .transform
              .storage[12],
          greaterThan(0),
        );
        expect(tester.state(_circle), same(state));
        await _capture(
          tester,
          'circle-${compact ? 'purple-small-200' : 'purple'}-partial-edge',
        );
        await finger.moveBy(const Offset(180, 0));
        await tester.pump(const Duration(milliseconds: 50));
        _expectNoLegacyHint();
        expect(_circle, findsOneWidget);
        expect(tester.state(_circle), same(state));
        expect(tester.takeException(), isNull);
        await _capture(
          tester,
          'circle-${compact ? 'purple-small-200' : 'purple'}-ready-edge',
        );
        await tester.pump(const Duration(milliseconds: 200));
        await finger.up();
        await tester.pumpAndSettle();
        _expectCircleParent(guardian: false);
        duplicate();
        await tester.pumpAndSettle();
        _expectCircleParent(guardian: false);
        _expectNoLegacyHint();
      },
    );
  }
}
