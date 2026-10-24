import 'zyra_wali_journey_service.dart';
import 'zyra_wali_link_service.dart';

enum GuardianDashboardAttentionKind { familyReview, guardianGate }

final class GuardianDashboardAttention {
  final GuardianDashboardAttentionKind kind;
  final WaliJourneyView journey;
  final String title;
  final String detail;
  final String actionLabel;

  const GuardianDashboardAttention({
    required this.kind,
    required this.journey,
    required this.title,
    required this.detail,
    required this.actionLabel,
  });
}

final class GuardianDashboardResolution {
  final List<GuardianDashboardAttention> attention;
  final int linkedSeekerCount;
  final int needsYouCount;

  const GuardianDashboardResolution({
    required this.attention,
    required this.linkedSeekerCount,
    required this.needsYouCount,
  });
}

/// Pure Guardian Dashboard decision layer.
///
/// The adapter remains the existing screen-owned group of permitted reads;
/// this resolver accepts only their returned domain values. It cannot query
/// Browse decisions, infer private Seeker behaviour, or widen RLS.
final class ZyraGuardianDashboardResolver {
  const ZyraGuardianDashboardResolver();

  GuardianDashboardResolution resolve({
    required List<WaliLinkedPerson> linkedPeople,
    required List<WaliJourneyView> journeys,
    required Set<String> openReviewIds,
  }) {
    // A Guardian may be Main for one Seeker and Additional for another.
    // Partition authority before inspecting any Journey field so a stale,
    // injected or over-broad Additional-owned row cannot affect priority,
    // copy, ordering or aggregates.
    final mainSeekerIds = {
      for (final person in linkedPeople)
        if (person.isMain) person.id,
    };
    final familyReviews = <GuardianDashboardAttention>[];
    final guardianGates = <GuardianDashboardAttention>[];

    for (final journey in journeys) {
      if (!mainSeekerIds.contains(journey.linkedSeekerId)) continue;
      if (journey.status == 'ended') continue;
      if (openReviewIds.contains(journey.matchId)) {
        familyReviews.add(
          GuardianDashboardAttention(
            kind: GuardianDashboardAttentionKind.familyReview,
            journey: journey,
            title: '${journey.linkedSeekerName} needs your Family Review',
            detail:
                'Both families decide whether this Journey continues. '
                'Your decision is waiting.',
            actionLabel: 'Review',
          ),
        );
      } else if (!journey.isJourneyLocked &&
          journey.journeyStage == 'wali_gate') {
        guardianGates.add(
          GuardianDashboardAttention(
            kind: GuardianDashboardAttentionKind.guardianGate,
            journey: journey,
            title: '${journey.linkedSeekerName} needs a Guardian step',
            detail:
                'The Journey is waiting at the Guardian Gate. '
                'Only a Guardian can complete this step.',
            actionLabel: 'Open',
          ),
        );
      }
    }

    final attention = [...familyReviews, ...guardianGates];
    final seekersNeedingAttention = {
      for (final item in attention) item.journey.linkedSeekerId,
    };

    return GuardianDashboardResolution(
      attention: attention,
      linkedSeekerCount: linkedPeople.length,
      needsYouCount: seekersNeedingAttention.length,
    );
  }
}
