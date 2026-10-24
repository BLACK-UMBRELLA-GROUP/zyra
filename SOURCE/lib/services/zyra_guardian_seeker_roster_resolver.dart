import '../data/zyra_journey_stages.dart';
import 'zyra_wali_journey_service.dart';
import 'zyra_wali_link_service.dart';

/// The four ruled Main-Guardian roster groups, in product order.
enum GuardianSeekerRosterGroup {
  needsYou('NEEDS YOU'),
  inAJourney('IN A JOURNEY'),
  pausedOrWaiting('PAUSED OR WAITING'),
  otherSeekers('OTHER SEEKERS');

  final String label;
  const GuardianSeekerRosterGroup(this.label);
}

final class GuardianSeekerRosterEntry {
  final WaliLinkedPerson person;
  final WaliJourneyView? currentJourney;
  final GuardianSeekerRosterGroup? group;
  final bool needsAttention;
  final DateTime? waitingSince;
  final String contextLine;

  const GuardianSeekerRosterEntry({
    required this.person,
    required this.currentJourney,
    required this.group,
    required this.needsAttention,
    required this.waitingSince,
    required this.contextLine,
  });
}

final class GuardianSeekerRosterSection {
  final GuardianSeekerRosterGroup group;
  final List<GuardianSeekerRosterEntry> entries;

  const GuardianSeekerRosterSection({
    required this.group,
    required this.entries,
  });
}

final class GuardianSeekerRosterResolution {
  final List<GuardianSeekerRosterSection> mainSections;
  final List<GuardianSeekerRosterEntry> additionalGuardianships;

  const GuardianSeekerRosterResolution({
    required this.mainSections,
    required this.additionalGuardianships,
  });

  bool get isEmpty =>
      mainSections.every((section) => section.entries.isEmpty) &&
      additionalGuardianships.isEmpty;
}

/// Pure, authority-first resolver for the Guardian-side Seeker roster.
///
/// Additional Guardianships remain in one neutral alphabetical section. They
/// receive current Journey context only when the server participation view
/// contains their Seeker-authorised assignment; Main-only attention states
/// never change their heading, order, badge or priority.
final class ZyraGuardianSeekerRosterResolver {
  const ZyraGuardianSeekerRosterResolver();

  GuardianSeekerRosterResolution resolve({
    required List<WaliLinkedPerson> linkedPeople,
    required GuardianSeekerRosterContext context,
  }) {
    final mainPeople = linkedPeople.where((person) => person.isMain).toList();
    final currentBySeeker = <String, WaliJourneyView>{};
    for (final journey in context.journeys) {
      if (journey.status == 'ended') continue;
      currentBySeeker.putIfAbsent(journey.linkedSeekerId, () => journey);
    }
    final additional = linkedPeople.where((person) => !person.isMain).map((
      person,
    ) {
      final journey = currentBySeeker[person.id];
      return GuardianSeekerRosterEntry(
        person: person,
        currentJourney: journey,
        group: null,
        needsAttention: false,
        waitingSince: null,
        contextLine: _additionalContextLine(journey),
      );
    }).toList()..sort(_compareEntriesByName);

    final grouped =
        <GuardianSeekerRosterGroup, List<GuardianSeekerRosterEntry>>{
          for (final group in GuardianSeekerRosterGroup.values) group: [],
        };
    for (final person in mainPeople) {
      final journey = currentBySeeker[person.id];
      final reviewOpen =
          journey != null &&
          context.openReviewMatchIds.contains(journey.matchId);
      final guardianGate =
          journey != null &&
          !journey.isJourneyLocked &&
          journey.journeyStage == 'wali_gate';
      final needsAttention = reviewOpen || guardianGate;
      final group = needsAttention
          ? GuardianSeekerRosterGroup.needsYou
          : journey == null
          ? GuardianSeekerRosterGroup.otherSeekers
          : journey.isJourneyLocked ||
                journey.isSuspended ||
                journey.isPauseDecisionPending
          ? GuardianSeekerRosterGroup.pausedOrWaiting
          : GuardianSeekerRosterGroup.inAJourney;
      final entry = GuardianSeekerRosterEntry(
        person: person,
        currentJourney: journey,
        group: group,
        needsAttention: needsAttention,
        waitingSince: journey == null
            ? null
            : context.waitingSinceByMatchId[journey.matchId],
        contextLine: _contextLine(journey, reviewOpen: reviewOpen),
      );
      grouped[group]!.add(entry);
    }

    for (final group in GuardianSeekerRosterGroup.values) {
      final entries = grouped[group]!;
      if (group == GuardianSeekerRosterGroup.needsYou) {
        entries.sort(_compareNeedsYou);
      } else {
        entries.sort(_compareEntriesByName);
      }
    }

    return GuardianSeekerRosterResolution(
      mainSections: [
        for (final group in GuardianSeekerRosterGroup.values)
          GuardianSeekerRosterSection(group: group, entries: grouped[group]!),
      ],
      additionalGuardianships: additional,
    );
  }

  static String _contextLine(
    WaliJourneyView? journey, {
    required bool reviewOpen,
  }) {
    if (journey == null) return 'No current Journey';
    if (reviewOpen) return 'Family Review needs you';
    if (journey.isPauseDecisionPending) {
      return 'Journey awaiting a decision';
    }
    if (journey.isSuspended) return 'Journey paused';
    return 'Journey with ${journey.partner.firstName} · '
        '${ZyraJourneyStages.labelFor(journey.journeyStage)}';
  }

  static String _additionalContextLine(WaliJourneyView? journey) {
    if (journey == null) return 'Not included in an active Journey';
    if (journey.isPauseDecisionPending) return 'Journey awaiting a decision';
    if (journey.isSuspended) return 'Journey paused';
    return 'Journey with ${journey.partner.firstName} · '
        '${ZyraJourneyStages.labelFor(journey.journeyStage)}';
  }

  static int _compareNeedsYou(
    GuardianSeekerRosterEntry left,
    GuardianSeekerRosterEntry right,
  ) {
    final leftAt = left.waitingSince;
    final rightAt = right.waitingSince;
    if (leftAt != null && rightAt != null) {
      final byTime = leftAt.compareTo(rightAt);
      if (byTime != 0) return byTime;
    } else if (leftAt != null) {
      return -1;
    } else if (rightAt != null) {
      return 1;
    }
    return _compareEntriesByName(left, right);
  }

  static int _compareEntriesByName(
    GuardianSeekerRosterEntry left,
    GuardianSeekerRosterEntry right,
  ) {
    final byName = left.person.firstName.toLowerCase().compareTo(
      right.person.firstName.toLowerCase(),
    );
    if (byName != 0) return byName;
    return left.person.id.compareTo(right.person.id);
  }
}
