import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_segmented_toggle.dart';

enum ZyraCircleTopicKind { general, current, past }

/// The selected current interior shares the existing floating-popup authority
/// boundary; it is not a membership or history grant.
enum ZyraCircleBubbleDesign {
  current('Current');

  const ZyraCircleBubbleDesign(this.label);
  final String label;
}

/// Detached visual metadata. An ID here is not a member, Journey, server
/// reference, history-consent record or permission to open another screen.
@immutable
class ZyraCircleDiscussionTopic {
  const ZyraCircleDiscussionTopic({
    required this.id,
    required this.firstName,
    required this.kind,
    this.endedOn,
    this.sharedSummaryLabel,
  });

  static const general = ZyraCircleDiscussionTopic(
    id: 'preview-circle-general',
    firstName: 'General conversation',
    kind: ZyraCircleTopicKind.general,
  );

  final String id;
  final String firstName;
  final ZyraCircleTopicKind kind;
  final DateTime? endedOn;

  /// Caller-supplied first names and dates for a shared past summary only.
  final String? sharedSummaryLabel;

  bool get isGeneral => kind == ZyraCircleTopicKind.general;
  bool get isPast => kind == ZyraCircleTopicKind.past;
}

String _topicLabel(ZyraCircleDiscussionTopic topic) => topic.isGeneral
    ? 'General conversation'
    : topic.sharedSummaryLabel ??
          '${topic.isPast ? 'Past Journey' : 'Journey'} · ${topic.firstName}';

String _topicDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

bool _sameTopic(
  ZyraCircleDiscussionTopic left,
  ZyraCircleDiscussionTopic right,
) =>
    left.id == right.id &&
    left.firstName == right.firstName &&
    left.kind == right.kind &&
    left.endedOn == right.endedOn &&
    left.sharedSummaryLabel == right.sharedSummaryLabel;

/// The canonical floating launcher. Route ownership and every permission
/// remain with Circle; this presentation only invokes its guarded callback.
class ZyraCircleDiscussLauncher extends StatelessWidget {
  const ZyraCircleDiscussLauncher({
    super.key,
    required this.topic,
    this.onChoose,
  });

  final ZyraCircleDiscussionTopic topic;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .16),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: IconButton(
      tooltip: 'Discuss a Journey',
      onPressed: onChoose,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: ZyraColors.journeyGold,
        disabledForegroundColor: ZyraColors.journeyGold.withValues(alpha: .42),
        backgroundColor: ZyraColors.surfaceEmphasisFill,
        shape: CircleBorder(
          side: BorderSide(
            color: ZyraColors.journeyGold.withValues(alpha: .5),
            width: .8,
          ),
        ),
      ),
      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
    ),
  );
}

/// A label only. Selecting a discussion topic never creates a Journey link.
class ZyraCircleTopicTag extends StatelessWidget {
  const ZyraCircleTopicTag({super.key, required this.topic});

  final ZyraCircleDiscussionTopic topic;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('circle_topic_tag_${topic.id}'),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: ZyraColors.journeyGold.withValues(alpha: .065),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(
        color: ZyraColors.journeyGold.withValues(alpha: .20),
        width: .6,
      ),
    ),
    child: Text(
      _topicLabel(topic),
      style: ZyraText.subtext(size: 11, color: ZyraColors.journeyGold),
    ),
  );
}

/// A local discussion change in the same Circle transcript, not a service
/// message, Journey lifecycle event, read receipt or history permission.
class ZyraCircleDiscussionBubble extends StatelessWidget {
  const ZyraCircleDiscussionBubble({
    super.key,
    required this.topic,
    this.onViewProfile,
    this.onViewJourney,
  });

