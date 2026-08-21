/// One optional fact a Seeker may choose to place in their Journey-only Bio
/// section. These values are mock data for the Active Journey preview; they do
/// not read or expose the private onboarding answer store.
class ZyraJourneyLifeSnapshotField {
  final String id;
  final String section;
  final String label;
  final String value;

  const ZyraJourneyLifeSnapshotField({
    required this.id,
    required this.section,
    required this.label,
    required this.value,
  });
}

enum ZyraJourneyLifeSnapshotRevealState {
  neither,
  mineWaiting,
  theirsWaiting,
  revealed,
}

abstract final class ZyraJourneyLifeSnapshotRevealPolicy {
  static ZyraJourneyLifeSnapshotRevealState resolve({
    required bool mine,
    required bool theirs,
  }) {
    if (mine && theirs) return ZyraJourneyLifeSnapshotRevealState.revealed;
    if (mine) return ZyraJourneyLifeSnapshotRevealState.mineWaiting;
    if (theirs) return ZyraJourneyLifeSnapshotRevealState.theirsWaiting;
    return ZyraJourneyLifeSnapshotRevealState.neither;
  }

  static bool canRevealMine({required bool mine}) => !mine;

  static bool canViewSnapshot({required bool mine, required bool theirs}) =>
      mine && theirs;
}

abstract final class ZyraJourneyLifeSnapshotMock {
  static const int bioCharacterLimit = 1000;

  static const String bio =
      'I am someone who values faith, family and a peaceful home. I work in '
      'product design and enjoy thoughtful conversations, long walks, cooking '
      'for the people close to me and continuing to learn about my Deen. I am '
      'looking for a marriage built on kindness, honesty and teamwork, where '
      'we can laugh together, speak openly when life is difficult and help '
      'each other grow without expecting perfection.';

  static const List<ZyraJourneyLifeSnapshotField> fields = [
    ZyraJourneyLifeSnapshotField(
      id: 'occupation',
      section: 'Work & education',
      label: 'Occupation',
      value: 'Product designer',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'employment',
      section: 'Work & education',
      label: 'Employment',
      value: 'Employed full-time',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'work_pattern',
      section: 'Work & education',
      label: 'Working pattern',
      value: 'Hybrid · Standard daytime hours',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'education',
      section: 'Work & education',
      label: 'Education',
      value: "Bachelor's degree",
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'marriage_status',
      section: 'Family & marriage',
      label: 'Marriage status',
      value: 'Never married',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'children',
      section: 'Family & marriage',
      label: 'Children',
      value: 'No children',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'future_children',
      section: 'Family & marriage',
      label: 'Future children',
      value: 'If Allah wills',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'responsibilities',
      section: 'Family & marriage',
      label: 'Family responsibilities',
      value: 'Supports parents occasionally',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'income',
      section: 'Practical life',
      label: 'Income range',
      value: '£40,000 – £59,999',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'financial_position',
      section: 'Practical life',
      label: 'Financial position',
      value: 'Mostly ready · Student finance only',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'home',
      section: 'Practical life',
      label: 'Current home',
      value: 'Living with family',
    ),
    ZyraJourneyLifeSnapshotField(
      id: 'relocation',
      section: 'Practical life',
      label: 'Relocation',
      value: 'Open for the right person',
    ),
  ];

  static const Set<String> defaultVisibleFieldIds = {
    'occupation',
    'employment',
    'work_pattern',
    'education',
    'marriage_status',
    'children',
    'future_children',
    'responsibilities',
    'income',
    'financial_position',
    'home',
    'relocation',
  };

  static Set<String> toggle(Set<String> current, String id) {
    if (!fields.any((field) => field.id == id)) {
      return Set<String>.unmodifiable(current);
    }
    final next = <String>{...current};
    if (!next.remove(id)) next.add(id);
    return Set<String>.unmodifiable(next);
  }
}
