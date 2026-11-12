// Display fixtures only. No SDK, service, payment, scoring or disclosure grant.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_compatibility_demo.dart';
import 'package:zyra/dev/zyra_draft_compatibility_score_designs.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_compatibility_area_row.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

const _font = 'PoppinsCompatibilityReaderFixture';
const _names = ['Overall', 'Every area'];
const _areas = [
  'Deen & Islamic Practice',
  'Marriage Intentions & Structure',
  'Children & Parenting',
  'Family & In-Laws',
  'Finances & Provision',
  'Education, Career & Work',
  'Home Life & Household Roles',
  'Communication & Conflict',
  'Personality & Connection',
  'Lifestyle, Health & Well-being',
  'Digital Life, Privacy & Boundaries',
  'Culture & Language',
];
const _areaPage = ValueKey('draft_compatibility_areas');
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
  bool synthetic = true,
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
        areaBands: synthetic
            ? ZyraCompatibilityDemo.bandsFor('draft-sara')
            : null,
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
    '${index + 1} / 2',
  );
  final title = find.byKey(ValueKey('draft_compatibility_score_title_$index'));
  expect(tester.widget<Text>(title).data, _names[index]);
  final counter = tester.widget<Text>(
    find.byKey(const ValueKey('draft_compatibility_score_position')),
  );
  expect(counter.semanticsLabel, 'Page ${index + 1} of 2: ${_names[index]}');
  for (final (key, label) in [
    (_previous, 'Previous page'),
    (_next, 'Next page'),
  ]) {
    final arrow = tester.widget<IconButton>(find.byKey(key));
    expect(arrow.onPressed, isNotNull);
    expect(arrow.tooltip, label);
  }
  expect(
    find.byKey(
      index == 0
          ? const ValueKey('draft_compatibility_score_page_0')
          : _areaPage,
    ),
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
  final areas = find.byType(ZyraCompatibilityAreaRow);
  expect(areas, findsNWidgets(12));
  expect(find.textContaining('%'), findsNothing);
  expect(find.text('Demo Guardian · Father'), findsNothing);
  expect(find.text('Main Guardian'), findsNothing);
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

  testWidgets('Overall and band-only areas use the locked presentation', (
    tester,
  ) async {
    await _mount(tester);
    _expectPage(tester, 0);
    _expectValues(0);
    final score = tester.widget<Text>(
      find.byKey(const ValueKey('draft_compatibility_overall_score')),
    );
    expect(score.data, '83%');
    expect(score.semanticsLabel, contains('with Sara Noor,'));
    expect(find.text('You and Sara Noor'), findsOneWidget);
    await tester.tap(find.byKey(_next));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);
    _expectValues(1);
    final rows = tester.widgetList<ZyraCompatibilityAreaRow>(
      find.byType(ZyraCompatibilityAreaRow),
    );
    expect(rows.map((row) => row.area.label), _areas);
    expect(rows.map((row) => row.band?.label), [
      'Good',
      'Strong',
      'Good',
      'Some differences',
      'Strong',
      'Good',
      'Not enough answers',
      'Good',
      'Strong',
      'Good',
      'Strong',
      'Some differences',
    ]);
    final unavailable = find.text('Not enough answers');
    final style = tester.widget<Text>(unavailable).style;
    expect(style?.color, ZyraColors.mutedText);
    expect(style?.fontStyle, FontStyle.italic);
    expect(
      find.ancestor(
        of: unavailable,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).borderRadius != null,
        ),
      ),
      findsNothing,
    );
    await tester.tap(find.byKey(_next));
    await tester.pumpAndSettle();
    _expectPage(tester, 0);
    await tester.tap(find.byKey(_previous));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);
  });

  testWidgets('absent bands use a neutral state without a sample fallback', (
    tester,
  ) async {
    await _mount(tester);
    await tester.pumpWidget(_app(synthetic: false));
    await tester.tap(find.byKey(_next));
    await tester.pumpAndSettle();
    _expectValues(1);
    expect(find.text('Not enough answers'), findsNWidgets(12));
    expect(find.text('Strong'), findsNothing);
    expect(find.text('Good'), findsNothing);
    expect(find.text('Some differences'), findsNothing);
  });

  testWidgets(
    'Golden Halo remains vertically readable at 320x568 with 200 percent text',
    (tester) async {
      await _mount(tester, compact: true);
      for (var index = 0; index < 2; index++) {
        _expectPage(tester, index);
        _expectValues(index);
        expect(find.byType(FittedBox), findsNothing);
        final page = find.byKey(
          index == 0
              ? const ValueKey('draft_compatibility_score_page_0')
              : _areaPage,
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
        if (index == 0) {
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

  testWidgets('swipes repeatedly wrap both ends and retain both page labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _mount(tester);
      for (var turn = 0; turn < 3; turn++) {
        await tester.drag(find.byKey(_pager), const Offset(300, 0));
        await tester.pumpAndSettle();
        _expectPage(tester, 1);
        expect(
          find.bySemanticsLabel('Page 2 of 2: Every area'),
          findsOneWidget,
        );
        _expectValues(1);
        await tester.drag(find.byKey(_pager), const Offset(-300, 0));
        await tester.pumpAndSettle();
        _expectPage(tester, 0);
        expect(find.bySemanticsLabel('Page 1 of 2: Overall'), findsOneWidget);
        _expectValues(0);
      }
      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();
      _expectPage(tester, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('a second arrow during a wrap continues to the adjacent page', (
    tester,
  ) async {
    await _mount(tester);
    await tester.pumpWidget(_app(disableAnimations: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_previous));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(_previous));
    await tester.pumpAndSettle();
    _expectPage(tester, 0);
    for (final index in [1, 0, 1]) {
      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();
      _expectPage(tester, index);
    }
  });

  testWidgets('animated wraps travel one adjacent page in either direction', (
    tester,
  ) async {
    await _mount(tester);
    await tester.pumpWidget(_app(disableAnimations: false));
    await tester.pumpAndSettle();
    final controller = tester.widget<PageView>(find.byKey(_pager)).controller!;
    for (final (arrow, direction, destination) in [
      (_previous, -1, 1),
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
      _expectPage(tester, 1);
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
      _expectPage(tester, 1);
      expect(pulses, ['HapticFeedbackType.mediumImpact']);
      pulses.clear();
      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();
      _expectPage(tester, 0);
      expect(pulses, ['HapticFeedbackType.mediumImpact']);
      pulses.clear();
      await tester.drag(find.byKey(_pager), const Offset(300, 0));
      await tester.pumpAndSettle();
      _expectPage(tester, 1);
      expect(pulses, isEmpty);
      ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
      await tester.tap(find.byKey(_next));
      await tester.pumpAndSettle();
      _expectPage(tester, 0);
      expect(pulses, isEmpty);
    },
  );

  testWidgets('parent rebuilds preserve the currently selected page', (
    tester,
  ) async {
    await _mount(tester);
    await tester.tap(find.byKey(_next));
    await tester.pumpAndSettle();
    _expectPage(tester, 1);
    for (var rebuild = 0; rebuild < 3; rebuild++) {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      _expectPage(tester, 1);
      _expectValues(1);
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
