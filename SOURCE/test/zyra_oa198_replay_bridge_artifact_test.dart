import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/oa198_historical_inventory.dart';

const _artifactDir =
    '../SYSTEM/RESOURCES/MIGRATION_HISTORY/'
    'OA-ZYRA-198_2026-09-11_RECONSTRUCTED_REPLAY_BRIDGE';
const _bridgeFilename =
    '20260811153415_oa198_reconstructed_question_bank_replay_bridge.sql';
const _bridgePath = '$_artifactDir/$_bridgeFilename';
const _manifestPath = '$_artifactDir/manifest.json';
const _readmePath = '$_artifactDir/README.md';
const _activeMigrationDir = 'supabase/migrations';
const _testPath = 'test/zyra_oa198_replay_bridge_artifact_test.dart';
const _historicalTestPath =
    'test/fixtures/oa198/zyra_oa198_replay_bridge_artifact_test.dart.txt';

const _bridgeSha256 =
    '461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055';
const _payloadSha256 =
    'eb355693f50651c7090aeaa5e7eb15187eb9a37855a785aaa259991cb1b43f90';
const _activeInventorySha256 =
    '8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861';
const _contractSha256 =
    'a929d23e5190ce238ef86a8786bdbaf0858337ae16a55cbf79572c6f2410850a';
const _laterNonScoredQids = <String>{
  'ch3_q10',
  'ch3_q17',
  'ch3_q19',
  'ch3_q21',
  'ch3_q27',
  'ch3_q32',
  'ch3_q41',
  'ch3_q42',
  'ch3_q45',
  'ch3_q58',
  'ch3_q59',
  'ch3_q62',
  'ch3_q69',
  'ch3_q76',
  'ch3_q77',
  'ch3_q79',
  'ch3_q80',
  'ch3_q82',
  'ch3_q83',
  'ch3_q88',
  'ch3_q89',
  'ch3_q91',
  'ch3_q92',
  'ch3_q93',
  'ch3_q94',
  'ch3_q96',
  'ch3_q98',
  'ch3_q99',
  'ch3_q100',
  'ch3_q101',
  'ch3_q102',
  'ch3_q103',
  'ch3_q104',
};

String _sha256Bytes(List<int> bytes) => sha256.convert(bytes).toString();

String _basename(String path) => path.split(Platform.pathSeparator).last;

String _bridgePayload(String sql) {
  const declaration = r'v_projection CONSTANT text := $oa198_rows$';
  const terminator = r'$oa198_rows$;';

  expect(r'$oa198_rows$'.allMatches(sql), hasLength(2));
  expect(declaration.allMatches(sql), hasLength(1));
  expect(terminator.allMatches(sql), hasLength(1));

  final start = sql.indexOf(declaration) + declaration.length;
  final end = sql.indexOf(terminator, start);
  expect(start, greaterThanOrEqualTo(declaration.length));
  expect(end, greaterThan(start));
  return sql.substring(start, end);
}

Object? _canonicalizeJson(Object? value) {
  if (value is List<dynamic>) {
    return value.map(_canonicalizeJson).toList(growable: false);
  }
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalizeJson(value[key]),
    };
  }
  return value;
}

String _activeInventoryDigest(List<File> files) {
  final sorted = [...files]
    ..sort(
      (left, right) => _basename(left.path).compareTo(_basename(right.path)),
    );
  final buffer = StringBuffer();
  for (final file in sorted) {
    buffer
      ..write(_sha256Bytes(file.readAsBytesSync()))
      ..write('  ./')
      ..writeln(_basename(file.path));
  }
  return _sha256Bytes(utf8.encode(buffer.toString()));
}

String _verbatimStatement(String source, String version) {
  final startMarker = '-- BEGIN VERBATIM LIVE STATEMENT $version\n';
  final endMarker = '\n-- END VERBATIM LIVE STATEMENT $version';
  expect(startMarker.allMatches(source), hasLength(1));
  expect(endMarker.allMatches(source), hasLength(1));
  final start = source.indexOf(startMarker) + startMarker.length;
  final end = source.indexOf(endMarker, start);
  return source.substring(start, end);
}

