// Public source only: no Auth initialization, member values or log transport.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String file) =>
    File('lib/services/$file.dart').readAsStringSync();

String _diagnostic(String source, String operation) {
  final calls = RegExp(r'debugPrint\([\s\S]*?\);')
      .allMatches(source)
      .map((match) => match.group(0)!)
      .where((call) => call.contains(operation))
      .toList();
  expect(
    calls,
    hasLength(1),
    reason: 'Keep one bounded $operation diagnostic.',
  );
  return calls.single;
}

List<String> _interpolations(String call) => RegExp(
  r'\$(?:\{([^}]*)\}|([A-Za-z_]\w*))',
).allMatches(call).map((match) => match.group(1) ?? match.group(2)!).toList();

void main() {
  for (final operation in ['revokeInvite', 'declineInvite', 'previewInvite']) {
    test('$operation diagnostics exclude invite and exception contents', () {
      final call = _diagnostic(_source('zyra_wali_link_service'), operation);
      expect(_interpolations(call), ['e.runtimeType']);
      expect(call, isNot(contains('toString(')));
    });
  }

  for (final operation in [
    'zyra_reset_profile returned an unknown status',
    'setProfileComplete refused',
    'zyra_create_profile request completed',
  ]) {
    test('$operation diagnostics exclude RPC responses', () {
      final call = _diagnostic(_source('zyra_profile_service'), operation);
      expect(_interpolations(call), isEmpty);
      expect(call, isNot(contains('toString(')));
    });
  }

  final memberDiagnostics = <String, List<String>>{
    'no reference code for': ['field'],
    'no ISO code for country_of_birth': [],
    'no ISO code for nationality': [],
    'no ISO 639-1 code for language': [],
    'stored reference code has no label': [],
  };
  for (final entry in memberDiagnostics.entries) {
    test('${entry.key} diagnostics exclude member answers and codes', () {
      final call = _diagnostic(
        _source('zyra_seeker_details_service'),
        entry.key,
      );
      expect(_interpolations(call), entry.value);
      expect(call, isNot(contains('toString(')));
    });
  }
}
