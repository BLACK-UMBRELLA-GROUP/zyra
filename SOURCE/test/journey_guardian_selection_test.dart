import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/data/zyra_journey_guardian_selection.dart';

void main() {
  group('Journey Guardian selection', () {
    test('selecting an Additional Guardian also selects the Main', () {
      expect(ZyraJourneyGuardianSelection.toggle(const <int>{}, 4), {0, 4});
    });

    test('all five Additional Guardians can be selected', () {
      var selected = const <int>{};
      for (var index = 1; index < 6; index++) {
        selected = ZyraJourneyGuardianSelection.toggle(selected, index);
      }
      expect(selected, {0, 1, 2, 3, 4, 5});
    });

    test('clearing the Main clears the mock Guardian network', () {
      expect(ZyraJourneyGuardianSelection.toggle({0, 2, 5}, 0), isEmpty);
    });

    test('clearing one Additional Guardian preserves the others', () {
      expect(ZyraJourneyGuardianSelection.toggle({0, 1, 3}, 1), {0, 3});
    });

    test('an out-of-range choice cannot alter the selection', () {
      expect(ZyraJourneyGuardianSelection.toggle({0, 2}, 6), {0, 2});
    });

    test('the other family portrait preview opens with its Main Guardian', () {
      final preview = ZyraJourneyGuardianSelection.otherGuardianPreview;

      expect(preview, isNotEmpty);
      expect(preview.first.isMain, isTrue);
      expect(preview.skip(1).every((guardian) => !guardian.isMain), isTrue);
    });

    test(
      'the other family portrait preview is independent of my selection',
      () {
        final before = ZyraJourneyGuardianSelection.otherGuardianPreview;
        final mySelection = ZyraJourneyGuardianSelection.toggle(const {}, 5);

        expect(mySelection, {0, 5});
        expect(ZyraJourneyGuardianSelection.otherGuardianPreview, same(before));
      },
    );
  });

  group('Journey Guardian mutual reveal', () {
    test('one reveal never opens the Guardian identities', () {
      expect(
        ZyraJourneyGuardianRevealPolicy.resolve(mine: true, theirs: false),
        ZyraJourneyGuardianRevealState.mineWaiting,
      );
      expect(
        ZyraJourneyGuardianRevealPolicy.canViewGuardians(
          mine: true,
          theirs: false,
        ),
        isFalse,
      );
    });

    test('both reveals open the Guardian identities', () {
      expect(
        ZyraJourneyGuardianRevealPolicy.resolve(mine: true, theirs: true),
        ZyraJourneyGuardianRevealState.revealed,
      );
      expect(
        ZyraJourneyGuardianRevealPolicy.canViewGuardians(
          mine: true,
          theirs: true,
        ),
        isTrue,
      );
    });
  });

  group('Journey Guardian optional Salams', () {
    test('moves from the Main Guardian to the next ungreeted portrait', () {
      expect(
        ZyraJourneyGuardianSalamPolicy.nextUngreeted(
          currentIndex: 0,
          greetedIndices: {0},
          guardianCount: 3,
        ),
        1,
      );
    });

    test('skips Guardians who already received Salam', () {
      expect(
        ZyraJourneyGuardianSalamPolicy.nextUngreeted(
          currentIndex: 0,
          greetedIndices: {0, 1},
          guardianCount: 3,
        ),
        2,
      );
    });

    test('does not force another action after everybody was greeted', () {
      expect(
        ZyraJourneyGuardianSalamPolicy.nextUngreeted(
          currentIndex: 2,
          greetedIndices: {0, 1, 2},
          guardianCount: 3,
        ),
        isNull,
      );
    });
  });
}
