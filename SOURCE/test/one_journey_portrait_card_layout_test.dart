// Founder-requested Portrait-card layout only. This directly exercises the
// offline presenter; root shell tests remain the owner/authority boundary.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

const _capture = bool.fromEnvironment('ZYRA_PORTRAIT_CARD_LAYOUT_CAPTURE');
const _boundary = ValueKey('portrait-card-layout-candidate');
const _candidates = String.fromEnvironment(
  'ZYRA_PORTRAIT_CARD_LAYOUT_CANDIDATES',
  defaultValue: 'visual/candidates/browse_gallery_filters_2026_10_09',
);
const _font = 'PoppinsPortraitLayout';
const _bottomPadding = 104.0; // max(34 safe, 14 inset) + 58 nav + 12 gap.
late ZyraOneJourneySamplePhotos _samples;

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Portrait layout fixtures must remain offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

void _expectSelectedDot(WidgetTester tester, int index) {
  final dot = tester.widget<AnimatedContainer>(
    _key('concept_browse_photo_dot_portrait-sara_$index'),
  );
  expect(dot.constraints!.maxWidth, 20);
  expect(dot.constraints!.maxHeight, 5);
  expect((dot.decoration! as BoxDecoration).color, ZyraColors.journeyGold);
}

SeekerProfile _profile({
  String id = 'portrait-sara',
  String first = 'Sara',
  String surname = 'Ahmed',
  int photos = 2,
}) => SeekerProfile(
  id: id,
  firstName: first,
  surnameLine: surname,
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  photos: _samples.sets.first.take(photos).toList(growable: false),
);

Widget _presenter({
  List<SeekerProfile>? profiles,
  int selected = 0,
  VoidCallback? previous,
  VoidCallback? next,
  VoidCallback? filters,
  ValueChanged<SeekerProfile>? request,
}) => ZyraOneJourneyBrowseDesigns(
  key: const ValueKey('portrait-layout-presenter'),
  profiles: profiles ?? [_profile()],
  selectedIndex: selected,
  design: ZyraOneJourneyBrowseDesign.portraitCard,
  bottomPadding: 100,
  showSave: false,
  onPrevious: previous ?? () {},
  onNext: next ?? () {},
  onFilters: filters ?? () {},
  onRequest: request ?? (_) {},
);

Widget _app(
  Widget presenter, {
  double scale = 1,
  double top = 59,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: EdgeInsets.only(top: top, bottom: 34),
      viewPadding: EdgeInsets.only(top: top, bottom: 34),
      disableAnimations: true,
    ),
    child: RepaintBoundary(key: _boundary, child: child!),
  ),
  home: Scaffold(
    backgroundColor: ZyraColors.luxuryDarkPurple,
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          presenter,
          FloatingNavBar(
            items: const [
              FloatingNavItem(icon: Icons.search, label: 'Browse'),
              FloatingNavItem(
                icon: Icons.route_outlined,
                label: 'Journey',
                useJourneyGlyph: true,
              ),
              FloatingNavItem(icon: Icons.dashboard_outlined, label: 'My ZYRA'),
              FloatingNavItem(icon: Icons.gpp_good_outlined, label: 'Guardian'),
              FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
            currentIndex: 0,
            onTap: (_) {},
          ),
        ],
      ),
    ),
  ),
);

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(393, 852),
  double scale = 1,
  double top = 59,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(child, scale: scale, top: top));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

ScrollableState _scrollState(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find
          .descendant(
            of: _key('concept_browse_design_scroll'),
            matching: find.byType(Scrollable),
          )
          .first,
    );

