// Direct component boundary coverage; no app authority or substitute menu.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/theme/zyra_text.dart';

const _id = 'row-geometry-sara';
const _subject = ValueKey('journey-options-row-geometry');
const _host = ValueKey('journey-options-row-host');
const _font = 'PoppinsJourneyOptionsRowGeometry';
const _labels = <ZyraConceptJourneyOption, String>{
  ZyraConceptJourneyOption.profile: 'View Profile',
  ZyraConceptJourneyOption.timeline: 'Timeline',
  ZyraConceptJourneyOption.bio: 'Journey Bio',
  ZyraConceptJourneyOption.compatibility: 'Compatibility score',
  ZyraConceptJourneyOption.guardians: 'Guardians',
  ZyraConceptJourneyOption.report: 'Report',
  ZyraConceptJourneyOption.end: 'End Journey',
};

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Journey option geometry must remain offline.');
  }
}

Finder _row(ZyraConceptJourneyOption option) =>
    find.byKey(ValueKey('draft_options_${option.name}_$_id'));

Finder get _scrollHost =>
    find.byKey(const ValueKey('draft_options_inline_scroll_$_id'));

List<ZyraConceptJourneyOption> _visible({
  required bool report,
  required bool end,
}) => [
  ZyraConceptJourneyOption.profile,
  ZyraConceptJourneyOption.timeline,
  ZyraConceptJourneyOption.bio,
  ZyraConceptJourneyOption.compatibility,
  ZyraConceptJourneyOption.guardians,
  if (report) ZyraConceptJourneyOption.report,
  if (end) ZyraConceptJourneyOption.end,
];

