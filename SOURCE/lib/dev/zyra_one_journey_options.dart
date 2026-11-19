import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_menu_sheet.dart';
// Caller-owned Journey options, either in the original opaque sheet or
// expanded inside a card. Choosing an option does not itself change a Journey.
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_preview_spacing.dart';
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
  final bool archived;
  // LOCK13 opts in; existing inline cards and sheets keep their geometry.
  final bool lockedPage;

  @override
  Widget build(BuildContext context) => lockedPage
      ? _cards(context)
      : inline
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
                      style: DefaultTextStyle.of(
                        context,
                      ).style.merge(ZyraText.button(size: 13)),
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
                  constraints.maxHeight >= rows.length * 56) {
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
                  ? ZyraShadowScrollView(
                      key: ValueKey('draft_options_inline_scroll_$id'),
                      child: content,
                    )
                  : content;
            },
          ),
        )
      : Builder(
          builder: (context) => ZyraMenuSheet(
            children: [
              const ZyraMenuHeader(text: 'Journey options'),
              const SizedBox(height: 5),
              ZyraMenuHeader(
                text: archived
                    ? 'Review your ended Journey with $firstName.'
                    : 'Manage your Journey with $firstName.',
              ),
              const SizedBox(height: 14),
              ..._rows,
              const SizedBox(height: 8),
              ZyraMenuCancel(
                onPressed: ZyraTapFeedback.onTap(context, onCancel),
              ),
            ],
          ),
        );

  Widget _cards(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: LayoutBuilder(
      builder: (context, bounds) {
        final groups = [
          _entries.take(4).toList(),
          [_entries[4]],
          _entries.skip(5).toList(),
        ];
        final stretch =
            bounds.hasBoundedHeight &&
            bounds.maxHeight >=
                _entries.length * 46 + 2 * ZyraPreviewSpacing.cardToCard;
        Widget card(int index) => _floatingOptionsCard(
          key: ValueKey(
            'journey_options_${['main', 'guardians', 'actions'][index]}_card_$id',
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < groups[index].length; i++)
                if (stretch)
                  Expanded(
                    child: _row(
                      groups[index][i].$1,
                      groups[index][i].$2,
                      groups[index][i].$3,
                      groups[index][i].$4,
                      first: i == 0,
                    ),
                  )
                else
                  _row(
                    groups[index][i].$1,
                    groups[index][i].$2,
                    groups[index][i].$3,
                    groups[index][i].$4,
                    first: i == 0,
                  ),
            ],
          ),
        );
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < groups.length; i++) ...[
              if (i > 0) const SizedBox(height: ZyraPreviewSpacing.cardToCard),
              if (stretch)
                Expanded(flex: groups[i].length, child: card(i))
              else
                card(i),
            ],
          ],
        );
        return !stretch && bounds.hasBoundedHeight
            ? ZyraShadowScrollView(child: content)
            : content;
      },
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
      _compatibilityIcon,
      _compatibilityLabel,
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
    String detail, {
    bool first = false,
  }) {
    final locked = switch (option) {
      ZyraConceptJourneyOption.bio => !canViewBio,
      ZyraConceptJourneyOption.compatibility => !canViewCompatibility,
      ZyraConceptJourneyOption.guardians => !canViewGuardians,
      _ => false,
    };
    final explanation = switch (option) {
      ZyraConceptJourneyOption.bio when locked =>
        archived
            ? 'Journey Bio was not shared before this Journey ended.'
            : 'Complete Journey Bio together to view it here.',
      ZyraConceptJourneyOption.compatibility when locked =>
        archived
            ? 'You can view the result you revealed together or used a profile Unlock to open.'
            : 'Complete Compatibility Reveal together to view your result.',
      ZyraConceptJourneyOption.guardians when locked =>
        'No Guardian details were saved in this archive.',
      _ => detail,
    };
    if (!inline && !lockedPage) {
      return Builder(
        builder: (context) => Tooltip(
          message: explanation,
          excludeFromSemantics: explanation == title,
          child: ZyraMenuOption(
            key: ValueKey('draft_options_${option.name}_$id'),
            label: title,
            destructive:
                option == ZyraConceptJourneyOption.end ||
                option == ZyraConceptJourneyOption.report,
            onPressed: ZyraTapFeedback.onTap(context, () => onSelected(option)),
            leading: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: ZyraColors.ivoryTop,
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
            subtitle: Text(explanation, style: ZyraText.subtext(size: 10.5)),
            trailing: Icon(
              locked ? Icons.lock_outline : Icons.chevron_right,
              key: locked
                  ? ValueKey('draft_options_${option.name}_locked_$id')
                  : null,
              semanticLabel: locked ? '$title locked' : null,
              size: 18,
              color: ZyraColors.ink(.4),
            ),
          ),
        ),
      );
    }
    return _journeyOptionRow(
      key: ValueKey('draft_options_${option.name}_$id'),
      lockKey: ValueKey('draft_options_${option.name}_locked_$id'),
      option: option,
      icon: icon,
      title: title,
      explanation: explanation,
      locked: locked,
      first: first,
      lockedPage: lockedPage,
      inline: inline,
      onTap: () => onSelected(option),
    );
  }
}

