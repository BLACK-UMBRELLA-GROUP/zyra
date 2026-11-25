// Focused LOCK 45 route checks and four-master captures of actual presenters.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/onboarding/bio_onboarding_flow.dart';
import 'package:zyra/screens/onboarding/traffic_light_question_screen.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_edit_profile_presentation.dart';
import 'package:zyra/widgets/zyra_photo_rules_card.dart';

import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _root = 'build/line139';
const _capture = bool.fromEnvironment('ZYRA_LINE139_CAPTURE');
final _captureFailures = <String, Object>{};
Finder _key(String id) => find.byKey(ValueKey(id));

BaselineHarness _harness(
  WidgetTester tester,
  String name, {
  Size size = const Size(430, 932),
  double scale = 1,
}) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'line139_$name',
    outputRoot: '$_root/screens',
    evidenceRoot: '$_root/screens',
    flatOutput: true,
    logicalSize: size,
    textScale: scale,
    safePadding: size.width == 375
        ? const EdgeInsets.only(top: 20)
        : const EdgeInsets.only(top: 59, bottom: 34),
  );
}

Future<void> _reveal(BaselineHarness h, String id) async {
  final scroll = find
      .descendant(
        of: _key('edit_profile_content_scroll'),
        matching: find.byType(Scrollable),
      )
      .first;
  await h.tester.scrollUntilVisible(_key(id), 180, scrollable: scroll);
  await Scrollable.ensureVisible(h.tester.element(_key(id)), alignment: .5);
  await h.flush();
}

Future<void> _back(BaselineHarness h) async {
  await h.tester.binding.handlePopRoute();
  await h.flush();
}

Future<void> _open(BaselineHarness h, String id) async {
  await _reveal(h, id);
  await h.tap(id);
}

Future<void> _done(BaselineHarness h) async {
  h.tester.testTextInput.hide();
  await h.flush();
  expect(
    h.tester.widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview)).canAct(),
    isTrue,
  );
  await h.tap('signup_continue');
  await h.tester.pumpAndSettle();
  h.assertPage('edit_profile');
  expect(find.byType(ZyraSignupPreview), findsNothing);
}

void _repaint(RenderObject object) {
  object.visitChildren(_repaint);
  object.markNeedsPaint();
}

Future<void> _checkAndCapture(BaselineHarness h, String name) async {
  final previous = debugDisableShadows;
  try {
    debugDisableShadows = false;
    await h.tester.pump(const Duration(milliseconds: 2600));
    await h.prepareRasterFrame();
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      _key('zyra-founder-baseline-boundary'),
    );
    _repaint(boundary);
    await h.tester.pump();
    final result = await auditZyraRenderedText(h.tester, boundary);
    // The audit can paint its own raster separately. Repaint the real tree
    // again with shadows enabled before saving the actual comparison PNG.
    _repaint(boundary);
    await h.tester.pump();
    expect(debugDisableShadows, isFalse);
    await h.capture(
      'edit_profile',
      name,
      'lock45',
      name,
      fileName: '$name.png',
    );
    await h.tester.runAsync(() async {
      final saved = File('$_root/screens/$name.png');
      final bytes = await saved.readAsBytes();
      final record = File('$_root/audit/$name.json');
      await record.parent.create(recursive: true);
      await record.writeAsString(
        jsonEncode({
          'audit': result.toJson(),
          'savedPng': saved.path,
          'sha256': sha256.convert(bytes).toString(),
          'realShadows': true,
          'repaintBeforeAudit': true,
          'repaintAfterAuditBeforeSave': true,
          'logicalWidth': h.logicalSize.width,
          'logicalHeight': h.logicalSize.height,
          'textScale': h.textScale,
        }),
      );
    });
    if (result.failures.isNotEmpty) _captureFailures[name] = result.toJson();
  } finally {
    debugDisableShadows = previous;
  }
}