Future<void> _mount(
  WidgetTester tester, {
  required double height,
  bool report = true,
  bool end = true,
  bool inline = true,
  double scale = 1,
  bool bold = false,
  double width = 393,
  ValueChanged<ZyraConceptJourneyOption>? selected,
}) async {
  tester.view.physicalSize = Size(width, height + 100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          boldText: bold,
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: _host,
            width: width - 40,
            height: height,
            child: ZyraConceptJourneyOptions(
              key: _subject,
              id: _id,
              firstName: 'Sara',
              inline: inline,
              canReport: report,
              canEnd: end,
              onSelected: selected ?? (_) {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectInventory(List<ZyraConceptJourneyOption> visible) {
  for (final option in _labels.keys) {
    expect(
      _row(option),
      visible.contains(option) ? findsOneWidget : findsNothing,
    );
  }
}

List<Rect> _expectRows(
  WidgetTester tester,
  List<ZyraConceptJourneyOption> visible, {
  bool bounded = false,
}) {
  _expectInventory(visible);
  final rows = <Rect>[];
  for (final option in visible) {
    final row = _row(option);
    final bounds = tester.getRect(row);
    expect(bounds.height, greaterThanOrEqualTo(55.95));
    if (rows.isNotEmpty) {
      expect(bounds.top, closeTo(rows.last.bottom, .05));
      if (bounded) expect(bounds.height, closeTo(rows.first.height, .05));
    }
    rows.add(bounds);
    final title = find.descendant(
      of: row,
      matching: find.text(_labels[option]!),
    );
    expect(title, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(title);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(paragraph.size.width, greaterThan(0));
    expect(paragraph.size.height, greaterThan(0));
    expect(tester.widget<Text>(title).style!.fontFamily, _font);
    if (!bounded) continue;
    expect(row.hitTestable(), findsOneWidget);
    final circle = find.descendant(
      of: row,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! Container || widget.decoration is! BoxDecoration) {
          return false;
        }
        final constraints = widget.constraints;
        return constraints != null &&
            constraints.minWidth == 38 &&
            constraints.maxWidth == 38 &&
            constraints.minHeight == 38 &&
            constraints.maxHeight == 38 &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle;
      }),
    );
    expect(circle, findsOneWidget);
    expect(tester.getSize(circle), const Size(38, 38));
    expect(tester.getRect(circle).center.dy, closeTo(bounds.center.dy, .6));
    final icon = find.descendant(of: circle, matching: find.byType(Icon));
    expect(icon, findsOneWidget);
    expect(tester.getRect(icon).center.dy, closeTo(bounds.center.dy, .6));
    expect(tester.getRect(title).center.dy, closeTo(bounds.center.dy, .6));
    final locked =
        option == ZyraConceptJourneyOption.bio ||
        option == ZyraConceptJourneyOption.compatibility;
    final trailingGlyph = find.descendant(
      of: row,
      matching: find.byIcon(locked ? Icons.lock_outline : Icons.chevron_right),
    );
    expect(trailingGlyph, findsOneWidget);
    expect(
      find.descendant(
        of: row,
        matching: find.byIcon(
          locked ? Icons.chevron_right : Icons.lock_outline,
        ),
      ),
      findsNothing,
    );
    expect(
      tester.getRect(trailingGlyph).center.dy,
      closeTo(bounds.center.dy, .6),
    );
  }
  if (bounded) {
    final host = tester.getRect(find.byKey(_host));
    expect(rows.first.top, closeTo(host.top, .05));
    expect(rows.last.bottom, closeTo(host.bottom, .05));
    expect(
      rows.fold<double>(0, (total, row) => total + row.height),
      closeTo(host.height, .05),
    );
  }
  expect(tester.takeException(), isNull);
  return rows;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late String? oldReading;

  setUpAll(() async {
    final font = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });

  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    oldReading = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraText.testReadingFontFamily = oldReading;
  });

  for (final report in [true, false]) {
    for (final end in [true, false]) {
      final visible = _visible(report: report, end: end);
      final threshold = visible.length * 56.0;
      final context = '${visible.length} rows, Report=$report, End=$end';

      testWidgets(
        '$context: one pixel below natural minimum scrolls without compressing rows',
        (tester) async {
          final selected = <ZyraConceptJourneyOption>[];
          await _mount(
            tester,
            height: threshold - 1,
            report: report,
            end: end,
            selected: selected.add,
          );
          _expectRows(tester, visible);
          expect(_scrollHost, findsOneWidget);
          final scroll = find.descendant(
            of: _scrollHost,
            matching: find.byType(Scrollable),
          );
          expect(scroll, findsOneWidget);
          expect(
            tester.state<ScrollableState>(scroll).position.maxScrollExtent,
            greaterThanOrEqualTo(.95),
          );
          final viewport = tester.getRect(find.byKey(_host));
          for (final option in visible) {
            final row = _row(option);
            await Scrollable.ensureVisible(tester.element(row), alignment: .5);
            await tester.pumpAndSettle();
            final bounds = tester.getRect(row);
            expect(bounds.top, greaterThanOrEqualTo(viewport.top - .05));
            expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom + .05));
            expect(row.hitTestable(), findsOneWidget);
            await tester.tap(row);
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
          expect(selected, visible);
        },
      );

      for (final spare in [0.0, 140.0]) {
        testWidgets(
          '$context: height=${threshold + spare} divides the actual centred touch cells',
          (tester) async {
            await _mount(
              tester,
              height: threshold + spare,
              report: report,
              end: end,
            );
            expect(
              _scrollHost,
              findsNothing,
              reason: 'The exact actual-row threshold is sufficient',
            );
            expect(
              find.descendant(
                of: find.byKey(_subject),
                matching: find.byType(Scrollable),
              ),
              findsNothing,
            );
            final rows = _expectRows(tester, visible, bounded: true);
            expect(
              rows.first.height,
              closeTo((threshold + spare) / visible.length, .05),
            );
          },
        );
      }
    }
  }

  testWidgets(
    'near-threshold rows measure inherited line height before dividing',
    (tester) async {
      // Deliberately use the missing production-family test fallback, whose
      // wider glyphs wrap the shorter caption at this readable-scale boundary.
      // DefaultTextStyle supplies a line height: measuring only the explicit
      // button style underestimates it. Keep that fallback assertion strict.
      ZyraText.testReadingFontFamily = null;
      await _mount(tester, height: 392, width: 353, scale: 1.3);
      expect(_scrollHost, findsOneWidget);
      final title = find.text('Compatibility score');
      final paragraph = tester.renderObject<RenderParagraph>(title);
      expect(paragraph.didExceedMaxLines, isFalse);
      for (final option in _visible(report: true, end: true)) {
        await Scrollable.ensureVisible(
          tester.element(_row(option)),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        expect(_row(option).hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('accessibility Bold Text uses natural readable rows', (
    tester,
  ) async {
    await _mount(tester, height: 500, bold: true);
    expect(_scrollHost, findsOneWidget);
    _expectRows(tester, _visible(report: true, end: true));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large text keeps natural readable rows even when the bounded height is ample',
    (tester) async {
      final visible = _visible(report: true, end: true);
      await _mount(tester, height: 700, width: 320, scale: 2);
      expect(
        _scrollHost,
        findsOneWidget,
        reason: 'Large text takes the non-flex readable fallback',
      );
      final rows = _expectRows(tester, visible);
      expect(
        rows.fold<double>(0, (total, row) => total + row.height),
        lessThan(699),
      );
      final title = find.text(_labels[ZyraConceptJourneyOption.compatibility]!);
      final paragraph = tester.renderObject<RenderParagraph>(title);
      expect(paragraph.textScaler.scale(13), 26);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        rows.any((row) => row.height > 56.5),
        isTrue,
        reason:
            'Wrapped large labels grow naturally instead of shrinking to fit',
      );
      expect(
        find.descendant(
          of: find.byKey(_subject),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      final scroll = find.descendant(
        of: _scrollHost,
        matching: find.byType(Scrollable),
      );
      expect(
        tester.state<ScrollableState>(scroll).position.maxScrollExtent,
        closeTo(0, .01),
      );
      for (final option in visible) {
        expect(_row(option).hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'legacy sheet retains natural 62px rows rather than bounded inline expansion',
    (tester) async {
      final visible = _visible(report: true, end: true);
      await _mount(tester, height: 850, width: 600, inline: false);
      _expectInventory(visible);
      expect(_scrollHost, findsNothing);
      expect(find.text('Journey options'), findsOneWidget);
      expect(find.text('Manage your Journey with Sara.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      final rows = [for (final option in visible) tester.getRect(_row(option))];
      for (var index = 0; index < rows.length; index++) {
        expect(rows[index].height, closeTo(62, .05));
        if (index > 0) {
          expect(rows[index].top, closeTo(rows[index - 1].bottom, .05));
        }
      }
      expect(
        rows.fold<double>(0, (total, row) => total + row.height),
        closeTo(visible.length * 62, .05),
      );
      expect(
        rows.last.bottom,
        lessThan(tester.getRect(find.byKey(_host)).bottom),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
