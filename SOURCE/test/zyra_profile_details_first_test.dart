// Offline public presentation regressions only. Invented profiles and a
// paint-only photo seam do not exercise disclosure, admission or member data.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart' as protected;
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_invitation_outline.dart';
import 'package:zyra/widgets/zyra_profile_details_page.dart';

const _font = 'PoppinsDetailsFirst';
const _presenterKey = ValueKey('details-first-presenter');
const _captureKey = ValueKey('gallery-modes-capture');
const _captures = String.fromEnvironment('ZYRA_GALLERY_MODES_CAPTURE_DIR');
const _person = SeekerProfile(
  id: 'details-sara',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  publicNationality: 'British',
  publicEthnicity: 'South Asian',
  photos: ['paint-sara-0', 'paint-sara-1', 'paint-sara-2'],
);
const _other = SeekerProfile(
  id: 'details-amira',
  firstName: 'Amira',
  surnameLine: 'Hussain',
  age: 28,
  city: 'Manchester',
  gender: 'female',
  photos: ['paint-amira-0', 'paint-amira-1'],
);
const _empty = SeekerProfile(
  id: 'details-empty',
  firstName: 'Amina',
  surnameLine: 'Rahman',
  age: 29,
  city: 'Leeds',
  gender: 'female',
  photos: [],
);
const _longPerson = SeekerProfile(
  id: 'details-long',
  firstName: 'Aaliyah Mariam Alexandra',
  surnameLine: 'Abdul Rahman Al-Hussaini',
  age: 31,
  city: 'Stratford-upon-Avon, Warwickshire, United Kingdom',
  gender: 'female',
  publicNationality: 'British Pakistani',
  publicEthnicity: 'South Asian Pakistani',
  photos: ['paint-long-0'],
);

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _details(String id) => _key('concept_browse_details_$id');
Finder _pager(String id) => _key('concept_browse_photo_swipe_$id');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Details-first fixtures must remain offline.');
  }
}

Widget _presenter({
  List<SeekerProfile> profiles = const [_person, _other],
  int selected = 0,
  Map<String, int> photoSeeds = const {},
  Map<String, int> gallerySeeds = const {},
  List<String>? painted,
  void Function(String, int)? onPhoto,
  void Function(String, int)? onGallery,
  VoidCallback? action,
  bool? sent,
  bool showFeedChrome = true,
  bool readOnlyPreview = false,
  String Function(SeekerProfile)? requestLabel,
  bool Function(SeekerProfile)? canRequest,
  bool Function(SeekerProfile)? invitationState,
}) => ZyraBrowseDesigns(
  key: _presenterKey,
  profiles: profiles,
  selectedIndex: selected,
  design: ZyraOneJourneyBrowseDesign.portraitCard,
  showFeedChrome: showFeedChrome,
  readOnlyPreview: readOnlyPreview,
  hapticLevel: ZyraHapticLevel.off,
  initialPhotoIndices: photoSeeds,
  initialGalleryIndices: gallerySeeds,
  onPhotoIndexChanged: onPhoto,
  onGalleryIndexChanged: onGallery,
  invitationSent: invitationState ?? (sent == null ? null : (_) => sent),
  requestLabel: requestLabel,
  canRequest: canRequest,
  photoBuilder:
      (context, photo, {required width, required height, required alignment}) {
        painted?.add(photo);
        return ColoredBox(
          key: ValueKey('details_paint_$photo'),
          color: photo.endsWith('1') ? Colors.blueGrey : Colors.teal,
        );
      },
  onPrevious: action,
  onNext: action,
  onFilters: action,
  onBrowseMenu: (_) => action?.call(),
  onProfile: (_) => action?.call(),
  onRequest: (_) => action?.call(),
);

Never _rejectFeedDelegate() => throw StateError(
  'Inspection must not evaluate a feed decision or action delegate.',
);

void _expectNoFeedChrome(WidgetTester tester) {
  for (final key in [
    'concept_browse_header',
    'concept_browse_footer',
    'concept_previous_profile',
    'concept_next_profile',
    'draft_profile_${_person.id}',
  ]) {
    expect(_key(key), findsNothing);
  }
  expect(find.byType(ZyraInvitationOutline), findsNothing);
  expect(find.text('Profiles'), findsNothing);
  expect(find.text('Request Journey'), findsNothing);
  expect(find.text('Request a Journey'), findsNothing);
  expect(find.text('Journey invitation sent'), findsNothing);
  final scroll = tester.widget<SingleChildScrollView>(
    _key('concept_browse_design_scroll'),
  );
  expect(scroll.padding, const EdgeInsets.fromLTRB(20, 16, 20, 0));
}

