import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_journey_end_presentation.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

const _capture = String.fromEnvironment('ZYRA_END_JOURNEY_CAPTURE_DIR');
const _boundary = ValueKey('end-journey-capture');
const _subject = 'draft-sara';
Finder _key(String name) => find.byKey(ValueKey(name));
void _noop() {}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('End confirmation must remain offline.');
  }
}

Future<void> _captureFrame(WidgetTester tester, String name) async {
  if (_capture.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_capture/$name.png');
      await file.create(exclusive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List photo;
  late bool oldStub;
  late String? oldFont;
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  setUpAll(() async {
    if (_capture.isNotEmpty) {
      if (!_capture.startsWith('/') ||
          FileSystemEntity.typeSync(_capture, followLinks: false) !=
              FileSystemEntityType.notFound) {
        throw StateError('Capture output must be a fresh absolute directory.');
      }
      Directory(_capture).createSync(recursive: true);
    }
    final font = FontLoader('PoppinsEndJourney');
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
    photo = (await rootBundle.load(
      'assets/dev/one_journey_photos/zyra1a.jpg',
    )).buffer.asUint8List();
  });
  setUp(() {
    oldStub = ZyraText.useTestFontStubs;
    oldFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsEndJourney';
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldStub;
    ZyraText.testReadingFontFamily = oldFont;
  });

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(393, 852),
    double scale = 1,
    bool blocked = false,
    bool disabled = false,
    bool motion = false,
    String name = 'Sara Ahmed',
    VoidCallback? confirm,
    VoidCallback? keep,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final top = size.height < 700 ? 44.0 : 59.0;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(top: top, bottom: 34),
            viewPadding: EdgeInsets.only(top: top, bottom: 34),
            textScaler: TextScaler.linear(scale),
            disableAnimations: !motion,
          ),
          child: RepaintBoundary(key: _boundary, child: child!),
        ),
        home: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: ZyraDevPalette.midnightPlum.gradient,
            ),
            child: ZyraPullDownBackScope(
              routeIdentity: 'end-test',
              enabled: false,
              onBack: () => fail('Confirmation cannot swipe close'),
              child: ZyraDraftJourneyEndPresentation(
                subjectId: _subject,
                title: blocked ? 'End this Journey?' : 'End with Sara?',
                name: blocked ? null : name,
                portrait: blocked
                    ? null
                    : Image.memory(
                        photo,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                onConfirm: disabled ? null : (confirm ?? _noop),
                onKeep: keep ?? _noop,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (!blocked) {
      final image = find.byType(Image);
      await tester.runAsync(
        () => precacheImage(
          tester.widget<Image>(image).image,
          tester.element(image),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    }
    expect(tester.takeException(), isNull);
  }

  for (final size in [
    const Size(390, 844),
    const Size(393, 852),
    const Size(430, 932),
  ]) {
    testWidgets('balanced layout and separated actions at $size', (
      tester,
    ) async {
      await mount(tester, size: size);
      final title = _key('draft_end_title_$_subject');
      expect(tester.widget<Text>(title).style, ZyraText.pageTitle());
      expect(tester.getRect(title).left, 20);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      expect(find.text('Your conversation closes'), findsOneWidget);
      expect(
        find.text('This Journey ends for both of you and cannot be reopened.'),
        findsOneWidget,
      );
      expect(find.text('Your Timeline stays'), findsOneWidget);
      final keep = _key('draft_cancel_end_$_subject');
      final end = _key('draft_confirm_end_$_subject');
      for (final target in [keep, end]) {
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        expect(tester.getRect(target).left, 20);
        expect(tester.getRect(target).right, size.width - 20);
      }
      expect(tester.getRect(keep).bottom, lessThan(tester.getRect(end).top));
      expect(tester.getRect(end).bottom, lessThanOrEqualTo(size.height - 34));
      final reader = tester.state<ScrollableState>(
        find.byType(Scrollable).last,
      );
      expect(reader.position.maxScrollExtent, 0);
      expect(find.byType(FittedBox), findsNothing);
      await _captureFrame(tester, 'normal_${size.width.toInt()}');
    });
  }

  testWidgets(
    'compact double text scrolls fully without shrinking and both actions work',
    (tester) async {
      var confirmed = 0, kept = 0;
      await mount(
        tester,
        size: const Size(320, 568),
        scale: 2,
        name: 'Abdul Rahman Ahmed',
        confirm: () => confirmed++,
        keep: () => kept++,
      );
      final name = _key('draft_end_identity_$_subject');
      expect(tester.getSize(name).width, 280);
      expect(tester.widget<Text>(name).style!.fontSize, 24);
      await _captureFrame(tester, 'compact_top');
      for (final id in [
        'draft_cancel_end_$_subject',
        'draft_confirm_end_$_subject',
      ]) {
        await tester.ensureVisible(_key(id));
        await tester.pumpAndSettle();
        expect(_key(id).hitTestable(), findsOneWidget);
        await tester.tap(_key(id));
        await tester.pumpAndSettle();
      }
      expect(confirmed, 1);
      expect(kept, 1);
      expect(tester.takeException(), isNull);
      await _captureFrame(tester, 'compact_actions');
    },
  );

  testWidgets(
    'blocked identity stays absent and confirmation has no swipe cue',
    (tester) async {
      await mount(tester, blocked: true);
      expect(find.text('End this Journey?'), findsOneWidget);
      expect(find.textContaining('Sara'), findsNothing);
      expect(find.byType(Image), findsNothing);
      await tester.timedDragFrom(
        const Offset(30, 110),
        const Offset(0, 230),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      expect(find.text('End this Journey?'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      await _captureFrame(tester, 'blocked');
    },
  );

  testWidgets(
    'disabled confirmation stays disabled and has destructive styling',
    (tester) async {
      await mount(tester, disabled: true);
      final end = tester.widget<OutlinedButton>(
        _key('draft_confirm_end_$_subject'),
      );
      expect(end.onPressed, isNull);
      expect(end.style!.foregroundColor!.resolve({}), ZyraColors.destructive);
      expect(end.style!.side!.resolve({})!.color, ZyraColors.destructiveBorder);
      await tester.tap(_key('draft_confirm_end_$_subject'));
      await tester.pumpAndSettle();
      expect(find.text('End with Sara?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final motion in [false, true]) {
    testWidgets('rendering never invokes actions with motion $motion', (
      tester,
    ) async {
      var actions = 0;
      await mount(
        tester,
        motion: motion,
        confirm: () => actions++,
        keep: () => actions++,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(actions, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
