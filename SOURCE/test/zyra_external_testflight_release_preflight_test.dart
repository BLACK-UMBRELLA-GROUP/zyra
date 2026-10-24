import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('external review export is not restricted to internal TestFlight', () {
    final options = read('ios/TestFlightExternalExportOptions.plist');

    expect(options, contains('<string>app-store-connect</string>'));
    expect(options, contains('<string>9Y7Z8F36SJ</string>'));
    expect(options, isNot(contains('testFlightInternalTestingOnly')));
  });

  test('external review builder enables only the local review entry', () {
    final script = read('tool/build_external_review_ipa.sh');

    expect(script, contains('ZYRA_EXTERNAL_TESTER_ACCESS=true'));
    expect(script, contains('TestFlightExternalExportOptions.plist'));
    expect(script, isNot(contains('ZYRA_INTERNAL_FOUNDER_ACCESS=true')));
    expect(script, isNot(contains('ZYRA_INTERNAL_FOUNDER_UUID')));
  });
}
