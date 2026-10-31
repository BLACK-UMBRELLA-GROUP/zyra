// LOCK14 V5 actual planned routes; asset launch projection is labelled explicitly.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_local_code_aliases.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'baseline_capture_support.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const evidence = '$root/REPORTS/EVIDENCE/LOCK14_IVORY_V5_2026-10-31';
const capture = bool.fromEnvironment('ZYRA_LOCK14_CAPTURE');
Finder k(String id) => find.byKey(ValueKey(id));
void advance(ViewRequestDraftModel m, String id) {
  expect(m.chooseStageContinue(id), isTrue);
  expect(m.simulatePeerStageContinue(id), isTrue);
  expect(m.advanceStage(id), isTrue);
}

ViewRequestDraftModel faith() {
  final m = ViewRequestDraftModel(
    capacity: 3,
    clock: () => DateTime.utc(2026, 10, 30, 14),
  );
  expect(m.seedJourneys(2), isTrue);
  expect(m.sendSalam('draft-sara'), isTrue);
  expect(m.simulatePeerSalam('draft-sara'), isTrue);
  advance(m, 'draft-sara');
  expect(m.chooseCompatibilityReveal('draft-sara'), isTrue);
  expect(m.simulatePeerCompatibilityReveal('draft-sara'), isTrue);
  advance(m, 'draft-sara');
  advance(m, 'draft-sara');
  return m;
}

BaselineHarness harness(
  WidgetTester t, {
  double scale = 1,
  bool contrast = false,
}) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(
    t,
    group: 'lock14_${scale}_$contrast',
    outputRoot: '$root/PRODUCT/APPROVED/APP_COLOURS/BUILT',
    evidenceRoot: evidence,
    flatOutput: true,
    textScale: scale,
    highContrast: contrast,
  );
}

Future<void> cap(BaselineHarness h, String name, String detail) async {
  for (final element in find.byType(Text).evaluate()) {
    final text = element.widget as Text;
    final inherited = DefaultTextStyle.of(element).style;
    final style = text.style == null ? inherited : inherited.merge(text.style);
    final size = style.fontSize ?? 14;
    final bold =
        (style.fontWeight ?? FontWeight.normal).value >= FontWeight.w700.value;
    final small = size < (bold ? 18.66 : 24);
    final colour = style.color;
    if (small && colour != null) {
      expect(
        colour.toARGB32() & 0x00ffffff,
        isNot(ZyraColors.journeyGold.toARGB32() & 0x00ffffff),
        reason:
            'LOCK14 V5 $name: small gold text "${text.data}" must use goldText.',
      );
    }
  }
  if (!capture) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  try {
    repaint(
      h.tester.renderObject(
        find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
      ),
    );
    await h.tester.pump();
    await h.capture('ivory', name, name, detail, fileName: '$name.png');
  } finally {
    debugDisableShadows = previous;
  }
}

Future<void> filters(BaselineHarness h) async {
  await h.mount();
  await h.tap('concept_browse_menu');
  await h.tester.tapAt(
    h.tester.getCenter(
      find.descendant(
        of: k('concept_browse_options_navigation'),
        matching: k('floating-nav-item-3'),
      ),
    ),
  );
  await h.flush();
}

