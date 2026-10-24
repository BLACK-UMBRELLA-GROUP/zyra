// Synthetic research exporter only. stdout JSON; never reads member state/env.
import 'dart:convert';
import 'dart:io';

import '../compatibility_stage1/manifest.dart';
import '../compatibility_stage1/models.dart';
import '../compatibility_stage1/scorer.dart';
import '../compatibility_stage1/validator.dart';
import '../../test/support/compatibility_stage1_fixtures.dart';

List<Map<String, Object?>> fields(Iterable<RawField> raw) => [
  for (final field in raw)
    {'key': field.key, 'value': encodeValue(field.value)},
];

Object? encodeValue(Object? value) => value is List<RawLight>
    ? [
        for (final light in value)
          {'option': light.option, 'value': light.value},
      ]
    : value;

Map<String, Object?> answers(DirectionalInput input, {bool target = false}) => {
  'answers': fields(target ? input.targetAnswers : input.ownAnswers),
  'chapter2': fields(input.chapter2Answers),
};

Map<String, Object?> preferences(DirectionalInput input) => {
  'pool': [for (final sex in input.permittedPool) sex.name],
  'controls': [
    for (final p in input.preferences)
      {
        'id': p.id,
        'lights': [
          for (final l in p.lights) {'option': l.option, 'value': l.value},
        ],
        'hards': p.hards,
        'semantics': p.semantics,
      },
  ],
  'chapter2': [
    for (final p in input.chapter2Preferences)
      {'key': p.key, 'fields': fields(p.fields), 'semantics': p.semantics},
  ],
};

Map<String, Object?> contributions(Manifest manifest, DirectionalInput input) {
  final validated = validateDirectionalInputs(manifest, input);
  if (validated is! ValidatedInputs) {
    throw StateError('Invalid synthetic fixture');
  }
  final calculated = calculateValidatedInputs(validated);
  if (calculated is! CalculatedContributions) {
    throw StateError('No fixture score');
  }
  return {
    'earned_n': calculated.total.earned.numerator.toInt(),
    'earned_d': calculated.total.earned.denominator.toInt(),
    'available': calculated.total.available.numerator.toInt(),
    'categories': {
      for (final entry in calculated.categories.entries)
        entry.key: {
          'earned_n': entry.value.earned.numerator.toInt(),
          'earned_d': entry.value.earned.denominator.toInt(),
          'available': entry.value.available.numerator.toInt(),
        },
    },
  };
}

void main() {
  final manifest = buildManifest();
  final failure = validateManifest(manifest);
  if (failure != null) throw StateError(failure);
  final male = syntheticInput(manifest);
  final female = syntheticInput(
    manifest,
    viewerSex: Sex.female,
    targetSex: Sex.male,
  );
  final mixed = copyInput(
    male,
    preferences: [
      for (var i = 0; i < male.preferences.length; i++)
        RawPreference(male.preferences[i].id, [
          for (var j = 0; j < male.preferences[i].lights.length; j++)
            RawLight(
              male.preferences[i].lights[j].option,
              ['green', 'amber', 'red'][(i + j) % 3],
            ),
        ]),
    ],
  );
  final registry = {
    'version': manifest.version,
    'bank_provenance': manifest.bankProvenance,
    'applicability_version': manifest.applicabilityVersion,
    'category_version': manifest.categoryMappingVersion,
    'hard_version': manifest.hardRequirementVersion,
    'semantics_version': futureSemantics,
    'categories': manifest.categories,
    'answers': [
      for (final a in manifest.answers)
        {
          'key': a.key,
          'question_id': a.questionId,
          'variant': a.variant?.name,
          'options': a.options,
          'selection': a.selection.name,
          'eligible': a.preferenceEligible,
          'hard_supported': a.hardSupported,
          'parent_key': a.parentKey,
          'hidden_options': a.hiddenForParentOptions,
          'exclusive_options': a.exclusiveOptions,
          'category': a.category,
        },
    ],
    'preferences': [
      for (final p in manifest.preferences)
        {
          'id': p.id,
          'target_key': p.targetKey,
          'options': p.options,
          'target_pool': [for (final s in p.targetPool) s.name],
          'hard_supported': p.hardSupported,
          'category': p.category,
        },
    ],
    'chapter2_vocabulary': manifest.chapter2Vocabulary,
  };
  stdout.write(
    jsonEncode({
      'research_only': true,
      'manifest': registry,
      'subjects': {
        'male': {'answers': answers(male), 'preferences': preferences(male)},
        'female': {
          'answers': answers(female),
          'preferences': preferences(female),
        },
      },
      'mixed_preferences': preferences(mixed),
      'oracles': {
        'male_to_female': contributions(manifest, male),
        'female_to_male': contributions(manifest, female),
        'mixed_male_to_female': contributions(manifest, mixed),
      },
      'oracle_boundary':
          'Stage1 parity outputs, not independent proof of policy/privacy',
    }),
  );
}
