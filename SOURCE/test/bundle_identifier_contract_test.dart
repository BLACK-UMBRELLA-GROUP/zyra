import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const canonicalId = 'app.zyraconnect.zyra';
  const canonicalTestId = '$canonicalId.RunnerTests';
  const canonicalIconChannel = '$canonicalId/app_icon';

  test('iOS Runner and RunnerTests use the canonical bundle identifiers', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(
      RegExp(
        'PRODUCT_BUNDLE_IDENTIFIER = ${RegExp.escape(canonicalId)};',
      ).allMatches(project),
      hasLength(3),
    );
    expect(
      RegExp(
        'PRODUCT_BUNDLE_IDENTIFIER = ${RegExp.escape(canonicalTestId)};',
      ).allMatches(project),
      hasLength(6),
    );
    expect(project, isNot(contains('$canonicalId.test')));
    expect(project, isNot(contains('foundertest')));
    expect(project, isNot(contains('ZYRATest')));
    expect(project, isNot(contains('com.shakeelahmed.zyraapp')));
    expect(project, isNot(contains('com.zyra.app')));

    final info = File('ios/Runner/Info.plist').readAsStringSync();
    expect(info, contains(r'$(PRODUCT_BUNDLE_IDENTIFIER)'));
    expect(info, contains(r'<string>$(APP_DISPLAY_NAME)</string>'));

    for (final mode in ['Debug', 'Profile', 'Release']) {
      final production = File(
        'ios/Flutter/$mode-production.xcconfig',
      ).readAsStringSync();
      expect(production, contains('APP_BUNDLE_NAME = ZYRA'));
      expect(production, contains('APP_DISPLAY_NAME = ZYRA'));
      expect(production, contains('PRODUCT_BUNDLE_IDENTIFIER = $canonicalId'));
      expect(
        File('ios/Flutter/$mode-foundertest.xcconfig').existsSync(),
        isFalse,
      );
    }
  });

  test('Android namespace, application ID and Activity package agree', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('namespace = "$canonicalId"'));
    expect(gradle, contains('applicationId = "$canonicalId"'));
    expect(gradle, isNot(contains('com.zyra.app')));

    final activity = File(
      'android/app/src/main/kotlin/app/zyraconnect/zyra/MainActivity.kt',
    );
    expect(activity.existsSync(), isTrue);
    expect(activity.readAsStringSync(), contains('package $canonicalId'));
    expect(
      File(
        'android/app/src/main/kotlin/com/example/app/MainActivity.kt',
      ).existsSync(),
      isFalse,
    );
  });

  test('native app-icon channel uses the canonical bundle identifier', () {
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(swift, contains('name: "$canonicalIconChannel"'));
    expect(swift, isNot(contains('com.shakeelahmed.zyraapp/app_icon')));
  });

  test('Google iOS client ID and reversed callback scheme stay paired', () {
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    final clientMatch = RegExp(
      r'<key>GIDClientID</key>\s*<string>([^<]+)</string>',
    ).firstMatch(info);
    final schemeMatch = RegExp(
      r'<key>CFBundleURLSchemes</key>\s*<array>\s*<string>([^<]+)</string>',
    ).firstMatch(info);

    expect(clientMatch, isNotNull);
    expect(schemeMatch, isNotNull);
    expect(clientMatch!.group(1), r'$(GOOGLE_IOS_CLIENT_ID)');
    expect(schemeMatch!.group(1), r'$(GOOGLE_IOS_URL_SCHEME)');

    const clientId =
        '734578322486-eoh5ba4usl0svs9ihqh2ltagqfgusnft.apps.googleusercontent.com';
    const callbackScheme =
        'com.googleusercontent.apps.734578322486-eoh5ba4usl0svs9ihqh2ltagqfgusnft';
    for (final mode in ['Debug', 'Profile', 'Release']) {
      final production = File(
        'ios/Flutter/$mode-production.xcconfig',
      ).readAsStringSync();
      expect(production, contains('GOOGLE_IOS_CLIENT_ID = $clientId'));
      expect(production, contains('GOOGLE_IOS_URL_SCHEME = $callbackScheme'));
    }
  });
}