Future<void> preference(BaselineHarness h) async {
  await filters(h);
  await h.tap('filter_preferences');
  await h.flush();
  await h.tester.scrollUntilVisible(
    k('edit-preferences-deen_practice'),
    180,
    scrollable: find.byType(Scrollable).last,
  );
  await h.flush();
  await h.tap('edit-preferences-deen_practice');
  await h.tap('edit-lights-ch3_q33');
  for (final (answer, light) in [
    ('Every prayer, every day', 'green'),
    ('Usually all five prayers', 'green'),
    ('Most days', 'yellow'),
    ('Occasionally', 'yellow'),
    ("I'm working towards praying consistently", 'red'),
  ]) {
    await h.tap('preference_${answer}_$light');
  }
  final scroll = find
      .ancestor(
        of: k('preference_option_Every prayer, every day'),
        matching: find.byType(Scrollable),
      )
      .first;
  h.tester.state<ScrollableState>(scroll).position.jumpTo(0);
  await h.flush();
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  setUp(() {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          zyraPhoneAccessChannel,
          (c) async => c.method == 'status'
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
    'LOCK14 c01-c10 and c14 actual routes and locked colour roles',
    (t) async {
      final h = harness(t);
      await h.mount();
      await h.tap('draft_profile_draft-sara');
      await cap(
        h,
        'c01_profiles',
        'Actual Sara Profiles details, sent request.',
      );
      await h.mount(tab: 1, model: faith());
      expect(find.text('Stage 4 of 8 · Faith & Values'), findsOneWidget);
      expect(find.textContaining('41 hours'), findsNothing);
      await cap(
        h,
        'c02_journey_tab',
        'Actual LOCK13 next step; c02 illustrative clock is not fabricated.',
      );
      await h.mount(tab: 2);
      await cap(
        h,
        'c03_my_zyra',
        'Actual existing My ZYRA; LOCK15 Focus is separate queue43.',
      );
      await h.mount(tab: 3);
      await cap(h, 'c04_guardian_tab', 'Actual Seeker Guardian tab.');
      await h.mount(tab: 4);
      await cap(
        h,
        'c05_profile_tab',
        'Actual Adam Profile; London home preserved.',
      );
      await h.mount();
      await h.tap('concept_browse_menu');
      await t.tapAt(
        t.getCenter(
          find.descendant(
            of: k('concept_browse_options_navigation'),
            matching: k('floating-nav-item-3'),
          ),
        ),
      );
      await h.flush();
      await h.tap('filter_next');
      await h.tap('concept_where_0');
      expect(find.text('Location'), findsOneWidget);
      expect(find.textContaining('London'), findsWidgets);
      expect(
        t.getRect(k('filters_card')),
        const Rect.fromLTWH(21, 147, 388, 648),
      );
      await cap(
        h,
        'c06_filters_where',
        'Actual LOCK10V6 Location wording/London, not old c06 Where/Manchester.',
      );
      await h.mount(tab: 2, pages: ['requests']);
      await h.tap('concept_request_draft-amira_header');
      await cap(
        h,
        'c07_requests_opened',
        'Actual opened Amira request and original actions.',
      );
      await h.mount(tab: 3);
      await h.tap('guardian-add-top');
      await t.enterText(k('local-code-field'), ZyraLocalCodeAliases.master);
      FocusManager.instance.primaryFocus?.unfocus();
      await h.flush();
      await h.tap('local-code-check');
      expect(find.text('Check code'), findsOneWidget);
      final materials = t.widgetList<Material>(
        find.descendant(
          of: k('local-code-check'),
          matching: find.byType(Material),
        ),
      );
      expect(materials.any((m) => m.color == ZyraColors.goldTextFill), isTrue);
      await cap(
        h,
        'c08_add_guardian_found',
        'Actual Code page found state; Check code and Send request gold fills.',
      );
      await h.mount(guardian: true, tab: 2);
      await cap(h, 'c09_guardian_my_zyra', 'Actual Guardian My ZYRA.');
      await h.mount(guardian: true, tab: 0);
      await cap(h, 'c10_guardian_network', 'Actual Guardian Network.');
      await preference(h);
      expect(find.text('Partner preference'), findsOneWidget);
      await cap(
        h,
        'c14_traffic_light_dots',
        'Actual retained daily-prayer editor, selected green/gold/red via real taps.',
      );
      await t.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets('LOCK14 c12 actual splash and c13 native asset projection', (
    t,
  ) async {
    final h = harness(t);
    final cp = ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: ViewRequestDraftModel(capacity: 3).snapshot(),
      tab: 0,
      pages: const [],
    );
    await h.mountPresentation(child: const SplashScreen(), checkpoint: cp);
    await t.pump(const Duration(milliseconds: 2401));
    await cap(
      h,
      'c12_splash',
      'Actual production Quiet Horizon final-frame splash; motion geometry retained.',
    );
    final launchBytes = await t.runAsync(
      () => File(
        '$root/SOURCE/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
      ).readAsBytes(),
    );
    await h.mountPresentation(
      child: ColoredBox(
        color: ZyraColors.ivoryTop,
        child: Center(
          child: Image.memory(
            launchBytes!,
            width: 200,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      ),
      checkpoint: cp,
    );
    await cap(
      h,
      'c13_iphone_launch',
      'HEADLESS ASSET PROJECTION: native launch background and centred LaunchImage at storyboard centre mode; no device/native launch attempted.',
    );
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'LOCK14 Larger Text plus Increase Contrast reachable tabs and retained pages',
    (t) async {
      final h = harness(t, scale: 1.5, contrast: true);
      for (final guardian in [false, true]) {
        for (var tab = 0; tab < 5; tab++) {
          await h.mount(
            guardian: guardian,
            tab: tab,
            model: guardian ? null : faith(),
          );
          expect(
            MediaQuery.of(t.element(find.byType(Scaffold).last)).highContrast,
            isTrue,
          );
          await cap(
            h,
            'a11y_${guardian ? 'guardian' : 'seeker'}_tab$tab',
            'Actual route at 150% Larger Text with MediaQuery Increase Contrast; no overflow exceptions.',
          );
        }
      }
      await filters(h);
      await h.tap('filter_next');
      await h.tap('concept_where_0');
      await cap(
        h,
        'a11y_filters',
        '150% Larger Text and Increase Contrast; actual Location controls remain reachable.',
      );
      await h.mount(tab: 2, pages: ['requests']);
      await h.tap('concept_request_draft-amira_header');
      await cap(
        h,
        'a11y_requests',
        '150% Larger Text and Increase Contrast; opened request actions.',
      );
      await h.mount(tab: 3);
      await h.tap('guardian-add-top');
      await t.enterText(k('local-code-field'), ZyraLocalCodeAliases.master);
      FocusManager.instance.primaryFocus?.unfocus();
      await h.flush();
      await h.tap('local-code-check');
      await cap(
        h,
        'a11y_code',
        '150% Larger Text and Increase Contrast; actual Add a Guardian found state, actions reached by scrolling.',
      );
      await h.mount(tab: 4);
      await h.tap('concept_personalisation');
      expect(k('personalisation_background'), findsNothing);
      expect(k('personalisation_gold_toggle'), findsOneWidget);
      await h.tap('personalisation_haptic');
      await h.tapText('Strong');
      expect(find.text('Strong'), findsOneWidget);
      await cap(
        h,
        'a11y_appearance',
        'Background absent; real Haptic choice and Gold accents remain.',
      );
      await h.mount(tab: 4, pages: ['settings']);
      await h.tap('concept_settings_phoneAccess');
      await cap(
        h,
        'a11y_phone_access',
        'Actual Phone access with mocked metadata only; permission lifetimes unchanged.',
      );
      await preference(h);
      await cap(
        h,
        'a11y_partner_preference',
        '150% Larger Text and Increase Contrast; all choices reached by scrolling.',
      );
      final last = k(
        "preference_option_I'm working towards praying consistently",
      );
      await Scrollable.ensureVisible(t.element(last), alignment: .5);
      await h.flush();
      expect(
        t.getRect(last).bottom,
        lessThanOrEqualTo(t.getRect(k('question-save')).top),
      );
      await cap(
        h,
        'a11y_partner_preference_last',
        'Last answer and exclusion control scroll fully clear of fixed Use this answer footer at 150% Larger Text and Increase Contrast.',
      );
      await t.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
