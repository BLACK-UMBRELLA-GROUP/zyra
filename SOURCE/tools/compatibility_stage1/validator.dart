// Unwired research validator. No caller identity, persistence or disclosure API.
import 'manifest.dart';
import 'models.dart';

class _Invalid implements Exception {
  final String reason;
  const _Invalid(this.reason);
}

Map<String, Object?> _fields(Iterable<RawField> raw, Set<String> allowed) {
  final result = <String, Object?>{};
  for (final entry in raw) {
    if (!allowed.contains(entry.key) || result.containsKey(entry.key)) {
      throw _Invalid('unknown-or-duplicate-field:${entry.key}');
    }
    result[entry.key] = entry.value;
  }
  return result;
}

List<String> _strings(
  Object? raw,
  List<String> vocabulary, {
  bool empty = false,
}) {
  if (raw is! List || (!empty && raw.isEmpty)) {
    throw const _Invalid('invalid-list');
  }
  final result = <String>[];
  for (final value in raw) {
    if (value is! String ||
        !vocabulary.contains(value) ||
        result.contains(value)) {
      throw const _Invalid('unknown-or-duplicate-option');
    }
    result.add(value);
  }
  return List.unmodifiable(result);
}

Map<String, List<String>> _answers(
  Manifest manifest,
  Sex sex,
  List<RawField> raw,
) {
  final visible = manifest.answers.where((a) => a.visibleTo(sex)).toList();
  final values = _fields(raw, visible.map((a) => a.key).toSet());
  final parsed = <String, List<String>>{};
  // Parse every supplied answer first, including non-scoring own answers.
  for (final answer in visible) {
    if (!values.containsKey(answer.key)) continue;
    final value = values[answer.key];
    final selected = answer.selection == Selection.single
        ? (value is String && answer.options.contains(value)
              ? <String>[value]
              : throw const _Invalid('invalid-scalar-answer'))
        : _strings(value, answer.options);
    if (selected.length > 1 && selected.any(answer.exclusiveOptions.contains)) {
      throw const _Invalid('exclusive-option-conflict');
    }
    parsed[answer.key] = List.unmodifiable(selected);
  }
  for (final answer in visible) {
    var applicable = true;
    if (answer.parentKey != null) {
      final parent = parsed[answer.parentKey];
      if (parent == null) throw const _Invalid('missing-parent-evidence');
      applicable = !parent.any(answer.hiddenForParentOptions.contains);
    }
    if (applicable && !parsed.containsKey(answer.key)) {
      throw _Invalid('missing-answer:${answer.key}');
    }
    if (!applicable && parsed.containsKey(answer.key)) {
      throw _Invalid('stale-nonapplicable-answer:${answer.key}');
    }
  }
  return Map.unmodifiable(parsed);
}

void _semantics(String? semantics, Iterable<Object?> lights) {
  if (semantics == futureSemantics) return;
  if (semantics != null && semantics != legacySemantics) {
    throw const _Invalid('unknown-semantics');
  }
  if (lights.any((v) => v == 'amber' || v == 'yellow')) {
    throw const _Invalid('legacy-amber-review-required');
  }
  // Unversioned green/red remains structurally validated, not auto-reset.
}

Map<String, Light> _lightMap(
  Object? raw,
  List<String> vocabulary,
  String? semantics,
) {
  if (raw is! List<RawLight>) {
    throw const _Invalid('invalid-light-entry-evidence');
  }
  _semantics(semantics, raw.map((entry) => entry.value));
  final parsed = <String, Light>{};
  for (final entry in raw) {
    final key = entry.option;
    final light = parseLight(entry.value);
    if (key is! String ||
        !vocabulary.contains(key) ||
        parsed.containsKey(key) ||
        light == null) {
      throw const _Invalid('invalid-or-duplicate-light');
    }
    parsed[key] = light;
  }
  if (parsed.length != vocabulary.length) {
    throw const _Invalid('missing-required-light');
  }
  return Map.unmodifiable(parsed);
}

class _Preference {
  final Map<String, Light> lights;
  final List<String> hards;
  const _Preference(this.lights, this.hards);
}

