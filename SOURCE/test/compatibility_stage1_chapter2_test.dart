import 'package:flutter_test/flutter_test.dart';

import '../tools/compatibility_stage1/bank_adapter.dart';
import '../tools/compatibility_stage1/manifest.dart';
import '../tools/compatibility_stage1/models.dart';
import '../tools/compatibility_stage1/scorer.dart';
import '../tools/compatibility_stage1/validator.dart';
import 'support/compatibility_stage1_fixtures.dart';
import 'support/compatibility_stage1_oracle.dart' as oracle;

RawChapter2 _sect(
  Manifest manifest, {
  String light = 'green',
  List<Object?> hards = const [],
  Object? outside = 'green',
}) => RawChapter2('sect', [
  RawField('matrix', <RawLight>[
    for (final code in manifest.chapter2Vocabulary['sect']!)
      RawLight(code, light),
  ]),
  RawField('hard_requirement', hards),
  RawField('outside_flexibility', outside),
]);

RawChapter2 _listBlock(
  String key, {
  List<String> preferred = const [],
  bool skipped = false,
  String? flexibility,
}) => RawChapter2(key, [
  RawField('preferred', preferred),
  RawField('skipped', skipped),
  if (flexibility != null) RawField('flexibility', flexibility),
]);

ValidatedInputs _validated(Manifest manifest, DirectionalInput input) {
  final outcome = validateDirectionalInputs(manifest, input);
  expect(
    outcome,
    isA<ValidatedInputs>(),
    reason:
        'Complete synthetic fixture must validate before arithmetic; '
        'got ${outcome.runtimeType}',
  );
  return outcome as ValidatedInputs;
}

void _expectFraction(Fraction actual, oracle.OracleRational expected) {
  expect(actual.numerator, BigInt.from(expected.numerator));
  expect(actual.denominator, BigInt.from(expected.denominator));
}

void _expectUnit(
  Manifest manifest,
  DirectionalInput input,
  String key,
  Light light,
  String category,
) {
  // The whole bank is validated first. Only then is this explicitly labelled
  // component projection used to check one Chapter2 branch's raw arithmetic.
  final validated = _validated(manifest, input);
  final units = validated.units.where((unit) => unit.id == 'ch2:$key').toList();
  expect(units, hasLength(1));
  expect(units.single.category, category);
  expect(units.single.selectedLights, [light]);
  final result =
      calculateValidatedInputs(ValidatedInputs(units, validated.categories))
          as CalculatedContributions;
  final expected = switch (light) {
    Light.green => oracle.chapter2Green,
    Light.amber => oracle.chapter2Amber,
    Light.red => oracle.chapter2Red,
  };
  _expectFraction(result.total.earned, expected.earned);
  expect(result.total.available, Fraction(expected.available));
  _expectFraction(result.overall, expected.overall);
}

void _expectNoUnit(Manifest manifest, DirectionalInput input, String key) {
  final validated = _validated(manifest, input);
  final units = validated.units.where((unit) => unit.id == 'ch2:$key').toList();
  expect(units, isEmpty);
  expect(
    calculateValidatedInputs(ValidatedInputs(units, validated.categories)),
    isA<NoScoreableData>(),
  );
}