Future<void> _press(WidgetTester tester, String id) async {
  final target = _key(id);
  expect(target, findsOneWidget);
  final ancestor = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (ancestor.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  final navTop = tester.getRect(find.byType(FloatingNavBar)).top;
  var visible = tester
      .getRect(target)
      .intersect(Rect.fromLTRB(0, 0, tester.view.physicalSize.width, navTop));
  if (ancestor.evaluate().isNotEmpty) {
    visible = visible.intersect(tester.getRect(ancestor.first));
  }
  expect(visible.width, greaterThan(0), reason: '$id clears navigation');
  expect(
    visible.height,
    greaterThan(0),
    reason: '$id has visible reading space',
  );
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  final point = Alignment(
    local.dx * 2 / box.size.width - 1,
    local.dy * 2 / box.size.height - 1,
  );
  expect(target.hitTestable(at: point), findsOneWidget);
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectTitle(WidgetTester tester, {double top = 59}) {
  final title = _key('concept_browse_title');
  expect(title, findsOneWidget);
  final text = tester.widget<Text>(title);
  expect(text.data, 'Profiles');
  expect(text.style!.fontSize, 26);
  expect(text.style!.fontWeight, FontWeight.w200);
  expect(text.style!.fontFamily, _font);
  final rect = tester.getRect(title);
  expect(rect.left, 20);
  expect(text.textAlign, TextAlign.left);
  expect(rect.top, closeTo(top + 16, .01));
  final highestText = tester
      .widgetList<Text>(find.byType(Text))
      .where((text) => text.data != null && text.data!.isNotEmpty);
  for (final text in highestText) {
    expect(
      tester.getRect(find.byWidget(text)).top,
      greaterThanOrEqualTo(rect.top),
      reason: 'Browse is the highest page text, including ${text.data}',
    );
  }
}

void _expectStandardGeometry(WidgetTester tester, Size size) {
  _expectTitle(tester);
  final card = tester.getRect(_key('concept_browse_portrait_card'));
  final footer = tester.getRect(_key('concept_browse_footer'));
  final previous = tester.getRect(_key('concept_previous_profile'));
  final next = tester.getRect(_key('concept_next_profile'));
  final header = tester.getRect(_key('concept_browse_header'));
  final request = tester.getRect(_key('draft_profile_portrait-sara'));
  final label = find.descendant(
    of: _key('draft_profile_portrait-sara'),
    matching: find.byType(Text),
  );
  final labelRect = tester.getRect(label);
  final requestText = tester.widget<Text>(label);
  expect(previous.width, lessThan(next.width));
  expect(next.width, lessThan(request.width));
  expect(previous.width, greaterThanOrEqualTo(48));
  expect(next.height, previous.height);
  expect(requestText.data, 'Request Journey');
  expect(requestText.textAlign, TextAlign.center);
  expect(requestText.style!.fontSize, 14);
  expect(requestText.style!.fontWeight, FontWeight.w400);
  expect(requestText.style!.fontFamily, _font);
  expect(labelRect.center.dx, closeTo(request.center.dx, .01));
  expect(labelRect.center.dy, closeTo(request.center.dy, .01));
  expect(card.left, 20);
  expect(card.right, size.width - 20);
  expect(card.top, greaterThan(header.bottom));
  expect(
    card.height,
    greaterThan(420),
    reason: 'Card occupies the usable canvas',
  );
  expect(previous.top, greaterThanOrEqualTo(card.bottom));
  expect(next.top, greaterThanOrEqualTo(card.bottom));
  expect(footer.top - card.bottom, inInclusiveRange(10.0, 20.0));
  expect(
    footer.bottom,
    closeTo(size.height - _bottomPadding, 1),
    reason:
        'header=${header.height}, card=${card.height}, footer=${footer.height}',
  );
  final nav = tester.getRect(find.byType(FloatingNavBar));
  expect(nav.top - footer.bottom, inInclusiveRange(12.0, 24.0));
  expect(_scrollState(tester).position.maxScrollExtent, closeTo(0, .01));
  expect(_key('concept_save_portrait-sara'), findsNothing);
  expect(find.text('Back'), findsNothing);
  expect(find.text('Pass'), findsNothing);
  expect(find.text('Dislike'), findsNothing);
  expect(find.text('Next profile'), findsNothing);
  expect(find.textContaining('photos'), findsNothing);
  expect(_key('concept_browse_photo_next_portrait-sara'), findsNothing);
  expect(_key('concept_browse_photo_previous_portrait-sara'), findsNothing);
  for (final image in find.byType(ZyraProfileImage).evaluate()) {
    final rect = tester.getRect(find.byWidget(image.widget));
    // The former 24px padding + 2px border now belongs to the image, not
    // additional card area. Header/footer/nav checks above stay unchanged.
    expect(rect.height, lessThan(size.height * .65 + 26));
    final visible = rect.intersect(card);
    if (!visible.isEmpty) {
      expect(card.contains(visible.topLeft), isTrue);
      expect(
        card.contains(visible.bottomRight - const Offset(.01, .01)),
        isTrue,
      );
    }
  }
}

Future<void> _snapshot(WidgetTester tester, String name) async {
  if (!_capture) return;
  for (final image in tester.widgetList<Image>(find.byType(Image))) {
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
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        bytes!.buffer.asUint8List(),
        matchesGoldenFile('$_candidates/$name.png'),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final priorFatal = WidgetController.hitTestWarningShouldBeFatal;
  final priorOverrides = HttpOverrides.current;
  late _NoNetwork network;
  setUpAll(() async {
    WidgetController.hitTestWarningShouldBeFatal = true;
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
    _samples = await ZyraOneJourneySamplePhotos.load();
  });
  tearDownAll(() {
    WidgetController.hitTestWarningShouldBeFatal = priorFatal;
    HttpOverrides.global = priorOverrides;
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = priorOverrides;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final viewport in const [
    (size: Size(320, 852), photos: 2, suffix: '320_2photos'),
    (size: Size(393, 852), photos: 2, suffix: '393_2photos'),
    (size: Size(430, 932), photos: 3, suffix: '430_3photos'),
    (size: Size(430, 932), photos: 1, suffix: '430_1photo'),
  ]) {
    testWidgets('Portrait fills ${viewport.suffix} below highest title', (
      tester,
    ) async {
      final requests = <String>[];
      var next = 0, previous = 0, filters = 0;
      await _mount(
        tester,
        _presenter(
          profiles: [_profile(photos: viewport.photos)],
          next: () => next++,
          previous: () => previous++,
          filters: () => filters++,
          request: (p) => requests.add(p.id),
        ),
        size: viewport.size,
      );
      _expectStandardGeometry(tester, viewport.size);
      if (viewport.suffix != '320_2photos') {
        await _snapshot(tester, viewport.suffix);
      }
      await _press(tester, 'concept_next_profile');
      await _press(tester, 'concept_previous_profile');
      await _press(tester, 'concept_filters');
      expect((next, previous, filters), (1, 1, 1));
      expect(requests, isEmpty, reason: 'Navigation is not a profile decision');
      if (viewport.photos > 1) {
        await tester.drag(
          _key('concept_browse_photo_swipe_portrait-sara'),
          const Offset(-300, 0),
        );
        await tester.pumpAndSettle();
        _expectSelectedDot(tester, 1);
        await tester.drag(
          _key('concept_browse_photo_swipe_portrait-sara'),
          const Offset(300, 0),
        );
        await tester.pumpAndSettle();
        _expectSelectedDot(tester, 0);
      } else {
        expect(_key('concept_browse_photo_next_portrait-sara'), findsNothing);
      }
      await _press(tester, 'draft_profile_portrait-sara');
      expect(requests, ['portrait-sara']);
    });
  }

  testWidgets(
    'compact 200% Portrait exposes real gallery/request/navigation taps',
    (tester) async {
      final requests = <String>[];
      var next = 0, previous = 0, filters = 0;
      await _mount(
        tester,
        _presenter(
          request: (p) => requests.add(p.id),
          next: () => next++,
          previous: () => previous++,
          filters: () => filters++,
        ),
        size: const Size(320, 568),
        scale: 2,
        top: 44,
      );
      _expectTitle(tester, top: 44);
      expect(_scrollState(tester).position.maxScrollExtent, greaterThan(0));
      await _snapshot(tester, 'compact_200_initial');
      await _press(tester, 'concept_filters');
      final pager = _key('concept_browse_photo_swipe_portrait-sara');
      await tester.ensureVisible(pager);
      await tester.pumpAndSettle();
      await tester.drag(pager, const Offset(-220, 0));
      await tester.pumpAndSettle();
      _expectSelectedDot(tester, 1);
      await _press(tester, 'draft_profile_portrait-sara');
      expect(requests, ['portrait-sara']);
      await _press(tester, 'concept_next_profile');
      await _press(tester, 'concept_previous_profile');
      expect((next, previous, filters), (1, 1, 1));
      await _snapshot(tester, 'compact_200_controls');
      expect(_key('concept_save_portrait-sara'), findsNothing);
    },
  );

  testWidgets('Portrait long public identity remains legible at 140%', (
    tester,
  ) async {
    final requests = <String>[];
    await _mount(
      tester,
      _presenter(
        profiles: [
          _profile(first: 'Aisha Mariam', surname: 'Abdul Rahman Ahmed'),
        ],
        request: (p) => requests.add(p.id),
      ),
      scale: 1.4,
    );
    _expectTitle(tester);
    expect(find.text('Aisha Mariam'), findsOneWidget);
    expect(find.text('Abdul Rahman Ahmed'), findsOneWidget);
    await _press(tester, 'draft_profile_portrait-sara');
    expect(requests, ['portrait-sara']);
    await _press(tester, 'concept_next_profile');
    await _snapshot(tester, 'long_identity_140_controls');
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty Portrait deck keeps highest title and reachable filters', (
    tester,
  ) async {
    var filters = 0;
    await _mount(tester, _presenter(profiles: [], filters: () => filters++));
    _expectTitle(tester);
    expect(find.text('No profiles to view right now.'), findsOneWidget);
    expect(_key('concept_browse_portrait_card'), findsNothing);
    expect(find.byType(ZyraProfileImage), findsNothing);
    await _press(tester, 'concept_filters');
    expect(filters, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('old Portrait request retains its rendered profile/delegate', (
    tester,
  ) async {
    final oldCalls = <String>[], currentCalls = <String>[];
    final people = [_profile(), _profile(id: 'portrait-amira', first: 'Amira')];
    await _mount(
      tester,
      _presenter(profiles: people, request: (p) => oldCalls.add(p.id)),
    );
    final old = tester
        .widget<InkWell>(_key('draft_profile_portrait-sara'))
        .onTap!;
    await tester.pumpWidget(
      _app(
        _presenter(
          profiles: people,
          selected: 1,
          request: (p) => currentCalls.add(p.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Deliberate retained-delegate check, not an ordinary UI tap. The caller
    // owns stale authority rejection; it must never receive a newer delegate.
    old();
    expect(oldCalls, ['portrait-sara']);
    expect(currentCalls, isEmpty);
    await _press(tester, 'draft_profile_portrait-amira');
    expect(currentCalls, ['portrait-amira']);
    expect(tester.takeException(), isNull);
  });
}
