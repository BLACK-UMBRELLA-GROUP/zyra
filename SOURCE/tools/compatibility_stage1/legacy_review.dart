// Pure simulated targeted review. No app restore/save path or persistence.
import 'models.dart';
import 'validator.dart';
import 'manifest.dart';

class LegacyReviewPlan {
  final Set<String> amberControls;
  final Set<String> structuralControls;
  final Set<String> unknownSemanticsControls;

  LegacyReviewPlan(
    Iterable<String> amber,
    Iterable<String> structural,
    Iterable<String> unknown,
  ) : amberControls = Set.unmodifiable(amber),
      structuralControls = Set.unmodifiable(structural),
      unknownSemanticsControls = Set.unmodifiable(unknown);

  bool get ready =>
      amberControls.isEmpty &&
      structuralControls.isEmpty &&
      unknownSemanticsControls.isEmpty;
}

LegacyReviewPlan planLegacyReview(
  Iterable<PreferenceDefinition> definitions,
  List<RawPreference> raw,
) {
  final expected = <String, PreferenceDefinition>{};
  final targets = <String>{};
  final concepts = <String>{};
  for (final control in definitions) {
    if (expected.containsKey(control.id) ||
        !targets.add(control.targetKey) ||
        !concepts.add(control.targetKey.split('::').first) ||
        control.options.isEmpty ||
        control.options.toSet().length != control.options.length ||
        control.semanticsVersion != futureSemantics) {
      throw ArgumentError('Invalid review-control configuration');
    }
    expected[control.id] = control;
  }
  final amber = <String>{};
  final structural = <String>{};
  final unknown = <String>{};
  final seen = <String>{};
  for (final pref in raw) {
    final control = expected[pref.id];
    if (control == null || !seen.add(pref.id)) {
      structural.add(pref.id);
      continue;
    }
    if (pref.semantics != null &&
        pref.semantics != legacySemantics &&
        pref.semantics != futureSemantics) {
      unknown.add(pref.id);
    }
    final options = <String>{};
    for (final entry in pref.lights) {
      final option = entry.option;
      final legacyAmber =
          pref.semantics != futureSemantics &&
          (entry.value == 'amber' || entry.value == 'yellow');
      if (legacyAmber) amber.add(pref.id);
      if (option is! String ||
          !control.options.contains(option) ||
          !options.add(option) ||
          (!legacyAmber && parseLight(entry.value) == null)) {
        structural.add(pref.id);
      }
    }
    if (options.length != control.options.length) structural.add(pref.id);
    final hards = <String>{};
    for (final hard in pref.hards) {
      if (hard is! String ||
          !control.options.contains(hard) ||
          !hards.add(hard) ||
          !control.hardSupported) {
        structural.add(pref.id);
      }
    }
  }
  structural.addAll(expected.keys.where((key) => !seen.contains(key)));
  return LegacyReviewPlan(amber, structural, unknown);
}

class ReviewReceipt {
  final String controlId;
  final List<RawLight> reviewedLights;
  final List<Object?> reviewedHards;
  final List<String> reviewedVocabulary;
  ReviewReceipt(
    this.controlId,
    Iterable<RawLight> lights,
    Iterable<Object?> hards,
    Iterable<String> vocabulary,
  ) : reviewedLights = List.unmodifiable(lights),
      reviewedHards = List.unmodifiable(hards),
      reviewedVocabulary = List.unmodifiable(vocabulary);
}

/// Simulate only the specific control's successful review; never certify peers.
List<RawPreference> applyReviewReceipt(
  List<RawPreference> raw,
  PreferenceDefinition definition,
  ReviewReceipt receipt, {
  required bool saveSucceeded,
}) {
  if (!saveSucceeded) return List.unmodifiable(raw);
  if (receipt.controlId != definition.id ||
      receipt.reviewedVocabulary.length != definition.options.length ||
      !receipt.reviewedVocabulary.every(definition.options.contains) ||
      receipt.reviewedVocabulary.toSet().length != definition.options.length) {
    throw ArgumentError('Receipt target/vocabulary mismatch');
  }
  final replacement = RawPreference(
    definition.id,
    receipt.reviewedLights,
    hards: receipt.reviewedHards,
  );
  if (!planLegacyReview([definition], [replacement]).ready) {
    throw ArgumentError('Incomplete reviewed control');
  }
  if (raw.where((p) => p.id == definition.id).length != 1) {
    throw ArgumentError('Alias/duplicate repair requires separate review');
  }
  return List.unmodifiable([
    for (final pref in raw) pref.id == definition.id ? replacement : pref,
  ]);
}

