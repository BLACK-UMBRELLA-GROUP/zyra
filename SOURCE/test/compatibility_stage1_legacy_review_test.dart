import 'package:flutter_test/flutter_test.dart';

import '../tools/compatibility_stage1/legacy_review.dart';
import '../tools/compatibility_stage1/manifest.dart';
import '../tools/compatibility_stage1/models.dart';
import 'support/compatibility_stage1_fixtures.dart';

void main() {
  final manifest = buildManifest();
  final controls = manifest.controlsForPool({Sex.female});
  final input = syntheticInput(manifest);
  final first = controls.first;
  RawPreference amber(
    PreferenceDefinition control, {
    String? semantics = legacySemantics,
  }) => RawPreference(control.id, [
    for (final o in control.options) RawLight(o, 'amber'),
  ], semantics: semantics);

  test('only affected legacy amber controls need semantic review', () {
    final raw = [
      for (final pref in input.preferences)
        pref.id == first.id
            ? amber(first)
            : RawPreference(pref.id, pref.lights, semantics: null),
    ];
    final plan = planLegacyReview(controls, raw);
    expect(plan.amberControls, {first.id});
    expect(plan.structuralControls, isEmpty);
    expect(plan.unknownSemanticsControls, isEmpty);
    expect(plan.ready, isFalse);
    expect(() => plan.amberControls.clear(), throwsUnsupportedError);
  });
  test(
    'future amber is valid; legacy yellow does not get silently translated',
    () {
      expect(
        planLegacyReview(
          [first],
          [amber(first, semantics: futureSemantics)],
        ).ready,
        isTrue,
      );
      final old = RawPreference(first.id, [
        for (final o in first.options) RawLight(o, 'yellow'),
      ], semantics: legacySemantics);
      expect(planLegacyReview([first], [old]).amberControls, {first.id});
      expect(old.lights.first.value, 'yellow');
      expect(old.semantics, legacySemantics);
    },
  );
  test(
    'green/red-only unversioned data is structurally checked, not bank-reset',
    () {
      final valid = RawPreference(first.id, [
        for (final o in first.options) RawLight(o, 'red'),
      ], semantics: null);
      expect(planLegacyReview([first], [valid]).ready, isTrue);
      final missing = RawPreference(
        first.id,
        valid.lights.skip(1),
        semantics: null,
      );
      expect(planLegacyReview([first], [missing]).structuralControls, {
        first.id,
      });
      expect(planLegacyReview([first], [missing]).amberControls, isEmpty);
    },
  );
  test(
    'unknown provenance, duplicates, hards and unknown lights require repair',
    () {
      final unknown = RawPreference(
        first.id,
        input.preferences.first.lights,
        semantics: 'guessed-from-date',
      );
      expect(planLegacyReview([first], [unknown]).unknownSemanticsControls, {
        first.id,
      });
      expect(planLegacyReview([first], [unknown, unknown]).structuralControls, {
        first.id,
      });
      final malformed = RawPreference(
        first.id,
        [const RawLight('unknown-option', 'purple')],
        hards: ['unknown-option'],
      );
      expect(planLegacyReview([first], [malformed]).structuralControls, {
        first.id,
      });
    },
  );
  test('q26 same wording never certifies a stale hidden alias', () {
    final female = controls.singleWhere((c) => c.id == 'pref:ch3_q26::female');
    final stale = RawPreference('pref:ch3_q26::male', [
      const RawLight("I'm unsure", 'green'),
    ]);
    final plan = planLegacyReview([female], [stale]);
    expect(plan.structuralControls, {female.id, stale.id});
    expect(
      () => applyReviewReceipt(
        [stale],
        female,
        ReviewReceipt(
          female.id,
          [for (final o in female.options) RawLight(o, 'green')],
          [],
          female.options,
        ),
        saveSucceeded: true,
      ),
      throwsArgumentError,
    );
  });
  test(
    'review configuration rejects both q26 variants in one editable state',
    () {
      final aliases = manifest.preferences
          .where((c) => c.targetKey.startsWith('ch3_q26::'))
          .toList();
      expect(aliases, hasLength(2));
      expect(
        () => planLegacyReview(aliases, [
          for (final c in aliases)
            RawPreference(c.id, [
              for (final option in c.options) RawLight(option, 'green'),
            ]),
        ]),
        throwsArgumentError,
      );
    },
  );
  test(
    'one successful control receipt cannot certify another affected control',
    () {
      final second = controls[1];
      final raw = [
        for (final pref in input.preferences)
          if (pref.id == first.id)
            amber(first)
          else if (pref.id == second.id)
            amber(second)
          else
            pref,
      ];
      final receipt = ReviewReceipt(
        first.id,
        [for (final o in first.options) RawLight(o, 'amber')],
        [],
        first.options,
      );
      final reviewed = applyReviewReceipt(
        raw,
        first,
        receipt,
        saveSucceeded: true,
      );
      expect(planLegacyReview(controls, reviewed).amberControls, {second.id});
      expect(
        reviewed.singleWhere((p) => p.id == first.id).semantics,
        futureSemantics,
      );
      expect(
        identical(
          reviewed.singleWhere((p) => p.id == second.id),
          raw.singleWhere((p) => p.id == second.id),
        ),
        isTrue,
      );
      expect(() => reviewed.clear(), throwsUnsupportedError);
    },
  );
  test(
    'cancelled/failed save leaves raw preferences and provenance unchanged',
    () {
      final raw = [amber(first)];
      final receipt = ReviewReceipt(
        first.id,
        [for (final o in first.options) RawLight(o, 'green')],
        [],
        first.options,
      );
      final result = applyReviewReceipt(
        raw,
        first,
        receipt,
        saveSucceeded: false,
      );
      expect(identical(result.single, raw.single), isTrue);
      expect(result.single.semantics, legacySemantics);
    },
  );
  test('receipt requires exact target, vocabulary and all option lights', () {
    final raw = [amber(first)];
    expect(
      () => applyReviewReceipt(
        raw,
        first,
        ReviewReceipt('wrong-control', [], [], first.options),
        saveSucceeded: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => applyReviewReceipt(
        raw,
        first,
        ReviewReceipt(first.id, [], [], first.options),
        saveSucceeded: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => applyReviewReceipt(
        raw,
        first,
        ReviewReceipt(
          first.id,
          [for (final o in first.options) RawLight(o, 'green')],
          [],
          [...first.options, first.options.first],
        ),
        saveSucceeded: true,
      ),
      throwsArgumentError,
    );
  });
  test(
    'q26 reviewed hard removal cannot resurrect a stale excluded option',
    () {
      final control = controls.singleWhere(
        (c) => c.id == 'pref:ch3_q26::female',
      );
      final old = RawPreference(
        control.id,
        [for (final o in control.options) RawLight(o, 'red')],
        hards: [control.options.first],
        semantics: legacySemantics,
      );
      final reviewed = applyReviewReceipt(
        [old],
        control,
        ReviewReceipt(
          control.id,
          [for (final o in control.options) RawLight(o, 'green')],
          [],
          control.options,
        ),
        saveSucceeded: true,
      );
      expect(reviewed.single.hards, isEmpty);
      expect(old.hards, isNotEmpty);
    },
  );

  RawChapter2 chapter2Amber(
    String key, {
    String? semantics = legacySemantics,
    String value = 'amber',
  }) {
    if (key == 'sect') {
      return RawChapter2(key, [
        RawField('matrix', [
          for (final option in manifest.chapter2Vocabulary[key]!)
            RawLight(option, value),
        ]),
        const RawField('hard_requirement', <String>[]),
      ], semantics: semantics);
    }
    if (key == 'revert') {
      return RawChapter2(key, [
        RawField('flexibility', value),
      ], semantics: semantics);
    }
    final option = manifest.chapter2Vocabulary[key]!.firstWhere(
      (v) => key != 'languages' || v != 'en',
    );
    return RawChapter2(key, [
      RawField('preferred', [option]),
      const RawField('skipped', false),
      RawField('flexibility', value),
    ], semantics: semantics);
  }

  for (final key in [
    'sect',
    'revert',
    'country_of_birth',
    'nationality',
    'ethnicity',
    'languages',
  ]) {
    test(
      'Chapter2 $key legacy Amber is targeted; future receipt preserves peers',
      () {
        final peer = key == 'revert' ? 'sect' : 'revert';
        final raw = [
          for (final block in input.chapter2Preferences)
            if (block.key == key || block.key == peer)
              chapter2Amber(block.key)
            else
              block,
        ];
        expect(planChapter2LegacyReview(manifest, raw).amberControls, {
          'ch2:$key',
          'ch2:$peer',
        });
        final future = chapter2Amber(key, semantics: futureSemantics);
        final reviewed = applyChapter2ReviewReceipt(
          manifest,
          raw,
          Chapter2ReviewReceipt(
            key,
            future.fields,
            chapter2ReviewVocabulary(manifest, key),
          ),
          saveSucceeded: true,
        );
        expect(planChapter2LegacyReview(manifest, reviewed).amberControls, {
          'ch2:$peer',
        });
        expect(
          reviewed.singleWhere((b) => b.key == key).semantics,
          futureSemantics,
        );
        for (final original in raw.where((b) => b.key != key)) {
          expect(
            identical(
              original,
              reviewed.singleWhere((b) => b.key == original.key),
            ),
            isTrue,
          );
        }
        expect(raw.singleWhere((b) => b.key == key).semantics, legacySemantics);
        expect(() => reviewed.clear(), throwsUnsupportedError);
      },
    );
  }
  test('Chapter2 legacy yellow is reviewed, not automatically rewritten', () {
    final old = chapter2Amber('revert', value: 'yellow');
    final raw = [
      for (final block in input.chapter2Preferences)
        block.key == 'revert' ? old : block,
    ];
    final plan = planChapter2LegacyReview(manifest, raw);
    expect(plan.amberControls, {'ch2:revert'});
    expect(plan.structuralControls, isEmpty);
    expect(old.fields.single.value, 'yellow');
  });
  test(
    'Chapter2 invalid manifest is configuration failure, not owner repair',
    () {
      final invalid = Manifest(
        answers: manifest.answers,
        preferences: manifest.preferences,
        categories: manifest.categories,
        bankProvenance: manifest.bankProvenance,
        chapter2Vocabulary: {
          for (final entry in manifest.chapter2Vocabulary.entries)
            if (entry.key != 'sect') entry.key: entry.value,
        },
      );
      expect(
        () => planChapter2LegacyReview(invalid, input.chapter2Preferences),
        throwsArgumentError,
      );
      expect(
        () => chapter2ReviewVocabulary(invalid, 'sect'),
        throwsArgumentError,
      );
      expect(
        () => applyChapter2ReviewReceipt(
          invalid,
          input.chapter2Preferences,
          Chapter2ReviewReceipt('sect', [], []),
          saveSucceeded: true,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'Chapter2 unversioned green/red controls need structure, not Amber reset',
    () {
      final raw = [
        for (final block in input.chapter2Preferences)
          RawChapter2(block.key, block.fields, semantics: null),
      ];
      expect(planChapter2LegacyReview(manifest, raw).ready, isTrue);
      final broken = [
        for (final block in raw)
          block.key == 'sect'
              ? RawChapter2(
                  'sect',
                  block.fields.where((f) => f.key != 'hard_requirement'),
                  semantics: null,
                )
              : block,
      ];
      final plan = planChapter2LegacyReview(manifest, broken);
      expect(plan.amberControls, isEmpty);
      expect(plan.structuralControls, {'ch2:sect'});
    },
  );
  test(
    'Chapter2 outside flexibility Amber is affected even while unscored',
    () {
      final sect = input.chapter2Preferences.singleWhere(
        (b) => b.key == 'sect',
      );
      final raw = [
        for (final block in input.chapter2Preferences)
          block.key == 'sect'
              ? RawChapter2('sect', [
                  ...sect.fields.where(
                    (field) => field.key != 'outside_flexibility',
                  ),
                  const RawField('outside_flexibility', 'amber'),
                ], semantics: null)
              : block,
      ];
      expect(planChapter2LegacyReview(manifest, raw).amberControls, {
        'ch2:sect',
      });
      expect(
        planChapter2LegacyReview(manifest, raw).structuralControls,
        isEmpty,
      );
    },
  );
  test(
    'Chapter2 unknown semantics and malformed controls are never certified',
    () {
      final raw = [
        for (final block in input.chapter2Preferences)
          block.key == 'nationality'
              ? RawChapter2(block.key, block.fields, semantics: 'unknown')
              : block,
      ];
      expect(planChapter2LegacyReview(manifest, raw).unknownSemanticsControls, {
        'ch2:nationality',
      });
      expect(
        planChapter2LegacyReview(manifest, [
          ...raw,
          raw.first,
        ]).structuralControls,
        {'ch2:sect'},
      );
      expect(
        planChapter2LegacyReview(
          manifest,
          raw.skip(1).toList(),
        ).structuralControls,
        {'ch2:sect'},
      );
      expect(
        planChapter2LegacyReview(manifest, [
          ...raw,
          RawChapter2('unknown', []),
        ]).structuralControls,
        {'ch2:unknown'},
      );
    },
  );
  test(
    'Chapter2 cancelled or failed save preserves provenance and old hards',
    () {
      final raw = [
        for (final block in input.chapter2Preferences)
          block.key == 'sect'
              ? RawChapter2('sect', [
                  RawField('matrix', [
                    for (final o in manifest.chapter2Vocabulary['sect']!)
                      RawLight(o, 'red'),
                  ]),
                  RawField('hard_requirement', [
                    manifest.chapter2Vocabulary['sect']!.first,
                  ]),
                ], semantics: legacySemantics)
              : block,
      ];
      final future = chapter2Amber('sect', semantics: futureSemantics);
      final receipt = Chapter2ReviewReceipt(
        'sect',
        future.fields,
        chapter2ReviewVocabulary(manifest, 'sect'),
      );
      final failed = applyChapter2ReviewReceipt(
        manifest,
        raw,
        receipt,
        saveSucceeded: false,
      );
      expect(identical(failed.first, raw.first), isTrue);
      final saved = applyChapter2ReviewReceipt(
        manifest,
        raw,
        receipt,
        saveSucceeded: true,
      );
      expect(
        saved.first.fields
            .singleWhere((f) => f.key == 'hard_requirement')
            .value,
        isEmpty,
      );
      expect(
        raw.first.fields.singleWhere((f) => f.key == 'hard_requirement').value,
        isNotEmpty,
      );
    },
  );
  test(
    'Chapter2 receipts reject missing/duplicate controls, vocabulary and fields',
    () {
      final block = chapter2Amber('revert', semantics: futureSemantics);
      final vocabulary = chapter2ReviewVocabulary(manifest, 'revert');
      final receipt = Chapter2ReviewReceipt('revert', block.fields, vocabulary);
      expect(
        () => applyChapter2ReviewReceipt(
          manifest,
          input.chapter2Preferences.where((b) => b.key != 'revert').toList(),
          receipt,
          saveSucceeded: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => applyChapter2ReviewReceipt(
          manifest,
          [...input.chapter2Preferences, block],
          receipt,
          saveSucceeded: true,
        ),
        throwsArgumentError,
      );
      for (final invalid in [
        Chapter2ReviewReceipt('revert', [], vocabulary),
        Chapter2ReviewReceipt('revert', [
          ...block.fields,
          ...block.fields,
        ], vocabulary),
        Chapter2ReviewReceipt('revert', block.fields, [
          'green',
          'amber',
          'amber',
        ]),
        Chapter2ReviewReceipt('unknown', block.fields, vocabulary),
      ]) {
        expect(
          () => applyChapter2ReviewReceipt(
            manifest,
            input.chapter2Preferences,
            invalid,
            saveSucceeded: true,
          ),
          throwsArgumentError,
        );
      }
    },
  );
}
