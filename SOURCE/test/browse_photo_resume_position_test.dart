// Presentation-only resume ordinals with invented profiles and paint-only
// renderers. No member lookup, image provider, persistence or network access.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';

const _sara = SeekerProfile(
  id: 'resume-sara',
  firstName: 'Sara',
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  photos: [
    'data:image/paint-sara-0',
    'data:image/paint-sara-1',
    'data:image/paint-sara-2',
  ],
);
const _aisha = SeekerProfile(
  id: 'resume-aisha',
  firstName: 'Aisha',
  age: 28,
  city: 'London',
  gender: 'female',
  photos: ['data:image/paint-aisha-0', 'data:image/paint-aisha-1'],
);
const _empty = SeekerProfile(
  id: 'resume-empty',
  firstName: 'Amina',
  age: 29,
  city: 'Leeds',
  gender: 'female',
  photos: [],
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Resume photo fixtures must remain offline.');
  }
}

Widget _paint(BuildContext context, String photo) => ColoredBox(
  key: ValueKey('paint_$photo'),
  color: photo.endsWith('1') ? Colors.blueGrey : Colors.teal,
);

Widget _photoBuilder(
  BuildContext context,
  String photo, {
  required double width,
  required double height,
  required Alignment alignment,
}) => _paint(context, photo);

Widget _shared({
  List<SeekerProfile> profiles = const [_sara, _aisha],
  int selected = 0,
  Map<String, int> initial = const {},
  void Function(String, int)? changed,
}) => ZyraBrowseDesigns(
  key: const ValueKey('shared-resume-presenter'),
  profiles: profiles,
  selectedIndex: selected,
  design: ZyraOneJourneyBrowseDesign.portraitCard,
  photoBuilder: _photoBuilder,
  showSave: false,
  hapticLevel: ZyraHapticLevel.off,
  initialGalleryIndices: initial,
  onGalleryIndexChanged: changed,
);

Widget _standalone({
  SeekerProfile profile = _sara,
  int initial = 0,
  ValueChanged<int>? changed,
  ZyraOneJourneyPhotoBuilder imageBuilder = _paint,
}) => ZyraOneJourneyBrowsePresentation(
  key: const ValueKey('standalone-resume-presenter'),
  profile: profile,
  onMenu: () {},
  showMenu: false,
  showActions: false,
  imageBuilder: imageBuilder,
  initialPhotoIndex: initial,
  onPhotoIndexChanged: changed,
);

Widget _app(Widget presenter) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: Scaffold(body: presenter),
);

Future<void> _mount(WidgetTester tester, Widget presenter) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(presenter));
  expect(tester.takeException(), isNull);
}

PageController _controller(WidgetTester tester, String id) => tester
    .widget<PageView>(find.byKey(ValueKey('concept_browse_photo_swipe_$id')))
    .controller!;

