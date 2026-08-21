/// The truthful ownership of the pause holds on one Journey.
///
/// A pause is not a request that the other person approves. Each person may
/// place or lift their own hold, and the Journey rests while either hold is
/// present. Keeping this tiny policy outside the screen makes the live state,
/// development preview and regression tests use exactly the same rules.
enum ZyraJourneyPauseState { none, you, them, both }

abstract final class ZyraJourneyPausePolicy {
  static ZyraJourneyPauseState resolve({
    required String? currentUserId,
    required String? suspendedBy,
    required String? alsoPausedBy,
  }) {
    final iHold =
        currentUserId != null &&
        (suspendedBy == currentUserId || alsoPausedBy == currentUserId);
    final otherHolds =
        suspendedBy != null && suspendedBy != currentUserId ||
        alsoPausedBy != null && alsoPausedBy != currentUserId;

    if (iHold && otherHolds) return ZyraJourneyPauseState.both;
    if (iHold) return ZyraJourneyPauseState.you;
    if (otherHolds) return ZyraJourneyPauseState.them;
    return ZyraJourneyPauseState.none;
  }

  /// Preview-only counterpart of lifting the signed-in member's hold.
  static ZyraJourneyPauseState liftMine(ZyraJourneyPauseState state) =>
      switch (state) {
        ZyraJourneyPauseState.you => ZyraJourneyPauseState.none,
        ZyraJourneyPauseState.both => ZyraJourneyPauseState.them,
        _ => state,
      };

  /// Preview-only counterpart of adding the signed-in member's own hold.
  static ZyraJourneyPauseState alsoPause(ZyraJourneyPauseState state) =>
      state == ZyraJourneyPauseState.them ? ZyraJourneyPauseState.both : state;
}
