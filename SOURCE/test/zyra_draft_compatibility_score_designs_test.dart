// Display fixtures only. No SDK, service, payment, scoring or disclosure grant.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_compatibility_demo.dart';
import 'package:zyra/dev/zyra_draft_compatibility_score_designs.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

const _font = 'PoppinsCompatibilityReaderFixture';
const _names = [
  'Overall',
  'Lifestyle',
  'Work & Education',
  'Family Values',
  'Marriage Goals',
  'Personality',
  'Deen',
];
const _tuples = [
  (80, 15, 5),
  (70, 20, 10),
  (85, 10, 5),
  (90, 5, 5),
  (60, 30, 10),
  (65, 25, 10),
];
const _reader = ValueKey('draft_compatibility_score_reader');
const _pager = ValueKey('draft_compatibility_score_pages');
const _previous = ValueKey('draft_compatibility_score_previous');
const _next = ValueKey('draft_compatibility_score_next');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('The fictional score reader must remain offline.');
  }
}

Widget _app({
  double scale = 1,
  String personName = 'Sara Noor',
  int overallScore = 83,
  bool disableAnimations = true,
  bool accessibleNavigation = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      disableAnimations: disableAnimations,
      accessibleNavigation: accessibleNavigation,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: SafeArea(
      child: ZyraCompatibilityScoreReader(
        personName: personName,
        overallScore: overallScore,
      ),
    ),
  ),
);

