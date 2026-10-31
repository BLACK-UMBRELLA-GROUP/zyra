import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_compatibility_demo.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _reveal = ValueKey('draft_compatibility_reveal');
const _more = ValueKey('draft_compatibility_buy_more');
const _card = ValueKey('draft_compatibility_card');
const _viewport = ValueKey('draft_compatibility_viewport');
const _reader = ValueKey('draft_compatibility_score_reader');
const _pages = ValueKey('draft_compatibility_score_pages');
const _score = ValueKey('draft_compatibility_overall_score');
const _font = 'PoppinsDraftCompatibility';

Future<void> _mount(
  WidgetTester tester, {
  int balance = 1,
  bool revealed = false,
  String name = 'Sara',
  double scale = 1,
  Size viewport = const Size(393, 852),
  bool reducedMotion = false,
  bool accessibleNavigation = false,
  bool boldText = false,
  bool settle = true,
  VoidCallback? onUnlock,
  VoidCallback? onBuyMore,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reducedMotion,
          accessibleNavigation: accessibleNavigation,
          boldText: boldText,
          padding: EdgeInsets.only(
            top: viewport.height <= 600 ? 24 : 59,
            bottom: viewport.height <= 600 ? 24 : 34,
          ),
          viewPadding: EdgeInsets.only(
            top: viewport.height <= 600 ? 24 : 59,
            bottom: viewport.height <= 600 ? 24 : 34,
          ),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: ZyraDraftCompatibilityPresentation(
                personName: name,
                balance: balance,
                overallScore: 81,
                revealed: revealed,
                onUnlock: onUnlock,
                onBuyMore: onBuyMore,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void _expectLocked(WidgetTester tester, int balance) {
  expect(find.text('Compatibility score'), findsOneWidget);
  expect(find.text('You and Sara'), findsOneWidget);
  expect(find.text('Your overall score and six areas'), findsOneWidget);
  expect(find.text('READY TO REVEAL'), findsOneWidget);
  expect(
    find.text('Faith & Values, Family, Lifestyle and more'),
    findsOneWidget,
  );
  expect(find.text('OVERALL'), findsNothing);
  expect(find.text('DETAILS'), findsNothing);
  expect(find.text('Your overall compatibility with Sara.'), findsNothing);
  expect(find.byKey(_card), findsOneWidget);
  expect(
    find.byKey(const ValueKey('draft_compatibility_locked_halo')),
    findsOneWidget,
  );
  expect(find.byKey(_reveal), findsOneWidget);
  expect(find.text('Unlock compatibility'), findsOneWidget);
  expect(find.byKey(_more), findsOneWidget);
  expect(find.byKey(_viewport), findsOneWidget);
  expect(find.byKey(_reader), findsNothing);
  expect(find.byKey(_score), findsNothing);
  expect(find.text('81%'), findsNothing);
  expect(find.text('—'), findsNothing);
  expect(find.text('__%'), findsNothing);
  expect(find.text('Demo Guardian · Father'), findsNothing);
  expect(find.text('Developer demo'), findsNothing);
  final label =
      '$balance ${balance == 1 ? 'Unlock' : 'Unlocks'} left · Get more';
  expect(
    tester
        .widget<Text>(
          find.byKey(const ValueKey('draft_compatibility_balances')),
        )
        .textSpan!
        .toPlainText(),
    label,
  );
  expect(
    tester.widget<FilledButton>(find.byKey(_reveal)).onPressed == null,
    balance == 0,
  );
  for (final category in ZyraCompatibilityDemo.categories) {
    expect(find.text(category.name), findsNothing);
  }
  expect(
    find.descendant(
      of: find.byKey(_reveal),
      matching: find.byKey(const ValueKey('draft_compatibility_balances')),
    ),
    findsNothing,
  );
  for (final key in [_reveal, _more]) {
    expect(
      find.descendant(of: find.byKey(_card), matching: find.byKey(key)),
      findsNothing,
    );
  }
}

void _expectRevealed(WidgetTester tester, {String person = 'Sara'}) {
  expect(find.text('Compatibility score'), findsOneWidget);
  expect(find.text('You and $person'), findsNothing);
  expect(find.byKey(_reader), findsOneWidget);
  expect(find.byKey(_pages), findsOneWidget);
  expect(find.byKey(_score), findsOneWidget);
  expect(find.text('81%'), findsOneWidget);
  expect(find.byKey(_card), findsNothing);
  expect(find.byKey(_viewport), findsNothing);
  expect(find.byKey(_reveal), findsNothing);
  expect(find.byKey(_more), findsNothing);
  expect(
    find.byKey(const ValueKey('draft_compatibility_balances')),
    findsNothing,
  );
  expect(find.text('OVERALL'), findsNothing);
  expect(find.text('DETAILS'), findsNothing);
  expect(find.text('—'), findsNothing);
  expect(
    find.byKey(const ValueKey('draft_compatibility_score_artwork_halo_0')),
    findsOneWidget,
  );
  expect(
    tester
        .widget<Text>(
          find.byKey(const ValueKey('draft_compatibility_score_position')),
        )
        .data,
    '1 / 7',
  );
}

void _expectInsideWidth(WidgetTester tester, double width) {
  expect(tester.takeException(), isNull);
  final card = tester.getRect(
    find.byKey(find.byKey(_reader).evaluate().isNotEmpty ? _reader : _card),
  );
  expect(card.left, greaterThanOrEqualTo(19.9));
  expect(card.right, lessThanOrEqualTo(width - 19.9));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraText.restoreAppFont(null);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final balance in [0, 1, 5]) {
    testWidgets('locked $balance-credit page has no mounted score reader', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var unlocks = 0;
      var storeVisits = 0;
      await _mount(
        tester,
        balance: balance,
        onUnlock: () => unlocks++,
        onBuyMore: () => storeVisits++,
      );
      _expectLocked(tester, balance);
      if (balance > 0) await _tap(tester, _reveal);
      await _tap(tester, _more);
      expect(unlocks, balance == 0 ? 0 : 1);
      expect(storeVisits, 1);
      _expectInsideWidth(tester, 393);
    });
  }

  testWidgets('locked Halo exposes no score or Guardian semantics', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      await _mount(tester, onUnlock: () {}, onBuyMore: () {});
      _expectLocked(tester, 1);
      expect(find.bySemanticsLabel(RegExp('81 percent|81%')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Guardian|GUARDIAN')), findsNothing);
      expect(find.byKey(_pages), findsNothing);
      expect(find.byType(PageView), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('positive balance cannot enable an absent unlock callback', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, balance: 5);
    expect(tester.widget<FilledButton>(find.byKey(_reveal)).onPressed, isNull);
    expect(tester.widget<TextButton>(find.byKey(_more)).onPressed, isNull);
    expect(find.byKey(_reader), findsNothing);
    expect(find.text('81%'), findsNothing);
  });

  for (final size in const [Size(320, 568), Size(568, 320)]) {
    testWidgets('locked Halo long name and 200% text stay reachable $size', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var unlocks = 0;
      var visits = 0;
      await _mount(
        tester,
        viewport: size,
        scale: 2,
        boldText: true,
        name: 'Sara Alexandra Ahmed with a long family name',
        onUnlock: () => unlocks++,
        onBuyMore: () => visits++,
      );
      expect(
        find.text('You and Sara Alexandra Ahmed with a long family name'),
        findsOneWidget,
      );
      _expectInsideWidth(tester, size.width);
      await _tap(tester, _reveal);
      await _tap(tester, _more);
      expect(unlocks, 1);
      expect(visits, 1);
      expect(find.byKey(_reader), findsNothing);
      expect(find.text('81%'), findsNothing);
    });
  }

  testWidgets(
    'revealed page has only the fixed Halo reader and score preview semantics',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        await _mount(tester, balance: 0, revealed: true);
        _expectRevealed(tester);
        expect(
          tester.widget<Text>(find.byKey(_score)).semanticsLabel,
          contains('Score preview: Overall with Sara'),
        );
        expect(
          tester.widget<Text>(find.byKey(_score)).semanticsLabel,
          contains('Not a real profile result.'),
        );
        expect(find.text('GUARDIAN EXAMPLE'), findsNothing);
        expect(find.text('Main Guardian · Fictional example'), findsNothing);
        expect(find.text('Main Guardian'), findsOneWidget);
        expect(find.text('Demo Guardian · Father'), findsOneWidget);
        expect(find.bySemanticsLabel('Page 1 of 7: Overall'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.byKey(
                  const ValueKey('draft_compatibility_score_previous'),
                ),
              )
              .onPressed,
          isNotNull,
        );
        _expectInsideWidth(tester, 393);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'one grant swaps locked content for reader without replay or spend',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var unlocks = 0;
      await _mount(tester, onUnlock: () => unlocks++);
      _expectLocked(tester, 1);
      await _tap(tester, _reveal);
      expect(unlocks, 1);
      await _mount(
        tester,
        balance: 0,
        revealed: true,
        onUnlock: () => unlocks++,
      );
      _expectRevealed(tester);
      await _mount(
        tester,
        balance: 5,
        revealed: true,
        onUnlock: () => unlocks++,
      );
      _expectRevealed(tester);
      expect(unlocks, 1);
      expect(find.text('Revealing'), findsNothing);
      expect(find.text('Revealed'), findsNothing);
    },
  );

  testWidgets(
    'reader navigates Overall plus six category pages by touch and swipe',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, revealed: true);
      expect(find.byKey(_pages), findsOneWidget);
      for (
        var index = 1;
        index <= ZyraCompatibilityDemo.categories.length;
        index++
      ) {
        await _tap(tester, const ValueKey('draft_compatibility_score_next'));
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey('draft_compatibility_score_position'),
                ),
              )
              .data,
          '${index + 1} / 7',
        );
        expect(
          find.byKey(ValueKey('draft_compatibility_score_title_$index')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('draft_compatibility_score_artwork_halo_$index')),
          findsOneWidget,
        );
      }
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('draft_compatibility_score_next')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.drag(find.byKey(_pages), const Offset(260, 0));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('draft_compatibility_score_position')),
            )
            .data,
        '6 / 7',
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final quiet in [false, true]) {
    testWidgets('quiet navigation jumps without a reveal animation: $quiet', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(
        tester,
        revealed: true,
        reducedMotion: quiet,
        accessibleNavigation: !quiet,
        settle: false,
      );
      _expectRevealed(tester);
      await tester.tap(
        find.byKey(const ValueKey('draft_compatibility_score_next')),
      );
      await tester.pump();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('draft_compatibility_score_position')),
            )
            .data,
        '2 / 7',
      );
      expect(find.text('Revealing'), findsNothing);
    });
  }

  testWidgets('changing the addressed person revokes the old result page', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, revealed: true, name: 'Sara');
    await _tap(tester, const ValueKey('draft_compatibility_score_next'));
    await _mount(tester, name: 'Aisha');
    expect(find.text('Compatibility score'), findsOneWidget);
    expect(find.text('You and Aisha'), findsOneWidget);
    expect(find.text('You and Sara'), findsNothing);
    expect(find.text('Your overall compatibility with Aisha.'), findsNothing);
    expect(find.text('Your overall compatibility with Sara.'), findsNothing);
    expect(find.byKey(_reader), findsNothing);
    expect(find.byKey(_score), findsNothing);
    expect(find.text('81%'), findsNothing);
    expect(find.text('Demo Guardian · Father'), findsNothing);
  });

  for (final size in const [Size(375, 812), Size(393, 852), Size(430, 932)]) {
    testWidgets('locked and Halo states stay within phone width $size', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, viewport: size, onUnlock: () {});
      _expectLocked(tester, 1);
      _expectInsideWidth(tester, size.width);
      final scroll = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(_viewport),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      expect(scroll.maxScrollExtent, closeTo(0, .5));
      await _mount(tester, viewport: size, revealed: true);
      _expectRevealed(tester);
      _expectInsideWidth(tester, size.width);
      expect(
        find.byKey(
          const ValueKey('draft_compatibility_reader_scroll_fallback'),
        ),
        findsNothing,
      );
    });
  }

  for (final reduced in [false, true]) {
    testWidgets('compact 200% Halo reader remains reachable reduced=$reduced', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(
        tester,
        viewport: const Size(320, 568),
        scale: 2,
        reducedMotion: reduced,
        revealed: true,
        name: 'Sara Alexandra Ahmed',
      );
      _expectRevealed(tester, person: 'Sara Alexandra Ahmed');
      _expectInsideWidth(tester, 320);
      final next = find.byKey(const ValueKey('draft_compatibility_score_next'));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      expect(next.hitTestable(), findsOneWidget);
      expect(tester.getSize(next).height, greaterThanOrEqualTo(44));
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('draft_compatibility_score_title_1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
