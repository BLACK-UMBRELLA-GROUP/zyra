import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retired second-app server packages are outside active source', () {
    for (final path in const [
      'supabase/functions/zyra-founder-persona-session',
      'supabase/staging/founder_persona',
      'supabase/staging/dev_rpc_hardening',
    ]) {
      expect(Directory(path).existsSync(), isFalse, reason: path);
    }
  });

  test('retired persona packages have not entered active migrations', () {
    final migrations = Directory('supabase/migrations');
    expect(migrations.existsSync(), isTrue);
    final activeNames = migrations.listSync().map((entry) => entry.path);
    for (final path in activeNames) {
      expect(path, isNot(contains('founder_persona_security_boundary')));
      expect(path, isNot(contains('zyra_test_dev_rpc_security_overlay')));
    }
  });
}
