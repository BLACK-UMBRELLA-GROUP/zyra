import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const backupPaths = [
    'zyra_signup_draft.xml',
    'FlutterSecureKeyStorage:zyra_signup_draft.xml',
    'FlutterSecureStorageConfiguration:zyra_signup_draft.xml',
  ];

  test('signup draft native dependency is exactly pinned', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('flutter_secure_storage: 11.1.1'),
    );
  });

  test('Apple targets declare only their default Keychain group', () {
    for (final file in [
      'ios/Runner/Runner.entitlements',
      'macos/Runner/DebugProfile.entitlements',
      'macos/Runner/Release.entitlements',
    ]) {
      expect(
        RegExp(
          r'<key>keychain-access-groups</key>\s*<array\s*/>',
        ).hasMatch(File(file).readAsStringSync()),
        isTrue,
        reason: file,
      );
    }
  });

  test('Android manifest installs both generations of backup exclusions', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifest,
      contains('android:fullBackupContent="@xml/zyra_backup_rules"'),
    );
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/zyra_data_extraction_rules"'),
    );
  });

  test('encrypted data, wrapped keys and config cannot leave this device', () {
    final legacy = File(
      'android/app/src/main/res/xml/zyra_backup_rules.xml',
    ).readAsStringSync();
    final modern = File(
      'android/app/src/main/res/xml/zyra_data_extraction_rules.xml',
    ).readAsStringSync();
    for (final path in backupPaths) {
      final rule = '<exclude domain="sharedpref" path="$path" />';
      expect(rule.allMatches(legacy), hasLength(1));
      for (final transport in ['cloud-backup', 'device-transfer']) {
        final section = RegExp(
          '<$transport>([\\s\\S]*?)</$transport>',
        ).firstMatch(modern)!.group(1)!;
        expect(rule.allMatches(section), hasLength(1), reason: transport);
      }
    }
  });
}
