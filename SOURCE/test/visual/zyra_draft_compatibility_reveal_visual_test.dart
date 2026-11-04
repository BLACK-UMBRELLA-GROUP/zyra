// Review-only real-font frames for the locked action and fixed Golden Halo.
// Uses a local Stateful callback fixture: no accounts, answers, credits,
// providers, backend calls, purchases, or approved golden-file promotions.
// Optional PNG output: --dart-define=ZYRA_COMPATIBILITY_REVEAL_CAPTURE_DIR=<absolute packet directory>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_compatibility_demo.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _captureDirectory = String.fromEnvironment(
  'ZYRA_COMPATIBILITY_REVEAL_CAPTURE_DIR',
);
const _root = ValueKey('draft-compatibility-reveal-visual-root');
const _card = ValueKey('draft_compatibility_card');
const _viewport = ValueKey('draft_compatibility_viewport');
const _reveal = ValueKey('draft_compatibility_reveal');
const _more = ValueKey('draft_compatibility_buy_more');
const _score = ValueKey('draft_compatibility_overall_score');
const _reader = ValueKey('draft_compatibility_score_reader');
const _next = ValueKey('draft_compatibility_score_next');
const _font = 'PoppinsCompatibilityRevealAudit';

class _RevealFixture extends StatefulWidget {
  const _RevealFixture({required this.fixtureKey}) : super(key: fixtureKey);

  final GlobalKey<_RevealFixtureState> fixtureKey;

  @override
  State<_RevealFixture> createState() => _RevealFixtureState();
}

class _RevealFixtureState extends State<_RevealFixture> {
  int balance = 1;
  int calls = 0;
  bool revealed = false;

  @override
  Widget build(BuildContext context) => ZyraDraftCompatibilityPresentation(
    personName: 'Sara',
    balance: balance,
    overallScore: 76,
    revealed: revealed,
    onUnlock: () {
      if (revealed || balance == 0) return;
      setState(() {
        calls++;
        balance--;
        revealed = true;
      });
    },
    onBuyMore: () {},
  );
}

Future<GlobalKey<_RevealFixtureState>> _mount(
  WidgetTester tester, {
  required Size size,
  double scale = 1,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final safeInsets = EdgeInsets.only(
    top: size.height <= 600 ? 24 : 59,
    bottom: size.height <= 600 ? 24 : 34,
  );
  final fixture = GlobalKey<_RevealFixtureState>();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
        splashFactory: NoSplash.splashFactory,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reducedMotion,
          padding: safeInsets,
          viewPadding: safeInsets,
        ),
        child: RepaintBoundary(key: _root, child: child!),
      ),
      home: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: _RevealFixture(fixtureKey: fixture),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.byKey(_reveal), findsOneWidget);
  return fixture;
}

Future<String> _frame(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_root),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  expect(image, isNotNull, reason: name);
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    expect(data, isNotNull, reason: name);
    final bytes = data!.buffer.asUint8List();
    if (_captureDirectory.isNotEmpty) {
      expect(
        _captureDirectory.startsWith('/'),
        isTrue,
        reason:
            'Captures must use the root-coordinated absolute review packet.',
      );
      final directory = Directory(_captureDirectory);
      expect(directory.existsSync(), isTrue);
      final output = File('${directory.path}/$name.png');
      expect(output.existsSync(), isFalse, reason: 'Retain immutable frames.');
      await tester.runAsync(() => output.writeAsBytes(bytes, flush: true));
    }
    return sha256.convert(bytes).toString();
  } finally {
    image!.dispose();
  }
}

