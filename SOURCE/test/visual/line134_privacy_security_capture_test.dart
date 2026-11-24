// Focused LOCK 40 replay at the approved 430 × 932 viewport. Captures stay
// under SOURCE/build; they are review evidence, never compiled app copies.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_app_lock.dart';
import 'package:zyra/services/zyra_local_prefs.dart';

import '../support/received_request_fixture.dart';
import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _root =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE/build/line134';

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: '$_root/screens'));
  tearDownAll(baselineTearDown);

  BaselineHarness harness(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return BaselineHarness(
      tester,
      group: 'line134_visual',
      outputRoot: '$_root/screens',
      evidenceRoot: '$_root/screens',
      flatOutput: true,
    );
  }

  Future<void> check(BaselineHarness h, String name) async {
    await h.capture(
      'privacy_security',
      name,
      'normal',
      name,
      fileName: '$name.png',
    );
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
    );
    final result = await auditZyraRenderedText(h.tester, boundary);
    expect(result.failures, isEmpty, reason: '$name ${result.toJson()}');
  }

  testWidgets('Seeker Settings and privacy pages use locked text', (
    tester,
  ) async {
    final model = ReceivedRequestFixture(capacity: 3)
      ..hide('draft-hana')
      ..hide('draft-safiya')
      ..block('draft-zainab');
    final h = harness(tester);
    await h.mount(tab: 4, pages: const ['settings'], model: model);
    await check(h, 'seeker_settings');
    await h.tap('concept_settings_hiddenProfiles');
    await check(h, 'hidden_blocked');
    await h.tap('privacy_unblock_draft-zainab');
    await check(h, 'unblock_confirm');
    await h.tap('privacy_keep_blocked');
    await tester.binding.handlePopRoute();
    await h.flush();
    await h.tap('concept_settings_appLock');
    await check(h, 'app_lock_off');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const auth = MethodChannel('plugins.flutter.io/local_auth');
    messenger.setMockMethodCallHandler(auth, (call) async {
      expect(call.method, 'authenticate');
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(auth, null));
    await tester.binding.handlePopRoute();
    await h.flush();
    final enabled = await tester.runAsync(
      () => ZyraAppLock.instance.setEnabled(true),
    );
    expect(enabled, isTrue);
    await h.tap('concept_settings_appLock');
    expect(find.text('LOCK AFTER LEAVING ZYRA'), findsOneWidget);
    await check(h, 'app_lock_on');
    await tester.runAsync(() => ZyraLocalPrefs.setAppLockEnabled(false));
    ZyraAppLock.instance.clearForSignOut();
    await tester.binding.handlePopRoute();
    await h.flush();
    await h.tap('concept_settings_signInSecurity');
    await check(h, 'sign_in_devices');
    await h.tap('privacy_sign_out_other_devices');
    expect(find.text('Only this phone is signed in.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await h.flush();
    await check(h, 'sign_in_one_device');
    await tester.binding.handlePopRoute();
    await h.flush();
    await h.tap('concept_settings_advanced');
    await check(h, 'seeker_advanced');
  });

  testWidgets('Guardian Settings and Advanced omit the Seeker break rule', (
    tester,
  ) async {
    final h = harness(tester);
    await h.mount(
      guardian: true,
      tab: 3,
      pages: const ['settings'],
      model: ViewRequestDraftModel(capacity: 3),
    );
    expect(find.text('Pause My Profile'), findsNothing);
    await check(h, 'guardian_settings');
    await h.tap('concept_settings_advanced');
    expect(find.text('After 6 months without opening ZYRA'), findsNothing);
    expect(find.text('After 2 years'), findsOneWidget);
    await check(h, 'guardian_advanced');
  });
}
