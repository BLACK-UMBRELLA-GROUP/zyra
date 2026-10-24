import 'package:flutter_test/flutter_test.dart';

import '../tools/compatibility_stage1/bank_adapter.dart';
import '../tools/compatibility_stage1/manifest.dart';
import '../tools/compatibility_stage1/models.dart';

void main() {
  group('Unwired Stage 1 canonical manifest', () {
    test(
      'accounts for all own answers, eligible topics and variant identities',
      () {
        final bank = readStaticBankSnapshot();
        final manifest = buildManifest(bank);
        expect(validateManifest(manifest), isNull);
        expect(bank.answers, hasLength(105));
        expect(bank.answers.map((answer) => answer.questionId).toSet(), {
          for (var number = 1; number <= 104; number++) 'ch3_q$number',
        });
        expect(
          bank.answers.map((answer) => answer.key).toSet(),
          hasLength(105),
        );
        final eligible = bank.answers.where(
          (answer) => answer.preferenceEligible,
        );
        expect(eligible, hasLength(72));
        expect(
          eligible.map((answer) => answer.questionId).toSet(),
          hasLength(71),
        );
        expect(manifest.preferences, hasLength(72));
        expect(
          manifest.preferences.map((control) => control.targetKey).toSet(),
          eligible.map((answer) => answer.key).toSet(),
        );
        expect(
          manifest.preferences.map((control) => control.id).toSet(),
          hasLength(72),
        );
        expect(
          manifest.preferences.every(
            (control) => control.semanticsVersion == futureSemantics,
          ),
          isTrue,
        );
        expect(
          manifest.bankProvenance,
          'sha256:5208df8f7315d5d4a29a890a57268700c2c5bcda88e4f8ec4e329c9a7394e52d',
        );
        expect(manifest.version, researchContract);
        expect(manifest.applicabilityVersion, researchApplicabilityVersion);
        expect(manifest.categoryMappingVersion, researchCategoryVersion);
        expect(manifest.hardRequirementVersion, researchHardVersion);
      },
    );

    test(
      'uses approved twelve-category order, with Culture last and unscored controls separate',
      () {
        final manifest = buildManifest();
        expect(manifest.categories, const [
          'deen_practice',
          'marriage_intentions',
          'children_parenting',
          'family_in_laws',
          'finances_provision',
          'education_career',
          'home_roles',
          'communication_conflict',
          'personality_connection',
          'lifestyle_wellbeing',
          'digital_boundaries',
          'culture_language',
        ]);
        expect(canonicalCategoryNames.values.toList(), const [
          'Deen & Islamic Practice',
          'Marriage Intentions & Structure',
          'Children & Parenting',
          'Family & In-Laws',
          'Finances & Provision',
          'Education, Career & Work',
          'Home Life & Household Roles',
          'Communication & Conflict',
          'Personality & Connection',
          'Lifestyle, Health & Well-being',
          'Digital Life, Privacy & Boundaries',
          'Culture & Language',
        ]);
        expect(chapter2ScoringCategories, const {
          'sect': 'deen_practice',
          'revert': 'deen_practice',
          'country_of_birth': 'culture_language',
          'nationality': 'culture_language',
          'ethnicity': 'culture_language',
          'languages': 'culture_language',
        });
        expect(unscoredChapter2Controls, const {
          'location',
          'sect.outside_flexibility',
        });
        expect(
          chapter2ScoringCategories.keys.toSet().intersection(
            unscoredChapter2Controls,
          ),
          isEmpty,
        );
        final mapped = canonicalOwnAnswerQuestionNumbers.values
            .expand((numbers) => numbers)
            .toList();
        expect(mapped, hasLength(104));
        expect(mapped.toSet(), {
          for (var number = 1; number <= 104; number++) number,
        });
      },
    );

    test(
      'reconciles per-category eligibility without creating information-only units',
      () {
        final manifest = buildManifest();
        const expected = {
          'deen_practice': 14,
          'marriage_intentions': 6,
          'children_parenting': 5,
          'family_in_laws': 6,
          'finances_provision': 9,
          'education_career': 4,
          'home_roles': 7,
          'communication_conflict': 4,
          'personality_connection': 2,
          'lifestyle_wellbeing': 10,
          'digital_boundaries': 4,
          'culture_language': 0,
        };
        for (final entry in expected.entries) {
          final eligibleIds = manifest.answers
              .where(
                (answer) =>
                    answer.preferenceEligible && answer.category == entry.key,
              )
              .map((answer) => answer.questionId)
              .toSet();
          expect(eligibleIds, hasLength(entry.value), reason: entry.key);
        }
        final informationOnly = manifest.answers
            .where((answer) => !answer.preferenceEligible)
            .toList();
        expect(informationOnly, hasLength(33));
        expect(
          informationOnly
              .map((answer) => answer.key)
              .toSet()
              .intersection(
                manifest.preferences
                    .map((control) => control.targetKey)
                    .toSet(),
              ),
          isEmpty,
        );
        for (final qid in ['ch3_q24', 'ch3_q37', 'ch3_q97']) {
          expect(
            manifest.preferences.any((control) => control.targetKey == qid),
            isTrue,
            reason: 'Historical optional classification does not omit $qid',
          );
        }
      },
    );

    test(
      'does not infer calculation ownership from source category labels or order',
      () {
        final baseline = readStaticBankSnapshot();
        final scrambled = BankSnapshot(
          answers: [
            for (final answer in baseline.answers.reversed)
              _copyAnswer(answer, category: 'untrusted-presentation-label'),
          ],
          chapter2Vocabulary: baseline.chapter2Vocabulary,
          provenance: baseline.provenance,
        );
        final manifest = buildManifest(scrambled);
        expect(validateManifest(manifest), isNull);
        expect(manifest.categories, canonicalCategoryIds);
        final ownership = {
          for (final answer in manifest.answers) answer.key: answer.category,
        };
        expect(ownership['ch3_q26::male'], 'marriage_intentions');
        expect(ownership['ch3_q26::female'], 'marriage_intentions');
        expect(ownership['ch3_q39::male'], 'deen_practice');
        expect(ownership['ch3_q24'], 'children_parenting');
        expect(ownership['ch3_q67'], 'finances_provision');
        expect(ownership['ch3_q97'], 'lifestyle_wellbeing');
        expect(ownership['ch3_q90'], 'digital_boundaries');
      },
    );

    test('deep-copies and seals bank, reference and control metadata', () {
      final registered = ['sunni', 'shia', 'ibadi'];
      final bank = readStaticBankSnapshot(registeredSectCodes: registered);
      registered.add('later-unregistered-code');
      expect(bank.chapter2Vocabulary['sect'], ['sunni', 'shia', 'ibadi']);
      final manifest = buildManifest(bank);
      expect(() => bank.answers.clear(), throwsUnsupportedError);
      expect(
        () => bank.answers.first.options[0] = 'changed',
        throwsUnsupportedError,
      );
      expect(
        () => bank.chapter2Vocabulary['sect']!.add('changed'),
        throwsUnsupportedError,
      );
      expect(
        () => bank.chapter2Vocabulary['new'] = ['changed'],
        throwsUnsupportedError,
      );
      expect(() => manifest.answers.clear(), throwsUnsupportedError);
      expect(
        () => manifest.preferences.first.options.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => manifest.preferences.first.targetPool.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => manifest.chapter2Vocabulary['languages']![0] = 'changed',
        throwsUnsupportedError,
      );
      expect(() => manifest.categories.clear(), throwsUnsupportedError);
      final fresh = readStaticBankSnapshot();
      expect(fresh.chapter2Vocabulary['sect'], ['sunni', 'shia']);
      expect(fresh.answers.first.options, bank.answers.first.options);
      expect(fresh.answers.first, isNot(same(bank.answers.first)));
      expect(manifest.answers.first, isNot(same(bank.answers.first)));
    });

    test(
      'registers canonical custom sect vocabulary without inventing a product universe',
      () {
        final standard = buildManifest();
        expect(standard.chapter2Vocabulary['sect'], const ['sunni', 'shia']);
        final research = buildManifest(
          readStaticBankSnapshot(
            registeredSectCodes: const ['sunni', 'shia', 'ibadi'],
          ),
        );
        expect(validateManifest(research), isNull);
        expect(research.chapter2Vocabulary['sect'], const [
          'sunni',
          'shia',
          'ibadi',
        ]);
        expect(standard.chapter2Vocabulary['sect'], isNot(contains('ibadi')));
        for (final registered in <List<String>>[
          [],
          ['shia'],
          ['sunni', 'shia', 'sunni'],
          ['sunni', 'shia', 'Ibadi'],
          ['sunni', 'shia', 'unknown code'],
          ['sunni', 'shia', '-sufi'],
        ]) {
          expect(
            validateManifest(
              buildManifest(
                readStaticBankSnapshot(registeredSectCodes: registered),
              ),
            ),
            isNotNull,
            reason: registered.toString(),
          );
        }
      },
    );

    test(
      'fails internal configuration on identities, targets, versions, mapping and dependency drift',
      () {
        final manifest = buildManifest();
        final first = manifest.preferences.first;
        final q24 = manifest.answers.singleWhere(
          (answer) => answer.key == 'ch3_q24',
        );
        final q37 = manifest.answers.singleWhere(
          (answer) => answer.key == 'ch3_q37',
        );
        final q39 = manifest.preferences.singleWhere(
          (control) => control.targetKey == 'ch3_q39::male',
        );
        final q24Control = manifest.preferences.singleWhere(
          (control) => control.targetKey == q24.key,
        );
        final alteredVocabulary = _replaceControl(
          _replaceAnswer(
            manifest,
            q24.key,
            _copyAnswer(q24, options: ['invented-option']),
          ),
          q24Control.id,
          _copyControl(q24Control, options: ['invented-option']),
        );
        final alteredHardCapability = _replaceControl(
          _replaceAnswer(
            manifest,
            q24.key,
            _copyAnswer(q24, hardSupported: false),
          ),
          q24Control.id,
          _copyControl(q24Control, hardSupported: false),
        );
        final cases = <String, Manifest>{
          'missing answer': _copyManifest(
            manifest,
            answers: manifest.answers.skip(1),
          ),
          'duplicate answer': _copyManifest(
            manifest,
            answers: [
              manifest.answers.first,
              ...manifest.answers.take(manifest.answers.length - 1),
            ],
          ),
          'unknown contract': _copyManifest(manifest, version: 'unsupported'),
          'unknown applicability version': _copyManifest(
            manifest,
            applicabilityVersion: 'unsupported',
          ),
          'unknown category version': _copyManifest(
            manifest,
            categoryMappingVersion: 'unsupported',
          ),
          'unknown hard version': _copyManifest(
            manifest,
            hardRequirementVersion: 'unsupported',
          ),
          'unverified bank': _copyManifest(manifest, provenance: 'unverified'),
          'missing category': _copyManifest(
            manifest,
            categories: manifest.categories.skip(1),
          ),
          'duplicate category': _copyManifest(
            manifest,
            categories: [
              manifest.categories.first,
              ...manifest.categories.take(manifest.categories.length - 1),
            ],
          ),
          'missing control': _copyManifest(
            manifest,
            preferences: manifest.preferences.skip(1),
          ),
          'duplicate control': _copyManifest(
            manifest,
            preferences: [first, ...manifest.preferences],
          ),
          'wrong control identity': _replaceControl(
            manifest,
            first.id,
            _copyControl(first, id: 'unknown-control'),
          ),
          'unscored target': _replaceControl(
            manifest,
            first.id,
            _copyControl(first, targetKey: 'ch3_q62'),
          ),
          'unmapped category': _replaceControl(
            manifest,
            first.id,
            _copyControl(first, category: 'not-mapped'),
          ),
          'wrong vocabulary': _replaceControl(
            manifest,
            first.id,
            _copyControl(first, options: ['invented-option']),
          ),
          'matching answer and control both differ from source vocabulary':
              alteredVocabulary,
          'matching answer and control both differ from source hard capability':
              alteredHardCapability,
          'wrong semantics': _replaceControl(
            manifest,
            first.id,
            _copyControl(first, semantics: legacySemantics),
          ),
          'wrong male pool': _replaceControl(
            manifest,
            q39.id,
            _copyControl(q39, pool: {Sex.female}),
          ),
          'wrong parent': _replaceAnswer(
            manifest,
            q24.key,
            _copyAnswer(q24, parentKey: 'ch3_q2'),
          ),
          'invented None rule': _replaceAnswer(
            manifest,
            q24.key,
            _copyAnswer(q24, exclusive: ['If Allah wills']),
          ),
          'missing None rule': _replaceAnswer(
            manifest,
            q37.key,
            _copyAnswer(q37, exclusive: []),
          ),
          'unknown reference codes': _copyManifest(
            manifest,
            vocabulary: {
              ...manifest.chapter2Vocabulary,
              'languages': ['zz'],
            },
          ),
        };
        for (final entry in cases.entries) {
          expect(validateManifest(entry.value), isNotNull, reason: entry.key);
        }
      },
    );
  });
}

