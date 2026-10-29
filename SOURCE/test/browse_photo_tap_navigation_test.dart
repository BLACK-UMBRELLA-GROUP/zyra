// Current Browse photo navigation only. Invented public profiles and an
// injected paint-only renderer; no service, member record or image provider.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_card_metrics.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_profile_name_block.dart';

const _paintBoundary = ValueKey('browse-photo-paint-boundary');

const _person = SeekerProfile(
  id: 'tap-photo-person',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  photos: ['paint-photo-0', 'paint-photo-1', 'paint-photo-2'],
);
const _other = SeekerProfile(
  id: 'tap-photo-other',
  firstName: 'Amira',
  age: 28,
  city: 'Manchester',
  gender: 'female',
  photos: ['paint-other-0', 'paint-other-1'],
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Photo tap fixtures must remain offline.');
  }
}

class _Actions {
  final opened = <String>[];
  final requested = <String>[];
  int previous = 0;
  int next = 0;

  void expectNoDecisions() {
    expect(opened, isEmpty);
    expect(requested, isEmpty);
    expect(previous, 0);
    expect(next, 0);
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _pager([String id = 'tap-photo-person']) =>
    _key('concept_browse_photo_swipe_$id');
Finder _tapTarget([String id = 'tap-photo-person']) =>
    _key('concept_browse_photo_tap_$id');
Finder _wrap([String id = 'tap-photo-person']) =>
    _key('concept_browse_photo_wrap_$id');

TapUpDetails _rightTapUp(WidgetTester tester) {
  final rect = tester.getRect(_tapTarget());
  final local = Offset(rect.width * .75, rect.height * .5);
  return TapUpDetails(
    kind: ui.PointerDeviceKind.touch,
    globalPosition: rect.topLeft + local,
    localPosition: local,
  );
}

SeekerProfile _withPhotos(List<String> photos) => SeekerProfile(
  id: _person.id,
  firstName: _person.firstName,
  surnameLine: _person.surnameLine,
  age: _person.age,
  city: _person.city,
  gender: _person.gender,
  photos: photos,
);

Widget _presenter(
  _Actions actions, {
  List<SeekerProfile> people = const [_person, _other],
  int selected = 0,
  Color? photoColor,
  bool emulateOldPhotoRounding = false,
}) => ZyraBrowseDesigns(
  key: const ValueKey('photo-tap-presenter'),
  profiles: people,
  selectedIndex: selected,
  design: ZyraOneJourneyBrowseDesign.portraitCard,
  photoBuilder:
      (context, photo, {required width, required height, required alignment}) {
        final paint = ColoredBox(
          color:
              photoColor ??
              (photo.endsWith('1')
                  ? Colors.blueGrey
                  : photo.endsWith('2')
                  ? Colors.teal
                  : Colors.grey),
        );
        // Negative-control renderer: the same inner corner clipping that
        // Current used before the fix, without changing production code.
        return emulateOldPhotoRounding
            ? ClipRRect(
                borderRadius: BorderRadius.circular(
                  ZyraCardMetrics.thumbRadius,
                ),
                child: paint,
              )
            : paint;
      },
  onProfile: (profile) => actions.opened.add(profile.id),
  onRequest: (profile) => actions.requested.add(profile.id),
  onPrevious: () => actions.previous++,
  onNext: () => actions.next++,
  onFilters: () {},
);

Widget _app(
  Widget presenter, {
  bool disableAnimations = false,
  bool accessibleNavigation = false,
}) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      disableAnimations: disableAnimations,
      accessibleNavigation: accessibleNavigation,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: RepaintBoundary(key: _paintBoundary, child: presenter),
  ),
);

