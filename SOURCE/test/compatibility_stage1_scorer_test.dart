import 'package:flutter_test/flutter_test.dart';

import '../tools/compatibility_stage1/models.dart';
import '../tools/compatibility_stage1/scorer.dart';
import 'support/compatibility_stage1_oracle.dart' as oracle;

// These explicitly labelled component fixtures bypass whole-bank validation
// only to isolate arithmetic. They do not represent eligible member inputs.
ValidatedInputs _component(
  List<List<Light>> questions, {
  List<String>? categoryForQuestion,
  List<String> categories = const ['A', 'B', 'unused'],
}) => ValidatedInputs([
  for (var index = 0; index < questions.length; index++)
    ValidatedUnit(
      'synthetic-question-$index',
      categoryForQuestion?[index] ?? 'A',
      questions[index],
    ),
], categories);

CalculatedContributions _calculate(ValidatedInputs input) {
  final outcome = calculateValidatedInputs(input);
  expect(outcome, isA<CalculatedContributions>());
  return outcome as CalculatedContributions;
}

void _expectFraction(Fraction actual, oracle.OracleRational expected) {
  expect(actual.numerator, BigInt.from(expected.numerator));
  expect(actual.denominator, BigInt.from(expected.denominator));
}

void _expectOracle(
  CalculatedContributions actual,
  oracle.OracleContributions expected,
) {
  _expectFraction(actual.total.earned, expected.earned);
  expect(actual.total.available, Fraction(expected.available));
  _expectFraction(actual.overall, expected.overall);
}

