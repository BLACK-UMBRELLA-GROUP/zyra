import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/oa198_historical_inventory.dart';

const _historyRoot = '../SYSTEM/RESOURCES/MIGRATION_HISTORY';
const _artifactDir =
    '$_historyRoot/'
    'OA-ZYRA-198_2026-09-11_RECONSTRUCTED_PROBE_SCORE_REPLAY_BRIDGE';
const _bridgeFilename =
    '20260811233812_oa198_reconstructed_probe_score_replay_bridge.sql';
const _bridgePath = '$_artifactDir/$_bridgeFilename';
const _readmePath = '$_artifactDir/README.md';
const _manifestPath = '$_artifactDir/manifest.json';
const _runtimePath =
    'supabase/tests/'
    'zyra_oa198_probe_score_replay_bridge_pg17_runtime.sql';
const _testPath =
    'test/fixtures/oa198/zyra_oa198_probe_score_replay_bridge_artifact_test.dart.txt';
const _activeMigrationDir = 'supabase/migrations';
const _targetPath =
    '$_activeMigrationDir/'
    '20260811233813_oa186c_function_execute_hygiene_and_probe_rls.sql';
const _v2Path =
    '$_historyRoot/'
    'OA-ZYRA-198_2026-09-11_RECONSTRUCTED_REPLAY_BRIDGE_V2/'
    '20260811153415_oa198_reconstructed_question_bank_replay_bridge_v2.sql';

const _bridgeSha =
    '9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46';
const _runtimeSha =
    'bfbd13da58a12b9cacfdca79ab86f26b1484127171fb28e89106687547446997';
const _targetSha =
    '3934282f2b2d97c3bac7b6cac42c4044942d69c5a59111ffb2e672d360e73c95';
const _v2Sha =
    '337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1';
const _activeInventorySha =
    '8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861';

String _sha(File file) => sha256.convert(file.readAsBytesSync()).toString();

String _basename(String path) => path.split(Platform.pathSeparator).last;

String _activeInventoryDigest(List<File> files) {
  final sorted = [...files]
    ..sort(
      (left, right) => _basename(left.path).compareTo(_basename(right.path)),
    );
  final buffer = StringBuffer();
  for (final file in sorted) {
    buffer
      ..write(_sha(file))
      ..write('  ./')
      ..writeln(_basename(file.path));
  }
  return sha256.convert(utf8.encode(buffer.toString())).toString();
}

List<File> _activeMigrations() =>
    Directory(_activeMigrationDir)
        .listSync(followLinks: false)
        .whereType<File>()
        .where(
          (file) => RegExp(r'^\d{14}_.+\.sql$').hasMatch(_basename(file.path)),
        )
        .toList()
      ..sort(
        (left, right) => _basename(left.path).compareTo(_basename(right.path)),
      );

