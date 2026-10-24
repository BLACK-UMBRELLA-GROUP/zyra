// Unwired Stage 1 research metadata only; no application behavior is changed.
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/data/zyra_reference_data.dart';
import 'package:zyra/models/onboarding_question.dart';

import 'models.dart';

/// Own-answer SOURCE file SHA-256 preserved in the Round 2 packet and rechecked
/// before Stage 1 source creation (not the packet's different content hash).
/// This is source provenance, not a version of any member's captured answers.
const staticBankProvenance =
    'sha256:5208df8f7315d5d4a29a890a57268700c2c5bcda88e4f8ec4e329c9a7394e52d';

/// Copy metadata without retaining a write path into the runtime bank.
///
/// Sect is not a fixed global product vocabulary: existing capture permits a
/// canonical custom slug. Only explicitly registered research codes are
/// supported here. The finite registry is not a production normalization or
/// migration policy; those boundaries remain later OA193/OA285 work.
BankSnapshot readStaticBankSnapshot({
  Iterable<String> registeredSectCodes = const ['sunni', 'shia'],
}) => BankSnapshot(
  answers: [
    for (final category in chapter3Categories)
      for (final question in category.questions)
        AnswerDefinition(
          key: question.responseKey,
          questionId: question.id,
          variant: switch (question.genderVisibility) {
            GenderVisibility.all => null,
            GenderVisibility.menOnly => Sex.male,
            GenderVisibility.womenOnly => Sex.female,
          },
          options: question.options,
          selection: switch (question.selectionType) {
            QuestionSelectionType.single => Selection.single,
            QuestionSelectionType.multi => Selection.multi,
          },
          preferenceEligible: question.ch4Status != Ch4Status.none,
          hardSupported: question.hardRequirementSupported,
          // Preserve own-answer dependencies as metadata only. Do not call
          // visibleGiven(viewer): prospective capture resolves the target.
          parentKey: question.showIf?.questionId,
          hiddenForParentOptions: question.showIf?.notAnyOf ?? const [],
          exclusiveOptions: const {'ch3_q37', 'ch3_q97'}.contains(question.id)
              ? const ['None']
              : const [],
          // This is source presentation metadata, not calculation authority.
          // buildManifest explicitly assigns canonical categories by qid.
          category: category.id,
        ),
  ],
  chapter2Vocabulary: {
    'sect': registeredSectCodes.toList(),
    'country_of_birth': [for (final item in zyraCountries) item.code],
    'nationality': [for (final item in zyraCountries) item.code],
    'ethnicity': [for (final item in zyraEthnicities) item.code],
    'languages': [for (final item in zyraLanguages) item.code],
    // Recognized captured metadata, deliberately not a scoring unit.
    'location': [for (final item in zyraLocationPreferences) item.code],
  },
  provenance: staticBankProvenance,
);
