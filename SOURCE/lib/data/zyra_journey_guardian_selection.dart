/// Selection rules for the six Stage 3 developer Guardians.
///
/// Index 0 is the one Main Guardian. The other five are Additional
/// Guardians. Selecting an Additional Guardian also selects the Main because
/// the app cannot truthfully preview an Additional-only Guardian network;
/// clearing the Main clears the whole mock network for the same reason.
abstract final class ZyraJourneyGuardianSelection {
  static const int guardianCount = 6;
  static const int mainIndex = 0;

  /// The other Seeker's display-only Guardian family used by the Active
  /// Journey developer preview. This is deliberately separate from
  /// [toggle]: that set represents *your* Guardian network and is only used
  /// to prove that the Stage 4 gate can be satisfied. Showing those people
  /// as the introductions awaiting you would reverse whose family the page
  /// is about.
  ///
  /// Main is always first so the portrait pager opens on the person who
  /// carries that responsibility. Production data keeps the same ordering.
  static const List<({String firstName, String relationship, bool isMain})>
  otherGuardianPreview = [
    (firstName: 'Ibrahim', relationship: 'uncle', isMain: true),
    (firstName: 'Maryam', relationship: 'sister', isMain: false),
    (firstName: 'Yusuf', relationship: 'grandfather', isMain: false),
  ];

  static Set<int> toggle(Set<int> current, int index) {
    if (index < 0 || index >= guardianCount) {
      return Set<int>.unmodifiable(current);
    }

    final next = <int>{...current};
    if (index == mainIndex) {
      if (next.contains(mainIndex)) {
        next.clear();
      } else {
        next.add(mainIndex);
      }
      return Set<int>.unmodifiable(next);
    }

    if (!next.remove(index)) {
      next
        ..add(mainIndex)
        ..add(index);
    }
    return Set<int>.unmodifiable(next);
  }
}

enum ZyraJourneyGuardianRevealState {
  neither,
  mineWaiting,
  theirsWaiting,
  revealed,
}

/// Stage 4 is a mutual identity threshold. A Seeker can offer their reveal,
/// but neither family opens for only one person's decision.
abstract final class ZyraJourneyGuardianRevealPolicy {
  static ZyraJourneyGuardianRevealState resolve({
    required bool mine,
    required bool theirs,
  }) {
    if (mine && theirs) return ZyraJourneyGuardianRevealState.revealed;
    if (mine) return ZyraJourneyGuardianRevealState.mineWaiting;
    if (theirs) return ZyraJourneyGuardianRevealState.theirsWaiting;
    return ZyraJourneyGuardianRevealState.neither;
  }

  static bool canRevealMine({required bool mine}) => !mine;

  static bool canViewGuardians({required bool mine, required bool theirs}) =>
      mine && theirs;
}

/// Salams after the reveal are optional and belong to one Guardian portrait,
/// not to the Stage 4 gate. After a greeting, move to the next person who has
/// not received one so offering several Salams stays quick without forcing
/// the member to greet everybody.
abstract final class ZyraJourneyGuardianSalamPolicy {
  static int? nextUngreeted({
    required int currentIndex,
    required Set<int> greetedIndices,
    required int guardianCount,
  }) {
    if (guardianCount <= 0) return null;
    for (var offset = 1; offset <= guardianCount; offset++) {
      final candidate = (currentIndex + offset) % guardianCount;
      if (!greetedIndices.contains(candidate)) return candidate;
    }
    return null;
  }
}
