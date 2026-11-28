import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_privacy_security_preview.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _capture = bool.fromEnvironment('ZYRA_LINE148_CAPTURE');
Finder _key(String value) => find.byKey(ValueKey(value));

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  BaselineHarness harness(
    WidgetTester tester,
    double width,
    double scale, {
    double? height,
  }) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return BaselineHarness(
      tester,
      group: 'line148_lock50_rebase_proof',
      outputRoot: 'build/line148/rebase',
      evidenceRoot: 'build/line148/rebase',
      logicalSize: Size(width, height ?? (width == 375 ? 667 : 932)),
      safePadding: width == 375
          ? const EdgeInsets.only(top: 20)
          : const EdgeInsets.only(top: 59, bottom: 34),
      textScale: scale,
      reduceMotion: true,
    );
  }

  ZyraPreviewNavigationCheckpoint checkpoint() =>
      ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: ViewRequestDraftModel(capacity: 3).snapshot(),
        tab: 4,
        pages: const [],
      );

  Future<void> audit(
    BaselineHarness h,
    String state, {
    bool saveRaster = false,
  }) async {
    final before = debugDisableShadows;
    try {
      debugDisableShadows = false;
      await h.tester.pump(const Duration(milliseconds: 2600));
      final boundary = h.tester.renderObject<RenderRepaintBoundary>(
        _key('zyra-founder-baseline-boundary'),
      );
      final result = await auditZyraRenderedText(h.tester, boundary);
      if (_capture) {
        await h.tester.runAsync(() async {
          final file = File('build/line148/rebase/audit/$state.json');
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(result.toJson()));
        });
        if (saveRaster) {
          void repaint(RenderObject object) {
            object.markNeedsPaint();
            object.visitChildren(repaint);
          }

          repaint(boundary);
          await h.tester.pump();
          await h.tester.runAsync(() async {
            final image = await boundary.toImage(
              pixelRatio: h.devicePixelRatio,
            );
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              expect(bytes, isNotNull);
              final file = File('build/line148/rebase/screens/$state.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
      }
      expect(result.failures, isEmpty, reason: '$state: ${result.failures}');
    } finally {
      debugDisableShadows = before;
    }
  }

  // Keep the six original combinations. Correction 4b removes the wrapped
  // wordmark line at 375x667/2x, so that page now fits and LOCK26 requires it
  // to stay still. A shorter viewport retains every real-overflow assertion.
  for (final setting in [
    (375.0, 1.0, 667.0),
    (375.0, 1.3, 667.0),
    (375.0, 2.0, 667.0),
    (430.0, 1.0, 932.0),
    (430.0, 1.3, 932.0),
    (430.0, 2.0, 932.0),
    (375.0, 2.0, 500.0),
  ]) {
    final (width, scale, height) = setting;
    final overflowStress = height == 500;
    final size =
        '${width.toInt()}_text${(scale * 100).round()}'
        '${overflowStress ? '_height500' : ''}';
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      final label = '${platform.name}_$size';
      testWidgets('LOCK50 Welcome and recovery $label', (tester) async {
        final controller = ZyraSignupPreviewController()..finishSplash();
        addTearDown(controller.dispose);
        final h = harness(tester, width, scale, height: height);
        await h.mountPresentation(
          checkpoint: checkpoint(),
          child: Builder(
            builder: (context) => Theme(
              data: Theme.of(context).copyWith(platform: platform),
              child: Scaffold(
                body: ZyraSignupPreview(
                  controller: controller,
                  canAct: () => true,
                  preferencesBuilder: (_) => const SizedBox.shrink(),
                  onPause: () => fail('Recovery must not create an account.'),
                  onEnter: () => fail('Recovery must not enter an account.'),
                  samplePhotos: const [],
                  ownCode: '',
                  onShareCode: () => fail('Recovery must not share a code.'),
                ),
              ),
            ),
          ),
        );
        final first = _key(
          platform == TargetPlatform.android ? 'signup_google' : 'signup_apple',
        );
        final second = _key(
          platform == TargetPlatform.android ? 'signup_apple' : 'signup_google',
        );
        final recovery = _key('signup_open_recovery');
        final welcomeScroll = find.descendant(
          of: _key('signup_welcome_scroll'),
          matching: find.byType(Scrollable),
        );
        final welcomePosition = tester
            .state<ScrollableState>(welcomeScroll)
            .position;
        final capTarget = width == 375 && scale == 2;
        final overflowing = overflowStress;
        final tracked = <String, Finder>{
          'wordmark': find.text('ZYRA'),
          'tagline': find.text('Connecting Through Trust'),
          'first': first,
          'second': second,
          'recovery': recovery,
        };
        Map<String, Rect> rects() => {
          for (final entry in tracked.entries)
            entry.key: tester.getRect(entry.value),
        };
        final atTop = rects();
        final safeBottom = height - 34;
        expect(tester.takeException(), isNull);
        expect(welcomePosition.pixels, 0);
        expect(welcomePosition.minScrollExtent, 0);
        expect(
          welcomePosition.viewportDimension,
          closeTo(height - 62 - 34, .001),
        );
        expect(
          welcomePosition.maxScrollExtent,
          overflowing ? greaterThan(0) : 0,
        );
        expect(tester.widget<Text>(tracked['wordmark']!).style!.fontSize, 54);
        expect(
          tester.widget<Text>(tracked['wordmark']!).style!.letterSpacing,
          14,
        );
        expect(
          tester.widget<Text>(tracked['tagline']!).style!.fontSize,
          width == 375 ? 12.5 : 430 * .0333,
        );
        expect(
          MediaQuery.textScalerOf(tester.element(recovery)).scale(14),
          closeTo(14 * scale, .001),
        );
        for (final provider in [first, second]) {
          final bounds = tester.getRect(provider);
          expect(bounds.left, 20);
          expect(bounds.width, width - 40);
          expect(bounds.height, closeTo(52 * scale, .001));
        }
        expect(
          tester.getRect(first).bottom,
          lessThan(tester.getRect(second).top),
        );
        expect(
          tester.getRect(second).bottom,
          lessThan(tester.getRect(recovery).top),
        );
        expect(atTop['second']!.top - atTop['first']!.bottom, 12);
        expect(atTop['recovery']!.top - atTop['second']!.bottom, 8);
        expect(atTop['tagline']!.top - atTop['wordmark']!.bottom, 8);
        expect(
          atTop['tagline']!.bottom,
          lessThanOrEqualTo(atTop['first']!.top),
        );
        await audit(h, 'welcome_$label', saveRaster: capTarget);
        if (!overflowing) {
          // These are the original Column's bottom stack and centered brand.
          // The scroll wrapper must not change a fitting screen's positions.
          expect(atTop['recovery']!.bottom, closeTo(safeBottom - 14, .001));
          final brandHeight =
              atTop['wordmark']!.height + 8 + atTop['tagline']!.height;
          expect(
            atTop['wordmark']!.top,
            closeTo(62 + (atTop['first']!.top - 62 - brandHeight) / 2, .001),
          );
          expect(atTop['wordmark']!.center.dx, closeTo(width / 2, .001));
          expect(atTop['tagline']!.center.dx, closeTo(width / 2, .001));
        }
        // Use a real gesture on both kinds of screen: fitting content cannot
        // move; overflowing content reaches the actual end of its one scroll.
        await tester.drag(
          welcomeScroll,
          Offset(0, -(welcomePosition.maxScrollExtent + 120)),
        );
        await tester.pumpAndSettle();
        await h.flush();
        final atEnd = rects();
        expect(
          welcomePosition.pixels,
          closeTo(welcomePosition.maxScrollExtent, .001),
        );
        for (final entry in atTop.entries) {
          final end = atEnd[entry.key]!;
          expect(end.size, entry.value.size);
          expect(end.left, entry.value.left);
          expect(
            end.top - entry.value.top,
            closeTo(-welcomePosition.maxScrollExtent, .001),
            reason: '${entry.key} must move with the whole Welcome content',
          );
        }
        expect(atEnd['first']!.bottom, lessThan(atEnd['second']!.top));
        expect(atEnd['second']!.bottom, lessThan(atEnd['recovery']!.top));
        expect(atEnd['recovery']!.bottom, lessThan(safeBottom));
        for (final name in ['first', 'second', 'recovery']) {
          final bounds = atEnd[name]!;
          expect(bounds.top, greaterThanOrEqualTo(62));
          expect(bounds.bottom, lessThanOrEqualTo(safeBottom));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(width));
        }
        expect(first.hitTestable(), findsOneWidget);
        expect(second.hitTestable(), findsOneWidget);
        expect(recovery.hitTestable(), findsOneWidget);
        if (overflowing) {
          expect(welcomePosition.extentBefore, greaterThan(0));
          expect(welcomePosition.extentAfter, closeTo(0, .001));
        }
        // Audit the real top and the post-gesture end at both prescribed cap
        // cases even when they fit, plus the genuine shorter-viewport scroll.
        if (capTarget) {
          await audit(h, 'welcome_end_$label', saveRaster: true);
        }
        if (_capture) {
          List<double> coordinates(Rect rect) => [
            rect.left,
            rect.top,
            rect.width,
            rect.height,
          ];
          await tester.runAsync(() async {
            final file = File(
              'build/line148/rebase/geometry/welcome_$label.json',
            );
            await file.parent.create(recursive: true);
            await file.writeAsString(
              jsonEncode({
                'platform': platform.name,
                'width': width,
                'height': height,
                'text_scale': scale,
                'cap_target': capTarget,
                'overflowing': overflowing,
                'min_extent': welcomePosition.minScrollExtent,
                'max_extent': welcomePosition.maxScrollExtent,
                'end_pixels': welcomePosition.pixels,
                'safe_bottom': safeBottom,
                'top': atTop.map(
                  (name, rect) => MapEntry(name, coordinates(rect)),
                ),
                'end': atEnd.map(
                  (name, rect) => MapEntry(name, coordinates(rect)),
                ),
              }),
            );
          });
        }
        await h.tap('signup_open_recovery');
        expect(controller.step, ZyraSignupStep.recovery);
        expect(_key('signup_back'), findsOneWidget);
        expect(_key('signup_progress'), findsNothing);
        expect(_key('signup_skip'), findsNothing);
        final action = _key('signup_recovery_contact');
        expect(action.hitTestable(), findsOneWidget);
        await audit(h, 'recovery_top_$label');
        final scroll = find.descendant(
          of: _key('signup_recovery_scroll'),
          matching: find.byType(Scrollable),
        );
        final position = tester.state<ScrollableState>(scroll).position;
        position.jumpTo(position.maxScrollExtent);
        await h.flush();
        expect(action.hitTestable(), findsOneWidget);
        await audit(h, 'recovery_bottom_$label');
        await h.tap('signup_recovery_contact');
        expect(
          find.text('Opens the support form — no sign-in needed'),
          findsOneWidget,
        );
        expect(controller.step, ZyraSignupStep.recovery);
        final notice = tester.widget<SnackBar>(find.byType(SnackBar));
        await tester.pump(notice.duration);
        await tester.pump(const Duration(milliseconds: 500));
        await h.flush();
        expect(find.byType(SnackBar), findsNothing);
        await h.tap('signup_back');
        expect(controller.step, ZyraSignupStep.welcome);
        if (overflowing) {
          await tester.drag(welcomeScroll, const Offset(0, -240));
          await tester.pumpAndSettle();
          await h.flush();
        }
        expect(_key('signup_open_recovery').hitTestable(), findsOneWidget);
        await h.tap('signup_open_recovery');
        expect(controller.step, ZyraSignupStep.recovery);
      });
    }

    // The extra viewport stresses Welcome/recovery, not another backup matrix.
    if (overflowStress) continue;

    for (final provider in ['Apple', 'Google']) {
      testWidgets('LOCK50 $provider backup $size', (tester) async {
        final h = harness(tester, width, scale);
        var added = false;
        final backup = provider == 'Apple' ? 'Google' : 'Apple';
        await h.mountPresentation(
          checkpoint: checkpoint(),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (_, update) => ZyraPrivacySecurityPreview(
                page: ZyraPrivacySecurityPage.signIn,
                signedInWith: provider,
                otherDevicesPresent: false,
                backupSignInAdded: added,
                onAddBackupSignIn: () => update(() => added = true),
              ),
            ),
          ),
        );
        final scroll = find.descendant(
          of: _key('concept_account_action_scroll'),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          _key('privacy_add_backup_sign_in'),
          110,
          scrollable: scroll,
        );
        expect(find.text('Add $backup as a backup'), findsOneWidget);
        await audit(h, 'backup_${provider}_before_$size');
        await h.tap('privacy_add_backup_sign_in');
        expect(find.text(backup), findsOneWidget);
        expect(find.text('Added'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('Added')).style!.color,
          const Color(0xFF326B4C),
        );
        expect(_key('privacy_add_backup_sign_in'), findsNothing);
        final account = provider == 'Google' ? 'Google account' : 'Apple ID';
        expect(
          find.text(
            'If you ever lose your $account, you can still sign in '
            'with $backup.',
          ),
          findsOneWidget,
        );
        await audit(h, 'backup_${provider}_after_$size');
      });
    }
  }

  testWidgets(
    'LOCK50 backup stays with its role across LOCK46 Switch profile',
    (tester) async {
      final h = harness(tester, 430, 1);
      var nativeChecks = 0;
      await h.mount(
        tab: 4,
        confirmSensitiveAction: () async {
          nativeChecks++;
          return true;
        },
      );
      Future<void> openSecurity() async {
        if (h.latest.tab != 4) await h.tap('floating-nav-item-4');
        await h.tap('concept_settings');
        await h.tap('concept_settings_signInSecurity');
        expect(find.text('Sign-in & security'), findsOneWidget);
      }

      Future<void> back() async {
        await tester.binding.handlePopRoute();
        await h.flush();
      }

      Future<void> switchRole({required bool guardian}) async {
        await back();
        await back();
        await h.tap('switch-account-button');
        expect(h.key('small_pages_switch_profile'), findsOneWidget);
        await h.tap('small_pages_switch_role');
        expect(h.latest.guardian, guardian);
        expect(h.latest.pages, isEmpty);
        await openSecurity();
      }

      await openSecurity();
      final backup = h.key('privacy_add_backup_sign_in');
      final beforeSwitch = tester.widget<InkWell>(backup).onTap!;
      await h.tap('privacy_add_backup_sign_in');
      expect(find.text('Added'), findsOneWidget);
      expect(nativeChecks, 0);
      await switchRole(guardian: true);
      expect(find.text('Add Google as a backup'), findsOneWidget);
      beforeSwitch();
      await h.flush();
      expect(find.text('Added'), findsNothing);
      expect(find.text('Add Google as a backup'), findsOneWidget);
      await switchRole(guardian: false);
      expect(find.text('Added'), findsOneWidget);
      expect(backup, findsNothing);
      expect(nativeChecks, 0);
    },
  );
}
