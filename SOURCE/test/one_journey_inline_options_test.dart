// Presenter-only regression coverage. The shell remains responsible for
// route authority, confirmation and any eventual Journey mutation.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _id = 'inline-sara';
const _subject = ValueKey('inline-options-under-test');
const _host = ValueKey('inline-options-bounds');
const _button = ValueKey('inline-options-button');
const _font = 'PoppinsInlineJourneyOptions';
const _rows = <ZyraConceptJourneyOption, String>{
  ZyraConceptJourneyOption.profile: 'View Profile',
  ZyraConceptJourneyOption.timeline: 'Timeline',
  ZyraConceptJourneyOption.bio: 'Journey Bio',
  ZyraConceptJourneyOption.compatibility: 'Compatibility score',
  ZyraConceptJourneyOption.guardians: 'Guardians',
  ZyraConceptJourneyOption.report: 'Report',
  ZyraConceptJourneyOption.end: 'End Journey',
};
const _archivedRows = <ZyraConceptJourneyOption, String>{
  ZyraConceptJourneyOption.profile: 'View Profile',
  ZyraConceptJourneyOption.timeline: 'Timeline',
  ZyraConceptJourneyOption.bio: 'Journey Bio',
  ZyraConceptJourneyOption.compatibility: 'Compatibility score',
  ZyraConceptJourneyOption.guardians: 'Guardians',
  ZyraConceptJourneyOption.report: 'Report',
};

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Inline Journey options must remain offline.');
  }
}

Finder _row(ZyraConceptJourneyOption option) =>
    find.byKey(ValueKey('draft_options_${option.name}_$_id'));

Widget _options({
  bool inline = true,
  bool canEnd = true,
  bool canReport = true,
  bool canViewBio = false,
  bool canViewCompatibility = false,
  bool archived = false,
  bool endedReadWindowOpen = true,
  bool canViewGuardians = true,
  ValueChanged<ZyraConceptJourneyOption>? onSelected,
  VoidCallback? onCancel,
}) => ZyraConceptJourneyOptions(
  key: _subject,
  id: _id,
  firstName: 'Sara',
  inline: inline,
  canEnd: canEnd,
  canReport: canReport,
  canViewBio: canViewBio,
  canViewCompatibility: canViewCompatibility,
  archived: archived,
  endedReadWindowOpen: endedReadWindowOpen,
  canViewGuardians: canViewGuardians,
  onSelected: onSelected ?? (_) {},
  onCancel: onCancel ?? () {},
);

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  double width = 393,
  double height = 420,
  double scale = 1,
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
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

ScrollableState _inlineScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(ValueKey('draft_options_inline_scroll_$_id')),
        matching: find.byType(Scrollable),
      ),
    );

