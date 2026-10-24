import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_text.dart';

const _profile = SeekerProfile(
  id: 'dismiss-sara',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  photos: ['photo-a', 'photo-b'],
);
const _other = SeekerProfile(
  id: 'dismiss-amira',
  firstName: 'Amira',
  surnameLine: 'Rahman',
  age: 28,
  city: 'Manchester',
  gender: 'female',
  photos: ['other-photo'],
);
const _start = Offset(110, 240);
Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _gallery => _key('concept_browse_photo_gallery');
Finder get _surface => _key('concept_browse_photo_dismiss_surface');

Widget _app({
  VoidCallback? onDismiss,
  SeekerProfile profile = _profile,
  bool reducedMotion = false,
  bool accessibleNavigation = false,
  VoidCallback? onRequest,
  VoidCallback? onSave,
  VoidCallback? onMenu,
}) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reducedMotion,
      accessibleNavigation: accessibleNavigation,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: ZyraOneJourneyBrowsePresentation(
      profile: profile,
      onMenu: onMenu ?? () {},
      onDismiss: onDismiss,
      onRequest: onRequest,
      onSave: onSave,
      requestKey: const ValueKey('dismiss-request'),
      saveKey: const ValueKey('dismiss-save'),
      menuKey: const ValueKey('dismiss-menu'),
      imageBuilder: (_, photo) =>
          ColoredBox(key: ValueKey(photo), color: Colors.black),
    ),
  ),
);

