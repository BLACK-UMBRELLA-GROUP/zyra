// The shared presenter, offline paint fixtures and an optional actual-shell
// PNG. No member data, provider, device, golden baseline or photo editing.
import 'dart:async';
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
import 'package:zyra/widgets/zyra_browse_designs.dart';

const _captureDirectory = String.fromEnvironment(
  'ZYRA_TOP_DOTS_CAPTURE_DIRECTORY',
);
const _font = 'PoppinsTopPhotoPagination';
const _boundary = ValueKey('top-photo-pagination-capture');
const _id = 'top-pagination-sara';
const _photos = ['paint-0', 'paint-1', 'paint-2'];
const _navItems = [
  FloatingNavItem(icon: Icons.search, label: 'Profiles'),
  FloatingNavItem(icon: Icons.people_outline, label: 'Journey'),
  FloatingNavItem(icon: Icons.dashboard_outlined, label: 'My ZYRA'),
  FloatingNavItem(icon: Icons.shield_outlined, label: 'Guardian'),
  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
];

Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _row => _key('concept_browse_photo_pagination');
Finder get _card => _key('concept_browse_portrait_card');
Finder get _footer => _key('concept_browse_footer');
Finder _dot(int index, [String id = _id]) =>
    _key('concept_browse_photo_dot_${id}_$index');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Top-pagination evidence must remain offline.');
  }
}

SeekerProfile _person({int count = 3, bool longText = false}) => SeekerProfile(
  id: _id,
  firstName: longText ? 'A very long fictional given name' : 'Sara',
  surnameLine: longText ? 'A very long fictional family name' : 'Ahmed',
  age: 27,
  city: longText ? 'Royal Leamington Spa, Warwickshire' : 'Birmingham',
  gender: 'female',
  publicNationality: 'Pakistani',
  publicEthnicity: 'Pakistani',
  photos: _photos.take(count).toList(growable: false),
);

Widget _presenter({
  int count = 3,
  bool readOnly = false,
  bool longText = false,
  int initial = 0,
  VoidCallback? decision,
  void Function(String, int)? changed,
}) => ZyraBrowseDesigns(
  key: const ValueKey('top-pagination-presenter'),
  profiles: [_person(count: count, longText: longText)],
  selectedIndex: 0,
  design: ZyraOneJourneyBrowseDesign.portraitCard,
  readOnlyPreview: readOnly,
  showSave: false,
  initialGalleryIndices: {_id: initial},
  onGalleryIndexChanged: changed,
  photoBuilder:
      (context, photo, {required width, required height, required alignment}) =>
          ColoredBox(
            color: photo.endsWith('1') ? Colors.blueGrey : Colors.grey,
          ),
  onFilters: () {},
  onPrevious: decision,
  onNext: decision,
  onRequest: (_) => decision?.call(),
  onProfile: (_) => decision?.call(),
  onSave: (_) => decision?.call(),
);

Widget _app(
  Widget presenter, {
  double scale = 1,
  bool reducedMotion = false,
  bool shell = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      disableAnimations: reducedMotion,
    ),
    child: child!,
  ),
  home: RepaintBoundary(
    key: _boundary,
    child: shell
        ? presenter
        : Scaffold(
            backgroundColor: Colors.transparent,
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: ZyraColors.currentDefaultPalette.gradient,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  presenter,
                  FloatingNavBar(
                    items: _navItems,
                    currentIndex: 0,
                    onTap: (_) {},
                    hapticLevel: ZyraHapticLevel.off,
                  ),
                ],
              ),
            ),
          ),
  ),
);

