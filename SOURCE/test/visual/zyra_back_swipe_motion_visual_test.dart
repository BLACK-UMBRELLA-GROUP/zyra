import '../support/zyra_hidden_dev_controls_driver.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
// Real-font motion evidence from the existing protected synthetic shell.
// During the gesture the revealed area is the app canvas, not cached or live
// parent pixels. The real parent is asserted only after the bound return.
// Optional immutable PNGs: ZYRA_BACK_SWIPE_MOTION_CAPTURE_DIR=<existing absolute directory>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

const _captures = String.fromEnvironment('ZYRA_BACK_SWIPE_MOTION_CAPTURE_DIR');
const _boundary = ValueKey('back-swipe-motion-review');
const _scope = ValueKey('concept_pull_down_back_scope');
const _translation = ValueKey('zyra_back_swipe_translation');
const _edge = ValueKey('zyra_back_swipe_edge');
const _back = ValueKey('zyra_visible_back_button');
const _font = 'PoppinsBackSwipeMotionAudit';

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _motion => find
    .descendant(of: find.byKey(_scope), matching: find.byKey(_translation))
    .first;

double _slide(WidgetTester tester) =>
    tester.widget<Transform>(_motion).transform.storage[12];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError(
      'Back-swipe motion evidence must remain local and offline.',
    );
  }
}

void _security() {
  expect(_key('concept_account_action_scroll'), findsOneWidget);
  expect(find.byType(ZyraConceptSettingsPresentation), findsNothing);
  expect(find.byType(ZyraConceptProfilePresentation), findsNothing);
  expect(find.byType(ZyraShellNavigation), findsNothing);
  expect(find.text('Sign-in & security'), findsOneWidget);
  expect(find.byKey(_edge), findsOneWidget);
  expect(find.text('Release to close'), findsNothing);
}

void _settings() {
  expect(_key('concept_account_action_scroll'), findsNothing);
  expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
  expect(find.byType(ZyraConceptProfilePresentation), findsNothing);
  expect(find.byType(ZyraShellNavigation), findsNothing);
  expect(find.byKey(_scope), findsOneWidget);
}

void _geometry(WidgetTester tester, Size size) {
  expect(tester.takeException(), isNull);
  expect(tester.getSize(find.byKey(_boundary)), size);
  final matrix = tester.widget<Transform>(_motion).transform.storage;
  expect(matrix[13], 0);
  expect(matrix[0], 1);
  expect(matrix[5], 1);
  expect(matrix[10], 1);
  expect(matrix[15], 1);
  expect(_slide(tester), inInclusiveRange(0, size.width));
  final scope = tester.getRect(find.byKey(_scope));
  expect(scope, Offset.zero & size);
  final edge = tester.getRect(find.byKey(_edge));
  expect(edge.left, 0);
  expect(edge.width, 44);
  expect(edge.height, size.height);
}

Future<String> _frame(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  expect(image, isNotNull, reason: name);
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    expect(data, isNotNull, reason: name);
    final bytes = data!.buffer.asUint8List();
    if (_captures.isNotEmpty) {
      expect(_captures.startsWith('/'), isTrue);
      final directory = Directory(_captures);
      expect(directory.existsSync(), isTrue);
      final output = File('${directory.path}/$name.png');
      expect(
        output.existsSync(),
        isFalse,
        reason: 'Retain immutable motion frames.',
      );
      await tester.runAsync(() => output.writeAsBytes(bytes, flush: true));
    }
    return sha256.convert(bytes).toString();
  } finally {
    image!.dispose();
  }
}