Map<String, _Preference> _preferences(
  Manifest manifest,
  DirectionalInput input,
) {
  final controls = manifest.controlsForPool(input.permittedPool);
  final expected = {for (final c in controls) c.id: c};
  final parsed = <String, _Preference>{};
  for (final pref in input.preferences) {
    final control = expected[pref.id];
    if (control == null || parsed.containsKey(pref.id)) {
      throw const _Invalid('unknown-or-duplicate-preference-control');
    }
    final lights = _lightMap(pref.lights, control.options, pref.semantics);
    final hards = _strings(pref.hards, control.options, empty: true);
    if (!control.hardSupported && hards.isNotEmpty) {
      throw const _Invalid('unsupported-hard-requirement');
    }
    parsed[pref.id] = _Preference(lights, hards);
  }
  if (parsed.length != controls.length) {
    throw const _Invalid('missing-required-control');
  }
  return Map.unmodifiable(parsed);
}

const _chapter2Keys = {
  'sect',
  'revert',
  'country_of_birth',
  'nationality',
  'ethnicity',
  'languages',
};

Map<String, Map<String, Object?>> _chapter2Preferences(
  Manifest manifest,
  List<RawChapter2> raw, {
  bool requireComplete = true,
}) {
  final blocks = <String, Map<String, Object?>>{};
  for (final block in raw) {
    if (!_chapter2Keys.contains(block.key) || blocks.containsKey(block.key)) {
      throw const _Invalid('unknown-or-duplicate-chapter2-control');
    }
    if (block.key == 'sect') {
      final fields = _fields(block.fields, {
        'matrix',
        'hard_requirement',
        'outside_flexibility',
      });
      final vocabulary = manifest.chapter2Vocabulary['sect']!;
      final matrix = _lightMap(fields['matrix'], vocabulary, block.semantics);
      if (!fields.containsKey('hard_requirement')) {
        throw const _Invalid('missing-sect-hards');
      }
      final hards = _strings(
        fields['hard_requirement'],
        vocabulary,
        empty: true,
      );
      _semantics(
        block.semantics,
        fields.containsKey('outside_flexibility')
            ? [fields['outside_flexibility']]
            : [],
      );
      if (fields.containsKey('outside_flexibility') &&
          parseLight(fields['outside_flexibility']) == null) {
        throw const _Invalid('invalid-unscored-outside-flexibility');
      }
      blocks[block.key] = {'matrix': matrix, 'hard_requirement': hards};
    } else if (block.key == 'revert') {
      final fields = _fields(block.fields, {'flexibility'});
      _semantics(block.semantics, [fields['flexibility']]);
      final light = parseLight(fields['flexibility']);
      if (light == null) {
        throw const _Invalid('missing-or-invalid-revert-light');
      }
      blocks[block.key] = {'flexibility': light};
    } else {
      final fields = _fields(block.fields, {
        'preferred',
        'flexibility',
        'skipped',
      });
      final skipped = fields['skipped'];
      if (skipped is! bool) {
        throw const _Invalid('missing-or-invalid-skipped-evidence');
      }
      if (!fields.containsKey('preferred')) {
        throw const _Invalid('missing-preferred');
      }
      final preferred = _strings(
        fields['preferred'],
        manifest.chapter2Vocabulary[block.key]!,
        empty: true,
      );
      final rawLight = fields['flexibility'];
      _semantics(
        block.semantics,
        fields.containsKey('flexibility') ? [rawLight] : [],
      );
      Light? light;
      if (fields.containsKey('flexibility')) {
        light = parseLight(rawLight);
        if (light == null) throw const _Invalid('invalid-flexibility');
      }
      if (!skipped && preferred.isNotEmpty && light == null) {
        throw const _Invalid('missing-required-flexibility');
      }
      if (skipped && preferred.isNotEmpty) {
        throw const _Invalid('contradictory-skip');
      }
      blocks[block.key] = {
        'preferred': preferred,
        'skipped': skipped,
        'flexibility': light,
      };
    }
  }
  if (requireComplete && blocks.length != _chapter2Keys.length) {
    throw const _Invalid('missing-chapter2-control');
  }
  return Map.unmodifiable(blocks);
}

/// Single-control research repair check; never certifies a whole direction.
String? chapter2ControlRepairReason(Manifest manifest, RawChapter2 control) {
  final configError = validateManifest(manifest);
  if (configError != null) return 'configuration:$configError';
  try {
    _chapter2Preferences(manifest, [control], requireComplete: false);
    return null;
  } on _Invalid catch (error) {
    return error.reason;
  }
}

