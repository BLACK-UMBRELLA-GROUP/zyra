import 'package:flutter_test/flutter_test.dart';

import '../tools/compatibility_stage1/manifest.dart';
import '../tools/compatibility_stage1/models.dart';
import '../tools/compatibility_stage1/validator.dart';
import 'support/compatibility_stage1_fixtures.dart';

void main() {
  final manifest = buildManifest();
  const parentChoices = ['Yes', 'No', 'If Allah wills', 'Unsure'];
  group('Unwired Stage 1 counterpart applicability', () {
    test(
      'keeps own-answer keys separate from mandatory prospective controls',
      () {
        for (final target in Sex.values) {
          final controls = manifest.controlsForPool({target});
          final eligible = manifest.answers.where(
            (answer) => answer.preferenceEligible && answer.visibleTo(target),
          );
          expect(
            controls.map((control) => control.targetKey).toSet(),
            eligible.map((answer) => answer.key).toSet(),
          );
          for (final control in controls) {
            final answer = manifest.answers.singleWhere(
              (answer) => answer.key == control.targetKey,
            );
            expect(control.id, 'pref:${answer.key}');
            expect(control.id, isNot(answer.key));
            expect(control.options, answer.options);
            expect(control.targetPool, contains(target));
          }
        }
        expect(manifest.controlsForPool({Sex.male}), hasLength(71));
        expect(manifest.controlsForPool({Sex.female}), hasLength(70));
        // These are static offered-control inventories, never pair denominators.
        expect(
          manifest.answers
              .singleWhere((answer) => answer.key == 'ch3_q24')
              .parentKey,
          'ch3_q3',
        );
        expect(
          manifest.answers
              .singleWhere((answer) => answer.key == 'ch3_q24')
              .hiddenForParentOptions,
          ['No'],
        );
      },
    );

    for (final viewer in Sex.values) {
      final target = viewer == Sex.male ? Sex.female : Sex.male;
      for (final ownQ3 in parentChoices) {
        for (final targetQ3 in parentChoices) {
          test(
            'q24 ${viewer.name} own=$ownQ3 target=$targetQ3 uses target condition only',
            () {
              final input = syntheticInput(
                manifest,
                viewerSex: viewer,
                targetSex: target,
                ownQ3: ownQ3,
                targetQ3: targetQ3,
              );
              expect(
                input.preferences.any(
                  (control) => control.id == 'pref:ch3_q24',
                ),
                isTrue,
              );
              expect(
                input.ownAnswers.any((answer) => answer.key == 'ch3_q24'),
                ownQ3 != 'No',
              );
              final outcome = validateDirectionalInputs(manifest, input);
              expect(outcome, isA<ValidatedInputs>());
              expect(
                (outcome as ValidatedInputs).units.any(
                  (unit) => unit.id == 'pref:ch3_q24',
                ),
                targetQ3 != 'No',
              );
            },
          );
        }
      }
    }

    test(
      'q24 missing or malformed target parent is unavailable, not nonapplicable',
      () {
        final input = syntheticInput(manifest);
        for (final invalid in <Object?>[
          null,
          'Unknown',
          [],
          ['No'],
          1,
        ]) {
          expect(
            validateDirectionalInputs(
              manifest,
              replaceAnswer(input, 'ch3_q3', invalid),
            ),
            isA<TargetUnavailable>(),
          );
        }
        expect(
          validateDirectionalInputs(
            manifest,
            copyInput(
              input,
              targetAnswers: input.targetAnswers.where(
                (answer) => answer.key != 'ch3_q3',
              ),
            ),
          ),
          isA<TargetUnavailable>(),
        );
        final noChildren = syntheticInput(manifest, targetQ3: 'No');
        final timing = manifest.answers.singleWhere(
          (answer) => answer.key == 'ch3_q24',
        );
        expect(
          validateDirectionalInputs(
            manifest,
            replaceAnswer(noChildren, timing.key, timing.options.first),
          ),
          isA<TargetUnavailable>(),
        );
      },
    );

    test(
      'q24 capture is not suppressed when all applicable target parent branches are Hard-excluded',
      () {
        final input = syntheticInput(manifest, ownQ3: 'No', targetQ3: 'Yes');
        final control = manifest.preferences.singleWhere(
          (control) => control.id == 'pref:ch3_q3',
        );
        final withHards = replacePreference(
          input,
          RawPreference(
            control.id,
            [
              for (final option in control.options)
                RawLight(option, option == 'No' ? 'green' : 'red'),
            ],
            hards: ['Yes', 'If Allah wills', 'Unsure'],
          ),
        );
        expect(
          withHards.preferences.any((control) => control.id == 'pref:ch3_q24'),
          isTrue,
        );
        expect(
          validateDirectionalInputs(manifest, withHards),
          isA<HardExcluded>(),
        );
        final missingTimingControl = copyInput(
          withHards,
          preferences: withHards.preferences.where(
            (control) => control.id != 'pref:ch3_q24',
          ),
        );
        expect(
          validateDirectionalInputs(manifest, missingTimingControl),
          isA<OwnerRepairRequired>(),
        );
      },
    );

    test(
      'q26 uses exact target variant and never translates shared Unsure',
      () {
        final male = manifest.answers.singleWhere(
          (answer) => answer.key == 'ch3_q26::male',
        );
        final female = manifest.answers.singleWhere(
          (answer) => answer.key == 'ch3_q26::female',
        );
        expect(male.options.toSet().intersection(female.options.toSet()), {
          "I'm unsure",
        });
        for (final viewer in Sex.values) {
          final target = viewer == Sex.male ? Sex.female : Sex.male;
          final key = 'ch3_q26::${target.name}';
          final input = syntheticInput(
            manifest,
            viewerSex: viewer,
            targetSex: target,
          );
          expect(
            input.preferences.any((control) => control.id == 'pref:$key'),
            isTrue,
          );
          expect(
            input.preferences.any(
              (control) => control.id == 'pref:ch3_q26::${viewer.name}',
            ),
            isFalse,
          );
          expect(
            validateDirectionalInputs(
              manifest,
              replaceAnswer(input, key, "I'm unsure"),
            ),
            isA<ValidatedInputs>(),
          );
          final ambiguous = copyInput(
            input,
            targetAnswers: [
              ...input.targetAnswers.where((answer) => answer.key != key),
              const RawField('ch3_q26', "I'm unsure"),
            ],
          );
          expect(
            validateDirectionalInputs(manifest, ambiguous),
            isA<TargetUnavailable>(),
          );
          final wrongVocabulary = manifest.answers
              .singleWhere((answer) => answer.key == 'ch3_q26::${viewer.name}')
              .options
              .first;
          expect(
            validateDirectionalInputs(
              manifest,
              replaceAnswer(input, key, wrongVocabulary),
            ),
            isA<TargetUnavailable>(),
          );
        }
      },
    );

    test(
      'q26 stale hidden control cannot overwrite active lights or resurrect a removed hard',
      () {
        final input = syntheticInput(manifest);
        final stale = manifest.preferences.singleWhere(
          (control) => control.id == 'pref:ch3_q26::male',
        );
        final contaminated = copyInput(
          input,
          preferences: [
            ...input.preferences,
            RawPreference(
              stale.id,
              [for (final option in stale.options) RawLight(option, 'red')],
              hards: ["I'm unsure"],
            ),
          ],
        );
        expect(
          validateDirectionalInputs(manifest, contaminated),
          isA<OwnerRepairRequired>(),
        );
        expect(
          validateDirectionalInputs(manifest, input),
          isA<ValidatedInputs>(),
        );
        expect(
          input.preferences
              .singleWhere((control) => control.id == 'pref:ch3_q26::female')
              .hards,
          isEmpty,
        );
      },
    );

    test(
      'q39 follows male-counterpart pool, independently of viewer own Masjid visibility',
      () {
        final femaleViewer = syntheticInput(
          manifest,
          viewerSex: Sex.female,
          targetSex: Sex.male,
        );
        expect(
          femaleViewer.ownAnswers.any(
            (answer) => answer.key == 'ch3_q39::male',
          ),
          isFalse,
        );
        expect(
          femaleViewer.preferences.any(
            (control) => control.id == 'pref:ch3_q39::male',
          ),
          isTrue,
        );
        final result = validateDirectionalInputs(manifest, femaleViewer);
        expect(result, isA<ValidatedInputs>());
        expect(
          (result as ValidatedInputs).units.any(
            (unit) => unit.id == 'pref:ch3_q39::male',
          ),
          isTrue,
        );
        expect(
          validateDirectionalInputs(
            manifest,
            copyInput(
              femaleViewer,
              preferences: femaleViewer.preferences.where(
                (control) => control.id != 'pref:ch3_q39::male',
              ),
            ),
          ),
          isA<OwnerRepairRequired>(),
        );
        expect(
          validateDirectionalInputs(
            manifest,
            copyInput(
              femaleViewer,
              targetAnswers: femaleViewer.targetAnswers.where(
                (answer) => answer.key != 'ch3_q39::male',
              ),
            ),
          ),
          isA<TargetUnavailable>(),
        );
        final maleViewer = syntheticInput(manifest);
        expect(
          maleViewer.ownAnswers.any((answer) => answer.key == 'ch3_q39::male'),
          isTrue,
        );
        expect(
          maleViewer.preferences.any(
            (control) => control.id == 'pref:ch3_q39::male',
          ),
          isFalse,
        );
      },
    );

    test('empty or dual-variant pool is not a valid editable owner state', () {
      final input = syntheticInput(manifest);
      for (final pool in <Set<Sex>>[
        {},
        {Sex.male, Sex.female},
      ]) {
        expect(
          validateDirectionalInputs(
            manifest,
            copyInput(input, permittedPool: pool),
          ),
          isA<OwnerRepairRequired>(),
        );
      }
    });

    test(
      'None exclusivity is explicit only for q37/q97, not inferred for q62',
      () {
        for (final answer in manifest.answers) {
          expect(
            answer.exclusiveOptions,
            const {'ch3_q37', 'ch3_q97'}.contains(answer.questionId)
                ? ['None']
                : isEmpty,
            reason: answer.key,
          );
        }
        final q62 = manifest.answers.singleWhere(
          (answer) => answer.key == 'ch3_q62',
        );
        expect(q62.selection, Selection.multi);
        expect(q62.preferenceEligible, isFalse);
        expect(
          manifest.preferences.any((control) => control.targetKey == q62.key),
          isFalse,
        );
      },
    );
  });
}
