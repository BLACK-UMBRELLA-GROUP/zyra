// Stage 1 research only. No production scoring or disclosure entry point.
import 'models.dart';

/// Calculates internal raw contributions from already validated research input.
///
/// Each question contributes one available unit, regardless of how many valid
/// options the target selected. Categories are bookkeeping, not extra weights.
/// This does not validate raw answers, produce bands, or authorize a result.
CalculationOutcome calculateValidatedInputs(ValidatedInputs input) {
  if (input.contractVersion != researchContract) {
    throw ArgumentError('Unsupported validated research contract');
  }
  final categories = input.categories.toSet();
  if (categories.length != input.categories.length) {
    throw ArgumentError('Duplicate validated category');
  }
  final unitIds = <String>{};
  final earnedByCategory = <String, Fraction>{
    for (final category in input.categories) category: Fraction(0),
  };
  final availableByCategory = <String, Fraction>{
    for (final category in input.categories) category: Fraction(0),
  };
  final patterns = <String, Pattern>{};
  var earned = Fraction(0);
  var available = Fraction(0);

  for (final unit in input.units) {
    if (!unitIds.add(unit.id)) {
      throw ArgumentError('Duplicate validated scoring-unit identity');
    }
    if (!categories.contains(unit.category)) {
      throw ArgumentError('Scoring unit has no validated category');
    }
    var selectedTotal = Fraction(0);
    for (final light in unit.selectedLights) {
      selectedTotal = selectedTotal + lightContribution(light);
    }
    final questionEarned = selectedTotal / Fraction(unit.selectedLights.length);
    earned = earned + questionEarned;
    available = available + Fraction(1);
    earnedByCategory[unit.category] =
        earnedByCategory[unit.category]! + questionEarned;
    availableByCategory[unit.category] =
        availableByCategory[unit.category]! + Fraction(1);

    final distinctLights = unit.selectedLights.toSet();
    patterns[unit.id] = distinctLights.length > 1
        ? Pattern.mixed
        : switch (distinctLights.single) {
            Light.green => Pattern.aligned,
            Light.amber => Pattern.open,
            Light.red => Pattern.opposed,
          };
  }

  if (input.units.isEmpty) return const NoScoreableData();
  return CalculatedContributions(Contributions(earned, available), {
    for (final category in input.categories)
      category: Contributions(
        earnedByCategory[category]!,
        availableByCategory[category]!,
      ),
  }, patterns);
}
