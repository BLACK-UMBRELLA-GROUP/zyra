// Scoped Current Browse presentation tests. Invented public records and an
// injected paint-only renderer: no member, network or entitlement authority.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';

const _font = 'PoppinsBrowsePolish';
const _person = SeekerProfile(
  id: 'photo-polish-person',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  publicNationality: 'British',
  publicEthnicity: 'South Asian',
  photos: ['offline-paint-0', 'offline-paint-1', 'offline-paint-2'],
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Browse polish fixtures must remain offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _dot(int index) => _key('concept_browse_photo_dot_${_person.id}_$index');
Finder get _pager => _key('concept_browse_photo_swipe_${_person.id}');

Widget _presenter({
  SeekerProfile person = _person,
  VoidCallback? previous,
  VoidCallback? next,
  ValueChanged<SeekerProfile>? request,
  ValueChanged<SeekerProfile>? open,
}) => ZyraBrowseDesigns(
  profiles: [person],
  selectedIndex: 0,
  design: ZyraOneJourneyBrowseDesign.portraitCard,
  showSave: false,
  photoBuilder:
      (context, photo, {required width, required height, required alignment}) =>
          ColoredBox(
            color: photo.endsWith('1') ? Colors.blueGrey : Colors.grey,
          ),
  onPrevious: previous ?? () {},
  onNext: next ?? () {},
  onFilters: () {},
  onRequest: request ?? (_) {},
  onProfile: open,
);

Widget _app(Widget presenter, {double scale = 1}) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        presenter,
        FloatingNavBar(
          items: const [
            FloatingNavItem(icon: Icons.search, label: 'Browse'),
            FloatingNavItem(icon: Icons.route_outlined, label: 'Journey'),
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
);

Future<void> _mount(
  WidgetTester tester,
  Widget presenter, {
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(presenter, scale: scale));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Rect _paintRect(WidgetTester tester, int index) => tester.getRect(
  find.descendant(of: _dot(index), matching: find.byType(DecoratedBox)),
);

Color? _color(WidgetTester tester, int index) =>
    (tester.widget<AnimatedContainer>(_dot(index)).decoration! as BoxDecoration)
        .color;

void _expectHeaderDots(WidgetTester tester, {int selected = 0}) {
  final photo = tester.getRect(_pager);
  final pagination = tester.getRect(_key('concept_browse_photo_pagination'));
  final dots = List.generate(4, (index) => _paintRect(tester, index));
  expect(pagination.height, 16);
  expect(pagination.bottom, closeTo(photo.top, .01));
  for (var index = 0; index < 4; index++) {
    final container = tester.widget<AnimatedContainer>(_dot(index));
    final width = index == selected ? 20.0 : 5.0;
    expect(container.constraints!.maxWidth, width);
    expect(container.constraints!.maxHeight, 5);
    expect(container.margin, const EdgeInsets.symmetric(horizontal: 3));
    expect(container.duration, Duration.zero);
    expect(
      (container.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(20),
    );
    expect(dots[index].size, Size(width, 5));
    expect(dots[index].center.dy, closeTo(pagination.center.dy - 4, .01));
    expect(dots[index].top, greaterThanOrEqualTo(pagination.top));
    expect(dots[index].bottom, lessThan(photo.top));
    expect(
      _color(tester, index),
      index == selected ? ZyraColors.journeyGold : ZyraColors.ink(.25),
    );
  }
  expect(dots[1].left - dots[0].right, closeTo(6, .01));
  expect(dots[2].left - dots[1].right, closeTo(6, .01));
  expect(dots[3].left - dots[2].right, closeTo(6, .01));
  expect(
    (dots.first.left + dots.last.right) / 2,
    closeTo(photo.center.dx, .01),
    reason: 'The horizontal group stays centred in the existing header gap.',
  );
  expect(
    find.ancestor(of: _dot(0), matching: _pager),
    findsNothing,
    reason: 'Pagination is outside the photograph, not an overlay.',
  );
  expect(
    find.ancestor(of: _dot(0), matching: find.byType(IgnorePointer)),
    findsWidgets,
  );
  expect(
    find.ancestor(of: _dot(0), matching: find.byType(ExcludeSemantics)),
    findsWidgets,
    reason: 'Decorative dots do not duplicate the accessible photo count.',
  );
}

Rect _outerPill(WidgetTester tester, String key) => tester.getRect(
  find.ancestor(of: _key(key), matching: find.byType(SizedBox)).first,
);

void _expectFooter(WidgetTester tester, {bool wrappedRequest = false}) {
  final back = tester.getRect(_key('concept_previous_profile'));
  final next = tester.getRect(_key('concept_next_profile'));
  final request = tester.getRect(_key('draft_profile_${_person.id}'));
  expect(_outerPill(tester, 'concept_previous_profile').width, 50);
  expect(_outerPill(tester, 'concept_next_profile').width, 72);
  expect(back.width, greaterThanOrEqualTo(48));
  expect(next.height, greaterThanOrEqualTo(48));
  expect(next.width, greaterThan(back.width));
  expect(request.width, greaterThan(next.width));
  expect(back.height, 48);
  expect(next.height, 48);
  expect(request.height, wrappedRequest ? 86 : 48);
  expect(back.center.dy, closeTo(request.center.dy, .01));
  expect(next.center.dy, closeTo(request.center.dy, .01));
  final label = find.descendant(
    of: _key('draft_profile_${_person.id}'),
    matching: find.byType(Text),
  );
  final text = tester.widget<Text>(label);
  expect(text.data, 'Request Journey');
  expect(text.textAlign, TextAlign.center);
  expect(text.style!.fontFamily, _font);
  expect(text.style!.fontSize, 14);
  expect(text.style!.fontWeight, FontWeight.w400);
  expect(text.style!.height, 1.25);
  expect(text.style!.letterSpacing, .1);
  expect(text.maxLines, isNull);
  expect(tester.getRect(label).center.dx, closeTo(request.center.dx, .01));
  expect(tester.getRect(label).center.dy, closeTo(request.center.dy, .01));
  for (final (key, glyph, size) in [
    ('concept_previous_profile', Icons.chevron_left, 20.0),
    ('concept_next_profile', Icons.chevron_right, 24.0),
  ]) {
    final icon = tester.widget<Icon>(
      find.descendant(of: _key(key), matching: find.byType(Icon)),
    );
    expect(icon.icon, glyph);
    expect(icon.size, size);
  }
}

Future<void> _press(WidgetTester tester, String key) async {
  final target = _key(key);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  final navTop = tester.getRect(find.byType(FloatingNavBar)).top;
  final visible = tester
      .getRect(target)
      .intersect(Rect.fromLTRB(0, 59, tester.view.physicalSize.width, navTop));
  expect(visible.width, greaterThanOrEqualTo(48));
  expect(visible.height, greaterThanOrEqualTo(48));
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
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
    ]) {
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await font.load();
  });
  setUp(() {
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = priorOverrides;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final size in const [Size(320, 852), Size(393, 852), Size(430, 932)]) {
    testWidgets(
      'Current ${size.width.toInt()} has centred header gold pagination',
      (tester) async {
        await _mount(tester, _presenter(), size: size);
        _expectHeaderDots(tester);
        _expectFooter(tester);
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: _key('concept_browse_design_scroll'),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(scroll.position.maxScrollExtent, 0);
        final footer = tester.getRect(_key('concept_browse_footer'));
        final navigation = tester.getRect(find.byType(FloatingNavBar));
        expect(footer.bottom, lessThanOrEqualTo(navigation.top - 12));
      },
    );
  }

  testWidgets(
    'Swipe updates the selected capsule without moving pagination or profile',
    (tester) async {
      var next = 0, previous = 0, requests = 0, opens = 0;
      await _mount(
        tester,
        _presenter(
          next: () => next++,
          previous: () => previous++,
          request: (_) => requests++,
          open: (_) => opens++,
        ),
      );
      final pagination = tester.getRect(
        _key('concept_browse_photo_pagination'),
      );
      await tester.drag(_pager, const Offset(-260, 0));
      await tester.pumpAndSettle();
      _expectHeaderDots(tester, selected: 1);
      expect(
        tester.getRect(_key('concept_browse_photo_pagination')),
        pagination,
      );
      await tester.drag(_pager, const Offset(260, 0));
      await tester.pumpAndSettle();
      _expectHeaderDots(tester);
      expect(
        tester.getRect(_key('concept_browse_photo_pagination')),
        pagination,
      );
      expect((next, previous, requests, opens), (0, 0, 0, 0));
    },
  );

  testWidgets(
    'Photo semantics retain count and accessible next/previous paging',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _mount(tester, _presenter());
        Semantics photoSemantics(int index) => tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Photo ${index + 1} of 3',
          ),
        );
        final first = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Profile details',
          ),
        );
        expect(first.properties.hint, isNotNull);
        final actions = first.properties.customSemanticsActions!;
        expect(actions.keys.map((action) => action.label).toSet(), {
          'Next page',
          'Previous page',
        });
        actions.entries
            .singleWhere((entry) => entry.key.label == 'Next page')
            .value();
        await tester.pumpAndSettle();
        _expectHeaderDots(tester, selected: 1);
        photoSemantics(0).properties.customSemanticsActions!.entries
            .singleWhere((entry) => entry.key.label == 'Previous page')
            .value();
        await tester.pumpAndSettle();
        _expectHeaderDots(tester);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Current footer keeps fixed navigation widths and equal eight-pixel gaps',
    (tester) async {
      await _mount(tester, _presenter());
      _expectFooter(tester);
      final footer = tester.getRect(_key('concept_browse_footer'));
      final back = _outerPill(tester, 'concept_previous_profile');
      final next = _outerPill(tester, 'concept_next_profile');
      final request = tester.getRect(
        find
            .ancestor(
              of: _key('draft_profile_${_person.id}'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(back.width, 50);
      expect(next.width, 72);
      expect(back.left, closeTo(footer.left, .01));
      expect(next.right, closeTo(footer.right, .01));
      expect(request.left - back.right, closeTo(8, .01));
      expect(next.left - request.right, closeTo(8, .01));
      expect(request.width, closeTo(footer.width - 50 - 72 - 16, .01));
    },
  );

  for (final count in [0, 1]) {
    testWidgets(
      'Current $count-photo record counts details separately from photos',
      (tester) async {
        final person = SeekerProfile(
          id: _person.id,
          firstName: _person.firstName,
          age: _person.age,
          city: _person.city,
          gender: _person.gender,
          photos: _person.photos.take(count).toList(),
        );
        await _mount(tester, _presenter(person: person));
        expect(_pager, findsOneWidget);
        for (var index = 0; index < 4; index++) {
          expect(
            _dot(index),
            count == 1 && index < 2 ? findsOneWidget : findsNothing,
          );
        }
        expect(
          _key('concept_browse_photo_pagination'),
          count == 0 ? findsNothing : findsOneWidget,
        );
        final semantics = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Profile details',
          ),
        );
        expect(
          semantics.properties.customSemanticsActions,
          count == 0 ? isNull : isNotNull,
        );
        expect(semantics.properties.hint, count == 0 ? isNull : isNotNull);
      },
    );
  }

  testWidgets(
    'Compact 200 percent text keeps header dots and all actions usable',
    (tester) async {
      var previous = 0, next = 0;
      final requests = <String>[];
      await _mount(
        tester,
        _presenter(
          previous: () => previous++,
          next: () => next++,
          request: (person) => requests.add(person.id),
        ),
        size: const Size(320, 568),
        scale: 2,
      );
      _expectHeaderDots(tester);
      _expectFooter(tester, wrappedRequest: true);
      await _press(tester, 'concept_previous_profile');
      await _press(tester, 'concept_next_profile');
      expect((previous, next), (1, 1));
      expect(requests, isEmpty);
      await _press(tester, 'draft_profile_${_person.id}');
      expect(requests, [_person.id]);
      expect(_key('concept_save_${_person.id}'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