void _expectButtonFootprint(WidgetTester tester) {
  final size = tester.getSize(find.byKey(_button));
  // Preserve the original 36px content plus the .6px border on both sides.
  expect(size.width, closeTo(37.2, .01));
  expect(size.height, closeTo(37.2, .01));
  expect(
    find.descendant(
      of: find.byKey(_button),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 36 && widget.height == 36,
      ),
    ),
    findsOneWidget,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousOverrides;
  late _NoNetwork network;
  late bool previousFontStubs;
  late String? previousReadingFont;

  setUpAll(() async {
    final loader = FontLoader(_font)
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
    await loader.load();
  });

  setUp(() {
    previousOverrides = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousFontStubs = ZyraText.useTestFontStubs;
    previousReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });

  tearDown(() {
    HttpOverrides.global = previousOverrides;
    ZyraText.useTestFontStubs = previousFontStubs;
    ZyraText.testReadingFontFamily = previousReadingFont;
    expect(network.attempts, 0);
  });

  testWidgets('inline rows keep exact IDs and delegate each action once', (
    tester,
  ) async {
    final selected = <ZyraConceptJourneyOption>[];
    var cancelled = 0;
    await _mount(
      tester,
      _options(onSelected: selected.add, onCancel: () => cancelled++),
    );
    expect(selected, isEmpty);
    expect(find.text('View archive'), findsNothing);
    expect(find.text('Check compatibility score'), findsNothing);
    expect(
      find.descendant(of: find.byKey(_subject), matching: find.byType(InkWell)),
      findsNWidgets(7),
    );
    for (final entry in _rows.entries) {
      expect(_row(entry.key), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
      await tester.tap(_row(entry.key));
      await tester.pump();
      expect(selected.last, entry.key);
    }
    expect(selected, _rows.keys.toList());
    expect(cancelled, 0);
    expect(tester.takeException(), isNull);
  });

  for (final inline in [true, false]) {
    testWidgets(
      'archived ${inline ? 'inline' : 'modal'} rows delegate six options '
      'and omit lifecycle actions',
      (tester) async {
        final selected = <ZyraConceptJourneyOption>[];
        var cancelled = 0;
        await _mount(
          tester,
          _options(
            inline: inline,
            archived: true,
            canEnd: true,
            onSelected: selected.add,
            onCancel: () => cancelled++,
          ),
          height: inline ? 420 : 680,
        );
        expect(
          find.descendant(
            of: find.byKey(_subject),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is InkWell &&
                  widget.key is ValueKey<String> &&
                  (widget.key! as ValueKey<String>).value.startsWith(
                    'draft_options_',
                  ),
            ),
          ),
          findsNWidgets(6),
        );
        expect(_row(ZyraConceptJourneyOption.end), findsNothing);
        expect(find.text('Request Pause'), findsNothing);
        expect(find.text('End Journey'), findsNothing);
        expect(
          find.text('Review your ended Journey with Sara.'),
          inline ? findsNothing : findsOneWidget,
        );
        expect(find.text('Manage your Journey with Sara.'), findsNothing);
        for (final entry in _archivedRows.entries) {
          expect(_row(entry.key), findsOneWidget);
          expect(find.text(entry.value), findsOneWidget);
          await tester.ensureVisible(_row(entry.key));
          await tester.pumpAndSettle();
          await tester.tap(_row(entry.key));
          await tester.pump();
        }
        expect(selected, _archivedRows.keys.toList());
        expect(cancelled, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('archived Report remains caller-owned', (tester) async {
    await _mount(
      tester,
      _options(archived: true, canReport: false, canEnd: true),
    );
    expect(_row(ZyraConceptJourneyOption.report), findsNothing);
    expect(_row(ZyraConceptJourneyOption.end), findsNothing);
    expect(
      find.descendant(of: find.byKey(_subject), matching: find.byType(InkWell)),
      findsNWidgets(5),
    );
  });

  for (final shared in [false, true]) {
    testWidgets('archived details respect caller grants when shared is $shared', (
      tester,
    ) async {
      final selected = <ZyraConceptJourneyOption>[];
      await _mount(
        tester,
        _options(
          archived: true,
          canViewBio: shared,
          canViewCompatibility: shared,
          onSelected: selected.add,
        ),
      );
      expect(
        find.byTooltip(
          shared
              ? 'Beyond a first impression.'
              : 'Journey Bio was not shared before this Journey ended.',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          shared
              ? 'Your revealed compatibility result for this profile.'
              : 'Journey access lasts three months. A used profile Unlock stays permanent.',
        ),
        findsOneWidget,
      );
      for (final option in [
        ZyraConceptJourneyOption.bio,
        ZyraConceptJourneyOption.compatibility,
      ]) {
        expect(
          find.byKey(ValueKey('draft_options_${option.name}_locked_$_id')),
          shared ? findsNothing : findsOneWidget,
        );
        await tester.tap(_row(option));
        await tester.pump();
      }
      // A lock explains the caller's state; the caller still owns routing.
      expect(selected, [
        ZyraConceptJourneyOption.bio,
        ZyraConceptJourneyOption.compatibility,
      ]);
      final explanations = tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .map((tooltip) => tooltip.message ?? '')
          .join(' ');
      expect(
        explanations.toLowerCase(),
        isNot(
          matches(RegExp(r'resume|reopen|complete.*together|mutual reveal')),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('explicit nonarchived options retain active rows and lock copy', (
    tester,
  ) async {
    await _mount(tester, _options(archived: false), height: 480);
    expect(find.text('View archive'), findsNothing);
    for (final entry in _rows.entries) {
      expect(_row(entry.key), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    }
    expect(find.text('Request Pause'), findsNothing);
    expect(
      find.byTooltip('Complete Journey Bio together to view it here.'),
      findsOneWidget,
    );
    expect(
      find.byTooltip(
        'Complete Compatibility Reveal together to view your result.',
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(_subject), matching: find.byType(InkWell)),
      findsNWidgets(7),
    );
  });

  testWidgets('inline has no sheet chrome, cancel or row descriptions', (
    tester,
  ) async {
    await _mount(tester, _options());
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(ZyraConceptJourneyOptions),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.type, MaterialType.transparency);
    expect(material.color, isNull);
    expect(material.borderRadius, isNull);
    expect(
      find.descendant(
        of: find.byKey(_subject),
        matching: find.byType(SafeArea),
      ),
      findsNothing,
    );
    expect(find.text('Journey options'), findsNothing);
    expect(find.text('Manage your Journey with Sara.'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Request Pause'), findsNothing);
    for (final detail in [
      'View Sara’s profile.',
      'Your shared Journey history.',
      'Beyond a first impression.',
      'Your result opens only through mutual reveal.',
      'Your circle of support for this Journey.',
      'Report a concern about this profile.',
      'Close this Journey permanently. Your Timeline stays.',
    ]) {
      expect(find.text(detail), findsNothing);
    }
    expect(
      find.descendant(of: find.byKey(_subject), matching: find.byType(Text)),
      findsNWidgets(7),
    );
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    final endLabel = tester.widget<Text>(find.text('End Journey'));
    expect(endLabel.style!.color, ZyraColors.destructive);
    final reportLabel = tester.widget<Text>(find.text('Report'));
    expect(reportLabel.style!.color, ZyraColors.foreground);
  });

  for (final width in [320.0, 393.0]) {
    testWidgets('seven inline rows fit evenly without scrolling at $width', (
      tester,
    ) async {
      await _mount(tester, _options(), width: width);
      final viewport = tester.getRect(find.byKey(_host));
      final rects = [
        for (final option in _rows.keys) tester.getRect(_row(option)),
      ];
      expect(
        find.descendant(
          of: find.byKey(_subject),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      final gaps = [
        rects.first.top - viewport.top,
        for (var index = 1; index < rects.length; index++)
          rects[index].top - rects[index - 1].bottom,
        viewport.bottom - rects.last.bottom,
      ];
      for (final gap in gaps) {
        expect(gap, closeTo(0, .01));
      }
      for (var index = 0; index < rects.length; index++) {
        final rect = rects[index];
        final entry = _rows.entries.elementAt(index);
        expect(rect.height, greaterThanOrEqualTo(56));
        expect(rect.height, closeTo(viewport.height / _rows.length, .01));
        expect(
          rect.top,
          closeTo(viewport.top + index * viewport.height / _rows.length, .01),
        );
        expect(rect.left, closeTo(viewport.left, .01));
        expect(rect.right, closeTo(viewport.right, .01));
        expect(rect.top, greaterThanOrEqualTo(viewport.top));
        expect(rect.bottom, lessThanOrEqualTo(viewport.bottom));
        final cell = tester.widget<Container>(
          find
              .descendant(of: _row(entry.key), matching: find.byType(Container))
              .first,
        );
        final decoration = cell.decoration! as BoxDecoration;
        final border = decoration.border! as Border;
        expect(border.top.width, .6);
        expect(border.top.color, ZyraColors.ink(.12));
        // The .6px top divider belongs to the cell. Its readable interior,
        // rather than a gap outside the row, centres every visible element.
        final interiorCenter = rect.center.dy + border.top.width / 2;
        final label = tester.getRect(find.text(entry.value));
        expect(label.center.dy, closeTo(interiorCenter, .01));
        expect(label.top, greaterThanOrEqualTo(rect.top));
        expect(label.bottom, lessThanOrEqualTo(rect.bottom));
        final icons = find.descendant(
          of: _row(entry.key),
          matching: find.byType(Icon),
        );
        expect(icons, findsNWidgets(2));
        for (final icon in [icons.first, icons.last]) {
          expect(tester.getRect(icon).center.dy, closeTo(interiorCenter, .01));
        }
        final locked =
            entry.key == ZyraConceptJourneyOption.bio ||
            entry.key == ZyraConceptJourneyOption.compatibility;
        expect(
          tester.widget<Icon>(icons.last).icon,
          locked ? Icons.lock_outline : Icons.chevron_right,
        );
      }
      expect(
        tester.getRect(_row(ZyraConceptJourneyOption.report)).top,
        closeTo(
          tester.getRect(_row(ZyraConceptJourneyOption.guardians)).bottom,
          .01,
        ),
      );
      expect(
        tester.getRect(_row(ZyraConceptJourneyOption.report)).bottom,
        closeTo(tester.getRect(_row(ZyraConceptJourneyOption.end)).top, .01),
      );
    });
  }

  testWidgets(
    '200 percent text uses natural scrolling without clipping actions',
    (tester) async {
      final selected = <ZyraConceptJourneyOption>[];
      await _mount(
        tester,
        _options(onSelected: selected.add),
        width: 320,
        height: 220,
        scale: 2,
      );
      expect(_inlineScroll(tester).position.maxScrollExtent, greaterThan(0));
      for (final entry in _rows.entries) {
        await tester.ensureVisible(_row(entry.key));
        await tester.pumpAndSettle();
        final row = tester.getRect(_row(entry.key));
        final text = tester.getRect(find.text(entry.value));
        expect(row.height, greaterThanOrEqualTo(48));
        expect(text.left, greaterThanOrEqualTo(row.left));
        expect(text.right, lessThanOrEqualTo(row.right));
        expect(text.top, greaterThanOrEqualTo(row.top));
        expect(text.bottom, lessThanOrEqualTo(row.bottom));
        expect(_row(entry.key).hitTestable(), findsOneWidget);
        await tester.tap(_row(entry.key));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(selected, _rows.keys.toList());
    },
  );

  testWidgets('inline can be hosted in unbounded reading space without flex', (
    tester,
  ) async {
    await _mount(tester, SingleChildScrollView(child: _options()), height: 300);
    expect(find.text('Report'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('caller flags hide optional Report and End rows', (tester) async {
    final selected = <ZyraConceptJourneyOption>[];
    await _mount(
      tester,
      _options(canEnd: false, canReport: false, onSelected: selected.add),
    );
    expect(_row(ZyraConceptJourneyOption.report), findsNothing);
    expect(_row(ZyraConceptJourneyOption.end), findsNothing);
    await tester.tap(_row(ZyraConceptJourneyOption.profile));
    await tester.pump();
    expect(selected, [ZyraConceptJourneyOption.profile]);
  });

  testWidgets('default modal preserves chrome, descriptions and cancel', (
    tester,
  ) async {
    final selected = <ZyraConceptJourneyOption>[];
    var cancelled = 0;
    await _mount(
      tester,
      ZyraConceptJourneyOptions(
        key: _subject,
        id: _id,
        firstName: 'Sara',
        canEnd: true,
        onSelected: selected.add,
        onCancel: () => cancelled++,
      ),
      height: 680,
    );
    final options = tester.widget<ZyraConceptJourneyOptions>(
      find.byKey(_subject),
    );
    expect(options.inline, isFalse);
    expect(options.archived, isFalse);
    expect(options.canReport, isTrue);
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(ZyraConceptJourneyOptions),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, ZyraColors.modalSheetSurface);
    expect(
      material.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(24)),
    );
    expect(find.text('Journey options'), findsOneWidget);
    expect(find.text('Manage your Journey with Sara.'), findsOneWidget);
    expect(find.text('Report a concern about this profile.'), findsOneWidget);
    expect(find.text('Request Pause'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.ensureVisible(_row(ZyraConceptJourneyOption.report));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(_row(ZyraConceptJourneyOption.report)).height,
      greaterThanOrEqualTo(62),
    );
    await tester.tap(_row(ZyraConceptJourneyOption.report));
    await tester.pump();
    expect(selected, [ZyraConceptJourneyOption.report]);
    expect(cancelled, 0);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(cancelled, 1);
    expect(selected, [ZyraConceptJourneyOption.report]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'expandable button keeps 36px content framing and exposes toggled state',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var expanded = false;
        var taps = 0;
        await _mount(
          tester,
          Center(
            child: StatefulBuilder(
              builder: (context, setState) => ZyraConceptJourneyOptionsButton(
                key: _button,
                isExpandable: true,
                expanded: expanded,
                onTap: () => setState(() {
                  taps++;
                  expanded = !expanded;
                }),
              ),
            ),
          ),
        );
        _expectButtonFootprint(tester);
        expect(find.byTooltip('Expand Journey options'), findsOneWidget);
        var data = tester.getSemantics(find.byKey(_button)).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isToggled, isNot(ui.Tristate.none));
        expect(data.flagsCollection.isToggled, ui.Tristate.isFalse);
        await tester.tap(find.byKey(_button));
        await tester.pumpAndSettle();
        expect(taps, 1);
        expect(find.byTooltip('Collapse Journey options'), findsOneWidget);
        data = tester.getSemantics(find.byKey(_button)).getSemanticsData();
        expect(data.flagsCollection.isToggled, ui.Tristate.isTrue);
        _expectButtonFootprint(tester);
        await tester.tap(find.byKey(_button));
        await tester.pumpAndSettle();
        expect(taps, 2);
        expect(find.byTooltip('Expand Journey options'), findsOneWidget);
        data = tester.getSemantics(find.byKey(_button)).getSemanticsData();
        expect(data.flagsCollection.isToggled, ui.Tristate.isFalse);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('default options button retains modal tooltip without toggle', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var taps = 0;
      await _mount(
        tester,
        Center(
          child: ZyraConceptJourneyOptionsButton(
            key: _button,
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.byTooltip('Journey options'), findsOneWidget);
      _expectButtonFootprint(tester);
      final data = tester.getSemantics(find.byKey(_button)).getSemanticsData();
      expect(data.flagsCollection.isToggled, ui.Tristate.none);
      final glyph = tester.widget<Icon>(find.byIcon(Icons.more_horiz));
      expect(glyph.size, 16);
      await tester.tap(find.byKey(_button));
      await tester.pump();
      expect(taps, 1);
    } finally {
      semantics.dispose();
    }
  });
}