Future<void> _mount(WidgetTester tester, {bool compact = false}) async {
  tester.view.physicalSize = compact
      ? const Size(320, 568)
      : const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(scale: compact ? 2 : 1));
  await tester.pumpAndSettle();
  expect(find.byKey(_reader), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void _expectPage(WidgetTester tester, int index) {
  expect(find.text('Swipe left or right to explore'), findsNothing);
  expect(
    tester
        .widget<Text>(
          find.byKey(const ValueKey('draft_compatibility_score_position')),
        )
        .data,
    '${index + 1} / 7',
  );
  final title = find.byKey(ValueKey('draft_compatibility_score_title_$index'));
  expect(tester.widget<Text>(title).data, _names[index]);
  final counter = tester.widget<Text>(
    find.byKey(const ValueKey('draft_compatibility_score_position')),
  );
  expect(counter.semanticsLabel, 'Page ${index + 1} of 7: ${_names[index]}');
  for (final (key, label) in [
    (_previous, 'Previous page'),
    (_next, 'Next page'),
  ]) {
    final arrow = tester.widget<IconButton>(find.byKey(key));
    expect(arrow.onPressed, isNotNull);
    expect(arrow.tooltip, label);
  }
  expect(
    find.byKey(ValueKey('draft_compatibility_score_page_$index')),
    findsOneWidget,
  );
  expect(
    tester.getSize(find.byKey(_previous)).shortestSide,
    greaterThanOrEqualTo(44),
  );
  expect(
    tester.getSize(find.byKey(_next)).shortestSide,
    greaterThanOrEqualTo(44),
  );
}

void _expectValues(int index) {
  if (index == 0) {
    final score = find.byKey(
      const ValueKey('draft_compatibility_overall_score'),
    );
    expect(score, findsOneWidget);
    expect(find.text('Demo Guardian · Father'), findsOneWidget);
    expect(find.text('Main Guardian'), findsOneWidget);
    expect(find.text('GUARDIAN EXAMPLE'), findsNothing);
    expect(find.text('Main Guardian · Fictional example'), findsNothing);
    return;
  }
  final tuple = _tuples[index - 1];
  final values = [tuple.$1, tuple.$2, tuple.$3];
  for (var metric = 0; metric < 3; metric++) {
    final label = ['aligned', 'discuss', 'opposed'][metric];
    final group = find.byKey(
      ValueKey('draft_compatibility_metric_${index}_$label'),
    );
    expect(group, findsOneWidget);
    expect(
      find.descendant(of: group, matching: find.text('${values[metric]}%')),
      findsOneWidget,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;

  setUpAll(() async {
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  test('Golden Halo uses the six original category tuples', () {
    expect(
      ZyraCompatibilityDemo.categories.map((category) => category.name),
      _names.skip(1),
    );
    expect(
      ZyraCompatibilityDemo.categories.map(
        (category) => (category.aligned, category.discuss, category.opposed),
      ),
      _tuples,
    );
  });

  testWidgets(
    'Golden Halo has seven ordered pages and unchanged fixture values',
    (tester) async {
      await _mount(tester);
      for (var index = 0; index < 7; index++) {
        _expectPage(tester, index);
        _expectValues(index);
        if (index == 0) {
          expect(
            tester
                .widget<Text>(
                  find.byKey(
                    const ValueKey('draft_compatibility_overall_score'),
                  ),
                )
                .data,
            '83%',
          );
        }
        expect(
          find.byKey(ValueKey('draft_compatibility_score_artwork_halo_$index')),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text && (widget.data?.contains('Sara Noor') ?? false),
          ),
          findsNothing,
        );
        final scoreKey = index == 0
            ? const ValueKey('draft_compatibility_overall_score')
            : ValueKey('draft_compatibility_category_score_$index');
        expect(
          tester.widget<Text>(find.byKey(scoreKey)).semanticsLabel,
          contains('with Sara Noor,'),
        );
        expect(tester.takeException(), isNull);
        if (index < 6) {
          await tester.tap(find.byKey(_next));
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();
      _expectPage(tester, 0);
      await tester.tap(find.byKey(_previous));
      await tester.pumpAndSettle();
      _expectPage(tester, 6);
    },
  );

  testWidgets(
    'Golden Halo remains vertically readable at 320x568 with 200 percent text',
    (tester) async {
      await _mount(tester, compact: true);
      for (var index = 0; index < 7; index++) {
        _expectPage(tester, index);
        _expectValues(index);
        expect(find.byType(FittedBox), findsNothing);
        final page = find.byKey(
          ValueKey('draft_compatibility_score_page_$index'),
        );
        expect(
          tester.widget<SingleChildScrollView>(page).scrollDirection,
          Axis.vertical,
        );
        await tester.drag(page, const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text('Fictional demo · not calculated from private answers.'),
          findsNothing,
        );
        if (index < 6) {
          await tester.tap(find.byKey(_next));
          await tester.pumpAndSettle();
        }
      }
    },
  );

  testWidgets('horizontal swipe changes pages without route navigation', (
    tester,
  ) async {
    await _mount(tester);
    await tester.drag(find.byKey(_pager), const Offset(-300, 0));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);
    await tester.drag(find.byKey(_pager), const Offset(300, 0));
    await tester.pumpAndSettle();
    _expectPage(tester, 0);
    expect(find.byType(ZyraCompatibilityScoreReader), findsOneWidget);
  });

  testWidgets('swipes repeatedly wrap both ends and retain the seven labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _mount(tester);
      for (var turn = 0; turn < 3; turn++) {
        await tester.drag(find.byKey(_pager), const Offset(300, 0));
        await tester.pumpAndSettle();
        _expectPage(tester, 6);
        expect(find.bySemanticsLabel('Page 7 of 7: Deen'), findsOneWidget);
        _expectValues(6);
        await tester.drag(find.byKey(_pager), const Offset(-300, 0));
        await tester.pumpAndSettle();
        _expectPage(tester, 0);
        expect(find.bySemanticsLabel('Page 1 of 7: Overall'), findsOneWidget);
        _expectValues(0);
      }
      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();
      _expectPage(tester, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'a second arrow during a wrap continues to the adjacent category',
    (tester) async {
      await _mount(tester);
      await tester.pumpWidget(_app(disableAnimations: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_previous));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(_previous));
      await tester.pumpAndSettle();
      _expectPage(tester, 5);
      for (final index in [6, 0, 1]) {
        await tester.tap(find.byKey(_next));
        await tester.pumpAndSettle();
        _expectPage(tester, index);
      }
    },
  );

  testWidgets('animated wraps travel one adjacent page in either direction', (
    tester,
  ) async {
    await _mount(tester);
    await tester.pumpWidget(_app(disableAnimations: false));
    await tester.pumpAndSettle();
    final controller = tester.widget<PageView>(find.byKey(_pager)).controller!;
    for (final (arrow, direction, destination) in [
      (_previous, -1, 6),
      (_next, 1, 0),
    ]) {
      final start = controller.page!;
      await tester.tap(find.byKey(arrow));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final travelled = (controller.page! - start) * direction;
      expect(travelled, greaterThan(0));
      expect(travelled, lessThan(1));
      await tester.pumpAndSettle();
      _expectPage(tester, destination);
    }
  });

  testWidgets(
    'accessible navigation wraps immediately and a new person resets',
    (tester) async {
      await _mount(tester);
      await tester.pumpWidget(
        _app(disableAnimations: false, accessibleNavigation: true),
      );
      await tester.tap(find.byKey(_previous));
      await tester.pump();
      _expectPage(tester, 6);
      await tester.pumpWidget(_app(personName: 'Aisha'));
      await tester.pumpAndSettle();
      _expectPage(tester, 0);
    },
  );

  testWidgets(
    'wrap arrows emit one selected haptic; swipes and Off stay silent',
    (tester) async {
      final pulses = <Object?>[];
      ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.medium);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              pulses.add(call.arguments);
            }
            return null;
          });
      addTearDown(() {
        ZyraInteractionStyle.restoreDefaults();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });
      await _mount(tester);
      await tester.tap(find.byKey(_previous));
      await tester.pumpAndSettle();
      _expectPage(tester, 6);
      expect(pulses, ['HapticFeedbackType.mediumImpact']);
      pulses.clear();
      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();
      _expectPage(tester, 0);
      expect(pulses, ['HapticFeedbackType.mediumImpact']);
      pulses.clear();
      await tester.drag(find.byKey(_pager), const Offset(300, 0));
      await tester.pumpAndSettle();
      _expectPage(tester, 6);
      expect(pulses, isEmpty);
      ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();
      _expectPage(tester, 0);
      expect(pulses, isEmpty);
    },
  );

  testWidgets('parent rebuilds preserve the currently selected category', (
    tester,
  ) async {
    await _mount(tester);
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();
    }
    _expectPage(tester, 3);
    for (var rebuild = 0; rebuild < 3; rebuild++) {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      _expectPage(tester, 3);
      _expectValues(3);
    }
  });

  testWidgets('a different person or overall value resets to Overall', (
    tester,
  ) async {
    await _mount(tester);
    await tester.tap(find.byKey(_next));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);
    await tester.pumpWidget(_app(personName: 'Aisha'));
    await tester.pumpAndSettle();
    _expectPage(tester, 0);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('draft_compatibility_overall_score')),
          )
          .semanticsLabel,
      contains('with Aisha,'),
    );
    await tester.tap(find.byKey(_next));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);
    await tester.pumpWidget(_app(personName: 'Aisha', overallScore: 100));
    await tester.pumpAndSettle();
    _expectPage(tester, 0);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('draft_compatibility_overall_score')),
          )
          .data,
      '100%',
    );
  });

  testWidgets('a fresh reveal mount starts Overall under the same route', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (_, show, _) => show
                ? const ZyraCompatibilityScoreReader(
                    personName: 'Sara',
                    overallScore: 83,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_next));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);
    visible.value = false;
    await tester.pumpAndSettle();
    visible.value = true;
    await tester.pumpAndSettle();
    _expectPage(tester, 0);
  });
}
