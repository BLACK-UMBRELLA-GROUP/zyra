import '../widgets/zyra_floating_surface.dart';
// Read-only Timeline presentation. Callers supply admitted values and fresh
// local actions; this widget owns no lookup, disclosure or relationship state.
import '../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';

import '../data/zyra_journey_stages.dart';
import '../data/zyra_timeline_milestones.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_state_widgets.dart';
import 'zyra_draft_timeline_preview.dart';

class ZyraDraftTimelinePresentation extends StatelessWidget {
  const ZyraDraftTimelinePresentation({
    super.key,
    required this.subjectId,
    required this.firstName,
    required this.view,
    this.ownedViewport = false,
    this.showContext = true,
    this.onRetry,
    this.onViewCompatibility,
    this.onViewAttemptCompatibility,
    this.readableCompatibilityAttemptIds = const {},
    this.onPropose,
    this.onConfirm,
    this.onNotYet,
  });

  final String subjectId, firstName;
  final ZyraDraftTimelineView view;
  final bool ownedViewport, showContext;
  final VoidCallback? onRetry, onViewCompatibility, onConfirm, onNotYet;
  final ValueChanged<String>? onViewAttemptCompatibility;
  final Set<String> readableCompatibilityAttemptIds;
  final ValueChanged<String>? onPropose;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // Calendar components are deliberate: a supplied date is never shifted to
  // another viewer's timezone, nor replaced by a relative or current date.
  static String dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';

  static String? _chapter(String type) {
    final stage = ZyraJourneyStages.ofTimelineMilestone(type);
    if (stage != null) return stage.label;
    return switch (type) {
      'liked' || 'match_created' => 'The match',
      'journey_started' => ZyraJourneyStages.all.first.label,
      'meeting' || 'nikah' => 'Family & beyond',
      _ => null,
    };
  }

