// Caller-owned Journey options, either in the original opaque sheet or
// expanded inside a card. Choosing an option does not itself change a Journey.
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

enum ZyraConceptJourneyOption {
  profile,
  timeline,
  bio,
  compatibility,
  guardians,
  report,
  end,
}

typedef _JourneyOptionEntry = (
  ZyraConceptJourneyOption,
  IconData,
  String,
  String,
);

class ZyraConceptJourneyOptions extends StatelessWidget {
  const ZyraConceptJourneyOptions({
    super.key,
    required this.id,
    required this.firstName,
    required this.canEnd,
    required this.onSelected,
    required this.onCancel,
    this.inline = false,
    this.canReport = true,
    this.canViewBio = false,
    this.canViewCompatibility = false,
    this.canViewGuardians = true,
    this.endedReadWindowOpen = false,
    this.archived = false,
    this.lockedPage = false,
  });
  final String id;
  final String firstName;
  final bool canEnd;
  final ValueChanged<ZyraConceptJourneyOption> onSelected;
  final VoidCallback onCancel;
  final bool inline;
  final bool canReport;
  final bool canViewBio;
  final bool canViewCompatibility;
  final bool canViewGuardians;
  final bool endedReadWindowOpen;
  final bool archived;
  // LOCK13 opts in; existing inline cards and sheets keep their geometry.
  final bool lockedPage;

