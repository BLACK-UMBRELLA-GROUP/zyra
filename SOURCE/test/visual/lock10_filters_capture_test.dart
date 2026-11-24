import 'dart:convert';
import 'dart:io';
// Actual LOCK10 V7 local shell interactions. Insets prove layout only:
// the headless renderer cannot provide an iPhone system keyboard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/dev/zyra_one_journey_filters_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'baseline_capture_support.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const evidence = '$root/REPORTS/EVIDENCE/LOCK10_FILTERS_V7_2026-10-31';
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
        outputRoot: '$root/PRODUCT/APPROVED/FILTERS/BUILT/V7',
        evidenceRoot: evidence,
        flatOutput: true,
      );
      await h.mount(navigatorObservers: [ZyraPreviewRouteObserver()]);
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
          final geometry = <String, Object?>{
            'state': file,
            'keyboard': inset
                ? 'headless system-keyboard inset layout only'
                : 'closed',
            'logical_viewport': [430, 932],
            for (final id in [
              'filters_card',
              'filter_viewport',
              'filter_content',
              'filter_monogram',
              'filter_title',
              'filter_current_choice',
            ])
              id: (() {
                final r = t.getRect(key(id));
                return [r.left, r.top, r.width, r.height];
              })(),
            'choice': t.widget<Text>(key('filter_current_choice')).data,
          };
          await t.runAsync(() async {
            final output = File('$evidence/geometry_$file.json');
            await output.parent.create(recursive: true);
            await output.writeAsString(
              const JsonEncoder.withIndent('  ').convert(geometry),
            );
          });
          await h.capture(
            'filters',
            file,
            file,
            inset
                ? 'HEADLESS SYSTEM-KEYBOARD INSET LAYOUT ONLY; no V7 native keyboard capture or device install.'
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
      final neighbour = key('filter_scroll_1');
      final viewport = t.getRect(key('filters_card'));
      expect(neighbour, findsNothing);
      final swipe = await t.startGesture(t.getCenter(key('concept_age_1')));
      await swipe.moveBy(const Offset(-120, 0));
      await t.pump();
      expect(t.getRect(neighbour).overlaps(viewport), isTrue);
      expect(find.bySemanticsLabel('Age, filter 1 of 4'), findsOneWidget);
      expect(find.bySemanticsLabel('Location, filter 2 of 4'), findsNothing);
      expect(key('concept_age_range'), findsNothing);
      await swipe.up();
      await h.flush();
      await t.pump();
      expect(find.bySemanticsLabel('Location, filter 2 of 4'), findsOneWidget);
      await h.tap('filter_previous');
      await t.pump();
      expect(key('concept_age_range'), findsNothing);
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
      final rangeBounds = t.getRect(key('concept_age_range'));
      Future<void> dragHandle(Offset start, Offset end) async {
        final gesture = await t.startGesture(start);
        await gesture.moveBy(Offset(end.dx > start.dx ? 24 : -24, 0));
        await t.pump(const Duration(milliseconds: 16));
        await gesture.moveTo(end);
        await t.pump(const Duration(milliseconds: 16));
        await gesture.up();
        await h.flush();
      }

      await dragHandle(
        Offset(
          rangeBounds.left + rangeBounds.width * .14,
          rangeBounds.center.dy,
        ),
        Offset(rangeBounds.left - 50, rangeBounds.center.dy),
      );
      expect(
        t.widget<RangeSlider>(key('concept_age_range')).values,
        const RangeValues(18, 32),
        reason:
            'Drag the visible start thumb to the left endpoint: $rangeBounds',
      );
      await dragHandle(
        Offset(
          rangeBounds.left + rangeBounds.width * .28,
          rangeBounds.center.dy,
        ),
        Offset(rangeBounds.right + 50, rangeBounds.center.dy),
      );
      expect(find.text('18 – 70'), findsNWidgets(2));
      expect(key('concept_age_range'), findsOneWidget);
      await h.tap('concept_reset_filter_draft');
      await h.tap('filter_next');
      expect(find.bySemanticsLabel('Location, filter 2 of 4'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('United Kingdom'), findsOneWidget);
      final card = key('filters_card');
      final interrupted = await t.startGesture(t.getCenter(card));
      await interrupted.moveBy(const Offset(-120, 0));
      await t.pump();
      await interrupted.up();
      final modalContext = t.element(card);
      showDialog<void>(
        context: modalContext,
        builder: (_) => const AlertDialog(title: Text('Route interruption')),
      );
      await t.pump();
      expect(find.text('Route interruption'), findsOneWidget);
      await t.binding.handlePopRoute();
      await h.flush();
      await t.pump();
      expect(find.bySemanticsLabel('Location, filter 2 of 4'), findsOneWidget);
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
      await t.pump();
      expect(key('filter_search_ethnicity'), findsOneWidget);
      await h.tap('filter_previous');
      await t.pump();
      expect(key('filter_add_2_GB'), findsOneWidget);
      expect(key('filter_remove_2_GB'), findsNothing);
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
      await cap('f07_nationality__typing_keyboard', inset: true);
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
      await cap('f10_ethnicity__no_match_keyboard', inset: true);
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
  testWidgets('V7 actual shell Larger Text Age and Location remain reachable', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    final h = BaselineHarness(
      t,
      group: 'lock10_v7_larger_text',
      outputRoot: '$root/PRODUCT/APPROVED/FILTERS/BUILT/V7',
      evidenceRoot: evidence,
      flatOutput: true,
      textScale: 2,
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
    Future<void> capLarge(String name) async {
      if (capture) {
        await h.capture(
          'filters',
          name,
          name,
          'Actual sample shell at 200% text; scroll fallback available; headless only.',
          fileName: '$name.png',
        );
      }
    }

    await capLarge('large_age');
    await h.tap('filter_next');
    await capLarge('large_location');
    await h.tap('filter_next');
    await capLarge('large_nationality');
    await h.tap('filter_next');
    await capLarge('large_ethnicity');
  });
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
    await h.flush(auditText: false);
    expect(editor.canAct!(), isFalse);
    expect(retained.canAct!(), isFalse);
    expect(await retained.onPersist(retained.initialDraft), isFalse);
  });
  testWidgets('LOCK10 V8 Basic keeps saved One filters and opens the upgrade', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    final h = BaselineHarness(t, group: 'lock10_v8_basic');
    final model = ViewRequestDraftModel(capacity: 3);
    const saved = ZyraBrowseFilter(
      nationalityCodes: {'JP'},
      ethnicityCodes: {'somali'},
    );
    await h.mount(
      model: model,
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: model.snapshot(),
        tab: 0,
        pages: const [],
        browseFilter: saved,
      ),
    );
    expect(find.text('No profiles in this view.'), findsOneWidget);
    await h.tap('concept_edit_filters');
    h.assertPage('filters');
    final previousOwner = t.widget<ZyraOneJourneyFiltersPresentation>(
      find.byType(ZyraOneJourneyFiltersPresentation),
    );
    expect(previousOwner.allFilters, isTrue);
    expect(find.text('Clear (2)'), findsOneWidget);
    expect(h.shellFixture.setSeekerBasic(true), isTrue);
    await h.flush();
    previousOwner.onChanged(const ZyraBrowseFilter());
    await h.flush();
    expect(find.text('Clear'), findsOneWidget);
    await h.tap('concept_age_1');
    expect(key('concept_age_range'), findsOneWidget);
    await h.tap('filter_next');
    await h.tap('concept_where_2');
    expect(find.text('Members anywhere in the world.'), findsOneWidget);
    await h.tap('filter_next');
    expect(find.text('Nationality'), findsOneWidget);
    expect(find.text('SEEKER ONE'), findsOneWidget);
    expect(find.text('Comes with Seeker One'), findsOneWidget);
    expect(key('filter_search_nationality'), findsNothing);
    expect(key('filter_remove_2_JP'), findsNothing);
    await h.tap('filter-see-seeker-one');
    h.assertPage('one_upgrade');
    expect(find.text('Age and location'), findsOneWidget);
    expect(find.text('All filters'), findsOneWidget);
    await h.tapText('Not now');
    h.assertPage('filters');
    expect(find.text('Nationality'), findsOneWidget);
    await h.tap('filter_next');
    expect(find.text('Ethnicity'), findsOneWidget);
    expect(find.text('Comes with Seeker One'), findsOneWidget);
    expect(key('filter_search_ethnicity'), findsNothing);
    await h.tap('filter_previous');
    await h.tap('filter_previous');
    expect(find.text('Members anywhere in the world.'), findsOneWidget);
    await h.tap('filter_previous');
    expect(key('concept_age_range'), findsOneWidget);
    await h.tap('concept_reset_filter_draft');
    expect(find.text('Clear'), findsOneWidget);
    await h.tap('concept_apply_filter');
    expect(h.latest.pages, isEmpty);
    expect(h.latest.browseFilter.nationalityCodes, saved.nationalityCodes);
    expect(h.latest.browseFilter.ethnicityCodes, saved.ethnicityCodes);
    expect(find.text('No profiles in this view.'), findsNothing);

    expect(h.shellFixture.setSeekerBasic(false), isTrue);
    await h.flush();
    expect(find.text('No profiles in this view.'), findsOneWidget);
    await h.tap('concept_edit_filters');
    expect(find.text('Clear (2)'), findsOneWidget);
    await h.tap('filter_next');
    await h.tap('filter_next');
    expect(key('filter_search_nationality'), findsOneWidget);
    expect(key('filter_remove_2_JP'), findsOneWidget);
    await h.tap('filter_next');
    expect(key('filter_search_ethnicity'), findsOneWidget);
    expect(key('filter_remove_3_somali'), findsOneWidget);
  });

  testWidgets('LOCK10 V8 paid choices survive a warm location reset', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    final h = BaselineHarness(t, group: 'lock10_v8_warm_reset');
    final model = ViewRequestDraftModel(capacity: 1);
    const saved = ZyraBrowseFilter(
      minAge: 33,
      maxAge: 35,
      where: ZyraBrowseWhere.worldwide,
      nationalityCodes: {'JP'},
      ethnicityCodes: {'somali'},
    );
    await h.mount(
      restoreLocation: false,
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: model.snapshot(),
        tab: 4,
        pages: const ['settings'],
        seekerMembership: 'Seeker Basic',
        browseFilter: saved,
      ),
    );
    expect(h.latest.tab, 2);
    expect(h.latest.pages, isEmpty);
    final restored = h.latest.browseFilter;
    expect(restored.hasAgeRange, isFalse);
    expect(restored.where, ZyraBrowseWhere.country);
    expect(restored.nationalityCodes, saved.nationalityCodes);
    expect(restored.ethnicityCodes, saved.ethnicityCodes);
  });
}