void main() {
  group('synthetic component arithmetic, independent hand-derived oracle', () {
    for (final entry in [
      (Light.green, oracle.scalarGreen, Pattern.aligned),
      (Light.amber, oracle.scalarAmber, Pattern.open),
      (Light.red, oracle.scalarRed, Pattern.opposed),
    ]) {
      test('${entry.$1.name} scalar contributes one unit', () {
        final result = _calculate(
          _component([
            [entry.$1],
          ]),
        );
        _expectOracle(result, entry.$2);
        expect(result.patterns['synthetic-question-0'], entry.$3);
      });
    }

    test('Green/Red question is one unit and Mixed', () {
      final result = _calculate(
        _component([
          [Light.green, Light.red],
        ]),
      );
      _expectOracle(result, oracle.greenRedQuestion);
      expect(result.patterns['synthetic-question-0'], Pattern.mixed);
    });

    test('two Amber selections are Open, not Mixed', () {
      final result = _calculate(
        _component([
          [Light.amber, Light.amber],
        ]),
      );
      _expectOracle(result, oracle.twoAmberQuestion);
      expect(result.patterns['synthetic-question-0'], Pattern.open);
    });

    test('Green/Red question plus Green scalar gives 3/4', () {
      _expectOracle(
        _calculate(
          _component([
            [Light.green, Light.red],
            [Light.green],
          ]),
        ),
        oracle.greenRedPlusGreen,
      );
    });

    test('distinct Green/Green/Red options plus Green give exact 5/6', () {
      _expectOracle(
        _calculate(
          _component([
            [Light.green, Light.green, Light.red],
            [Light.green],
          ]),
        ),
        oracle.greenGreenRedPlusGreen,
      );
    });

    test('overall sums raw contributions, not equal category percentages', () {
      final result = _calculate(
        _component(
          [
            [Light.green],
            [Light.red],
            [Light.red],
            [Light.red],
          ],
          categoryForQuestion: ['A', 'B', 'B', 'B'],
        ),
      );
      _expectOracle(result, oracle.unequalCategoryCoverage);
      expect(result.categories['A']!.earned, Fraction(1));
      expect(result.categories['A']!.available, Fraction(1));
      expect(result.categories['B']!.earned, Fraction(0));
      expect(result.categories['B']!.available, Fraction(3));
      expect(result.categories['unused']!.earned, Fraction(0));
      expect(result.categories['unused']!.available, Fraction(0));
      expect(result.overall, isNot(Fraction(1, 2)));
    });

    test('OA228 extra selected Red changes mean, not question denominator', () {
      final before = _calculate(
        _component([
          [Light.green],
          [Light.green],
        ]),
      );
      final after = _calculate(
        _component([
          [Light.green, Light.red],
          [Light.green],
        ]),
      );
      _expectOracle(before, oracle.oa228Before);
      _expectOracle(after, oracle.oa228After);
      expect(before.total.available, after.total.available);
    });

    test('valid all-Red coverage returns a real zero', () {
      final result = _calculate(
        _component([
          [Light.red],
          [Light.red],
          [Light.red, Light.red],
        ]),
      );
      _expectOracle(result, oracle.allRedWithCoverage);
      expect(result.patterns.values, everyElement(Pattern.opposed));
    });

    test('no available unit is unavailable, not zero or neutral', () {
      expect(calculateValidatedInputs(_component([])), isA<NoScoreableData>());
    });

    test('all differing selected-light combinations are Mixed', () {
      for (final lights in [
        [Light.green, Light.amber],
        [Light.amber, Light.red],
        [Light.green, Light.red],
        [Light.green, Light.amber, Light.red],
      ]) {
        final result = _calculate(_component([lights]));
        expect(result.patterns['synthetic-question-0'], Pattern.mixed);
      }
    });
  });

  group('raw invariants and research object boundaries', () {
    test('selected-option order changes neither totals nor pattern', () {
      final first = _calculate(
        _component([
          [Light.green, Light.amber, Light.red, Light.green],
        ]),
      );
      final reordered = _calculate(
        _component([
          [Light.red, Light.green, Light.green, Light.amber],
        ]),
      );
      expect(first.total.earned, reordered.total.earned);
      expect(first.total.available, reordered.total.available);
      expect(first.overall, reordered.overall);
      expect(first.patterns, reordered.patterns);
    });

    test('question order changes neither raw category nor overall totals', () {
      final input = _component(
        [
          [Light.green, Light.green, Light.red],
          [Light.amber],
          [Light.red],
        ],
        categoryForQuestion: ['A', 'B', 'A'],
      );
      final first = _calculate(input);
      final reordered = _calculate(
        ValidatedInputs(input.units.reversed, input.categories),
      );
      expect(first.total.earned, reordered.total.earned);
      expect(first.total.available, reordered.total.available);
      expect(first.overall, reordered.overall);
      for (final category in input.categories) {
        expect(
          first.categories[category]!.earned,
          reordered.categories[category]!.earned,
        );
        expect(
          first.categories[category]!.available,
          reordered.categories[category]!.available,
        );
      }
      expect(first.patterns, reordered.patterns);
    });

    test(
      'categories reconcile exactly, including non-terminating fractions',
      () {
        final result = _calculate(
          _component(
            [
              [Light.green, Light.green, Light.red],
              [Light.amber],
              [Light.red, Light.amber, Light.green, Light.red, Light.red],
            ],
            categoryForQuestion: ['A', 'B', 'A'],
          ),
        );
        var earned = Fraction(0);
        var available = Fraction(0);
        for (final contribution in result.categories.values) {
          earned = earned + contribution.earned;
          available = available + contribution.available;
        }
        expect(earned, result.total.earned);
        expect(available, result.total.available);
        expect(earned / available, result.overall);
        expect(result.categories.keys, ['A', 'B', 'unused']);
      },
    );

    test('category reclassification does not change numerical result', () {
      final input = _component(
        [
          [Light.green, Light.red],
          [Light.green],
          [Light.amber],
        ],
        categoryForQuestion: ['A', 'B', 'A'],
      );
      final before = _calculate(input);
      final after = _calculate(
        ValidatedInputs([
          for (final unit in input.units)
            ValidatedUnit(unit.id, 'B', unit.selectedLights),
        ], input.categories),
      );
      expect(after.total.earned, before.total.earned);
      expect(after.total.available, before.total.available);
      expect(after.overall, before.overall);
      expect(after.patterns, before.patterns);
      expect(after.categories['A']!.available, Fraction(0));
      expect(after.categories['B']!.available, Fraction(3));
    });

    test('result maps are immutable and input collections remain intact', () {
      final input = _component([
        [Light.green, Light.red],
      ]);
      final result = _calculate(input);
      expect(() => result.categories.clear(), throwsUnsupportedError);
      expect(() => result.patterns.clear(), throwsUnsupportedError);
      expect(input.units.single.selectedLights, [Light.green, Light.red]);
    });

    test('manually malformed validated objects do not silently overwrite', () {
      expect(
        () => calculateValidatedInputs(
          ValidatedInputs(
            [
              ValidatedUnit('same-id', 'A', [Light.green]),
              ValidatedUnit('same-id', 'A', [Light.red]),
            ],
            ['A'],
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateValidatedInputs(
          ValidatedInputs(
            [
              ValidatedUnit('one', 'not-mapped', [Light.green]),
            ],
            ['A'],
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateValidatedInputs(ValidatedInputs([], ['A', 'A'])),
        throwsArgumentError,
      );
      expect(
        () => calculateValidatedInputs(
          ValidatedInputs([], [
            'A',
          ], contractVersion: 'unsupported-synthetic-version'),
        ),
        throwsArgumentError,
      );
      expect(() => ValidatedUnit('empty', 'A', []), throwsArgumentError);
    });
  });
}