Future<void> _mount(
  WidgetTester tester,
  Widget presenter, {
  bool disableAnimations = false,
  bool accessibleNavigation = false,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(
      presenter,
      disableAnimations: disableAnimations,
      accessibleNavigation: accessibleNavigation,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectPhoto(
  WidgetTester tester,
  int index, {
  String id = 'tap-photo-person',
}) {
  expect(
    tester.widget<PageView>(_pager(id)).controller!.page,
    closeTo(index, .01),
  );
  final dot = _key('concept_browse_photo_dot_${id}_$index');
  if (dot.evaluate().isNotEmpty) {
    expect(
      (tester.widget<AnimatedContainer>(dot).decoration! as BoxDecoration)
          .color,
      ZyraColors.journeyGold,
    );
  }
}

Semantics _photoSemantics(WidgetTester tester, int index, {int count = 3}) =>
    tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                (index == 0 ? 'Profile details' : 'Photo $index of $count'),
      ),
    );

Future<void> _showLastPhoto(WidgetTester tester, int count) async {
  for (var index = 1; index <= count; index++) {
    await tester.tap(_tapTarget());
    await tester.pumpAndSettle();
    _expectPhoto(tester, index);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final platformCalls = <MethodCall>[];
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late bool previousFontStubs;
  late ZyraHapticLevel previousHaptics;
  late ZyraDevPalette previousPalette;

  List<MethodCall> haptics() => platformCalls
      .where((call) => call.method == 'HapticFeedback.vibrate')
      .toList();

  void expectTicks(int count) {
    expect(haptics(), hasLength(count));
    for (final call in haptics()) {
      expect(call.arguments, 'HapticFeedbackType.selectionClick');
    }
  }

  setUp(() {
    platformCalls.clear();
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousFontStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
    previousHaptics = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.subtle);
    previousPalette = ZyraColors.devPalette;
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = previousFontStubs;
    ZyraInteractionStyle.selectHapticLevel(previousHaptics);
    ZyraColors.selectDevPalette(previousPalette);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('completed taps advance and wrap photos, never the person', (
    tester,
  ) async {
    final actions = _Actions();
    await _mount(tester, _presenter(actions));
    expectTicks(0);
    expect(
      tester.widget<InkWell>(_key('concept_browse_open_${_person.id}')).onTap,
      isNull,
    );

    expect(_key('concept_browse_details_${_person.id}'), findsOneWidget);
    for (final (tap, index) in [(1, 1), (2, 2), (3, 3), (4, 0), (5, 1)]) {
      await tester.tap(_tapTarget());
      await tester.pumpAndSettle();
      _expectPhoto(tester, index);
      expectTicks(tap);
      actions.expectNoDecisions();
      expect(
        tester
            .widget<ZyraBrowseDesigns>(find.byType(ZyraBrowseDesigns))
            .selectedIndex,
        0,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap then swipe uses the same pager and selected gold dot', (
    tester,
  ) async {
    final actions = _Actions();
    await _mount(tester, _presenter(actions));
    await tester.tap(_tapTarget());
    await tester.pumpAndSettle();
    _expectPhoto(tester, 1);
    await tester.drag(_pager(), const Offset(-300, 0));
    await tester.pumpAndSettle();
    _expectPhoto(tester, 2);
    await tester.drag(_pager(), const Offset(300, 0));
    await tester.pumpAndSettle();
    _expectPhoto(tester, 1);
    expectTicks(3);
    actions.expectNoDecisions();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Current adjacent tap takes 420ms with a smooth cubic midpoint', (
    tester,
  ) async {
    final actions = _Actions();
    await _mount(tester, _presenter(actions));
    final card = tester.getRect(_key('concept_browse_portrait_card'));
    final controller = tester.widget<PageView>(_pager()).controller!;
    await tester.tap(_tapTarget());
    await tester.pump();
    expect(controller.page, closeTo(0, .001));
    expect(controller.position.isScrollingNotifier.value, isTrue);
    await tester.pump(const Duration(milliseconds: 210));
    expect(controller.page, closeTo(.5, .025));
    expect(controller.position.isScrollingNotifier.value, isTrue);
    await tester.pump(const Duration(milliseconds: 10));
    expect(controller.page, inExclusiveRange(.5, 1));
    expect(controller.position.isScrollingNotifier.value, isTrue);
    expectTicks(1);
    expect(tester.getRect(_key('concept_browse_portrait_card')), card);
    await tester.pump(const Duration(milliseconds: 200));
    _expectPhoto(tester, 1);
    expectTicks(1);
    // The driven activity settles on its first completion frame after the
    // exact-duration endpoint; measure that endpoint before advancing it.
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.position.isScrollingNotifier.value, isFalse);
    expect(_wrap(), findsNothing);
    expectTicks(1);
    actions.expectNoDecisions();
    expect(tester.takeException(), isNull);
  });

  for (final count in [3, 4]) {
    testWidgets('$count-photo gallery wraps to details over 420ms', (
      tester,
    ) async {
      final actions = _Actions();
      final person = _withPhotos([
        for (var index = 0; index < count; index++) 'paint-photo-$index',
      ]);
      await _mount(tester, _presenter(actions, people: [person]));
      await _showLastPhoto(tester, count);
      final cardRect = tester.getRect(_key('concept_browse_portrait_card'));
      final controller = tester.widget<PageView>(_pager()).controller!;
      final visited = <int>[];
      void observe() {
        final index = controller.page!.round();
        if (visited.isEmpty || visited.last != index) visited.add(index);
      }

      controller.addListener(observe);
      platformCalls.clear();
      try {
        await tester.tap(_tapTarget());
        await tester.pump();
        _expectPhoto(tester, 0);
        expect(visited, [
          0,
        ], reason: 'Wrap is one atomic selection, not 2→1→0.');
        expectTicks(1);
        expect(_wrap(), findsOneWidget);
        expect(
          tester.widget<SlideTransition>(_wrap()).position.value.dx,
          closeTo(0, .001),
        );
        expect(
          find.descendant(
            of: _wrap(),
            matching: find.byType(ZyraProfileNameBlock),
          ),
          findsNothing,
          reason: 'Details-first wrap photos stay free of identity overlays.',
        );
        expect(
          find.ancestor(
            of: _key('concept_browse_photo_dot_${person.id}_0'),
            matching: _wrap(),
          ),
          findsNothing,
        );
        expect(tester.getRect(_key('concept_browse_portrait_card')), cardRect);
        await tester.tap(_tapTarget());
        await tester.pump(const Duration(milliseconds: 210));
        expect(
          tester.widget<SlideTransition>(_wrap()).position.value.dx,
          closeTo(-.5, .025),
        );
        _expectPhoto(tester, 0);
        await tester.tap(_tapTarget());
        await tester.pump(const Duration(milliseconds: 10));
        expect(
          tester.widget<SlideTransition>(_wrap()).position.value.dx,
          inExclusiveRange(-1, -.5),
        );
        expectTicks(1);
        expect(visited, [0]);
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester.widget<SlideTransition>(_wrap()).position.value.dx,
          closeTo(-1, .001),
        );
        _expectPhoto(tester, 0);
        expectTicks(1);
        expect(visited, [0]);
        await tester.pump(const Duration(milliseconds: 16));
        expect(_wrap(), findsNothing);
        _expectPhoto(tester, 0);
        expectTicks(1);
        expect(visited, [0]);
        expect(_key('concept_browse_details_${person.id}'), findsOneWidget);
        expect(find.byType(ZyraProfileNameBlock), findsNothing);
        expect(tester.getRect(_key('concept_browse_portrait_card')), cardRect);
        expect(
          tester
              .widget<ZyraBrowseDesigns>(find.byType(ZyraBrowseDesigns))
              .selectedIndex,
          0,
        );
        actions.expectNoDecisions();
        expect(tester.takeException(), isNull);
      } finally {
        controller.removeListener(observe);
      }
    });
  }

  testWidgets(
    'real photo swipe interrupts wrap slide and owns the next index',
    (tester) async {
      final actions = _Actions();
      await _mount(tester, _presenter(actions));
      await _showLastPhoto(tester, 3);
      platformCalls.clear();
      await tester.tap(_tapTarget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      expect(_wrap(), findsOneWidget);
      _expectPhoto(tester, 0);
      expectTicks(1);
      final finger = await tester.startGesture(tester.getCenter(_tapTarget()));
      await finger.moveBy(const Offset(-80, 0));
      await tester.pump();
      expect(_wrap(), findsNothing);
      expect(
        tester
            .widget<PageView>(_pager())
            .controller!
            .position
            .isScrollingNotifier
            .value,
        isTrue,
      );
      await finger.moveBy(const Offset(-250, 0));
      await finger.up();
      await tester.pumpAndSettle();
      _expectPhoto(tester, 1);
      expectTicks(2);
      await tester.pump(const Duration(milliseconds: 500));
      _expectPhoto(tester, 1);
      expect(_wrap(), findsNothing);
      expectTicks(2);
      actions.expectNoDecisions();
      expect(tester.takeException(), isNull);
    },
  );

  for (final change in [
    'person',
    'photo sources',
    'photo count',
    'disposed',
    'disable animations',
    'accessible navigation',
  ]) {
    testWidgets('wrap overlay is cancelled by $change without late authority', (
      tester,
    ) async {
      final actions = _Actions();
      await _mount(tester, _presenter(actions));
      await _showLastPhoto(tester, 3);
      await tester.tap(_tapTarget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_wrap(), findsOneWidget);
      _expectPhoto(tester, 0);
      final replacement = switch (change) {
        'person' => _presenter(actions, selected: 1),
        'photo sources' => _presenter(
          actions,
          people: [
            _withPhotos(const ['new-source-0', 'new-source-1', 'new-source-2']),
          ],
        ),
        'photo count' => _presenter(
          actions,
          people: [
            _withPhotos(const ['new-only-photo']),
          ],
        ),
        'disposed' => const SizedBox.shrink(),
        _ => _presenter(actions),
      };
      await tester.pumpWidget(
        _app(
          replacement,
          disableAnimations: change == 'disable animations',
          accessibleNavigation: change == 'accessible navigation',
        ),
      );
      await tester.pump();
      expect(_wrap(), findsNothing);
      platformCalls.clear();
      await tester.pump(const Duration(milliseconds: 600));
      expect(_wrap(), findsNothing);
      if (change != 'disposed') {
        _expectPhoto(
          tester,
          0,
          id: change == 'person' ? _other.id : _person.id,
        );
      }
      expectTicks(0);
      actions.expectNoDecisions();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('same-count source replacement cancels an early adjacent move', (
    tester,
  ) async {
    final actions = _Actions();
    await _mount(tester, _presenter(actions));
    await tester.tap(_tapTarget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<PageView>(_pager()).controller!.page,
      inExclusiveRange(0, .5),
    );
    expectTicks(0);
    await tester.pumpWidget(
      _app(
        _presenter(
          actions,
          people: [
            _withPhotos(const ['new-source-0', 'new-source-1', 'new-source-2']),
          ],
        ),
      ),
    );
    await tester.pump();
    _expectPhoto(tester, 0);
    expect(
      tester
          .widget<PageView>(_pager())
          .controller!
          .position
          .isScrollingNotifier
          .value,
      isFalse,
    );
    await tester.pump(const Duration(milliseconds: 500));
    _expectPhoto(tester, 0);
    expectTicks(0);
    actions.expectNoDecisions();
    expect(tester.takeException(), isNull);
  });

  for (final accessible in [false, true]) {
    testWidgets(
      'enabling ${accessible ? 'accessible navigation' : 'reduced motion'} finishes the owned adjacent tap',
      (tester) async {
        final actions = _Actions();
        await _mount(tester, _presenter(actions));
        await tester.tap(_tapTarget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.widget<PageView>(_pager()).controller!.page,
          inExclusiveRange(0, .5),
        );
        expectTicks(0);
        await tester.pumpWidget(
          _app(
            _presenter(actions),
            disableAnimations: !accessible,
            accessibleNavigation: accessible,
          ),
        );
        await tester.pump();
        _expectPhoto(tester, 1);
        expect(
          tester
              .widget<PageView>(_pager())
              .controller!
              .position
              .isScrollingNotifier
              .value,
          isFalse,
        );
        expect(_wrap(), findsNothing);
        expectTicks(1);
        await tester.pump(const Duration(milliseconds: 500));
        _expectPhoto(tester, 1);
        expectTicks(1);
        actions.expectNoDecisions();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Current clips the viewport, not each sliding photograph', (
    tester,
  ) async {
    final actions = _Actions();
    await _mount(tester, _presenter(actions));
    final card = _key('concept_browse_portrait_card');
    final material = tester.widget<Material>(
      find.descendant(of: card, matching: find.byType(Material)).first,
    );
    expect(
      material.borderRadius,
      BorderRadius.circular(ZyraCardMetrics.cardRadius),
    );
    expect(material.clipBehavior, Clip.antiAlias);
    expect(
      find.descendant(of: _pager(), matching: find.byType(ClipRRect)),
      findsNothing,
      reason: 'Inner rounded pages create a notch where moving photos meet.',
    );
    final viewportClips = find.ancestor(
      of: _pager(),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ClipRRect &&
            widget.borderRadius ==
                BorderRadius.circular(ZyraCardMetrics.thumbRadius),
      ),
    );
    expect(
      viewportClips,
      findsOneWidget,
      reason:
          'The shared photo viewport keeps its own rounded boundary; '
          'the outer Next-motion card clip does not round individual pages.',
    );
    _expectPhoto(tester, 0);
    expectTicks(0);
    actions.expectNoDecisions();
    expect(tester.takeException(), isNull);
  });

  for (final oldPhotoCorners in [false, true]) {
    testWidgets(
      oldPhotoCorners
          ? 'the seam pixel probe detects the original inner rounded-photo notch'
          : 'a real Current photo swipe has no top or bottom seam notch',
      (tester) async {
        final actions = _Actions();
        await _mount(
          tester,
          _presenter(
            actions,
            photoColor: Colors.white,
            emulateOldPhotoRounding: oldPhotoCorners,
          ),
        );
        // Probe the seam between two real photographs, after details.
        await tester.tap(_tapTarget());
        await tester.pumpAndSettle();
        final pagerRect = tester.getRect(_pager());
        final finger = await tester.startGesture(pagerRect.center);
        await finger.moveBy(const Offset(-25, 0));
        await tester.pump();
        await finger.moveBy(Offset(-pagerRect.width * .4, 0));
        await tester.pump();
        final page = tester.widget<PageView>(_pager()).controller!.page!;
        expect(page, inExclusiveRange(1.25, 1.75));
        final seam = tester
            .getRect(_key('concept_browse_photo_${_person.id}_1'))
            .left;
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_paintBoundary),
        );
        final boundaryRect = tester.getRect(find.byKey(_paintBoundary));
        final painted = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            return (width: image.width, height: image.height, bytes: bytes!);
          } finally {
            image.dispose();
          }
        });
        expect(painted, isNotNull);
        final pixels = painted!;
        List<int> pixelAt(double x, double y) {
          final px = (x - boundaryRect.left).round();
          final py = (y - boundaryRect.top).round();
          expect(px, inInclusiveRange(0, pixels.width - 1));
          expect(py, inInclusiveRange(0, pixels.height - 1));
          final offset = (py * pixels.width + px) * 4;
          return [
            for (var channel = 0; channel < 4; channel++)
              pixels.bytes.getUint8(offset + channel),
          ];
        }

        // Avoid the single raster pixel at a fractional rectangle boundary.
        // Radius 10 corners exclude several pixels at these first/last rows,
        // so ±3 still detects the original triangular notch. The scrim is uniform
        // per row and the control must fail this same tight channel tolerance.
        for (final y in [pagerRect.top + 1, pagerRect.bottom - 1]) {
          final reference = pixelAt(seam - 20, y);
          var controlNotchDetected = false;
          for (final x in [seam - 3, seam + 3, seam + 20]) {
            final sample = pixelAt(x, y);
            for (var channel = 0; channel < 4; channel++) {
              if (oldPhotoCorners) {
                controlNotchDetected |=
                    (sample[channel] - reference[channel]).abs() > 2;
              } else {
                expect(
                  sample[channel],
                  closeTo(reference[channel], 2),
                  reason:
                      'No clipped notch at seam ($x, $y), channel $channel.',
                );
              }
            }
          }
          if (oldPhotoCorners) {
            expect(
              controlNotchDetected,
              isTrue,
              reason:
                  'The same probe must detect old inner rounding at row $y.',
            );
          }
        }
        await finger.up();
        await tester.pumpAndSettle();
        actions.expectNoDecisions();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final photos in const <List<String>>[
    [],
    ['paint-single'],
  ]) {
    testWidgets(
      '${photos.length} photos exposes exactly its details and photo pages',
      (tester) async {
        final actions = _Actions();
        await _mount(
          tester,
          _presenter(actions, people: [_withPhotos(photos)]),
        );
        expect(
          tester.widget<GestureDetector>(_tapTarget()).onTapUp,
          photos.isEmpty ? isNull : isNotNull,
        );
        final semantics = _photoSemantics(tester, 0, count: 1);
        expect(semantics.properties.onTap, photos.isEmpty ? isNull : isNotNull);
        expect(
          semantics.properties.customSemanticsActions,
          photos.isEmpty ? isNull : isNotNull,
        );
        await tester.tap(_tapTarget());
        await tester.pumpAndSettle();
        _expectPhoto(tester, photos.isEmpty ? 0 : 1);
        expectTicks(photos.isEmpty ? 0 : 1);
        if (photos.isNotEmpty) {
          expect(
            _photoSemantics(tester, 1, count: 1).properties.label,
            'Photo 1 of 1',
          );
          await tester.tap(_tapTarget());
          await tester.pumpAndSettle();
          _expectPhoto(tester, 0);
          expectTicks(2);
        }
        actions.expectNoDecisions();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final change in ['person', 'photos', 'photo count', 'disposed']) {
    testWidgets('a captured tap cannot act after $change changes', (
      tester,
    ) async {
      final actions = _Actions();
      await _mount(tester, _presenter(actions));
      final staleTap = tester.widget<GestureDetector>(_tapTarget()).onTapUp!;
      final tapDetails = _rightTapUp(tester);
      final stalePageChange = tester.widget<PageView>(_pager()).onPageChanged!;
      final replacement = switch (change) {
        'person' => _presenter(actions, selected: 1),
        'photos' => _presenter(
          actions,
          people: [
            _withPhotos(const [
              'replacement-0',
              'replacement-1',
              'replacement-2',
            ]),
          ],
        ),
        'photo count' => _presenter(
          actions,
          people: [
            _withPhotos(const ['replacement-single']),
          ],
        ),
        _ => const SizedBox.shrink(),
      };
      await tester.pumpWidget(_app(replacement));
      await tester.pumpAndSettle();
      platformCalls.clear();
      staleTap(tapDetails);
      stalePageChange(1);
      await tester.pumpAndSettle();
      expectTicks(0);
      actions.expectNoDecisions();
      if (change != 'disposed') {
        _expectPhoto(
          tester,
          0,
          id: change == 'person' ? _other.id : _person.id,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('additional taps during an animated page move are ignored', (
    tester,
  ) async {
    final actions = _Actions();
    await _mount(tester, _presenter(actions));
    final tap = tester.widget<GestureDetector>(_tapTarget()).onTapUp!;
    final tapDetails = _rightTapUp(tester);
    tap(tapDetails);
    tap(tapDetails);
    await tester.pump(const Duration(milliseconds: 30));
    tester.widget<GestureDetector>(_tapTarget()).onTapUp!(tapDetails);
    await tester.pumpAndSettle();
    _expectPhoto(tester, 1);
    expectTicks(1);
    actions.expectNoDecisions();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap cannot interrupt an in-progress finger swipe', (
    tester,
  ) async {
    final actions = _Actions();
    await _mount(tester, _presenter(actions));
    final tap = tester.widget<GestureDetector>(_tapTarget()).onTapUp!;
    final tapDetails = _rightTapUp(tester);
    final finger = await tester.startGesture(tester.getCenter(_pager()));
    await finger.moveBy(const Offset(-40, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester
          .widget<PageView>(_pager())
          .controller!
          .position
          .isScrollingNotifier
          .value,
      isTrue,
    );
    tap(tapDetails);
    await tester.pump(const Duration(milliseconds: 100));
    expectTicks(0);
    expect(tester.widget<PageView>(_pager()).controller!.page, lessThan(.5));
    await finger.up();
    await tester.pumpAndSettle();
    actions.expectNoDecisions();
    expect(tester.takeException(), isNull);
  });

  for (final accessible in [false, true]) {
    testWidgets(
      '${accessible ? 'accessibility' : 'reduced motion'} taps jump',
      (tester) async {
        final actions = _Actions();
        await _mount(
          tester,
          _presenter(actions),
          disableAnimations: !accessible,
          accessibleNavigation: accessible,
        );
        await tester.tap(_tapTarget());
        await tester.pump();
        _expectPhoto(tester, 1);
        expect(
          tester
              .widget<PageView>(_pager())
              .controller!
              .position
              .isScrollingNotifier
              .value,
          isFalse,
        );
        expectTicks(1);
        for (final (tap, index) in [(2, 2), (3, 3), (4, 0)]) {
          await tester.tap(_tapTarget());
          await tester.pump();
          _expectPhoto(tester, index);
          expect(_wrap(), findsNothing);
          expect(
            tester
                .widget<PageView>(_pager())
                .controller!
                .position
                .isScrollingNotifier
                .value,
            isFalse,
          );
          expectTicks(tap);
        }
        actions.expectNoDecisions();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('accessible tap and Next page advance details and photos', (
    tester,
  ) async {
    final actions = _Actions();
    final semanticsHandle = tester.ensureSemantics();
    try {
      await _mount(tester, _presenter(actions));
      final semantics = _photoSemantics(tester, 0);
      expect(
        semantics.properties.hint,
        'Tap or swipe to view details and photos',
      );
      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.onTap, isNotNull);
      final data = tester.getSemantics(_tapTarget()).getSemanticsData();
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isButton, isTrue);
      expect(
        tester.widget<GestureDetector>(_tapTarget()).excludeFromSemantics,
        isTrue,
      );
      semantics.properties.onTap!();
      await tester.pumpAndSettle();
      _expectPhoto(tester, 1);
      final next = _photoSemantics(tester, 1)
          .properties
          .customSemanticsActions!
          .entries
          .singleWhere((entry) => entry.key.label == 'Next page');
      next.value();
      await tester.pumpAndSettle();
      _expectPhoto(tester, 2);
      expectTicks(2);
      actions.expectNoDecisions();
      expect(tester.takeException(), isNull);
    } finally {
      semanticsHandle.dispose();
    }
  });
}
