import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _historyRoot = '../REPORTS/EVIDENCE/OA-ZYRA-198_2026-09-11';
const _v1Dir =
    '$_historyRoot/OA-ZYRA-198_2026-09-11_RECONSTRUCTED_REPLAY_BRIDGE';
const _v2Dir =
    '$_historyRoot/OA-ZYRA-198_2026-09-11_RECONSTRUCTED_REPLAY_BRIDGE_V2';
const _v1Filename =
    '20260811153415_oa198_reconstructed_question_bank_replay_bridge.sql';
const _runtimePath =
    'supabase/tests/'
    'zyra_oa198_replay_bridge_v2_column_acl_pg17_runtime.sql';
const _testPath =
    'test/fixtures/oa198/zyra_oa198_replay_bridge_v2_artifact_test.dart.txt';
const _message081Path =
    '../REPORTS/ARCHIVE/MESSAGES_2026-08_TO_10/'
    '081_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_ONE_REPLAY_FIRST_RESULT_'
    'BRIDGE_ACL_POSTCONDITION_FAILED.md';
const _v1BridgeSha =
    '461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055';
const _v1ReadmeSha =
    'd883fe559f417d1ab8c5311cb7e521aeea1fdfe2b9262c0b7ef54567f5cbab21';
const _v1ManifestSha =
    '71678199bb76cf43d66f1d755f401767a72b209df1142cdf0dba77223d285c63';
const _v1TestSha =
    '11148da4d68ec8d63633a1a9db868b84451e65ebacc4810aa73bc9fb3b0bb975';
const _message081Sha =
    '05b7f682e59516308f80b3b6cc249d7c758db8bf8dba1566410314451d0a4b3b';
const _v2BridgeSha =
    '337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1';
const _runtimeSha =
    '745bb3295e909db6febd5609f46677b5dcaa99ec860cd1195925ac2002f5d35e';
const _contractSha =
    'a929d23e5190ce238ef86a8786bdbaf0858337ae16a55cbf79572c6f2410850a';
String _sha(File file) => sha256.convert(file.readAsBytesSync()).toString();

void main() {
  test('V1 bridge lineage remains byte-identical after the failed replay', () {
    final files = <String, (int, String)>{
      '$_v1Dir/$_v1Filename': (28387, _v1BridgeSha),
      '$_v1Dir/README.md': (5521, _v1ReadmeSha),
      '$_v1Dir/manifest.json': (7237, _v1ManifestSha),
      'test/fixtures/oa198/zyra_oa198_replay_bridge_artifact_test.dart.txt': (
        20192,
        _v1TestSha,
      ),
      _message081Path: (7748, _message081Sha),
    };

    for (final entry in files.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(file.lengthSync(), entry.value.$1, reason: entry.key);
      expect(_sha(file), entry.value.$2, reason: entry.key);
    }
  });

  test('PostgreSQL 17 runtime proof is pinned and read-only', () {
    final runtime = File(_runtimePath);
    final sql = runtime.readAsStringSync();

    expect(runtime.lengthSync(), 2929);
    expect(_sha(runtime), _runtimeSha);
    expect(sql, contains('BEGIN TRANSACTION READ ONLY;'));
    expect(sql, endsWith('ROLLBACK;\n'));
    expect(RegExp(r'^COMMIT;', multiLine: true).hasMatch(sql), isFalse);
    expect(sql, contains('server_version_num'));
    expect(sql, contains("pg_catalog.acldefault('c', v_owner)"));
    expect(sql, contains("'22023'"));
    expect(RegExp("WHEN SQLSTATE '22023'").allMatches(sql), hasLength(2));
    expect(sql, contains('\'{"empty":0,"nonempty":1,"null":0}\''));
    expect(sql, contains('OA-ZYRA-198 V2 PG17 COLUMN ACL PASS'));
    expect(
      RegExp(
        r'^\s*(CREATE|ALTER|DROP|GRANT|REVOKE|INSERT|UPDATE|DELETE|TRUNCATE|COPY)\b',
        multiLine: true,
        caseSensitive: false,
      ).hasMatch(sql),
      isFalse,
    );
  });

  test('V2 manifest and README pin the proof and preserve every gate', () {
    final manifestFile = File('$_v2Dir/manifest.json');
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final bridge = manifest['bridge'] as Map<String, dynamic>;
    final predecessor = manifest['predecessor'] as Map<String, dynamic>;
    final runtime = manifest['runtime_verification'] as Map<String, dynamic>;
    final verification = manifest['verification'] as Map<String, dynamic>;
    final sideEffects = manifest['side_effects'] as Map<String, dynamic>;
    final futureGate = manifest['future_gate'] as Map<String, dynamic>;

    expect(
      manifest['artifact_id'],
      'OA-ZYRA-198-RECONSTRUCTED-QUESTION-BANK-REPLAY-BRIDGE-V2-2026-09-11',
    );
    expect(
      manifest['status'],
      'CODEX_INTERNALLY_VERIFIED_REPLAY_NOT_AUTHORISED',
    );
    expect(bridge['sha256'], _v2BridgeSha);
    expect(bridge['bytes'], 28501);
    expect(bridge['active_migration_path'], isFalse);
    expect(bridge['change_scope'], 'column_acl_postcondition_only');
    expect(predecessor['sha256'], _v1BridgeSha);
    expect(
      predecessor['execution_status'],
      'EXECUTED_ONCE_REJECTED_SQLSTATE_22023',
    );
    expect(predecessor['founder_go_consumed'], isTrue);
    expect(predecessor['retry_permitted'], isFalse);
    expect(predecessor['immutable'], isTrue);
    expect(manifest['contract_identity_sha256'], _contractSha);
    expect(runtime['sql_sha256'], _runtimeSha);
    expect(
      runtime['database_execution_used_for_internal_verification'],
      isTrue,
    );
    expect(runtime['application_migrations_loaded'], isFalse);
    expect(runtime['production_accessed'], isFalse);
    expect(runtime['cases'], {'empty': 0, 'nonempty': 1, 'null': 0});
    expect(verification['bridge_executed_in_minimal_integration'], isTrue);
    expect(verification['full_208_file_replay_run'], isFalse);
    expect(verification['artifact_test_sha256'], _sha(File(_testPath)));
    expect(sideEffects['production_accessed'], isFalse);
    expect(sideEffects['production_applied'], isFalse);
    expect(sideEffects['testflight_uploaded'], isFalse);
    expect(sideEffects['git_write_index_or_history_operation_used'], isFalse);
    expect(sideEffects['read_only_git_status_used'], isTrue);
    expect(sideEffects['git_status_repository_state_change'], isFalse);
    expect(sideEffects['categorical_no_ai_git_rule_compliant'], isFalse);
    expect(futureGate['separate_founder_one_replay_go_required'], isTrue);
    expect(futureGate['production_apply_permitted'], isFalse);

    final readme = File('$_v2Dir/README.md').readAsStringSync();
    for (final phrase in [
      'V1 remains immutable',
      _v1BridgeSha,
      'SQLSTATE `22023`',
      'PostgreSQL 17 runtime PASS',
      'REPLAY NOT AUTHORISED',
      'PRODUCTION APPLY PROHIBITED',
      'separate exact Founder one-replay GO',
    ]) {
      expect(readme, contains(phrase));
    }
  });
}
