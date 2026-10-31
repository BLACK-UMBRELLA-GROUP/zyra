import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/dev/zyra_one_journey_filters_presentation.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

class _Harness {
  ZyraBrowseFilter filter = const ZyraBrowseFilter();
  late StateSetter update;

  void change(ZyraBrowseFilter value) => update(() => filter = value);
}

Future<_Harness> _pump(
  WidgetTester tester, {
  Size size = const Size(430, 932),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final harness = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, set) {
            harness.update = set;
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: ZyraOneJourneyFiltersPresentation(
                filter: harness.filter,
                canAct: () => true,
                onChanged: harness.change,
                onApply: () {},
                onCountry: () =>
                    harness.change(harness.filter.withCountry('BA')),
                onOrigin: () {},
                onPreferences: () {},
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

void _choice(WidgetTester tester, String value) {
  expect(tester.widget<Text>(_key('filter_current_choice')).data, value);
}

void _placement(WidgetTester tester, {bool fromTop = false}) {
  final viewport = tester.getRect(_key('filter_viewport'));
  final content = tester.getRect(_key('filter_content'));
  final pos = Scrollable.of(tester.element(_key('filter_content'))).position;
  if (fromTop) {
    expect(content.top + pos.pixels, closeTo(viewport.top + 36, .1));
  } else if (content.height + 36 <= viewport.height) {
    expect(content.center.dy + pos.pixels, closeTo(viewport.center.dy, .1));
  } else {
    expect(content.top + pos.pixels, closeTo(viewport.top + 18, .1));
    expect(
      Scrollable.of(
        tester.element(_key('filter_content')),
      ).position.maxScrollExtent,
      greaterThan(0),
    );
  }
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets(
    'V7 monogram head uses locked ring, icon and text on every card',
    (tester) async {
      await _pump(tester);
      for (var index = 0; index < 4; index++) {
        expect(tester.getSize(_key('filter_monogram')), const Size(92, 92));
        final circle = tester.widget<Container>(_key('filter_monogram'));
        final decoration = circle.decoration! as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
        final ring = decoration.border! as Border;
        expect(ring.top.width, 1);
        expect(ring.top.color, const Color(0xffa9792e).withValues(alpha: .7));
        final icon = tester.widget<Icon>(
          find.descendant(
            of: _key('filter_monogram'),
            matching: find.byType(Icon),
          ),
        );
        expect(icon.size, 36);
        final title = tester.widget<Text>(_key('filter_title'));
        expect(title.style!.fontSize, 28);
        expect(title.style!.fontWeight, FontWeight.w300);
        final choice = tester.widget<Text>(_key('filter_current_choice'));
        expect(choice.style!.fontSize, 11);
        expect(choice.style!.letterSpacing, 1.2);
        expect(choice.style!.color, ZyraColors.goldText);
        expect(choice.textAlign, TextAlign.center);
        expect(choice.maxLines, isNull);
        if (index < 3) await _tap(tester, 'filter_next');
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('V7 Age choice follows range, slider, any age and Clear live', (
    tester,
  ) async {
    final harness = await _pump(tester);
    _choice(tester, 'ANY AGE (18+)');
    await _tap(tester, 'concept_age_1');
    _choice(tester, '18 – 70');
    tester.widget<RangeSlider>(_key('concept_age_range')).onChanged!(
      const RangeValues(24, 32),
    );
    await tester.pumpAndSettle();
    _choice(tester, '24 – 32');
    expect(harness.filter.minAge, 24);
    expect(harness.filter.maxAge, 32);
    await _tap(tester, 'concept_age_0');
    _choice(tester, 'ANY AGE (18+)');
    await _tap(tester, 'concept_age_1');
    await _tap(tester, 'concept_reset_filter_draft');
    _choice(tester, 'ANY AGE (18+)');
    expect(harness.filter.hasAgeRange, isFalse);
  });

  testWidgets(
    'V7 Location choice follows country, radius, worldwide and Clear',
    (tester) async {
      final harness = await _pump(tester);
      await _tap(tester, 'filter_next');
      _choice(tester, 'UNITED KINGDOM');
      await _tap(tester, 'concept_country');
      _choice(tester, 'BOSNIA AND HERZEGOVINA');
      await _tap(tester, 'concept_where_0');
      _choice(tester, 'WITHIN 50 KM');
      tester.widget<Slider>(_key('concept_radius')).onChanged!(9);
      await tester.pumpAndSettle();
      _choice(tester, 'WITHIN 300 KM');
      expect(harness.filter.radiusKm, 300);
      await _tap(tester, 'concept_where_2');
      _choice(tester, 'WORLDWIDE');
      await _tap(tester, 'concept_where_1');
      _choice(tester, 'BOSNIA AND HERZEGOVINA');
      await _tap(tester, 'concept_reset_filter_draft');
      _choice(tester, 'UNITED KINGDOM');
    },
  );

  for (final kind in ['Nationality', 'Ethnicity']) {
    testWidgets(
      'V7 $kind choice counts live selections through add/remove/Clear',
      (tester) async {
        final harness = await _pump(tester);
        final nationality = kind == 'Nationality';
        final index = nationality ? 2 : 3;
        for (var i = 0; i < index; i++) {
          await _tap(tester, 'filter_next');
        }
        final first = nationality ? 'GB' : 'pakistani';
        final second = nationality ? 'PK' : 'arab';
        final any = 'ANY ${kind.toUpperCase()}';
        _choice(tester, any);
        await _tap(tester, 'filter_add_${index}_$first');
        _choice(tester, '1 CHOSEN');
        await _tap(tester, 'filter_add_${index}_$second');
        _choice(tester, '2 CHOSEN');
        // The choice is a selection count; Clear still counts this as one filter.
        expect(find.text('Clear (1)'), findsOneWidget);
        expect(harness.filter.activeCount, 1);
        expect(find.text('Show profiles'), findsOneWidget);
        final memberCount = RegExp(
          r'\d+\s+(members|profiles|matches)',
          caseSensitive: false,
        );
        expect(
          tester
              .widgetList<Text>(find.byType(Text))
              .map((text) => text.data ?? ''),
          everyElement(isNot(matches(memberCount))),
        );
        await _tap(tester, 'filter_remove_${index}_$first');
        _choice(tester, '1 CHOSEN');
        await _tap(tester, 'filter_remove_${index}_$second');
        _choice(tester, any);
        await _tap(tester, 'filter_add_${index}_$first');
        await _tap(tester, 'concept_reset_filter_draft');
        _choice(tester, any);
        expect(harness.filter.activeCount, 0);
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'V7 Age/Location center and heritage starts at top at scale $scale',
      (tester) async {
        await _pump(tester, scale: scale);
        _placement(tester);
        await _tap(tester, 'concept_age_1');
        _placement(tester);
        await _tap(tester, 'filter_next');
        _placement(tester);
        await _tap(tester, 'concept_where_0');
        _placement(tester);
        await _tap(tester, 'concept_where_2');
        _placement(tester);
        await _tap(tester, 'filter_next');
        _placement(tester, fromTop: true);
        await _tap(tester, 'filter_next');
        _placement(tester, fromTop: true);
      },
    );
  }

  testWidgets(
    'V7 narrow Larger Text wraps current choice and scrolls full controls',
    (tester) async {
      await _pump(tester, size: const Size(320, 852), scale: 2);
      await _tap(tester, 'filter_next');
      await _tap(tester, 'concept_country');
      // Bring the head back into view after ensuring the lower Change control.
      await tester.ensureVisible(_key('filter_current_choice'));
      await tester.pumpAndSettle();
      _choice(tester, 'BOSNIA AND HERZEGOVINA');
      final paragraph = tester.renderObject<RenderParagraph>(
        _key('filter_current_choice'),
      );
      final lines = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 22),
      );
      expect(lines.map((box) => box.top).toSet().length, greaterThan(1));
      expect(paragraph.didExceedMaxLines, isFalse);
      final choice = tester.getRect(_key('filter_current_choice'));
      final content = tester.getRect(_key('filter_content'));
      expect(choice.left, greaterThanOrEqualTo(content.left));
      expect(choice.right, lessThanOrEqualTo(content.right));
      expect(choice.center.dx, closeTo(content.center.dx, .1));
      await _tap(tester, 'concept_where_0');
      // Reset the scroll before checking the top fallback for oversized content.
      final scrollable = find.descendant(
        of: _key('filter_scroll_1'),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable.first).position;
      position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(_key('filter_content')).height + 36,
        greaterThan(tester.getSize(_key('filter_viewport')).height),
      );
      _placement(tester);
      await tester.ensureVisible(_key('concept_radius'));
      await tester.pumpAndSettle();
      final slider = tester.getRect(_key('concept_radius'));
      final viewport = tester.getRect(_key('filter_viewport'));
      expect(slider.top, greaterThanOrEqualTo(viewport.top));
      expect(slider.bottom, lessThanOrEqualTo(viewport.bottom));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'V7 short Larger Text viewport keeps nonnegative scroll constraints',
    (tester) async {
      await _pump(tester, size: const Size(320, 600), scale: 2);
      await _tap(tester, 'filter_next');
      await _tap(tester, 'concept_country');
      _choice(tester, 'BOSNIA AND HERZEGOVINA');
      expect(tester.takeException(), isNull);
    },
  );
}
