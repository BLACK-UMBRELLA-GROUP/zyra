// Actual protected local shell, with synthetic records and offline photos.
// These checks prove action routing and retained-delegate denial, not real
// member activation, receipt authority, private results or provider access.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_draft_code_entry.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_options_button.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _capture = bool.fromEnvironment('ZYRA_BROWSE_MENU_CAPTURE');
const _font = 'PoppinsBrowseMenu';
const _boundary = ValueKey('browse-menu-candidate');
const _candidateDirectory = String.fromEnvironment(
  'ZYRA_BROWSE_MENU_CAPTURE_DIRECTORY',
  defaultValue: 'visual/candidates/browse_menu_2026_10_10',
);
const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _labels = [
  'Compatibility score',
  'Scan',
  'Hide profile',
  'Filters',
  'Report',
];

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Browse menu checks must not contact a provider.');
  }
}

ZyraOneJourneyBrowseDesigns _browse(WidgetTester tester) =>
    tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );

ZyraShellNavigation _navigation(WidgetTester tester) =>
    tester.widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation));

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  double scale = 1,
  bool guardian = false,
  bool reduce = true,
  bool accessible = false,
  ValueNotifier<bool>? motion,
  bool Function()? canAct,
  Widget? body,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  Widget media(BuildContext context, Widget? child, bool quiet) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      disableAnimations: quiet,
      accessibleNavigation: accessible,
    ),
    child: child!,
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => motion == null
          ? media(context, child, reduce)
          : ValueListenableBuilder<bool>(
              valueListenable: motion,
              child: child,
              builder: (context, quiet, child) => media(context, child, quiet),
            ),
      home: RepaintBoundary(
        key: _boundary,
        child:
            body ??
            ZyraOneJourneyConceptShell(
              fixture: ZyraShellTestFixture().fixture,
              canAct: canAct ?? () => true,
              onExit: () {},
              initialGuardianRole: guardian,
            ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> _press(WidgetTester tester, String key) async {
  if (await pressZyraDevControlKey(tester, key)) return;
  final target = _key(key);
  if (target.evaluate().isEmpty &&
      (key.startsWith('my-zyra-route-') ||
          key == 'concept_settings' ||
          key == 'concept_safety_advice' ||
          key.startsWith('concept_settings_'))) {
    final owner = key.startsWith('my-zyra-route-')
        ? find.byWidgetPredicate((widget) {
            final value = widget.key;
            return value is ValueKey<String> &&
                value.value.startsWith('my-zyra-quiet-scroll-');
          }).hitTestable()
        : _key(
            key == 'concept_settings' || key == 'concept_safety_advice'
                ? 'concept-current-profile-scroll'
                : 'concept-current-settings-scroll',
          );
    expect(
      owner,
      findsOneWidget,
      reason: 'The visible guarded scroll owner must contain $key.',
    );
    final scrollable = find
        .descendant(of: owner, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(target, 250, scrollable: scrollable);
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final view =
      Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);
  var visible = tester.getRect(target).intersect(view);
  final owner = find.ancestor(of: target, matching: _key('draft_scroll'));
  if (owner.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(owner.first));
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final point = box.globalToLocal(visible.center);
  expect(
    target.hitTestable(
      at: Alignment(
        2 * point.dx / box.size.width - 1,
        2 * point.dy / box.size.height - 1,
      ),
    ),
    findsOneWidget,
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

// The existing bar owns touch at the whole-pill detector, not at each icon.
// Select the real icon cell through that touch owner, never a direct onTap.
Future<void> _tapBar(WidgetTester tester, String label) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final navigation = _navigation(tester);
  final index = navigation.items.indexWhere((item) => item.label == label);
  expect(
    index,
    greaterThanOrEqualTo(0),
    reason: 'Current bar must contain $label.',
  );
  final item = navigation.items[index];
  final icon = find.descendant(
    of: find.byType(ZyraShellNavigation),
    matching: find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  final owner = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(owner.hitTestable(), findsOneWidget);
  final point = tester.getCenter(icon);
  expect(tester.getRect(owner).contains(point), isTrue);
  await tester.tapAt(point);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  if (label == 'My ZYRA' || label == 'Profile') {
    expect(
      _navigation(tester).currentIndex,
      index,
      reason: 'The actual navigation touch must select $label.',
    );
  }
}

Future<void> _openMenu(WidgetTester tester) async {
  await _press(tester, 'concept_browse_menu');
  expect(_navigation(tester).items.map((item) => item.label), _labels);
  expect(_navigation(tester).commitOnRelease, isTrue);
  expect(find.byType(PopupMenuItem<ZyraBrowseAction>), findsNothing);
}

Future<void> _dismissMenu(WidgetTester tester) async {
  await tester.tapAt(const Offset(150, 260));
  await tester.pumpAndSettle();
  expect(_navigation(tester).items.first.label, 'Profiles');
  expect(tester.takeException(), isNull);
}

BoxDecoration _cueDecoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_key('concept_browse_options_cue')).decoration
        as BoxDecoration;

double _cueAlpha(WidgetTester tester) =>
    (_cueDecoration(tester).border! as Border).top.color.a;

Rect _barGlassRect(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(FloatingNavBar),
        matching: find.byType(ClipRRect),
      )
      .first,
);

Future<void> _openPulse(WidgetTester tester) async {
  final menu = _key('concept_browse_menu');
  expect(menu.hitTestable(), findsOneWidget);
  await tester.tap(menu);
  await tester.pump();
  expect(_navigation(tester).items.map((item) => item.label), _labels);
  await tester.pump(const Duration(milliseconds: 220));
  expect(_cueAlpha(tester), greaterThan(.5));
  expect(tester.takeException(), isNull);
}

Future<void> _snapshot(
  WidgetTester tester,
  String name, {
  bool settle = true,
}) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  for (final image in tester.widgetList<Image>(find.byType(Image))) {
    expect(image.image, isA<MemoryImage>());
    await tester.runAsync(() async {
      final ready = Completer<void>();
      final stream = image.image.resolve(const ImageConfiguration());
      final listener = ImageStreamListener(
        (_, _) {
          if (!ready.isCompleted) ready.complete();
        },
        onError: (Object error, StackTrace? stack) {
          if (!ready.isCompleted) ready.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      try {
        await ready.future.timeout(const Duration(seconds: 10));
      } finally {
        stream.removeListener(listener);
      }
    });
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile('$_candidateDirectory/$name.png'),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final priorOverrides = HttpOverrides.current;
  late _NoNetwork network;
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
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });
  setUp(() {
    network = _NoNetwork();
    HttpOverrides.global = network;
    // The nested My ZYRA fixture keeps its own developer-only authority gate.
    // Authorize synthetic test data through the existing test hook, never an
    // account, member record or a production bypass.
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });
  tearDown(() {
    expect(network.attempts, 0);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    HttpOverrides.global = priorOverrides;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final viewport in const [
    (size: Size(393, 852), scale: 1.0),
    (size: Size(320, 568), scale: 2.0),
  ]) {
    testWidgets(
      'Browse keeps its five-action bar unchanged beside the LOCK 6 root bar ${viewport.scale}',
      (tester) async {
        await _mount(tester, size: viewport.size, scale: viewport.scale);
        final header = tester.widget<IconButton>(_key('concept_browse_menu'));
        expect(header.icon, isA<Icon>());
        expect((header.icon as Icon).icon, Icons.more_horiz_rounded);
        expect((header.icon as Icon).size, 24);
        expect(header.color, ZyraColors.journeyGold);
        final menuRect = tester.getRect(_key('concept_browse_menu'));
        final menuScrollBefore =
            Scrollable.maybeOf(
              tester.element(_key('concept_browse_menu')),
            )?.position.pixels ??
            0;
        expect(menuRect.width, greaterThanOrEqualTo(48));
        expect(menuRect.height, greaterThanOrEqualTo(48));
        expect(header.tooltip, contains('Sara'));
        final before = _barGlassRect(tester);
        final fullWidth = viewport.size.width - 40;
        expect(_key('compact-nav-surface'), findsOneWidget);
        expect(
          before.width,
          closeTo(viewport.scale > 1 ? fullWidth : fullWidth * .6, .001),
        );
        expect(before.height, closeTo(viewport.scale > 1 ? 58 : 50, .001));
        final bodyBefore = tester.getRect(
          find.byType(ZyraOneJourneyBrowseDesigns),
        );
        expect(_key('concept_browse_options_cue'), findsNothing);
        await _openMenu(tester);
        final after = _barGlassRect(tester);
        expect(_key('compact-nav-surface'), findsNothing);
        expect(after.left, closeTo(20, .01));
        expect(after.right, closeTo(viewport.size.width - 20, .01));
        expect(after.width, closeTo(fullWidth, .01));
        expect(after.height, closeTo(ZyraNavBarMetrics.restingHeight, .01));
        expect(after.bottom, closeTo(before.bottom, .01));
        expect(
          tester.getRect(find.byType(ZyraOneJourneyBrowseDesigns)),
          bodyBefore,
          reason: 'The separate footer sizes do not move the profile body.',
        );
        final menuScrollAfter =
            Scrollable.maybeOf(
              tester.element(_key('concept_browse_menu')),
            )?.position.pixels ??
            0;
        expect(
          tester.getRect(_key('concept_browse_menu')),
          menuRect.shift(Offset(0, menuScrollBefore - menuScrollAfter)),
          reason:
              'The existing ensureVisible scroll moves the menu with its page.',
        );
        expect(
          tester.getRect(_key('concept_browse_options_cue')),
          _barGlassRect(tester),
          reason: 'The cue follows the unchanged full-width action pill.',
        );
        expect(
          _navigation(tester).items.any((item) => item.label.contains('Help')),
          isFalse,
        );
        expect(find.text('Help & support'), findsNothing);
        await _dismissMenu(tester);
        expect(_key('compact-nav-surface'), findsOneWidget);
        expect(_barGlassRect(tester), before);
        expect(
          tester.getRect(find.byType(ZyraOneJourneyBrowseDesigns)),
          bodyBefore,
        );
        expect(
          _browse(tester).profiles[_browse(tester).selectedIndex].id,
          _sara,
        );
      },
    );
  }

  testWidgets('Browse opening cue is finite, gold and purely decorative', (
    tester,
  ) async {
    await _mount(tester, reduce: false);
    final ids = _browse(tester).profiles.map((profile) => profile.id).toList();
    final rootBar = _barGlassRect(tester);
    expect(rootBar.width, closeTo(211.8, .01));
    expect(rootBar.height, closeTo(50, .01));
    await _openPulse(tester);
    final actionBar = _barGlassRect(tester);
    expect(actionBar.left, closeTo(20, .01));
    expect(actionBar.width, closeTo(353, .01));
    expect(actionBar.height, closeTo(ZyraNavBarMetrics.restingHeight, .01));
    expect(actionBar.bottom, closeTo(rootBar.bottom, .01));
    final cue = _key('concept_browse_options_cue');
    expect(tester.getRect(cue), actionBar);
    final decoration = _cueDecoration(tester);
    expect(decoration.borderRadius, BorderRadius.circular(28));
    expect((decoration.border! as Border).top.width, 1.5);
    expect(decoration.color!.a, lessThan(.061));
    expect(
      (decoration.border! as Border).top.color.r,
      closeTo(ZyraColors.journeyGold.r, .001),
    );
    final pointer = find
        .ancestor(of: cue, matching: find.byType(IgnorePointer))
        .first;
    expect(pointer, findsOneWidget);
    expect(tester.widget<IgnorePointer>(pointer).ignoring, isTrue);
    final semantics = find
        .ancestor(of: cue, matching: find.byType(ExcludeSemantics))
        .first;
    expect(tester.widget<ExcludeSemantics>(semantics).excluding, isTrue);
    await _snapshot(tester, 'browse_options_gold_cue_peak', settle: false);
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pump();
    expect(_cueAlpha(tester), 0);
    expect(_cueDecoration(tester).color!.a, 0);
    expect(tester.binding.transientCallbackCount, 0);
    expect(_barGlassRect(tester), actionBar);
    expect(_browse(tester).profiles.map((profile) => profile.id), ids);
    expect(_navigation(tester).items.map((item) => item.label), _labels);
    await _snapshot(tester, 'browse_options_gold_cue_settled');
    await _dismissMenu(tester);
    expect(_barGlassRect(tester), rootBar);
    expect(_key('concept_browse_options_cue'), findsNothing);
  });

  for (final accessible in [false, true]) {
    testWidgets('quiet Browse cue is static with no pulse $accessible', (
      tester,
    ) async {
      await _mount(tester, reduce: !accessible, accessible: accessible);
      await _openMenu(tester);
      final cue = _key('concept_browse_options_cue');
      final before = _cueDecoration(tester);
      expect(_cueAlpha(tester), closeTo(.29, .005));
      expect(before.boxShadow, isEmpty);
      expect(
        find.ancestor(
          of: cue,
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(_cueDecoration(tester), before);
      expect(_navigation(tester).items.map((item) => item.label), _labels);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('enabling quiet motion disposes an in-flight opening pulse', (
    tester,
  ) async {
    final motion = ValueNotifier(false);
    addTearDown(motion.dispose);
    await _mount(tester, motion: motion);
    await _openPulse(tester);
    final before = _barGlassRect(tester);
    motion.value = true;
    await tester.pump();
    final cue = _key('concept_browse_options_cue');
    expect(_cueAlpha(tester), closeTo(.29, .005));
    expect(
      find.ancestor(
        of: cue,
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
      findsNothing,
    );
    final stable = _cueDecoration(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_cueDecoration(tester), stable);
    expect(_barGlassRect(tester), before);
    await _dismissMenu(tester);
    expect(_key('concept_browse_options_cue'), findsNothing);
  });

  testWidgets('a real action touch passes through the visible opening cue', (
    tester,
  ) async {
    await _mount(tester, reduce: false);
    await _openPulse(tester);
    final ids = _browse(tester).profiles.map((profile) => profile.id).toList();
    await _tapBar(tester, 'Filters');
    expect(find.text('Filters'), findsOneWidget);
    expect(_key('concept_browse_options_cue'), findsNothing);
    await returnZyraPreviewPage(tester);
    expect(_browse(tester).profiles.map((profile) => profile.id), ids);
    expect(_navigation(tester).items.first.label, 'Profiles');
  });

  for (final quiet in [false, true]) {
    testWidgets('first held bar touch removes cue before breathing $quiet', (
      tester,
    ) async {
      await _mount(tester, reduce: quiet);
      if (quiet) {
        await _openMenu(tester);
      } else {
        await _openPulse(tester);
      }
      final before = _barGlassRect(tester);
      final filters = find.descendant(
        of: find.byType(ZyraShellNavigation),
        matching: find.byIcon(ZyraBrowseAction.filters.icon),
      );
      expect(filters, findsOneWidget);
      final touchOwner = find
          .ancestor(
            of: filters,
            matching: find.byWidgetPredicate(
              (widget) => widget is GestureDetector && widget.onTapDown != null,
            ),
          )
          .first;
      expect(touchOwner.hitTestable(), findsOneWidget);
      final point = tester.getCenter(filters);
      expect(tester.getRect(touchOwner).contains(point), isTrue);
      final finger = await tester.startGesture(point);
      // Allow the real tap recognizer's press deadline, then its existing
      // breathing animation; do not invoke its callbacks or skip the hold.
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 240));
      expect(_key('concept_browse_options_cue'), findsNothing);
      expect(_navigation(tester).items.map((item) => item.label), _labels);
      final held = _barGlassRect(tester);
      expect(held.height, closeTo(ZyraNavBarMetrics.height, .01));
      expect(
        held.width,
        closeTo(before.width, .01),
        reason: 'Aligned Browse keeps its content edges fixed while held.',
      );
      await finger.up();
      await tester.pumpAndSettle();
      expect(find.text('Filters'), findsOneWidget);
      expect(_key('concept_browse_options_cue'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'closing and reopening the cue cannot revive old menu authority',
    (tester) async {
      var allowed = true;
      await _mount(tester, reduce: false, canAct: () => allowed);
      final ids = _browse(
        tester,
      ).profiles.map((profile) => profile.id).toList();
      await _openPulse(tester);
      final retained = _navigation(tester).onTap;
      allowed = false;
      retained(ZyraBrowseAction.hide.index);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_key('concept_browse_hide_confirmation'), findsNothing);
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
      allowed = true;
      await _dismissMenu(tester);
      expect(_key('concept_browse_options_cue'), findsNothing);
      await _press(tester, 'concept_next_profile');
      retained(ZyraBrowseAction.hide.index);
      await tester.pumpAndSettle();
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
      expect(
        _browse(tester).profiles[_browse(tester).selectedIndex].id,
        _aisha,
      );
      await _openPulse(tester);
      retained(ZyraBrowseAction.hide.index);
      await tester.pump();
      expect(_key('concept_browse_hide_confirmation'), findsNothing);
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
      await _dismissMenu(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(_key('concept_browse_options_cue'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Hide applies only to displayed Sara and preserves her sent invitation',
    (tester) async {
      await _mount(tester);
      await _press(tester, 'draft_profile_$_sara');
      await _openMenu(tester);
      await _tapBar(tester, 'Hide profile');
      expect(_key('concept_browse_hide_confirmation'), findsOneWidget);
      expect(
        _browse(tester).profiles.map((profile) => profile.id),
        contains(_sara),
      );
      final sara = _browse(
        tester,
      ).profiles.firstWhere((profile) => profile.id == _sara);
      expect(_browse(tester).requestLabel!(sara), 'Request sent');
      await _press(tester, 'browse-hide-confirm');
      expect(
        _browse(tester).profiles.map((profile) => profile.id),
        isNot(contains(_sara)),
      );
      expect(
        _browse(tester).profiles.map((profile) => profile.id),
        contains(_aisha),
      );
      await _tapBar(tester, 'My ZYRA');
      await _press(tester, 'my-zyra-route-concept-my-requests');
      await _press(tester, 'draft_requests_1');
      expect(_key('concept_request_${_sara}_header'), findsOneWidget);
    },
  );

  testWidgets(
    'Portrait photo stays in Browse and menu Hide excludes only that person',
    (tester) async {
      await _mount(tester);
      // The approved Portrait card cycles photos in place; it no longer
      // opens a gallery viewer or exposes an alternate design in Actions.
      await _press(tester, 'concept_browse_photo_tap_$_sara');
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(_browse(tester).design, ZyraOneJourneyBrowseDesign.portraitCard);
      expect(_browse(tester).profiles[_browse(tester).selectedIndex].id, _sara);
      await _openMenu(tester);
      await _tapBar(tester, 'Hide profile');
      expect(_key('concept_browse_hide_confirmation'), findsOneWidget);
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      await _press(tester, 'browse-hide-confirm');
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      expect(
        _browse(tester).profiles.map((profile) => profile.id),
        isNot(contains(_sara)),
      );
      expect(
        _browse(tester).profiles.map((profile) => profile.id),
        contains(_aisha),
      );
    },
  );

  testWidgets(
    'Filters remain functional and do not cancel the first invitation',
    (tester) async {
      await _mount(tester);
      await _press(tester, 'draft_profile_$_sara');
      await _openMenu(tester);
      await _tapBar(tester, 'Filters');
      expect(find.text('Filters'), findsOneWidget);
      await _press(tester, 'concept_nationality');
      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Pakistani');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pakistani (PK)').last);
      await tester.pumpAndSettle();
      await _press(tester, 'concept_apply_filter');
      final body = _browse(tester);
      final person = body.profiles.firstWhere((profile) => profile.id == _sara);
      expect(
        body.profiles.map((profile) => profile.id),
        isNot(contains(_aisha)),
      );
      expect(body.requestLabel!(person), 'Request sent');
      expect(body.invitationSent!(person), isTrue);
    },
  );

  testWidgets(
    'Compatibility score keeps the selected person and reveals all with one local unlock',
    (tester) async {
      await _mount(tester);
      final selected = _browse(tester).profiles[_browse(tester).selectedIndex];
      expect(selected.id, _sara);
      await _openMenu(tester);
      await _tapBar(tester, 'Compatibility score');
      expect(find.text('Compatibility score'), findsOneWidget);
      // The approved locked Halo identifies the pair inside the card, not
      // as a subtitle beneath the page title.
      expect(find.text('You and Sara'), findsOneWidget);
      expect(
        find.descendant(
          of: _key('draft_compatibility_card'),
          matching: find.text('You and Sara'),
        ),
        findsOneWidget,
      );
      expect(_key('draft_compatibility_demo_notice'), findsNothing);
      expect(find.textContaining('Try Compatibility with'), findsNothing);
      expect(_key('draft_compatibility_select_overall'), findsNothing);
      expect(_key('draft_compatibility_select_plus'), findsNothing);
      expect(_key('draft_compatibility_reveal'), findsOneWidget);
      final before = tester.widget<ZyraDraftCompatibilityPresentation>(
        find.byType(ZyraDraftCompatibilityPresentation),
      );
      expect(before.personName, selected.firstName);
      expect(before.balance, 1);
      expect(before.revealed, isFalse);
      final retainedReveal = tester
          .widget<OutlinedButton>(_key('draft_compatibility_reveal'))
          .onPressed;
      expect(retainedReveal, isNotNull);

      await _press(tester, 'draft_compatibility_reveal');
      final after = tester.widget<ZyraDraftCompatibilityPresentation>(
        find.byType(ZyraDraftCompatibilityPresentation),
      );
      expect(after.personName, 'Sara');
      expect(after.balance, 0);
      expect(after.revealed, isTrue);
      expect(
        tester.widget<Text>(_key('draft_compatibility_overall_score')).data,
        '${before.overallScore}%',
      );
      expect(find.text('Demo Guardian · Father'), findsOneWidget);
      expect(_key('draft_compatibility_score_reader'), findsOneWidget);
      expect(_key('draft_compatibility_guardian_result'), findsOneWidget);
      for (final (offset, category) in const [
        ('Lifestyle', 80, 15, 5),
        ('Work & Education', 70, 20, 10),
        ('Family Values', 85, 10, 5),
        ('Marriage Goals', 90, 5, 5),
        ('Personality', 60, 30, 10),
        ('Deen', 65, 25, 10),
      ].indexed) {
        await _press(tester, 'draft_compatibility_score_next');
        expect(find.text(category.$1), findsOneWidget);
        final index = offset + 1;
        for (final metric in [
          ('aligned', category.$2),
          ('discuss', category.$3),
          ('opposed', category.$4),
        ]) {
          expect(
            find.descendant(
              of: _key('draft_compatibility_metric_${index}_${metric.$1}'),
              matching: find.text('${metric.$2}%'),
            ),
            findsOneWidget,
          );
        }
        expect(
          _key('draft_compatibility_score_artwork_halo_$index'),
          findsOneWidget,
        );
      }
      final revealAgain = retainedReveal!;
      revealAgain();
      revealAgain();
      await tester.pumpAndSettle();
      final repeated = tester.widget<ZyraDraftCompatibilityPresentation>(
        find.byType(ZyraDraftCompatibilityPresentation),
      );
      expect(repeated.balance, 0);
      expect(repeated.revealed, isTrue);
      expect(find.text('7 / 7'), findsOneWidget);
      expect(find.text('Your shared result'), findsNothing);
      expect(_key('draft_reveal_$_sara'), findsNothing);
      expect(_key('draft_peer_reveal_$_sara'), findsNothing);
      expect(_key('concept_message'), findsNothing);
      // The rail now opens this page's own options. Returning to Profiles uses
      // the same public Back action as the other secondary pages.
      final backScope = _key('concept_pull_down_back_scope');
      expect(backScope, findsOneWidget);
      await returnZyraPreviewPage(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
      final body = _browse(tester);
      expect(body.profiles[body.selectedIndex].id, _sara);
      expect(
        body.requestLabel!(
          body.profiles.firstWhere((profile) => profile.id == _sara),
        ),
        'Request a Journey',
      );
    },
  );

  testWidgets(
    'Scan uses LOCK9 disclosure and returns its exact Browse parent',
    (tester) async {
      await _mount(tester);
      await _openMenu(tester);
      await _tapBar(tester, 'Scan');
      expect(find.byType(ZyraDraftCodeEntry), findsOneWidget);
      expect(_key('local-code-field'), findsOneWidget);
      expect(_key('local-code-check').hitTestable(), findsOneWidget);
      expect(find.text('Enter code'), findsNothing);
      await tester.enterText(_key('local-code-field'), 'ZYRA-DRAFT-SARA');
      await _press(tester, 'local-code-check');
      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('Seeker · first name and role only'), findsOneWidget);
      expect(find.text('27 · Birmingham'), findsNothing);
      expect(find.text('View profile'), findsNothing);
      expect(find.text('Request sent'), findsNothing);
      expect(network.attempts, 0);
      await returnZyraPreviewPage(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
      final browse = _browse(tester);
      expect(browse.profiles[browse.selectedIndex].id, _sara);
    },
  );

  testWidgets('Report identifies the peer without submitting or opening Help', (
    tester,
  ) async {
    await _mount(tester);
    await _openMenu(tester);
    await _tapBar(tester, 'Report');
    expect(find.text('Report profile'), findsOneWidget);
    expect(_key('draft_report_target'), findsOneWidget);
    expect(find.textContaining('Sara'), findsWidgets);
    expect(find.text('Help & support'), findsNothing);
    expect(_key('draft_safety_hide'), findsOneWidget);
    expect(_key('draft_safety_block'), findsOneWidget);
    await _press(tester, 'draft_report_reason_fakeProfile');
    expect(
      tester.widget<OutlinedButton>(_key('draft_report_submit')).onPressed,
      isNull,
    );
    expect(find.text('Report sent'), findsNothing);
    expect(find.textContaining('Demonstration only'), findsNothing);
    await _snapshot(tester, 'report_profile');
    expect(_key('concept_message'), findsNothing);
    expect(network.attempts, 0);
  });

  testWidgets('Help and support remain accessible from Profile settings', (
    tester,
  ) async {
    await _mount(tester);
    await _tapBar(tester, 'Profile');
    await _press(tester, 'concept_settings');
    await _press(tester, 'concept_settings_helpSupport');
    expect(find.byType(HelpSupportScreen), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('PREVIEW ONLY'), findsNothing);
    expect(_key('concept_browse_menu'), findsNothing);
    final search = find.descendant(
      of: _key('help-support-preview-search'),
      matching: find.byType(TextField),
    );
    expect(search.hitTestable(), findsOneWidget);
    await tester.enterText(search, 'sign in');
    await tester.pumpAndSettle();
    expect(find.text('How do I sign in?'), findsOneWidget);
    expect(find.text('How do I invite someone to a Journey?'), findsNothing);
    await _press(tester, 'help-support-faq:Getting started:How do I sign in?');
    expect(
      find.text(
        'With Apple or Google. There is no password to create or forget, and we '
        'never see one.',
      ),
      findsOneWidget,
    );
    expect(_key('support-safety-case-status'), findsNothing);
    expect(_key('help-support-email-action'), findsNothing);
    expect(network.attempts, 0);
  });

  testWidgets('account Safety does not retain the last reported Browse peer', (
    tester,
  ) async {
    await _mount(tester);
    await _openMenu(tester);
    await _tapBar(tester, 'Report');
    expect(_key('draft_report_target'), findsOneWidget);
    await returnZyraPreviewPage(tester);
    await tester.pumpAndSettle();
    await _tapBar(tester, 'Profile');
    await _press(tester, 'concept_safety_advice');
    await _press(tester, 'draft_safety_advice_report');
    expect(find.text('Choose a profile to report'), findsOneWidget);
    expect(_key('draft_report_target'), findsNothing);
    expect(_key('draft_safety_hide'), findsNothing);
    expect(_key('draft_safety_block'), findsNothing);
    expect(network.attempts, 0);
  });

  for (final size in [
    const Size(375, 812),
    const Size(393, 852),
    const Size(430, 932),
  ]) {
    testWidgets('Scan and Report fit the actual safe viewport $size', (
      tester,
    ) async {
      await _mount(tester, size: size);
      for (final action in ['Scan', 'Report']) {
        await _openMenu(tester);
        await _tapBar(tester, action);
        final owner = find.byType(
          action == 'Scan' ? ZyraDraftCodeEntry : ZyraDraftReportPresentation,
        );
        expect(owner, findsOneWidget);
        if (action == 'Scan') {
          expect(_key('local-code-field'), findsOneWidget);
          expect(_key('local-code-check').hitTestable(), findsOneWidget);
          expect(find.text('Consider'), findsNothing);
          expect(find.text('View profile'), findsNothing);
        }
        expect(find.byType(ZyraShellNavigation), findsNothing);
        for (final element
            in find
                .descendant(of: owner, matching: find.byType(Scrollable))
                .evaluate()) {
          final state = (element as StatefulElement).state as ScrollableState;
          expect(state.position.maxScrollExtent, closeTo(0, .5));
          expect(state.position.pixels, closeTo(0, .5));
        }
        for (final key
            in action == 'Scan'
                ? ['local-code-field', 'local-code-check']
                : [
                    'draft_report_target',
                    'draft_report_reason_other',
                    'draft_report_submit',
                  ]) {
          final rect = tester.getRect(_key(key));
          expect(rect.top, greaterThanOrEqualTo(59));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 34 - 16 + .5));
          expect(rect.left, greaterThanOrEqualTo(20));
          expect(rect.right, lessThanOrEqualTo(size.width - 20 + .5));
        }
        await _snapshot(
          tester,
          '${action.toLowerCase()}_${size.width.toInt()}',
        );
        await returnZyraPreviewPage(tester);
        await tester.pumpAndSettle();
        expect(
          _browse(tester).profiles[_browse(tester).selectedIndex].id,
          _sara,
        );
      }
    });
  }

  testWidgets(
    'retained action selection cannot hide the next displayed person',
    (tester) async {
      await _mount(tester);
      final ids = _browse(
        tester,
      ).profiles.map((profile) => profile.id).toList();
      await _openMenu(tester);
      final retained = _navigation(tester).onTap;
      await _dismissMenu(tester);
      await _press(tester, 'concept_next_profile');
      expect(
        _browse(tester).profiles[_browse(tester).selectedIndex].id,
        _aisha,
      );
      retained(ZyraBrowseAction.hide.index);
      await tester.pumpAndSettle();
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
      expect(
        _browse(tester).profiles[_browse(tester).selectedIndex].id,
        _aisha,
      );
      await _openMenu(tester);
      await _tapBar(tester, 'Hide profile');
      expect(_key('concept_browse_hide_confirmation'), findsOneWidget);
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
      await _press(tester, 'browse-hide-confirm');
      expect(
        _browse(tester).profiles.map((profile) => profile.id),
        contains(_sara),
      );
      expect(
        _browse(tester).profiles.map((profile) => profile.id),
        isNot(contains(_aisha)),
      );
    },
  );

  testWidgets(
    'Hide Cancel retains both people and rejects its stale confirmation',
    (tester) async {
      await _mount(tester);
      final ids = _browse(
        tester,
      ).profiles.map((profile) => profile.id).toList();
      await _openMenu(tester);
      await _tapBar(tester, 'Hide profile');
      expect(_key('browse-hide-outer-surface'), findsNothing);
      final confirmation = tester.widget<FloatingNavConfirmationBar>(
        _key('concept_browse_hide_confirmation'),
      );
      expect(confirmation.showOuterSurface, isFalse);
      expect(_key('browse-hide-cancel').hitTestable(), findsOneWidget);
      expect(_key('browse-hide-confirm').hitTestable(), findsOneWidget);
      await _snapshot(tester, 'hide_profile_confirmation');
      final retained = tester
          .widget<FloatingNavConfirmationBar>(
            _key('concept_browse_hide_confirmation'),
          )
          .onConfirm;
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
      await _press(tester, 'browse-hide-cancel');
      expect(_key('concept_browse_hide_confirmation'), findsNothing);
      expect(_navigation(tester).items.map((item) => item.label), _labels);
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
      retained();
      await tester.pumpAndSettle();
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
      await _dismissMenu(tester);
      await _press(tester, 'concept_next_profile');
      expect(
        _browse(tester).profiles[_browse(tester).selectedIndex].id,
        _aisha,
      );
      retained();
      await tester.pumpAndSettle();
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
      expect(
        _browse(tester).profiles[_browse(tester).selectedIndex].id,
        _aisha,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Hide confirmation is denied after authority revocation', (
    tester,
  ) async {
    var allowed = true;
    await _mount(tester, canAct: () => allowed);
    final ids = _browse(tester).profiles.map((profile) => profile.id).toList();
    await _openMenu(tester);
    await _tapBar(tester, 'Hide profile');
    final retained = tester
        .widget<FloatingNavConfirmationBar>(
          _key('concept_browse_hide_confirmation'),
        )
        .onConfirm;
    allowed = false;
    retained();
    await tester.pumpAndSettle();
    expect(_browse(tester).profiles.map((profile) => profile.id), ids);
    allowed = true;
    await _press(tester, 'browse-hide-cancel');
    expect(_browse(tester).profiles.map((profile) => profile.id), ids);
    await _dismissMenu(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary Hide confirmation keeps its existing outer surface', (
    tester,
  ) async {
    var cancelled = 0;
    var hidden = 0;
    await _mount(
      tester,
      body: Scaffold(
        body: Stack(
          children: [
            FloatingNavConfirmationBar(
              onCancel: () => cancelled++,
              onConfirm: () => hidden++,
            ),
          ],
        ),
      ),
    );
    expect(_key('browse-hide-outer-surface'), findsOneWidget);
    expect(
      tester.getSize(_key('browse-hide-cancel')).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getSize(_key('browse-hide-confirm')).height,
      greaterThanOrEqualTo(44),
    );
    await _press(tester, 'browse-hide-cancel');
    await _press(tester, 'browse-hide-confirm');
    expect(cancelled, 1);
    expect(hidden, 1);
  });

  testWidgets('canAct revocation denies a pending menu mutation', (
    tester,
  ) async {
    var allowed = true;
    await _mount(tester, canAct: () => allowed);
    final ids = _browse(tester).profiles.map((profile) => profile.id).toList();
    await _openMenu(tester);
    final retained = _navigation(tester).onTap;
    allowed = false;
    retained(ZyraBrowseAction.hide.index);
    await tester.pumpAndSettle();
    expect(_browse(tester).profiles.map((profile) => profile.id), ids);
    allowed = true;
    await _dismissMenu(tester);
    expect(_browse(tester).profiles.map((profile) => profile.id), ids);
  });

  testWidgets(
    'retained Seeker menu cannot act after a Guardian role round trip',
    (tester) async {
      await _mount(tester);
      final ids = _browse(
        tester,
      ).profiles.map((profile) => profile.id).toList();
      await _openMenu(tester);
      final retained = _navigation(tester).onTap;
      await _dismissMenu(tester);
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_role_guardian');
      expect(_key('concept_browse_menu'), findsNothing);
      retained(ZyraBrowseAction.hide.index);
      await tester.pumpAndSettle();
      await _press(tester, 'draft_back');
      await _press(tester, 'draft_role_seeker');
      retained(ZyraBrowseAction.hide.index);
      await tester.pumpAndSettle();
      expect(_browse(tester).profiles.map((profile) => profile.id), ids);
    },
  );

  testWidgets(
    'optional header passes null context without substituting a person',
    (tester) async {
      final opened = <SeekerProfile?>[];
      await _mount(
        tester,
        body: Scaffold(
          body: Center(
            child: ZyraBrowseOptionsButton(profile: null, onOpen: opened.add),
          ),
        ),
      );
      expect(
        tester.widget<IconButton>(_key('concept_browse_menu')).tooltip,
        'Profiles options',
      );
      await _press(tester, 'concept_browse_menu');
      expect(opened, [null]);
    },
  );

  testWidgets(
    'new offline candidates show header and existing five-action bar',
    (tester) async {
      if (!_capture) return;
      await _mount(tester);
      await _snapshot(tester, 'browse_header');
      await _openMenu(tester);
      await _snapshot(tester, 'browse_options');
    },
  );

  testWidgets('packet-only Current sent card and held photo seam candidates', (
    tester,
  ) async {
    if (!_capture) return;
    final platformCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    final hapticPreference = ZyraInteractionStyle.hapticLevel;
    int haptics() => platformCalls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .length;
    await _mount(tester, reduce: false);
    final before = _browse(tester);
    final ids = before.profiles.map((profile) => profile.id).toList();
    final person = before.profiles[before.selectedIndex];
    expect(person.id, _sara);
    expect(person.photos.length, greaterThanOrEqualTo(2));
    await _press(tester, 'draft_profile_$_sara');
    final requested = _browse(tester);
    expect(requested.profiles[requested.selectedIndex].id, _sara);
    expect(requested.invitationSent!(person), isTrue);
    expect(requested.requestLabel!(person), 'Request sent');
    await _snapshot(tester, 'current_sent_card_thick_outline');
    final requestRect = tester.getRect(_key('draft_profile_$_sara'));
    final pager = _key('concept_browse_photo_swipe_$_sara');
    final hapticsBefore = haptics();
    final finger = await tester.startGesture(tester.getCenter(pager));
    await finger.moveBy(const Offset(-25, 0));
    await tester.pump();
    await finger.moveBy(Offset(-tester.getSize(pager).width * .4, 0));
    await tester.pump();
    expect(
      tester.widget<PageView>(pager).controller!.page,
      inExclusiveRange(0, .5),
    );
    expect(_browse(tester).profiles.map((profile) => profile.id), ids);
    expect(_browse(tester).profiles[_browse(tester).selectedIndex].id, _sara);
    expect(_browse(tester).requestLabel!(person), 'Request sent');
    expect(tester.getRect(_key('draft_profile_$_sara')), requestRect);
    expect(haptics(), hapticsBefore);
    expect(_key('concept_browse_options_cue'), findsNothing);
    await _snapshot(tester, 'current_sent_photo_held_seam', settle: false);
    await finger.moveBy(Offset(-tester.getSize(pager).width * .3, 0));
    await tester.pump();
    await finger.up();
    await tester.pumpAndSettle();
    expect(tester.widget<PageView>(pager).controller!.page, closeTo(1, .01));
    expect(
      haptics() - hapticsBefore,
      hapticPreference == ZyraHapticLevel.off ? 0 : 1,
    );
    expect(ZyraInteractionStyle.hapticLevel, hapticPreference);
    expect(_browse(tester).profiles.map((profile) => profile.id), ids);
    expect(_browse(tester).profiles[_browse(tester).selectedIndex].id, _sara);
    expect(_browse(tester).invitationSent!(person), isTrue);
    expect(_browse(tester).requestLabel!(person), 'Request sent');
    expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