Manifest _copyManifest(
  Manifest manifest, {
  Iterable<AnswerDefinition>? answers,
  Iterable<PreferenceDefinition>? preferences,
  Iterable<String>? categories,
  Map<String, List<String>>? vocabulary,
  String? version,
  String? provenance,
  String? applicabilityVersion,
  String? categoryMappingVersion,
  String? hardRequirementVersion,
}) => Manifest(
  answers: answers ?? manifest.answers,
  preferences: preferences ?? manifest.preferences,
  categories: categories ?? manifest.categories,
  chapter2Vocabulary: vocabulary ?? manifest.chapter2Vocabulary,
  bankProvenance: provenance ?? manifest.bankProvenance,
  version: version ?? manifest.version,
  applicabilityVersion: applicabilityVersion ?? manifest.applicabilityVersion,
  categoryMappingVersion:
      categoryMappingVersion ?? manifest.categoryMappingVersion,
  hardRequirementVersion:
      hardRequirementVersion ?? manifest.hardRequirementVersion,
);

AnswerDefinition _copyAnswer(
  AnswerDefinition answer, {
  String? category,
  String? parentKey,
  Iterable<String>? exclusive,
  Iterable<String>? options,
  bool? hardSupported,
}) => AnswerDefinition(
  key: answer.key,
  questionId: answer.questionId,
  variant: answer.variant,
  options: options ?? answer.options,
  selection: answer.selection,
  preferenceEligible: answer.preferenceEligible,
  hardSupported: hardSupported ?? answer.hardSupported,
  category: category ?? answer.category,
  parentKey: parentKey ?? answer.parentKey,
  hiddenForParentOptions: answer.hiddenForParentOptions,
  exclusiveOptions: exclusive ?? answer.exclusiveOptions,
);

PreferenceDefinition _copyControl(
  PreferenceDefinition control, {
  String? id,
  String? targetKey,
  String? category,
  Iterable<String>? options,
  Iterable<Sex>? pool,
  String? semantics,
  bool? hardSupported,
}) => PreferenceDefinition(
  id: id ?? control.id,
  targetKey: targetKey ?? control.targetKey,
  category: category ?? control.category,
  options: options ?? control.options,
  targetPool: pool ?? control.targetPool,
  hardSupported: hardSupported ?? control.hardSupported,
  semanticsVersion: semantics ?? control.semanticsVersion,
);

Manifest _replaceAnswer(
  Manifest manifest,
  String key,
  AnswerDefinition replacement,
) => _copyManifest(
  manifest,
  answers: [
    for (final answer in manifest.answers)
      answer.key == key ? replacement : answer,
  ],
);

Manifest _replaceControl(
  Manifest manifest,
  String id,
  PreferenceDefinition replacement,
) => _copyManifest(
  manifest,
  preferences: [
    for (final control in manifest.preferences)
      control.id == id ? replacement : control,
  ],
);