Future<void> _mount(
  WidgetTester tester,
  Widget presenter, {
  double width = 393,
  double scale = 1,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = Size(width, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(presenter, scale: scale, reducedMotion: reducedMotion),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectSelected(WidgetTester tester, int selected, {String id = _id}) {
  for (var index = 0; index < 4; index++) {
    final dot = tester.widget<AnimatedContainer>(_dot(index, id));
    expect(dot.constraints!.maxWidth, index == selected ? 20 : 5);
    expect(dot.constraints!.maxHeight, 5);
    expect(dot.margin, const EdgeInsets.symmetric(horizontal: 3));
    expect(
      (dot.decoration! as BoxDecoration).color,
      index == selected ? ZyraColors.journeyGold : ZyraColors.ink(.25),
    );
  }
}

void _expectPlacement(WidgetTester tester) {
  final row = tester.getRect(_row);
  final card = tester.getRect(_card);
  expect(row.height, 16);
  expect(row.left, closeTo(card.left, .01));
  expect(row.right, closeTo(card.right, .01));
  expect(row.center.dx, closeTo(card.center.dx, .01));
  expect(row.bottom, closeTo(card.top, .01));
  final first = tester.getRect(_dot(0));
  final last = tester.getRect(_dot(3));
  expect((first.left + last.right) / 2, closeTo(card.center.dx, .01));
  for (var index = 0; index < 4; index++) {
    final dot = tester.getRect(_dot(index));
    expect(row.contains(dot.topLeft), isTrue);
    expect(row.contains(dot.bottomRight), isTrue);
    expect(dot.center.dy, closeTo(row.center.dy - 4, .01));
    expect(dot.bottom, lessThan(card.top));
  }
  expect(
    find.ancestor(of: _row, matching: find.byType(ClipRRect)),
    findsNothing,
    reason: 'Pagination must not be inside the clipped portrait viewport.',
  );
}

Future<void> _capture(WidgetTester tester) async {
  final directory = Directory(_captureDirectory);
  expect(_captureDirectory.startsWith('/'), isTrue);
  expect(directory.existsSync(), isTrue);
  expect(directory.resolveSymbolicLinksSync(), _captureDirectory);
  final source = Directory.current.resolveSymbolicLinksSync();
  expect(
    _captureDirectory == source || _captureDirectory.startsWith('$source/'),
    isFalse,
    reason: 'Capture evidence belongs in the owned packet, not SOURCE.',
  );
  final file = File('$_captureDirectory/browse_top_dots_393.png');
  expect(
    file.existsSync(),
    isFalse,
    reason: 'Never overwrite existing evidence.',
  );
  final visiblePortraits = find
      .descendant(of: _card, matching: find.byType(RawImage))
      .hitTestable();
  for (var frame = 0; frame < 100; frame++) {
    final portraits = tester.widgetList<RawImage>(visiblePortraits).toList();
    if (portraits.isNotEmpty &&
        portraits.every((image) => image.image != null)) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  final portraits = tester.widgetList<RawImage>(visiblePortraits).toList();
  expect(portraits, isNotEmpty, reason: 'Capture the visible actual portrait.');
  for (final portrait in portraits) {
    expect(
      portrait.image,
      isNotNull,
      reason: 'Do not capture blank photo frames.',
    );
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.create(exclusive: true);
      await file.writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late bool previousStubs;
  late String? previousFont;
  late ZyraDevPalette previousPalette;
  late ZyraHapticLevel previousHaptics;
  late ZyraNavStyle previousNav;

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
    previousStubs = ZyraText.useTestFontStubs;
    previousFont = ZyraText.testReadingFontFamily;
    previousPalette = ZyraColors.devPalette;
    previousHaptics = ZyraInteractionStyle.hapticLevel;
    previousNav = ZyraInteractionStyle.navStyle;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    ZyraInteractionStyle.selectNavStyle(
      ZyraInteractionStyle.currentDefaultNavStyle,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = previousStubs;
    ZyraText.testReadingFontFamily = previousFont;
    ZyraColors.selectDevPalette(previousPalette);
    ZyraInteractionStyle.selectHapticLevel(previousHaptics);
    ZyraInteractionStyle.selectNavStyle(previousNav);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('top dots are centred above and outside the unchanged card', (
    tester,
  ) async {
    await _mount(tester, _presenter());
    _expectSelected(tester, 0);
    _expectPlacement(tester);
    final card = tester.getRect(_card);
    final footer = tester.getRect(_footer);
    for (final count in [1, 0, 3]) {
      await tester.pumpWidget(_app(_presenter(count: count)));
      await tester.pumpAndSettle();
      expect(tester.getRect(_card), card);
      expect(tester.getRect(_footer), footer);
      expect(_row, count == 0 ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'gold elongated selection follows existing tap and swipe callbacks',
    (tester) async {
      final changed = <(String, int)>[];
      var decisions = 0;
      await _mount(
        tester,
        _presenter(
          changed: (id, index) => changed.add((id, index)),
          decision: () => decisions++,
        ),
      );
      final card = tester.getRect(_card);
      await tester.tap(_key('concept_browse_photo_tap_$_id'));
      await tester.pumpAndSettle();
      _expectSelected(tester, 1);
      await tester.drag(
        _key('concept_browse_photo_swipe_$_id'),
        const Offset(-260, 0),
      );
      await tester.pumpAndSettle();
      _expectSelected(tester, 2);
      expect(changed, [(_id, 1), (_id, 2)]);
      expect(decisions, 0);
      expect(tester.getRect(_card), card);
      _expectPlacement(tester);
    },
  );

  testWidgets('restored photo selection is reflected without a new callback', (
    tester,
  ) async {
    var changes = 0;
    await _mount(tester, _presenter(initial: 2, changed: (_, _) => changes++));
    _expectSelected(tester, 2);
    expect(changes, 0);
  });

  testWidgets('pagination is decorative with one photo-count semantics node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var changes = 0;
      await _mount(tester, _presenter(changed: (_, _) => changes++));
      expect(
        find.ancestor(of: _row, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      expect(
        find.ancestor(of: _row, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      expect(
        find.descendant(of: _row, matching: find.byType(GestureDetector)),
        findsNothing,
      );
      expect(find.bySemanticsLabel(RegExp(r'Profile details')), findsOneWidget);
      await tester.tapAt(tester.getCenter(_dot(2)));
      await tester.pumpAndSettle();
      _expectSelected(tester, 0);
      expect(changes, 0);
      expect(find.bySemanticsLabel(RegExp(r'Profile details')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reduced motion removes dot animation duration', (tester) async {
    await _mount(tester, _presenter(), reducedMotion: true);
    expect(tester.widget<AnimatedContainer>(_dot(0)).duration, Duration.zero);
    await tester.tap(_key('concept_browse_photo_tap_$_id'));
    await tester.pumpAndSettle();
    _expectSelected(tester, 1);
    _expectPlacement(tester);
  });

  testWidgets('ordinary motion uses the quiet 180ms transition', (
    tester,
  ) async {
    await _mount(tester, _presenter());
    expect(
      tester.widget<AnimatedContainer>(_dot(0)).duration,
      const Duration(milliseconds: 180),
    );
  });

  testWidgets(
    'read-only profile preview shares pagination but decision buttons stay inert',
    (tester) async {
      var decisions = 0;
      await _mount(
        tester,
        _presenter(readOnly: true, decision: () => decisions++),
      );
      _expectPlacement(tester);
      for (final key in [
        'concept_previous_profile',
        'draft_profile_$_id',
        'concept_next_profile',
      ]) {
        expect(tester.widget<InkWell>(_key(key)).onTap, isNull);
      }
      await tester.tap(_key('concept_browse_photo_tap_$_id'));
      await tester.pumpAndSettle();
      _expectSelected(tester, 1);
      expect(decisions, 0);
    },
  );

  testWidgets(
    '320px at 200 percent keeps long text and footer scrollable above navigation',
    (tester) async {
      await _mount(tester, _presenter(longText: true), width: 320, scale: 2);
      _expectPlacement(tester);
      await tester.ensureVisible(_footer);
      await tester.pumpAndSettle();
      final footer = tester.getRect(_footer);
      final nav = tester.getRect(_key('floating-nav-item-0'));
      expect(footer.left, greaterThanOrEqualTo(20));
      expect(footer.right, lessThanOrEqualTo(300));
      expect(footer.bottom, lessThan(nav.top));
      expect(tester.takeException(), isNull);
    },
  );

  if (_captureDirectory.isNotEmpty) {
    testWidgets(
      'capture actual offline portrait, brand typography and navigation',
      (tester) async {
        ZyraDeveloperAccess.resetAuthorizationForTesting();
        ZyraDeveloperAccess.setAuthorizedForTesting(true);
        addTearDown(() {
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          ZyraDeveloperAccess.resetAuthorizationForTesting();
        });
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final ready = Completer<void>();
        await tester.pumpWidget(
          _app(
            ZyraOneJourneyConceptShell(
              canAct: () => true,
              onExit: () {},
              onPresentationReady: () {
                if (!ready.isCompleted) ready.complete();
              },
            ),
            reducedMotion: true,
            shell: true,
          ),
        );
        for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
          await tester.pump(const Duration(milliseconds: 20));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        }
        expect(
          ready.isCompleted,
          isTrue,
          reason: 'Actual bundled portraits ready',
        );
        await tester.pumpAndSettle();
        final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
          find.byType(ZyraOneJourneyBrowseDesigns),
        );
        final person = browse.profiles[browse.selectedIndex];
        expect(person.photos.length, greaterThan(1));
        expect(
          person.photos.every((photo) => photo.startsWith('data:image/')),
          isTrue,
        );
        await tester.tap(_key('concept_browse_photo_tap_${person.id}'));
        await tester.pumpAndSettle();
        expect(
          (tester.widget<AnimatedContainer>(_dot(1, person.id)).decoration!
                  as BoxDecoration)
              .color,
          ZyraColors.journeyGold,
        );
        expect(find.byType(FloatingNavBar), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
