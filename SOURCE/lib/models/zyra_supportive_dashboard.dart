import 'zyra_dashboard_resolution.dart';

/// Founder-review presentation categories, not new domain states or stores.
enum SupportiveSection {
  needsYou,
  stand,
  changed,
  fromZyra,
  working,
  repeating,
  learned,
  help;

  String get label => switch (this) {
    needsYou => 'What Needs You',
    stand => 'Where You Stand',
    changed => 'What Changed',
    fromZyra => 'From ZYRA',
    working => 'What’s Working',
    repeating => 'What Keeps Happening',
    learned => 'What You’ve Learned',
    help => 'What May Help',
  };

  bool get isInsight => index >= working.index;
}

final class SupportiveEvidence {
  final String summary;
  final String period;
  final String reason;
  final String limitation;

  const SupportiveEvidence({
    required this.summary,
    required this.period,
    required this.reason,
    required this.limitation,
  });

  bool get isComplete => [
    summary,
    period,
    reason,
    limitation,
  ].every((value) => value.trim().isNotEmpty);
}

/// A read-only presentation object. [id] is its explicit semantic identity;
/// titles, dates and guessed aliases are never used for deduplication.
final class SupportiveCard {
  final String id;
  final SupportiveSection section;
  final String title;
  final String? detail;
  final String? actionLabel;
  final ZyraDashboardTarget target;
  final DateTime? date;
  final bool? isUnread;

  /// Local attention state, independent of a notification read acknowledgement.
  final bool hasNewActivity;
  final SupportiveEvidence? evidence;
  final bool isGeneralGuide;
  final String? ownerLabel;

  const SupportiveCard({
    required this.id,
    required this.section,
    required this.title,
    this.detail,
    this.actionLabel,
    this.target = ZyraDashboardTarget.none,
    this.date,
    this.isUnread,
    this.hasNewActivity = false,
    this.evidence,
    this.isGeneralGuide = false,
    this.ownerLabel,
  });
}

/// Projects only evidence already present in the existing resolver. There is
/// no category-score calculation, new read, notification-derived obligation,
/// billing assumption, editorial source or intelligence processing here.
List<SupportiveCard> supportiveCardsFromResolution(
  DashboardResolution resolution, {
  required DateTime comparisonClock,
}) {
  final cards = <SupportiveCard>[];
  final obligations = <DashboardResolvedItem>[
    if (resolution.answer.item != null) resolution.answer.item!,
    ...resolution.otherActions,
  ];
  for (final item in obligations) {
    final signal = item.signal;
    if (!signal.kind.isObligation ||
        item.source == DashboardSignalSource.updates ||
        item.source == DashboardSignalSource.insights ||
        signal.target == ZyraDashboardTarget.notifications) {
      continue;
    }
    cards.add(
      SupportiveCard(
        id: signal.id,
        section: SupportiveSection.needsYou,
        title: signal.title,
        detail: signal.detail,
        actionLabel: _ownerAction(signal.target) ?? signal.actionLabel,
        target: signal.target,
        date: signal.dueAt,
      ),
    );
  }

  final family = resolution.stableState.family.valueOrNull;
  if (family?.kind == DashboardFamilyKind.connected &&
      family?.title == 'Choose a Main Guardian') {
    cards.add(
      const SupportiveCard(
        id: 'guardian:main-required',
        section: SupportiveSection.needsYou,
        title: 'Choose a Main Guardian',
        detail:
            'Your active Journey is held until you choose the Guardian who leads.',
        actionLabel: 'Go to Guardian',
        target: ZyraDashboardTarget.guardian,
      ),
    );
  } else if (family?.kind == DashboardFamilyKind.notConnected) {
    cards.add(
      const SupportiveCard(
        id: 'guardian:not-connected',
        section: SupportiveSection.stand,
        title: 'No Guardian connected yet',
        detail: 'You will need a Guardian for parts of your ZYRA Journey.',
        actionLabel: 'Go to Guardian',
        target: ZyraDashboardTarget.guardian,
      ),
    );
  } else if (family?.kind == DashboardFamilyKind.invitationPending &&
      family!.expiresAt?.isAfter(comparisonClock) == true) {
    cards.add(
      SupportiveCard(
        id: 'guardian:invitation-expiry',
        section: SupportiveSection.stand,
        title: 'Your Guardian invitation has an expiry date',
        detail: 'View the invitation in Guardian.',
        actionLabel: 'View invitation',
        target: ZyraDashboardTarget.guardian,
        date: family.expiresAt,
      ),
    );
  }
  final journey = resolution.journey.summary;
  if (resolution.journey.state == DashboardJourneyResolutionState.available &&
      journey?.kind == DashboardJourneyKind.paused) {
    cards.add(
      SupportiveCard(
        id: journey!.id,
        section: SupportiveSection.stand,
        title: journey.title,
        detail: 'You can continue browsing while your Journey remains paused.',
        actionLabel: 'View Journey',
        target: ZyraDashboardTarget.connectionsJourneys,
      ),
    );
  }
  for (final item in resolution.recently) {
    // This candidate does not assemble movement from other domain branches.
    if (item.source != DashboardSignalSource.updates) continue;
    final signal = item.signal;
    if (signal.kind != DashboardSignalKind.meaningfulMovement) continue;
    cards.add(
      SupportiveCard(
        id: signal.id,
        section: SupportiveSection.changed,
        title: signal.title,
        detail: signal.detail,
        actionLabel: _ownerAction(signal.target),
        target: signal.target,
        date: signal.eventAt,
        isUnread: signal.isUnread,
      ),
    );
  }
  return mergeSupportiveCards(cards);
}

/// Highest-priority section wins the same explicit issue ID. A supplement
/// may replace an equal-priority display, never demote a real obligation.
/// Sample admission is the guarded widget's responsibility, not this helper.
List<SupportiveCard> mergeSupportiveCards(
  Iterable<SupportiveCard> cards, [
  Iterable<SupportiveCard> supplements = const [],
]) {
  final byId = <String, SupportiveCard>{};
  for (final card in [...cards, ...supplements]) {
    if (card.id.trim().isEmpty || card.title.trim().isEmpty) continue;
    if (card.section.isInsight &&
        !card.isGeneralGuide &&
        card.evidence?.isComplete != true) {
      continue;
    }
    final previous = byId[card.id];
    if (previous == null || card.section.index <= previous.section.index) {
      byId[card.id] = card;
    }
  }
  return List.unmodifiable(byId.values);
}

String? _ownerAction(ZyraDashboardTarget target) => switch (target) {
  ZyraDashboardTarget.none || ZyraDashboardTarget.notifications => null,
  ZyraDashboardTarget.connectionsJourneys => 'View Journey',
  ZyraDashboardTarget.guardian => 'Go to Guardian',
  ZyraDashboardTarget.connectionsActivity => 'View activity',
  ZyraDashboardTarget.discovery => 'Go to Profiles',
  ZyraDashboardTarget.profile => 'Go to Profile',
  ZyraDashboardTarget.preferences => 'View preferences',
  ZyraDashboardTarget.onboarding => 'View account setup',
};