const _compatibilityIcon = Icons.balance_outlined;
const _compatibilityLabel = 'Compatibility score';

Widget _floatingOptionsCard({Key? key, required Widget child}) =>
    ZyraFloatingSurface(
      radius: 20,
      circle: false,
      gold: false,
      child: Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ZyraColors.surfaceBorder, width: .6),
        ),
        child: child,
      ),
    );

/// Standalone row using the same floating card and option as the Journey page.
class ZyraGuardianCompatibilityRow extends StatelessWidget {
  const ZyraGuardianCompatibilityRow({
    super.key,
    required this.rowKey,
    required this.canAct,
    required this.onTap,
  });

  final Key rowKey;
  final bool Function() canAct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: _floatingOptionsCard(
      child: Semantics(
        button: true,
        child: _journeyOptionRow(
          key: rowKey,
          option: ZyraConceptJourneyOption.compatibility,
          icon: _compatibilityIcon,
          title: _compatibilityLabel,
          explanation: _compatibilityLabel,
          locked: false,
          first: true,
          lockedPage: true,
          inline: true,
          canAct: canAct,
          onTap: onTap,
        ),
      ),
    ),
  );
}

Widget _journeyOptionRow({
  required Key key,
  Key? lockKey,
  required ZyraConceptJourneyOption option,
  required IconData icon,
  required String title,
  required String explanation,
  required bool locked,
  required bool first,
  required bool lockedPage,
  required bool inline,
  bool Function()? canAct,
  required VoidCallback onTap,
}) => Builder(
  builder: (context) => Tooltip(
    message: explanation,
    excludeFromSemantics: explanation == title,
    child: InkWell(
      key: key,
      onTap: ZyraTapFeedback.onTap(context, onTap, canAct: canAct),
      child: Container(
        constraints: BoxConstraints(
          minHeight: lockedPage
              ? 46
              : inline
              ? 56
              : 62,
        ),
        padding: EdgeInsets.symmetric(
          vertical: lockedPage
              ? 10
              : inline
              ? 5
              : 10,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: lockedPage && first
                  ? Colors.transparent
                  : ZyraColors.ink(.12),
              width: .6,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (lockedPage)
              Icon(
                icon,
                size: 20,
                color: option == ZyraConceptJourneyOption.end
                    ? ZyraColors.destructive
                    : locked
                    ? ZyraColors.ink(.4)
                    : ZyraColors.journeyGold,
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ZyraColors.ivoryTop,
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
            SizedBox(width: lockedPage ? 16 : 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ZyraText.button(
                      size: lockedPage ? 15 : 13,
                      color:
                          option == ZyraConceptJourneyOption.end ||
                              option == ZyraConceptJourneyOption.report
                          ? ZyraColors.dangerText
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
            if (!lockedPage || option != ZyraConceptJourneyOption.end)
              Icon(
                locked ? Icons.lock_outline : Icons.chevron_right,
                key: locked ? lockKey : null,
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
      child: ZyraFloatingSurface(
        radius: 999,
        circle: false,
        gold: false,
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
    ),
  );
}

enum ZyraEndedJourneyAction { restart, remove }

/// Ended Journeys action sheet. The caller validates the attempt and owns the
/// following confirmation.
class ZyraEndedJourneyMenu extends StatelessWidget {
  const ZyraEndedJourneyMenu({
    super.key,
    required this.onSelect,
    this.restartEnabled = true,
  });

  final ValueChanged<ZyraEndedJourneyAction?> onSelect;
  final bool restartEnabled;

  @override
  Widget build(BuildContext context) => ZyraMenuSheet(
    children: [
      ZyraMenuOption(
        label: 'Request a new Journey',
        onPressed: restartEnabled
            ? ZyraTapFeedback.onTap(
                context,
                () => onSelect(ZyraEndedJourneyAction.restart),
              )
            : null,
      ),
      const Divider(height: 1, color: ZyraColors.divider),
      ZyraMenuOption(
        label: 'Remove from my Journeys',
        destructive: true,
        onPressed: ZyraTapFeedback.onTap(
          context,
          () => onSelect(ZyraEndedJourneyAction.remove),
        ),
      ),
      const SizedBox(height: 8),
      ZyraMenuCancel(
        onPressed: ZyraTapFeedback.onTap(context, () => onSelect(null)),
      ),
    ],
  );
}
