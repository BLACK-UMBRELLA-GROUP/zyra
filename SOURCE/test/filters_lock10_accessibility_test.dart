import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/dev/zyra_one_journey_filters_presentation.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';

Finder k(String id) => find.byKey(ValueKey(id));
void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'LOCK10 accessible controls wrap at 320 and scale $scale; haptic ownership',
      (t) async {
        t.view.physicalSize = const Size(320, 852);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final ticks = <String>[];
        var level = ZyraHapticLevel.subtle;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                ticks.add(call.arguments as String);
              }
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null),
        );
        var filter = const ZyraBrowseFilter();
        var allowed = true;
        late StateSetter update;
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, set) {
                  update = set;
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: ZyraTapFeedback(
                      level: () => level,
                      canAct: () => allowed,
                      child: ZyraOneJourneyFiltersPresentation(
                        filter: filter,
                        canAct: () => allowed,
                        onChanged: (v) => set(() => filter = v),
                        onApply: () {},
                        onCountry: () {},
                        onOrigin: () {},
                        onPreferences: () {},
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final sem = t.ensureSemantics();
        try {
          expect(find.bySemanticsLabel('Age, filter 1 of 4'), findsOneWidget);
          await t.ensureVisible(k('concept_age_1'));
          await t.tap(k('concept_age_1'));
          await t.pumpAndSettle();
          expect(ticks, hasLength(1));
          expect(filter.hasAgeRange, isTrue);
          final range = t.widget<RangeSlider>(k('concept_age_range'));
          expect(range.semanticFormatterCallback!(24), '24 years');
          await t.tap(k('filter_next'));
          await t.pumpAndSettle();
          expect(
            find.bySemanticsLabel('Location, filter 2 of 4'),
            findsOneWidget,
          );
          expect(find.text('Location'), findsOneWidget);
          await t.ensureVisible(k('concept_where_0'));
          await t.tap(k('concept_where_0'));
          await t.pumpAndSettle();
          final slider = t.widget<Slider>(k('concept_radius'));
          expect(
            slider.semanticFormatterCallback!(10),
            'Within 500 kilometres',
          );
          slider.onChanged!(10);
          await t.pumpAndSettle();
          expect(filter.radiusKm, 500);
          await t.tap(k('filter_next'));
          await t.pumpAndSettle();
          await t.enterText(k('filter_search_nationality'), 'alg');
          await t.pumpAndSettle();
          expect(find.bySemanticsLabel('Add Algerian'), findsOneWidget);
          await t.ensureVisible(k('filter_add_2_DZ'));
          await t.tap(k('filter_add_2_DZ'));
          await t.pumpAndSettle();
          expect(filter.nationalityCodes, {'DZ'});
          FocusManager.instance.primaryFocus?.unfocus();
          await t.pumpAndSettle();
          level = ZyraHapticLevel.off;
          final before = ticks.length;
          await t.tap(k('filter_next'));
          await t.pumpAndSettle();
          expect(ticks.length, before);
          expect(t.widget<InkWell>(k('filter_next')).onTap, isNull);
          final stale = t
              .widget<TextButton>(k('concept_reset_filter_draft'))
              .onPressed!;
          update(() => allowed = false);
          await t.pumpAndSettle();
          stale();
          await t.pumpAndSettle();
          expect(filter.nationalityCodes, {'DZ'});
        } finally {
          sem.dispose();
        }
      },
    );
  }
}
