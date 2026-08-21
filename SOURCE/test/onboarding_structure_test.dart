import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/data/compatibility_categories.dart';
import 'package:zyra/data/onboarding_category_guidance.dart';
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/models/onboarding_question.dart';

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

    test('maps every scored Values topic into one reveal category', () {
      final scoredQuestionIds = <String>{
        for (final category in chapter3Categories)
          for (final question in category.questions)
            if (question.ch4Status != Ch4Status.none) question.id,
      };
      final mappedIds = [
        for (final category in compatibilityCategories) ...category.questionIds,
      ];

      expect(compatibilityCategories, hasLength(12));
      expect(mappedIds.toSet(), scoredQuestionIds);
      expect(mappedIds, hasLength(scoredQuestionIds.length));
      expect(scoredQuestionIds, hasLength(71));
      expect(
        compatibilityCategories
            .singleWhere((category) => category.id == 'culture_location')
            .comesFromProfile,
        isTrue,
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
