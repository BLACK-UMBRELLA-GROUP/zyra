import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _migrationDir = 'supabase/migrations';

String _verbatimStatement(String source, String version) {
  final startMarker = '-- BEGIN VERBATIM LIVE STATEMENT $version\n';
  final endMarker = '\n-- END VERBATIM LIVE STATEMENT $version';

  expect(startMarker.allMatches(source), hasLength(1));
  expect(endMarker.allMatches(source), hasLength(1));

  final start = source.indexOf(startMarker) + startMarker.length;
  final end = source.indexOf(endMarker, start);
  expect(start, greaterThanOrEqualTo(startMarker.length));
  expect(end, greaterThan(start));
  return source.substring(start, end);
}

void main() {
  final recoveries = <({String version, String filename, String sha256})>[
    (
      version: '20260811152220',
      filename:
          '20260811152220_oa193_scoring_method_ratified_plain_count_two_scores.sql',
      sha256:
          '82fdc1d13db0564ddfa9aeeb09fde7eb3b0a509e678005536c17b03b703d24fa',
    ),
    (
      version: '20260811152255',
      filename: '20260811152255_oa193_two_scores_plus_and_dev_functions.sql',
      sha256:
          '884de52af3e96ef92ce5427a9a8c69b7a0b4cb6257309e43f8a2140031cbc2ed',
    ),
    (
      version: '20260811152809',
      filename: '20260811152809_score_candidates_null_array_guard.sql',
      sha256:
          '38a2a20e810895d1975d4ec27eaea5db0cd03e78d3a114848171343bb2b16366',
    ),
    (
      version: '20260811153416',
      filename:
          '20260811153416_oa193c_onboarding_question_bank_and_completeness.sql',
      sha256:
          '0f9022853b97fa328940e15296e885e917d83842ee19ff9d469ebef88e42fcfc',
    ),
    (
      version: '20260811153547',
      filename: '20260811153547_oa193c_materialise_onboarding_complete.sql',
      sha256:
          '0a4149339dfbddc7b18a1bbf9da59ff79ea8f5cf73c6a97607d65f47ad852f5f',
    ),
    (
      version: '20260811153643',
      filename: '20260811153643_oa193c_enforce_the_gate.sql',
      sha256:
          'cc919cc511b71d3061dac6036687ad353cdb43fa39f33e6b9d6e3f4bfd2ac4cc',
    ),
    (
      version: '20260811172021',
      filename: '20260811172021_fix_question_is_due_multi_variant_qid.sql',
      sha256:
          '88eb598aab415c90338ddbb0fa58d567ba36890830086e6995ccb024b1dc9671',
    ),
    (
      version: '20260811173212',
      filename:
          '20260811173212_oa193c_bank_holds_all_104_chapter3_questions.sql',
      sha256:
          '2e814b5f9962429ca202721788c7a0ad1778b20e908ed5e1fda2603a89b3d558',
    ),
  ];

  for (final recovery in recoveries) {
    test('${recovery.version} preserves the exact retained live statement', () {
      final source = File(
        '$_migrationDir/${recovery.filename}',
      ).readAsStringSync();
      final body = _verbatimStatement(source, recovery.version);

      expect(source, isNot(contains('SELECT 1; -- applied-in-remote record')));
      expect(sha256.convert(utf8.encode(body)).toString(), recovery.sha256);
    });
  }

  test('recovered history creates the OA-ZYRA-283 prerequisites', () {
    final scoring = File(
      '$_migrationDir/${recoveries[0].filename}',
    ).readAsStringSync();
    final dependants = File(
      '$_migrationDir/${recoveries[1].filename}',
    ).readAsStringSync();

    expect(scoring, contains('ADD COLUMN IF NOT EXISTS seeker_a_score'));
    expect(scoring, contains('ADD COLUMN IF NOT EXISTS seeker_b_score'));
    expect(
      scoring,
      contains('CREATE OR REPLACE FUNCTION public.score_candidates'),
    );
    expect(dependants, contains('public.zyra_compatibility_for_plus'));
    expect(dependants, contains('public.zyra_dev_set_compatibility'));
  });

  test('the governed OA-ZYRA-198 frontier contains all eight recoveries', () {
    expect(recoveries.map((recovery) => recovery.version), <String>[
      '20260811152220',
      '20260811152255',
      '20260811152809',
      '20260811153416',
      '20260811153547',
      '20260811153643',
      '20260811172021',
      '20260811173212',
    ]);
  });
}
