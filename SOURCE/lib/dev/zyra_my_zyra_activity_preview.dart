// Disposable My ZYRA activity examples. This catalog reads no account data and
// grants no request, Journey, message, entitlement or notification authority.
// The protected shell owns selection, lifetime checks and addressed navigation.

import '../models/zyra_dashboard_resolution.dart';
import '../models/zyra_supportive_dashboard.dart';

enum ZyraMyZyraActivityOwner {
  requests,
  introductions,
  journey,
  ended,
  guardian,
  circle;

  ZyraDashboardTarget get target => switch (this) {
    requests ||
    introductions ||
    ended => ZyraDashboardTarget.connectionsActivity,
    journey => ZyraDashboardTarget.connectionsJourneys,
    guardian || circle => ZyraDashboardTarget.guardian,
  };
}

/// A fictional display item, never evidence that the named event happened.
final class ZyraMyZyraActivityItem {
  const ZyraMyZyraActivityItem({
    required this.id,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.owner,
    this.personId,
  });

  final String id;
  final String title;
  final String detail;
  final String actionLabel;
  final ZyraMyZyraActivityOwner owner;
  final String? personId;

  SupportiveCard get card => SupportiveCard(
    id: id,
    section: SupportiveSection.needsYou,
    title: title,
    detail: detail,
    actionLabel: actionLabel,
    target: owner.target,
    hasNewActivity: true,
  );
}

enum ZyraMyZyraActivityExample {
  quiet('No new activity', 'Only the permanent Quick access cards remain.'),
  requestReceived('Request received', 'A new Journey request needs a review.'),
  severalRequests(
    'Several requests',
    'More than one person has sent a request.',
  ),
  requestAccepted('Request accepted', 'A reply changes the next action.'),
  requestDeclined('Request declined', 'A recorded reply replaces the request.'),
  introductionReceived(
    'Introduction received',
    'A Guardian has put someone forward.',
  ),
  journeyReady(
    'Journey ready',
    'A Journey is ready for its next permitted step.',
  ),
  journeyEnded('Journey ended', 'A recorded ending leads to its archive.'),
  guardianUpdate('Guardian update', 'A confirmed Guardian link has changed.'),
  familyReviewOpened(
    'Family Review opened',
    'Existing dashboard review-opened display fixture.',
  ),
  milestoneToConfirm(
    'Milestone to confirm',
    'Existing dashboard milestone-proposed display fixture.',
  ),
  guardianInvitationExpiring(
    'Guardian invitation expiring',
    'Existing dashboard invitation-expiring display fixture.',
  ),
  circleMessage(
    'Circle message',
    'A Guardian Circle conversation has activity.',
  );

  const ZyraMyZyraActivityExample(this.label, this.description);

  final String label;
  final String description;

  /// Immutable local examples, isolated from the shell's actual draft model.
  List<ZyraMyZyraActivityItem> get items => switch (this) {
    quiet => const [],
    requestReceived => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-requestReceived-amira',
        title: 'Journey request from Amira',
        detail: 'Amira would like to begin a Journey with you.',
        actionLabel: 'View request',
        owner: ZyraMyZyraActivityOwner.requests,
        personId: 'draft-amira',
      ),
    ],
    severalRequests => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-severalRequests-amira',
        title: 'Journey request from Amira',
        detail: 'Amira would like to begin a Journey with you.',
        actionLabel: 'View request',
        owner: ZyraMyZyraActivityOwner.requests,
        personId: 'draft-amira',
      ),
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-severalRequests-sara',
        title: 'Journey request from Sara',
        detail: 'Sara would like to begin a Journey with you.',
        actionLabel: 'View request',
        owner: ZyraMyZyraActivityOwner.requests,
        personId: 'draft-sara',
      ),
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-severalRequests-noor',
        title: 'Journey request from Noor',
        detail: 'Noor would like to begin a Journey with you.',
        actionLabel: 'View request',
        owner: ZyraMyZyraActivityOwner.requests,
        personId: 'draft-noor',
      ),
    ],
    requestAccepted => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-requestAccepted-sara',
        title: 'Sara accepted your Journey request',
        detail: 'Review the next step before beginning together.',
        actionLabel: 'View Journey',
        owner: ZyraMyZyraActivityOwner.journey,
        personId: 'draft-sara',
      ),
    ],
    requestDeclined => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-requestDeclined-aisha',
        title: 'Aisha declined your Journey request',
        detail: 'The request is closed. No Journey has begun.',
        actionLabel: 'View request',
        owner: ZyraMyZyraActivityOwner.requests,
        personId: 'draft-aisha',
      ),
    ],
    introductionReceived => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-introductionReceived-noor',
        title: 'Hassan introduced Noor',
        detail: 'Review the person your Guardian has put forward.',
        actionLabel: 'View introduction',
        owner: ZyraMyZyraActivityOwner.introductions,
        personId: 'draft-noor',
      ),
    ],
    journeyReady => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-journeyReady-maryam',
        title: 'Your Journey with Maryam is ready to continue',
        detail: 'Open the Journey to review its next step together.',
        actionLabel: 'Continue Journey',
        owner: ZyraMyZyraActivityOwner.journey,
        personId: 'draft-maryam',
      ),
    ],
    journeyEnded => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-journeyEnded-noor',
        title: 'Your Journey with Noor has ended',
        detail: 'The past Journey remains in your read-only archive.',
        actionLabel: 'View archive',
        owner: ZyraMyZyraActivityOwner.ended,
        personId: 'draft-noor',
      ),
    ],
    guardianUpdate => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-guardianUpdate-yusuf',
        title: 'Yusuf joined your Guardians',
        detail: 'Review the confirmed Guardian link.',
        actionLabel: 'View Guardian',
        owner: ZyraMyZyraActivityOwner.guardian,
      ),
    ],
    // These display-only adapters use the existing dashboard update keys.
    // They never establish a review, milestone, invitation or new permission.
    familyReviewOpened => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-dashboard_updates.guardian.review_opened',
        title: 'Family Review opened',
        detail: 'Your Guardians are reviewing your Journey with Sara.',
        actionLabel: 'View Journey',
        owner: ZyraMyZyraActivityOwner.journey,
        personId: 'draft-sara',
      ),
    ],
    milestoneToConfirm => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-dashboard_updates.notification.milestone_proposed',
        title: 'Milestone to confirm',
        detail: 'Confirm the step you and Sara reached.',
        actionLabel: 'Open Timeline',
        owner: ZyraMyZyraActivityOwner.journey,
        personId: 'draft-sara',
      ),
    ],
    guardianInvitationExpiring => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-dashboard_updates.notification.wali_invite_expiring',
        title: 'Guardian invitation expiring',
        detail: 'Your invitation to Yusuf ends soon.',
        actionLabel: 'View Guardian',
        owner: ZyraMyZyraActivityOwner.guardian,
      ),
    ],
    circleMessage => const [
      ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-circleMessage-hassan',
        title: 'New message in Guardian Circle',
        detail: 'Hassan has added to your Circle conversation.',
        actionLabel: 'Open Circle',
        owner: ZyraMyZyraActivityOwner.circle,
      ),
    ],
  };
}
