// Stage 1 research only. Not imported by production application code.
enum Sex { male, female }

enum Selection { single, multi }

enum Light { green, amber, red }

enum Pattern { aligned, open, opposed, mixed }

const futureSemantics = 'prefer-open-not-for-me-research-v1';
const legacySemantics = 'legacy-no-preference';
const researchContract = 'compatibility-stage1-research-v1';
const researchApplicabilityVersion = 'counterpart-applicability-stage1-v1';
const researchCategoryVersion = 'twelve-categories-stage1-v1';
const researchHardVersion = 'source-hard-capability-stage1-v1';

/// Exact rational arithmetic; never reconstruct the overall from percentages.
class Fraction implements Comparable<Fraction> {
  final BigInt numerator;
  final BigInt denominator;

  factory Fraction(int numerator, [int denominator = 1]) =>
      Fraction.big(BigInt.from(numerator), BigInt.from(denominator));

  factory Fraction.big(BigInt numerator, BigInt denominator) {
    if (denominator <= BigInt.zero) {
      throw ArgumentError('Denominator must be positive');
    }
    final gcd = numerator.abs().gcd(denominator);
    return Fraction._(numerator ~/ gcd, denominator ~/ gcd);
  }

  const Fraction._(this.numerator, this.denominator);

  Fraction operator +(Fraction other) => Fraction.big(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  Fraction operator /(Fraction other) {
    if (other.numerator <= BigInt.zero) {
      throw ArgumentError('Divisor must be positive');
    }
    return Fraction.big(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  @override
  int compareTo(Fraction other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is Fraction &&
      numerator == other.numerator &&
      denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => '$numerator/$denominator';
}

Fraction lightContribution(Light light) => switch (light) {
  Light.green => Fraction(1),
  Light.amber => Fraction(1, 2),
  Light.red => Fraction(0),
};

Light? parseLight(Object? raw) => switch (raw) {
  'green' => Light.green,
  'amber' => Light.amber,
  'red' => Light.red,
  _ => null,
};

/// All metadata collections are copied and sealed at construction.
class AnswerDefinition {
  final String key;
  final String questionId;
  final Sex? variant;
  final List<String> options;
  final Selection selection;
  final bool preferenceEligible;
  final bool hardSupported;
  final String? parentKey;
  final List<String> hiddenForParentOptions;
  final List<String> exclusiveOptions;
  final String category;

  AnswerDefinition({
    required this.key,
    required this.questionId,
    required this.variant,
    required Iterable<String> options,
    required this.selection,
    required this.preferenceEligible,
    required this.hardSupported,
    required this.category,
    this.parentKey,
    Iterable<String> hiddenForParentOptions = const [],
    Iterable<String> exclusiveOptions = const [],
  }) : options = List.unmodifiable(options),
       hiddenForParentOptions = List.unmodifiable(hiddenForParentOptions),
       exclusiveOptions = List.unmodifiable(exclusiveOptions);

  bool visibleTo(Sex sex) => variant == null || variant == sex;
}

class PreferenceDefinition {
  final String id;
  final String targetKey;
  final String category;
  final List<String> options;
  final Set<Sex> targetPool;
  final bool hardSupported;
  final String semanticsVersion;

  PreferenceDefinition({
    required this.id,
    required this.targetKey,
    required this.category,
    required Iterable<String> options,
    required Iterable<Sex> targetPool,
    required this.hardSupported,
    this.semanticsVersion = futureSemantics,
  }) : options = List.unmodifiable(options),
       targetPool = Set.unmodifiable(targetPool);
}

class BankSnapshot {
  final List<AnswerDefinition> answers;
  final Map<String, List<String>> chapter2Vocabulary;
  final String provenance;

  BankSnapshot({
    required Iterable<AnswerDefinition> answers,
    required Map<String, List<String>> chapter2Vocabulary,
    required this.provenance,
  }) : answers = List.unmodifiable(answers),
       chapter2Vocabulary = Map.unmodifiable({
         for (final entry in chapter2Vocabulary.entries)
           entry.key: List<String>.unmodifiable(entry.value),
       });
}

class Manifest {
  final List<AnswerDefinition> answers;
  final List<PreferenceDefinition> preferences;
  final List<String> categories;
  final Map<String, List<String>> chapter2Vocabulary;
  final String version;
  final String bankProvenance;
  final String applicabilityVersion;
  final String categoryMappingVersion;
  final String hardRequirementVersion;

  Manifest({
    required Iterable<AnswerDefinition> answers,
    required Iterable<PreferenceDefinition> preferences,
    required Iterable<String> categories,
    required Map<String, List<String>> chapter2Vocabulary,
    required this.bankProvenance,
    this.version = researchContract,
    this.applicabilityVersion = researchApplicabilityVersion,
    this.categoryMappingVersion = researchCategoryVersion,
    this.hardRequirementVersion = researchHardVersion,
  }) : answers = List.unmodifiable(answers),
       preferences = List.unmodifiable(preferences),
       categories = List.unmodifiable(categories),
       chapter2Vocabulary = Map.unmodifiable({
         for (final entry in chapter2Vocabulary.entries)
           entry.key: List<String>.unmodifiable(entry.value),
       });

  List<PreferenceDefinition> controlsForPool(Set<Sex> pool) =>
      List.unmodifiable(
        preferences.where((p) => p.targetPool.any(pool.contains)),
      );
}

/// Raw entries retain duplicates/types for validation BEFORE map/set coercion.
class RawField {
  final String key;
  final Object? value;
  const RawField(this.key, this.value);
}

class RawLight {
  final Object? option;
  final Object? value;
  const RawLight(this.option, this.value);
}

class RawPreference {
  final String id;
  final List<RawLight> lights;
  final List<Object?> hards;
  final String? semantics;

  RawPreference(
    this.id,
    Iterable<RawLight> lights, {
    Iterable<Object?> hards = const [],
    this.semantics = futureSemantics,
  }) : lights = List.unmodifiable(lights),
       hards = List.unmodifiable(hards);
}

class RawChapter2 {
  final String key;
  final List<RawField> fields;
  final String? semantics;

  RawChapter2(
    this.key,
    Iterable<RawField> fields, {
    this.semantics = futureSemantics,
  }) : fields = List.unmodifiable(fields);
}

class DirectionalInput {
  final Sex viewerSex;
  final Sex targetSex;
  final Set<Sex> permittedPool;
  final List<RawField> ownAnswers;
  final List<RawField> targetAnswers;
  final List<RawPreference> preferences;
  final List<RawField> chapter2Answers;
  final List<RawChapter2> chapter2Preferences;
  final bool rawEntryEvidence;

  DirectionalInput({
    required this.viewerSex,
    required this.targetSex,
    required Iterable<Sex> permittedPool,
    required Iterable<RawField> ownAnswers,
    required Iterable<RawField> targetAnswers,
    required Iterable<RawPreference> preferences,
    Iterable<RawField> chapter2Answers = const [],
    Iterable<RawChapter2> chapter2Preferences = const [],
    this.rawEntryEvidence = true,
  }) : permittedPool = Set.unmodifiable(permittedPool),
       ownAnswers = List.unmodifiable(ownAnswers),
       targetAnswers = List.unmodifiable(targetAnswers),
       preferences = List.unmodifiable(preferences),
       chapter2Answers = List.unmodifiable(chapter2Answers),
       chapter2Preferences = List.unmodifiable(chapter2Preferences);
}

/// Internal research outcomes; never expose diagnostic reasons to a viewer.
sealed class ValidationOutcome {
  const ValidationOutcome();
}

class OwnerRepairRequired extends ValidationOutcome {
  final String internalReason;
  const OwnerRepairRequired(this.internalReason);
}

class TargetUnavailable extends ValidationOutcome {
  const TargetUnavailable();
}

class ConfigurationFailure extends ValidationOutcome {
  final String internalReason;
  const ConfigurationFailure(this.internalReason);
}

class HardExcluded extends ValidationOutcome {
  const HardExcluded();
}

class ValidatedUnit {
  final String id;
  final String category;
  final List<Light> selectedLights;

  ValidatedUnit(this.id, this.category, Iterable<Light> selectedLights)
    : selectedLights = List.unmodifiable(selectedLights) {
    if (this.selectedLights.isEmpty) throw ArgumentError('Empty scoring unit');
  }
}

/// Research value object, not proof of production authorization or validation.
class ValidatedInputs extends ValidationOutcome {
  final List<ValidatedUnit> units;
  final List<String> categories;
  final String contractVersion;

  ValidatedInputs(
    Iterable<ValidatedUnit> units,
    Iterable<String> categories, {
    this.contractVersion = researchContract,
  }) : units = List.unmodifiable(units),
       categories = List.unmodifiable(categories);
}

class Contributions {
  final Fraction earned;
  final Fraction available;
  const Contributions(this.earned, this.available);
}

sealed class CalculationOutcome {
  const CalculationOutcome();
}

class NoScoreableData extends CalculationOutcome {
  const NoScoreableData();
}

class CalculatedContributions extends CalculationOutcome {
  final Contributions total;
  final Map<String, Contributions> categories;
  final Map<String, Pattern> patterns;

  CalculatedContributions(
    this.total,
    Map<String, Contributions> categories,
    Map<String, Pattern> patterns,
  ) : categories = Map.unmodifiable(categories),
      patterns = Map.unmodifiable(patterns);

  Fraction get overall => total.earned / total.available;
}
