// Offline presentation checks only: these are invented public profiles, not
// production disclosure, membership, geographic or matching authority proof.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

const _font = 'PoppinsBrowseGallery';
const _boundary = ValueKey('browse-gallery-candidate');

const _person = SeekerProfile(
  id: 'gallery-person',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  photos: ['offline-photo-0', 'offline-photo-1', 'offline-photo-2'],
  publicNationality: 'British',
  publicEthnicity: 'South Asian',
);

const _other = SeekerProfile(
  id: 'gallery-other',
  firstName: 'Amira',
  age: 28,
  city: 'Manchester',
  gender: 'female',
  photos: ['offline-other-0', 'offline-other-1'],
);

Finder _key(String name) => find.byKey(ValueKey(name));

void _expectSelectedDot(WidgetTester tester, String id, int index) {
  final dot = tester.widget<AnimatedContainer>(
    _key('concept_browse_photo_dot_${id}_$index'),
  );
  expect(dot.constraints!.maxWidth, 20);
  expect(dot.constraints!.maxHeight, 5);
  expect((dot.decoration! as BoxDecoration).color, ZyraColors.journeyGold);
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Browse gallery fixtures must remain offline.');
  }
}

Widget _photo(
  BuildContext context,
  String photo, {
  required double width,
  required double height,
  required Alignment alignment,
}) => photo.startsWith('data:image/')
    ? ZyraProfileImage(
        photo,
        width: width,
        height: height,
        alignment: alignment,
      )
    : ColoredBox(
        color: photo.endsWith('1')
            ? Colors.blueGrey.shade600
            : photo.endsWith('2')
            ? Colors.blueGrey.shade800
            : Colors.blueGrey.shade700,
      );

Widget _presenter({
  ZyraOneJourneyBrowseDesign design = ZyraOneJourneyBrowseDesign.portraitCard,
  List<SeekerProfile> people = const [_person, _other],
  int selected = 0,
  VoidCallback? previous,
  VoidCallback? next,
  VoidCallback? filters,
  ValueChanged<SeekerProfile>? request,
  ValueChanged<SeekerProfile>? profile,
  bool Function(SeekerProfile)? canRequest,
  String Function(SeekerProfile)? requestLabel,
}) => ZyraBrowseDesigns(
  key: const ValueKey('gallery-presenter'),
  profiles: people,
  selectedIndex: selected,
  design: design,
  photoBuilder: _photo,
  showSave: false,
  onPrevious: previous ?? () {},
  onNext: next ?? () {},
  onFilters: filters ?? () {},
  onRequest: request ?? (_) {},
  onProfile: profile,
  canRequest: canRequest,
  requestLabel: requestLabel,
);

