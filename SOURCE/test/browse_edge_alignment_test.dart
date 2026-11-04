// Actual protected shell and bundled offline photographs. This fixture checks
// the visible content edges and real gesture owners, not member activation.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsBrowseAlignment';
const _boundary = ValueKey('browse-alignment-paint');
const _capture = bool.fromEnvironment('ZYRA_BROWSE_ALIGNMENT_CAPTURE');
const _captureDirectory = String.fromEnvironment(
  'ZYRA_BROWSE_ALIGNMENT_CAPTURE_DIRECTORY',
);
const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _actions = [
  'Compatibility score',
  'Scan',
  'Hide profile',
  'Filters',
  'Report',
];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Browse edge alignment must remain offline.');
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

ZyraOneJourneyBrowseDesigns _browse(WidgetTester tester) =>
    tester.widget<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    );

SeekerProfile _person(WidgetTester tester) {
  final browse = _browse(tester);
  return browse.profiles[browse.selectedIndex];
}

ZyraShellNavigation _navigation(WidgetTester tester) =>
    tester.widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation));

Finder _glass() => find
    .descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(ClipRRect),
    )
    .first;

Finder _touchOwner() => find
    .descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onTapDown != null,
      ),
    )
    .first;

Rect _outerPill(WidgetTester tester, String key) => tester.getRect(
  find.ancestor(of: _key(key), matching: find.byType(Material)).first,
);

void _edges(Rect rect, double width, double inset) {
  expect(rect.left, closeTo(inset, .01));
  expect(rect.right, closeTo(width - inset, .01));
}

void _target(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final rect = tester.getRect(finder);
  expect(rect.width, greaterThanOrEqualTo(44));
  expect(rect.height, greaterThanOrEqualTo(44));
  expect(finder.hitTestable(), findsOneWidget);
}

void _expectRootBarGeometry(
  WidgetTester tester,
  Size size, {
  required bool expanded,
}) {
  final nav = tester.getRect(_glass());
  if (expanded) {
    _edges(nav, size.width, 20);
    expect(nav.height, closeTo(58, .01));
  } else {
    expect(nav.width, closeTo((size.width - 40) * .6, .01));
    expect(nav.center.dx, closeTo(size.width / 2, .01));
    expect(nav.height, closeTo(50, .01));
  }
  expect(nav.bottom, lessThanOrEqualTo(size.height - 14));
  _target(tester, _touchOwner());
  if (expanded) {
    expect(
      tester.getRect(_touchOwner()).width / _navigation(tester).items.length,
      greaterThanOrEqualTo(44),
    );
  }
}

void _expectBrowseGeometry(
  WidgetTester tester,
  Size size, {
  required bool expanded,
}) {
  final header = tester.getRect(_key('concept_browse_header'));
  final title = tester.getRect(_key('concept_browse_title'));
  final menu = tester.getRect(_key('concept_browse_menu'));
  final photo = tester.getRect(_key('concept_browse_portrait_card'));
  final footer = tester.getRect(_key('concept_browse_footer'));
  _edges(header, size.width, 20);
  _edges(photo, size.width, 20);
  _edges(footer, size.width, 20);
  expect(title.left, closeTo(20, .01));
  expect(menu.right, closeTo(size.width - 20, .01));
  expect(title.top, greaterThanOrEqualTo(59 + 16));
  expect(title.bottom, lessThanOrEqualTo(header.bottom + .01));
  expect(photo.top, greaterThanOrEqualTo(header.bottom + 15.99));
  expect(footer.top, greaterThanOrEqualTo(photo.bottom + 15.99));

  final glyph = find.descendant(
    of: _key('concept_browse_menu'),
    matching: find.byIcon(Icons.more_horiz_rounded),
  );
  final glyphRect = tester.getRect(glyph);
  expect(glyphRect.width, 24);
  expect(glyphRect.right, closeTo(size.width - 20, .01));
  _target(tester, _key('concept_browse_menu'));

  final previous = _outerPill(tester, 'concept_previous_profile');
  final next = _outerPill(tester, 'concept_next_profile');
  final request = _outerPill(tester, 'draft_profile_${_person(tester).id}');
  expect(previous.left, closeTo(20, .01));
  expect(next.right, closeTo(size.width - 20, .01));
  expect(previous, request, reason: 'LOCK7 uses one shared request pill.');
  expect(next, request);
  expect(tester.getSize(_key('concept_previous_profile')).width, 68);
  expect(tester.getSize(_key('concept_next_profile')).width, 68);
  for (final key in [
    'concept_previous_profile',
    'concept_next_profile',
    'draft_profile_${_person(tester).id}',
  ]) {
    _target(tester, _key(key));
  }

  final scroll = tester.widget<SingleChildScrollView>(
    _key('concept_browse_design_scroll'),
  );
  final position = find
      .descendant(of: find.byWidget(scroll), matching: find.byType(Scrollable))
      .first;
  expect(tester.state<ScrollableState>(position).position.maxScrollExtent, 0);
  final nav = tester.getRect(_glass());
  _expectRootBarGeometry(tester, size, expanded: expanded);
  expect(nav.top, greaterThanOrEqualTo(footer.bottom + 8));
  expect(tester.takeException(), isNull);
}