Map<String, Object?> _chapter2Answers(Manifest manifest, List<RawField> raw) {
  final fields = _fields(raw, {..._chapter2Keys, 'location'});
  if (!_chapter2Keys.every(fields.containsKey)) {
    throw const _Invalid('missing-chapter2-answer');
  }
  for (final key in _chapter2Keys) {
    final value = fields[key];
    if (key == 'revert') {
      if (value is! bool) throw const _Invalid('invalid-revert-evidence');
    } else if (key == 'languages') {
      fields[key] = _strings(value, manifest.chapter2Vocabulary[key]!);
    } else {
      if (value is! String ||
          !manifest.chapter2Vocabulary[key]!.contains(value)) {
        throw const _Invalid('invalid-chapter2-vocabulary');
      }
    }
  }
  if (fields.containsKey('location') &&
      (fields['location'] is! String ||
          (fields['location'] as String).trim().isEmpty)) {
    throw const _Invalid('invalid-unscored-location');
  }
  return Map.unmodifiable(fields);
}

/// Deterministic internal precedence: config, owner, target, hards, units.
/// Public target failure is deliberately reasonless; this is not a server API.
ValidationOutcome validateDirectionalInputs(
  Manifest manifest,
  DirectionalInput input,
) {
  final configError = validateManifest(manifest);
  if (configError != null) return ConfigurationFailure(configError);
  Map<String, _Preference> prefs;
  Map<String, Map<String, Object?>> ch2Prefs;
  try {
    if (!input.rawEntryEvidence) {
      throw const _Invalid('lossy-entry-representation');
    }
    if (input.permittedPool.length != 1 ||
        !input.permittedPool.contains(input.targetSex)) {
      throw const _Invalid('invalid-counterpart-pool');
    }
    _answers(manifest, input.viewerSex, input.ownAnswers);
    prefs = _preferences(manifest, input);
    ch2Prefs = _chapter2Preferences(manifest, input.chapter2Preferences);
  } on _Invalid catch (error) {
    return OwnerRepairRequired(error.reason);
  }
  Map<String, List<String>> target;
  Map<String, Object?> ch2Target;
  try {
    target = _answers(manifest, input.targetSex, input.targetAnswers);
    ch2Target = _chapter2Answers(manifest, input.chapter2Answers);
  } on _Invalid {
    return const TargetUnavailable();
  }

  final units = <ValidatedUnit>[];
  for (final control in manifest.controlsForPool(input.permittedPool)) {
    if (!control.targetPool.contains(input.targetSex)) continue;
    final selected = target[control.targetKey];
    if (selected == null) {
      continue; // Only a validated, correctly skipped child.
    }
    final pref = prefs[control.id]!;
    if (selected.any(pref.hards.contains)) return const HardExcluded();
    units.add(
      ValidatedUnit(
        control.id,
        control.category,
        selected.map((option) => pref.lights[option]!),
      ),
    );
  }
  final sect = ch2Prefs['sect']!;
  final targetSect = ch2Target['sect'] as String;
  if ((sect['hard_requirement'] as List<String>).contains(targetSect)) {
    return const HardExcluded();
  }
  units.add(
    ValidatedUnit('ch2:sect', 'deen_practice', [
      (sect['matrix'] as Map<String, Light>)[targetSect]!,
    ]),
  );
  if (ch2Target['revert'] == true) {
    units.add(
      ValidatedUnit('ch2:revert', 'deen_practice', [
        ch2Prefs['revert']!['flexibility'] as Light,
      ]),
    );
  }
  for (final key in [
    'country_of_birth',
    'nationality',
    'ethnicity',
    'languages',
  ]) {
    final pref = ch2Prefs[key]!;
    if (pref['skipped'] == true) continue;
    final preferred = (pref['preferred'] as List<String>)
        .where((v) => key != 'languages' || v != 'en')
        .toList();
    if (preferred.isEmpty) continue; // Explicit governed no-preference state.
    final matches = key == 'languages'
        ? (ch2Target[key] as List<String>).any(preferred.contains)
        : preferred.contains(ch2Target[key]);
    units.add(
      ValidatedUnit('ch2:$key', 'culture_language', [
        matches ? Light.green : pref['flexibility'] as Light,
      ]),
    );
  }
  return ValidatedInputs(
    units,
    manifest.categories,
    contractVersion: manifest.version,
  );
}
