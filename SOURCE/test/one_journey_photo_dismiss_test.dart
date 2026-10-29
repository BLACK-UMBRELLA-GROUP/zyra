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
const _start = Offset(110, 240);
Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _gallery => _key('concept_browse_photo_gallery');
Finder get _surface => _key('concept_browse_photo_dismiss_surface');

Widget _app({
  VoidCallback? onDismiss,
  VoidCallback? onRequest,
  VoidCallback? onMenu,
}) => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(
    body: ZyraOneJourneyBrowsePresentation(
      profile: _profile,
      onMenu: onMenu ?? () {},
      onDismiss: onDismiss,
      onRequest: onRequest,
      requestKey: const ValueKey('dismiss-request'),
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

Future<void> _pull(WidgetTester tester, Offset delta) =>
    tester.timedDragFrom(_start, delta, const Duration(milliseconds: 650));

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

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

  testWidgets('photo taps and explicit actions keep their original delegates', (
    tester,
  ) async {
    var dismissed = 0, requested = 0, menu = 0;
    await _mount(
      tester,
      _app(
        onDismiss: () => dismissed++,
        onRequest: () => requested++,
        onMenu: () => menu++,
      ),
    );
    await tester.tapAt(const Offset(350, 300));
    await tester.pumpAndSettle();
    expect(_key('photo-b'), findsOneWidget);
    await tester.tapAt(const Offset(40, 300));
    await tester.pumpAndSettle();
    expect(_key('photo-a'), findsOneWidget);
    expect((dismissed, requested, menu), (0, 0, 0));
    await tester.tap(_key('dismiss-request'));
    await tester.tap(_key('dismiss-menu'));
    await tester.pumpAndSettle();
    expect((dismissed, requested, menu), (0, 1, 1));
    expect(tester.takeException(), isNull);
  });
}