Future<void> _mount(
  WidgetTester tester,
  Size size,
  bool quiet, {
  Widget? body,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: quiet,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _boundary,
        child:
            body ??
            ZyraOneJourneyConceptShell(
              fixture: ZyraShellTestFixture().fixture,
              canAct: () => true,
              onExit: () {},
            ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (body == null) {
    // Asset reading and codec work are real asynchronous operations. Wait
    // only for the bounded local deck to publish, then inspect actual frames.
    for (
      var attempt = 0;
      attempt < 100 && _person(tester).photos.isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(_person(tester).photos, isNotEmpty);
    await tester.pumpAndSettle();

    final personId = _person(tester).id;
    final gallery = _key('concept_browse_photo_tap_$personId');
    expect(gallery, findsOneWidget);
    await tester.tap(gallery);
    await tester.pumpAndSettle();
    expect(_browse(tester).initialGalleryIndices[personId], 1);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, isNotEmpty);
    expect(images.every((image) => image.image is MemoryImage), isTrue);
    final frames = tester.widgetList<RawImage>(find.byType(RawImage));
    expect(frames, isNotEmpty);
    expect(frames.every((image) => image.image != null), isTrue);
    final photoRect = tester.getRect(gallery);
    await tester.tapAt(
      Offset(photoRect.left + photoRect.width * .25, photoRect.center.dy),
    );
    await tester.pumpAndSettle();
    expect(_browse(tester).initialGalleryIndices[personId], 0);
  }
  expect(tester.takeException(), isNull);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> _press(WidgetTester tester, String key) async {
  if (await pressZyraDevControlKey(tester, key)) return;
  _target(tester, _key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Finder _barIcon(WidgetTester tester, String label) {
  final item = _navigation(
    tester,
  ).items.singleWhere((item) => item.label == label);
  final icon = find.descendant(
    of: find.byType(FloatingNavBar),
    matching: find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  return icon;
}

Future<TestGesture> _holdBar(WidgetTester tester, Finder icon) async {
  _target(tester, _touchOwner());
  final point = tester.getCenter(icon);
  expect(tester.getRect(_touchOwner()).contains(point), isTrue);
  final finger = await tester.startGesture(point);
  // A real stationary pointer needs the tap-down deadline before the bar
  // owns the touch; then its existing 220ms vertical breath can finish.
  await tester.pump(const Duration(milliseconds: 110));
  await tester.pump(const Duration(milliseconds: 220));
  expect(tester.takeException(), isNull);
  return finger;
}

Future<void> _snapshot(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(
    _captureDirectory.startsWith('/'),
    isTrue,
    reason: 'Captures require an explicit absolute evidence directory.',
  );
  expect(_captureDirectory.contains('/SOURCE/'), isFalse);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory(_captureDirectory);
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late bool previousFontStubs;
  late String? previousReadingFont;
  late bool previousFatal;
  late ZyraNavStyle previousNavStyle;
  late ZyraHapticLevel previousHaptic;
  late ZyraDevPalette previousPalette;

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
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousFontStubs = ZyraText.useTestFontStubs;
    previousReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    previousFatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    previousNavStyle = ZyraInteractionStyle.navStyle;
    previousHaptic = ZyraInteractionStyle.hapticLevel;
    previousPalette = ZyraColors.devPalette;
    ZyraInteractionStyle.selectNavStyle(ZyraNavStyle.floatingGlass);
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    expect(network.attempts, 0);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = previousFontStubs;
    ZyraText.testReadingFontFamily = previousReadingFont;
    WidgetController.hitTestWarningShouldBeFatal = previousFatal;
    ZyraInteractionStyle.selectNavStyle(previousNavStyle);
    ZyraInteractionStyle.selectHapticLevel(previousHaptic);
    ZyraColors.selectDevPalette(previousPalette);
  });

  for (final size in const [Size(375, 812), Size(393, 852), Size(430, 932)]) {
    for (final quiet in [false, true]) {
      testWidgets(
        'Actual Browse has one 20px edge at ${size.width}, quiet=$quiet',
        (tester) async {
          await _mount(tester, size, quiet);
          expect(_person(tester).id, _sara);
          _expectBrowseGeometry(tester, size, expanded: false);
          final card = tester.getRect(_key('concept_browse_portrait_card'));
          final initial = tester.getRect(_glass());
          await _snapshot(
            tester,
            '${size.width.toInt()}_${quiet ? 'quiet' : 'motion'}_browse',
          );

          await expandZyraPreviewTabBarIfIdle(tester);
          _expectBrowseGeometry(tester, size, expanded: true);
          expect(_person(tester).id, _sara);
          final held = await _holdBar(tester, _barIcon(tester, 'Profiles'));
          _expectRootBarGeometry(tester, size, expanded: true);
          expect(tester.getRect(_glass()).height, greaterThan(initial.height));
          expect(_person(tester).id, _sara);
          await held.up();
          await tester.pumpAndSettle();
          _expectBrowseGeometry(tester, size, expanded: true);
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
          _expectBrowseGeometry(tester, size, expanded: false);
          expect(tester.getRect(_key('concept_browse_portrait_card')), card);

          await _press(tester, 'draft_profile_$_sara');
          expect(_browse(tester).invitationSent!(_person(tester)), isTrue);
          await expandZyraPreviewTabBarIfIdle(tester);
          _expectBrowseGeometry(tester, size, expanded: true);
          expect(tester.getRect(_key('concept_browse_portrait_card')), card);
          await _press(tester, 'concept_next_profile');
          expect(_person(tester).id, _aisha);
          await expandZyraPreviewTabBarIfIdle(tester);
          _expectBrowseGeometry(tester, size, expanded: true);
          await _press(tester, 'concept_previous_profile');
          expect(_person(tester).id, _sara);
          expect(_browse(tester).invitationSent!(_person(tester)), isTrue);

          await _press(tester, 'concept_browse_menu');
          expect(_navigation(tester).items.map((item) => item.label), _actions);
          _edges(tester.getRect(_glass()), size.width, 20);
          expect(tester.getRect(_key('concept_browse_portrait_card')), card);
          expect(_person(tester).id, _sara);
          await _snapshot(
            tester,
            '${size.width.toInt()}_${quiet ? 'quiet' : 'motion'}_menu',
          );
          final hide = await _holdBar(tester, _barIcon(tester, 'Hide profile'));
          _edges(tester.getRect(_glass()), size.width, 20);
          expect(
            _key('concept_browse_hide_confirmation'),
            findsNothing,
            reason: 'The action bar must wait for a real release.',
          );
          await hide.up();
          await tester.pumpAndSettle();
          expect(_key('concept_browse_hide_confirmation'), findsOneWidget);
          expect(_key('browse-hide-outer-surface'), findsNothing);
          final cancel = tester.getRect(_key('browse-hide-cancel'));
          final confirm = tester.getRect(_key('browse-hide-confirm'));
          expect(cancel.left, closeTo(20, .01));
          expect(confirm.right, closeTo(size.width - 20, .01));
          expect(cancel.width, closeTo(confirm.width, .01));
          expect(confirm.left - cancel.right, greaterThanOrEqualTo(6));
          for (final key in ['browse-hide-cancel', 'browse-hide-confirm']) {
            final target = find
                .descendant(of: _key(key), matching: find.byType(InkWell))
                .first;
            _target(tester, target);
          }
          expect(_person(tester).id, _sara);
          expect(_browse(tester).invitationSent!(_person(tester)), isTrue);
          await _snapshot(
            tester,
            '${size.width.toInt()}_${quiet ? 'quiet' : 'motion'}_hide',
          );
          await _press(tester, 'browse-hide-cancel');
          _edges(tester.getRect(_glass()), size.width, 20);
          expect(_navigation(tester).items.map((item) => item.label), _actions);
          expect(_person(tester).id, _sara);
          expect(_browse(tester).invitationSent!(_person(tester)), isTrue);
          expect(
            _browse(tester).profiles.map((profile) => profile.id),
            contains(_sara),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Default shared bar retains 24px outer inset and 10px idle squeeze',
    (tester) async {
      const size = Size(393, 852);
      var selected = 0;
      await _mount(
        tester,
        size,
        false,
        body: Scaffold(
          body: Stack(
            children: [
              FloatingNavBar(
                items: const [
                  FloatingNavItem(icon: Icons.search, label: 'Browse'),
                  FloatingNavItem(icon: Icons.route_outlined, label: 'Journey'),
                  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
                ],
                currentIndex: 0,
                onTap: (index) => selected = index,
              ),
            ],
          ),
        ),
      );
      _edges(tester.getRect(find.byType(FloatingNavBar)), size.width, 24);
      _edges(tester.getRect(_glass()), size.width, 34);
      final icon = find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.byIcon(Icons.search),
      );
      final held = await _holdBar(tester, icon);
      _edges(tester.getRect(_glass()), size.width, 24);
      await held.up();
      await tester.pumpAndSettle();
      _edges(tester.getRect(_glass()), size.width, 34);
      expect(selected, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