Widget _app(Widget presenter, {double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 44, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: RepaintBoundary(
      key: _boundary,
      child: DecoratedBox(
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
                FloatingNavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'My ZYRA',
                ),
                FloatingNavItem(
                  icon: Icons.gpp_good_outlined,
                  label: 'Guardian',
                ),
                FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
              ],
              currentIndex: 0,
              onTap: (_) {},
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

Future<void> _press(WidgetTester tester, String name) async {
  final target = _key(name);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final navTop = tester.getRect(find.byType(FloatingNavBar)).top;
  final visible = tester
      .getRect(target)
      .intersect(Rect.fromLTRB(0, 44, tester.view.physicalSize.width, navTop));
  expect(
    visible.height,
    greaterThan(0),
    reason: '$name clears footer navigation',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _swipe(WidgetTester tester, String id, double direction) async {
  final pager = _key('concept_browse_photo_swipe_$id');
  await tester.ensureVisible(pager);
  await tester.pumpAndSettle();
  await tester.drag(pager, Offset(direction * 240, 0));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectHeader(WidgetTester tester) {
  final title = _key('concept_browse_title');
  final text = tester.widget<Text>(title);
  expect(text.data, 'Profiles');
  expect(text.style!.fontSize, 26);
  expect(text.textAlign, TextAlign.left);
  final rect = tester.getRect(title);
  expect(rect.left, 20);
  expect(rect.top, 60);
  for (final entry in tester.widgetList<Text>(find.byType(Text))) {
    if (entry.data?.isNotEmpty ?? false) {
      expect(
        tester.getRect(find.byWidget(entry)).top,
        greaterThanOrEqualTo(rect.top),
      );
    }
  }
}

void _expectFooterHierarchy(WidgetTester tester) {
  final back = tester.getRect(_key('concept_previous_profile'));
  final next = tester.getRect(_key('concept_next_profile'));
  final requestKey = _key('draft_profile_${_person.id}');
  final request = tester.getRect(requestKey);
  expect(back.width, lessThan(next.width));
  expect(next.width, lessThan(request.width));
  expect(back.width, greaterThanOrEqualTo(48));
  expect(next.height, back.height);
  final requestLabel = find.descendant(
    of: requestKey,
    matching: find.byType(Text),
  );
  final text = tester.widget<Text>(requestLabel);
  final rect = tester.getRect(requestLabel);
  expect(text.data, 'Request Journey');
  expect(text.textAlign, TextAlign.center);
  expect(text.style!.fontFamily, _font);
  expect(text.style!.fontSize, 14);
  expect(text.style!.fontWeight, FontWeight.w400);
  expect(text.style!.height, 1.25);
  expect(text.style!.letterSpacing, .1);
  expect(
    text.maxLines,
    isNull,
    reason: 'Scaled text can wrap instead of clipping',
  );
  expect(rect.center.dx, closeTo(request.center.dx, .01));
  expect(rect.center.dy, closeTo(request.center.dy, .01));
  final backIcon = tester.widget<Icon>(
    find.descendant(
      of: _key('concept_previous_profile'),
      matching: find.byType(Icon),
    ),
  );
  final nextIcon = tester.widget<Icon>(
    find.descendant(
      of: _key('concept_next_profile'),
      matching: find.byType(Icon),
    ),
  );
  expect(backIcon.size, 20);
  expect(nextIcon.size, 24);
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
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = priorOverrides;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  // The 24 unreachable design studies and their original assertions are
  // retained in OA151's retirement archive; they are not current app choices.
  test('Browse exposes only the current Portrait design', () {
    expect(ZyraOneJourneyBrowseDesign.values, [
      ZyraOneJourneyBrowseDesign.portraitCard,
    ]);
    expect(ZyraOneJourneyBrowseDesign.values.map((d) => d.name), [
      'portraitCard',
    ]);
  });

  testWidgets(
    'Current taps cycle and wrap photos without calling profile open',
    (tester) async {
      final opened = <String>[], requested = <String>[];
      var next = 0, previous = 0;
      await _mount(
        tester,
        _presenter(
          profile: (person) => opened.add(person.id),
          request: (person) => requested.add(person.id),
          next: () => next++,
          previous: () => previous++,
        ),
      );
      final details = _key('concept_browse_details_${_person.id}');
      expect(details, findsOneWidget);
      for (final text in [
        'Sara',
        'Ahmed',
        'Age',
        '27',
        'Location',
        'Birmingham',
        'Nationality',
        'British',
        'Ethnicity',
        'South Asian',
      ]) {
        expect(
          find.descendant(of: details, matching: find.text(text)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: details, matching: find.byType(ZyraProfileImage)),
        findsNothing,
      );
      expect(
        find.descendant(of: details, matching: find.byType(Image)),
        findsNothing,
      );
      expect(find.text('Next profile'), findsNothing);
      expect(find.text('View profiles at your pace.'), findsNothing);
      final pager = _key('concept_browse_photo_swipe_${_person.id}');
      final tap = 'concept_browse_photo_tap_${_person.id}';
      for (final index in [1, 2, 3, 0]) {
        await _press(tester, tap);
        expect(
          tester.widget<PageView>(pager).controller!.page,
          closeTo(index, .01),
        );
        _expectSelectedDot(tester, _person.id, index);
        expect(opened, isEmpty);
        expect(requested, isEmpty);
        expect((next, previous), (0, 0));
      }
      await _swipe(tester, _person.id, -1);
      _expectSelectedDot(tester, _person.id, 1);
      expect(opened, isEmpty);
      expect(requested, isEmpty);
      expect(
        tester.widget<InkWell>(_key('concept_browse_open_${_person.id}')).onTap,
        isNull,
      );
      expect(opened, isEmpty, reason: 'Current has no outer-card open action.');
      await _press(tester, 'draft_profile_${_person.id}');
      expect(requested, [_person.id]);
      expect(opened, isEmpty);
    },
  );

  for (final design in [ZyraOneJourneyBrowseDesign.portraitCard]) {
    for (final viewport in const [
      (size: Size(393, 852), scale: 1.0),
      (size: Size(320, 852), scale: 1.0),
      (size: Size(430, 932), scale: 1.0),
      (size: Size(320, 568), scale: 2.0),
    ]) {
      testWidgets(
        '${design.name} ${viewport.size.width.toInt()} at ${viewport.scale} keeps all footer actions reachable',
        (tester) async {
          var previous = 0, next = 0, filters = 0;
          final requested = <String>[];
          await _mount(
            tester,
            _presenter(
              design: design,
              previous: () => previous++,
              next: () => next++,
              filters: () => filters++,
              request: (p) => requested.add(p.id),
            ),
            size: viewport.size,
            scale: viewport.scale,
          );
          _expectHeader(tester);
          _expectFooterHierarchy(tester);
          for (final name in [
            'concept_previous_profile',
            'concept_next_profile',
            'draft_profile_${_person.id}',
          ]) {
            final rect = tester.getRect(_key(name));
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
          }
          final card = _key('concept_browse_details_${_person.id}');
          expect(
            find.descendant(of: card, matching: find.text(_person.firstName)),
            findsOneWidget,
          );
          await _press(tester, 'concept_filters');
          await _press(tester, 'concept_next_profile');
          await _press(tester, 'concept_previous_profile');
          expect((next, previous, filters), (1, 1, 1));
          expect(requested, isEmpty);
          await _press(tester, 'draft_profile_${_person.id}');
          expect(requested, [_person.id]);
          expect(_key('concept_save_${_person.id}'), findsNothing);
          expect(find.textContaining('photos'), findsNothing);
        },
      );
    }
  }

  testWidgets('Portrait swipes only photos and resets on profile navigation', (
    tester,
  ) async {
    var next = 0, previous = 0, requests = 0;
    await _mount(
      tester,
      _presenter(
        next: () => next++,
        previous: () => previous++,
        request: (_) => requests++,
      ),
    );
    await _swipe(tester, _person.id, -1);
    _expectSelectedDot(tester, _person.id, 1);
    expect((next, previous, requests), (0, 0, 0));
    await tester.pumpWidget(_app(_presenter(selected: 1)));
    await tester.pumpAndSettle();
    _expectSelectedDot(tester, _other.id, 0);
    expect(_key('concept_browse_details_${_other.id}'), findsOneWidget);
    expect(find.text('Nationality'), findsNothing);
    expect(find.text('Ethnicity'), findsNothing);
    await tester.pumpWidget(_app(_presenter()));
    await tester.pumpAndSettle();
    _expectSelectedDot(tester, _person.id, 0);
    expect(_key('concept_browse_details_${_person.id}'), findsOneWidget);
  });

  testWidgets(
    'retained photo callbacks cannot mutate after update or dispose',
    (tester) async {
      await _mount(tester, _presenter());
      final oldPhotoChange = tester
          .widget<PageView>(_key('concept_browse_photo_swipe_${_person.id}'))
          .onPageChanged!;
      final tapRect = tester.getRect(
        _key('concept_browse_photo_tap_${_person.id}'),
      );
      final local = Offset(tapRect.width * .75, tapRect.height * .5);
      final tapDetails = TapUpDetails(
        kind: ui.PointerDeviceKind.touch,
        globalPosition: tapRect.topLeft + local,
        localPosition: local,
      );
      final oldPhotoTap = tester
          .widget<GestureDetector>(
            _key('concept_browse_photo_tap_${_person.id}'),
          )
          .onTapUp!;
      await tester.pumpWidget(_app(_presenter(selected: 1)));
      await tester.pumpAndSettle();
      oldPhotoChange(2);
      oldPhotoTap(tapDetails);
      await tester.pumpAndSettle();
      _expectSelectedDot(tester, _other.id, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      oldPhotoChange(1);
      oldPhotoTap(tapDetails);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'request keeps rendered owner delegate and rejects revoked owner in that delegate',
    (tester) async {
      var oldOwnerCurrent = true;
      final oldCalls = <String>[], newCalls = <String>[];
      await _mount(
        tester,
        _presenter(
          request: (p) {
            if (oldOwnerCurrent) oldCalls.add(p.id);
          },
        ),
      );
      final oldTap = tester
          .widget<InkWell>(_key('draft_profile_${_person.id}'))
          .onTap!;
      oldOwnerCurrent = false;
      await tester.pumpWidget(
        _app(_presenter(selected: 1, request: (p) => newCalls.add(p.id))),
      );
      await tester.pumpAndSettle();
      oldTap();
      expect(oldCalls, isEmpty);
      expect(newCalls, isEmpty);
      await _press(tester, 'draft_profile_${_other.id}');
      expect(newCalls, [_other.id]);
    },
  );

  testWidgets(
    'icon navigation, photo alternatives and disabled request have semantic names',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _mount(
          tester,
          _presenter(
            canRequest: (_) => false,
            requestLabel: (_) => 'Requested',
          ),
        );
        expect(
          tester.getSemantics(_key('concept_next_profile')),
          matchesSemantics(
            label: 'Next profile · no decision',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(_key('draft_profile_${_person.id}')),
          matchesSemantics(
            label: 'Requested',
            isButton: true,
            hasEnabledState: true,
          ),
        );
        final photoSemantics = tester.widget<Semantics>(
          find
              .ancestor(
                of: _key('concept_browse_photo_swipe_${_person.id}'),
                matching: find.byType(Semantics),
              )
              .first,
        );
        final actions = photoSemantics.properties.customSemanticsActions!;
        expect(
          actions.keys.map((a) => a.label),
          containsAll(['Previous page', 'Next page']),
        );
        expect(photoSemantics.properties.label, 'Profile details');
        actions.entries.singleWhere((e) => e.key.label == 'Next page').value();
        await tester.pumpAndSettle();
        _expectSelectedDot(tester, _person.id, 1);
      } finally {
        semantics.dispose();
      }
    },
  );
}
