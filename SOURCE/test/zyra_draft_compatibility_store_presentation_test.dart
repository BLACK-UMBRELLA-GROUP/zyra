import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _font = 'PoppinsDraftCompatibilityStore';
const _offers = <String, int>{
  'unlock_single': 299,
  'unlock_three': 699,
  'unlock_five': 999,
};
const _savings = <String, String>{
  'unlock_three': 'Save 22% vs singles',
  'unlock_five': 'Save 33% vs singles',
};
const _captures = String.fromEnvironment('ZYRA_UNLOCK_STORE_CAPTURE_DIR');
const _captureKey = ValueKey('unlock-store-capture');
const _membershipScrollKey = ValueKey('unlock-store-membership-parent');
const _examplePages = [
  ('Overall', 79),
  ('Lifestyle', 72),
  ('Work & Education', 84),
  ('Family Values', 88),
  ('Marriage Goals', 81),
  ('Personality', 76),
  ('Deen', 90),
];
const _benefits = [
  'See your overall match score',
  'See how you match on faith, family and lifestyle',
  'See who their Guardian is, where available',
];
const _lifetime =
    'An unlock is permanent. Once you unlock a profile it stays unlocked, '
    'including after a Journey ends.';
const _terms =
    'One-off purchase. Refunds are subject to Apple’s terms and applicable law';
const _androidTerms =
    'One-off purchase. Refunds are subject to Google Play’s terms and applicable law';

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    ++attempts;
    throw StateError('The Unlocks presentation must remain offline.');
  }
}

Finder _key(String id) => find.byKey(ValueKey('draft_compatibility_store_$id'));

