import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const retired = {
    'mock_purchase_wali_premium': '',
    'mock_set_wali_plan': 'text',
  };
  final sql = File(
    'supabase/migrations/'
    '20260923225150_retire_unused_legacy_purchase_mutators.sql',
  ).readAsStringSync().toLowerCase();

  test('retired test mutators deny every ordinary client role', () {
    for (final entry in retired.entries) {
      expect(
        sql,
        contains(
          'revoke execute on function public.${entry.key}'
          '(${entry.value})\n  from public, anon, authenticated;',
        ),
      );
    }
    expect(sql, contains('staged only'));
    expect(sql, isNot(contains('drop function')));
    expect(sql, isNot(contains('grant execute')));
  });

  test('no current Flutter RPC invokes retired test mutations', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final name in retired.keys) {
        final call = RegExp('rpc\\s*\\(\\s*[\'"]$name[\'"]');
        expect(call.hasMatch(source), isFalse, reason: '${file.path}: $name');
      }
    }
  });
}
