// Unwired Stage 1 research registry. Not a production capture/scoring API.
import 'bank_adapter.dart';
import 'models.dart';

const canonicalCategoryIds = <String>[
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
];

const canonicalCategoryNames = <String, String>{
  'deen_practice': 'Deen & Islamic Practice',
  'marriage_intentions': 'Marriage Intentions & Structure',
  'children_parenting': 'Children & Parenting',
  'family_in_laws': 'Family & In-Laws',
  'finances_provision': 'Finances & Provision',
  'education_career': 'Education, Career & Work',
  'home_roles': 'Home Life & Household Roles',
  'communication_conflict': 'Communication & Conflict',
  'personality_connection': 'Personality & Connection',
  'lifestyle_wellbeing': 'Lifestyle, Health & Well-being',
  'digital_boundaries': 'Digital Life, Privacy & Boundaries',
  'culture_language': 'Culture & Language',
};

/// Explicit qid ownership, reconciled to the current bank's explicit grouping
/// and DR-ZYRA-250 D3. No list position or old compatibilityCategories mapping
/// grants ownership. Information-only answers are accounted for here but do
/// not thereby gain a scoring unit. This does not regroup onboarding UI.
const canonicalOwnAnswerQuestionNumbers = <String, List<int>>{
  'deen_practice': [
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    45,
    46,
    49,
    50,
    51,
  ],
  'marriage_intentions': [1, 23, 25, 26, 27, 28, 31, 32],
  'children_parenting': [2, 3, 24, 29, 48],
  'family_in_laws': [4, 5, 6, 7, 8, 9, 10],
  'finances_provision': [12, 13, 14, 15, 19, 20, 21, 22, 47, 67, 68],
  'education_career': [11, 16, 17, 18, 63],
  'home_roles': [64, 65, 66, 69, 70, 71, 72, 73],
  'communication_conflict': [74, 75, 76, 77, 78, 79, 80, 81, 82, 83],
  'personality_connection': [61, 62, 84],
  'lifestyle_wellbeing': [
    30,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    59,
    60,
    94,
    95,
    96,
    97,
    98,
    99,
    100,
    101,
    102,
    103,
    104,
  ],
  'digital_boundaries': [85, 86, 87, 88, 89, 90, 91, 92, 93],
};

/// Eligible topic inventory, not a per-person denominator. The old optional
/// classification grants no permission to omit a required prospective control.
const _eligibleQuestionNumbers = <int>{
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  11,
  12,
  13,
  14,
  15,
  16,
  18,
  20,
  22,
  23,
  24,
  25,
  26,
  28,
  29,
  30,
  31,
  33,
  34,
  35,
  36,
  37,
  38,
  39,
  40,
  43,
  44,
  46,
  47,
  48,
  49,
  50,
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  60,
  61,
  63,
  64,
  65,
  66,
  67,
  68,
  70,
  71,
  72,
  73,
  74,
  75,
  78,
  81,
  84,
  85,
  86,
  87,
  90,
  95,
  97,
};

const chapter2ScoringCategories = <String, String>{
  'sect': 'deen_practice',
  'revert': 'deen_practice',
  'country_of_birth': 'culture_language',
  'nationality': 'culture_language',
  'ethnicity': 'culture_language',
  'languages': 'culture_language',
};

const unscoredChapter2Controls = <String>{
  'location',
  'sect.outside_flexibility',
};

String? _categoryForQuestion(String questionId) {
  final matches = [
    for (final entry in canonicalOwnAnswerQuestionNumbers.entries)
      if (entry.value.any((number) => 'ch3_q$number' == questionId)) entry.key,
  ];
  return matches.length == 1 ? matches.single : null;
}

Manifest buildManifest([BankSnapshot? bank]) {
  final snapshot = bank ?? readStaticBankSnapshot();
  final answers = [
    for (final answer in snapshot.answers)
      AnswerDefinition(
        key: answer.key,
        questionId: answer.questionId,
        variant: answer.variant,
        options: answer.options,
        selection: answer.selection,
        preferenceEligible: answer.preferenceEligible,
        hardSupported: answer.hardSupported,
        category: _categoryForQuestion(answer.questionId) ?? '',
        parentKey: answer.parentKey,
        hiddenForParentOptions: answer.hiddenForParentOptions,
        exclusiveOptions: answer.exclusiveOptions,
      ),
  ];
  return Manifest(
    answers: answers,
    preferences: [
      for (final answer in answers)
        if (answer.preferenceEligible)
          PreferenceDefinition(
            id: 'pref:${answer.key}',
            targetKey: answer.key,
            category: answer.category,
            options: answer.options,
            targetPool: answer.variant == null
                ? const {Sex.male, Sex.female}
                : {answer.variant!},
            hardSupported: answer.hardSupported,
          ),
    ],
    categories: canonicalCategoryIds,
    chapter2Vocabulary: snapshot.chapter2Vocabulary,
    bankProvenance: snapshot.provenance,
  );
}