  final ZyraCircleDiscussionTopic topic;
  final VoidCallback? onViewProfile;
  final VoidCallback? onViewJourney;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('circle_discussion_bubble_${topic.id}'),
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 9),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: BoxDecoration(
      color: ZyraColors.journeyGold.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: ZyraColors.journeyGold.withValues(alpha: .5),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              topic.isGeneral
                  ? Icons.forum_outlined
                  : Icons.chat_bubble_outline_rounded,
              color: ZyraColors.journeyGold,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.isGeneral
                        ? 'Back to general conversation'
                        : 'Discussing',
                    style: ZyraText.subtext(
                      size: 11,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
                  if (!topic.isGeneral) ...[
                    const SizedBox(height: 4),
                    Text(
                      topic.sharedSummaryLabel ??
                          'Journey with ${topic.firstName}',
                      style: ZyraText.heading(size: 18),
                    ),
                    if (topic.sharedSummaryLabel == null) ...[
                      const SizedBox(height: 5),
                      Text(
                        topic.isPast && topic.endedOn != null
                            ? 'Past Journey · Ended ${_topicDate(topic.endedOn!)}'
                            : 'Current Journey',
                        style: ZyraText.subtext(size: 11.5),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
        if (onViewProfile != null || onViewJourney != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onViewJourney != null)
                OutlinedButton(
                  key: ValueKey('circle_discussion_journey_${topic.id}'),
                  onPressed: onViewJourney,
                  style: _actionStyle(),
                  child: Text(
                    'View Journey',
                    style: ZyraText.body(
                      size: 12,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
                ),
              if (onViewProfile != null)
                OutlinedButton(
                  key: ValueKey('circle_discussion_profile_${topic.id}'),
                  onPressed: onViewProfile,
                  style: _actionStyle(),
                  child: Text(
                    'View profile',
                    style: ZyraText.body(
                      size: 12,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );

  ButtonStyle _actionStyle() => OutlinedButton.styleFrom(
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    foregroundColor: ZyraColors.journeyGold,
    side: BorderSide(
      color: ZyraColors.journeyGold.withValues(alpha: .45),
      width: .8,
    ),
    shape: const StadiumBorder(),
  );
}

/// A bounded, caller-owned selector. It performs no navigation, API request,
/// persistence, membership change or lookup beyond the supplied local rows.
class ZyraCircleTopicPicker extends StatefulWidget {
  const ZyraCircleTopicPicker({
    super.key,
    required this.currentTopics,
    required this.pastTopics,
    required this.selected,
    required this.onSelected,
    required this.canSelect,
    this.embedded = false,
    this.title = 'Discuss a Journey',
    this.showGeneralConversation = true,
    this.bubbleDesign,
    this.onClose,
  });

  final List<ZyraCircleDiscussionTopic> currentTopics;
  final List<ZyraCircleDiscussionTopic> pastTopics;
  final ZyraCircleDiscussionTopic selected;
  final ValueChanged<ZyraCircleDiscussionTopic> onSelected;
  final bool Function() canSelect;
  final bool embedded;
  final String title;

  /// Legacy message-reference pickers use General to remove a Journey link.
  /// Floating discussion pickers only offer the supplied Journey topics.
  final bool showGeneralConversation;
  final ZyraCircleBubbleDesign? bubbleDesign;
  final VoidCallback? onClose;

  @override
  State<ZyraCircleTopicPicker> createState() => _ZyraCircleTopicPickerState();
}

class _ZyraCircleTopicPickerState extends State<ZyraCircleTopicPicker> {
  final _search = TextEditingController();
  late ZyraCircleDiscussionTopic _selected;
  late int _tab;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
    _tab = _selected.isPast ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant ZyraCircleTopicPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameTopic(oldWidget.selected, widget.selected)) {
      _selected = widget.selected;
      _tab = _selected.isPast ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _allowed() {
    if (!mounted) return false;
    try {
      return widget.canSelect();
    } catch (_) {
      return false;
    }
  }

  bool _includes(ZyraCircleDiscussionTopic topic) => topic.isGeneral
      ? widget.showGeneralConversation &&
            _sameTopic(topic, ZyraCircleDiscussionTopic.general)
      : (topic.isPast ? widget.pastTopics : widget.currentTopics).any(
          (known) => _sameTopic(known, topic),
        );

  void _choose(ZyraCircleDiscussionTopic topic) {
    if (!_allowed() || !_includes(topic)) return;
    setState(() => _selected = topic);
    widget.onSelected(topic);
  }

  bool _matches(ZyraCircleDiscussionTopic topic, String query) {
    if (query.isEmpty ||
        (topic.sharedSummaryLabel ?? topic.firstName).toLowerCase().contains(
          query,
        )) {
      return true;
    }
    final date = topic.endedOn;
    if (date == null) return false;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return _topicDate(date).toLowerCase().contains(query) ||
        '${date.year}-$month-$day'.contains(query) ||
        '$day/$month/${date.year}'.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final topics = (_tab == 0 ? widget.currentTopics : widget.pastTopics)
        .where(
          (topic) =>
              topic.kind ==
                  (_tab == 0
                      ? ZyraCircleTopicKind.current
                      : ZyraCircleTopicKind.past) &&
              (_tab == 0 || _matches(topic, query)),
        )
        .toList(growable: false);
    final enabled = _allowed();
    final keyboard = widget.embedded
        ? 0.0
        : MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      keyboard;
            final height = math.max(
              0.0,
              widget.embedded
                  ? available
                  : math.min(
                      available,
                      MediaQuery.sizeOf(context).height * .78,
                    ),
            );
            return SizedBox(
              key: const ValueKey('circle_topic_picker'),
              height: height,
              child: Material(
                color: ZyraColors.modalSheetSurface,
                borderRadius: widget.embedded
                    ? BorderRadius.zero
                    : const BorderRadius.vertical(top: Radius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: CustomScrollView(
                    primary: false,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.bubbleDesign == null)
                              Text(
                                widget.title,
                                style: ZyraText.heading(size: 21),
                              )
                            else
                              _presentationHeader(),
                            const SizedBox(height: 14),
                            TweenAnimationBuilder<double>(
                              tween: Tween(end: _tab.toDouble()),
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : ZyraSegmentedMotion.selectionDuration,
                              curve: ZyraSegmentedMotion.selectionCurve,
                              builder: (context, position, _) =>
                                  ZyraSegmentedToggle(
                                    labels: const ['Current', 'Past'],
                                    labelSize: 13,
                                    position: position,
                                    segmentKeys: const [
                                      ValueKey('circle_topic_tab_0'),
                                      ValueKey('circle_topic_tab_1'),
                                    ],
                                    onChanged: (index) {
                                      if (!_allowed() ||
                                          index < 0 ||
                                          index > 1) {
                                        return;
                                      }
                                      setState(() => _tab = index);
                                    },
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (widget.showGeneralConversation) ...[
                              _row(ZyraCircleDiscussionTopic.general, enabled),
                              const SizedBox(height: 12),
                            ],
                            if (_tab == 1) ...[
                              TextField(
                                key: const ValueKey('circle_topic_search'),
                                controller: _search,
                                enabled: enabled,
                                textInputAction: TextInputAction.search,
                                onChanged: (_) {
                                  if (_allowed()) setState(() {});
                                },
                                style: ZyraText.body(size: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search past Journeys',
                                  hintStyle: ZyraText.subtext(size: 13),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: ZyraColors.foregroundMuted,
                                  ),
                                  filled: true,
                                  fillColor: ZyraColors.surfaceFill,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(
                                      color: ZyraColors.surfaceBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(
                                      color: ZyraColors.surfaceBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(
                                      color: ZyraColors.journeyGold.withValues(
                                        alpha: .55,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                      if (topics.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              query.isNotEmpty && _tab == 1
                                  ? 'No matching Journeys'
                                  : _tab == 1
                                  ? 'No past Journeys'
                                  : 'No current Journeys',
                              style: ZyraText.subtext(size: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, index) => index.isOdd
                                ? const SizedBox(height: 8)
                                : _row(topics[index ~/ 2], enabled),
                            childCount: topics.length * 2 - 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _presentationHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(widget.title, style: ZyraText.heading(size: 22)),
          ),
          const SizedBox(width: 6),
          IconButton(
            key: const ValueKey('circle_topic_picker_close'),
            tooltip: 'Close',
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close_rounded,
              color: ZyraColors.journeyGold,
              size: 22,
            ),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              backgroundColor: ZyraColors.surfaceFill,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Choose a Journey to bring into this conversation.',
        style: ZyraText.subtext(size: 12.5),
      ),
    ],
  );

  Widget _row(ZyraCircleDiscussionTopic topic, bool enabled) {
    final selected = _sameTopic(_selected, topic);
    final design = widget.bubbleDesign;
    final legacy = design == null;
    final keyboardReading =
        design != null &&
        MediaQuery.viewInsetsOf(context).bottom > 0 &&
        MediaQuery.textScalerOf(context).scale(13) >= 20;
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          topic.sharedSummaryLabel ?? topic.firstName,
          style: ZyraText.body(size: 13),
        ),
        if (topic.sharedSummaryLabel == null &&
            !legacy &&
            !topic.isGeneral &&
            !keyboardReading) ...[
          const SizedBox(height: 4),
          Text(
            topic.isPast ? 'Past Journey' : 'Current Journey',
            style: ZyraText.subtext(size: 11),
          ),
        ],
        if (topic.sharedSummaryLabel == null &&
            topic.isPast &&
            topic.endedOn != null) ...[
          const SizedBox(height: 3),
          Text(_topicDate(topic.endedOn!), style: ZyraText.subtext(size: 11)),
        ],
      ],
    );
    final indicator = Icon(
      selected
          ? legacy
                ? Icons.check_circle_outline_rounded
                : Icons.check_circle_rounded
          : Icons.circle_outlined,
      color: selected
          ? ZyraColors.journeyGold
          : ZyraColors.foregroundMuted.withValues(alpha: .4),
      size: 20,
    );
    Widget identity() => Container(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ZyraColors.journeyGold.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: ZyraColors.journeyGold.withValues(alpha: .28),
          width: .7,
        ),
      ),
      child: Text(
        topic.firstName.trim().isEmpty
            ? '?'
            : topic.firstName.characters.first.toUpperCase(),
        style: ZyraText.heading(size: 18, color: ZyraColors.journeyGold),
      ),
    );
    final content = Row(
      children: [
        if (!legacy && !topic.isGeneral && !keyboardReading) ...[
          identity(),
          const SizedBox(width: 12),
        ],
        Expanded(child: detail),
        const SizedBox(width: 10),
        indicator,
      ],
    );
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        key: ValueKey(
          topic.isGeneral ? 'circle_topic_general' : 'circle_topic_${topic.id}',
        ),
        color: selected
            ? ZyraColors.journeyGold.withValues(alpha: .075)
            : ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: enabled ? () => _choose(topic) : null,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            key: ValueKey(
              'circle_topic_interior_${design?.name ?? 'legacy'}_${topic.id}',
            ),
            constraints: const BoxConstraints(minHeight: 44),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? ZyraColors.journeyGold.withValues(alpha: .44)
                    : ZyraColors.surfaceBorder,
                width: .7,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