Widget _app(
  Widget body, {
  double scale = 1,
  bool quiet = true,
  bool accessible = false,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      textScaler: TextScaler.linear(scale),
      disableAnimations: quiet,
      accessibleNavigation: accessible,
    ),
    child: Directionality(textDirection: direction, child: child!),
  ),
  home: Scaffold(
    body: RepaintBoundary(key: _captureKey, child: body),
  ),
);

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  expect(
    RegExp(
      r'^/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/OA305_GALLERY_MODES_2026_10_22\.[A-Za-z0-9]+/FRAMES_GALLERY$',
    ).hasMatch(_captures),
    isTrue,
  );
  final directory = Directory(_captures);
  expect(directory.existsSync(), isTrue);
  expect(directory.resolveSymbolicLinksSync(), _captures);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  try {
    final bytes = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    expect(bytes, isNotNull);
    await tester.runAsync(() async {
      final file = File('$_captures/$name.png');
      expect(await file.exists(), isFalse);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    });
  } finally {
    image!.dispose();
  }
}

void _expectCleanPhoto(WidgetTester tester, {required int photo}) {
  final image = _key('concept_browse_photo_${_person.id}_$photo');
  expect(image, findsOneWidget);
  expect(_key('concept_browse_identity_${_person.id}'), findsNothing);
  for (final value in [
    _person.firstName,
    _person.surnameLine!,
    '${_person.age} · ${_person.city}',
    'Nationality: ${_person.publicNationality}',
    'Ethnicity: ${_person.publicEthnicity}',
  ]) {
    expect(
      find.descendant(of: image, matching: find.text(value)),
      findsNothing,
    );
  }
  // The paint-only source itself remains unfiltered; identity-only scrims are
  // forbidden anywhere in the visible photo page, not merely under Text.
  final photoPage = find
      .ancestor(of: image, matching: find.byType(Stack))
      .first;
  for (final decoration in tester.widgetList<DecoratedBox>(
    find.descendant(of: photoPage, matching: find.byType(DecoratedBox)),
  )) {
    final box = decoration.decoration;
    if (box is BoxDecoration) expect(box.gradient, isNull);
  }
}