bool _sameList<T>(List<T> a, List<T> b) =>
    a.length == b.length &&
    List.generate(
      a.length,
      (index) => a[index] == b[index],
    ).every((same) => same);

bool _sameSet<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

/// Deterministic internal configuration check; never a public error payload.
/// Required control presence/lights and target parent values belong to raw
/// input validation. Both variant definitions may exist in this inventory;
/// that is not permission to load both into one editable or validated state.
String? validateManifest(Manifest manifest) {
  if (manifest.version != researchContract) {
    return 'Unsupported research contract';
  }
  if (manifest.bankProvenance != staticBankProvenance) {
    return 'Unsupported bank provenance';
  }
  if (manifest.applicabilityVersion != researchApplicabilityVersion) {
    return 'Unsupported applicability version';
  }
  if (manifest.categoryMappingVersion != researchCategoryVersion) {
    return 'Unsupported category mapping version';
  }
  if (manifest.hardRequirementVersion != researchHardVersion) {
    return 'Unsupported Hard Requirement version';
  }
  if (!_sameList(manifest.categories, canonicalCategoryIds)) {
    return 'Missing, duplicate or reordered canonical category';
  }
  final mappedNumbers = canonicalOwnAnswerQuestionNumbers.values
      .expand((v) => v)
      .toList();
  if (mappedNumbers.length != 104 ||
      mappedNumbers.toSet().length != 104 ||
      !mappedNumbers.toSet().containsAll(
        List.generate(104, (index) => index + 1),
      )) {
    return 'Ambiguous own-answer category inventory';
  }
  if (manifest.answers.length != 105) {
    return 'Incomplete own-answer inventory';
  }
  final sourceSnapshot = readStaticBankSnapshot();
  final sourceByKey = {
    for (final answer in sourceSnapshot.answers) answer.key: answer,
  };
  final expectedKeys = <String>{
    for (var number = 1; number <= 104; number++)
      if (number == 26) ...{
        'ch3_q26::male',
        'ch3_q26::female',
      } else if (number == 39)
        'ch3_q39::male'
      else
        'ch3_q$number',
  };
  final answersByKey = <String, AnswerDefinition>{};
  for (final answer in manifest.answers) {
    if (answersByKey.containsKey(answer.key)) {
      return 'Duplicate own-answer identity';
    }
    answersByKey[answer.key] = answer;
    if (!expectedKeys.contains(answer.key)) {
      return 'Unknown own-answer identity';
    }
    final expectedKey = answer.variant == null
        ? answer.questionId
        : '${answer.questionId}::${answer.variant!.name}';
    if (answer.key != expectedKey) {
      return 'Wrong own-answer variant identity';
    }
    if ((answer.questionId == 'ch3_q26' && answer.variant == null) ||
        (answer.questionId == 'ch3_q39' && answer.variant != Sex.male) ||
        (!const {'ch3_q26', 'ch3_q39'}.contains(answer.questionId) &&
            answer.variant != null)) {
      return 'Wrong target variant definition';
    }
    final category = _categoryForQuestion(answer.questionId);
    if (category == null || answer.category != category) {
      return 'Missing or wrong answer category';
    }
    final number = int.tryParse(answer.questionId.substring('ch3_q'.length));
    if (answer.preferenceEligible !=
        _eligibleQuestionNumbers.contains(number)) {
      return 'Wrong scoring eligibility';
    }
    if (answer.options.isEmpty ||
        answer.options.any((option) => option.isEmpty) ||
        answer.options.toSet().length != answer.options.length) {
      return 'Invalid target vocabulary';
    }
    final source = sourceByKey[answer.key];
    if (source == null ||
        !_sameList(answer.options, source.options) ||
        answer.hardSupported != source.hardSupported) {
      return 'Bank metadata differs from declared source version';
    }
    final expectedSelection =
        const {'ch3_q37', 'ch3_q62', 'ch3_q97'}.contains(answer.questionId)
        ? Selection.multi
        : Selection.single;
    if (answer.selection != expectedSelection) {
      return 'Wrong selection metadata';
    }
    final expectedExclusive =
        const {'ch3_q37', 'ch3_q97'}.contains(answer.questionId)
        ? const ['None']
        : const <String>[];
    if (!_sameList(answer.exclusiveOptions, expectedExclusive) ||
        !answer.options.toSet().containsAll(answer.exclusiveOptions)) {
      return 'Missing or unsupported exclusivity metadata';
    }
    if (answer.questionId == 'ch3_q24') {
      if (answer.parentKey != 'ch3_q3' ||
          !_sameList(answer.hiddenForParentOptions, const ['No'])) {
        return 'Wrong counterpart timing condition';
      }
    } else if (answer.parentKey != null ||
        answer.hiddenForParentOptions.isNotEmpty) {
      return 'Unsupported conditional rule';
    }
  }
  if (!_sameSet(answersByKey.keys.toSet(), expectedKeys)) {
    return 'Missing own-answer identities';
  }
  final parent = answersByKey['ch3_q3']!;
  if (!_sameSet(parent.options.toSet(), const {
    'Yes',
    'No',
    'If Allah wills',
    'Unsure',
  })) {
    return 'Unresolved timing parent vocabulary';
  }
  if (_sameList(
    answersByKey['ch3_q26::male']!.options,
    answersByKey['ch3_q26::female']!.options,
  )) {
    return 'Collapsed polygamy vocabularies';
  }
  final controls = <String>{};
  final targets = <String>{};
  for (final preference in manifest.preferences) {
    if (!controls.add(preference.id)) {
      return 'Duplicate preference identity';
    }
    if (!targets.add(preference.targetKey)) {
      return 'Duplicate target control';
    }
    final target = answersByKey[preference.targetKey];
    if (target == null || !target.preferenceEligible) {
      return 'Unknown or unscored preference target';
    }
    if (preference.id != 'pref:${target.key}') {
      return 'Unresolved preference identity';
    }
    if (preference.semanticsVersion != futureSemantics) {
      return 'Unsupported preference semantics';
    }
    if (preference.category != target.category) {
      return 'Wrong preference category';
    }
    if (!_sameList(preference.options, target.options)) {
      return 'Unresolved target vocabulary';
    }
    final expectedPool = target.variant == null
        ? {Sex.male, Sex.female}
        : {target.variant!};
    if (!_sameSet(preference.targetPool, expectedPool)) {
      return 'Wrong prospective target pool';
    }
    if (preference.hardSupported != target.hardSupported) {
      return 'Unresolved Hard Requirement capability';
    }
  }
  final eligibleKeys = answersByKey.values
      .where((a) => a.preferenceEligible)
      .map((a) => a.key)
      .toSet();
  if (!_sameSet(targets, eligibleKeys)) {
    return 'Missing required prospective control';
  }

  const vocabularyKeys = {
    'sect',
    'country_of_birth',
    'nationality',
    'ethnicity',
    'languages',
    'location',
  };
  if (!_sameSet(manifest.chapter2Vocabulary.keys.toSet(), vocabularyKeys)) {
    return 'Unresolved Chapter2 vocabulary registry';
  }
  for (final vocabulary in manifest.chapter2Vocabulary.values) {
    if (vocabulary.isEmpty ||
        vocabulary.any((option) => option.isEmpty) ||
        vocabulary.toSet().length != vocabulary.length) {
      return 'Invalid Chapter2 vocabulary';
    }
  }
  final sect = manifest.chapter2Vocabulary['sect']!;
  final canonicalSlug = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  if (!sect.contains('sunni') ||
      !sect.contains('shia') ||
      sect.any((code) => !canonicalSlug.hasMatch(code))) {
    return 'Invalid registered sect vocabulary';
  }
  final reference = sourceSnapshot.chapter2Vocabulary;
  for (final key in vocabularyKeys.where((key) => key != 'sect')) {
    if (!_sameSet(
      manifest.chapter2Vocabulary[key]!.toSet(),
      reference[key]!.toSet(),
    )) {
      return 'Unknown Chapter2 reference vocabulary';
    }
  }
  return null;
}