Future<void> _press(WidgetTester tester, String key, String ownerKey) async {
  final target = _key(key);
  if (target.evaluate().isEmpty) {
    final scroll = find
        .descendant(of: _key(ownerKey), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(target, 160, scrollable: scroll);
  }
  await Scrollable.ensureVisible(tester.element(target), alignment: .45);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _mountSecurity(
  WidgetTester tester, {
  required Size size,
  bool reduced = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final padding = EdgeInsets.only(
    top: size.height <= 600 ? 24 : 59,
    bottom: size.height <= 600 ? 24 : 34,
  );
  final theme = ThemeData.dark();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(textTheme: ZyraText.textTheme(theme.textTheme)),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: padding,
          viewPadding: padding,
          disableAnimations: reduced,
          accessibleNavigation: reduced,
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: ZyraOneJourneyConceptShell(
        fixture: ZyraShellTestFixture().fixture,
        canAct: () => ZyraDeveloperAccess.canUseDeveloperTools,
        onExit: () => fail('Nested motion must not exit the protected shell.'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Complete the existing bundled deck publication before capturing the
  // stable owner. No member image request or provider operation is involved.
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump();
      final finder = find.byType(ZyraOneJourneyBrowseDesigns);
      if (finder.evaluate().isNotEmpty) {
        final deck = tester.widget<ZyraOneJourneyBrowseDesigns>(finder);
        if (deck.profiles.isNotEmpty &&
            deck.profiles.every((person) => person.photos.isNotEmpty)) {
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('The bundled synthetic photo deck did not publish.');
  });
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  // LOCK 6 V2, master seeker_tab_bar__idle_small.png: expand the idle
  // 60-percent bar before pressing the real Profile slot. LOCK 21 p01 keeps
  // Settings on that Profile; the edge-motion assertions below are unchanged.
  await expandZyraPreviewTabBarIfIdle(tester);
  final navigation = find.byType(ZyraShellNavigation);
  final profile = tester
      .widget<ZyraShellNavigation>(navigation)
      .items
      .singleWhere((item) => item.label == 'Profile');
  final icon = find.descendant(
    of: navigation,
    matching: find.byIcon(profile.icon),
  );
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  await _press(tester, 'concept_settings', 'concept-current-profile-scroll');
  await _press(
    tester,
    'concept_settings_signInSecurity',
    'concept-current-settings-scroll',
  );
  _security();
  _geometry(tester, size);
  expect(_slide(tester), 0);
  expect(find.byKey(_back), findsNothing);
  expect(find.text('Back'), findsNothing);
  expect(find.byKey(const ValueKey('zyra_back_header_space')), findsNothing);
  expect(
    tester.getRect(find.text('Sign-in & security')).top,
    greaterThanOrEqualTo(padding.top),
  );
}

Future<TestGesture> _heldSwipe(
  WidgetTester tester, {
  required Size size,
  double distance = 120,
  bool reduced = false,
}) async {
  final owner = tester.widget<ZyraPullDownBackScope>(find.byKey(_scope)).onBack;
  final titleAtRest = tester.getRect(find.text('Sign-in & security'));
  final edge = tester.getRect(find.byKey(_edge));
  final finger = await tester.startGesture(Offset(8, edge.height * .35));
  for (var step = 0; step < 6; step++) {
    await finger.moveBy(Offset(distance / 6, 0));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 200));
  expect(
    tester.widget<ZyraPullDownBackScope>(find.byKey(_scope)).onBack,
    same(owner),
  );
  _security();
  _geometry(tester, size);
  final expected = reduced ? 0.0 : distance;
  expect(_slide(tester), closeTo(expected, .01));
  expect(find.byKey(_back), findsNothing);
  expect(
    tester.getRect(find.text('Sign-in & security')).left - titleAtRest.left,
    closeTo(expected, .01),
  );
  return finger;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;

  late bool previousStubs;
  late String? previousReading;
  late List<Object?> memberBefore;
  late VoidCallback memberListener;
  var memberChanges = 0;
  List<Object?> snapshot() => [
    List.of(AppState.instance.saved),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.activeJourneys),
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
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'ordinary-member-preference': 'keep',
    });
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousStubs = ZyraText.useTestFontStubs;
    previousReading = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraColors.restoreAppPalette(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final gold = ZyraAppGoldStyle.instance;
    ZyraAppGoldRenderer.instance.resetForTesting();
    expect(
      gold.select(
        false,
        expectedGeneration: ZyraAccountState.generation,
        expectedRevision: gold.revision,
      ),
      isTrue,
    );
    memberBefore = snapshot();
    memberChanges = 0;
    memberListener = () => memberChanges++;
    AppState.instance.addListener(memberListener);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() async {
    AppState.instance.removeListener(memberListener);
    expect(snapshot(), memberBefore);
    expect(memberChanges, 0);
    expect(network.attempts, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ordinary-member-preference'), 'keep');
    HttpOverrides.global = previousNetwork;
    ZyraAppGoldRenderer.instance.resetForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = previousStubs;
    ZyraText.testReadingFontFamily = previousReading;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final size in [const Size(393, 852), const Size(320, 568)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets(
      '$label real shell edge motion paints held and finishing canvas before its parent return',
      (tester) async {
        await _mountSecurity(tester, size: size);
        final hashes = <String>{await _frame(tester, '$label-edge-rest')};
        final stale = tester
            .widget<ZyraPullDownBackScope>(find.byKey(_scope))
            .onBack;
        final finger = await _heldSwipe(tester, size: size);
        hashes.add(await _frame(tester, '$label-edge-held'));
        await finger.up();
        _security();
        await tester.pump();
        expect(_slide(tester), closeTo(120, .01));
        await tester.pump(const Duration(milliseconds: 120));
        _security();
        _geometry(tester, size);
        expect(_slide(tester), inExclusiveRange(120, size.width));
        hashes.add(await _frame(tester, '$label-edge-finishing-120ms'));
        await tester.pump(const Duration(milliseconds: 119));
        _security();
        await tester.pump(const Duration(milliseconds: 2));
        _settings();
        await tester.pumpAndSettle();
        expect(_slide(tester), 0);
        hashes.add(await _frame(tester, '$label-edge-parent-completed'));
        expect(hashes.length, 4);
        stale();
        await tester.pumpAndSettle();
        _settings();
      },
    );
  }

  testWidgets(
    'short real shell edge swipe visibly restores without leaving Security',
    (tester) async {
      const size = Size(393, 852);
      await _mountSecurity(tester, size: size);
      final finger = await _heldSwipe(tester, size: size, distance: 40);
      await finger.up();
      await tester.pump();
      expect(_slide(tester), closeTo(40, .01));
      await tester.pump(const Duration(milliseconds: 100));
      _security();
      _geometry(tester, size);
      expect(_slide(tester), inExclusiveRange(0, 40));
      final intermediate = await _frame(tester, '393x852-edge-rollback-100ms');
      await tester.pumpAndSettle();
      _security();
      expect(_slide(tester), 0);
      expect(
        await _frame(tester, '393x852-edge-rollback-restored'),
        isNot(intermediate),
      );
    },
  );

  testWidgets(
    'reduced real shell motion stays fixed then returns without a motion delay',
    (tester) async {
      const size = Size(393, 852);
      await _mountSecurity(tester, size: size, reduced: true);
      final finger = await _heldSwipe(tester, size: size, reduced: true);
      await _frame(tester, '393x852-edge-reduced-held');
      final releasedAt = tester.binding.clock.now();
      await finger.up();
      await tester.pump();
      expect(tester.binding.clock.now(), releasedAt);
      _settings();
      expect(_slide(tester), 0);
      await _frame(tester, '393x852-edge-reduced-parent-immediate');
      await tester.pump(const Duration(milliseconds: 500));
      _settings();
    },
  );
}
