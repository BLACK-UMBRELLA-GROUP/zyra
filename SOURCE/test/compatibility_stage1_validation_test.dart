import 'package:flutter_test/flutter_test.dart';

import '../tools/compatibility_stage1/manifest.dart';
import '../tools/compatibility_stage1/models.dart';
import '../tools/compatibility_stage1/scorer.dart';
import '../tools/compatibility_stage1/validator.dart';
import 'support/compatibility_stage1_fixtures.dart';

void main() {
  final manifest = buildManifest();
  DirectionalInput fresh() => syntheticInput(manifest);
  ValidationOutcome validate(DirectionalInput input) =>
      validateDirectionalInputs(manifest, input);

  test(
    'complete synthetic direction is valid; raw inputs are not retained',
    () {
      final input = fresh();
      final result = validate(input) as ValidatedInputs;
      expect(result.units, isNotEmpty);
      expect(() => result.units.clear(), throwsUnsupportedError);
      expect(
        () => result.units.first.selectedLights.clear(),
        throwsUnsupportedError,
      );
    },
  );

  for (final own in [false, true]) {
    final expected = own
        ? isA<OwnerRepairRequired>()
        : isA<TargetUnavailable>();
    test(
      '${own ? 'owner' : 'target'} missing required or unknown answers fails',
      () {
        final input = fresh();
        final raw = own ? input.ownAnswers : input.targetAnswers;
        expect(
          validate(
            copyInput(
              input,
              ownAnswers: own ? raw.where((a) => a.key != 'ch3_q1') : null,
              targetAnswers: !own ? raw.where((a) => a.key != 'ch3_q1') : null,
            ),
          ),
          expected,
        );
        expect(
          validate(replaceAnswer(input, 'unknown-question', 'x', own: own)),
          expected,
        );
        expect(
          validate(replaceAnswer(input, 'ch3_q1', 'unknown-option', own: own)),
          expected,
        );
        expect(
          validate(replaceAnswer(input, 'ch3_q1', 123, own: own)),
          expected,
        );
        expect(
          validate(replaceAnswer(input, 'ch3_q1', ['Never Married'], own: own)),
          expected,
        );
      },
    );
    test(
      '${own ? 'owner' : 'target'} duplicates, empty multi and None conflicts fail',
      () {
        final input = fresh();
        final raw = own ? input.ownAnswers : input.targetAnswers;
        final duplicate = [...raw, raw.first];
        expect(
          validate(
            copyInput(
              input,
              ownAnswers: own ? duplicate : null,
              targetAnswers: !own ? duplicate : null,
            ),
          ),
          expected,
        );
        for (final key in ['ch3_q37', 'ch3_q97']) {
          final answer = manifest.answers.singleWhere((a) => a.key == key);
          final other = answer.options.firstWhere((o) => o != 'None');
          expect(
            validate(replaceAnswer(input, key, ['None', other], own: own)),
            expected,
          );
          expect(
            validate(replaceAnswer(input, key, [other, other], own: own)),
            expected,
          );
          expect(validate(replaceAnswer(input, key, [], own: own)), expected);
          expect(
            validate(replaceAnswer(input, key, [other, 1], own: own)),
            expected,
          );
          expect(
            validate(
              replaceAnswer(input, key, [
                other,
                'not-a-mapped-option',
              ], own: own),
            ),
            expected,
          );
          expect(
            validate(replaceAnswer(input, key, [other], own: own)),
            isA<ValidatedInputs>(),
          );
        }
      },
    );
  }

  test('target failure carries no private diagnostic or provisional score', () {
    final result = validate(
      replaceAnswer(fresh(), 'ch3_q1', 'private-corruption'),
    );
    expect(result.runtimeType, TargetUnavailable);
    expect(result, isNot(isA<ValidatedInputs>()));
  });

  test('complete required controls include unselected lights', () {
    final input = fresh();
    final pref = input.preferences.first;
    expect(
      validate(copyInput(input, preferences: input.preferences.skip(1))),
      isA<OwnerRepairRequired>(),
    );
    expect(
      validate(
        replacePreference(
          input,
          RawPreference(pref.id, pref.lights.take(pref.lights.length - 1)),
        ),
      ),
      isA<OwnerRepairRequired>(),
    );
    expect(
      validate(copyInput(input, preferences: [...input.preferences, pref])),
      isA<OwnerRepairRequired>(),
    );
    expect(
      validate(
        replacePreference(
          input,
          RawPreference(pref.id, [...pref.lights, pref.lights.first]),
        ),
      ),
      isA<OwnerRepairRequired>(),
    );
    expect(
      validate(
        replacePreference(input, RawPreference('pref:unknown', pref.lights)),
      ),
      isA<OwnerRepairRequired>(),
    );
    expect(
      validate(
        replacePreference(
          input,
          RawPreference(pref.id, [
            ...pref.lights.skip(1),
            const RawLight('unknown', 'red'),
          ]),
        ),
      ),
      isA<OwnerRepairRequired>(),
    );
    for (final invalid in [null, true, 0, 'yellow', 'GREEN', 'purple']) {
      final lights = [
        RawLight(pref.lights.first.option, invalid),
        ...pref.lights.skip(1),
      ];
      expect(
        validate(replacePreference(input, RawPreference(pref.id, lights))),
        isA<OwnerRepairRequired>(),
      );
    }
    expect(
      validate(
        replacePreference(
          input,
          RawPreference(pref.id, [
            const RawLight(12, 'green'),
            ...pref.lights.skip(1),
          ]),
        ),
      ),
      isA<OwnerRepairRequired>(),
    );
    expect(
      validate(
        replacePreference(
          input,
          RawPreference(pref.id, pref.lights, hards: ['unknown']),
        ),
      ),
      isA<OwnerRepairRequired>(),
    );
    expect(
      validate(
        replacePreference(
          input,
          RawPreference(
            pref.id,
            pref.lights,
            hards: [pref.lights.first.option, pref.lights.first.option],
          ),
        ),
      ),
      isA<OwnerRepairRequired>(),
    );
  });

  test(
    'an information-only answer does not acquire a hard or scoring control',
    () {
      final answer = manifest.answers.singleWhere((a) => a.key == 'ch3_q62');
      expect(answer.preferenceEligible, isFalse);
      final input = fresh();
      final unsupported = RawPreference(
        'pref:${answer.key}',
        [for (final option in answer.options) RawLight(option, 'red')],
        hards: [answer.options.first],
      );
      expect(
        validate(
          copyInput(input, preferences: [...input.preferences, unsupported]),
        ),
        isA<OwnerRepairRequired>(),
      );
    },
  );

  test(
    'Chapter2 duplicate fields/blocks/options and unknown keys fail before coercion',
    () {
      final input = fresh();
      expect(
        validate(
          copyInput(
            input,
            chapter2Answers: [
              ...input.chapter2Answers,
              input.chapter2Answers.first,
            ],
          ),
        ),
        isA<TargetUnavailable>(),
      );
      expect(
        validate(
          copyInput(
            input,
            chapter2Preferences: [
              ...input.chapter2Preferences,
              input.chapter2Preferences.first,
            ],
          ),
        ),
        isA<OwnerRepairRequired>(),
      );
      expect(
        validate(
          replaceChapter2(
            input,
            RawChapter2('revert', [
              const RawField('flexibility', 'green'),
              const RawField('flexibility', 'red'),
            ]),
          ),
        ),
        isA<OwnerRepairRequired>(),
      );
      expect(
        validate(
          replaceChapter2(
            input,
            RawChapter2('revert', [
              const RawField('flexibility', 'green'),
              const RawField('unknown-field', true),
            ]),
          ),
        ),
        isA<OwnerRepairRequired>(),
      );
      expect(
        validate(replaceChapter2Answer(input, 'languages', ['en', 'en'])),
        isA<TargetUnavailable>(),
      );
      expect(
        validate(
          replaceChapter2(
            input,
            RawChapter2('languages', [
              const RawField('preferred', ['ur', 'ur']),
              const RawField('skipped', false),
              const RawField('flexibility', 'green'),
            ]),
          ),
        ),
        isA<OwnerRepairRequired>(),
      );
    },
  );

  test(
    'complete directional fixtures produce zero or full alignment, not a neutral default',
    () {
      final positive =
          validate(syntheticInput(manifest, light: 'green')) as ValidatedInputs;
      final zero =
          validate(syntheticInput(manifest, light: 'red')) as ValidatedInputs;
      final a = calculateValidatedInputs(positive) as CalculatedContributions;
      final b = calculateValidatedInputs(zero) as CalculatedContributions;
      expect(a.overall, Fraction(1));
      expect(b.overall, Fraction(0));
      expect(a.total.available, b.total.available);
      expect(b.total.available.compareTo(Fraction(0)), greaterThan(0));
    },
  );

  test(
    'lossy representations and ambiguous counterpart variants fail closed',
    () {
      expect(
        validate(copyInput(fresh(), rawEntryEvidence: false)),
        isA<OwnerRepairRequired>(),
      );
      expect(
        validate(copyInput(fresh(), permittedPool: {})),
        isA<OwnerRepairRequired>(),
      );
      expect(
        validate(copyInput(fresh(), permittedPool: {Sex.male})),
        isA<OwnerRepairRequired>(),
      );
      expect(
        validate(
          syntheticInput(manifest, permittedPool: {Sex.male, Sex.female}),
        ),
        isA<OwnerRepairRequired>(),
      );
    },
  );

  test(
    'q26 hidden aliases cannot replace or coexist with the correct target variant',
    () {
      final input = fresh();
      final pref = input.preferences.singleWhere(
        (p) => p.id.contains('ch3_q26'),
      );
      expect(pref.id, 'pref:ch3_q26::female');
      expect(
        validate(
          copyInput(
            input,
            preferences: [
              ...input.preferences,
              RawPreference(
                'pref:ch3_q26::male',
                pref.lights,
                hards: [pref.lights.first.option],
              ),
            ],
          ),
        ),
        isA<OwnerRepairRequired>(),
      );
      expect(
        validate(replaceAnswer(input, 'ch3_q26', "I'm unsure")),
        isA<TargetUnavailable>(),
      );
      expect(
        validate(replaceAnswer(input, 'ch3_q26::male', "I'm unsure")),
        isA<TargetUnavailable>(),
      );
    },
  );

  for (final viewerChoice in ['Yes', 'No', 'If Allah wills', 'Unsure']) {
    for (final targetChoice in ['Yes', 'No', 'If Allah wills', 'Unsure']) {
      test(
        'q24 viewer=$viewerChoice target=$targetChoice uses target applicability',
        () {
          final input = syntheticInput(
            manifest,
            ownQ3: viewerChoice,
            targetQ3: targetChoice,
          );
          final result = validate(input) as ValidatedInputs;
          expect(input.preferences.any((p) => p.id == 'pref:ch3_q24'), isTrue);
          expect(
            result.units.any((u) => u.id == 'pref:ch3_q24'),
            targetChoice != 'No',
          );
        },
      );
    }
  }
  test(
    'q24 capture survives hards excluding all applicable parent branches',
    () {
      final input = syntheticInput(manifest, ownQ3: 'No', targetQ3: 'No');
      final q3 = input.preferences.singleWhere((p) => p.id == 'pref:ch3_q3');
      final hards = ['Yes', 'If Allah wills', 'Unsure'];
      final adjusted = replacePreference(
        input,
        RawPreference(q3.id, [
          for (final l in q3.lights)
            RawLight(l.option, hards.contains(l.option) ? 'red' : 'green'),
        ], hards: hards),
      );
      expect(adjusted.preferences.any((p) => p.id == 'pref:ch3_q24'), isTrue);
      expect(validate(adjusted), isA<ValidatedInputs>());
      expect(
        validate(
          copyInput(
            adjusted,
            preferences: adjusted.preferences.where(
              (p) => p.id != 'pref:ch3_q24',
            ),
          ),
        ),
        isA<OwnerRepairRequired>(),
      );
    },
  );
  test(
    'q24 missing/invalid parent is not a skip; stale hidden child is rejected',
    () {
      expect(
        validate(replaceAnswer(fresh(), 'ch3_q3', null)),
        isA<TargetUnavailable>(),
      );
      final input = fresh();
      expect(
        validate(
          copyInput(
            input,
            targetAnswers: input.targetAnswers.where((a) => a.key != 'ch3_q3'),
          ),
        ),
        isA<TargetUnavailable>(),
      );
      expect(
        validate(replaceAnswer(input, 'ch3_q3', 'No')),
        isA<TargetUnavailable>(),
      );
    },
  );
  test('q39 follows explicit male target pool, not viewer own visibility', () {
    final input = syntheticInput(
      manifest,
      viewerSex: Sex.female,
      targetSex: Sex.male,
    );
    expect(input.ownAnswers.any((a) => a.key == 'ch3_q39::male'), isFalse);
    expect(input.preferences.any((p) => p.id == 'pref:ch3_q39::male'), isTrue);
    expect(validate(input), isA<ValidatedInputs>());
    expect(
      validate(
        copyInput(
          input,
          preferences: input.preferences.where(
            (p) => p.id != 'pref:ch3_q39::male',
          ),
        ),
      ),
      isA<OwnerRepairRequired>(),
    );
  });

  test(
    'legacy amber review, version and structural checks remain independent',
    () {
      final input = fresh();
      final pref = input.preferences.first;
      expect(
        validate(
          replacePreference(
            input,
            RawPreference(pref.id, pref.lights, semantics: null),
          ),
        ),
        isA<ValidatedInputs>(),
      );
      for (final semantics in [legacySemantics, null, 'unknown-version']) {
        final legacy = RawPreference(pref.id, [
          for (final l in pref.lights) RawLight(l.option, 'amber'),
        ], semantics: semantics);
        expect(
          validate(replacePreference(input, legacy)),
          isA<OwnerRepairRequired>(),
        );
      }
      expect(
        validate(
          replacePreference(
            input,
            RawPreference(pref.id, pref.lights, semantics: 'unknown-version'),
          ),
        ),
        isA<OwnerRepairRequired>(),
      );
      for (final skipped in [true, false]) {
        expect(
          validate(
            replaceChapter2(
              input,
              RawChapter2('country_of_birth', [
                const RawField('preferred', <String>[]),
                RawField('skipped', skipped),
              ], semantics: 'unknown-version'),
            ),
          ),
          isA<OwnerRepairRequired>(),
        );
      }
    },
  );

  for (final semantics in [legacySemantics, null]) {
    test(
      'sect ${semantics ?? 'unversioned'} Amber outside flexibility needs owner review',
      () {
        final input = replaceChapter2(
          fresh(),
          RawChapter2('sect', [
            RawField('matrix', [
              for (final code in manifest.chapter2Vocabulary['sect']!)
                RawLight(code, 'green'),
            ]),
            const RawField('hard_requirement', <Object?>[]),
            const RawField('outside_flexibility', 'amber'),
          ], semantics: semantics),
        );
        final result = validate(input);
        expect(result, isA<OwnerRepairRequired>());
        expect(result, isNot(isA<ValidatedInputs>()));
      },
    );
  }

  test('configuration faults precede owner and target repair', () {
    final bad = Manifest(
      answers: manifest.answers,
      preferences: manifest.preferences,
      categories: [...manifest.categories, manifest.categories.first],
      chapter2Vocabulary: manifest.chapter2Vocabulary,
      bankProvenance: manifest.bankProvenance,
    );
    expect(
      validateDirectionalInputs(
        bad,
        replaceAnswer(fresh(), 'ch3_q1', null, own: true),
      ),
      isA<ConfigurationFailure>(),
    );
    final unmapped = Manifest(
      answers: manifest.answers,
      preferences: manifest.preferences,
      categories: manifest.categories.skip(1),
      chapter2Vocabulary: manifest.chapter2Vocabulary,
      bankProvenance: manifest.bankProvenance,
    );
    expect(
      validateDirectionalInputs(unmapped, fresh()),
      isA<ConfigurationFailure>(),
    );
    final wrongVersion = Manifest(
      answers: manifest.answers,
      preferences: manifest.preferences,
      categories: manifest.categories,
      chapter2Vocabulary: manifest.chapter2Vocabulary,
      bankProvenance: manifest.bankProvenance,
      version: 'unsupported',
    );
    expect(
      validateDirectionalInputs(wrongVersion, fresh()),
      isA<ConfigurationFailure>(),
    );
  });
}
