import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/data/zyra_journey_life_snapshot.dart';
import 'package:zyra/data/zyra_journey_stages.dart';

void main() {
  group('Journey Life Snapshot mock', () {
    test('sits visually between Compatibility and Guardian Gate', () {
      expect(ZyraJourneyStages.previewAll.length, 9);
      expect(ZyraJourneyStages.previewAll.map((stage) => stage.value), [
        'salam_exchange',
        'compatibility_reveal',
        'life_snapshot_preview',
        'wali_gate',
        'phase_1',
        'phase_2',
        'phase_3',
        'family_stage',
        'conversation',
      ]);
      expect(ZyraJourneyStages.previewAll.last.order, 9);
    });

    test('supports a completely empty optional Bio section', () {
      expect(
        ZyraJourneyLifeSnapshotMock.toggle(
          ZyraJourneyLifeSnapshotMock.defaultVisibleFieldIds,
          'occupation',
        ),
        isNot(contains('occupation')),
      );
      expect(ZyraJourneyLifeSnapshotMock.bio.length, lessThanOrEqualTo(1000));
    });

    test('unknown field ids cannot enter the sharing set', () {
      expect(
        ZyraJourneyLifeSnapshotMock.toggle(const {'occupation'}, 'unknown'),
        {'occupation'},
      );
    });

    test('profiles stay closed until both people reveal', () {
      expect(
        ZyraJourneyLifeSnapshotRevealPolicy.canViewSnapshot(
          mine: true,
          theirs: false,
        ),
        isFalse,
      );
      expect(
        ZyraJourneyLifeSnapshotRevealPolicy.canViewSnapshot(
          mine: true,
          theirs: true,
        ),
        isTrue,
      );
    });

    test('all four mutual reveal states are distinct', () {
      expect(
        ZyraJourneyLifeSnapshotRevealPolicy.resolve(mine: false, theirs: false),
        ZyraJourneyLifeSnapshotRevealState.neither,
      );
      expect(
        ZyraJourneyLifeSnapshotRevealPolicy.resolve(mine: true, theirs: false),
        ZyraJourneyLifeSnapshotRevealState.mineWaiting,
      );
      expect(
        ZyraJourneyLifeSnapshotRevealPolicy.resolve(mine: false, theirs: true),
        ZyraJourneyLifeSnapshotRevealState.theirsWaiting,
      );
      expect(
        ZyraJourneyLifeSnapshotRevealPolicy.resolve(mine: true, theirs: true),
        ZyraJourneyLifeSnapshotRevealState.revealed,
      );
    });
  });
}
