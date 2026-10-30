// Actual LOCK10 V6 local shell interactions. Insets prove layout only:
// the headless renderer cannot provide an iPhone system keyboard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'baseline_capture_support.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const evidence = '$root/REPORTS/EVIDENCE/LOCK10_FILTERS_2026-10-30';
const capture = bool.fromEnvironment('ZYRA_LOCK10_CAPTURE');
Finder key(String id) => find.byKey(ValueKey(id));
void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  testWidgets(
    'LOCK10 ten states: real shell, no network, paging, controls and keyboard layout',
    (t) async {
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetViewInsets);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
      final h = BaselineHarness(
        t,
        group: 'lock10_filters',
        outputRoot: '$root/PRODUCT/APPROVED/FILTERS/BUILT',
        evidenceRoot: evidence,
        flatOutput: true,
      );
      await h.mount();
      await h.tap('concept_browse_menu');
      await t.tapAt(
        t.getCenter(
          find.descendant(
            of: key('concept_browse_options_navigation'),
            matching: key('floating-nav-item-3'),
          ),
        ),
      );
      await h.flush();
      Future<void> cap(String file, {bool inset = false}) async {
        if (capture) {
          await h.capture(
            'filters',
            file,
            file,
            inset
                ? 'HEADLESS INSET LAYOUT ONLY; native keyboard proof is separately captured from installed V4 aab4973.'
                : 'Actual sample shell; network blocked.',
            fileName: '$file.png',
          );
        }
      }

      final semantics = t.ensureSemantics();

      expect(find.bySemanticsLabel('Age, filter 1 of 4'), findsOneWidget);
      expect(t.widget<InkWell>(key('filter_previous')).onTap, isNull);
      expect(find.text('Clear'), findsOneWidget);
      expect(
        t.getRect(key('filters_card')),
        const Rect.fromLTWH(21, 147, 388, 648),
      );
      await cap('f01_age__any');
      await t.fling(key('concept_age_0'), const Offset(-230, 0), 800);
      await h.flush();
      expect(key('concept_age_1'), findsOneWidget);
      await h.tap('concept_age_1');
      t.widget<RangeSlider>(key('concept_age_range')).onChanged!(
        const RangeValues(24, 32),
      );
      await h.flush();
      expect(
        t.getRect(key('concept_age_range')).top -
            t.getRect(key('concept_age_segments')).bottom,
        26,
      );
      expect(
        h.latest.browseFilter.hasAgeRange,
        isFalse,
        reason: 'Editing is not applied to the checkpoint.',
      );
      await cap('f02_age__range');
      await h.tap('concept_reset_filter_draft');
      await h.tap('filter_next');
      expect(find.bySemanticsLabel('Location, filter 2 of 4'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('United Kingdom'), findsOneWidget);
      await cap('f03_where__country');
      await h.tap('concept_where_0');
      expect(t.widget<Slider>(key('concept_radius')).value, 4);
      expect(find.text('Within 50 km'), findsOneWidget);
      expect(
        t.getRect(key('concept_filter_origin_row')).top -
            t.getRect(key('concept_where_segments')).bottom,
        22,
      );
      expect(
        t.getRect(key('concept_radius')).top -
            t.getRect(key('concept_filter_origin_row')).bottom,
        18,
      );
      await cap('f04_where__near_me');
      await h.tap('concept_filter_origin');
      expect(find.text('Where should distance start?'), findsOneWidget);
      await h.tap('filter_origin_done');
      expect(find.text('Where should distance start?'), findsNothing);
      await t.drag(key('concept_radius'), const Offset(70, 0));
      await h.flush();
      expect(
        key('concept_radius'),
        findsOneWidget,
        reason: 'Slider drag must not page.',
      );
      await h.tap('concept_where_2');
      expect(find.text('Clear'), findsOneWidget);
      await cap('f05_where__worldwide');
      await t.fling(key('filters_card'), const Offset(-280, 0), 800);
      await h.flush();
      expect(
        find.bySemanticsLabel('Nationality, filter 3 of 4'),
        findsOneWidget,
      );
      await cap('f06_nationality__popular');
      final oldChip = t.widget<InkWell>(key('filter_add_2_GB')).onTap!;
      final oldSearch = t.widget<TextField>(key('filter_search_nationality'));
      await t.fling(key('filter_add_2_GB'), const Offset(-230, 0), 800);
      await h.flush();
      expect(key('filter_search_nationality'), findsOneWidget);
      await t.fling(
        key('filter_search_nationality'),
        const Offset(-230, 0),
        800,
      );
      await h.flush();
      expect(key('filter_search_nationality'), findsOneWidget);
      await t.enterText(key('filter_search_nationality'), 'alg');
      await h.flush();
      expect(find.text('Algerian'), findsOneWidget);
      expect(key('concept_apply_filter'), findsNothing);
      t.view.viewInsets = const FakeViewPadding(bottom: 759);
      await h.flush();
      expect(t.getRect(key('filters_card')).bottom, 669);
      await cap(
        'f07_nationality__typing_keyboard__headless_layout',
        inset: true,
      );
      await h.tap('filter_add_2_DZ');
      expect(
        t.widget<TextField>(key('filter_search_nationality')).controller!.text,
        isEmpty,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      t.view.resetViewInsets();
      await h.flush();
      await h.tap('filter_add_2_GB');
      expect(find.bySemanticsLabel('Remove Algerian'), findsOneWidget);
      expect(find.text('Clear (1)'), findsOneWidget);
      await cap('f08_nationality__chosen');
      await h.tap('filter_remove_2_GB');
      await h.tap('filter_add_2_GB');
      await t.enterText(key('filter_search_nationality'), 'dominican');
      await h.flush();
      expect(find.text('Dominican (Dominica)'), findsOneWidget);
      expect(find.text('Dominican (Dominican Republic)'), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      await h.flush();
      await h.tap('filter_next');
      expect(find.bySemanticsLabel('Ethnicity, filter 4 of 4'), findsOneWidget);
      expect(t.widget<InkWell>(key('filter_next')).onTap, isNull);
      await cap('f09_ethnicity__popular');
      oldChip();
      oldSearch.onChanged!('stale');
      oldSearch.onSubmitted!('stale');
      await h.flush();
      expect(find.text('Algerian'), findsNothing);
      expect(find.text('Clear (1)'), findsOneWidget);
      await t.fling(key('filters_card'), const Offset(-280, 0), 800);
      await h.flush();
      expect(key('filter_search_ethnicity'), findsOneWidget);
      await t.enterText(key('filter_search_ethnicity'), 'xyzq');
      await h.flush();
      expect(find.text('No ethnicity called “xyzq”.'), findsOneWidget);
      t.view.viewInsets = const FakeViewPadding(bottom: 759);
      await h.flush();
      await cap(
        'f10_ethnicity__no_match_keyboard__headless_layout',
        inset: true,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      t.view.resetViewInsets();
      await h.flush();
      await h.tap('concept_apply_filter');
      expect(h.latest.browseFilter.nationalityCodes, {'GB', 'DZ'});
      expect(h.latest.pages, isEmpty);
      oldChip();
      oldSearch.onChanged!('after disposal');
      oldSearch.onSubmitted!('after disposal');
      await h.flush();
      expect(find.text('City'), findsNothing);
      expect(find.textContaining('Best matches'), findsNothing);
      semantics.dispose();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets('Filters link opens detached traffic-light preferences', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    final h = BaselineHarness(
      t,
      group: 'lock10_preferences',
      evidenceRoot: evidence,
    );
    await h.mount();
    await h.tap('concept_browse_menu');
    await t.tapAt(
      t.getCenter(
        find.descendant(
          of: key('concept_browse_options_navigation'),
          matching: key('floating-nav-item-3'),
        ),
      ),
    );
    await h.flush();
    await h.tap('filter_preferences');
    final editor = t.widget<CompatibilityEditorScreen>(
      find.byType(CompatibilityEditorScreen),
    );
    expect(editor.kind, CompatibilityEditorKind.trafficLights);
    expect(editor.canAct!(), isTrue);
    expect(h.latest.pages.last, 'filter_preferences');
    await h.tap('compatibility-save');
    expect(key('filters_card'), findsOneWidget);
    expect(h.latest.pages.last, 'filters');
    await h.tap('filter_preferences');
    final retained = t.widget<CompatibilityEditorScreen>(
      find.byType(CompatibilityEditorScreen),
    );
    await t.pumpWidget(const SizedBox.shrink());
    await h.flush();
    expect(editor.canAct!(), isFalse);
    expect(retained.canAct!(), isFalse);
    expect(await retained.onPersist(retained.initialDraft), isFalse);
  });
}
