// Actual Founder-shell renders with permission metadata mocked, never OS prompts.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'baseline_capture_support.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const evidence = '$root/REPORTS/EVIDENCE/LOCK12_PHONE_ACCESS_V2_2026-10-30';
const capture = bool.fromEnvironment('ZYRA_LOCK12_CAPTURE');
Finder k(String id) => find.byKey(ValueKey(id));
void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  final calls = <String>[];
  setUp(() {
    calls.clear();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraPhoneAccessChannel, (call) async {
          calls.add(call.method);
          return call.method == 'status'
              ? {
                  'location': 'allowed',
                  'notifications': 'allowed',
                  'photos': 'limited',
                  'camera': 'notDetermined',
                  'faceID': 'notDetermined',
                }
              : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraPhoneAccessChannel, null);
  });
  Future<BaselineHarness> mount(WidgetTester t, {bool guardian = false}) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final h = BaselineHarness(
      t,
      group: 'lock12_phone_access',
      outputRoot: '$root/PRODUCT/APPROVED/PHONE_ACCESS/BUILT',
      evidenceRoot: evidence,
      flatOutput: true,
    );
    await h.mount(guardian: guardian, tab: 4, pages: ['settings']);
    return h;
  }

  testWidgets(
    'Seeker Settings NEW opens real Phone access and clears receipt',
    (t) async {
      final h = await mount(t);
      expect(k('phone_access_new'), findsOneWidget);
      expect(find.text('Hidden Profiles'), findsOneWidget);
      expect(calls, isEmpty);
      if (capture) {
        await h.capture(
          'settings',
          'settings',
          'phone_access_row',
          'Actual Settings route; NEW not yet opened.',
          fileName: 'settings__phone_access_row.png',
        );
      }
      await h.tap('concept_settings_phoneAccess');
      h.assertPage('phone_access');
      expect(find.byType(ZyraPhoneAccessPresentation), findsOneWidget);
      expect(calls, everyElement('status'));
      expect(find.text('While using'), findsOneWidget);
      expect(find.text('Selected photos'), findsOneWidget);
      if (capture) {
        await h.capture(
          'settings',
          'phone_access',
          'normal',
          'Actual shell; mocked permissions as master. No native prompt.',
          fileName: 'phone_access__normal.png',
        );
      }
      await t.binding.handlePopRoute();
      await h.flush();
      h.assertPage('settings');
      expect(k('phone_access_new'), findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
      await h.flush();
    },
  );
  testWidgets(
    'Guardian keeps Privacy ordering and opens same permission page',
    (t) async {
      final h = await mount(t, guardian: true);
      expect(find.text('Guardian privacy'), findsOneWidget);
      expect(find.text('Hidden Profiles'), findsNothing);
      await h.tap('concept_settings_phoneAccess');
      h.assertPage('phone_access');
      expect(find.text('What ZYRA can use on this phone.'), findsOneWidget);
      expect(calls, everyElement('status'));
      await t.pumpWidget(const SizedBox.shrink());
      await h.flush();
    },
  );
  testWidgets(
    'covered retained row callback cannot request after controls roundtrip',
    (t) async {
      final h = await mount(t);
      await h.tap('concept_settings_phoneAccess');
      final old = t.widget<InkWell>(k('phone_access_camera')).onTap!;
      await openZyraDevControls(t);
      await closeZyraDevControls(t);
      calls.clear();
      old();
      await h.flush();
      expect(calls, isEmpty);
      await t.pumpWidget(const SizedBox.shrink());
      await h.flush();
    },
  );
  testWidgets(
    'small phone and Larger Text keep rows scrollable without overflow',
    (t) async {
      final h = await mount(t);
      await h.tap('concept_settings_phoneAccess');
      t.view.physicalSize = const Size(960, 1704);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pump();
      await t.ensureVisible(k('phone_access_faceID'));
      await h.flush();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await h.flush();
    },
  );
  test('locked purpose strings and protected Location/Add remain exact', () {
    final source = File(
      '$root/SOURCE/ios/Runner/Info.plist',
    ).readAsStringSync();
    for (final text in [
      'Scanning ZYRA Codes, taking photos and the identity check.',
      'Choosing your profile photos. ZYRA only sees the ones you pick.',
      'Opening ZYRA when App lock is on.',
      'Your approximate area is used to measure distance in Filters. It is never shown to anyone.',
      'ZYRA can save photos back to your library when you download them.',
    ]) {
      expect(source, contains(text));
    }
    for (final key in [
      'NSContactsUsageDescription',
      'NSMicrophoneUsageDescription',
      'NSUserTrackingUsageDescription',
      'NSLocationAlwaysUsageDescription',
      'NSLocationAlwaysAndWhenInUseUsageDescription',
    ]) {
      expect(source, isNot(contains(key)));
    }
    expect(
      source,
      contains('<key>NSLocationDefaultAccuracyReduced</key>\n\t<true/>'),
    );
  });
}