void main() {
  test('probe bridge is byte-pinned, quarantined and correctly ordered', () {
    final bridge = File(_bridgePath);
    final target = File(_targetPath);
    final v2 = File(_v2Path);
    final allActive = _activeMigrations();
    final active = oa198HistoricalInventory(allActive);
    expect(allActive.any((f) => _basename(f.path) == _bridgeFilename), isFalse);
    final activeNames = active.map((file) => _basename(file.path)).toSet();
    final scratchNames = {...activeNames, _basename(v2.path), _bridgeFilename};

    expect(bridge.existsSync(), isTrue);
    expect(bridge.lengthSync(), 7302);
    expect(_sha(bridge), _bridgeSha);
    expect(FileStat.statSync(bridge.path).mode & 0x1ff, 0x180);
    expect(_sha(target), _targetSha);
    expect(_sha(v2), _v2Sha);

    expect(active, hasLength(207));
    expect(_activeInventoryDigest(active), _activeInventorySha);
    expect(
      activeNames.any((name) => name.startsWith('20260811153415_')),
      false,
    );
    expect(
      activeNames.any((name) => name.startsWith('20260811233812_')),
      false,
    );
    expect(scratchNames, hasLength(209));

    final ordered = scratchNames.toList()..sort();
    expect(
      ordered.indexOf(
        '20260811233755_fix_duplicate_journey_ended_milestone.sql',
      ),
      lessThan(ordered.indexOf(_bridgeFilename)),
    );
    expect(
      ordered.indexOf(_bridgeFilename),
      lessThan(
        ordered.indexOf(
          '20260811233813_oa186c_function_execute_hygiene_and_probe_rls.sql',
        ),
      ),
    );
  });

  test(
    'bridge reconstructs only the catalog-proven schema and fails closed',
    () {
      final sql = File(_bridgePath).readAsStringSync();

      expect(sql, startsWith('-- OA-ZYRA-198 RECONSTRUCTED PROBE-SCORE'));
      expect(sql, endsWith('COMMIT;\n'));
      expect(sql, contains('NOT RETAINED PRODUCTION HISTORY — DO NOT APPLY'));
      expect(sql, contains("CURRENT_USER <> 'postgres'"));
      expect(sql, contains("version::text = '20260811233755'"));
      expect(sql, contains("version::text = '20260811233812'"));
      expect(sql, contains("version::text >= '20260811233813'"));
      expect(
        sql,
        contains("pg_catalog.to_regclass('public.zyra_probe_score')"),
      );
      expect(
        RegExp(
          r'CREATE TABLE public\.zyra_probe_score \(\s*'
          r'viewer text,\s*'
          r'rows_returned integer,\s*'
          r'score numeric\s*\);',
          multiLine: true,
        ).allMatches(sql),
        hasLength(1),
      );
      expect(RegExp(r'^\s*INSERT\b', multiLine: true).hasMatch(sql), false);
      expect(RegExp(r'^\s*GRANT\b', multiLine: true).hasMatch(sql), false);
      expect(RegExp(r'^\s*DROP\b', multiLine: true).hasMatch(sql), false);
      expect(sql, isNot(contains('IF NOT EXISTS')));
      expect(sql, isNot(contains('sxoaxonzjqkgajmlagyk')));
    },
  );

  test('runtime proof is pinned, read-only and covers post-target security', () {
    final runtime = File(_runtimePath);
    final sql = runtime.readAsStringSync();

    expect(runtime.existsSync(), isTrue);
    expect(runtime.lengthSync(), 4676);
    expect(_sha(runtime), _runtimeSha);
    expect(sql, contains(r'\set ON_ERROR_STOP on'));
    expect(sql, contains('BEGIN TRANSACTION READ ONLY;'));
    expect(sql, endsWith('ROLLBACK;\n'));
    expect(RegExp(r'^COMMIT;', multiLine: true).hasMatch(sql), false);
    expect(sql, contains("server_version_num')::integer < 170000"));
    expect(sql, contains('postgres|r|p|d|true|false'));
    expect(sql, contains("ARRAY['anon', 'authenticated']"));
    expect(sql, contains("'MAINTAIN'"));
    expect(sql, contains('OA-ZYRA-198 PROBE SCORE BRIDGE PG17 PASS'));
    expect(
      RegExp(
        r'^\s*(CREATE|ALTER|DROP|GRANT|REVOKE|INSERT|UPDATE|DELETE|TRUNCATE|COPY)\b',
        multiLine: true,
        caseSensitive: false,
      ).hasMatch(sql),
      false,
    );
  });

  test(
    'manifest records reconstruction evidence and preserves future gates',
    () {
      final manifest =
          jsonDecode(File(_manifestPath).readAsStringSync())
              as Map<String, dynamic>;
      final bridge = manifest['bridge'] as Map<String, dynamic>;
      final catalog =
          manifest['production_catalog_evidence'] as Map<String, dynamic>;
      final verification = manifest['verification'] as Map<String, dynamic>;
      final sideEffects = manifest['side_effects'] as Map<String, dynamic>;
      final futureGate = manifest['future_gate'] as Map<String, dynamic>;

      expect(
        manifest['artifact_id'],
        'OA-ZYRA-198-RECONSTRUCTED-PROBE-SCORE-REPLAY-BRIDGE-2026-09-11',
      );
      expect(
        manifest['status'],
        'CODEX_INTERNALLY_VERIFIED_REPLAY_NOT_AUTHORISED',
      );
      expect(bridge['sha256'], _bridgeSha);
      expect(bridge['bytes'], 7302);
      expect(bridge['ordering_version'], '20260811233812');
      expect(bridge['ordering_version_is_recovered_history'], false);
      expect(bridge['active_migration_path'], false);
      expect(catalog['access'], 'read_only_schema_and_count');
      expect(catalog['rows_copied_into_bridge'], 0);
      expect(catalog['live_row_count'], 2);
      expect(catalog['columns'], [
        {'name': 'viewer', 'type': 'text', 'nullable': true},
        {'name': 'rows_returned', 'type': 'integer', 'nullable': true},
        {'name': 'score', 'type': 'numeric', 'nullable': true},
      ]);
      expect(verification['runtime_sql_sha256'], _runtimeSha);
      expect(verification['artifact_test_sha256'], _sha(File(_testPath)));
      expect(verification['postgresql_server_version_num'], 170006);
      expect(verification['runtime_result'], 'PASS');
      expect(verification['full_209_file_replay_run'], false);
      expect(sideEffects['production_catalog_read_only_access'], true);
      expect(sideEffects['production_mutated'], false);
      expect(sideEffects['active_migration_path_changed'], false);
      expect(sideEffects['testflight_uploaded'], false);
      expect(sideEffects['git_used'], false);
      expect(sideEffects['private_credential_store_accessed'], false);
      expect(futureGate['separate_founder_one_replay_go_required'], true);
      expect(futureGate['production_apply_permitted'], false);

      final readme = File(_readmePath).readAsStringSync();
      for (final phrase in [
        'REPLAY NOT AUTHORISED',
        'PRODUCTION APPLY PROHIBITED',
        _bridgeSha,
        _runtimeSha,
        _targetSha,
        _v2Sha,
        'separate exact Founder one-replay GO',
      ]) {
        expect(readme, contains(phrase));
      }
    },
  );
}