Future<void> _captureFrame(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  double scale = 1,
  bool reduceMotion = false,
  bool membershipParent = false,
  int? balance,
  VoidCallback? onTerms,
  TargetPlatform storePlatform = TargetPlatform.iOS,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  Widget presentation = ZyraDraftCompatibilityStorePresentation(
    balance: balance,
    onTerms: onTerms,
    storePlatform: storePlatform,
  );
  if (membershipParent) {
    presentation = SingleChildScrollView(
      key: _membershipScrollKey,
      child: presentation,
    );
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => RepaintBoundary(
        key: _captureKey,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
      ),
      home: Scaffold(
        body: DecoratedBox(
          key: const ValueKey('store-fixture-background'),
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SizedBox.expand(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: presentation,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

ScrollPosition _position(WidgetTester tester) {
  final scrollable = find.descendant(
    of: _key('viewport'),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    ),
  );
  return tester.state<ScrollableState>(scrollable).position;
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

RenderParagraph _paragraphForText(Element element) {
  final paragraphs = <RenderParagraph>[];
  void visit(Element child) {
    if (child.widget is RichText) {
      final render = child.renderObject;
      expect(render, isA<RenderParagraph>());
      paragraphs.add(render! as RenderParagraph);
      return;
    }
    child.visitChildElements(visit);
  }

  // Text.semanticsLabel adds wrappers above RichText. Inspect its actual
  // paragraph instead of assuming Text's first render object is the glyphs.
  element.visitChildElements(visit);
  expect(paragraphs, hasLength(1));
  return paragraphs.single;
}

void _expectNoHorizontalOverflow(
  WidgetTester tester,
  double width, {
  bool allowOffscreenOffers = false,
  double? scale,
}) {
  for (final element
      in find
          .descendant(of: _key('presentation'), matching: find.byType(Text))
          .evaluate()) {
    final paragraph = _paragraphForText(element);
    if (!paragraph.hasSize) continue;
    final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
    expect(paragraph.didExceedMaxLines, isFalse);
    final text = element.widget as Text;
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(text.overflow, isNot(TextOverflow.fade));
    if (scale != null) {
      expect(
        MediaQuery.textScalerOf(element).scale(14),
        closeTo(14 * scale, .001),
      );
    }
    var offerText = false;
    var previewPageText = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is PageView) previewPageText = true;
      if (ancestor.widget is OutlinedButton &&
          _offers.keys.any(
            (id) =>
                ancestor.widget.key ==
                ValueKey('draft_compatibility_store_$id'),
          )) {
        offerText = true;
        return false;
      }
      return true;
    });
    // PageView may retain a neighbouring page beyond its clipped viewport.
    // Keep all typography checks, but only apply screen bounds to the visible
    // page. A partially visible/overflowing current-page paragraph still fails.
    if (previewPageText &&
        !rect.overlaps(tester.getRect(_key('preview_pages')))) {
      continue;
    }
    if (!(allowOffscreenOffers && offerText)) {
      expect(rect.left, greaterThanOrEqualTo(20 - .01), reason: text.data);
      expect(
        rect.right,
        lessThanOrEqualTo(width - 20 + .01),
        reason: text.data,
      );
    }
  }
}

void _expectOfferContentsContained(WidgetTester tester, String id) {
  final offer = tester.getRect(_key(id));
  final contents = <Rect>[];
  for (final element
      in find
          .descendant(of: _key(id), matching: find.byType(Text))
          .evaluate()) {
    final paragraph = _paragraphForText(element);
    final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
    expect(rect.left, greaterThanOrEqualTo(offer.left - .01));
    expect(rect.right, lessThanOrEqualTo(offer.right + .01));
    expect(rect.top, greaterThanOrEqualTo(offer.top - .01));
    expect(rect.bottom, lessThanOrEqualTo(offer.bottom + .01));
    contents.add(rect);
  }
  for (var a = 0; a < contents.length; a++) {
    for (var b = a + 1; b < contents.length; b++) {
      expect(contents[a].overlaps(contents[b]), isFalse);
    }
  }
}

void _expectCheckoutHeld(WidgetTester tester, {String? selected}) {
  expect(ZyraMembershipCatalog.checkoutAvailable, isFalse);
  expect(tester.widget<FilledButton>(_key('continue')).onPressed, isNull);
  final label = selected == null
      ? 'Continue'
      : 'Continue · ${ZyraMembershipCatalog.pounds(_offers[selected]!)}';
  expect(
    find.descendant(of: _key('continue'), matching: find.text(label)),
    findsOneWidget,
  );
  if (_savings.containsKey(selected)) {
    expect(
      find.descendant(
        of: _key('continue'),
        matching: find.text(_savings[selected]!),
      ),
      findsOneWidget,
    );
  } else {
    expect(
      find.descendant(
        of: _key('continue'),
        matching: find.textContaining('Save '),
      ),
      findsNothing,
    );
  }
  expect(find.text('Purchasing isn’t available yet.'), findsOneWidget);
  expect(find.textContaining('Non-refundable'), findsNothing);
  expect(find.textContaining('Buy now'), findsNothing);
  expect(find.textContaining('Save £'), findsNothing);
}

void _expectNoUseFeature() {
  expect(_key('use_unlocks'), findsNothing);
  expect(_key('use_guidance'), findsNothing);
  expect(find.text('Use an unlock'), findsNothing);
  expect(
    find.text('Choose a profile in Profiles to use an unlock.'),
    findsNothing,
  );
  expect(_key('person'), findsNothing);
}

void _expectBalance(WidgetTester tester, int balance) {
  expect(find.text('Unlocks remaining'), findsOneWidget);
  expect(tester.widget<Text>(_key('balance_count')).data, '$balance');
  final semantics = tester.widget<Semantics>(_key('balance')).properties;
  expect(semantics.onTap, isNull);
  expect(semantics.label, 'Unlocks remaining: $balance');
  expect(
    find.descendant(of: _key('balance'), matching: find.byType(OutlinedButton)),
    findsNothing,
  );
  final panel = tester.getRect(_key('balance'));
  final label = tester.getRect(_key('balance_label'));
  final count = tester.getRect(_key('balance_count'));
  final capsule = tester.getRect(_key('balance_capsule'));
  expect(capsule.left, greaterThanOrEqualTo(panel.left));
  expect(capsule.right, lessThanOrEqualTo(panel.right));
  expect(capsule.top, greaterThanOrEqualTo(panel.top));
  expect(capsule.bottom, lessThanOrEqualTo(panel.bottom));
  expect(count.left, greaterThanOrEqualTo(capsule.left + 8));
  expect(count.right, lessThanOrEqualTo(capsule.right - 8));
  expect(label.left, greaterThanOrEqualTo(panel.left));
  expect(count.right, lessThanOrEqualTo(panel.right));
  if (_key('balance_stacked').evaluate().isNotEmpty) {
    expect(label.bottom + 4, lessThanOrEqualTo(count.top + .01));
  } else {
    expect(label.right + 8, lessThanOrEqualTo(count.left));
    expect(label.center.dy, closeTo(count.center.dy, .01));
  }
  _expectNoUseFeature();
}

void _expectPreviewPosition(WidgetTester tester, int page) {
  expect(tester.widget<Text>(_key('preview_position')).data, '${page + 1} / 8');
  expect(
    tester.widget<IconButton>(_key('preview_previous')).onPressed == null,
    page == 0,
  );
  expect(
    tester.widget<IconButton>(_key('preview_next')).onPressed == null,
    page == 7,
  );
}

Future<void> _nextPreview(WidgetTester tester) async {
  await _reveal(tester, _key('preview_next'));
  await tester.tap(_key('preview_next'));
  await tester.pumpAndSettle();
}

Future<void> _openInfo(WidgetTester tester, {String entry = 'info'}) async {
  await _reveal(tester, _key(entry));
  await tester.tap(_key(entry));
  await tester.pumpAndSettle();
  expect(_key('info_dialog'), findsOneWidget);
}

Future<void> _closeInfo(WidgetTester tester) async {
  await tester.tap(_key('info_close'));
  await tester.pumpAndSettle();
  expect(_key('info_dialog'), findsNothing);
}

void _expectSelected(WidgetTester tester, String? selected) {
  for (final id in _offers.keys) {
    final choice = tester.widget<Semantics>(_key('${id}_selection'));
    expect(choice.properties.selected, id == selected);
    expect(choice.properties.inMutuallyExclusiveGroup, isTrue);
    expect(tester.widget<OutlinedButton>(_key(id)).onPressed, isNotNull);
  }
}

double _contrast(Color foreground, Color background) {
  final actual = Color.alphaBlend(foreground, background).computeLuminance();
  final back = background.computeLuminance();
  return (actual > back ? actual + .05 : back + .05) /
      (actual > back ? back + .05 : actual + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final priorHttp = HttpOverrides.current;
  final priorFatal = WidgetController.hitTestWarningShouldBeFatal;
  final priorFontStubs = ZyraText.useTestFontStubs;
  final priorReadingFont = ZyraText.testReadingFontFamily;
  final priorPalette = ZyraColors.devPalette;
  late _NoNetwork network;

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError(
          'Capture output must be an existing absolute directory.',
        );
      }
      var componentPath = '';
      for (final component
          in _captures.split('/').where((part) => part.isNotEmpty)) {
        if (component == '.' || component == '..') {
          throw StateError('Capture output cannot contain path aliases.');
        }
        componentPath += '/$component';
        if (FileSystemEntity.typeSync(componentPath, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError(
            'Capture output requires existing nonlinked directories.',
          );
        }
      }
    }
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
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraColors.selectDevPalette(ZyraDevPalette.midnightPlum);
    network = _NoNetwork();
    HttpOverrides.global = network;
    WidgetController.hitTestWarningShouldBeFatal = true;
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = priorHttp;
    ZyraText.useTestFontStubs = priorFontStubs;
    ZyraText.testReadingFontFamily = priorReadingFont;
    WidgetController.hitTestWarningShouldBeFatal = priorFatal;
    ZyraColors.selectDevPalette(priorPalette);
  });

  for (final size in const [
    Size(320, 852),
    Size(375, 812),
    Size(393, 852),
    Size(430, 932),
  ]) {
    testWidgets('Halo focus fits the normal phone viewport at $size', (
      tester,
    ) async {
      await _mount(tester, size: size, balance: 1, onTerms: () {});
      final title = tester.widget<Text>(_key('title'));
      expect(title.data, 'Compatibility Unlocks');
      expect(title.textAlign, TextAlign.left);
      expect(title.style!.fontFamily, _font);
      expect(_position(tester).maxScrollExtent, 0);
      expect(find.byType(FittedBox), findsNothing);
      _expectNoHorizontalOverflow(tester, size.width, scale: 1);
      _expectBalance(tester, 1);
      Rect? previous;
      for (final id in _offers.keys) {
        _expectOfferContentsContained(tester, id);
        final rect = tester.getRect(_key(id));
        expect(rect.width, greaterThanOrEqualTo(44));
        expect(rect.height, greaterThanOrEqualTo(44));
        if (previous != null) {
          expect(rect.top, closeTo(previous.top, .01));
          expect(rect.left, greaterThan(previous.right));
        }
        previous = rect;
      }
      expect(
        tester.getRect(_key('continue')).bottom,
        lessThanOrEqualTo(size.height - 34),
      );
      expect(_key('included').hitTestable(), findsOneWidget);
      expect(_key('terms').hitTestable(), findsOneWidget);
      _expectSelected(tester, null);
      _expectCheckoutHeld(tester);
      if (size.width == 320 || size.width == 393) {
        await _captureFrame(tester, 'store-${size.width.toInt()}-top');
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'compact order and catalogue are exact with benefits behind information',
    (tester) async {
      await _mount(tester, balance: 3, onTerms: () {});
      _expectBalance(tester, 3);
      for (final benefit in _benefits) {
        expect(find.text(benefit), findsNothing);
      }
      expect(find.text(_lifetime), findsNothing);
      expect(find.text(_terms), findsNothing);
      expect(find.text('£2.33 each'), findsOneWidget);
      expect(find.text('£2.00 each'), findsOneWidget);
      expect(find.text('For one profile'), findsOneWidget);
      expect(find.text('Best value'), findsNothing);
      expect(find.text('BEST VALUE'), findsNothing);
      expect(find.text('Purchase terms'), findsOneWidget);
      final order = [
        _key('title'),
        _key('balance'),
        _key('preview'),
        _key('unlock_single'),
        _key('continue'),
        _key('terms'),
        _key('unavailable'),
      ];
      for (var i = 0; i < order.length - 1; i++) {
        expect(
          tester.getRect(order[i]).bottom,
          lessThanOrEqualTo(tester.getRect(order[i + 1]).top),
        );
      }
      for (final entry in _offers.entries) {
        expect(
          find.text(ZyraMembershipCatalog.pounds(entry.value)),
          findsOneWidget,
        );
      }
      expect(find.textContaining('approach'), findsNothing);
      _expectNoUseFeature();
    },
  );

  for (final balance in <int?>[null, 0]) {
    testWidgets(
      'zero or unknown balance $balance has no invented count or use action',
      (tester) async {
        await _mount(tester, balance: balance);
        expect(_key('balance'), findsNothing);
        expect(_key('balance_label'), findsNothing);
        expect(_key('balance_count'), findsNothing);
        _expectNoUseFeature();
        _expectCheckoutHeld(tester);
      },
    );
  }

  for (final balance in [1, 3, 37]) {
    testWidgets('positive balance $balance is read-only and cannot spend', (
      tester,
    ) async {
      await _mount(tester, balance: balance);
      _expectBalance(tester, balance);
      await tester.tap(_key('balance'));
      await tester.pumpAndSettle();
      _expectBalance(tester, balance);
      expect(_key('info_dialog'), findsNothing);
      _expectCheckoutHeld(tester);
    });
  }

  testWidgets(
    'balance uses a quiet gold-outline capsule with regular app type',
    (tester) async {
      await _mount(tester, balance: 1);
      _expectBalance(tester, 1);
      final number = tester.widget<Text>(_key('balance_count'));
      expect(number.style!.fontFamily, _font);
      expect(number.style!.fontWeight, FontWeight.w400);
      expect(number.style!.fontSize, 18);
      expect(number.textAlign, TextAlign.center);
      final capsule = tester.widget<Container>(_key('balance_capsule'));
      final decoration = capsule.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.rectangle);
      expect(decoration.color, ZyraColors.modalSheetSurface);
      expect(decoration.borderRadius, BorderRadius.circular(14));
      expect(
        (decoration.border! as Border).top.color,
        ZyraColors.journeyGold.withValues(alpha: .70),
      );
      expect(
        tester.getSize(_key('balance_capsule')).width,
        greaterThanOrEqualTo(36),
      );
      expect(
        tester.getSize(_key('balance_capsule')).height,
        greaterThanOrEqualTo(32),
      );
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('full large balance remains readable at ${scale * 100}%', (
      tester,
    ) async {
      const balance = 1234567890123456789;
      await _mount(
        tester,
        size: const Size(320, 568),
        scale: scale,
        balance: balance,
      );
      _expectBalance(tester, balance);
      expect(_key('balance_stacked'), findsOneWidget);
      expect(find.byType(FittedBox), findsNothing);
      final paragraph = _paragraphForText(
        tester.element(_key('balance_count')),
      );
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 19),
      );
      expect(boxes, isNotEmpty);
      for (final box in boxes) {
        expect(box.left, greaterThanOrEqualTo(-.01));
        expect(box.right, lessThanOrEqualTo(paragraph.size.width + .01));
        expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + .01));
      }
      _expectNoHorizontalOverflow(
        tester,
        320,
        allowOffscreenOffers: true,
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }

  test('whole-percent savings are floored from integer pence', () {
    for (final offer in [
      (id: 'unlock_three', count: 3, pence: 699, percent: 22),
      (id: 'unlock_five', count: 5, pence: 999, percent: 33),
    ]) {
      final singles = offer.count * 299;
      final saving = singles - offer.pence;
      final floor = saving * 100 ~/ singles;
      expect(floor, offer.percent);
      expect(saving * 100, greaterThanOrEqualTo(floor * singles));
      expect(saving * 100, lessThan((floor + 1) * singles));
      expect(_savings[offer.id], 'Save $floor% vs singles');
    }
  });

  testWidgets(
    'all tiles only select, replacing earlier selection without checkout or callbacks',
    (tester) async {
      var terms = 0;
      await _mount(tester, balance: 2, onTerms: () => terms++);
      _expectSelected(tester, null);
      for (final id in ['unlock_three', 'unlock_five', 'unlock_single']) {
        await tester.ensureVisible(_key(id));
        await tester.pumpAndSettle();
        await tester.tap(_key(id));
        await tester.pumpAndSettle();
        _expectSelected(tester, id);
        _expectCheckoutHeld(tester, selected: id);
        expect(terms, 0);
        _expectBalance(tester, 2);
        if (id == 'unlock_five') {
          await _captureFrame(tester, 'store-five-selected');
        }
      }
      await tester.ensureVisible(_key('unlock_three'));
      await tester.pumpAndSettle();
      await tester.tap(_key('unlock_three'));
      await tester.pumpAndSettle();
      final button = tester.widget<OutlinedButton>(_key('unlock_three'));
      expect(button.style!.side!.resolve({})!.color, ZyraColors.journeyGold);
      _expectCheckoutHeld(tester, selected: 'unlock_three');
      await _captureFrame(tester, 'store-three-selected');
    },
  );

  for (final entry in ['info', 'included']) {
    testWidgets(
      '$entry opens exact benefits, permanent rule and safe refund copy',
      (tester) async {
        var terms = 0;
        await _mount(tester, balance: 1, onTerms: () => terms++);
        await _openInfo(tester, entry: entry);
        for (final benefit in _benefits) {
          expect(find.text(benefit), findsOneWidget);
        }
        expect(find.text(_lifetime), findsOneWidget);
        expect(tester.widget<Text>(_key('refund_terms')).data, _terms);
        expect(terms, 0);
        _expectNoUseFeature();
        if (entry == 'info') await _captureFrame(tester, 'store-info-dialog');
        await _closeInfo(tester);
        _expectBalance(tester, 1);
        _expectSelected(tester, null);
        _expectCheckoutHeld(tester);
      },
    );
  }

  testWidgets(
    'accessible pack names include exact price, unit and percent savings',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _mount(tester);
        for (final entry in _offers.entries) {
          final label = tester
              .getSemantics(_key('${entry.key}_selection'))
              .getSemanticsData()
              .label;
          expect(label, contains(ZyraMembershipCatalog.pounds(entry.value)));
          if (_savings.containsKey(entry.key)) {
            expect(label, contains(_savings[entry.key]!));
          } else {
            expect(label, isNot(contains('Save ')));
          }
          expect(label, isNot(contains('Save £')));
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'terms forwards only the supplied caller-guarded legal destination',
    (tester) async {
      var terms = 0;
      var callerCurrent = true;
      await _mount(
        tester,
        onTerms: () {
          if (callerCurrent) terms++;
        },
      );
      final retained = tester.widget<TextButton>(_key('terms')).onPressed!;
      callerCurrent = false;
      retained();
      expect(terms, 0);
      callerCurrent = true;
      await tester.ensureVisible(_key('terms'));
      await tester.pumpAndSettle();
      await tester.tap(_key('terms'));
      await tester.pumpAndSettle();
      expect(terms, 1);
      _expectSelected(tester, null);
      _expectCheckoutHeld(tester);
    },
  );

  testWidgets(
    'missing terms authority is disabled but safe copy remains readable',
    (tester) async {
      await _mount(tester);
      expect(tester.widget<TextButton>(_key('terms')).onPressed, isNull);
      await _openInfo(tester);
      expect(find.text(_terms), findsOneWidget);
      await _closeInfo(tester);
      _expectCheckoutHeld(tester);
    },
  );

  testWidgets('retained dialog close cannot dismiss a covered or later route', (
    tester,
  ) async {
    await _mount(tester);
    await _openInfo(tester);
    final retained = tester.widget<IconButton>(_key('info_close')).onPressed!;
    final navigator = Navigator.of(tester.element(_key('info_close')));
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Covered destination')),
      ),
    );
    await tester.pumpAndSettle();
    retained();
    await tester.pumpAndSettle();
    expect(find.text('Covered destination'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    await _closeInfo(tester);
    retained();
    await tester.pumpAndSettle();
    expect(_key('presentation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'retained tile selection is inert while covered and after disposal',
    (tester) async {
      await _mount(tester);
      final retained = tester
          .widget<OutlinedButton>(_key('unlock_three'))
          .onPressed!;
      final navigator = Navigator.of(tester.element(_key('unlock_three')));
      navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Covered destination')),
        ),
      );
      await tester.pumpAndSettle();
      retained();
      await tester.pumpAndSettle();
      expect(find.text('Covered destination'), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      _expectSelected(tester, null);
      await tester.pumpWidget(const SizedBox.shrink());
      retained();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'locked first page has no score numbers, actual reader, image blur or Guardian payload',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _mount(tester);
        final preview = tester
            .getSemantics(_key('preview_semantics'))
            .getSemanticsData();
        expect(
          preview.label,
          contains('No scores or Guardian information are loaded.'),
        );
        expect(
          find.descendant(
            of: _key('preview_locked'),
            matching: find.textContaining(RegExp(r'\d+%')),
          ),
          findsNothing,
        );
        expect(_key('halo'), findsOneWidget);
        _expectPreviewPosition(tester, 0);
        expect(find.byType(ImageFiltered), findsNothing);
        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.byType(Image), findsNothing);
        expect(
          find.byKey(const ValueKey('draft_compatibility_score_reader')),
          findsNothing,
        );
        expect(find.textContaining('Demo Guardian'), findsNothing);
        expect(
          find.byKey(const ValueKey('draft_compatibility_store_person')),
          findsNothing,
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  test(
    'preview API cannot receive values and cannot request protected data or checkout',
    () {
      final source = File(
        'lib/dev/zyra_draft_compatibility_store_presentation.dart',
      ).readAsStringSync();
      final api = source
          .split('class _ZyraDraftCompatibilityStorePresentationState')
          .first;
      final callbackFields = RegExp(
        r'final\s+VoidCallback\?\s+(\w+)\s*;',
      ).allMatches(api).map((match) => match.group(1)).toList();
      expect(callbackFields, ['onTerms']);
      expect(api, isNot(contains('onUseUnlocks')));
      expect(source, isNot(contains('overallScore')));
      expect(source, isNot(contains('fetchMyScoreFor')));
      expect(source, isNot(contains('Supabase')));
      expect(source, isNot(contains('ZyraUnlockService')));
      expect(source, isNot(contains('ZyraCompatibilityDemo')));
      expect(source, isNot(contains('ZyraCompatibilityScoreReader')));
      expect(source, isNot(contains('onContinue')));
      expect(source, isNot(contains('onPurchase')));
      expect(source, isNot(contains('personId')));
      expect(source, contains('const _fictionalScores = ['));
      expect(source, contains('PageController(keepPage: false)'));
      expect(source, contains('_pages.dispose();'));
      expect(source, isNot(contains('SharedPreferences')));
      expect(source, isNot(contains('PopScope')));
    },
  );

  for (final size in const [Size(393, 852), Size(430, 932)]) {
    testWidgets('fictional halo previews fit without vertical scroll at $size', (
      tester,
    ) async {
      await _mount(tester, size: size, balance: 1, onTerms: () {});
      _expectPreviewPosition(tester, 0);
      await _captureFrame(tester, 'store-${size.width.toInt()}-locked-preview');
      for (var index = 0; index < _examplePages.length; index++) {
        await _nextPreview(tester);
        final page = index + 1;
        _expectPreviewPosition(tester, page);
        expect(
          tester.widget<Text>(_key('example_title_$page')).data,
          _examplePages[index].$1,
        );
        expect(
          tester.widget<Text>(_key('example_score_$page')).data,
          '${_examplePages[index].$2}%',
        );
        expect(_key('example_label_$page'), findsNothing);
        expect(find.text('Example only'), findsNothing);
        expect(_position(tester).maxScrollExtent, 0);
        _expectNoHorizontalOverflow(tester, size.width, scale: 1);
        _expectBalance(tester, 1);
        _expectCheckoutHeld(tester);
        expect(_key('terms').hitTestable(), findsOneWidget);
        if (page <= 2) {
          await _captureFrame(
            tester,
            'store-${size.width.toInt()}-example-${page == 1 ? 'overall' : 'lifestyle'}',
          );
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'touch swipes stay local and never spend or change pack selection',
    (tester) async {
      var terms = 0;
      await _mount(tester, balance: 2, onTerms: () => terms++);
      await tester.tap(_key('unlock_five'));
      await tester.pumpAndSettle();
      final navigator = Navigator.of(tester.element(_key('preview_pages')));
      expect(navigator.canPop(), isFalse);
      await tester.drag(_key('preview_pages'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      _expectPreviewPosition(tester, 1);
      expect(_key('example_1').hitTestable(), findsOneWidget);
      _expectSelected(tester, 'unlock_five');
      _expectCheckoutHeld(tester, selected: 'unlock_five');
      _expectBalance(tester, 2);
      expect(terms, 0);
      expect(navigator.canPop(), isFalse);
      await tester.drag(_key('preview_pages'), const Offset(300, 0));
      await tester.pumpAndSettle();
      _expectPreviewPosition(tester, 0);
      expect(_key('included').hitTestable(), findsOneWidget);
      _expectSelected(tester, 'unlock_five');
      _expectCheckoutHeld(tester, selected: 'unlock_five');
      _expectBalance(tester, 2);
      expect(terms, 0);
    },
  );

  testWidgets(
    'every score illustration and local arrow has clear accessible labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _mount(tester);
        for (final arrow in ['preview_previous', 'preview_next']) {
          final rect = tester.getRect(_key(arrow));
          expect(rect.width, 44);
          expect(rect.height, 44);
          final widget = tester.widget<IconButton>(_key(arrow));
          expect(
            widget.tooltip,
            arrow == 'preview_previous'
                ? 'Previous preview page'
                : 'Next preview page',
          );
        }
        for (var page = 1; page <= _examplePages.length; page++) {
          await _nextPreview(tester);
          final data = tester
              .getSemantics(_key('example_$page'))
              .getSemanticsData();
          expect(data.label, contains('Score preview.'));
          expect(data.label, isNot(contains('Fictional example only.')));
          expect(data.label, contains('Not a real profile result.'));
          expect(data.label, contains(_examplePages[page - 1].$1));
          expect(
            data.label,
            contains('${_examplePages[page - 1].$2} percent aligned'),
          );
          expect(
            tester.widget<Text>(_key('preview_position')).semanticsLabel,
            contains('Score preview page ${page + 1} of 8:'),
          );
          expect(find.textContaining('Demo Guardian'), findsNothing);
          expect(find.textContaining('You and'), findsNothing);
          _expectNoUseFeature();
          _expectCheckoutHeld(tester);
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('preview arrows are inert when covered and after disposal', (
    tester,
  ) async {
    await _mount(tester);
    final retained = tester.widget<IconButton>(_key('preview_next')).onPressed!;
    final navigator = Navigator.of(tester.element(_key('preview_next')));
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Text('Covered preview destination')),
      ),
    );
    await tester.pumpAndSettle();
    retained();
    await tester.pumpAndSettle();
    expect(find.text('Covered preview destination'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    _expectPreviewPosition(tester, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    retained();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _mount(tester);
    _expectPreviewPosition(tester, 0);
  });

  testWidgets(
    '200% examples use natural height and keep the full score readable',
    (tester) async {
      await _mount(
        tester,
        size: const Size(320, 568),
        scale: 2,
        balance: 1,
        onTerms: () {},
      );
      expect(_position(tester).maxScrollExtent, greaterThan(0));
      for (var page = 1; page <= _examplePages.length; page++) {
        await _nextPreview(tester);
        _expectPreviewPosition(tester, page);
        expect(
          tester.widget<Text>(_key('example_score_$page')).maxLines,
          isNull,
        );
        expect(find.byType(FittedBox), findsNothing);
        _expectNoHorizontalOverflow(
          tester,
          320,
          allowOffscreenOffers: true,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        if (page == 3) {
          await _reveal(tester, _key('example_title_$page'));
          await _captureFrame(tester, 'store-compact200-example-work');
        }
      }
      await _reveal(tester, _key('terms'));
      expect(_key('terms').hitTestable(), findsOneWidget);
      _expectBalance(tester, 1);
      _expectCheckoutHeld(tester);
    },
  );

  testWidgets('200% locked preview measures its exact rendered leading', (
    tester,
  ) async {
    await _mount(tester, size: const Size(320, 568), scale: 2, balance: 1);
    for (final element
        in find
            .descendant(of: _key('preview_locked'), matching: find.byType(Text))
            .evaluate()) {
      final text = element.widget as Text;
      expect(text.style!.leadingDistribution, TextLeadingDistribution.even);
      expect(text.style!.textBaseline, TextBaseline.alphabetic);
      expect(
        text.style!.letterSpacing,
        text.data == 'What’s included' ? .1 : .25,
      );
      final paragraph = _paragraphForText(element);
      final measured = TextPainter(
        text: TextSpan(text: text.data, style: text.style),
        textDirection: Directionality.of(element),
        textScaler: MediaQuery.textScalerOf(element),
      )..layout(maxWidth: paragraph.constraints.maxWidth);
      expect(
        measured.height,
        closeTo(paragraph.size.height, .001),
        reason: text.data,
      );
      measured.dispose();
    }
  });

  testWidgets('320 by 568 uses an honest reachable vertical fallback', (
    tester,
  ) async {
    await _mount(
      tester,
      size: const Size(320, 568),
      balance: 1,
      onTerms: () {},
    );
    expect(_position(tester).maxScrollExtent, greaterThan(0));
    expect(find.byType(FittedBox), findsNothing);
    _expectNoHorizontalOverflow(
      tester,
      320,
      allowOffscreenOffers: true,
      scale: 1,
    );
    for (final id in _offers.keys) {
      await _reveal(tester, _key(id));
      _expectOfferContentsContained(tester, id);
      expect(_key(id).hitTestable(), findsOneWidget);
    }
    await _reveal(tester, _key('terms'));
    expect(_key('terms').hitTestable(), findsOneWidget);
    expect(tester.getRect(_key('terms')).height, greaterThanOrEqualTo(44));
    _expectCheckoutHeld(tester);
  });

  for (final scale in [1.2, 1.5, 2.0]) {
    testWidgets(
      '320px at ${scale * 100}% retains readable natural-height controls',
      (tester) async {
        await _mount(
          tester,
          size: const Size(320, 568),
          scale: scale,
          balance: 1,
          onTerms: () {},
        );
        expect(_position(tester).maxScrollExtent, greaterThan(0));
        expect(find.byType(FittedBox), findsNothing);
        _expectNoHorizontalOverflow(
          tester,
          320,
          allowOffscreenOffers: true,
          scale: scale,
        );
        final title = tester.widget<Text>(_key('title'));
        final word = TextPainter(
          text: TextSpan(text: 'Compatibility', style: title.style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(scale),
        )..layout();
        expect(
          word.width,
          lessThanOrEqualTo(tester.getRect(_key('title')).width),
        );
        word.dispose();
        for (final id in _offers.keys) {
          await tester.ensureVisible(_key(id));
          await tester.pumpAndSettle();
          _expectOfferContentsContained(tester, id);
          expect(tester.getRect(_key(id)).height, greaterThanOrEqualTo(44));
          expect(_key(id).hitTestable(), findsOneWidget);
          await tester.tap(_key(id));
          await tester.pumpAndSettle();
          _expectSelected(tester, id);
        }
        _expectCheckoutHeld(tester, selected: 'unlock_five');
        if (scale == 2) {
          _position(tester).jumpTo(0);
          await tester.pumpAndSettle();
          await _captureFrame(tester, 'store-compact200-top');
        }
        await tester.ensureVisible(_key('terms'));
        await tester.pumpAndSettle();
        expect(tester.getRect(_key('terms')).height, greaterThanOrEqualTo(44));
        expect(
          tester.getRect(_key('continue')).height,
          greaterThanOrEqualTo(44),
        );
        if (scale == 2) await _captureFrame(tester, 'store-compact200-footer');
        await _openInfo(tester, entry: 'included');
        await _reveal(tester, _key('lifetime'));
        expect(_key('lifetime').hitTestable(), findsOneWidget);
        await _reveal(tester, _key('refund_terms'));
        expect(_key('refund_terms').hitTestable(), findsOneWidget);
        expect(_key('info_close').hitTestable(), findsOneWidget);
        if (scale == 2) await _captureFrame(tester, 'store-compact200-info');
        await _closeInfo(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in const [Size(852, 393), Size(568, 320)]) {
    testWidgets('landscape $size keeps every control reachable', (
      tester,
    ) async {
      await _mount(tester, size: size, balance: 1, onTerms: () {});
      expect(_position(tester).maxScrollExtent, greaterThan(0));
      expect(find.byType(FittedBox), findsNothing);
      _expectNoHorizontalOverflow(
        tester,
        size.width,
        allowOffscreenOffers: true,
        scale: 1,
      );
      for (final id in _offers.keys) {
        await _reveal(tester, _key(id));
        _expectOfferContentsContained(tester, id);
        expect(_key(id).hitTestable(), findsOneWidget);
      }
      await _reveal(tester, _key('terms'));
      expect(_key('terms').hitTestable(), findsOneWidget);
      _expectCheckoutHeld(tester);
    });
  }

  testWidgets('unbounded Membership parent owns natural vertical scrolling', (
    tester,
  ) async {
    await _mount(
      tester,
      size: const Size(320, 568),
      scale: 1.5,
      balance: 1,
      onTerms: () {},
      membershipParent: true,
    );
    expect(_position(tester).maxScrollExtent, 0);
    final outerScrollable = find
        .descendant(
          of: find.byKey(_membershipScrollKey),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        )
        .first;
    expect(
      tester.state<ScrollableState>(outerScrollable).position.maxScrollExtent,
      greaterThan(0),
    );
    expect(find.byType(FittedBox), findsNothing);
    _expectNoHorizontalOverflow(
      tester,
      320,
      allowOffscreenOffers: true,
      scale: 1.5,
    );
    for (final id in _offers.keys) {
      await _reveal(tester, _key(id));
      _expectOfferContentsContained(tester, id);
      expect(_key(id).hitTestable(), findsOneWidget);
    }
    await _reveal(tester, _key('terms'));
    expect(_key('terms').hitTestable(), findsOneWidget);
    _expectCheckoutHeld(tester);
    await _captureFrame(tester, 'store-membership-unbounded-footer');
  });

  testWidgets('header and benefit icons use one consistent gold treatment', (
    tester,
  ) async {
    await _mount(tester);
    final header = tester.widget<Icon>(
      find.descendant(of: _key('info'), matching: find.byType(Icon)),
    );
    expect(header.color, ZyraColors.journeyGold);
    await _openInfo(tester);
    final icons = tester
        .widgetList<Icon>(find.byType(Icon))
        .where(
          (icon) => const [
            Icons.insights_outlined,
            Icons.subject_outlined,
            Icons.groups_outlined,
          ].contains(icon.icon),
        )
        .toList();
    expect(icons, hasLength(3));
    expect(icons.map((icon) => icon.color).toSet(), {ZyraColors.journeyGold});
    await _closeInfo(tester);
  });

  testWidgets(
    'opaque helper and price text exceeds AA contrast on the plum surfaces',
    (tester) async {
      await _mount(tester);
      final backgrounds = [
        ...ZyraColors.brandGradient.colors,
        const Color(0xFF30253E),
        const Color(0xFF3A2E49),
        Color.alphaBlend(ZyraColors.surfaceFill, const Color(0xFF30253E)),
        Color.alphaBlend(
          ZyraColors.journeyGold.withValues(alpha: .12),
          const Color(0xFF30253E),
        ),
      ];
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final color = text.style!.color!;
        expect(color.a, 1);
        for (final background in backgrounds) {
          expect(
            _contrast(color, background),
            greaterThanOrEqualTo(4.5),
            reason: text.data,
          );
        }
      }
    },
  );

  testWidgets('light palette keeps readable ink and consistent dark gold', (
    tester,
  ) async {
    ZyraColors.selectDevPalette(ZyraDevPalette.paperWhite);
    await _mount(tester, balance: 1, onTerms: () {});
    await _captureFrame(tester, 'store-light-top');
    await _openInfo(tester);
    final text = tester.widget<Text>(_key('lifetime'));
    for (final background in ZyraColors.brandGradient.colors) {
      expect(
        _contrast(text.style!.color!, background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(const Color(0xFF76531F), background),
        greaterThanOrEqualTo(4.5),
      );
    }
    await _captureFrame(tester, 'store-light-info');
    await _closeInfo(tester);
    await _nextPreview(tester);
    _expectPreviewPosition(tester, 1);
    final example = tester.widget<Text>(_key('example_score_1'));
    expect(example.style!.color, const Color(0xFF76531F));
    for (final background in ZyraColors.brandGradient.colors) {
      expect(
        _contrast(example.style!.color!, background),
        greaterThanOrEqualTo(4.5),
      );
    }
    await _captureFrame(tester, 'store-light-example-overall');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android names Google Play without changing the iPhone wording', (
    tester,
  ) async {
    await _mount(tester, storePlatform: TargetPlatform.android);
    expect(find.text(_androidTerms), findsNothing);
    await _openInfo(tester);
    expect(tester.widget<Text>(_key('refund_terms')).data, _androidTerms);
    expect(find.textContaining('Apple’s'), findsNothing);
    await _closeInfo(tester);
    _expectCheckoutHeld(tester);
  });

  testWidgets('reduced motion stays still and cannot begin checkout', (
    tester,
  ) async {
    await _mount(tester, reduceMotion: true);
    _expectCheckoutHeld(tester);
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byType(AnimatedSwitcher), findsNothing);
    await tester.tap(_key('preview_next'));
    await tester.pump();
    final pages = tester.widget<PageView>(_key('preview_pages')).controller!;
    expect(pages.page, 1);
    expect(pages.position.isScrollingNotifier.value, isFalse);
    await tester.pumpAndSettle();
    _expectPreviewPosition(tester, 1);
    _expectCheckoutHeld(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.binding.transientCallbackCount, 0);
  });
}