void _expectNormalFit(WidgetTester tester, Size size) {
  final scrollable = find.descendant(
    of: find.byKey(_viewport),
    matching: find.byType(Scrollable),
  );
  expect(scrollable, findsOneWidget);
  final position = tester.state<ScrollableState>(scrollable).position;
  expect(position.maxScrollExtent, closeTo(0, .01));
  expect(position.pixels, 0);
  final card = tester.getRect(find.byKey(_card));
  // LOCK 22 V6 §§2–3, master UNITY_PASS/MASTERS/x01: the Monogram
  // head is above the floating information card; actions sit below both.
  expect(card.left, greaterThanOrEqualTo(20));
  expect(card.right, lessThanOrEqualTo(size.width - 20));
  for (final key in [_reveal, _more]) {
    if (find.byKey(key).evaluate().isEmpty) continue;
    final rect = tester.getRect(find.byKey(key));
    expect(rect.top, greaterThanOrEqualTo(75));
    expect(rect.bottom, lessThanOrEqualTo(size.height - 50));
    expect(rect.left, greaterThanOrEqualTo(20));
    expect(rect.right, lessThanOrEqualTo(size.width - 20));
    expect(find.byKey(key).hitTestable(), findsOneWidget);
  }
  final head = tester.getRect(
    find.byKey(const ValueKey('draft_compatibility_locked_halo')),
  );
  expect(head.size, const Size(96, 96));
  expect(head.bottom, lessThanOrEqualTo(card.top));
  final actions = tester.getRect(
    find.byKey(const ValueKey('draft_compatibility_actions')),
  );
  expect(actions.top, greaterThanOrEqualTo(card.bottom));
  for (final key in [
    const ValueKey('draft_compatibility_locked_halo'),
    _card,
    const ValueKey('draft_compatibility_actions'),
  ]) {
    final rect = tester.getRect(find.byKey(key));
    expect(rect.left, greaterThanOrEqualTo(20));
    expect(rect.right, lessThanOrEqualTo(size.width - 20));
    expect(rect.top, greaterThanOrEqualTo(75));
    expect(rect.bottom, lessThanOrEqualTo(size.height - 50));
  }
  expect(find.text('You and Sara'), findsOneWidget);
  expect(find.text('READY TO REVEAL'), findsOneWidget);
  expect(find.text('Your overall score and six areas'), findsOneWidget);
  expect(find.text('Uses 1 Unlock'), findsOneWidget);
  expect(find.text('OVERALL'), findsNothing);
  expect(find.text('DETAILS'), findsNothing);
  expect(find.textContaining('%'), findsNothing);
  expect(find.byKey(_reader), findsNothing);
  expect(find.text('Demo Guardian · Father'), findsNothing);
  expect(tester.takeException(), isNull);
}

Future<void> _startReveal(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_reveal));
  await tester.pumpAndSettle();
  expect(find.byKey(_reveal).hitTestable(), findsOneWidget);
  await tester.tap(find.byKey(_reveal));
  // Commit the caller-owned reveal. The fixed reader appears immediately.
  await tester.pump();
}