Future<void> _mount(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

double _offset(WidgetTester tester) =>
    tester.widget<Transform>(_surface).transform.storage[13];

DragEndDetails _release(double velocity) => DragEndDetails(
  velocity: Velocity(pixelsPerSecond: Offset(0, velocity)),
  primaryVelocity: velocity,
);

Future<void> _pull(WidgetTester tester, Offset delta) =>
    tester.timedDragFrom(_start, delta, const Duration(milliseconds: 650));

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets('downward pull follows the finger before release', (
    tester,
  ) async {
    var dismissed = 0;
    await _mount(tester, _app(onDismiss: () => dismissed++));
    final gesture = await tester.startGesture(_start);
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(_offset(tester), greaterThan(40));
    expect(_offset(tester), lessThanOrEqualTo(120));
    expect(dismissed, 0);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(_offset(tester), 0);
  });

  testWidgets('deliberate pull slides away then dismisses exactly once', (
    tester,
  ) async {
    var dismissed = 0;
    await _mount(tester, _app(onDismiss: () => dismissed++));
    final release = tester.widget<GestureDetector>(_gallery).onVerticalDragEnd!;
    await _pull(tester, const Offset(0, 240));
    expect(dismissed, 0, reason: 'The photo closes after its slide finishes.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(dismissed, 0);
    await tester.pumpAndSettle();
    expect(dismissed, 1);
    release(_release(1200));
    await tester.pumpAndSettle();
    expect(dismissed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small slow pull springs back without dismissal', (tester) async {
    var dismissed = 0;
    await _mount(tester, _app(onDismiss: () => dismissed++));
    await _pull(tester, const Offset(0, 60));
    await tester.pump();
    final beginning = _offset(tester);
    expect(beginning, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 70));
    expect(_offset(tester), lessThan(beginning));
    expect(_offset(tester), greaterThan(0));
    await tester.pumpAndSettle();
    expect(_offset(tester), 0);
    expect(dismissed, 0);
  });

  for (final direction in const [Offset(0, -150), Offset(160, 0)]) {
    testWidgets('$direction does not dismiss or change a photo', (
      tester,
    ) async {
      var dismissed = 0;
      await _mount(tester, _app(onDismiss: () => dismissed++));
      await _pull(tester, direction);
      await tester.pumpAndSettle();
      expect(_offset(tester), 0);
      expect(dismissed, 0);
      expect(_key('photo-a'), findsOneWidget);
    });
  }

  testWidgets('positive fling with a meaningful pull dismisses', (
    tester,
  ) async {
    var dismissed = 0;
    await _mount(tester, _app(onDismiss: () => dismissed++));
    await tester.flingFrom(_start, const Offset(0, 70), 1400);
    await tester.pumpAndSettle();
    expect(dismissed, 1);
  });

  testWidgets('tiny fast pull is not a dismissing fling', (tester) async {
    var dismissed = 0;
    await _mount(tester, _app(onDismiss: () => dismissed++));
    final gesture = tester.widget<GestureDetector>(_gallery);
    gesture.onVerticalDragStart!(DragStartDetails(globalPosition: _start));
    gesture.onVerticalDragUpdate!(
      DragUpdateDetails(
        globalPosition: _start + const Offset(0, 12),
        delta: const Offset(0, 12),
        primaryDelta: 12,
      ),
    );
    gesture.onVerticalDragEnd!(_release(1800));
    await tester.pumpAndSettle();
    expect(_offset(tester), 0);
    expect(dismissed, 0);
  });

  for (final reducedMotion in [false, true]) {
    for (final pull in [60.0, 220.0]) {
      testWidgets(
        'actual pointer cancellation at $pull (reduced $reducedMotion) returns to photo',
        (tester) async {
          var dismissed = 0;
          await _mount(
            tester,
            _app(onDismiss: () => dismissed++, reducedMotion: reducedMotion),
          );
          final gesture = await tester.startGesture(_start);
          await gesture.moveBy(const Offset(0, 40));
          await tester.pump();
          await gesture.moveBy(Offset(0, pull - 40));
          await tester.pump();
          expect(_offset(tester), greaterThan(0));
          if (pull > 100) expect(_offset(tester), greaterThan(100));
          // This is a real PointerCancelEvent after the recognizer accepted
          // the drag, not a direct call to its onVerticalDragCancel delegate.
          await gesture.cancel();
          await tester.pumpAndSettle();
          expect(_offset(tester), 0);
          expect(dismissed, 0);
          expect(_key('photo-a'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final cancelFirst in [false, true]) {
      testWidgets(
        'raw cancel wins proxied release ordering $cancelFirst (reduced $reducedMotion)',
        (tester) async {
          var dismissed = 0;
          await _mount(
            tester,
            _app(onDismiss: () => dismissed++, reducedMotion: reducedMotion),
          );
          final pointer = tester.widget<Listener>(
            _key('concept_browse_photo_dismiss_pointer'),
          );
          final gesture = tester.widget<GestureDetector>(_gallery);
          pointer.onPointerDown!(
            const PointerDownEvent(pointer: 7, position: _start),
          );
          gesture.onVerticalDragStart!(
            DragStartDetails(globalPosition: _start),
          );
          gesture.onVerticalDragUpdate!(
            DragUpdateDetails(
              globalPosition: _start + const Offset(0, 220),
              delta: const Offset(0, 220),
              primaryDelta: 220,
            ),
          );
          void cancel() => pointer.onPointerCancel!(
            const PointerCancelEvent(pointer: 7, position: _start),
          );
          void release() => gesture.onVerticalDragEnd!(_release(1400));
          if (cancelFirst) {
            cancel();
            release();
          } else {
            release();
            cancel();
          }
          await tester.pumpAndSettle();
          expect(_offset(tester), 0);
          expect(dismissed, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('default-null viewer has no new vertical gesture', (
    tester,
  ) async {
    await _mount(tester, _app());
    final gesture = tester.widget<GestureDetector>(_gallery);
    expect(gesture.onVerticalDragStart, isNull);
    expect(gesture.onVerticalDragUpdate, isNull);
    expect(gesture.onVerticalDragEnd, isNull);
    expect(gesture.onVerticalDragCancel, isNull);
    expect(_surface, findsNothing);
    await _pull(tester, const Offset(0, 240));
    await tester.pumpAndSettle();
    expect(_key('photo-a'), findsOneWidget);
  });

  for (final accessible in [false, true]) {
    testWidgets(
      'reduced motion ($accessible) dismisses without animated wait',
      (tester) async {
        var dismissed = 0;
        await _mount(
          tester,
          _app(
            onDismiss: () => dismissed++,
            reducedMotion: !accessible,
            accessibleNavigation: accessible,
          ),
        );
        await _pull(tester, const Offset(0, 240));
        expect(dismissed, 1);
        await tester.pumpAndSettle();
        expect(dismissed, 1);
      },
    );
  }

  testWidgets('photo taps and explicit actions keep their original delegates', (
    tester,
  ) async {
    var dismissed = 0, requested = 0, saved = 0, menu = 0;
    await _mount(
      tester,
      _app(
        onDismiss: () => dismissed++,
        onRequest: () => requested++,
        onSave: () => saved++,
        onMenu: () => menu++,
      ),
    );
    await tester.tapAt(const Offset(350, 300));
    await tester.pumpAndSettle();
    expect(_key('photo-b'), findsOneWidget);
    await tester.tapAt(const Offset(40, 300));
    await tester.pumpAndSettle();
    expect(_key('photo-a'), findsOneWidget);
    expect((dismissed, requested, saved, menu), (0, 0, 0, 0));
    await tester.tap(_key('dismiss-request'));
    await tester.tap(_key('dismiss-save'));
    await tester.tap(_key('dismiss-menu'));
    await tester.pumpAndSettle();
    expect((dismissed, requested, saved, menu), (0, 1, 1, 1));
    expect(tester.takeException(), isNull);
  });

  for (final change in [
    'render',
    'delegate',
    'profile',
    'disabled',
    'dispose',
  ]) {
    testWidgets('retained release is inert after $change', (tester) async {
      var oldDismissed = 0, newDismissed = 0;
      void oldDismiss() => oldDismissed++;
      void newDismiss() => newDismissed++;
      await _mount(tester, _app(onDismiss: oldDismiss));
      final retained = tester.widget<GestureDetector>(_gallery);
      final retainedPointer = tester.widget<Listener>(
        _key('concept_browse_photo_dismiss_pointer'),
      );
      retainedPointer.onPointerDown!(
        const PointerDownEvent(pointer: 9, position: _start),
      );
      retained.onVerticalDragStart!(DragStartDetails(globalPosition: _start));
      retained.onVerticalDragUpdate!(
        DragUpdateDetails(
          globalPosition: _start + const Offset(0, 220),
          delta: const Offset(0, 220),
          primaryDelta: 220,
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        change == 'dispose'
            ? const MaterialApp(home: SizedBox.shrink())
            : _app(
                onDismiss: change == 'disabled'
                    ? null
                    : change == 'delegate'
                    ? newDismiss
                    : oldDismiss,
                profile: change == 'profile' ? _other : _profile,
              ),
      );
      retainedPointer.onPointerCancel!(
        const PointerCancelEvent(pointer: 9, position: _start),
      );
      retained.onVerticalDragEnd!(_release(1400));
      retained.onVerticalDragCancel!();
      retained.onVerticalDragUpdate!(
        DragUpdateDetails(
          globalPosition: _start + const Offset(0, 100),
          delta: const Offset(0, 100),
          primaryDelta: 100,
        ),
      );
      await tester.pumpAndSettle();
      expect((oldDismissed, newDismissed), (0, 0));
      if (change != 'dispose' && change != 'disabled') {
        expect(_offset(tester), 0);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('in-flight dismissal is revoked after $change', (tester) async {
      var oldDismissed = 0, newDismissed = 0;
      void oldDismiss() => oldDismissed++;
      void newDismiss() => newDismissed++;
      await _mount(tester, _app(onDismiss: oldDismiss));
      await _pull(tester, const Offset(0, 240));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(oldDismissed, 0);
      await tester.pumpWidget(
        change == 'dispose'
            ? const MaterialApp(home: SizedBox.shrink())
            : _app(
                onDismiss: change == 'disabled'
                    ? null
                    : change == 'delegate'
                    ? newDismiss
                    : oldDismiss,
                profile: change == 'profile' ? _other : _profile,
              ),
      );
      await tester.pumpAndSettle();
      expect((oldDismissed, newDismissed), (0, 0));
      if (change != 'dispose' && change != 'disabled') {
        expect(_offset(tester), 0);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('new delegate can dismiss after an old gesture was revoked', (
    tester,
  ) async {
    var oldDismissed = 0, newDismissed = 0;
    await _mount(tester, _app(onDismiss: () => oldDismissed++));
    final retained = tester.widget<GestureDetector>(_gallery);
    retained.onVerticalDragStart!(DragStartDetails(globalPosition: _start));
    await tester.pumpWidget(_app(onDismiss: () => newDismissed++));
    await _pull(tester, const Offset(0, 240));
    await tester.pumpAndSettle();
    expect((oldDismissed, newDismissed), (0, 1));
    expect(tester.takeException(), isNull);
  });
}
