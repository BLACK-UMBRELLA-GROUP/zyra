import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/data/journey_questions.dart';

void main() {
  group('Journey answer character limits', () {
    test('Faith & Values is locked to 400 characters', () {
      expect(JourneyQuestions.answerCharacterLimitForPhase(1), 400);
      expect(JourneyQuestions.answerFitsCharacterLimit(1, 'a' * 400), isTrue);
      expect(JourneyQuestions.answerFitsCharacterLimit(1, 'a' * 401), isFalse);
    });

    test('the later phases remain unchanged', () {
      expect(JourneyQuestions.answerCharacterLimitForPhase(2), isNull);
      expect(JourneyQuestions.answerCharacterLimitForPhase(3), isNull);
      expect(JourneyQuestions.answerFitsCharacterLimit(2, 'a' * 1000), isTrue);
    });
  });

  group('Journey question chapter handoff', () {
    test('derives real question counts for all three question chapters', () {
      expect(JourneyQuestions.forStageValue('phase_1')?.length, 8);
      expect(JourneyQuestions.forStageValue('phase_2')?.length, 7);
      expect(JourneyQuestions.forStageValue('phase_3')?.length, 7);
    });

    test('does not add the handoff to non-question Journey stages', () {
      expect(JourneyQuestions.forStageValue('salam_exchange'), isNull);
      expect(JourneyQuestions.forStageValue('compatibility_reveal'), isNull);
      expect(JourneyQuestions.forStageValue('life_snapshot_preview'), isNull);
      expect(JourneyQuestions.forStageValue('wali_gate'), isNull);
      expect(JourneyQuestions.forStageValue('family_stage'), isNull);
      expect(JourneyQuestions.forStageValue('conversation'), isNull);
      expect(JourneyQuestions.forStageValue('phase_4'), isNull);
      expect(JourneyQuestions.forStageValue('phase_01'), isNull);
      expect(JourneyQuestions.forStageValue(null), isNull);
    });
  });
}