const _chapter2ReviewKeys = {
  'sect',
  'revert',
  'country_of_birth',
  'nationality',
  'ethnicity',
  'languages',
};

/// Explicit vocabulary bound to a simulated receipt, not a live capture schema.
List<String> chapter2ReviewVocabulary(Manifest manifest, String key) {
  final error = validateManifest(manifest);
  if (error != null) throw ArgumentError('Invalid review configuration:$error');
  if (!_chapter2ReviewKeys.contains(key)) {
    throw ArgumentError('Unknown Chapter2 control');
  }
  return key == 'revert'
      ? const ['green', 'amber', 'red']
      : manifest.chapter2Vocabulary[key]!;
}

LegacyReviewPlan planChapter2LegacyReview(
  Manifest manifest,
  List<RawChapter2> raw,
) {
  final error = validateManifest(manifest);
  if (error != null) throw ArgumentError('Invalid review configuration:$error');
  final amber = <String>{};
  final structural = <String>{};
  final unknown = <String>{};
  final seen = <String>{};
  for (final block in raw) {
    final id = 'ch2:${block.key}';
    if (!_chapter2ReviewKeys.contains(block.key) || !seen.add(block.key)) {
      structural.add(id);
      continue;
    }
    if (block.semantics != null &&
        block.semantics != legacySemantics &&
        block.semantics != futureSemantics) {
      unknown.add(id);
    }
    Object? inspectLight(Object? value) {
      final affected =
          block.semantics != futureSemantics &&
          (value == 'amber' || value == 'yellow');
      if (affected) amber.add(id);
      // A temporary structural check only. The original capture is never changed.
      return affected && value == 'yellow' ? 'amber' : value;
    }

    final checkedFields = [
      for (final field in block.fields)
        RawField(
          field.key,
          field.key == 'matrix' && field.value is List<RawLight>
              ? [
                  for (final entry in field.value as List<RawLight>)
                    RawLight(entry.option, inspectLight(entry.value)),
                ]
              : field.key == 'flexibility' || field.key == 'outside_flexibility'
              ? inspectLight(field.value)
              : field.value,
        ),
    ];
    final structuralOnly = RawChapter2(block.key, checkedFields);
    if (chapter2ControlRepairReason(manifest, structuralOnly) != null) {
      structural.add(id);
    }
  }
  structural.addAll(
    _chapter2ReviewKeys
        .where((key) => !seen.contains(key))
        .map((key) => 'ch2:$key'),
  );
  return LegacyReviewPlan(amber, structural, unknown);
}

class Chapter2ReviewReceipt {
  final String controlKey;
  final List<RawField> reviewedFields;
  final List<String> reviewedVocabulary;
  Chapter2ReviewReceipt(
    this.controlKey,
    Iterable<RawField> fields,
    Iterable<String> vocabulary,
  ) : reviewedFields = List.unmodifiable(fields),
      reviewedVocabulary = List.unmodifiable(vocabulary);
}

/// Simulated successful review of exactly one Chapter2 control; no persistence.
List<RawChapter2> applyChapter2ReviewReceipt(
  Manifest manifest,
  List<RawChapter2> raw,
  Chapter2ReviewReceipt receipt, {
  required bool saveSucceeded,
}) {
  if (!saveSucceeded) return List.unmodifiable(raw);
  final vocabulary = chapter2ReviewVocabulary(manifest, receipt.controlKey);
  if (receipt.reviewedVocabulary.length != vocabulary.length ||
      receipt.reviewedVocabulary.toSet().length != vocabulary.length ||
      !receipt.reviewedVocabulary.every(vocabulary.contains)) {
    throw ArgumentError('Receipt vocabulary mismatch');
  }
  final replacement = RawChapter2(receipt.controlKey, receipt.reviewedFields);
  if (chapter2ControlRepairReason(manifest, replacement) != null) {
    throw ArgumentError('Incomplete reviewed Chapter2 control');
  }
  if (raw.where((block) => block.key == receipt.controlKey).length != 1) {
    throw ArgumentError('Duplicate/missing repair requires separate review');
  }
  return List.unmodifiable([
    for (final block in raw)
      block.key == receipt.controlKey ? replacement : block,
  ]);
}
