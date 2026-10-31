// Queue71 actual Founder routes. Outputs are isolated from the V7 handover.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _built = '$_root/PRODUCT/APPROVED/FILTERS/BUILT/V7FIX';
const _evidence = '$_root/REPORTS/EVIDENCE/QUEUE71_V7FIX_2026-10-31';
const _capture = bool.fromEnvironment('ZYRA_V7FIX_CAPTURE');
Finder _key(String value) => find.byKey(ValueKey(value));
List<double> _rect(Rect r) => [r.left, r.top, r.width, r.height];

ViewRequestDraftModel _faith() {
  final model = ViewRequestDraftModel(
    capacity: 3,
    clock: () => DateTime.utc(2026, 10, 30, 14),
  );
  expect(model.seedJourneys(2), isTrue);
  expect(model.sendSalam('draft-sara'), isTrue);
  expect(model.simulatePeerSalam('draft-sara'), isTrue);
  void advance() {
    expect(model.chooseStageContinue('draft-sara'), isTrue);
    expect(model.simulatePeerStageContinue('draft-sara'), isTrue);
    expect(model.advanceStage('draft-sara'), isTrue);
  }

  advance();
  expect(model.chooseCompatibilityReveal('draft-sara'), isTrue);
  expect(model.simulatePeerCompatibilityReveal('draft-sara'), isTrue);
  advance();
  advance();
  return model;
}

Future<void> _filters(BaselineHarness h) async {
  await h.mount();
  await h.tap('concept_browse_menu');
  await h.tester.tapAt(
    h.tester.getCenter(
      find.descendant(
        of: _key('concept_browse_options_navigation'),
        matching: _key('floating-nav-item-3'),
      ),
    ),
  );
  await h.flush();
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  setUp(() {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          zyraPhoneAccessChannel,
          (call) async => call.method == 'status'
              ? {
                  'location': 'allowed',
                  'notifications': 'allowed',
                  'photos': 'limited',
                  'camera': 'notDetermined',
                  'faceID': 'notDetermined',
                }
              : null,
        );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraPhoneAccessChannel, null),
  );

  testWidgets(
    'V7FIX actual c01/c02/c06/f01 and 200% footer',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final records = <Map<String, Object?>>[];
      BaselineHarness harness(double scale) => BaselineHarness(
        tester,
        group: 'queue71_$scale',
        outputRoot: _built,
        evidenceRoot: _evidence,
        flatOutput: true,
        textScale: scale,
      );
      Future<void> checkAndCapture(
        BaselineHarness h,
        String file,
        String action,
      ) async {
        final surface = _key('concept_request_row_surface');
        final label = find.descendant(
          of: _key(action),
          matching: find.byType(Text),
        );
        final fill = tester.widget<Material>(surface).color!;
        final ink = tester.widget<Text>(label).style!.color!;
        expect(fill, ZyraColors.surfaceFill);
        expect(ink, ZyraColors.espresso);
        final contrasts = [
          for (final bg in [ZyraColors.ivoryTop, ZyraColors.ivoryBottom])
            (Color.alphaBlend(fill, bg).computeLuminance() + .05) /
                (ink.computeLuminance() + .05),
        ];
        expect(contrasts, everyElement(greaterThanOrEqualTo(4.5)));
        final record = <String, Object?>{
          'frame': file,
          'text_scale': h.textScale,
          'pill': _rect(tester.getRect(surface)),
          'label': tester.widget<Text>(label).data,
          'fill_argb': fill.toARGB32(),
          'ink_argb': ink.toARGB32(),
          'contrast_on_ivory_endpoints': contrasts,
        };
        if (_key('filter_preferences').evaluate().isNotEmpty) {
          final link = _key('filter_preferences');
          final text = find.descendant(of: link, matching: find.byType(Text));
          final paragraph = tester.renderObject<RenderParagraph>(text);
          final intrinsic = paragraph.getMaxIntrinsicHeight(
            paragraph.size.width,
          );
          final pillTop = tester.getRect(surface).top;
          expect(paragraph.size.height, greaterThanOrEqualTo(intrinsic));
          expect(tester.getRect(text).bottom, lessThanOrEqualTo(pillTop));
          expect(tester.getRect(link).bottom, lessThanOrEqualTo(pillTop));
          record.addAll({
            'preferences_button': _rect(tester.getRect(link)),
            'preferences_text': _rect(tester.getRect(text)),
            'preferences_intrinsic_height': intrinsic,
            'full_text_bottom': tester.getRect(text).top + intrinsic,
            'overlap_pill': (tester.getRect(text).top + intrinsic - pillTop)
                .clamp(0, double.infinity),
          });
        }
        records.add(record);
        if (!_capture) return;
        final oldShadows = debugDisableShadows;
        debugDisableShadows = false;
        void repaint(RenderObject object) {
          object.markNeedsPaint();
          object.visitChildren(repaint);
        }

        try {
          repaint(tester.renderObject(_key('zyra-founder-baseline-boundary')));
          await tester.pump();
          await h.capture(
            'queue71',
            file,
            file,
            'Actual sample Founder shell; headless, bundled fonts, network blocked. '
                'Queue71 explicit normal-ink instruction supersedes gold prototype labels.',
            fileName: '$file.png',
          );
        } finally {
          debugDisableShadows = oldShadows;
        }
      }

      final h = harness(1);
      await h.mount();
      await h.tap('draft_profile_draft-sara');
      await checkAndCapture(h, 'c01_profiles', 'draft_profile_draft-sara');
      await h.mount(tab: 1, model: _faith());
      await checkAndCapture(h, 'c02_journey_tab', 'journey_tab_continue');
      await _filters(h);
      await h.tap('filter_next');
      await h.tap('concept_where_0');
      await checkAndCapture(h, 'c06_filters_where', 'concept_apply_filter');
      await _filters(h);
      await checkAndCapture(h, 'f01_age__any', 'concept_apply_filter');
      final large = harness(2);
      await _filters(large);
      await checkAndCapture(large, 'f01_age__any_200', 'concept_apply_filter');
      for (var page = 1; page < 4; page++) {
        await large.tap('filter_next');
        // Check all footer states; only the required Age frame is captured.
        final link = _key('filter_preferences');
        final text = find.descendant(of: link, matching: find.byType(Text));
        final paragraph = tester.renderObject<RenderParagraph>(text);
        final intrinsic = paragraph.getMaxIntrinsicHeight(paragraph.size.width);
        expect(paragraph.size.height, greaterThanOrEqualTo(intrinsic));
        expect(
          tester.getRect(text).top + intrinsic,
          lessThanOrEqualTo(
            tester.getRect(_key('concept_request_row_surface')).top,
          ),
        );
      }
      if (_capture) {
        await tester.runAsync(() async {
          await File(
            '$_built/GEOMETRY.json',
          ).writeAsString(const JsonEncoder.withIndent('  ').convert(records));
        });
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