  @override
  Widget build(BuildContext context) => inline
      ? Material(
          type: MaterialType.transparency,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rows = _rows;
              final readable =
                  !MediaQuery.boldTextOf(context) &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3;
              var labelsFit = false;
              if (constraints.maxHeight.isFinite && constraints.maxWidth > 76) {
                final available = constraints.maxHeight / rows.length - 10.6;
                labelsFit = _entries.every((entry) {
                  final painter = TextPainter(
                    text: TextSpan(
                      text: entry.$3,
                      style: DefaultTextStyle.of(context).style.merge(
                        ZyraText.button(size: lockedPage ? 15 : 13),
                      ),
                    ),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(maxWidth: constraints.maxWidth - 76);
                  final fits = painter.height <= available;
                  painter.dispose();
                  return fits;
                });
              }
              // Divide the actual row cells, not the gaps between them. Their
              // borders then enclose a centred icon, label and chevron.
              if (readable &&
                  labelsFit &&
                  constraints.maxHeight.isFinite &&
                  constraints.maxHeight >=
                      rows.length * (lockedPage ? 60 : 56)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final row in rows) Expanded(child: row)],
                );
              }
              final content = ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rows,
                ),
              );
              // The caller's whole-card reading fallback already scrolls.
              // Do not add a competing nested gesture owner when unbounded.
              return constraints.maxHeight.isFinite
                  ? SingleChildScrollView(
                      key: ValueKey('draft_options_inline_scroll_$id'),
                      child: content,
                    )
                  : content;
            },
          ),
        )
      : Material(
          color: ZyraColors.modalSheetSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 11, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ZyraColors.ink(.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Journey options', style: ZyraText.heading(size: 22)),
                  const SizedBox(height: 5),
                  Text(
                    archived
                        ? 'Review your ended Journey with $firstName.'
                        : 'Manage your Journey with $firstName.',
                    style: ZyraText.subtext(size: 12),
                  ),
                  const SizedBox(height: 14),
                  ..._rows,
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: ZyraTapFeedback.onTap(context, onCancel),
                    child: Text('Cancel', style: ZyraText.button(size: 12)),
                  ),
                ],
              ),
            ),
          ),
        );

  List<Widget> get _rows => [
    for (final entry in _entries) _row(entry.$1, entry.$2, entry.$3, entry.$4),
  ];

  List<_JourneyOptionEntry> get _entries => [
    (
      ZyraConceptJourneyOption.profile,
      Icons.person_outline,
      'View Profile',
      'View $firstName’s profile.',
    ),
    (
      ZyraConceptJourneyOption.timeline,
      Icons.timeline_outlined,
      'Timeline',
      'Your shared Journey history.',
    ),
    (
      ZyraConceptJourneyOption.bio,
      Icons.notes_outlined,
      'Journey Bio',
      'Beyond a first impression.',
    ),
    (
      ZyraConceptJourneyOption.compatibility,
      Icons.balance_outlined,
      'Compatibility score',
      archived
          ? 'Your revealed compatibility result for this profile.'
          : 'Your result opens only through mutual reveal.',
    ),
    (
      ZyraConceptJourneyOption.guardians,
      Icons.people_outline,
      'Guardians',
      'Your circle of support for this Journey.',
    ),
    if (canReport)
      (
        ZyraConceptJourneyOption.report,
        Icons.flag_outlined,
        'Report',
        'Report a concern about this profile.',
      ),
    if (!archived && canEnd)
      (
        ZyraConceptJourneyOption.end,
        Icons.close_rounded,
        'End Journey',
        'Close this Journey permanently. Your Timeline stays.',
      ),
  ];

  Widget _row(
    ZyraConceptJourneyOption option,
    IconData icon,
    String title,
    String detail,
  ) {
    final locked = switch (option) {
      ZyraConceptJourneyOption.bio => !canViewBio,
      ZyraConceptJourneyOption.compatibility => !canViewCompatibility,
      ZyraConceptJourneyOption.guardians => !canViewGuardians,
      _ => false,
    };
    final explanation = switch (option) {
      ZyraConceptJourneyOption.bio when locked =>
        archived
            ? endedReadWindowOpen
                  ? 'Journey Bio was not shared before this Journey ended.'
                  : 'Journey Bio is available for three months after a Journey ends.'
            : 'Complete Journey Bio together to view it here.',
      ZyraConceptJourneyOption.compatibility when locked =>
        archived
            ? 'Journey access lasts three months. A used profile Unlock stays permanent.'
            : 'Complete Compatibility Reveal together to view your result.',
      ZyraConceptJourneyOption.guardians when locked =>
        'Historical Guardian details are available for three months after a Journey ends.',
      _ => detail,
    };
    return Builder(
      builder: (context) => Tooltip(
        message: explanation,
        child: InkWell(
          key: ValueKey('draft_options_${option.name}_$id'),
          onTap: ZyraTapFeedback.onTap(context, () => onSelected(option)),
          child: Container(
            constraints: BoxConstraints(
              minHeight: lockedPage
                  ? 60
                  : inline
                  ? 56
                  : 62,
            ),
            padding: EdgeInsets.symmetric(vertical: inline ? 5 : 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: ZyraColors.ink(.12), width: .6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: option == ZyraConceptJourneyOption.end
                        ? ZyraColors.destructive.withValues(alpha: .09)
                        : ZyraColors.ink(.09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: option == ZyraConceptJourneyOption.end
                        ? ZyraColors.destructive
                        : locked
                        ? ZyraColors.ink(.42)
                        : ZyraColors.foreground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ZyraText.button(
                          size: lockedPage ? 15 : 13,
                          color: option == ZyraConceptJourneyOption.end
                              ? ZyraColors.destructive
                              : locked
                              ? ZyraColors.ink(.5)
                              : ZyraColors.foreground,
                        ),
                      ),
                      if (!inline) ...[
                        const SizedBox(height: 3),
                        Text(explanation, style: ZyraText.subtext(size: 10.5)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  locked ? Icons.lock_outline : Icons.chevron_right,
                  key: locked
                      ? ValueKey('draft_options_${option.name}_locked_$id')
                      : null,
                  semanticLabel: locked ? '$title locked' : null,
                  size: 18,
                  color: ZyraColors.ink(.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The original compact action framing without another vertical card row.
/// The label remains available to assistive technology and long-press tooltip.
class ZyraConceptJourneyOptionsButton extends StatelessWidget {
  const ZyraConceptJourneyOptionsButton({
    super.key,
    required this.onTap,
    this.expanded = false,
    this.isExpandable = false,
  });
  final VoidCallback onTap;
  final bool expanded;
  final bool isExpandable;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Journey options',
    toggled: isExpandable ? expanded : null,
    child: Tooltip(
      message: isExpandable
          ? '${expanded ? 'Collapse' : 'Expand'} Journey options'
          : 'Journey options',
      child: Material(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: ZyraColors.surfaceBorder, width: .6),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: ZyraTapFeedback.onTap(context, onTap),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.more_horiz,
                size: 16,
                color: ZyraColors.ink(.8),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
