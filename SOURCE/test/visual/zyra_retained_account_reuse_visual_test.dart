import '../support/zyra_hidden_dev_controls_driver.dart';
// Real-font, offline review of retained account pages in the request shell.
// Captures are evidence, not native acceptance or live-account save proof.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

const _output = String.fromEnvironment('ZYRA_ACCOUNT_REUSE_VISUAL_OUTPUT');
const _boundary = ValueKey('retained-account-real-font-boundary');
const _font = 'PoppinsRetainedAccountAudit';

class _NoNetwork extends HttpOverrides {
  int calls = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    ++calls;
    throw StateError('Account visual review must remain offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

LinearGradient _localBackground(WidgetTester tester) {
  // The retained leaf has nested shared background wrappers. Inspect the
  // nearest actual gradient, rather than requiring one wrapper in the tree.
  final background = find
      .ancestor(
        of: find.byType(PersonalisationScreen),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).gradient is LinearGradient,
        ),
      )
      .first;
  expect(background, findsOneWidget);
  return (tester.widget<DecoratedBox>(background).decoration as BoxDecoration)
          .gradient!
      as LinearGradient;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = _key(key);
  if (finder.evaluate().isEmpty) {
    final owner = [
      'concept-current-profile-scroll',
      'personalisation-scroll',
    ].map(_key).firstWhere((f) => f.evaluate().isNotEmpty);
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find
          .descendant(of: owner, matching: find.byType(Scrollable))
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _waitForDisplayedPhoto(WidgetTester tester) async {
  final photo = _key('photo-large-0');
  expect(photo, findsOneWidget);
  final imageWidget = find.descendant(of: photo, matching: find.byType(Image));
  expect(imageWidget, findsOneWidget);
  expect(
    tester.widget<Image>(imageWidget).image,
    isA<MemoryImage>(),
    reason: 'The retained editor must paint its actual local JPEG.',
  );
  final pixels = find.descendant(of: photo, matching: find.byType(RawImage));
  // A fake-clock settle does not guarantee that the engine has decoded the
  // newly mounted Image.memory. Wait for its actual displayed first frame.
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await tester.pump();
      expect(tester.takeException(), isNull);
      if (pixels.evaluate().length == 1) {
        final painted = tester.renderObject<RenderImage>(pixels);
        if (painted.image != null &&
            painted.image!.width > 0 &&
            painted.image!.height > 0) {
          return;
        }
      }
    }
    fail('The retained local photo did not decode to a displayed first frame.');
  });
  await tester.pumpAndSettle();
  expect(pixels, findsOneWidget);
  final painted = tester.renderObject<RenderImage>(pixels);
  expect(painted.image, isNotNull);
  expect(painted.image!.width, greaterThan(0));
  expect(painted.image!.height, greaterThan(0));
  expect(painted.size.width, greaterThan(0));
  expect(painted.size.height, greaterThan(0));
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    expect(data, isNotNull);
    if (_output.isNotEmpty) {
      expect(_output.startsWith('/'), isTrue);
      final file = File('$_output/$name.png');
      expect(file.parent.existsSync(), isTrue);
      expect(file.existsSync(), isFalse, reason: 'Captures are immutable.');
      await tester.runAsync(
        () => file.writeAsBytes(data!.buffer.asUint8List(), flush: true),
      );
    }
  } finally {
    image?.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final reading = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final mark = FontLoader('SyneRetainedAccountAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), mark.load(), icons.load()]);
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraText.testWordmarkFontFamily = 'SyneRetainedAccountAudit';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final (size, scale, name) in [
    (const Size(393, 852), 1.0, 'phone'),
    (const Size(320, 568), 1.4, 'compact140'),
    (const Size(320, 568), 2.0, 'compact200'),
  ]) {
    for (final (destination, pageName, pageType) in [
      ('concept_edit_profile', 'profile_answers', EditProfileScreen),
      ('concept_manage_photos', 'photos', EditPhotosScreen),
      ('concept_personalisation', 'personalisation', PersonalisationScreen),
    ]) {
      testWidgets('$pageName $name retains theme and has no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final network = _NoNetwork();
        final globalPaletteBefore = ZyraColors.devPalette;
        var memberWrites = 0;
        void changed() => ++memberWrites;
        AppState.instance.addListener(changed);
        addTearDown(() => AppState.instance.removeListener(changed));
        await HttpOverrides.runWithHttpOverrides(() async {
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData.dark().copyWith(
                textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
              ),
              builder: (_, child) => MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: EdgeInsets.only(
                    top: size.height <= 600 ? 24 : 59,
                    bottom: size.height <= 600 ? 24 : 34,
                  ),
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                  accessibleNavigation: true,
                ),
                child: RepaintBoundary(key: _boundary, child: child!),
              ),
              home: ZyraOneJourneyConceptShell(
                fixture: ZyraShellTestFixture().fixture,
                canAct: () => true,
                onExit: () {},
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final deadline = DateTime.now().add(const Duration(seconds: 5));
            while (DateTime.now().isBefore(deadline)) {
              final deck = tester.widget<ZyraOneJourneyBrowseDesigns>(
                find.byType(ZyraOneJourneyBrowseDesigns),
              );
              if (deck.profiles.isNotEmpty &&
                  deck.profiles.first.photos.isNotEmpty) {
                return;
              }
              await Future<void>.delayed(const Duration(milliseconds: 5));
              await tester.pump();
            }
            fail('Real-font captures require prepared local photo frames.');
          });
          await tester.pumpAndSettle();
          final navigation = tester.widget<ZyraShellNavigation>(
            find.byType(ZyraShellNavigation),
          );
          navigation.onTap(
            navigation.items.indexWhere((item) => item.label == 'Profile'),
          );
          await tester.pumpAndSettle();
          await _tap(tester, destination);
          expect(find.byType(pageType), findsOneWidget);
          expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
          expect(find.text('PREVIEW ONLY'), findsNothing);
          if (pageName == 'photos') {
            await _waitForDisplayedPhoto(tester);
          }
          await _capture(tester, '${pageName}_$name');
          if (pageName == 'personalisation') {
            final localPaletteBefore = tester
                .widget<PersonalisationScreen>(
                  find.byType(PersonalisationScreen),
                )
                .palette!;
            expect(localPaletteBefore, isNot(ZyraDevPalette.deepEmerald));
            expect(_localBackground(tester), localPaletteBefore.gradient);
            await _tap(tester, 'personalisation_background');
            await _capture(tester, 'background_choices_$name');
            final sheet = find.byWidgetPredicate(
              (widget) =>
                  widget is ZyraPersonalisationChoiceSheet<ZyraDevPalette>,
            );
            expect(sheet, findsOneWidget);
            final sheetScrollable = find.descendant(
              of: sheet,
              matching: find.byType(Scrollable),
            );
            expect(sheetScrollable, findsOneWidget);
            final choice = _key(
              'personalisation_choice_${ZyraDevPalette.deepEmerald}',
            );
            await tester.scrollUntilVisible(
              choice,
              100,
              scrollable: sheetScrollable,
              maxScrolls: 12,
            );
            await tester.ensureVisible(choice);
            await tester.pumpAndSettle();
            expect(choice.hitTestable(), findsOneWidget);
            expect(
              tester
                  .getRect(sheetScrollable)
                  .contains(tester.getCenter(choice)),
              isTrue,
              reason: 'The actual choice must be reachable inside its sheet.',
            );
            await tester.tap(choice);
            await tester.pumpAndSettle();
            expect(sheet, findsNothing);
            expect(
              tester
                  .widget<PersonalisationScreen>(
                    find.byType(PersonalisationScreen),
                  )
                  .palette,
              ZyraDevPalette.deepEmerald,
            );
            final content = tester.widget<ZyraPersonalisationContent>(
              find.byType(ZyraPersonalisationContent),
            );
            expect(content.snapshot.palette, ZyraDevPalette.deepEmerald);
            expect(
              content.previewGradient,
              ZyraDevPalette.deepEmerald.gradient,
            );
            expect(
              _localBackground(tester),
              ZyraDevPalette.deepEmerald.gradient,
            );
            expect(
              _localBackground(tester),
              isNot(localPaletteBefore.gradient),
            );
            expect(ZyraColors.devPalette, globalPaletteBefore);
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }, network);
        expect(network.calls, 0);
        expect(memberWrites, 0);
        expect(ZyraColors.devPalette, globalPaletteBefore);
      });
    }
  }
}
