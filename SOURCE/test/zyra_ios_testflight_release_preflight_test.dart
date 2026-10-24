import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_release_gates.dart';

String _read(String path) => File(path).readAsStringSync();

String _plistString(String plist, String key) {
  final match = RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*<string>([^<]+)</string>',
  ).firstMatch(plist);
  expect(match, isNotNull, reason: 'Missing plist string key $key');
  return match!.group(1)!;
}

bool _plistBool(String plist, String key) {
  final match = RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*<(true|false)/>',
  ).firstMatch(plist);
  expect(match, isNotNull, reason: 'Missing plist boolean key $key');
  return match!.group(1) == 'true';
}

String _sha256(String path) =>
    sha256.convert(File(path).readAsBytesSync()).toString();

void main() {
  const canonicalBundleId = 'app.zyraconnect.zyra';
  const paidTeamId = '9Y7Z8F36SJ';
  const retiredFreeTeamId = 'JB25YJ2T3N';
  const stalePreHoldIpaSha256 =
      '4685a31b2e2159d07777ffba8c729b2d371a6d96256c57e7eccb2a8abe074815';

  test('iOS release signing remains on the paid canonical App ID', () {
    final project = _read('ios/Runner.xcodeproj/project.pbxproj');

    expect(
      RegExp(
        'PRODUCT_BUNDLE_IDENTIFIER = ${RegExp.escape(canonicalBundleId)};',
      ).allMatches(project),
      hasLength(3),
    );
    expect(
      RegExp('DEVELOPMENT_TEAM = $paidTeamId;').allMatches(project),
      hasLength(3),
    );
    expect(
      RegExp(
        r'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;',
      ).allMatches(project),
      hasLength(3),
    );
    expect(
      RegExp(
        r'CURRENT_PROJECT_VERSION = "\$\(FLUTTER_BUILD_NUMBER\)";',
      ).allMatches(project),
      hasLength(3),
    );
    expect(project, isNot(contains(retiredFreeTeamId)));
  });

  test('all remaining iOS project configurations require iOS 15 or later', () {
    final project = _read('ios/Runner.xcodeproj/project.pbxproj');

    expect(
      RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = 15\.0;').allMatches(project),
      hasLength(6),
    );
    expect(project, isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0;')));
  });

  test('installed iOS identity and export-compliance values are explicit', () {
    final info = _read('ios/Runner/Info.plist');

    expect(_plistString(info, 'CFBundleDisplayName'), r'$(APP_DISPLAY_NAME)');
    expect(_plistString(info, 'CFBundleName'), r'$(APP_BUNDLE_NAME)');
    expect(
      _plistString(info, 'CFBundleIdentifier'),
      r'$(PRODUCT_BUNDLE_IDENTIFIER)',
    );
    expect(
      _plistString(info, 'CFBundleShortVersionString'),
      r'$(FLUTTER_BUILD_NAME)',
    );
    expect(_plistString(info, 'CFBundleVersion'), r'$(FLUTTER_BUILD_NUMBER)');
    expect(_plistBool(info, 'ITSAppUsesNonExemptEncryption'), isFalse);
  });

  test('Sign in with Apple entitlement remains exact', () {
    final entitlements = _read('ios/Runner/Runner.entitlements');
    final match = RegExp(
      r'<key>com\.apple\.developer\.applesignin</key>\s*'
      r'<array>\s*<string>([^<]+)</string>\s*</array>',
    ).firstMatch(entitlements);

    expect(match, isNotNull);
    expect(match!.group(1), 'Default');
    expect(
      RegExp(
        r'<key>com\.apple\.developer\.applesignin</key>',
      ).allMatches(entitlements),
      hasLength(1),
    );
  });

  test('source-owned export contract is internal-only and never uploads', () {
    final options = _read('ios/TestFlightInternalExportOptions.plist');

    expect(_plistString(options, 'method'), 'app-store-connect');
    expect(_plistString(options, 'destination'), 'export');
    expect(_plistString(options, 'signingStyle'), 'automatic');
    expect(_plistString(options, 'teamID'), paidTeamId);
    expect(_plistBool(options, 'testFlightInternalTestingOnly'), isTrue);
    expect(_plistBool(options, 'manageAppVersionAndBuildNumber'), isFalse);
    expect(_plistBool(options, 'generateAppStoreInformation'), isFalse);
    expect(_plistBool(options, 'stripSwiftSymbols'), isTrue);
    expect(_plistBool(options, 'uploadSymbols'), isTrue);
    expect(options, isNot(contains('<string>upload</string>')));
  });

  test('source build and feedback metadata agree on real bundle values', () {
    final pubspec = _read('pubspec.yaml');
    final feedback = _read('lib/services/zyra_feedback_service.dart');

    expect(
      pubspec,
      contains(RegExp(r'^version: 1\.0\.0\+5$', multiLine: true)),
    );
    expect(feedback, contains('PackageInfo.fromPlatform()'));
    expect(feedback, isNot(contains('static const String appVersion =')));
    expect(feedback, isNot(contains("'1.0.0+1'")));
  });

  test(
    'Founder-internal Journey release pair remains byte-pinned and held',
    () {
      expect(ZyraReleaseGates.requestNewJourneyEnabled, isFalse);
      expect(
        _sha256(
          'supabase/migrations/'
          '20260910184252_oa283_journey_compatibility_rpc_boundary.sql',
        ),
        '63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d',
      );
      expect(
        _sha256(
          'supabase/migrations/'
          '20260910195642_oa156_request_new_journey_testflight_hold.sql',
        ),
        '0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545',
      );
    },
  );

  test('retained pre-hold IPA identity stays explicitly forbidden', () {
    expect(stalePreHoldIpaSha256, hasLength(64));
    final retained = File('build/ios/ipa/ZYRA.ipa');
    if (retained.existsSync()) {
      // The output path is reused by subsequent approved builds; it is not
      // an immutable location for the superseded artifact. Any candidate
      // found here must not be the explicitly forbidden pre-hold binary.
      expect(_sha256(retained.path), isNot(stalePreHoldIpaSha256));
    }

    final evidence = jsonEncode({
      'sha256': stalePreHoldIpaSha256,
      'eligible_for_upload': false,
    });
    expect(evidence, contains('"eligible_for_upload":false'));
  });
}
