// LOCK 44 focused replay through the actual Founder Settings routes.
// Q225: manual pause, calm Profiles card and request admission.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_pause_private_preview.dart';

import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _root = 'build/line138';
const _capture = bool.fromEnvironment('ZYRA_LINE138_CAPTURE');
Finder _key(String id) => find.byKey(ValueKey(id));

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  BaselineHarness harness(
    WidgetTester t,
    String name, {
    Size size = const Size(430, 932),
    double scale = 1,
  }) {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    return BaselineHarness(
      t,
      group: 'line138_$name',
      logicalSize: size,
      textScale: scale,
      outputRoot: '$_root/screens',
      evidenceRoot: '$_root/screens',
      flatOutput: true,
      safePadding: size.width == 375
          ? const EdgeInsets.only(top: 20)
          : const EdgeInsets.only(top: 59, bottom: 34),
    );
  }

  Future<void> setting(BaselineHarness h, String id) async {
    final scroll = find
        .descendant(
          of: _key('concept-current-settings-scroll'),
          matching: find.byType(Scrollable),
        )
        .first;
    await h.tester.scrollUntilVisible(_key(id), 160, scrollable: scroll);
    await h.tap(id);
    h.assertPage('account_action');
    expect(find.byType(ZyraPausePrivatePreview), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(_key('floating-nav-item-0'), findsNothing);
  }

  Future<void> back(BaselineHarness h) async {
    await h.tester.binding.handlePopRoute();
    await h.flush();
  }

  ZyraPausePrivatePreview page(WidgetTester t) =>
      t.widget<ZyraPausePrivatePreview>(find.byType(ZyraPausePrivatePreview));

  Future<void> check(BaselineHarness h, String name) async {
    final previousShadows = debugDisableShadows;
    try {
      debugDisableShadows = false;
      await h.tester.pump(const Duration(milliseconds: 2600));
      final boundary = h.tester.renderObject<RenderRepaintBoundary>(
        _key('zyra-founder-baseline-boundary'),
      );
      final result = await auditZyraRenderedText(h.tester, boundary);
      await h.tester.runAsync(() async {
        final file = File('$_root/audit/$name.json');
        await file.parent.create(recursive: true);
        final geometry = <String, Object?>{};
        for (final id in [
          'concept_main_title_Profiles',
          'paused_profiles_card',
          'paused_profiles_show_again',
          'compact-nav-surface',
        ]) {
          final found = _key(id);
          if (found.evaluate().length == 1) {
            final rect = h.tester.getRect(found);
            geometry[id] = [rect.left, rect.top, rect.width, rect.height];
          }
        }
        await file.writeAsString(
          jsonEncode({...result.toJson(), 'geometry_pt': geometry}),
        );
      });
      expect(result.failures, isEmpty, reason: '$name ${result.toJson()}');
      void repaint(RenderObject object) {
        object.visitChildren(repaint);
        object.markNeedsPaint();
      }

      repaint(boundary);
      await h.tester.pump();
      await h.capture(
        'pause_private',
        name,
        'normal',
        name,
        fileName: '$name.png',
      );
    } finally {
      debugDisableShadows = previousShadows;
    }
  }

  testWidgets('LOCK44 Seeker pause and Private mode stay separate', (t) async {
    final h = harness(t, 'seeker_actions');
    await h.mount(tab: 4, pages: const ['settings']);
    await setting(h, 'concept_settings_privateMode');
    expect(page(t).privateMode, isFalse);
    await h.tap('private_mode_switch');
    await h.flush();
    expect(page(t).privateMode, isTrue);
    expect(
      find.text('On · only people you send a request to can see you'),
      findsOneWidget,
    );
    expect(find.text('Private mode comes with Seeker One.'), findsNothing);
    await back(h);
    await setting(h, 'concept_settings_visibility');
    expect(page(t).paused, isFalse);
    expect(find.text('Your profile is visible'), findsOneWidget);
    await h.tap('pause_private_action');
    await h.flush();
    expect(page(t).paused, isTrue);
    expect(page(t).privateMode, isTrue);
    expect(find.text('Paused. You are hidden from Profiles.'), findsOneWidget);
    expect(find.text('PAUSE FOR'), findsNothing);
    await back(h);
    final pauseRow = t.widget<ZyraSettingsRow>(
      _key('concept_settings_visibility'),
    );
    expect(pauseRow.value, 'Paused');
    expect(
      t.widget<ZyraSettingsRow>(_key('concept_settings_privateMode')).value,
      'On',
    );
    await setting(h, 'concept_settings_visibility');
    await h.tap('pause_private_action');
    await h.flush();
    expect(page(t).paused, isFalse);
    expect(page(t).privateMode, isTrue);
    expect(find.text('Your profile is visible again.'), findsOneWidget);
    expect(find.text('Families can find you in Profiles'), findsOneWidget);
    expect(find.textContaining('confirmed account'), findsNothing);
    expect(find.textContaining('server setting'), findsNothing);
  });

  testWidgets(
    'LOCK44 Basic switch is locked and upgrade opens existing plans',
    (t) async {
      final h = harness(t, 'basic');
      await h.mount(
        tab: 4,
        pages: const ['settings'],
        seekerMembership: 'Seeker Basic',
        initialSeekerBasic: true,
      );
      await setting(h, 'concept_settings_privateMode');
      expect(page(t).seekerOne, isFalse);
      await h.tap('private_mode_switch');
      await h.flush();
      expect(page(t).privateMode, isFalse);
      expect(find.text('Private mode comes with Seeker One.'), findsOneWidget);
      await h.tap('pause_private_action');
      await h.flush();
      h.assertPage('one_upgrade');
      expect(find.byType(ZyraPausePrivatePreview), findsNothing);
    },
  );

  testWidgets('LOCK44 Guardian Settings has neither Seeker privacy row', (
    t,
  ) async {
    final h = harness(t, 'guardian');
    await h.mount(guardian: true, tab: 4, pages: const ['settings']);
    await t.drag(
      _key('concept-current-settings-scroll'),
      const Offset(0, -350),
    );
    await h.flush();
    expect(_key('concept_settings_visibility'), findsNothing);
    expect(_key('concept_settings_privateMode'), findsNothing);
    expect(find.text('Pause My Profile'), findsNothing);
    expect(find.text('Private mode'), findsNothing);
  });

  testWidgets('LOCK44 callbacks from a departed page cannot change state', (
    t,
  ) async {
    final h = harness(t, 'stale');
    await h.mount(tab: 4, pages: const ['settings']);
    await setting(h, 'concept_settings_visibility');
    final old = page(t);
    await back(h);
    old.onPause();
    old.onPrivateChanged(true);
    old.onUpgrade();
    await h.flush();
    h.assertPage('settings');
    await setting(h, 'concept_settings_visibility');
    expect(page(t).paused, isFalse);
    expect(page(t).privateMode, isFalse);
  });

  testWidgets(
    'LOCK44 paused Profiles hides browsing and manually restores without changing Private',
    (t) async {
      final h = harness(t, 'manual_unpause');
      await h.mount(tab: 4, pages: const ['settings']);
      await setting(h, 'concept_settings_privateMode');
      page(t).onPrivateChanged(true);
      await h.flush();
      await back(h);
      await setting(h, 'concept_settings_visibility');
      expect(find.text('PAUSE FOR'), findsNothing);
      expect(find.text('1 week'), findsNothing);
      expect(find.text('1 month'), findsNothing);
      page(t).onPause();
      await h.flush();
      await back(h);
      await back(h);
      await h.tap('floating-nav-item-0');
      expect(_key('paused_profiles_card'), findsOneWidget);
      expect(find.text('Until you turn it off'), findsOneWidget);
      expect(_key('concept_browse_portrait_card'), findsNothing);
      expect(_key('floating-nav-item-4'), findsOneWidget);
      final model = h.shellFixture.model;
      expect(model.canRequest('draft-zainab'), isFalse);
      expect(model.request('draft-zainab'), isFalse);
      final old = t
          .widget<ZyraPausedProfilesCard>(find.byType(ZyraPausedProfilesCard))
          .onShowProfile;
      await h.tap('floating-nav-item-4');
      old();
      await h.flush();
      expect(model.ownProfilePrivacy!.paused, isTrue);
      await h.tap('floating-nav-item-0');
      await h.tap('paused_profiles_show_again');
      await h.flush();
      expect(_key('paused_profiles_card'), findsNothing);
      expect(model.ownProfilePrivacy!.paused, isFalse);
      expect(model.ownProfilePrivacy!.privateMode, isTrue);
      expect(find.text('Your profile is visible again.'), findsOneWidget);
    },
  );

  for (final width in [375.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final profiles in [false, true]) {
        testWidgets(
          'LOCK44 paused rendered text $width $scale profiles=$profiles',
          (t) async {
            final name =
                '${width.toInt()}_${scale.toInt()}_paused_${profiles ? 'profiles' : 'settings'}';
            final h = harness(
              t,
              name,
              size: Size(width, width == 375 ? 667 : 932),
              scale: scale,
            );
            await h.mount(tab: 4, pages: const ['settings']);
            await setting(h, 'concept_settings_visibility');
            page(t).onPause();
            await h.flush();
            if (profiles) {
              await back(h);
              await back(h);
              await h.tap('floating-nav-item-0');
            }
            await check(h, '${name}_top');
            final scroll = find
                .descendant(
                  of: find.byType(
                    profiles ? ZyraPausedProfilesCard : ZyraPausePrivatePreview,
                  ),
                  matching: find.byType(Scrollable),
                )
                .first;
            await t.drag(scroll, const Offset(0, -1800));
            await h.flush();
            await check(h, '${name}_bottom');
            expect(
              find.text('Show my profile again').hitTestable(),
              findsOneWidget,
            );
            expect(t.takeException(), isNull);
          },
          skip: !_capture,
        );
      }
    }
  }

  for (final variant in [
    ('pp01_pause__visible', false, false, false),
    ('pp02_pause__paused', false, true, false),
    ('pp03_private_mode__off', true, false, false),
    ('pp04_private_mode__on', true, true, false),
    ('pp05_private_mode__seeker_basic_locked', true, false, true),
    ('pp06_settings__privacy_rows', false, false, true),
    ('pp07_profiles__paused', false, true, false),
  ]) {
    testWidgets('LOCK44 master ${variant.$1} actual Settings route', (t) async {
      final h = harness(t, variant.$1);
      await h.mount(
        tab: 4,
        pages: const ['settings'],
        seekerMembership: variant.$4 ? 'Seeker Basic' : 'Seeker One',
        initialSeekerBasic: variant.$4,
      );
      if (variant.$1 != 'pp06_settings__privacy_rows') {
        await setting(
          h,
          variant.$2
              ? 'concept_settings_privateMode'
              : 'concept_settings_visibility',
        );
        if (variant.$3) {
          if (variant.$2) {
            page(t).onPrivateChanged(true);
          } else {
            page(t).onPause();
          }
          await h.flush();
        }
      }
      if (variant.$1.startsWith('pp07')) {
        await back(h);
        await back(h);
        await h.tap('floating-nav-item-0');
        expect(_key('paused_profiles_card'), findsOneWidget);
      }
      await t.pump(const Duration(seconds: 4));
      await check(h, variant.$1);
    }, skip: !_capture);
  }

  for (final width in [375.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final private in [false, true]) {
        testWidgets(
          'LOCK44 focused rendered text $width $scale private=$private',
          (t) async {
            final name =
                '${width.toInt()}_${scale.toInt()}_${private ? 'private' : 'pause'}';
            final h = harness(
              t,
              name,
              size: Size(width, width == 375 ? 667 : 932),
              scale: scale,
            );
            await h.mount(tab: 4, pages: const ['settings']);
            await setting(
              h,
              private
                  ? 'concept_settings_privateMode'
                  : 'concept_settings_visibility',
            );
            if (private) {
              page(t).onPrivateChanged(true);
              await h.flush();
            }
            await check(h, '${name}_top');
            final scroll = find
                .descendant(
                  of: find.byType(ZyraPausePrivatePreview),
                  matching: find.byType(Scrollable),
                )
                .first;
            await t.drag(scroll, const Offset(0, -1800));
            await h.flush();
            await check(h, '${name}_bottom');
            expect(t.takeException(), isNull);
            if (!private) {
              expect(
                find.text('Pause my profile').hitTestable(),
                findsOneWidget,
              );
            }
          },
          skip: !_capture,
        );
      }
    }
  }
}
