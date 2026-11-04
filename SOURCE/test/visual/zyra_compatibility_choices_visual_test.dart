// Review-only fixed fictional compatibility UI, never real answers or spending.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_draft_compatibility_score_designs.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _out = String.fromEnvironment('ZYRA_COMPATIBILITY_CHOICES_CAPTURE_DIR');
const _root = ValueKey('choices-capture-root');

class _NonlinearTextScaler extends TextScaler {
  const _NonlinearTextScaler();
  @override
  double scale(double fontSize) => fontSize * (fontSize > 35 ? 2.4 : 2);
  @override
  double get textScaleFactor => 2;
}

Future<void> _mount(
  WidgetTester tester, {
  bool revealed = false,
  int balance = 1,
  bool compact = false,
  Size? viewport,
  String personName = 'Sara',
  int overallScore = 76,
  bool bold = false,
  TextScaler? scaler,
}) async {
  tester.view.physicalSize =
      viewport ?? (compact ? const Size(320, 568) : const Size(393, 852));
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: scaler ?? TextScaler.linear(compact ? 2 : 1),
          boldText: bold,
          disableAnimations: true,
          padding: EdgeInsets.only(
            top: compact ? 24 : 59,
            bottom: compact ? 24 : 34,
          ),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: _root,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                        style: TextButton.styleFrom(
                          foregroundColor: ZyraColors.journeyGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ZyraDraftCompatibilityPresentation(
                        personName: personName,
                        balance: revealed ? 0 : balance,
                        overallScore: overallScore,
                        revealed: revealed,
                        onUnlock: () {},
                        onBuyMore: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.text('Compatibility score'), findsOneWidget);
  expect(
    find.text('You and $personName'),
    revealed ? findsNothing : findsOneWidget,
  );
  expect(
    find.byType(ZyraCompatibilityScoreReader),
    revealed ? findsOneWidget : findsNothing,
  );
}

Future<void> _frame(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  if (_out.isEmpty) return;
  expect(_out.startsWith('/'), isTrue);
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_root),
    );
    final picture = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_out/$name.png');
      expect(file.existsSync(), isFalse);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      picture.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('PoppinsCompatibilityChoices');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([loader.load(), icons.load()]);
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsCompatibilityChoices';
    ZyraText.restoreAppFont(null);
    ZyraColors.restoreAppPalette(null);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });
  for (final compact in [false, true]) {
    testWidgets('locked Halo compact=$compact', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, compact: compact);
      expect(
        find.byKey(const ValueKey('draft_compatibility_locked_halo')),
        findsOneWidget,
      );
      expect(find.text('OVERALL'), findsNothing);
      expect(find.text('DETAILS'), findsNothing);
      await _frame(
        tester,
        'locked_halo_${compact ? 'compact200_top' : 'phone_top'}',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('draft_compatibility_actions')),
      );
      await tester.pumpAndSettle();
      await _frame(
        tester,
        'reveal_current_${compact ? 'compact200' : 'phone'}',
      );
      if (compact) {
        await tester.ensureVisible(
          find.byKey(const ValueKey('draft_compatibility_buy_more')),
        );
        await tester.pumpAndSettle();
        await _frame(tester, 'reveal_current_compact200_bottom');
      }
    });
  }
  testWidgets('locked Halo zero-credit action remains visibly unavailable', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, balance: 0, personName: 'Aisha');
    expect(
      tester
          // LOCK 22 V6 §3, master UNITY_PASS/MASTERS/x01: the gold
          // Unlock compatibility action is filled; zero balance still disables it.
          .widget<FilledButton>(
            find.byKey(const ValueKey('draft_compatibility_reveal')),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.textContaining('0 Unlocks left', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('You and Aisha'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    await _frame(tester, 'locked_halo_zero_credits');
  });
  testWidgets('fixed Halo short landscape long name 100% bold nonlinear', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(
      tester,
      revealed: true,
      compact: true,
      viewport: const Size(568, 320),
      personName: 'A long first name needing extra space',
      overallScore: 100,
      bold: true,
      scaler: const _NonlinearTextScaler(),
    );
    expect(
      find.byKey(const ValueKey('draft_compatibility_reader_scroll_fallback')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('draft_compatibility_score_next')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final score = find.byKey(
      const ValueKey('draft_compatibility_overall_score'),
    );
    await tester.ensureVisible(score);
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: score, matching: find.byType(RichText)).first,
    );
    for (final box in paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 4),
    )) {
      expect(box.left, greaterThanOrEqualTo(-.5));
      expect(box.right, lessThanOrEqualTo(paragraph.size.width + .5));
    }
    await _frame(tester, 'score_halo_landscape100_bold_nonlinear');
  });
  for (final compact in [false, true]) {
    testWidgets('fixed Halo score compact=$compact', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, revealed: true, compact: compact);
      await _frame(tester, 'score_halo_${compact ? 'compact200' : 'overall'}');
      if (compact) {
        await tester.ensureVisible(
          find.byKey(const ValueKey('draft_compatibility_score_next')),
        );
        await tester.pumpAndSettle();
        await _frame(tester, 'score_halo_compact200_navigation');
        await tester.ensureVisible(
          find.byKey(const ValueKey('draft_compatibility_overall_score')),
        );
        await tester.pumpAndSettle();
        await _frame(tester, 'score_halo_compact200_score');
        final next = find.byKey(
          const ValueKey('draft_compatibility_score_next'),
        );
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        expect(next.hitTestable(), findsOneWidget);
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  const ValueKey('draft_compatibility_score_position'),
                ),
              )
              .data,
          '2 / 7',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('draft_compatibility_score_title_1')),
        );
        await tester.pumpAndSettle();
        await _frame(tester, 'score_halo_compact200_category');
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        await _frame(tester, 'score_halo_compact200_category_navigation');
        await tester.ensureVisible(
          find.byKey(const ValueKey('draft_compatibility_category_score_1')),
        );
        await tester.pumpAndSettle();
        await _frame(tester, 'score_halo_compact200_category_score');
        await tester.ensureVisible(
          find.byKey(const ValueKey('draft_compatibility_metric_1_opposed')),
        );
        await tester.pumpAndSettle();
        await _frame(tester, 'score_halo_compact200_category_details');
      }
      if (!compact) {
        final pager = find.byKey(
          const ValueKey('draft_compatibility_score_pages'),
        );
        await tester.drag(pager, const Offset(-280, 0));
        await tester.pumpAndSettle();
        await _frame(tester, 'score_halo_category');
      }
    });
  }
}
