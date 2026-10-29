import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/onboarding_bank_contract.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/data/onboarding_category_guidance.dart';
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';

void main() {
  group('Founder-approved onboarding structure', () {
    test('keeps every original Values question exactly once per gender', () {
      List<OnboardingQuestion> visibleFor(String gender) => [
        for (final category in chapter3Categories)
          ...category.questions.where(
            (question) => question.visibleFor(gender),
          ),
      ];

      final men = visibleFor('male');
      final women = visibleFor('female');

      expect(chapter3Categories, hasLength(11));
      expect(men.map((question) => question.id).toSet(), hasLength(104));
      expect(men, hasLength(104));
      expect(women.map((question) => question.id).toSet(), hasLength(103));
      expect(women, hasLength(103));
      expect(men.map((question) => question.id).toSet(), {
        for (var index = 1; index <= 104; index++) 'ch3_q$index',
      });
    });

    test('keeps the two ch3_q26 client variants distinct', () {
      final variants = chapter3Categories
          .expand((category) => category.questions)
          .where((question) => question.id == 'ch3_q26')
          .toList();

      expect(variants, hasLength(2));
      expect(variants.map((question) => question.responseKey).toSet(), {
        'ch3_q26::male',
        'ch3_q26::female',
      });
      expect(variants[0].options, isNot(variants[1].options));
      final clientAnswers = <String, dynamic>{
        variants[0].responseKey: variants[0].options.first,
        variants[1].responseKey: variants[1].options.last,
      };
      expect(clientAnswers, hasLength(2));
      expect(clientAnswers, containsPair('ch3_q26::male', isNotNull));
      expect(clientAnswers, containsPair('ch3_q26::female', isNotNull));
      expect(
        variants.map(
          (question) => ZyraOnboardingAnswersService.persistedQuestionId(
            question.responseKey,
          ),
        ),
        everyElement('ch3_q26'),
      );
    });

    test('SQL question-bank suite is generated from the Dart bank', () {
      final sql = File(
        'supabase/tests/zyra_onboarding_bank_suite.sql',
      ).readAsStringSync();
      const startMarker = '-- BEGIN DART-GENERATED BANK';
      const endMarker = '-- END DART-GENERATED BANK';
      String generatedBlock(String source) {
        final start = source.indexOf(startMarker);
        final end = source.indexOf(endMarker);
        expect(start, greaterThanOrEqualTo(0));
        expect(end, greaterThan(start));
        return source
            .substring(start + startMarker.length, end)
            .replaceFirst(RegExp(r'^\r?\n'), '')
            .trimRight();
      }

      final actual = generatedBlock(sql);
      expect(actual, onboardingBankExpectedSqlValues());
      expect(onboardingBankContract, hasLength(105));

      // Evidence for OA-ZYRA-196's failure mode: simulate one question being
      // removed from only the SQL copy. The exact detector must disagree.
      final oneSidedSql = sql.replaceFirst(
        "    ('ch3_q104', 'all', false, NULL, '[]'::jsonb)",
        '',
      );
      expect(
        generatedBlock(oneSidedSql),
        isNot(onboardingBankExpectedSqlValues()),
      );
    });

    test('provides one transition message for every question section', () {
      expect(onboardingCategoryGuidance, hasLength(chapter3Categories.length));
      expect(
        onboardingCategoryGuidance.map((guidance) => guidance.categoryId),
        orderedEquals(chapter3Categories.map((category) => category.id)),
      );
      for (final guidance in onboardingCategoryGuidance) {
        expect(guidance.description, isNotEmpty);
      }
    });
  });

  group('Journey Bio privacy model', () {
    test('supports a completely empty optional Bio', () {
      const bio = JourneyBio();

      expect(bio.isEmpty, isTrue);
      expect(bio.sharedItemCount, 0);
      expect(bio.toOnboardingAnswers()['bio_show_about_me'], isFalse);
    });

    test('serialises only populated and explicitly shared Journey fields', () {
      const bio = JourneyBio(
        aboutMe: '  Faith, family and a peaceful home.  ',
        showAboutMe: true,
        fieldValues: {'occupation': ' Product designer ', 'income': ''},
        visibleFieldIds: {'occupation', 'income'},
      );

      final payload = bio.toOnboardingAnswers();
      expect(payload['bio_about_me'], 'Faith, family and a peaceful home.');
      expect(payload['bio_fields'], {'occupation': 'Product designer'});
      expect(payload['bio_visible_field_ids'], ['occupation']);
      expect(bio.sharedItemCount, 2);
    });

    test('the biography limit remains locked at 400 characters', () {
      expect(JourneyBio.characterLimit, 400);
    });
  });
}