void main() {
  late Manifest manifest;
  late DirectionalInput base;

  setUp(() {
    manifest = buildManifest();
    base = syntheticInput(manifest);
  });

  group('synthetic whole-bank Chapter2 baseline and canonical sect', () {
    test('default fixture validates; only sect contributes from Chapter2', () {
      final validated = _validated(manifest, base);
      expect(
        validated.units
            .where((unit) => unit.id.startsWith('ch2:'))
            .map((unit) => unit.id),
        ['ch2:sect'],
      );
      _expectUnit(manifest, base, 'sect', Light.green, 'deen_practice');
    });

    for (final light in ['green', 'amber', 'red']) {
      test('sect $light is one provisional unit without a hard', () {
        final input = replaceChapter2(base, _sect(manifest, light: light));
        _expectUnit(
          manifest,
          input,
          'sect',
          parseLight(light)!,
          'deen_practice',
        );
      });
    }

    test('sect hard veto is separate from a green soft contribution', () {
      final input = replaceChapter2(
        base,
        _sect(manifest, light: 'green', hards: ['sunni']),
      );
      expect(validateDirectionalInputs(manifest, input), isA<HardExcluded>());
    });

    test('hard for another registered sect does not veto this target', () {
      final input = replaceChapter2(base, _sect(manifest, hards: ['shia']));
      _expectUnit(manifest, input, 'sect', Light.green, 'deen_practice');
    });

    test('explicit custom registry code works with a complete matrix', () {
      final custom = buildManifest(
        readStaticBankSnapshot(registeredSectCodes: ['sunni', 'shia', 'ibadi']),
      );
      final input = replaceChapter2Answer(
        syntheticInput(custom),
        'sect',
        'ibadi',
      );
      _expectUnit(custom, input, 'sect', Light.green, 'deen_practice');
    });

    test('unregistered canonical target code is generically unavailable', () {
      final input = replaceChapter2Answer(base, 'sect', 'ibadi');
      expect(
        validateDirectionalInputs(manifest, input),
        isA<TargetUnavailable>(),
      );
    });

    test('display label is not silently translated into a canonical code', () {
      final input = replaceChapter2Answer(base, 'sect', 'Sunni');
      expect(
        validateDirectionalInputs(manifest, input),
        isA<TargetUnavailable>(),
      );
    });

    test(
      'every registered sect needs a matrix light, even if not selected',
      () {
        final custom = buildManifest(
          readStaticBankSnapshot(
            registeredSectCodes: ['sunni', 'shia', 'ibadi'],
          ),
        );
        final input = replaceChapter2(
          syntheticInput(custom),
          RawChapter2('sect', [
            RawField('matrix', <RawLight>[
              RawLight('sunni', 'green'),
              RawLight('shia', 'green'),
            ]),
            RawField('hard_requirement', <Object?>[]),
          ]),
        );
        expect(
          validateDirectionalInputs(custom, input),
          isA<OwnerRepairRequired>(),
        );
      },
    );

    test(
      'outside flexibility never supplies a missing registered matrix light',
      () {
        final input = replaceChapter2(
          base,
          RawChapter2('sect', [
            RawField('matrix', <RawLight>[RawLight('shia', 'green')]),
            RawField('hard_requirement', <Object?>[]),
            RawField('outside_flexibility', 'green'),
          ]),
        );
        expect(
          validateDirectionalInputs(manifest, input),
          isA<OwnerRepairRequired>(),
        );
      },
    );
  });

  group('revert is conditional but captured evidence is required', () {
    test('valid target false contributes no revert unit', () {
      _expectNoUnit(
        manifest,
        replaceChapter2Answer(base, 'revert', false),
        'revert',
      );
    });

    for (final light in ['green', 'amber', 'red']) {
      test('valid target true uses $light flexibility as one Deen unit', () {
        var input = replaceChapter2Answer(base, 'revert', true);
        input = replaceChapter2(
          input,
          RawChapter2('revert', [RawField('flexibility', light)]),
        );
        _expectUnit(
          manifest,
          input,
          'revert',
          parseLight(light)!,
          'deen_practice',
        );
      });
    }

    test('missing revert is unavailable, not false', () {
      final input = copyInput(
        base,
        chapter2Answers: base.chapter2Answers.where(
          (field) => field.key != 'revert',
        ),
      );
      expect(
        validateDirectionalInputs(manifest, input),
        isA<TargetUnavailable>(),
      );
    });

    for (final raw in [null, 'false', 0, <Object?>[]]) {
      test(
        'invalid target revert $raw is unavailable, not a valid exclusion',
        () {
          final input = replaceChapter2Answer(base, 'revert', raw);
          expect(
            validateDirectionalInputs(manifest, input),
            isA<TargetUnavailable>(),
          );
        },
      );
    }

    test('missing owner revert light fails even when target false', () {
      final input = replaceChapter2(base, RawChapter2('revert', []));
      expect(
        validateDirectionalInputs(manifest, input),
        isA<OwnerRepairRequired>(),
      );
    });
  });

  group(
    'birth, nationality and ethnicity preserve match/flexibility conditions',
    () {
      for (final key in ['country_of_birth', 'nationality', 'ethnicity']) {
        for (final light in ['green', 'amber', 'red']) {
          test('$key match is green even with $light outside flexibility', () {
            final target =
                base.chapter2Answers.singleWhere((f) => f.key == key).value
                    as String;
            final input = replaceChapter2(
              base,
              _listBlock(key, preferred: [target], flexibility: light),
            );
            _expectUnit(manifest, input, key, Light.green, 'culture_language');
          });

          test('$key mismatch uses $light flexibility as one Culture unit', () {
            final target =
                base.chapter2Answers.singleWhere((f) => f.key == key).value
                    as String;
            final other = manifest.chapter2Vocabulary[key]!.firstWhere(
              (code) => code != target,
            );
            final input = replaceChapter2(
              base,
              _listBlock(key, preferred: [other], flexibility: light),
            );
            _expectUnit(
              manifest,
              input,
              key,
              parseLight(light)!,
              'culture_language',
            );
          });
        }

        test('$key explicit skipped state adds no unit', () {
          _expectNoUnit(
            manifest,
            replaceChapter2(base, _listBlock(key, skipped: true)),
            key,
          );
        });

        test('$key explicit empty preferred/no-preference adds no unit', () {
          _expectNoUnit(manifest, replaceChapter2(base, _listBlock(key)), key);
        });

        test('$key missing skipped evidence is corruption, not false', () {
          final input = replaceChapter2(
            base,
            RawChapter2(key, [RawField('preferred', <String>[])]),
          );
          expect(
            validateDirectionalInputs(manifest, input),
            isA<OwnerRepairRequired>(),
          );
        });

        test(
          '$key contradictory skip plus selection is not silently pruned',
          () {
            final selected = manifest.chapter2Vocabulary[key]!.first;
            final input = replaceChapter2(
              base,
              _listBlock(key, preferred: [selected], skipped: true),
            );
            expect(
              validateDirectionalInputs(manifest, input),
              isA<OwnerRepairRequired>(),
            );
          },
        );

        test('$key active nonempty preference requires flexibility', () {
          final selected = manifest.chapter2Vocabulary[key]!.first;
          final input = replaceChapter2(
            base,
            _listBlock(key, preferred: [selected]),
          );
          expect(
            validateDirectionalInputs(manifest, input),
            isA<OwnerRepairRequired>(),
          );
        });
      }
    },
  );

  group(
    'languages use any non-English overlap, never per-language weighting',
    () {
      test('English-only preference is a governed non-contributing state', () {
        final input = replaceChapter2(
          base,
          _listBlock('languages', preferred: ['en'], flexibility: 'red'),
        );
        _expectNoUnit(manifest, input, 'languages');
      });

      test(
        'empty no-preference and explicit skip both add no language unit',
        () {
          _expectNoUnit(
            manifest,
            replaceChapter2(base, _listBlock('languages')),
            'languages',
          );
          _expectNoUnit(
            manifest,
            replaceChapter2(base, _listBlock('languages', skipped: true)),
            'languages',
          );
        },
      );

      test(
        'one non-English overlap gives one green unit despite other misses',
        () {
          var input = replaceChapter2Answer(base, 'languages', ['en', 'ur']);
          input = replaceChapter2(
            input,
            _listBlock(
              'languages',
              preferred: ['en', 'ar', 'ur'],
              flexibility: 'red',
            ),
          );
          _expectUnit(
            manifest,
            input,
            'languages',
            Light.green,
            'culture_language',
          );
        },
      );

      for (final light in ['green', 'amber', 'red']) {
        test('no non-English overlap uses $light flexibility once', () {
          var input = replaceChapter2Answer(base, 'languages', ['en']);
          input = replaceChapter2(
            input,
            _listBlock(
              'languages',
              preferred: ['en', 'ur'],
              flexibility: light,
            ),
          );
          _expectUnit(
            manifest,
            input,
            'languages',
            parseLight(light)!,
            'culture_language',
          );
        });
      }

      test(
        'missing or empty target languages are not English-only exclusion',
        () {
          final missing = copyInput(
            base,
            chapter2Answers: base.chapter2Answers.where(
              (field) => field.key != 'languages',
            ),
          );
          expect(
            validateDirectionalInputs(manifest, missing),
            isA<TargetUnavailable>(),
          );
          expect(
            validateDirectionalInputs(
              manifest,
              replaceChapter2Answer(base, 'languages', <String>[]),
            ),
            isA<TargetUnavailable>(),
          );
        },
      );
    },
  );

  group('whole-bank Chapter2 validation and raw category reconstruction', () {
    for (final key in [
      'sect',
      'revert',
      'country_of_birth',
      'nationality',
      'ethnicity',
      'languages',
    ]) {
      test(
        'required target $key cannot disappear even when prefs do not score it',
        () {
          final input = copyInput(
            base,
            chapter2Answers: base.chapter2Answers.where(
              (field) => field.key != key,
            ),
          );
          expect(
            validateDirectionalInputs(manifest, input),
            isA<TargetUnavailable>(),
          );
        },
      );
      test('required owner $key block cannot disappear', () {
        final input = copyInput(
          base,
          chapter2Preferences: base.chapter2Preferences.where(
            (block) => block.key != key,
          ),
        );
        expect(
          validateDirectionalInputs(manifest, input),
          isA<OwnerRepairRequired>(),
        );
      });
    }

    test(
      'six applicable blocks have provisional weight one and raw totals',
      () {
        var input = syntheticInput(manifest, light: 'amber');
        input = replaceChapter2Answer(input, 'revert', true);
        for (final key in ['country_of_birth', 'nationality', 'ethnicity']) {
          final target =
              input.chapter2Answers.singleWhere((f) => f.key == key).value
                  as String;
          input = replaceChapter2(
            input,
            _listBlock(key, preferred: [target], flexibility: 'red'),
          );
        }
        input = replaceChapter2(
          input,
          _listBlock('languages', preferred: ['ur'], flexibility: 'red'),
        );
        final validated = _validated(manifest, input);
        final units = validated.units.where(
          (unit) => unit.id.startsWith('ch2:'),
        );
        expect(units, hasLength(6));
        final result =
            calculateValidatedInputs(
                  ValidatedInputs(units, validated.categories),
                )
                as CalculatedContributions;
        // Independently derived: two Amber Deen units earn 1, four matching
        // Culture units earn 4; 5 earned across 6 available gives 5/6 overall.
        _expectFraction(result.total.earned, oracle.chapter2AllSix.earned);
        expect(
          result.total.available,
          Fraction(oracle.chapter2AllSix.available),
        );
        _expectFraction(result.overall, oracle.chapter2AllSix.overall);
        expect(result.categories['deen_practice']!.earned, Fraction(1));
        expect(result.categories['deen_practice']!.available, Fraction(2));
        expect(result.categories['culture_language']!.earned, Fraction(4));
        expect(result.categories['culture_language']!.available, Fraction(4));
      },
    );

    test(
      'valid unscored location and sect outside flexibility do not alter math',
      () {
        final before =
            calculateValidatedInputs(_validated(manifest, base))
                as CalculatedContributions;
        var input = replaceChapter2Answer(
          base,
          'location',
          'Another synthetic region',
        );
        input = replaceChapter2(input, _sect(manifest, outside: 'red'));
        final after =
            calculateValidatedInputs(_validated(manifest, input))
                as CalculatedContributions;
        expect(after.total.earned, before.total.earned);
        expect(after.total.available, before.total.available);
        expect(after.patterns, before.patterns);
        expect(
          after.patterns.keys.where(
            (id) =>
                id.contains('location') || id.contains('outside_flexibility'),
          ),
          isEmpty,
        );
      },
    );

    test(
      'present unscored fields are still validated, not silently ignored',
      () {
        expect(
          validateDirectionalInputs(
            manifest,
            replaceChapter2Answer(base, 'location', 123),
          ),
          isA<TargetUnavailable>(),
        );
        expect(
          validateDirectionalInputs(
            manifest,
            replaceChapter2(base, _sect(manifest, outside: 'unknown-light')),
          ),
          isA<OwnerRepairRequired>(),
        );
      },
    );

    test(
      'target corruption cannot hide behind an otherwise valid sect hard',
      () {
        var input = replaceChapter2(base, _sect(manifest, hards: ['sunni']));
        input = replaceChapter2Answer(input, 'revert', null);
        expect(
          validateDirectionalInputs(manifest, input),
          isA<TargetUnavailable>(),
        );
      },
    );
  });
}