Future<void> _expectReachableBottom(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_more));
  await tester.pumpAndSettle();
  expect(find.byKey(_more).hitTestable(), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void _expectReader(WidgetTester tester, {int page = 0}) {
  expect(find.byKey(_reader), findsOneWidget);
  expect(find.byKey(_card), findsNothing);
  expect(find.byKey(_reveal), findsNothing);
  expect(find.byKey(_more), findsNothing);
  expect(find.text('Compatibility score'), findsOneWidget);
  expect(find.text('You and Sara'), findsNothing);
  expect(find.text('${page + 1} / 7'), findsOneWidget);
  expect(
    find.byKey(ValueKey('draft_compatibility_score_artwork_halo_$page')),
    findsOneWidget,
  );
  final target = find.byKey(_next);
  expect(tester.getSize(target).shortestSide, greaterThanOrEqualTo(44));
  expect(target.hitTestable(), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void _expectReaderFit(WidgetTester tester, Size size) {
  _expectReader(tester);
  final rect = tester.getRect(find.byKey(_reader));
  expect(rect.left, closeTo(20, .01));
  expect(rect.right, closeTo(size.width - 20, .01));
  expect(rect.top, greaterThan(0));
  final bottomInset = size.height <= 600 ? 24 : 34;
  expect(rect.bottom, lessThanOrEqualTo(size.height - bottomInset - 16 + .01));
}

Future<void> _nextPage(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(_next));
  await tester.pumpAndSettle();
  _expectReader(tester, page: index);
  final category = ZyraCompatibilityDemo.categories[index - 1];
  expect(find.text(category.name), findsOneWidget);
  for (final metric in [
    ('aligned', category.aligned),
    ('discuss', category.discuss),
    ('opposed', category.opposed),
  ]) {
    expect(
      find.descendant(
        of: find.byKey(
          ValueKey('draft_compatibility_metric_${index}_${metric.$1}'),
        ),
        matching: find.text('${metric.$2}%'),
      ),
      findsOneWidget,
    );
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
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraText.restoreAppFont(null);
    ZyraColors.restoreAppPalette(null);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  testWidgets(
    '393x852 locked card becomes Golden Halo with one caller-owned reveal',
    (tester) async {
      const size = Size(393, 852);
      final fixture = await _mount(tester, size: size);
      _expectNormalFit(tester, size);
      final retainedReveal = tester
          .widget<FilledButton>(find.byKey(_reveal))
          .onPressed!;
      await _frame(tester, '393x852-locked');
      await _startReveal(tester);
      _expectReaderFit(tester, size);
      expect(fixture.currentState!.calls, 1);
      expect(fixture.currentState!.balance, 0);
      expect(find.text('76%'), findsOneWidget);
      expect(find.text('Demo Guardian · Father'), findsOneWidget);
      await _frame(tester, '393x852-golden-halo-overall');
      await _nextPage(tester, 1);
      await _frame(tester, '393x852-golden-halo-lifestyle');
      retainedReveal();
      retainedReveal();
      await tester.pumpAndSettle();
      _expectReader(tester, page: 1);
      expect(fixture.currentState!.calls, 1);
      expect(fixture.currentState!.balance, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  for (final size in const [Size(375, 812), Size(320, 568)]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('$name locked and settled remain readable and reachable', (
      tester,
    ) async {
      final fixture = await _mount(tester, size: size);
      if (size.width >= 375) _expectNormalFit(tester, size);
      await _frame(tester, '$name-locked');
      await _startReveal(tester);
      _expectReaderFit(tester, size);
      await _frame(tester, '$name-golden-halo-overall');
      expect(fixture.currentState!.calls, 1);
      expect(find.text('76%'), findsOneWidget);
      expect(find.text('Demo Guardian · Father'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('200 percent text keeps all content reachable', (tester) async {
    await _mount(tester, size: const Size(393, 852), scale: 2);
    await _frame(tester, '393x852-text200-locked-top');
    await _expectReachableBottom(tester);
    await _frame(tester, '393x852-text200-locked-bottom');
    await _startReveal(tester);
    _expectReader(tester);
    final guardian = find.byKey(
      const ValueKey('draft_compatibility_guardian_result'),
    );
    await tester.ensureVisible(guardian);
    await tester.pumpAndSettle();
    expect(guardian.hitTestable(), findsOneWidget);
    await _frame(tester, '393x852-text200-golden-halo-overall-bottom');
    final page = find.byKey(const ValueKey('draft_compatibility_score_page_0'));
    await tester.drag(page, const Offset(0, 1200));
    await tester.pumpAndSettle();
    await _frame(tester, '393x852-text200-golden-halo-overall-top');
    expect(find.text('76%'), findsOneWidget);
    expect(find.text('Demo Guardian · Father'), findsOneWidget);
    for (
      var index = 1;
      index <= ZyraCompatibilityDemo.categories.length;
      index++
    ) {
      await _nextPage(tester, index);
      final bottom = find.byKey(
        ValueKey('draft_compatibility_metric_${index}_opposed'),
      );
      await tester.ensureVisible(bottom);
      await tester.pumpAndSettle();
      expect(bottom.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Overall is complete on the first caller-committed reveal frame',
    (tester) async {
      const size = Size(393, 852);
      final fixture = await _mount(tester, size: size);
      await tester.tap(find.byKey(_reveal));
      await tester.pump();
      _expectReaderFit(tester, size);
      expect(tester.widget<Text>(find.byKey(_score)).data, '76%');
      expect(find.text('76%'), findsOneWidget);
      expect(find.text('Demo Guardian · Father'), findsOneWidget);
      expect(fixture.currentState!.calls, 1);
      expect(fixture.currentState!.balance, 0);
      await _frame(tester, '393x852-golden-halo-first-frame');
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(_score)).data, '76%');
      expect(fixture.currentState!.calls, 1);
      expect(fixture.currentState!.balance, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('reduced motion displays the complete result immediately', (
    tester,
  ) async {
    const size = Size(393, 852);
    final fixture = await _mount(tester, size: size, reducedMotion: true);
    await _startReveal(tester);
    _expectReaderFit(tester, size);
    expect(find.text('76%'), findsOneWidget);
    expect(find.text('Demo Guardian · Father'), findsOneWidget);
    expect(fixture.currentState!.calls, 1);
    expect(fixture.currentState!.balance, 0);
    await _frame(tester, '393x852-golden-halo-reduced-motion');
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
