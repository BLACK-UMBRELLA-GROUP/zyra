// SYNTHETIC Stage 1 fixtures only: no member identities, stored answers or app use.
import '../../tools/compatibility_stage1/models.dart';

/// A complete synthetic input, not a component profile or production payload.
///
/// Every visible own/target answer and every pool-offered preference is present.
/// Dependency visibility is evaluated separately for each side. All preference
/// options receive a light, including options not chosen by this target.
DirectionalInput syntheticInput(
  Manifest manifest, {
  Sex viewerSex = Sex.male,
  Sex targetSex = Sex.female,
  Set<Sex>? permittedPool,
  String ownQ3 = 'Yes',
  String targetQ3 = 'Yes',
  String light = 'green',
}) {
  final pool = permittedPool ?? {targetSex};
  final sectVocabulary = manifest.chapter2Vocabulary['sect'];
  if (sectVocabulary == null || !sectVocabulary.contains('sunni')) {
    throw ArgumentError('Synthetic fixture requires a registered sunni code');
  }
  return DirectionalInput(
    viewerSex: viewerSex,
    targetSex: targetSex,
    permittedPool: pool,
    ownAnswers: _syntheticAnswers(manifest, viewerSex, ownQ3),
    targetAnswers: _syntheticAnswers(manifest, targetSex, targetQ3),
    preferences: [
      for (final control in manifest.controlsForPool(pool))
        RawPreference(control.id, [
          for (final option in control.options) RawLight(option, light),
        ]),
    ],
    chapter2Answers: const [
      RawField('sect', 'sunni'),
      RawField('revert', false),
      RawField('country_of_birth', 'PK'),
      RawField('nationality', 'PK'),
      RawField('ethnicity', 'pakistani'),
      RawField('languages', ['en', 'ur']),
      RawField('location', 'Synthetic region'),
    ],
    chapter2Preferences: [
      RawChapter2('sect', [
        RawField(
          'matrix',
          List<RawLight>.unmodifiable([
            for (final code in sectVocabulary) RawLight(code, light),
          ]),
        ),
        const RawField('hard_requirement', <Object?>[]),
        RawField('outside_flexibility', light),
      ]),
      RawChapter2('revert', [RawField('flexibility', light)]),
      for (final key in ['country_of_birth', 'nationality', 'ethnicity'])
        RawChapter2(key, [
          const RawField('preferred', <String>[]),
          RawField('flexibility', light),
          const RawField('skipped', true),
        ]),
      // English-only preference is explicitly captured, but adds no score unit.
      RawChapter2('languages', [
        const RawField('preferred', ['en']),
        RawField('flexibility', light),
        const RawField('skipped', false),
      ]),
    ],
  );
}

List<RawField> _syntheticAnswers(Manifest manifest, Sex sex, String q3) {
  final visible = manifest.answers.where((answer) => answer.visibleTo(sex));
  final selected = <String, List<String>>{};
  for (final answer in visible) {
    if (answer.options.isEmpty) {
      throw ArgumentError('Synthetic fixture requires nonempty vocabulary');
    }
    selected[answer.key] = [
      answer.questionId == 'ch3_q3' ? q3 : answer.options.first,
    ];
  }
  return [
    for (final answer in visible)
      if (answer.parentKey == null ||
          !selected[answer.parentKey]!.any(
            answer.hiddenForParentOptions.contains,
          ))
        RawField(
          answer.key,
          answer.selection == Selection.single
              ? selected[answer.key]!.single
              : List<String>.unmodifiable(selected[answer.key]!),
        ),
  ];
}

/// Copies raw entry lists without deduplication or normalization.
/// Use the list parameters directly when constructing duplicate evidence cases.
DirectionalInput copyInput(
  DirectionalInput input, {
  Sex? viewerSex,
  Sex? targetSex,
  Iterable<Sex>? permittedPool,
  Iterable<RawField>? ownAnswers,
  Iterable<RawField>? targetAnswers,
  Iterable<RawPreference>? preferences,
  Iterable<RawField>? chapter2Answers,
  Iterable<RawChapter2>? chapter2Preferences,
  bool? rawEntryEvidence,
}) => DirectionalInput(
  viewerSex: viewerSex ?? input.viewerSex,
  targetSex: targetSex ?? input.targetSex,
  permittedPool: permittedPool ?? input.permittedPool,
  ownAnswers: ownAnswers ?? input.ownAnswers,
  targetAnswers: targetAnswers ?? input.targetAnswers,
  preferences: preferences ?? input.preferences,
  chapter2Answers: chapter2Answers ?? input.chapter2Answers,
  chapter2Preferences: chapter2Preferences ?? input.chapter2Preferences,
  rawEntryEvidence: rawEntryEvidence ?? input.rawEntryEvidence,
);

/// Deliberately replaces a key with one raw entry; all unrelated entries survive.
/// This helper does not repair dependencies. Invalid cases stay invalid.
DirectionalInput replaceAnswer(
  DirectionalInput input,
  String key,
  Object? value, {
  bool own = false,
}) => own
    ? copyInput(input, ownAnswers: _replaceField(input.ownAnswers, key, value))
    : copyInput(
        input,
        targetAnswers: _replaceField(input.targetAnswers, key, value),
      );

DirectionalInput replaceChapter2Answer(
  DirectionalInput input,
  String key,
  Object? value,
) => copyInput(
  input,
  chapter2Answers: _replaceField(input.chapter2Answers, key, value),
);

DirectionalInput replacePreference(
  DirectionalInput input,
  RawPreference replacement,
) => copyInput(
  input,
  preferences: _replaceEntry(
    input.preferences,
    (entry) => entry.id == replacement.id,
    replacement,
  ),
);

DirectionalInput replaceChapter2(
  DirectionalInput input,
  RawChapter2 replacement,
) => copyInput(
  input,
  chapter2Preferences: _replaceEntry(
    input.chapter2Preferences,
    (entry) => entry.key == replacement.key,
    replacement,
  ),
);

List<RawField> _replaceField(
  Iterable<RawField> entries,
  String key,
  Object? value,
) => _replaceEntry(entries, (entry) => entry.key == key, RawField(key, value));

List<T> _replaceEntry<T>(
  Iterable<T> entries,
  bool Function(T) matches,
  T replacement,
) {
  var replaced = false;
  final result = <T>[];
  for (final entry in entries) {
    if (matches(entry)) {
      if (!replaced) result.add(replacement);
      replaced = true;
    } else {
      result.add(entry);
    }
  }
  if (!replaced) result.add(replacement);
  return List.unmodifiable(result);
}