void main() {
  test('bridge is byte-pinned and quarantined outside active migrations', () {
    final bridge = File(_bridgePath);
    final bytes = bridge.readAsBytesSync();
    final artifactEntities = Directory(
      _artifactDir,
    ).listSync(followLinks: false);
    final artifactNames =
        artifactEntities.map((entity) => _basename(entity.path)).toList()
          ..sort();
    final allActiveFiles = Directory(_activeMigrationDir)
        .listSync()
        .whereType<File>()
        .where(
          (file) => RegExp(r'^\d{14}_.+\.sql$').hasMatch(_basename(file.path)),
        )
        .toList();
    final activeFiles = oa198HistoricalInventory(allActiveFiles);
    final activeNames = activeFiles.map((file) => _basename(file.path)).toSet();
    expect(
      allActiveFiles.any((f) => _basename(f.path) == _bridgeFilename),
      isFalse,
    );

    expect(
      FileSystemEntity.typeSync(_artifactDir, followLinks: false),
      FileSystemEntityType.directory,
    );
    expect(artifactNames, [_bridgeFilename, 'README.md', 'manifest.json']);
    for (final entity in artifactEntities) {
      expect(
        FileSystemEntity.typeSync(entity.path, followLinks: false),
        FileSystemEntityType.file,
      );
    }
    expect(bytes, hasLength(28387));
    expect(_sha256Bytes(bytes), _bridgeSha256);
    expect(activeFiles, hasLength(207));
    expect(activeNames, isNot(contains(_bridgeFilename)));
    expect(
      activeNames.any((name) => name.startsWith('20260811153415_')),
      isFalse,
    );
    expect(_activeInventoryDigest(activeFiles), _activeInventorySha256);

    final versions = activeNames
        .map((name) => name.substring(0, 14))
        .toList(growable: false);
    expect(versions.toSet(), hasLength(207));

    final scratchNames = {...activeNames, _bridgeFilename};
    expect(scratchNames, hasLength(208));
    expect(scratchNames.difference(activeNames), {_bridgeFilename});
  });

  test('embedded payload is the exact frozen scored reconstruction', () {
    final sql = File(_bridgePath).readAsStringSync();
    final payload = _bridgePayload(sql);
    final bytes = utf8.encode(payload);
    final decoded = jsonDecode(payload) as List<dynamic>;
    final rows = decoded.cast<Map<String, dynamic>>();

    expect(bytes, hasLength(12927));
    expect(_sha256Bytes(bytes), _payloadSha256);
    expect(rows, hasLength(72));
    expect(rows.map((row) => row['qid']).toSet(), hasLength(71));
    for (final row in rows) {
      expect(
        row.keys,
        orderedEquals(const [
          'gender_visibility',
          'is_multi',
          'options',
          'qid',
        ]),
      );
      expect(row['qid'], isA<String>());
      expect(row['gender_visibility'], isA<String>());
      expect(row['is_multi'], isA<bool>());
      expect(row['options'], isA<List<dynamic>>());
      final options = row['options']! as List<dynamic>;
      expect(options, isNotEmpty);
      expect(options, everyElement(isA<String>()));
    }
    final compositeKeys = <String>{};
    var previousQid = 0;
    var previousGender = '';
    for (final row in rows) {
      final qid = row['qid']! as String;
      final match = RegExp(r'^ch3_q([1-9][0-9]*)$').firstMatch(qid);
      expect(match, isNotNull);
      final numericQid = int.parse(match!.group(1)!);
      final gender = row['gender_visibility']! as String;
      expect(gender, isIn(const ['all', 'menOnly', 'womenOnly']));
      expect(
        numericQid > previousQid ||
            (numericQid == previousQid && gender.compareTo(previousGender) > 0),
        isTrue,
        reason: 'payload order at $qid/$gender',
      );
      expect(compositeKeys.add('$qid::$gender'), isTrue);
      previousQid = numericQid;
      previousGender = gender;
    }
    expect(compositeKeys, hasLength(72));

    final q26 = rows.where((row) => row['qid'] == 'ch3_q26').toList();
    expect(q26, hasLength(2));
    expect(q26.map((row) => row['gender_visibility']).toSet(), {
      'menOnly',
      'womenOnly',
    });
    expect(
      rows.where((row) => row['qid'] == 'ch3_q39').single['gender_visibility'],
      'menOnly',
    );
    expect(
      rows
          .where((row) => row['is_multi'] == true)
          .map((row) => row['qid'])
          .toSet(),
      {'ch3_q37', 'ch3_q97'},
    );

    final duplicateQids = <String>{
      for (final qid in rows.map((row) => row['qid']! as String).toSet())
        if (rows.where((row) => row['qid'] == qid).length > 1) qid,
    };
    expect(duplicateQids, {'ch3_q26'});
    expect(
      rows
          .map((row) => row['qid']! as String)
          .toSet()
          .intersection(_laterNonScoredQids),
      isEmpty,
    );

    expect(rows.any((row) => row['qid'] == 'ch3_q62'), isFalse);
  });

  test('SQL fails closed and contains no drift-hiding bootstrap', () {
    final sql = File(_bridgePath).readAsStringSync();
    final preflight = sql.indexOf(r'DO $oa198_preflight$');
    final permanentCreate = sql.indexOf(
      'CREATE TABLE public.zyra_seed_ch4_questions',
    );

    expect(
      sql,
      startsWith(
        '-- OA-ZYRA-198 RECONSTRUCTED REPLAY BRIDGE\n'
        '-- REPLAY-ONLY GOVERNED ARTIFACT',
      ),
    );
    expect(sql, isNot(contains('BEGIN VERBATIM LIVE STATEMENT')));
    expect(sql, isNot(contains('APPLIED-IN-REMOTE RECORD')));
    expect(RegExp(r'^BEGIN;$', multiLine: true).allMatches(sql), hasLength(1));
    expect(RegExp(r'^COMMIT;$', multiLine: true).allMatches(sql), hasLength(1));
    expect(preflight, greaterThanOrEqualTo(0));
    expect(permanentCreate, greaterThan(preflight));

    for (final guard in [
      "'supabase_migrations.schema_migrations'",
      "'public.zyra_seed_ch4_questions'",
      "'public.zyra_onboarding_questions'",
      "version::text = '20260811152809'",
      "version::text = '20260811153415'",
      "version::text >= '20260811153416'",
      "version::text > '20260811152809'",
      "version::text < '20260811153416'",
    ]) {
      expect(sql.indexOf(guard), inInclusiveRange(preflight, permanentCreate));
    }

    expect(sql, isNot(contains('CREATE TABLE IF NOT EXISTS')));
    expect(sql, isNot(contains('ON CONFLICT')));
    expect(
      RegExp(r'\bIF\s+NOT\s+EXISTS\b', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(sql, isNot(contains('CREATE POLICY')));
    expect(sql, isNot(contains('SECURITY DEFINER')));
    expect(sql, isNot(contains('CREATE FUNCTION')));
    expect(sql, isNot(contains('CREATE OR REPLACE FUNCTION')));
    expect(
      RegExp(
        r'^\s*GRANT\s',
        multiLine: true,
        caseSensitive: false,
      ).hasMatch(sql),
      isFalse,
    );
    expect(
      RegExp(
        r'^\s*SET\s+(ROLE|SESSION\s+AUTHORIZATION)',
        multiLine: true,
        caseSensitive: false,
      ).hasMatch(sql),
      isFalse,
    );
    expect(
      RegExp(
        r'^\s*(DROP|TRUNCATE|DELETE|UPDATE)\s',
        multiLine: true,
        caseSensitive: false,
      ).hasMatch(sql),
      isFalse,
    );
    expect(
      RegExp(
        r'^\s*CREATE\s+TABLE\s+public\.zyra_onboarding_questions',
        multiLine: true,
        caseSensitive: false,
      ).hasMatch(sql),
      isFalse,
    );
    expect(sql, isNot(contains('RENAME TO')));
    expect(sql, contains('IF v_current_count <> 0 THEN'));
    expect(
      sql,
      contains(
        "pg_catalog.sha256(pg_catalog.convert_to(v_projection, 'UTF8'))",
      ),
    );
    expect(sql, contains('EXCEPT ALL'));
  });

  test('SQL pins the minimal reconstructed catalog and security contract', () {
    final sql = File(_bridgePath).readAsStringSync();
    final createStart = sql.indexOf(
      'CREATE TABLE public.zyra_seed_ch4_questions',
    );
    final createEnd = sql.indexOf('\n);', createStart);
    final create = sql.substring(createStart, createEnd + 3);

    expect(
      create,
      contains(
        'qid text NOT NULL,\n'
        '  gender_visibility text NOT NULL,\n'
        '  is_multi boolean NOT NULL,\n'
        '  options jsonb NOT NULL,',
      ),
    );
    expect(
      create,
      contains(
        'CONSTRAINT zyra_seed_ch4_questions_pkey\n'
        '    PRIMARY KEY (qid, gender_visibility)',
      ),
    );
    expect(create, isNot(contains('DEFAULT')));
    expect(create, isNot(contains('CHECK')));
    expect(sql, isNot(contains('OWNER TO')));
    expect(sql, contains('v_owner IS DISTINCT FROM current_user::name'));
    expect(
      sql,
      contains(
        'ALTER TABLE public.zyra_seed_ch4_questions '
        'ENABLE ROW LEVEL SECURITY;',
      ),
    );
    expect(
      sql,
      contains(
        'ALTER TABLE public.zyra_seed_ch4_questions '
        'NO FORCE ROW LEVEL SECURITY;',
      ),
    );
    expect(
      sql,
      contains(
        'REVOKE ALL ON TABLE public.zyra_seed_ch4_questions FROM PUBLIC;',
      ),
    );
    expect(
      sql,
      contains('REVOKE ALL ON TABLE public.zyra_seed_ch4_questions FROM anon;'),
    );
    expect(
      sql,
      contains(
        'REVOKE ALL ON TABLE public.zyra_seed_ch4_questions '
        'FROM authenticated;',
      ),
    );
    expect(sql, contains('v_policy_count <> 0'));
    expect(sql, contains('v_constraint_count <> 1'));
    expect(sql, contains('v_index_count <> 1'));
    expect(sql, contains('acl.grantee <> class_row.relowner'));
    expect(sql, contains('v_column_acl_count <> 0'));
    expect(sql, contains('pg_catalog.has_table_privilege('));
    expect(sql, contains("('MAINTAIN'::text)"));
    expect(sql, contains('pg_catalog.has_column_privilege('));
  });

  test('manifest and README pin the artifact without claiming execution', () {
    final manifest =
        jsonDecode(File(_manifestPath).readAsStringSync())
            as Map<String, dynamic>;
    final bridge = manifest['bridge']! as Map<String, dynamic>;
    final readme = manifest['readme']! as Map<String, dynamic>;
    final payload = manifest['payload']! as Map<String, dynamic>;
    final activeInventory =
        manifest['active_inventory']! as Map<String, dynamic>;
    final chronology = manifest['chronology']! as Map<String, dynamic>;
    final catalog =
        manifest['reconstructed_catalog_contract']! as Map<String, dynamic>;
    final security = manifest['security_contract']! as Map<String, dynamic>;
    final verification = manifest['verification']! as Map<String, dynamic>;
    final sideEffects = manifest['side_effects']! as Map<String, dynamic>;
    final futureGate = manifest['future_gate']! as Map<String, dynamic>;
    final contractIdentity =
        manifest['contract_identity']! as Map<String, dynamic>;

    expect(
      manifest['classification'],
      contains('not retained production history'),
    );
    expect(manifest.containsKey('sha256'), isFalse);
    expect(
      manifest['status'],
      'CODEX_INTERNALLY_VERIFIED_REPLAY_NOT_AUTHORISED',
    );
    expect(bridge['active_migration_path'], isFalse);
    expect(bridge['ordering_version_is_recovered_history'], isFalse);
    expect(bridge['bytes'], File(_bridgePath).lengthSync());
    expect(bridge['sha256'], _sha256Bytes(File(_bridgePath).readAsBytesSync()));
    expect(readme['bytes'], File(_readmePath).lengthSync());
    expect(readme['sha256'], _sha256Bytes(File(_readmePath).readAsBytesSync()));
    expect(payload['bytes'], 12927);
    expect(payload['sha256'], _payloadSha256);
    expect(payload['rows'], 72);
    expect(payload['distinct_qids'], 71);
    expect(activeInventory['sql_files'], 207);
    expect(activeInventory['digest'], _activeInventorySha256);
    expect(
      activeInventory['contains_ordering_version_20260811153415'],
      isFalse,
    );
    expect(activeInventory['hypothetical_isolated_scratch_sql_files'], 208);
    expect(catalog['historical_claim'], isFalse);
    expect(catalog['persistent_checks'], isEmpty);
    expect(catalog['owner'], 'migration executor (current_user)');
    expect(catalog['historical_owner'], 'unknown');
    expect(security['rls_enabled'], isTrue);
    expect(security['force_rls'], isFalse);
    expect(security['policies'], 0);
    expect(security['postgresql_17_maintain_privilege_checked'], isTrue);
    final sourceEvidence = manifest['source_evidence']! as Map<String, dynamic>;
    expect(sourceEvidence['historical_ddl_recovered'], isFalse);
    expect(sourceEvidence['historical_catalog_recovered'], isFalse);
    expect(sourceEvidence['historical_acl_recovered'], isFalse);
    final archivedSource =
        sourceEvidence['archived_chapter3_categories']! as Map<String, dynamic>;
    final archivedModel =
        sourceEvidence['archived_onboarding_model']! as Map<String, dynamic>;
    expect(archivedSource['bytes'], 32290);
    expect(archivedSource['lines'], 681);
    expect(
      archivedSource['sha256'],
      '232cdf3e70f7e739fedda2a0004e57ffa346686347c86cc2b67e9c895a8677ce',
    );
    expect(
      archivedModel['sha256'],
      '0a87d252dc2f2b2895ea058defb92683949669f01dd9bee12ccc628c6bb525f4',
    );
    final predecessor = chronology['predecessor']! as Map<String, dynamic>;
    final successor = chronology['successor']! as Map<String, dynamic>;
    expect(
      predecessor['file_sha256'],
      '94799280bc9edd760bd1566e8b65dd79f6271a95bf32475c96edc9a4df9382bd',
    );
    expect(
      predecessor['retained_statement_sha256'],
      '38a2a20e810895d1975d4ec27eaea5db0cd03e78d3a114848171343bb2b16366',
    );
    expect(
      successor['file_sha256'],
      '832c4bdfcac2e622700458810768a995a058d7186933ea5fb6458ac4ac3f3d6d',
    );
    expect(
      successor['retained_statement_sha256'],
      '0f9022853b97fa328940e15296e885e917d83842ee19ff9d469ebef88e42fcfc',
    );
    final canonicalContract = jsonEncode(
      _canonicalizeJson(<String, dynamic>{
        'reconstructed_catalog_contract': catalog,
        'security_contract': security,
      }),
    );
    expect(_sha256Bytes(utf8.encode(canonicalContract)), _contractSha256);
    expect(contractIdentity['sha256'], _contractSha256);
    expect(verification['test_path'], 'SOURCE/$_testPath');
    expect(verification['test_bytes'], File(_historicalTestPath).lengthSync());
    expect(
      verification['test_sha256'],
      _sha256Bytes(File(_historicalTestPath).readAsBytesSync()),
    );
    expect(verification['tests_run'], isTrue);
    expect(verification['static_review_complete'], isTrue);
    expect(
      verification['database_execution_used_for_internal_verification'],
      isFalse,
    );
    expect(sideEffects.values, everyElement(isFalse));
    expect(futureGate['separate_founder_one_replay_go_required'], isTrue);
    expect(futureGate['production_apply_permitted'], isFalse);

    final readmeText = File(_readmePath).readAsStringSync();
    for (final phrase in [
      'REPLAY NOT AUTHORISED',
      'PRODUCTION APPLY PROHIBITED',
      'not recovered production history',
      'outside `SOURCE/supabase/migrations`',
      'separate exact Founder one-replay GO',
    ]) {
      expect(readmeText, contains(phrase));
    }
  });

  test('the eight exact retained migration bodies remain unchanged', () {
    const recoveries = <(String, String, String)>[
      (
        '20260811152220',
        '20260811152220_oa193_scoring_method_ratified_plain_count_two_scores.sql',
        '82fdc1d13db0564ddfa9aeeb09fde7eb3b0a509e678005536c17b03b703d24fa',
      ),
      (
        '20260811152255',
        '20260811152255_oa193_two_scores_plus_and_dev_functions.sql',
        '884de52af3e96ef92ce5427a9a8c69b7a0b4cb6257309e43f8a2140031cbc2ed',
      ),
      (
        '20260811152809',
        '20260811152809_score_candidates_null_array_guard.sql',
        '38a2a20e810895d1975d4ec27eaea5db0cd03e78d3a114848171343bb2b16366',
      ),
      (
        '20260811153416',
        '20260811153416_oa193c_onboarding_question_bank_and_completeness.sql',
        '0f9022853b97fa328940e15296e885e917d83842ee19ff9d469ebef88e42fcfc',
      ),
      (
        '20260811153547',
        '20260811153547_oa193c_materialise_onboarding_complete.sql',
        '0a4149339dfbddc7b18a1bbf9da59ff79ea8f5cf73c6a97607d65f47ad852f5f',
      ),
      (
        '20260811153643',
        '20260811153643_oa193c_enforce_the_gate.sql',
        'cc919cc511b71d3061dac6036687ad353cdb43fa39f33e6b9d6e3f4bfd2ac4cc',
      ),
      (
        '20260811172021',
        '20260811172021_fix_question_is_due_multi_variant_qid.sql',
        '88eb598aab415c90338ddbb0fa58d567ba36890830086e6995ccb024b1dc9671',
      ),
      (
        '20260811173212',
        '20260811173212_oa193c_bank_holds_all_104_chapter3_questions.sql',
        '2e814b5f9962429ca202721788c7a0ad1778b20e908ed5e1fda2603a89b3d558',
      ),
    ];

    for (final (version, filename, expectedSha) in recoveries) {
      final source = File('$_activeMigrationDir/$filename').readAsStringSync();
      expect(
        _sha256Bytes(utf8.encode(_verbatimStatement(source, version))),
        expectedSha,
        reason: version,
      );
    }
  });
}
