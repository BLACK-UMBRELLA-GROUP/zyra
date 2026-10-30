// Disposable My ZYRA activity examples. This catalog reads no account data and
// grants no request, Journey, message, entitlement or notification authority.
// The protected shell owns selection, lifetime checks and addressed navigation.
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../models/zyra_dashboard_resolution.dart';
import '../models/zyra_supportive_dashboard.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

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

/// A scroll-compatible checklist body; its caller owns the protected surface.
class ZyraMyZyraActivityChecklist extends StatelessWidget {
  const ZyraMyZyraActivityChecklist({
    super.key,
    required this.selected,
    required this.reviewed,
    required this.onSelected,
  });

  final ZyraMyZyraActivityExample? selected;
  final Set<ZyraMyZyraActivityExample> reviewed;
  final ValueChanged<ZyraMyZyraActivityExample?> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Activity checklist', style: ZyraText.heading(size: 20)),
      const SizedBox(height: 8),
      Text(
        'Fictional examples. Choosing one does not change requests, Journeys or permissions.',
        style: ZyraText.subtext(size: 12),
      ),
      const SizedBox(height: 8),
      Text(
        '${reviewed.length} of ${ZyraMyZyraActivityExample.values.length} viewed',
        key: const ValueKey('activity-checklist-progress'),
        style: ZyraText.subtext(size: 11.5),
      ),
      const SizedBox(height: 12),
      _ActivityChecklistRow(
        key: const ValueKey('activity-checklist-current'),
        title: 'Current activity',
        detail: 'Return to the current local preview without an example.',
        selected: selected == null,
        onTap: () => onSelected(null),
      ),
      for (final example in ZyraMyZyraActivityExample.values) ...[
        const SizedBox(height: 8),
        _ActivityChecklistRow(
          key: ValueKey('activity-checklist-${example.name}'),
          title: example.label,
          detail: example.description,
          selected: selected == example,
          viewed: reviewed.contains(example),
          onTap: () => onSelected(example),
        ),
      ],
    ],
  );
}

class _ActivityChecklistRow extends StatelessWidget {
  const _ActivityChecklistRow({
    super.key,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.viewed,
  });

  final String title;
  final String detail;
  final bool selected;
  final bool? viewed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    checked: viewed,
    label: '$title. ${viewed == true ? 'Viewed. ' : ''}$detail',
    onTap: ZyraTapFeedback.onTap(context, onTap),
    excludeSemantics: true,
    child: Material(
      color: selected ? ZyraColors.surfaceEmphasisFill : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? ZyraColors.surfaceEmphasisBorder
              : ZyraColors.surfaceBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: ZyraTapFeedback.onTap(context, onTap),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    viewed == null
                        ? Icons.restore_rounded
                        : viewed!
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 22,
                    color: viewed == true || selected
                        ? ZyraColors.journeyGold
                        : ZyraColors.foregroundMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ZyraText.body(
                          size: 13,
                          color: selected
                              ? ZyraColors.journeyGold
                              : ZyraColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(detail, style: ZyraText.subtext(size: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Optional in-preview controls. It owns no selection or persisted state.
class ZyraMyZyraActivityPreviewBar extends StatelessWidget {
  const ZyraMyZyraActivityPreviewBar({
    super.key,
    required this.example,
    required this.onPrevious,
    required this.onNext,
    required this.onChecklist,
    required this.onCurrent,
  });

  final ZyraMyZyraActivityExample example;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onChecklist;
  final VoidCallback onCurrent;

  Widget _button(
    String id,
    String label,
    IconData icon,
    VoidCallback callback,
  ) => Builder(
    builder: (context) => TextButton.icon(
      key: ValueKey('activity-preview-$id'),
      onPressed: ZyraTapFeedback.onTap(context, callback),
      icon: Icon(icon, size: 18),
      label: Text(label, style: ZyraText.button(size: 11.5)),
      style: TextButton.styleFrom(
        foregroundColor: ZyraColors.journeyGold,
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ZyraColors.surfaceFill,
      border: Border.all(color: ZyraColors.surfaceBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Activity preview', style: ZyraText.body(size: 13)),
          const SizedBox(height: 4),
          Text(
            '${example.index + 1} / ${ZyraMyZyraActivityExample.values.length} · ${example.label}',
            key: const ValueKey('activity-preview-example'),
            style: ZyraText.subtext(size: 12),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _button(
                'previous',
                'Previous',
                Icons.arrow_back_rounded,
                onPrevious,
              ),
              _button('next', 'Next', Icons.arrow_forward_rounded, onNext),
              _button(
                'checklist',
                'Checklist',
                Icons.checklist_rounded,
                onChecklist,
              ),
              _button(
                'current',
                'Current activity',
                Icons.restore_rounded,
                onCurrent,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