void main() {
  late bool oldFontStubs;
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;

  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
  });

  testWidgets('shared gallery begins on restored photo two without a seek', (
    tester,
  ) async {
    final changes = <(String, int)>[];
    final initial = <String, int>{_sara.id: 2};
    await _mount(
      tester,
      _shared(
        initial: initial,
        changed: (id, index) => changes.add((id, index)),
      ),
    );
    final pager = _controller(tester, _sara.id);
    expect(pager.initialPage, 2);
    expect(pager.page, closeTo(2, .001));
    expect(pager.position.isScrollingNotifier.value, isFalse);
    expect(changes, isEmpty);
    initial[_sara.id] = 0;
    await tester.pump();
    expect(pager.page, closeTo(2, .001));
    expect(changes, isEmpty);
  });

  testWidgets('shared gallery seeds clamp against details plus actual photos', (
    tester,
  ) async {
    await _mount(tester, _shared(initial: {_sara.id: 99}));
    expect(_controller(tester, _sara.id).initialPage, 3);
    await tester.pumpWidget(const SizedBox());
    await _mount(tester, _shared(initial: {_sara.id: -99}));
    expect(_controller(tester, _sara.id).initialPage, 0);
    await tester.pumpWidget(const SizedBox());
    await _mount(
      tester,
      _shared(profiles: const [_empty], initial: {_empty.id: 99}),
    );
    expect(_controller(tester, _empty.id).initialPage, 0);
    expect(
      find.byKey(ValueKey('concept_browse_details_${_empty.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('paint_')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared seeds are initial-only and profile changes reset', (
    tester,
  ) async {
    await _mount(tester, _shared(initial: {_sara.id: 1, _aisha.id: 1}));
    await tester.pumpWidget(_app(_shared(initial: {_sara.id: 2})));
    await tester.pumpAndSettle();
    expect(_controller(tester, _sara.id).page, closeTo(1, .001));
    await tester.pumpWidget(
      _app(_shared(selected: 1, initial: {_aisha.id: 1})),
    );
    await tester.pumpAndSettle();
    expect(_controller(tester, _aisha.id).page, closeTo(0, .001));
    await tester.pumpWidget(_app(_shared()));
    await tester.pumpAndSettle();
    expect(_controller(tester, _sara.id).page, closeTo(0, .001));
  });

  testWidgets(
    'shared real tap emits only the current profile and gallery ordinal',
    (tester) async {
      final changes = <(String, int)>[];
      await _mount(
        tester,
        _shared(
          initial: {_sara.id: 1},
          changed: (id, index) => changes.add((id, index)),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('concept_browse_photo_tap_resume-sara')),
      );
      await tester.pumpAndSettle();
      expect(changes, [(_sara.id, 2)]);
      expect(_controller(tester, _sara.id).page, closeTo(2, .001));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('gallery callbacks include the dedicated details ordinal', (
    tester,
  ) async {
    final changes = <(String, int)>[];
    await _mount(
      tester,
      _shared(
        initial: {_sara.id: 3},
        changed: (id, index) => changes.add((id, index)),
      ),
    );
    final tap = find.byKey(
      const ValueKey('concept_browse_photo_tap_resume-sara'),
    );
    await tester.tap(tap);
    await tester.pumpAndSettle();
    expect(_controller(tester, _sara.id).page, closeTo(0, .001));
    expect(changes, [(_sara.id, 0)]);
    await tester.tap(tap);
    await tester.pumpAndSettle();
    expect(changes, [(_sara.id, 0), (_sara.id, 1)]);
  });

  testWidgets('sample wrapper forwards only photo ordinal data and callback', (
    tester,
  ) async {
    final changes = <(String, int)>[];
    await _mount(
      tester,
      ZyraOneJourneyBrowseDesigns(
        profiles: const [_sara],
        selectedIndex: 0,
        design: ZyraOneJourneyBrowseDesign.portraitCard,
        photoBuilder: _photoBuilder,
        hapticLevel: ZyraHapticLevel.off,
        initialPhotoIndices: {_sara.id: 1},
        onPhotoIndexChanged: (id, index) => changes.add((id, index)),
      ),
    );
    expect(_controller(tester, _sara.id).initialPage, 2);
    await tester.tap(
      find.byKey(const ValueKey('concept_browse_photo_tap_resume-sara')),
    );
    await tester.pumpAndSettle();
    expect(changes, [(_sara.id, 2)]);
  });

  testWidgets(
    'shared actual-photo API keeps old seeds and never emits details',
    (tester) async {
      final changes = <(String, int)>[];
      await _mount(
        tester,
        ZyraBrowseDesigns(
          profiles: const [_sara],
          selectedIndex: 0,
          design: ZyraOneJourneyBrowseDesign.portraitCard,
          photoBuilder: _photoBuilder,
          showSave: false,
          hapticLevel: ZyraHapticLevel.off,
          initialPhotoIndices: {_sara.id: 1},
          onPhotoIndexChanged: (id, index) => changes.add((id, index)),
        ),
      );
      expect(_controller(tester, _sara.id).initialPage, 2);
      expect(changes, isEmpty);
      final tap = find.byKey(
        const ValueKey('concept_browse_photo_tap_resume-sara'),
      );
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(changes, [(_sara.id, 2)]);
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(_controller(tester, _sara.id).page, closeTo(0, .001));
      expect(
        find.byKey(ValueKey('concept_browse_details_${_sara.id}')),
        findsOneWidget,
      );
      expect(changes, [(_sara.id, 2)]);
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(changes, [(_sara.id, 2), (_sara.id, 0)]);
      expect(_controller(tester, _sara.id).page, closeTo(1, .001));
    },
  );

  testWidgets(
    'actual-photo seeds still clamp to photos and empty records stay details-only',
    (tester) async {
      Widget legacy(SeekerProfile profile, int initial) => ZyraBrowseDesigns(
        profiles: [profile],
        selectedIndex: 0,
        design: ZyraOneJourneyBrowseDesign.portraitCard,
        photoBuilder: _photoBuilder,
        initialPhotoIndices: {profile.id: initial},
      );
      await _mount(tester, legacy(_sara, 99));
      expect(_controller(tester, _sara.id).initialPage, 3);
      await tester.pumpWidget(const SizedBox());
      await _mount(tester, legacy(_sara, -99));
      expect(_controller(tester, _sara.id).initialPage, 1);
      await tester.pumpWidget(const SizedBox());
      await _mount(tester, legacy(_empty, 99));
      expect(_controller(tester, _empty.id).initialPage, 0);
      expect(
        find.byKey(ValueKey('concept_browse_details_${_empty.id}')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('paint_')), findsNothing);
    },
  );

  testWidgets('standalone first paint restores photo two without a flash', (
    tester,
  ) async {
    final painted = <String>[];
    final changes = <int>[];
    await _mount(
      tester,
      _standalone(
        initial: 1,
        changed: changes.add,
        imageBuilder: (context, photo) {
          painted.add(photo);
          return _paint(context, photo);
        },
      ),
    );
    expect(painted, isNotEmpty);
    expect(painted.every((photo) => photo == _sara.photos[1]), isTrue);
    expect(changes, isEmpty);
    await tester.pump();
    expect(painted.every((photo) => photo == _sara.photos[1]), isTrue);
  });

  testWidgets('standalone clamps seeds and ignores subsequent seed changes', (
    tester,
  ) async {
    await _mount(tester, _standalone(initial: 99));
    expect(find.byKey(ValueKey('paint_${_sara.photos[2]}')), findsOneWidget);
    await tester.pumpWidget(_app(_standalone(initial: 0)));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('paint_${_sara.photos[2]}')), findsOneWidget);
    await tester.pumpWidget(_app(_standalone(profile: _aisha, initial: 1)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('paint_${_aisha.photos.first}')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await _mount(tester, _standalone(initial: -9));
    expect(find.byKey(ValueKey('paint_${_sara.photos.first}')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _mount(tester, _standalone(profile: _empty, initial: 9));
    expect(find.byKey(const ValueKey('paint_')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone actual tap emits the changed ordinal only', (
    tester,
  ) async {
    final changes = <int>[];
    await _mount(tester, _standalone(initial: 1, changed: changes.add));
    final gallery = find.byKey(const ValueKey('concept_browse_photo_gallery'));
    final bounds = tester.getRect(gallery);
    await tester.tapAt(Offset(bounds.right - 40, bounds.center.dy));
    await tester.pumpAndSettle();
    expect(changes, [2]);
    expect(find.byKey(ValueKey('paint_${_sara.photos[2]}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