  Widget _chapterHeading(String label, {bool dim = false}) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 14),
    child: Text(
      label.toUpperCase(),
      style: ZyraText.subtext(
        size: 11,
        color: dim ? ZyraColors.foregroundMuted : ZyraColors.goldText,
      ).copyWith(letterSpacing: 1.1),
    ),
  );

  Widget _rail({
    required Widget content,
    required IconData icon,
    required bool last,
    bool quiet = false,
    bool current = false,
    bool ahead = false,
  }) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              ZyraFloatingSurface(
                radius: 22,
                circle: true,
                gold: false,
                child: Container(
                  width: quiet ? 26 : 34,
                  height: quiet ? 26 : 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ahead
                        ? Colors.transparent
                        : current
                        ? ZyraColors.accentBg
                        : ZyraColors.surfaceFill,
                    border: Border.all(
                      color: current
                          ? ZyraColors.journeyGold
                          : ZyraColors.surfaceBorder,
                      width: current ? 1.6 : 1,
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: quiet ? 13 : 17,
                      color: ahead || quiet
                          ? ZyraColors.foregroundMuted
                          : current
                          ? ZyraColors.journeyGold
                          : ZyraColors.foreground,
                    ),
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 1, color: ZyraColors.surfaceBorder),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: quiet ? 3 : 5,
              bottom: quiet ? 20 : 28,
            ),
            child: content,
          ),
        ),
      ],
    ),
  );

  Widget _event(ZyraDraftTimelineEntry entry, int index, {required bool last}) {
    final quiet = ZyraTimelineMilestones.isQuiet(entry.type);
    return Builder(
      builder: (context) => KeyedSubtree(
        key: ValueKey('draft_timeline_event_${entry.type}_$index'),
        child: _rail(
          icon: ZyraTimelineMilestones.iconFor(entry.type),
          last: last,
          quiet: quiet,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.invitationAccepted
                    ? 'Journey invitation accepted'
                    : ZyraTimelineMilestones.labelFor(entry.type),
                style: quiet
                    ? ZyraText.subtext(size: 13)
                    : ZyraText.body(size: 15),
              ),
              if (entry.occurredOn case final date?) ...[
                const SizedBox(height: 4),
                Text(dateLabel(date), style: ZyraText.subtext(size: 12)),
              ],
              if (entry.type == 'compatibility_revealed' &&
                  (entry.attemptId == null
                      ? view.compatibilityRevealed &&
                            onViewCompatibility != null
                      : readableCompatibilityAttemptIds.contains(
                              entry.attemptId,
                            ) &&
                            onViewAttemptCompatibility != null))
                TextButton(
                  key: ValueKey(
                    entry.attemptId == null
                        ? 'draft_timeline_compatibility'
                        : 'draft_timeline_compatibility_${entry.attemptId}',
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.centerLeft,
                    foregroundColor: ZyraColors.goldText,
                  ),
                  onPressed: ZyraTapFeedback.onTap(
                    context,
                    entry.attemptId == null
                        ? onViewCompatibility
                        : () => onViewAttemptCompatibility!(entry.attemptId!),
                  ),
                  child: Text(
                    'View compatibility',
                    style: ZyraText.button(
                      size: 12.5,
                      color: ZyraColors.goldText,
                    ),
                  ),
                ),
              if (entry.showAnswers && entry.type.startsWith('phase_')) ...[
                const SizedBox(height: 10),
                if (!entry.answersRevealed)
                  ZyraFloatingSurface(
                    radius: 12,
                    circle: false,
                    gold: false,
                    child: Container(
                      key: const ValueKey('draft_timeline_answers_locked'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ZyraColors.surfaceFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ZyraColors.surfaceBorder),
                      ),
                      child: Text(
                        'Answers stay private until you both finish.',
                        style: ZyraText.subtext(size: 12),
                      ),
                    ),
                  )
                else
                  for (final pair in entry.answers)
                    _TimelineAnswer(
                      key: ValueKey(
                        'draft_timeline_answer_${entry.type}_${pair.questionId}',
                      ),
                      pair: pair,
                      theirName: firstName,
                      forceOpen: entry.forceAnswersOpen,
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _story() {
    final children = <Widget>[];
    String? chapter;
    String? attemptId;
    final stage = ZyraJourneyStages.of(view.currentStageValue);
    for (var i = 0; i < view.entries.length; i++) {
      final entry = view.entries[i];
      if (entry.attemptId != null && entry.attemptId != attemptId) {
        attemptId = entry.attemptId;
        chapter = null;
        children.add(
          Padding(
            key: ValueKey('draft_timeline_attempt_$attemptId'),
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              'Journey ${entry.attemptNumber}',
              style: ZyraText.heading(size: 21),
            ),
          ),
        );
      }
      final next = entry.invitationAccepted ? null : _chapter(entry.type);
      if (next != null && next != chapter) {
        chapter = next;
        children.add(_chapterHeading(next));
      }
      children.add(
        _event(entry, i, last: i == view.entries.length - 1 && stage == null),
      );
    }
    if (stage == null) return children;
    if (chapter != stage.label) children.add(_chapterHeading(stage.label));
    final ahead = ZyraJourneyStages.all
        .where((next) => next.order > stage.order)
        .toList();
    children.add(
      KeyedSubtree(
        key: ValueKey('draft_timeline_here_${stage.value}'),
        child: _rail(
          icon: Icons.people_outline,
          current: true,
          last: ahead.isEmpty,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stage.label, style: ZyraText.body(size: 15)),
              const SizedBox(height: 4),
              Text(
                view.frozen ? 'Reached this stage' : 'In progress',
                style: ZyraText.subtext(size: 12),
              ),
              const SizedBox(height: 7),
              Text(
                'YOU ARE HERE · ${stage.order} OF ${ZyraJourneyStages.count}',
                style: ZyraText.subtext(
                  size: 10.5,
                  color: ZyraColors.goldText,
                ).copyWith(letterSpacing: .5),
              ),
            ],
          ),
        ),
      ),
    );
    if (ahead.isNotEmpty) {
      children.add(_chapterHeading('The road ahead', dim: true));
    }
    for (var i = 0; i < ahead.length; i++) {
      final next = ahead[i];
      children.add(
        KeyedSubtree(
          key: ValueKey('draft_timeline_ahead_${next.value}'),
          child: _rail(
            icon: Icons.circle_outlined,
            ahead: true,
            last: i == ahead.length - 1,
            content: Text(next.label, style: ZyraText.subtext(size: 13)),
          ),
        ),
      );
    }
    return children;
  }

  Widget _pending(ZyraDraftTimelinePending pending) {
    final label = ZyraTimelineMilestones.labelFor(pending.type);
    final waiting =
        pending.state == ZyraDraftTimelinePendingState.waitingForPeer;
    final busy = pending.state == ZyraDraftTimelinePendingState.confirming;
    return Builder(
      builder: (context) => ZyraFloatingSurface(
        radius: 18,
        circle: false,
        gold: false,
        child: Container(
          key: const ValueKey('draft_timeline_pending'),
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ZyraColors.surfaceFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                waiting
                    ? 'Waiting for $firstName to confirm'
                    : '$firstName would like to record this milestone',
                style: ZyraText.body(size: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '$label · ${dateLabel(pending.occurredOn)}',
                style: ZyraText.subtext(size: 12.5),
              ),
              if (!waiting) ...[
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  children: [
                    TextButton(
                      key: const ValueKey('draft_timeline_not_yet'),
                      onPressed: ZyraTapFeedback.onTap(
                        context,
                        busy ? null : onNotYet,
                      ),
                      child: Text(
                        'Not yet',
                        style: ZyraText.button(size: 12.5),
                      ),
                    ),
                    ZyraFloatingSurface(
                      radius: 999,
                      circle: false,
                      gold: false,
                      child: OutlinedButton(
                        key: const ValueKey('draft_timeline_confirm'),
                        onPressed: ZyraTapFeedback.onTap(
                          context,
                          busy ? null : onConfirm,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: ZyraColors.journeyGold),
                        ),
                        child: Text(
                          busy ? 'Confirming…' : 'Confirm',
                          style: ZyraText.button(
                            size: 12.5,
                            color: ZyraColors.goldText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _status() {
    if (view.status == ZyraDraftTimelineStatus.loading) {
      return Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: Semantics(
              label: 'Loading timeline',
              liveRegion: true,
              child: const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          ),
        ),
      );
    }
    final failed = view.status == ZyraDraftTimelineStatus.unavailable;
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 72),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.timeline_outlined,
                size: 34,
                color: ZyraColors.foregroundMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              failed
                  ? 'Couldn’t load your timeline'
                  : 'Your story starts here.',
              key: ValueKey(
                failed ? 'draft_timeline_unavailable' : 'draft_timeline_empty',
              ),
              textAlign: TextAlign.center,
              style: ZyraText.body(size: 16),
            ),
            if (failed && onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(
                key: const ValueKey('draft_timeline_retry'),
                onPressed: ZyraTapFeedback.onTap(context, onRetry),
                child: Text(
                  'Try again',
                  style: ZyraText.button(size: 13, color: ZyraColors.goldText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recorded = view.entries.map((entry) => entry.type).toSet();
    final canPropose =
        view.status == ZyraDraftTimelineStatus.ready &&
        !view.frozen &&
        view.pending == null &&
        view.canPropose &&
        onPropose != null;
    final available = [
      'meeting',
      'nikah',
    ].where((type) => !recorded.contains(type)).toList();
    final header = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'Timeline',
              key: const ValueKey('draft_timeline_title'),
              style: ZyraText.pageTitle(),
              textAlign: TextAlign.left,
            ),
          ),
          if (canPropose && available.isNotEmpty)
            PopupMenuButton<String>(
              key: const ValueKey('draft_timeline_propose'),
              tooltip: 'Record a milestone',
              onOpened: ZyraTapFeedback.onTap(context, () {}),
              onSelected: ZyraTapFeedback.onChanged(context, onPropose),
              icon: Icon(Icons.add, color: ZyraColors.journeyGold),
              itemBuilder: (_) => [
                for (final type in available)
                  PopupMenuItem(
                    value: type,
                    child: Text(
                      ZyraTimelineMilestones.labelFor(type),
                      style: ZyraText.body(size: 14),
                    ),
                  ),
              ],
            ),
        ],
      ),
      if (showContext) ...[
        const SizedBox(height: 7),
        Text(
          'Journey with $firstName',
          key: const ValueKey('draft_timeline_context'),
          style: ZyraText.subtext(size: 13),
        ),
      ],
      const SizedBox(height: 24),
    ];
    final confirmedEmpty =
        view.status == ZyraDraftTimelineStatus.ready &&
        view.entries.isEmpty &&
        view.currentStageValue == null &&
        view.pending == null;
    if (ownedViewport && confirmedEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            key: ValueKey('draft_timeline_$subjectId'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...header,
              Expanded(
                child: LayoutBuilder(
                  key: const ValueKey('draft_timeline_empty_viewport'),
                  builder: (context, constraints) => ZyraShadowScrollView(
                    key: PageStorageKey('draft_timeline_scroll_$subjectId'),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const ZyraEmptyState(
                        key: ValueKey('draft_timeline_empty'),
                        icon: Icons.timeline_outlined,
                        title: 'Your story starts here.',
                        message: '',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final content = Column(
      key: ValueKey('draft_timeline_$subjectId'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...header,
        if (view.status != ZyraDraftTimelineStatus.ready)
          _status()
        else ...[
          if (view.pending case final pending?) _pending(pending),
          if (view.entries.isEmpty && view.currentStageValue == null)
            _status()
          else
            ..._story(),
        ],
      ],
    );
    return ownedViewport
        ? SafeArea(
            child: ZyraShadowScrollView(
              key: PageStorageKey('draft_timeline_scroll_$subjectId'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: content,
            ),
          )
        : content;
  }
}

class _TimelineAnswer extends StatefulWidget {
  const _TimelineAnswer({
    super.key,
    required this.pair,
    required this.theirName,
    required this.forceOpen,
  });
  final ZyraDraftTimelineAnswer pair;
  final String theirName;
  final bool forceOpen;

  @override
  State<_TimelineAnswer> createState() => _TimelineAnswerState();
}

class _TimelineAnswerState extends State<_TimelineAnswer> {
  bool _open = false;

  @override
  void didUpdateWidget(covariant _TimelineAnswer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pair.questionId != widget.pair.questionId ||
        oldWidget.pair.mine != widget.pair.mine ||
        oldWidget.pair.theirs != widget.pair.theirs ||
        oldWidget.theirName != widget.theirName) {
      _open = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.forceOpen || _open;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ZyraFloatingSurface(
        radius: 12,
        circle: false,
        gold: false,
        child: Material(
          color: ZyraColors.surfaceFill,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: ZyraTapFeedback.onTap(
              context,
              widget.forceOpen ? null : () => setState(() => _open = !_open),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ZyraColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.pair.question,
                          style: ZyraText.body(size: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ExcludeSemantics(
                        child: Icon(
                          open ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: ZyraColors.foregroundSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (open) ...[
                    const SizedBox(height: 12),
                    Text(
                      'YOU',
                      style: ZyraText.subtext(
                        size: 10.5,
                        color: ZyraColors.goldText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(widget.pair.mine, style: ZyraText.body(size: 13)),
                    const SizedBox(height: 12),
                    Text(
                      widget.theirName.toUpperCase(),
                      style: ZyraText.subtext(
                        size: 10.5,
                        color: ZyraColors.goldText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(widget.pair.theirs, style: ZyraText.body(size: 13)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
