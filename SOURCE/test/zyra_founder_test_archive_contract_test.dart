import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('separate Founder Test archive entrypoints are retired', () {
    for (final path in const [
      'tool/build_founder_test_ipa.sh',
      'tool/validate_founder_test_config.dart',
      'config/founder_test.public.json.example',
      'ios/ZYRATestInternalExportOptions.plist',
    ]) {
      expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound);
    }
  });

  test('main internal archive remains local, production, and explicit', () {
    final script = File(
      'tool/build_internal_founder_ipa.sh',
    ).readAsStringSync();

    expect(script, contains('flutter build ipa'));
    expect(script, contains('--no-pub --release --flavor production'));
    expect(script, contains('ZYRA_INTERNAL_FOUNDER_ACCESS=true'));
    expect(
      script,
      contains(
        'ZYRA_INTERNAL_FOUNDER_UUID='
        'dfcbd00d-bc22-4d6e-999b-3a9264cf3510',
      ),
    );
    expect(
      script,
      contains(
        '--export-options-plist=ios/TestFlightInternalExportOptions.plist',
      ),
    );
    expect(script, isNot(contains('foundertest')));
    expect(script, isNot(contains('ZYRATest')));
    expect(script, isNot(contains('altool')));
    expect(script, isNot(contains('notarytool')));
    expect(script, isNot(contains('iTMSTransporter')));
  });

  test('main internal export remains internal-only and export-only', () {
    final options = File(
      'ios/TestFlightInternalExportOptions.plist',
    ).readAsStringSync();

    expect(options, contains('<key>testFlightInternalTestingOnly</key>'));
    expect(options, contains('<true/>'));
    expect(
      options,
      contains('<key>destination</key>\n\t<string>export</string>'),
    );
    expect(options, isNot(contains('<string>upload</string>')));
  });

  test('iOS startup retains its pre-network native identity gate', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('await _verifyNativeIdentity();'));
    expect(
      source.indexOf('await _verifyNativeIdentity();'),
      lessThan(source.indexOf('Supabase.initialize(')),
    );
    expect(
      source,
      contains('_nativeIdentityAccepted && SupabaseConfig.isConfigured'),
    );
  });
}
