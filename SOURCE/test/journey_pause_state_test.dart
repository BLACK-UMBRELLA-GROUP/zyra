import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_pause_state.dart';

void main() {
  group('ZyraJourneyPausePolicy.resolve', () {
    test('no holds is a live Journey', () {
      expect(
        ZyraJourneyPausePolicy.resolve(
          currentUserId: 'me',
          suspendedBy: null,
          alsoPausedBy: null,
        ),
        ZyraJourneyPauseState.none,
      );
    });

    test('the current user may own the primary hold', () {
      expect(
        ZyraJourneyPausePolicy.resolve(
          currentUserId: 'me',
          suspendedBy: 'me',
          alsoPausedBy: null,
        ),
        ZyraJourneyPauseState.you,
      );
    });

    test('the current user may own the mirrored hold', () {
      expect(
        ZyraJourneyPausePolicy.resolve(
          currentUserId: 'me',
          suspendedBy: 'them',
          alsoPausedBy: 'me',
        ),
        ZyraJourneyPauseState.both,
      );
    });

    test('a single other-person hold is theirs', () {
      expect(
        ZyraJourneyPausePolicy.resolve(
          currentUserId: 'me',
          suspendedBy: 'them',
          alsoPausedBy: null,
        ),
        ZyraJourneyPauseState.them,
      );
    });

    test('an unavailable identity never claims someone else hold as yours', () {
      expect(
        ZyraJourneyPausePolicy.resolve(
          currentUserId: null,
          suspendedBy: 'them',
          alsoPausedBy: null,
        ),
        ZyraJourneyPauseState.them,
      );
    });
  });

  group('development pause preview transitions', () {
    test('lifting your sole hold returns to the live Journey', () {
      expect(
        ZyraJourneyPausePolicy.liftMine(ZyraJourneyPauseState.you),
        ZyraJourneyPauseState.none,
      );
    });

    test('lifting your hold keeps their hold in place', () {
      expect(
        ZyraJourneyPausePolicy.liftMine(ZyraJourneyPauseState.both),
        ZyraJourneyPauseState.them,
      );
    });

    test('also pause adds your own hold without replacing theirs', () {
      expect(
        ZyraJourneyPausePolicy.alsoPause(ZyraJourneyPauseState.them),
        ZyraJourneyPauseState.both,
      );
    });

    test('preview transitions do not invent actions in unrelated states', () {
      expect(
        ZyraJourneyPausePolicy.alsoPause(ZyraJourneyPauseState.you),
        ZyraJourneyPauseState.you,
      );
      expect(
        ZyraJourneyPausePolicy.liftMine(ZyraJourneyPauseState.them),
        ZyraJourneyPauseState.them,
      );
    });
  });
}
