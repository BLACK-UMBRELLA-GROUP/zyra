// LOCK22 V4: real Founder routes, with unchanged caller-owned destinations.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _raw =
    '/Users/shakeelahmad/Documents/Codex/2026-11-01/zyra-queue62-settings-edit-profile-v4/work/raw';
const _capture = bool.fromEnvironment('ZYRA_LOCK22_V4_CAPTURE');
Finder k(String id) => find.byKey(ValueKey(id));

Future<void> _reveal(BaselineHarness h, String scrollId, Finder target) async {
  final scroll = find
      .descendant(of: k(scrollId), matching: find.byType(Scrollable))
      .first;
  await h.tester.scrollUntilVisible(
    target,
    160,
    scrollable: scroll,
    maxScrolls: 30,
  );
  await h.tester
      .state<ScrollableState>(scroll)
      .position
      .ensureVisible(h.tester.renderObject(target), alignment: .5);
  await h.flush();
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _cap(BaselineHarness h, String name) async {
  if (!_capture) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  void repaint(RenderObject node) {
    node.markNeedsPaint();
    node.visitChildren(repaint);
  }

  try {
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      k('zyra-founder-baseline-boundary'),
    );
    repaint(boundary);
    await h.tester.pump();
    await h.tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        final file = File(
          '$_root/PRODUCT/APPROVED/UNITY_PASS/BUILT/V4/$name.png',
        );
        await file.parent.create(recursive: true);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        final geometry = <String, Object?>{};
        for (final id in [
          'concept_settings_title',
          'edit_profile_preview_title',
          'edit_profile_answers_card',
          'edit_profile_fixed_card',
          'edit_profile_open_support',
          'concept_settings_privacyData',
          'concept_settings_phoneAccess',
        ]) {
          final f = k(id);
          if (f.evaluate().length == 1) {
            final r = h.tester.getRect(f);
            geometry[id] = [r.left, r.top, r.width, r.height];
          }
        }
        await File(
          '$_root/PRODUCT/APPROVED/UNITY_PASS/BUILT/V4/$name.json',
        ).writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'file': '$name.png',
            'png_size': [image.width, image.height],
            'logical_size': [430, 932],
            'text_scale': h.textScale,
            'route': h.latest.pages,
            'tab': h.latest.tab,
            'geometry_pt': geometry,
            'reached':
                'Actual admitted offline Founder shell; existing routes/sample data; real close/back control; no backend or native device.',
          }),
        );
      } finally {
        image.dispose();
      }
    });
  } finally {
    debugDisableShadows = previous;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _raw));
  tearDownAll(baselineTearDown);
  for (final scale in [1.0, 2.0]) {
    testWidgets('LOCK22 V4 actual Settings and Edit profile routes at $scale', (
      t,
    ) async {
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final h = BaselineHarness(
        t,
        group: 'settings_edit_v4',
        evidenceRoot: _raw,
        outputRoot: _raw,
        flatOutput: true,
        textScale: scale,
      );
      final suffix = scale == 1 ? '' : '__text200';
      await h.mount(tab: 4, pages: ['settings']);
      expect(find.text('Settings'), findsOneWidget);
      expect(t.getRect(k('concept_settings_title')).left, 20);
      expect(find.text('MEMBERSHIP'), findsNothing);
      expect(k('concept_settings_membership'), findsNothing);
      expect(find.text('Membership'), findsOneWidget); // Summary retained.
      expect(find.text('Seeker One'), findsOneWidget);
      await _cap(h, 's01_settings__top$suffix');
      await _reveal(
        h,
        'concept-current-settings-scroll',
        k('concept_settings_privacyData'),
      );
      await _cap(h, 's02_settings__bottom$suffix');
      await t.binding.handlePopRoute();
      await h.flush();
      expect(h.latest.pages, isEmpty);

      await h.mount(tab: 4, pages: ['edit_profile']);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('COMPATIBILITY'), findsNothing);
      expect(find.text('FIXED'), findsNothing);
      expect(find.textContaining('Your answers stay private.'), findsOneWidget);
      for (final count in [
        '0 of 20 answered',
        '0 of 46 answered',
        '0 of 38 answered',
        '0 of 325 preferences set',
        '0 introduction-blocking answers',
      ]) {
        expect(find.text(count), findsOneWidget);
      }
      if (scale == 1) {
        final card = t.getRect(k('edit_profile_answers_card'));
        expect(card.top, closeTo(180, 6));
        expect(card.height, closeTo(344, 6));
      }
      await _cap(h, 's03_edit_profile$suffix');
      for (final kind in CompatibilityEditorKind.values) {
        final row = k('compatibility-editor-${kind.name}');
        await _reveal(h, 'edit_profile_content_scroll', row);
        await t.tap(row);
        await h.flush();
        expect(
          t
              .widget<CompatibilityEditorScreen>(
                find.byType(CompatibilityEditorScreen),
              )
              .kind,
          kind,
        );
        Navigator.of(t.element(find.byType(CompatibilityEditorScreen))).pop();
        await h.flush();
      }
      await _reveal(
        h,
        'edit_profile_content_scroll',
        k('edit_profile_fixed_card'),
      );
      expect(find.text('Age 30'), findsOneWidget);
      expect(find.text('Brother'), findsOneWidget);
      expect(
        find.descendant(
          of: k('edit_profile_fixed_card'),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: k('edit_profile_fixed_card'),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNWidgets(2),
      );
      expect(
        find.textContaining('essentials and cannot be edited here.'),
        findsOneWidget,
      );
      await _reveal(
        h,
        'edit_profile_content_scroll',
        k('edit_profile_open_support'),
      );
      if (scale == 2) await _cap(h, 's03_edit_profile__text200__bottom');
      expect(
        t.getSize(k('edit_profile_open_support')).height,
        greaterThanOrEqualTo(48),
      );
      await t.tap(k('edit_profile_open_support'));
      await h.flush();
      h.assertPage('help_support');
      await t.binding.handlePopRoute();
      await h.flush();
      h.assertPage('edit_profile');
      await t.binding.handlePopRoute();
      await h.flush();
      expect(h.latest.pages, isEmpty);
      expect(t.takeException(), isNull);
    });
  }

  for (final guardian in [false, true]) {
    for (final smooth in [false, true]) {
      testWidgets(
        'Settings retains every row action guardian=$guardian smooth=$smooth',
        (t) async {
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final actions = <ZyraConceptAccountAction>[];
          var backs = 0;
          final h = BaselineHarness(
            t,
            group: 'settings_actions',
            evidenceRoot: _raw,
            textScale: 2,
          );
          await h.mountPresentation(
            child: ZyraConceptSettingsPresentation(
              data: ZyraConceptAccountData(
                guardian: guardian,
                name: 'Adam',
                age: '30',
                gender: 'male',
                location: 'London',
                membership: guardian ? 'Guardian One' : 'Seeker One',
                isOne: true,
                relationship: '',
                linkedSeekers: '2',
                guardianCount: '2',
                signedInWith: 'Apple',
                backgroundLabel: 'Ivory',
                hapticLabel: 'Soft',
                gold: true,
                smoothSettings: smooth,
              ),
              onAction: actions.add,
              onBack: () => backs++,
            ),
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: guardian,
              tab: 4,
              pages: const [],
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
            ),
          );
          final expected = [
            ZyraConceptAccountAction.signInSecurity,
            ZyraConceptAccountAction.appLock,
            ZyraConceptAccountAction.advanced,
            ZyraConceptAccountAction.visibility,
            if (guardian)
              ZyraConceptAccountAction.guardianPrivacy
            else
              ZyraConceptAccountAction.hiddenProfiles,
            ZyraConceptAccountAction.phoneAccess,
            ZyraConceptAccountAction.notificationSettings,
            ZyraConceptAccountAction.helpSupport,
            ZyraConceptAccountAction.feedback,
            ZyraConceptAccountAction.privacyData,
          ];
          for (final action in expected) {
            final row = k('concept_settings_${action.name}');
            await _reveal(h, 'concept-current-settings-scroll', row);
            await t.tap(row);
            await h.flush();
          }
          expect(actions, expected);
          expect(find.text('MEMBERSHIP'), findsNothing);
          expect(k('concept_settings_membership'), findsNothing);
          await t.tap(find.byType(BackButton));
          await h.flush();
          expect(backs, 1);
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
