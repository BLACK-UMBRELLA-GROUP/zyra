import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/data/zyra_journey_stages.dart';

void main() {
  group('canonical Journey sequence', () {
    test('contains the eight server stages in order', () {
      expect(ZyraJourneyStages.count, 8);
      expect(ZyraJourneyStages.all.map((stage) => stage.value), [
        'salam_exchange',
        'compatibility_reveal',
        'wali_gate',
        'phase_1',
        'phase_2',
        'phase_3',
        'family_stage',
        'conversation',
      ]);
      expect(ZyraJourneyStages.all.map((stage) => stage.order), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
      ]);
    });

    test('every stage has arrival and completion copy', () {
      for (final stage in ZyraJourneyStages.all) {
        expect(stage.introduction.trim(), isNotEmpty, reason: stage.value);
        expect(stage.completionHeading.trim(), isNotEmpty, reason: stage.value);
        expect(stage.completionLine.trim(), isNotEmpty, reason: stage.value);
      }
    });

    test('Salam arrival avoids repeating the formal stage name', () {
      final salam = ZyraJourneyStages.of('salam_exchange')!;
      expect(salam.arrivalTitle, 'Let’s begin');
      expect(salam.introduction, 'The first words can be simple.');
      expect(salam.arrivalTitle, isNot(contains(salam.label)));
      expect(salam.introduction, isNot(contains('Salam Exchange')));
    });

    test('upward history contains only stages completed before current', () {
      expect(ZyraJourneyStages.completedBefore('salam_exchange'), isEmpty);
      expect(
        ZyraJourneyStages.completedBefore(
          'compatibility_reveal',
        ).map((stage) => stage.value),
        ['salam_exchange'],
      );
      expect(
        ZyraJourneyStages.completedBefore(
          'phase_2',
        ).map((stage) => stage.value),
        ['salam_exchange', 'compatibility_reveal', 'wali_gate', 'phase_1'],
      );
      expect(ZyraJourneyStages.completedBefore('unknown'), isEmpty);
    });

    test('every stage has one canonical Timeline milestone', () {
      final types = ZyraJourneyStages.all
          .map((stage) => stage.timelineMilestoneType)
          .toList();
      expect(types.toSet().length, ZyraJourneyStages.count);
      for (final stage in ZyraJourneyStages.all) {
        expect(
          ZyraJourneyStages.ofTimelineMilestone(stage.timelineMilestoneType),
          same(stage),
          reason: stage.value,
        );
      }
    });

    test('sustained phases keep their guiding questions', () {
      for (final value in ['phase_1', 'phase_2', 'phase_3']) {
        final stage = ZyraJourneyStages.of(value);
        expect(stage, isNotNull);
        expect(stage!.kind, ZyraStageKind.sustained);
        expect(stage.guidingQuestion?.trim(), isNotEmpty, reason: value);
      }
    });

    test('Family Review stays an override, not a ninth stage', () {
      expect(ZyraJourneyStages.of('family_review'), isNull);
      expect(ZyraJourneyStages.familyReviewOverride, 'Family Review');
      expect(ZyraJourneyStages.all.last.value, 'conversation');
      expect(ZyraJourneyStages.all.last.kind, ZyraStageKind.destination);
    });
  });
}