void main() {
  late ZyraOneJourneySamplePhotos photos;
  setUpAll(() async {
    await baselineSetUp(evidenceRoot: null);
    photos = await ZyraOneJourneySamplePhotos.load();
  });
  tearDownAll(baselineTearDown);

  testWidgets('LOCK45 every editable row routes, saves and returns', (
    tester,
  ) async {
    final h = _harness(tester, 'rows');
    await h.mount(
      tab: 4,
      seekerPhotos: [photos.seekerPhoto, photos.seekerPhoto],
    );
    await h.tap('concept_edit_profile');
    h.assertPage('edit_profile');
    expect(find.byType(ZyraPhotoRulesCard), findsOneWidget);
    for (final retired in [
      'Green / Yellow / Red',
      'Hard requirements',
      'Lifestyle',
      'Brother',
      'Sister',
    ]) {
      expect(find.textContaining(retired), findsNothing);
    }

    final initial = tester.widget<ZyraEditProfilePresentation>(
      find.byType(ZyraEditProfilePresentation),
    );
    await _open(h, 'edit_profile_photos');
    h.assertPage('manage_photos');
    expect(find.byType(EditPhotosScreen), findsOneWidget);
    await tester.drag(_key('photo-large-0'), const Offset(0, -100));
    await h.flush();
    await h.tap('remove-photo-0');
    await h.tapText('Remove photo');
    await _back(h);
    h.assertPage('edit_profile');
    final afterPhotos = tester.widget<ZyraEditProfilePresentation>(
      find.byType(ZyraEditProfilePresentation),
    );
    expect(afterPhotos.photoCount, initial.photoCount - 1);

    await _open(h, 'edit_profile_about');
    expect(
      tester
          .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
          .controller
          .step,
      ZyraSignupStep.aboutYou,
    );
    await tester.enterText(
      _key('signup_about_you'),
      'A peaceful home and time with family.',
    );
    await _done(h);
    expect(
      tester
          .widget<ZyraEditProfilePresentation>(
            find.byType(ZyraEditProfilePresentation),
          )
          .about,
      'A peaceful home and time with family.',
    );

    for (final row in [
      ('edit_profile_location', ZyraSignupStep.location, 'Manchester'),
      ('edit_profile_nationality', ZyraSignupStep.nationality, 'Indian'),
      ('edit_profile_ethnicity', ZyraSignupStep.ethnicity, 'Bangladeshi'),
    ]) {
      await _open(h, row.$1);
      expect(
        tester
            .widget<ZyraSignupPreview>(find.byType(ZyraSignupPreview))
            .controller
            .step,
        row.$2,
      );
      await h.tap('signup_choice_${row.$3}');
      await _done(h);
      final current = tester.widget<ZyraEditProfilePresentation>(
        find.byType(ZyraEditProfilePresentation),
      );
      switch (row.$2) {
        case ZyraSignupStep.location:
          expect(current.location, 'Manchester');
        case ZyraSignupStep.nationality:
          expect(current.nationality, 'Indian');
        case ZyraSignupStep.ethnicity:
          expect(current.ethnicity, contains('Bangladeshi'));
        default:
          fail('Unexpected detail step');
      }
    }

    for (var index = 0; index < 3; index++) {
      await _open(h, 'edit_profile_bio_$index');
      expect(find.byType(BioOnboardingFlow), findsOneWidget);
      if (index < 2) {
        final field = find.byType(TextField).first;
        await Scrollable.ensureVisible(tester.element(field));
        await tester.enterText(
          field,
          index == 0 ? 'Software engineer' : 'Helping my parents',
        );
        tester.testTextInput.hide();
      } else {
        await tester.tap(find.byType(DropdownButtonFormField<String>).first);
        await h.flush();
        await tester.tap(find.text('Under £20,000').last);
      }
      await h.flush();
      await h.tap('onboarding_continue');
      await tester.pumpAndSettle();
      h.assertPage('edit_profile');
      expect(find.byType(BioOnboardingFlow), findsNothing);
      final current = tester.widget<ZyraEditProfilePresentation>(
        find.byType(ZyraEditProfilePresentation),
      );
      expect(current.bioProgress[index], '1 of 4');
    }

    await _open(h, 'compatibility-editor-trafficLights');
    final editor = tester.widget<CompatibilityEditorScreen>(
      find.byType(CompatibilityEditorScreen),
    );
    expect(editor.kind, CompatibilityEditorKind.trafficLights);
    final category = chapter3Categories.firstWhere(
      (category) =>
          editor.initialDraft.preferenceQuestions(category).isNotEmpty,
    );
    final question = editor.initialDraft.preferenceQuestions(category).first;
    await h.tap('edit-preferences-${category.id}');
    await h.tap('edit-lights-${question.responseKey}');
    final renderer = tester.widget<TrafficLightQuestionScreen>(
      find.byType(TrafficLightQuestionScreen),
    );
    renderer.onChanged({
      for (final option in question.options) option: TrafficLight.green,
    });
    await h.flush();
    await h.tap('question-save');
    await _back(h);
    await h.tapText('Save changes');
    await tester.pumpAndSettle();
    h.assertPage('edit_profile');
    expect(find.byType(CompatibilityEditorScreen), findsNothing);
    final afterPreferences = tester.widget<ZyraEditProfilePresentation>(
      find.byType(ZyraEditProfilePresentation),
    );
    expect(
      afterPreferences.preferencesProgress,
      '${question.options.length} of ${editor.initialDraft.preferenceOptionCount}',
    );
    await _back(h);
    expect(h.latest.pages, isEmpty);
    expect(_key('concept_edit_profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'LOCK45 identity rows are locked and inline support opens Contact support',
    (tester) async {
      final h = _harness(tester, 'identity');
      await h.mount(tab: 4);
      await h.tap('concept_edit_profile');
      for (final id in ['name', 'birth', 'gender']) {
        await _reveal(h, 'edit_profile_identity_$id');
        final row = tester.widget<ZyraSettingsRow>(
          _key('edit_profile_identity_$id'),
        );
        expect(row.locked, isTrue);
        expect(row.onTap, isNull);
        await tester.tap(_key('edit_profile_identity_$id'));
        await h.flush();
        h.assertPage('edit_profile');
      }
      expect(find.text('Adam Khan'), findsOneWidget);
      expect(find.text('Age 30'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      await _reveal(h, 'edit_profile_open_support');
      final text = tester.widget<Text>(_key('edit_profile_open_support'));
      final span = text.textSpan! as TextSpan;
      final plain = span.toPlainText();
      final start = plain.indexOf('contact support');
      expect(start, greaterThanOrEqualTo(0));
      final paragraph = tester.renderObject<RenderParagraph>(
        _key('edit_profile_open_support'),
      );
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: start,
          extentOffset: start + 'contact support'.length,
        ),
      );
      expect(boxes, isNotEmpty);
      await tester.tapAt(paragraph.localToGlobal(boxes.first.toRect().center));
      await h.flush();
      h.assertPage('help_contact');
      await _back(h);
      h.assertPage('edit_profile');
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(430, 932), const Size(375, 667)]) {
    for (final scale in [1.0, 1.3]) {
      final suffix = size.width == 430 && scale == 1
          ? ''
          : '__${size.width.toInt()}x${size.height.toInt()}_${scale.toStringAsFixed(1)}';
      testWidgets(
        'LOCK45 bounded four-master rendered replay ${size.width} scale $scale',
        (tester) async {
          _captureFailures.clear();
          final h = _harness(
            tester,
            'captures$suffix',
            size: size,
            scale: scale,
          );
          await h.mount(
            tab: 4,
            seekerPhotos: List.filled(4, photos.seekerPhoto),
          );
          await h.tap('concept_edit_profile');
          await _open(h, 'edit_profile_about');
          await tester.enterText(
            _key('signup_about_you'),
            '“I value faith, family and a peaceful home…”',
          );
          await _done(h);
          final topScroll = tester.state<ScrollableState>(
            find
                .descendant(
                  of: _key('edit_profile_content_scroll'),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          topScroll.position.jumpTo(0);
          await h.flush();
          await _checkAndCapture(h, 'ep01_edit_profile__top$suffix');
          final scroll = tester.state<ScrollableState>(
            find
                .descendant(
                  of: _key('edit_profile_content_scroll'),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          scroll.position.jumpTo(scroll.position.maxScrollExtent);
          await h.flush();
          await _checkAndCapture(h, 'ep02_edit_profile__bottom$suffix');
          for (final filled in [false, true]) {
            final c = ZyraSignupPreviewController()
              ..setStep(ZyraSignupStep.photos);
            if (filled) {
              c.addPhoto(photos.seekerPhoto);
              c.addPhoto(photos.seekerPhoto);
            }
            await h.mountPresentation(
              checkpoint: ZyraPreviewNavigationCheckpoint(
                guardian: false,
                model: ViewRequestDraftModel(capacity: 3).snapshot(),
                tab: 4,
                pages: const [],
              ),
              backdrop: BoxDecoration(gradient: ZyraColors.brandGradient),
              child: Material(
                type: MaterialType.transparency,
                child: ZyraSignupPreview(
                  controller: c,
                  canAct: () => true,
                  preferencesBuilder: (_) => const SizedBox.shrink(),
                  onPause: () {},
                  onEnter: () {},
                  onShareCode: () {},
                  samplePhotos: [photos.seekerPhoto],
                  ownCode: '',
                ),
              ),
            );
            expect(find.byType(ZyraPhotoRulesCard), findsOneWidget);
            expect(c.photos.length, filled ? 2 : 0);
            await _checkAndCapture(
              h,
              '${filled ? 's20_photos__two' : 's19_photos__empty'}$suffix',
            );
            await tester.pumpWidget(const SizedBox.shrink());
            c.dispose();
          }
          expect(tester.takeException(), isNull);
          expect(_captureFailures, isEmpty);
        },
        skip: !_capture,
      );
    }
  }
}
