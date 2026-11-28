import 'dart:convert';
import 'dart:io';

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
const _evidence = 'build/line148';

Finder _key(String value) => find.byKey(ValueKey(value));

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  BaselineHarness harness(WidgetTester tester, {bool compact = false}) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return BaselineHarness(
      tester,
      group: 'line148_account_recovery',
      outputRoot: '$_evidence/screens',
      evidenceRoot: '$_evidence/screens',
      flatOutput: true,
      logicalSize: compact ? const Size(375, 667) : const Size(430, 932),
      safePadding: compact
          ? const EdgeInsets.only(top: 20)
          : const EdgeInsets.only(top: 59, bottom: 34),
      textScale: compact ? 2 : 1,
    );
  }

  ZyraPreviewNavigationCheckpoint checkpoint() =>
      ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: ViewRequestDraftModel(capacity: 3).snapshot(),
        tab: 4,
        pages: const [],
      );

  Future<void> mountSignup(
    BaselineHarness h,
    ZyraSignupPreviewController controller, {
    TargetPlatform platform = TargetPlatform.iOS,
  }) => h.mountPresentation(
    checkpoint: checkpoint(),
    child: Builder(
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(platform: platform),
        child: Scaffold(
          body: ZyraSignupPreview(
            controller: controller,
            canAct: () => true,
            preferencesBuilder: (_) => const SizedBox.shrink(),
            onPause: () => fail('Recovery must not create a preview account.'),
            onEnter: () => fail('Recovery must not enter the sample account.'),
            samplePhotos: const [],
            ownCode: '',
            onShareCode: () => fail('Recovery must not share a code.'),
          ),
        ),
      ),
    ),
  );

  Future<void> check(
    BaselineHarness h,
    String state, {
    bool saveMaster = true,
  }) async {
    final originalShadows = debugDisableShadows;
    try {
      debugDisableShadows = false;
      await h.tester.pump(const Duration(milliseconds: 2600));
      final boundary = h.tester.renderObject<RenderRepaintBoundary>(
        _key('zyra-founder-baseline-boundary'),
      );
      final audit = await auditZyraRenderedText(h.tester, boundary);
      if (_capture) {
        await h.tester.runAsync(() async {
          final file = File('$_evidence/audit/$state.json');
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(audit.toJson()));
        });
        if (saveMaster) {
          await h.capture(
            'account_recovery',
            state,
            'lock50',
            'Founder sample account recovery, LOCK 50.',
            fileName: '$state.png',
          );
        }
      }
      expect(audit.failures, isEmpty, reason: '$state: ${audit.failures}');
    } finally {
      debugDisableShadows = originalShadows;
    }
  }

  testWidgets('Welcome and support only recovery match ar01 and ar02', (
    tester,
  ) async {
    final controller = ZyraSignupPreviewController()..finishSplash();
    addTearDown(controller.dispose);
    final h = harness(tester);
    await mountSignup(h, controller);
    expect(
      tester.getTopLeft(_key('signup_apple')).dy,
      lessThan(tester.getTopLeft(_key('signup_google')).dy),
    );
    await check(h, 'ar01_welcome__cant_sign_in');
    await h.tap('signup_open_recovery');
    expect(controller.step, ZyraSignupStep.recovery);
    expect(_key('signup_back'), findsOneWidget);
    expect(_key('signup_progress'), findsNothing);
    expect(_key('signup_skip'), findsNothing);
    await check(h, 'ar02_cant_sign_in__support');
  });

  testWidgets('backup sign-in uses the safe sample Settings route', (
    tester,
  ) async {
    final h = harness(tester);
    var nativeChecks = 0;
    await h.mount(
      tab: 4,
      pages: const ['settings'],
      confirmSensitiveAction: () async {
        nativeChecks++;
        return true;
      },
    );
    await h.tap('concept_settings_signInSecurity');
    expect(find.text('Add Google as a backup'), findsOneWidget);
    final old = tester
        .widget<InkWell>(_key('privacy_add_backup_sign_in'))
        .onTap!;
    expect(
      tester.getTopLeft(find.text('BACKUP SIGN-IN')).dy,
      lessThan(tester.getTopLeft(find.text('SIGNED-IN DEVICES')).dy),
    );
    await check(h, 'ar03_sign_in_security__backup');
    await tester.binding.handlePopRoute();
    await h.flush();
    await h.tap('concept_settings_signInSecurity');
    old();
    await h.flush();
    expect(find.text('Add Google as a backup'), findsOneWidget);
    await h.tap('privacy_add_backup_sign_in');
    expect(
      find.text('Google added. You can now sign in with Apple or Google.'),
      findsOneWidget,
    );
    expect(nativeChecks, 0);
    expect(
      tester.widget<Text>(find.text('Added')).style!.color,
      const Color(0xFF326B4C),
    );
    await tester.pump(const Duration(seconds: 3));
    await h.flush();
    await check(h, 'ar04_sign_in_security__backup_added');
    await tester.binding.handlePopRoute();
    await h.flush();
    await h.tap('concept_settings_signInSecurity');
    expect(find.text('Added'), findsOneWidget);

    await h.tap('privacy_sign_out_other_devices');
    expect(nativeChecks, 1);
    expect(find.text('Only this phone is signed in.'), findsOneWidget);
    expect(find.text('BACKUP SIGN-IN'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await check(h, 'ps07_sign_in_one_device__with_backup');
  });

  testWidgets('Android Welcome keeps Google first with the recovery link', (
    tester,
  ) async {
    final controller = ZyraSignupPreviewController()..finishSplash();
    addTearDown(controller.dispose);
    final h = harness(tester);
    await mountSignup(h, controller, platform: TargetPlatform.android);
    final google = tester.getRect(_key('signup_google'));
    final apple = tester.getRect(_key('signup_apple'));
    final recovery = tester.getRect(_key('signup_open_recovery'));
    expect(google.bottom, lessThan(apple.top));
    expect(apple.bottom, lessThan(recovery.top));
    await check(h, 's03_welcome__android_google_first_with_recovery');
  });

  testWidgets('Larger Text retains the scrollable recovery and pinned action', (
    tester,
  ) async {
    final controller = ZyraSignupPreviewController()
      ..finishSplash()
      ..openRecovery();
    addTearDown(controller.dispose);
    final h = harness(tester, compact: true);
    await mountSignup(h, controller);
    final frame = tester.getRect(_key('signup_recovery'));
    final action = _key('signup_recovery_contact');
    expect(action.hitTestable(), findsOneWidget);
    expect(tester.getRect(action).bottom, lessThanOrEqualTo(frame.bottom));
    final scroll = find.descendant(
      of: _key('signup_recovery_scroll'),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scroll).position;
    expect(position.maxScrollExtent, greaterThan(0));
    await check(h, 'ar02_larger_text_top', saveMaster: false);
    position.jumpTo(position.maxScrollExtent);
    await h.flush();
    expect(action.hitTestable(), findsOneWidget);
    await check(h, 'ar02_larger_text_bottom', saveMaster: false);
  });

  testWidgets('Google offers the mirror backup even in the one-device state', (
    tester,
  ) async {
    final h = harness(tester, compact: true);
    var added = false;
    await h.mountPresentation(
      checkpoint: checkpoint(),
      child: Scaffold(
        body: StatefulBuilder(
          builder: (_, update) => ZyraPrivacySecurityPreview(
            page: ZyraPrivacySecurityPage.signIn,
            signedInWith: 'Google',
            otherDevicesPresent: false,
            backupSignInAdded: added,
            onAddBackupSignIn: () => update(() => added = true),
          ),
        ),
      ),
    );
    expect(find.text('Only this phone is signed in.'), findsOneWidget);
    final signInScroll = find.descendant(
      of: _key('concept_account_action_scroll'),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      _key('privacy_add_backup_sign_in'),
      110,
      scrollable: signInScroll,
    );
    await h.tap('privacy_add_backup_sign_in');
    expect(
      find.text(
        'If you ever lose your Google account, you can still sign in with Apple.',
      ),
      findsOneWidget,
    );
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Added'), findsOneWidget);
    expect(_key('privacy_add_backup_sign_in'), findsNothing);
    await check(h, 'ar04_google_larger_text', saveMaster: false);
  });
}