Future<void> _mount(
  WidgetTester tester,
  Widget body, {
  Size size = const Size(393, 852),
  double scale = 1,
  bool quiet = true,
  bool accessible = false,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(
      body,
      scale: scale,
      quiet: quiet,
      accessible: accessible,
      direction: direction,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

PageController _controller(WidgetTester tester, String id) =>
    tester.widget<PageView>(_pager(id)).controller!;

void _expectDetailsText(String id, Iterable<String> values) {
  expect(_details(id), findsOneWidget);
  for (final value in values) {
    expect(
      find.descendant(of: _details(id), matching: find.text(value)),
      findsOneWidget,
      reason: 'The supplied public value "$value" appears on details.',
    );
  }
}

Future<void> _swipe(WidgetTester tester, String id, double dx) async {
  await tester.ensureVisible(_pager(id));
  await tester.pumpAndSettle();
  await tester.drag(_pager(id), Offset(dx, 0));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tapFraction(
  WidgetTester tester,
  double fraction, {
  bool settle = true,
}) async {
  final viewport = tester.getRect(_pager(_person.id));
  await tester.tapAt(
    Offset(viewport.left + viewport.width * fraction, viewport.center.dy),
  );
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectSharedOutline(WidgetTester tester, {required bool sent}) {
  final outline = find.byType(ZyraInvitationOutline);
  expect(outline, findsOneWidget);
  expect(tester.widget<ZyraInvitationOutline>(outline).sent, sent);
  final decoration =
      tester
              .widget<DecoratedBox>(
                find.descendant(
                  of: outline,
                  matching: find.byType(DecoratedBox),
                ),
              )
              .decoration
          as BoxDecoration;
  expect(decoration.border!.top.width, 5);
  expect(
    decoration.border!.top.color,
    ZyraColors.journeyGold.withValues(alpha: sent ? .65 : 0),
  );
  expect(
    tester.getRect(outline),
    tester.getRect(_key('concept_browse_portrait_card')),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late String? oldReadingFont;

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
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    oldFontStubs = ZyraText.useTestFontStubs;
    oldReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraText.testReadingFontFamily = oldReadingFont;
  });

  testWidgets('first page shows all six public fields without a photo render', (
    tester,
  ) async {
    final painted = <String>[];
    await _mount(tester, _presenter(painted: painted));

    expect(find.byType(ZyraProfileDetailsPage), findsOneWidget);
    final detailsScroll = tester.state<ScrollableState>(
      find.descendant(
        of: _details(_person.id),
        matching: find.byType(Scrollable),
      ),
    );
    expect(detailsScroll.position.maxScrollExtent, 0);
    _expectDetailsText(_person.id, [
      _person.firstName,
      _person.surnameLine!,
      'Age',
      '${_person.age}',
      'Location',
      _person.city,
      'Nationality',
      _person.publicNationality!,
      'Ethnicity',
      _person.publicEthnicity!,
    ]);
    expect(_controller(tester, _person.id).page, closeTo(0, .001));
    expect(painted, isEmpty);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(RawImage), findsNothing);
    expect(
      tester
          .widget<PageView>(_pager(_person.id))
          .childrenDelegate
          .estimatedChildCount,
      _person.photos.length + 1,
    );
    await _capture(tester, '01-details-first-public-details');
  });

  testWidgets('details-first photo is clean with no identity copy or scrim', (
    tester,
  ) async {
    await _mount(tester, _presenter());
    await _swipe(tester, _person.id, -260);
    expect(_controller(tester, _person.id).page, closeTo(1, .001));
    _expectCleanPhoto(tester, photo: 0);
    await _capture(tester, '02-details-first-clean-photo');
    await _tapFraction(tester, .75);
    _expectCleanPhoto(tester, photo: 1);
  });

  testWidgets(
    'inspection Details-first keeps public gallery without evaluating feed delegates',
    (tester) async {
      final photos = <(String, int)>[];
      final galleries = <(String, int)>[];
      await _mount(
        tester,
        _presenter(
          showFeedChrome: false,
          requestLabel: (_) => _rejectFeedDelegate(),
          canRequest: (_) => _rejectFeedDelegate(),
          invitationState: (_) => _rejectFeedDelegate(),
          action: _rejectFeedDelegate,
          onPhoto: (id, index) => photos.add((id, index)),
          onGallery: (id, index) => galleries.add((id, index)),
        ),
      );

      _expectNoFeedChrome(tester);
      expect(_key('concept_browse_photo_pagination'), findsOneWidget);
      expect(_key('concept_browse_portrait_card'), findsOneWidget);
      expect(_controller(tester, _person.id).page, closeTo(0, .001));
      expect(
        tester
            .widget<PageView>(_pager(_person.id))
            .childrenDelegate
            .estimatedChildCount,
        _person.photos.length + 1,
      );
      _expectDetailsText(_person.id, [
        _person.firstName,
        _person.surnameLine!,
        '${_person.age}',
        _person.city,
        _person.publicNationality!,
        _person.publicEthnicity!,
      ]);

      await _swipe(tester, _person.id, -260);
      expect(_controller(tester, _person.id).page, closeTo(1, .001));
      _expectCleanPhoto(tester, photo: 0);
      await _tapFraction(tester, .75);
      expect(_controller(tester, _person.id).page, closeTo(2, .001));
      expect(galleries, [(_person.id, 1), (_person.id, 2)]);
      expect(photos, [(_person.id, 0), (_person.id, 1)]);
      _expectNoFeedChrome(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'protected inspection Details-first forwards chrome suppression without widening photo sources',
    (tester) async {
      final painted = <String>[];
      await _mount(
        tester,
        protected.ZyraOneJourneyBrowseDesigns(
          profiles: const [_person],
          selectedIndex: 0,
          design: ZyraOneJourneyBrowseDesign.portraitCard,
          showFeedChrome: false,
          hapticLevel: ZyraHapticLevel.off,
          requestLabel: (_) => _rejectFeedDelegate(),
          canRequest: (_) => _rejectFeedDelegate(),
          invitationSent: (_) => _rejectFeedDelegate(),
          onPrevious: _rejectFeedDelegate,
          onNext: _rejectFeedDelegate,
          onFilters: _rejectFeedDelegate,
          onBrowseMenu: (_) => _rejectFeedDelegate(),
          onProfile: (_) => _rejectFeedDelegate(),
          onRequest: (_) => _rejectFeedDelegate(),
          photoBuilder:
              (
                context,
                source, {
                required width,
                required height,
                required alignment,
              }) {
                painted.add(source);
                return const ColoredBox(color: Colors.teal);
              },
        ),
      );
      _expectNoFeedChrome(tester);
      await _tapFraction(tester, .75);
      expect(_controller(tester, _person.id).page, closeTo(1, .001));
      expect(painted, isNotEmpty);
      expect(painted, everyElement(isEmpty));
      _expectNoFeedChrome(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'default feed chrome and inert own-preview footer stay unchanged',
    (tester) async {
      await _mount(tester, _presenter(sent: true));
      expect(_key('concept_browse_header'), findsOneWidget);
      expect(_key('concept_browse_footer'), findsOneWidget);
      _expectSharedOutline(tester, sent: true);

      await tester.pumpWidget(
        _app(
          _presenter(
            readOnlyPreview: true,
            requestLabel: (_) => _rejectFeedDelegate(),
            canRequest: (_) => _rejectFeedDelegate(),
            invitationState: (_) => _rejectFeedDelegate(),
            action: _rejectFeedDelegate,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_key('concept_browse_header'), findsNothing);
      expect(_key('concept_browse_footer'), findsOneWidget);
      expect(find.text('Request a Journey'), findsOneWidget);
      _expectSharedOutline(tester, sent: false);
      await tester.ensureVisible(_key('draft_profile_${_person.id}'));
      await tester.pumpAndSettle();
      await tester.tap(_key('draft_profile_${_person.id}'));
      await tester.tap(_key('concept_next_profile'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inspection scrolls long public details naturally at 320 and 200 percent',
    (tester) async {
      await _mount(
        tester,
        _presenter(
          profiles: const [_longPerson],
          showFeedChrome: false,
          requestLabel: (_) => _rejectFeedDelegate(),
          canRequest: (_) => _rejectFeedDelegate(),
          invitationState: (_) => _rejectFeedDelegate(),
          action: _rejectFeedDelegate,
        ),
        size: const Size(320, 568),
        scale: 2,
      );
      _expectDetailsText(_longPerson.id, [
        _longPerson.firstName,
        _longPerson.surnameLine!,
        '${_longPerson.age}',
        _longPerson.city,
        _longPerson.publicNationality!,
        _longPerson.publicEthnicity!,
      ]);
      _expectNoFeedChrome(tester);
      final outer = find
          .descendant(
            of: _key('concept_browse_design_scroll'),
            matching: find.byType(Scrollable),
          )
          .first;
      expect(
        tester.state<ScrollableState>(outer).position.maxScrollExtent,
        greaterThan(0),
      );
      final ethnicity = find.text(_longPerson.publicEthnicity!);
      await tester.ensureVisible(ethnicity);
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(ethnicity)
            .intersect(const Rect.fromLTWH(0, 59, 320, 509))
            .height,
        greaterThan(0),
      );
      for (final text in tester.widgetList<Text>(
        find.descendant(
          of: _details(_longPerson.id),
          matching: find.byType(Text),
        ),
      )) {
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final heritage in [null, '   ']) {
    testWidgets(
      'missing public heritage $heritage is omitted without inference',
      (tester) async {
        final person = SeekerProfile(
          id: 'heritage-omitted',
          firstName: 'Sara',
          surnameLine: 'Ahmed',
          age: 27,
          city: 'Birmingham',
          gender: 'female',
          publicNationality: heritage,
          publicEthnicity: heritage,
          photos: const [],
        );
        await _mount(tester, _presenter(profiles: [person]));

        _expectDetailsText(person.id, [
          'Sara',
          'Ahmed',
          'Age',
          '27',
          'Location',
          'Birmingham',
        ]);
        expect(find.text('Nationality'), findsNothing);
        expect(find.text('Ethnicity'), findsNothing);
        expect(find.text('Unknown'), findsNothing);
        expect(find.text('Not provided'), findsNothing);
      },
    );
  }

  testWidgets('withheld age and location omit labels and placeholders', (
    tester,
  ) async {
    const person = SeekerProfile(
      id: 'details-withheld',
      firstName: 'Sara',
      surnameLine: 'Ahmed',
      age: 0,
      city: '—',
      gender: 'female',
      photos: [],
    );
    await _mount(tester, _presenter(profiles: const [person]));

    _expectDetailsText(person.id, ['Sara', 'Ahmed']);
    for (final value in [
      'Age',
      'Location',
      'Nationality',
      'Ethnicity',
      '0',
      '—',
      'Unknown',
      'Not provided',
    ]) {
      expect(find.text(value), findsNothing);
    }
  });

  testWidgets('zero photos leave a details-only page with no photo callback', (
    tester,
  ) async {
    final painted = <String>[];
    final photos = <(String, int)>[];
    final gallery = <(String, int)>[];
    var actions = 0;
    await _mount(
      tester,
      _presenter(
        profiles: const [_empty],
        photoSeeds: {_empty.id: 99},
        gallerySeeds: {_empty.id: 99},
        painted: painted,
        onPhoto: (id, index) => photos.add((id, index)),
        onGallery: (id, index) => gallery.add((id, index)),
        action: () => actions++,
      ),
    );

    expect(
      tester
          .widget<PageView>(_pager(_empty.id))
          .childrenDelegate
          .estimatedChildCount,
      1,
    );
    await _swipe(tester, _empty.id, -260);
    await tester.tap(_key('concept_browse_photo_tap_${_empty.id}'));
    await tester.pumpAndSettle();
    _expectDetailsText(_empty.id, ['Amina', 'Rahman', '29', 'Leeds']);
    expect(_controller(tester, _empty.id).page, closeTo(0, .001));
    expect(painted, isEmpty);
    expect(photos, isEmpty);
    expect(gallery, isEmpty);
    expect(actions, 0);
    expect(tester.takeException(), isNull);
  });

  for (final seed in const [
    (photo: 0, gallery: null, expected: 1),
    (photo: 1, gallery: null, expected: 2),
    (photo: 99, gallery: null, expected: 3),
    (photo: -99, gallery: null, expected: 1),
    (photo: 2, gallery: 0, expected: 0),
    (photo: 2, gallery: 1, expected: 1),
    (photo: 0, gallery: 99, expected: 3),
    (photo: 1, gallery: -99, expected: 0),
  ]) {
    testWidgets(
      'legacy photo ${seed.photo}, gallery ${seed.gallery} starts at ${seed.expected}',
      (tester) async {
        final painted = <String>[];
        final photos = <(String, int)>[];
        final gallery = <(String, int)>[];
        await _mount(
          tester,
          _presenter(
            photoSeeds: {_person.id: seed.photo},
            gallerySeeds: {if (seed.gallery != null) _person.id: seed.gallery!},
            painted: painted,
            onPhoto: (id, index) => photos.add((id, index)),
            onGallery: (id, index) => gallery.add((id, index)),
          ),
        );

        expect(_controller(tester, _person.id).initialPage, seed.expected);
        expect(
          _controller(tester, _person.id).page,
          closeTo(seed.expected, .001),
        );
        if (seed.expected == 0) {
          expect(_details(_person.id), findsOneWidget);
          expect(painted, isEmpty);
        } else {
          expect(
            _key('details_paint_${_person.photos[seed.expected - 1]}'),
            findsOneWidget,
          );
        }
        expect(
          photos,
          isEmpty,
          reason: 'Restoring a seed is not photo navigation.',
        );
        expect(
          gallery,
          isEmpty,
          reason: 'Restoring a seed is not gallery navigation.',
        );
      },
    );
  }

  testWidgets(
    'swiping to a photo and back emits separate ordinals and no actions',
    (tester) async {
      final photos = <(String, int)>[];
      final gallery = <(String, int)>[];
      var actions = 0;
      await _mount(
        tester,
        _presenter(
          onPhoto: (id, index) => photos.add((id, index)),
          onGallery: (id, index) => gallery.add((id, index)),
          action: () => actions++,
        ),
      );

      await _swipe(tester, _person.id, -260);
      expect(_controller(tester, _person.id).page, closeTo(1, .001));
      expect(_key('details_paint_${_person.photos.first}'), findsOneWidget);
      expect(photos, [(_person.id, 0)]);
      expect(gallery, [(_person.id, 1)]);
      await _swipe(tester, _person.id, 260);
      expect(_controller(tester, _person.id).page, closeTo(0, .001));
      expect(_details(_person.id), findsOneWidget);
      expect(photos, [
        (_person.id, 0),
      ], reason: 'Details has no real photo ordinal.');
      expect(gallery, [(_person.id, 1), (_person.id, 0)]);
      expect(actions, 0);
    },
  );

  testWidgets('selecting a different person and returning starts on details', (
    tester,
  ) async {
    final gallery = <(String, int)>[];
    Widget presenter(int selected) => _presenter(
      selected: selected,
      gallerySeeds: {_person.id: 2, _other.id: 2},
      onGallery: (id, index) => gallery.add((id, index)),
    );
    await _mount(tester, presenter(0));
    expect(_controller(tester, _person.id).page, closeTo(2, .001));

    await tester.pumpWidget(_app(presenter(1)));
    await tester.pumpAndSettle();
    expect(_controller(tester, _other.id).page, closeTo(0, .001));
    _expectDetailsText(_other.id, ['Amira', 'Hussain', '28', 'Manchester']);
    await _swipe(tester, _other.id, -260);
    expect(_controller(tester, _other.id).page, closeTo(1, .001));

    await tester.pumpWidget(_app(presenter(0)));
    await tester.pumpAndSettle();
    expect(_controller(tester, _person.id).page, closeTo(0, .001));
    _expectDetailsText(_person.id, ['Sara', 'Ahmed', '27', 'Birmingham']);
    expect(gallery, [(_other.id, 1)]);
    expect(tester.takeException(), isNull);
  });

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets('photo halves and exact centre stay physical in $direction', (
      tester,
    ) async {
      final gallery = <(String, int)>[];
      final photos = <(String, int)>[];
      var actions = 0;
      await _mount(
        tester,
        _presenter(
          gallerySeeds: {_person.id: 2},
          onGallery: (id, index) => gallery.add((id, index)),
          onPhoto: (id, index) => photos.add((id, index)),
          action: () => actions++,
        ),
        direction: direction,
      );

      await _tapFraction(tester, .75);
      expect(_controller(tester, _person.id).page, closeTo(3, .001));
      expect(_key('details_paint_${_person.photos[2]}'), findsOneWidget);
      await _tapFraction(tester, .25);
      expect(_controller(tester, _person.id).page, closeTo(2, .001));
      expect(_key('details_paint_${_person.photos[1]}'), findsOneWidget);
      await _tapFraction(tester, .5);
      expect(_controller(tester, _person.id).page, closeTo(3, .001));
      expect(_key('details_paint_${_person.photos[2]}'), findsOneWidget);
      expect(gallery, [(_person.id, 3), (_person.id, 2), (_person.id, 3)]);
      expect(photos, [(_person.id, 2), (_person.id, 1), (_person.id, 2)]);
      expect(actions, 0);
    });
  }

  for (final edge in const [
    (page: 1, fraction: .25, label: 'first photo left'),
    (page: 3, fraction: .75, label: 'last photo right'),
  ]) {
    testWidgets('${edge.label} returns to details without a photo ordinal', (
      tester,
    ) async {
      final gallery = <(String, int)>[];
      final photos = <(String, int)>[];
      var actions = 0;
      await _mount(
        tester,
        _presenter(
          gallerySeeds: {_person.id: edge.page},
          onGallery: (id, index) => gallery.add((id, index)),
          onPhoto: (id, index) => photos.add((id, index)),
          action: () => actions++,
        ),
      );

      await _tapFraction(tester, edge.fraction);
      expect(_controller(tester, _person.id).page, closeTo(0, .001));
      expect(_details(_person.id), findsOneWidget);
      expect(gallery, [(_person.id, 0)]);
      expect(photos, isEmpty);
      expect(actions, 0);
    });
  }

  testWidgets('a physical left tap on details enters the first real photo', (
    tester,
  ) async {
    final gallery = <(String, int)>[];
    final photos = <(String, int)>[];
    var actions = 0;
    await _mount(
      tester,
      _presenter(
        onGallery: (id, index) => gallery.add((id, index)),
        onPhoto: (id, index) => photos.add((id, index)),
        action: () => actions++,
      ),
    );

    expect(_details(_person.id), findsOneWidget);
    await _tapFraction(tester, .25);
    expect(_controller(tester, _person.id).page, closeTo(1, .001));
    expect(_key('details_paint_${_person.photos.first}'), findsOneWidget);
    expect(gallery, [(_person.id, 1)]);
    expect(photos, [(_person.id, 0)]);
    expect(actions, 0);
  });

  for (final start in [1, 2]) {
    testWidgets(
      'left tap reverses page $start over 420ms and ignores retained mid-motion taps',
      (tester) async {
        final gallery = <(String, int)>[];
        final photos = <(String, int)>[];
        var actions = 0;
        await _mount(
          tester,
          _presenter(
            gallerySeeds: {_person.id: start},
            onGallery: (id, index) => gallery.add((id, index)),
            onPhoto: (id, index) => photos.add((id, index)),
            action: () => actions++,
          ),
          quiet: false,
        );

        final tapTarget = _key('concept_browse_photo_tap_${_person.id}');
        final retainedTapUp = tester
            .widget<GestureDetector>(tapTarget)
            .onTapUp!;
        final size = tester.getSize(tapTarget);
        final origin = tester.getTopLeft(tapTarget);
        final left = Offset(size.width * .25, size.height / 2);
        final right = Offset(size.width * .75, size.height / 2);
        final leftUp = TapUpDetails(
          kind: ui.PointerDeviceKind.touch,
          localPosition: left,
          globalPosition: origin + left,
        );
        final rightUp = TapUpDetails(
          kind: ui.PointerDeviceKind.touch,
          localPosition: right,
          globalPosition: origin + right,
        );
        await _tapFraction(tester, .25, settle: false);
        expect(_controller(tester, _person.id).page, closeTo(start, .001));
        await tester.pump(const Duration(milliseconds: 210));
        expect(_controller(tester, _person.id).page, closeTo(start - .5, .02));
        // Exercise both retained callbacks without inserting a pointer-down
        // that legitimately interrupts PageView's driven scroll activity.
        retainedTapUp(leftUp);
        retainedTapUp(rightUp);
        await tester.pump(const Duration(milliseconds: 210));
        expect(_controller(tester, _person.id).page, closeTo(start - 1, .001));
        await tester.pumpAndSettle();
        expect(_controller(tester, _person.id).page, closeTo(start - 1, .001));
        expect(gallery, [(_person.id, start - 1)]);
        expect(photos, start == 1 ? isEmpty : [(_person.id, 0)]);
        expect(actions, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a second physical left tap during reversal from page $start settles once',
      (tester) async {
        final gallery = <(String, int)>[];
        final photos = <(String, int)>[];
        var actions = 0;
        await _mount(
          tester,
          _presenter(
            gallerySeeds: {_person.id: start},
            onGallery: (id, index) => gallery.add((id, index)),
            onPhoto: (id, index) => photos.add((id, index)),
            action: () => actions++,
          ),
          quiet: false,
        );

        await _tapFraction(tester, .25, settle: false);
        await tester.pump(const Duration(milliseconds: 210));
        expect(_controller(tester, _person.id).page, closeTo(start - .5, .02));
        await _tapFraction(tester, .25, settle: false);
        // The extra pointer sequence can replace driven scrolling with a
        // ballistic snap; its settled destination and callback count matter.
        await tester.pumpAndSettle();
        expect(_controller(tester, _person.id).page, closeTo(start - 1, .001));
        expect(gallery, [(_person.id, start - 1)]);
        expect(photos, start == 1 ? isEmpty : [(_person.id, 0)]);
        expect(actions, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final quiet in const [
    (disable: true, accessible: false),
    (disable: false, accessible: true),
  ]) {
    testWidgets(
      'reverse tap is immediate for quiet ${quiet.disable}/${quiet.accessible}',
      (tester) async {
        final gallery = <(String, int)>[];
        final photos = <(String, int)>[];
        var actions = 0;
        await _mount(
          tester,
          _presenter(
            gallerySeeds: {_person.id: 2},
            onGallery: (id, index) => gallery.add((id, index)),
            onPhoto: (id, index) => photos.add((id, index)),
            action: () => actions++,
          ),
          quiet: quiet.disable,
          accessible: quiet.accessible,
        );

        await _tapFraction(tester, .25, settle: false);
        expect(_controller(tester, _person.id).page, closeTo(1, .001));
        expect(_key('details_paint_${_person.photos.first}'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 420));
        expect(_controller(tester, _person.id).page, closeTo(1, .001));
        expect(gallery, [(_person.id, 1)]);
        expect(photos, [(_person.id, 0)]);
        expect(actions, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final sent in [false, true]) {
    testWidgets(
      'details has no baseline border and shares one request outline, sent=$sent',
      (tester) async {
        var actions = 0;
        await _mount(tester, _presenter(sent: sent, action: () => actions++));

        final detailsDecoration =
            tester.widget<DecoratedBox>(_details(_person.id)).decoration
                as BoxDecoration;
        expect(detailsDecoration.border, isNull);
        expect(detailsDecoration.borderRadius, isNull);
        final halo =
            tester
                    .widget<Container>(
                      find
                          .ancestor(
                            of: find.byIcon(Icons.person_outline),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(halo.shape, BoxShape.circle);
        expect(
          halo.border!.top.color,
          ZyraColors.journeyGold.withValues(alpha: .65),
        );
        _expectSharedOutline(tester, sent: sent);
        final outline = tester.element(find.byType(ZyraInvitationOutline));

        await _tapFraction(tester, .75);
        expect(_controller(tester, _person.id).page, closeTo(1, .001));
        expect(_key('details_paint_${_person.photos.first}'), findsOneWidget);
        _expectSharedOutline(tester, sent: sent);
        expect(
          tester.element(find.byType(ZyraInvitationOutline)),
          same(outline),
        );
        await _tapFraction(tester, .25);
        expect(_controller(tester, _person.id).page, closeTo(0, .001));
        expect(_details(_person.id), findsOneWidget);
        _expectSharedOutline(tester, sent: sent);
        expect(
          tester.element(find.byType(ZyraInvitationOutline)),
          same(outline),
        );
        expect(actions, 0);
      },
    );
  }

  for (final scale in [1.4, 2.0]) {
    testWidgets(
      'long public details scroll at 320 wide and text scale $scale',
      (tester) async {
        await _mount(
          tester,
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                height: 300,
                child: ZyraProfileDetailsPage(profile: _longPerson),
              ),
            ),
          ),
          size: const Size(320, 568),
          scale: scale,
        );

        _expectDetailsText(_longPerson.id, [
          _longPerson.firstName,
          _longPerson.surnameLine!,
          '${_longPerson.age}',
          _longPerson.city,
          _longPerson.publicNationality!,
          _longPerson.publicEthnicity!,
        ]);
        final scrollable = find.descendant(
          of: _key('concept_browse_details_scroll_${_longPerson.id}'),
          matching: find.byType(Scrollable),
        );
        expect(
          tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
          greaterThan(0),
          reason: 'The bounded details page provides a vertical fallback.',
        );
        final ethnicity = find.text(_longPerson.publicEthnicity!);
        await tester.ensureVisible(ethnicity);
        await tester.pumpAndSettle();
        final visible = tester
            .getRect(ethnicity)
            .intersect(
              tester.getRect(
                _key('concept_browse_details_scroll_${_longPerson.id}'),
              ),
            );
        expect(visible.height, greaterThan(0));
        for (final text in tester.widgetList<Text>(
          find.descendant(
            of: _details(_longPerson.id),
            matching: find.byType(Text),
          ),
        )) {
          expect(text.maxLines, isNull);
          expect(text.overflow, isNot(TextOverflow.ellipsis));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'compact browse keeps long details and actions without overflow',
    (tester) async {
      final painted = <String>[];
      await _mount(
        tester,
        _presenter(
          profiles: const [_longPerson],
          painted: painted,
          action: () {},
        ),
        size: const Size(320, 568),
        scale: 2,
      );

      expect(_details(_longPerson.id), findsOneWidget);
      expect(painted, isEmpty);
      final request = _key('draft_profile_${_longPerson.id}');
      await tester.ensureVisible(request);
      await tester.pumpAndSettle();
      expect(request.hitTestable(), findsOneWidget);
      expect(_key('concept_next_profile').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
