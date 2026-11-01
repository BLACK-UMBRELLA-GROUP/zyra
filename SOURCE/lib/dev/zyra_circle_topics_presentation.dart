import 'package:flutter/material.dart';

import '../services/zyra_family_messaging_service.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_loading.dart';
import '../widgets/zyra_state_widgets.dart';
import '../widgets/zyra_tap_feedback.dart';
import '../theme/zyra_interaction_style.dart';

@immutable
class ZyraCircleTopicTile {
  const ZyraCircleTopicTile({
    required this.id,
    required this.name,
    this.stage,
    this.photo,
    this.startedOn,
    this.endedOn,
    this.sharedLabel,
  });

  final String id;
  final String name;
  final String? stage;
  final String? photo;
  final DateTime? startedOn;
  final DateTime? endedOn;
  final String? sharedLabel;
}

@immutable
class ZyraCircleTopicMessage {
  const ZyraCircleTopicMessage({required this.message, this.about});

  final ZyraFamilyMessage message;
  final String? about;
}

/// LOCK20 display only. The owner supplies admission, filtering and every
/// action's current authority; a tab or a read-only footer grants no access.
class ZyraCircleTopicsPresentation extends StatelessWidget {
  const ZyraCircleTopicsPresentation({
    super.key,
    required this.viewerIsSeeker,
    required this.guardianBasic,
    required this.loading,
    required this.available,
    required this.pastSelected,
    required this.showPast,
    required this.canCompose,
    required this.senderId,
    required this.current,
    required this.past,
    required this.selected,
    required this.messages,
    required this.now,
    required this.scrollController,
    required this.composer,
    required this.sending,
    required this.onMenu,
    required this.onSend,
    required this.onAll,
    required this.onPast,
    required this.onAllPast,
    required this.onViewJourney,
    required this.onMembership,
    required this.onRetry,
    required this.onTopic,
    required this.onReport,
    required this.bind,
    this.seekerName,
    this.participantIds,
    this.canSendNow,
  });

  final bool viewerIsSeeker;
  final bool guardianBasic;
  final bool loading;
  final bool available;
  final bool pastSelected;
  final bool showPast;
  final bool canCompose;
  final String senderId;
  final String? seekerName;
  final Set<String>? participantIds;
  final bool Function()? canSendNow;
  final List<ZyraCircleTopicTile> current;
  final List<ZyraCircleTopicTile> past;
  final ZyraCircleTopicTile? selected;
  final List<ZyraCircleTopicMessage> messages;
  final DateTime now;
  final ScrollController scrollController;
  final TextEditingController composer;
  final bool sending;
  final VoidCallback onMenu;
  final VoidCallback onSend;
  final VoidCallback onAll;
  final VoidCallback onPast;
  final VoidCallback onAllPast;
  final VoidCallback onViewJourney;
  final VoidCallback onMembership;
  final VoidCallback onRetry;
  final ValueChanged<String> onTopic;
  final ValueChanged<ZyraFamilyMessage> onReport;
  final VoidCallback Function(BuildContext, VoidCallback) bind;

  static const _months = [
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
  static const _side = 21.0;

  bool get _pastList => pastSelected && selected == null;
  bool get _pastTopic => pastSelected && selected != null;

  DateTime? _deadline(ZyraCircleTopicTile tile) =>
      tile.endedOn?.add(const Duration(days: 30));

  bool _closed(ZyraCircleTopicTile tile) {
    final deadline = _deadline(tile);
    return deadline != null && now.isAfter(deadline);
  }

  int _daysLeft(ZyraCircleTopicTile tile) {
    final deadline = _deadline(tile);
    if (deadline == null) return 0;
    return (deadline.difference(now).inMilliseconds /
            Duration.millisecondsPerDay)
        .ceil()
        .clamp(0, 30)
        .toInt();
  }

  String _shortDate(DateTime date) => '${date.day} ${_months[date.month - 1]}';

  String _pastName(ZyraCircleTopicTile tile) {
    if (viewerIsSeeker) return tile.name;
    return tile.sharedLabel ??
        (seekerName == null ? tile.name : '$seekerName & ${tile.name}');
  }

  String _pastDates(ZyraCircleTopicTile tile) {
    final end = tile.endedOn;
    if (end == null) return '';
    if (viewerIsSeeker) return 'Journey ended ${_shortDate(end)}';
    final start = tile.startedOn;
    if (start == null) return '${_shortDate(end)} ${end.year}';
    final startYear = start.year == end.year ? '' : ' ${start.year}';
    return '${_shortDate(start)}$startYear – ${_shortDate(end)} ${end.year}';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(_side, 14, _side, 10),
        child: Row(
          children: [
            Expanded(
              child: Text('Guardian Circle', style: ZyraText.heading(size: 28)),
            ),
            const SizedBox(width: 8),
            _action(
              context,
              id: 'menu',
              label: 'Guardian Circle menu',
              onTap: onMenu,
              child: SizedBox(
                width: 44,
                height: 48,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: _surface(radius: 99),
                    child: Icon(
                      Icons.more_horiz,
                      size: 20,
                      color: ZyraColors.foreground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _side),
        child: Row(
          children: [
            _pill(
              context,
              'all',
              'All',
              onAll,
              selected: !pastSelected && selected == null,
            ),
            for (final tile in current) ...[
              const SizedBox(width: 6),
              _pill(
                context,
                'topic_${tile.id}',
                tile.name,
                () => onTopic(tile.id),
                selected: !pastSelected && selected?.id == tile.id,
              ),
            ],
            if (showPast) ...[
              const SizedBox(width: 6),
              _pill(context, 'past', 'Past', onPast, selected: pastSelected),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (!loading && available && selected != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _side),
          child: _headCard(context, selected!),
        ),
      if (!loading && available && _pastTopic)
        Padding(
          padding: const EdgeInsets.fromLTRB(_side, 8, _side, 4),
          child: _pastStatus(selected!),
        ),
      Expanded(child: _body(context)),
      if (!loading && available && !_pastList) _footer(context),
    ],
  );

  Widget _body(BuildContext context) {
    if (loading) {
      return const ZyraLoading(label: 'Opening conversation…');
    }
    if (!available) {
      // The shared error CTA has feedback already. Its inner bound action
      // owns the fresh guard and the single actual feedback event.
      final retry = bind(context, onRetry);
      return ZyraTapFeedback(
        level: () => ZyraHapticLevel.off,
        canAct: () => true,
        child: ZyraUnknownErrorState(onRetry: retry),
      );
    }
    if (_pastList) return _pastRows(context);
    if (messages.isEmpty) return _empty(context);
    final ordered = messages.indexed.toList()
      ..sort((a, b) {
        final date = a.$2.message.createdAt.compareTo(b.$2.message.createdAt);
        return date == 0 ? a.$1.compareTo(b.$1) : date;
      });
    final newestRead = ordered.lastIndexWhere(
      (item) =>
          item.$2.message.senderId == senderId &&
          item.$2.message.readBy.any((reader) => reader.userId != senderId),
    );
    final firstUnread = ordered.indexWhere(
      (item) => item.$2.message.unreadForMe,
    );
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(_side, 8, _side, 12),
      itemCount: ordered.length,
      itemBuilder: (context, index) {
        final item = ordered[index].$2;
        final day = item.message.createdAt.toLocal();
        final previous = index == 0
            ? null
            : ordered[index - 1].$2.message.createdAt.toLocal();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (previous == null || !_sameDay(previous, day))
              _separator(_dayLabel(day)),
            if (index == firstUnread) _separator('UNREAD MESSAGES', gold: true),
            _bubble(context, item, receipt: index == newestRead),
          ],
        );
      },
    );
  }

  Widget _empty(BuildContext context) => ZyraEmptyState(
    icon: Icons.forum_outlined,
    title: selected == null ? 'Talk about your search' : null,
    message: selected == null
        ? 'Who to request, introductions, and what matters to your family. '
              'Each Journey gets its own tab when it begins.'
        : 'No messages about ${selected!.name} yet.\nStart the discussion below.',
  );

  Widget _pastRows(BuildContext context) => ListView(
    controller: scrollController,
    padding: const EdgeInsets.fromLTRB(_side, 0, _side, 24),
    children: [
      for (final tile in past)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _action(
            context,
            id: 'past_${tile.id}',
            label:
                '${_pastName(tile)}, ${_pastDates(tile)}, '
                '${_closed(tile) ? 'Read only' : 'Open · ${_daysLeft(tile)} days left'}',
            onTap: () => onTopic(tile.id),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: _surface(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(14) > 18;
                  final status = Text(
                    _closed(tile)
                        ? 'Read only'
                        : 'Open\n${_daysLeft(tile)} days left',
                    textAlign: compact ? TextAlign.start : TextAlign.end,
                    style: ZyraText.subtext(
                      size: 12,
                      color: _closed(tile)
                          ? ZyraColors.foregroundMuted
                          : ZyraColors.goldText,
                    ),
                  );
                  return Row(
                    children: [
                      _topicImage(tile, size: 52, past: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pastName(tile),
                              style: ZyraText.body(size: 16),
                            ),
                            Text(
                              _pastDates(tile),
                              style: ZyraText.subtext(size: 12),
                            ),
                            if (compact) ...[const SizedBox(height: 4), status],
                          ],
                        ),
                      ),
                      if (!compact) ...[const SizedBox(width: 8), status],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      const SizedBox(height: 2),
      Text(
        'You can talk about a Journey for 30 days after it ends. '
        'Then it becomes read only.'
        '${viewerIsSeeker ? '\nGuardians see these only if you share past Journey summaries with them.' : ''}',
        textAlign: TextAlign.center,
        style: ZyraText.body(size: 13, color: ZyraColors.foregroundMuted),
      ),
    ],
  );

  Widget _headCard(BuildContext context, ZyraCircleTopicTile tile) => Container(
    decoration: _surface(),
    clipBehavior: Clip.antiAlias,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 350 ||
            MediaQuery.textScalerOf(context).scale(14) > 18;
        final action = _pill(
          context,
          _pastTopic ? 'all_past' : 'view_journey',
          _pastTopic ? 'All past' : 'View Journey',
          _pastTopic ? onAllPast : onViewJourney,
          gold: !_pastTopic,
        );
        return Row(
          children: [
            _topicImage(tile, size: 64, past: _pastTopic),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pastTopic ? _pastName(tile) : tile.name,
                      style: ZyraText.body(size: 16),
                    ),
                    if (_pastTopic || tile.stage != null)
                      Text(
                        _pastTopic ? _pastDates(tile) : tile.stage!,
                        style: ZyraText.subtext(size: 12),
                      ),
                    if (compact) ...[
                      const SizedBox(height: 6),
                      Align(alignment: Alignment.centerLeft, child: action),
                    ],
                  ],
                ),
              ),
            ),
            if (!compact) ...[const SizedBox(width: 8), action],
            const SizedBox(width: 12),
          ],
        );
      },
    ),
  );

  Widget _topicImage(
    ZyraCircleTopicTile tile, {
    required double size,
    required bool past,
  }) {
    final photo = tile.photo;
    final showPhoto =
        (!past || viewerIsSeeker) && photo != null && photo.isNotEmpty;
    final image = showPhoto
        ? ZyraProfileImage(photo, width: size, height: size)
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(past && size == 52 ? 12 : 0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ZyraColors.surfaceFill,
          border: showPhoto
              ? null
              : Border.all(color: ZyraColors.surfaceBorder),
          borderRadius: BorderRadius.circular(past && size == 52 ? 12 : 0),
        ),
        child: image != null
            ? past && _closed(tile)
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        .2126,
                        .7152,
                        .0722,
                        0,
                        0,
                        .2126,
                        .7152,
                        .0722,
                        0,
                        0,
                        .2126,
                        .7152,
                        .0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: image,
                    )
                  : image
            : Icon(
                past ? Icons.forum_outlined : Icons.person_outline,
                size: 18,
                color: ZyraColors.journeyGold,
              ),
      ),
    );
  }

  Widget _pastStatus(ZyraCircleTopicTile tile) {
    final deadline = _deadline(tile);
    if (deadline == null) return const SizedBox.shrink();
    return Text(
      _closed(tile)
          ? 'Closed ${_shortDate(deadline)} · read only'
          : 'Open until ${_shortDate(deadline)} · ${_daysLeft(tile)} days left',
      textAlign: TextAlign.center,
      style: ZyraText.subtext(
        size: 12,
        color: _closed(tile) ? ZyraColors.foregroundMuted : ZyraColors.goldText,
      ),
    );
  }

  Widget _bubble(
    BuildContext context,
    ZyraCircleTopicMessage item, {
    required bool receipt,
  }) {
    final message = item.message;
    if (message.lifecycle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          message.body,
          textAlign: TextAlign.center,
          style: ZyraText.subtext(size: 12),
        ),
      );
    }
    final own = message.senderId == senderId;
    final report = !own && message.senderId != null
        ? bind(context, () => onReport(message))
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: own
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(
            widthFactor: MediaQuery.textScalerOf(context).scale(14) > 18
                ? .94
                : .82,
            child: Semantics(
              container: true,
              onLongPress: report,
              child: GestureDetector(
                excludeFromSemantics: true,
                onLongPress: report,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: own
                          ? ZyraColors.surfaceEmphasisBorder
                          : ZyraColors.surfaceBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!own && message.senderIdentityLabel != null) ...[
                        Text(
                          message.senderIdentityLabel!,
                          style: ZyraText.subtext(size: 12),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (item.about != null && item.about!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: ZyraColors.surfaceEmphasisBorder,
                            ),
                          ),
                          child: Text(
                            'About ${item.about}',
                            style: ZyraText.subtext(
                              size: 11,
                              color: ZyraColors.goldText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                      Text(message.body, style: ZyraText.body(size: 13)),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _time(message.createdAt.toLocal()),
                          style: ZyraText.subtext(size: 10.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (receipt)
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 4),
              child: Text(
                _receipt(message),
                textAlign: TextAlign.end,
                style: ZyraText.subtext(size: 13, color: ZyraColors.goldText),
              ),
            ),
        ],
      ),
    );
  }

  String _receipt(ZyraFamilyMessage message) {
    final readers = message.readBy
        .where((reader) => reader.userId != senderId)
        .toList();
    final readIds = readers.map((reader) => reader.userId).toSet();
    final expected = participantIds?.where((id) => id != senderId).toSet();
    final everyone =
        expected != null &&
        expected.isNotEmpty &&
        readIds.length == readers.length &&
        readIds.containsAll(expected);
    return '✓✓ Seen by ${everyone ? 'everyone' : readers.map((reader) => reader.firstName).join(', ')}';
  }

  Widget _separator(String label, {bool gold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: LayoutBuilder(
      builder: (context, box) => Row(
        children: [
          Expanded(child: Divider(color: ZyraColors.divider, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * .6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: ZyraText.subtext(
                  size: 11,
                  color: gold
                      ? ZyraColors.goldText
                      : ZyraColors.foregroundMuted,
                ).copyWith(letterSpacing: 1),
              ),
            ),
          ),
          Expanded(child: Divider(color: ZyraColors.divider, height: 1)),
        ],
      ),
    ),
  );

  Widget _footer(BuildContext context) {
    if (_pastTopic && _closed(selected!)) {
      return _footerLine(
        child: Text(
          'This discussion closed 30 days after the Journey ended. '
          'You can still read it.',
          textAlign: TextAlign.center,
          style: ZyraText.body(size: 13, color: ZyraColors.foregroundMuted),
        ),
      );
    }
    if (guardianBasic) {
      return _footerLine(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final membership = _pill(
              context,
              'membership',
              'See Guardian One',
              onMembership,
              gold: true,
            );
            final line = Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: ZyraColors.foregroundMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You're reading only. Chat comes with Guardian One.",
                    style: ZyraText.body(
                      size: 12,
                      color: ZyraColors.foregroundMuted,
                    ),
                  ),
                ),
              ],
            );
            if (constraints.maxWidth < 350 ||
                MediaQuery.textScalerOf(context).scale(14) > 18) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  line,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: membership),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: line),
                const SizedBox(width: 12),
                membership,
              ],
            );
          },
        ),
      );
    }
    if (!canCompose) return const SizedBox(height: 16);
    final sendBound = bind(context, onSend);
    void send() {
      if (canSendNow?.call() ?? true) sendBound();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(_side, 14, _side, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('circle_topics_composer'),
              controller: composer,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: sending ? null : (_) => send(),
              style: ZyraText.body(size: 14),
              decoration: InputDecoration(
                hintText: 'Message your Circle',
                hintStyle: ZyraText.body(
                  size: 14,
                  color: ZyraColors.foregroundMuted,
                ),
                filled: true,
                fillColor: ZyraColors.surfaceFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: ZyraColors.surfaceEmphasisBorder,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _action(
            context,
            id: 'send',
            label: 'Send message',
            onTap: onSend,
            canAct: canSendNow,
            enabled: !sending,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ZyraColors.journeyGold),
              ),
              child: sending
                  ? Padding(
                      padding: const EdgeInsets.all(15),
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: ZyraColors.journeyGold,
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: ZyraColors.goldText,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLine({required Widget child}) => Padding(
    padding: const EdgeInsets.fromLTRB(_side, 10, _side, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: ZyraColors.divider),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _pill(
    BuildContext context,
    String id,
    String label,
    VoidCallback onTap, {
    bool selected = false,
    bool gold = false,
  }) => _action(
    context,
    id: id,
    label: label,
    onTap: onTap,
    selected: selected,
    child: Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: selected ? ZyraColors.journeyGold.withValues(alpha: .12) : null,
        border: Border.all(
          color: selected || gold
              ? ZyraColors.journeyGold
              : ZyraColors.surfaceBorder,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: ZyraText.body(
          size: 13,
          color: selected || gold
              ? ZyraColors.goldText
              : ZyraColors.foregroundMuted,
        ),
      ),
    ),
  );

  /// Both accessibility and pointer routes call the same owner-bound action.
  Widget _action(
    BuildContext context, {
    required String id,
    required String label,
    required VoidCallback onTap,
    required Widget child,
    bool selected = false,
    bool enabled = true,
    bool Function()? canAct,
  }) {
    final bound = bind(context, onTap);
    void action() {
      if (canAct?.call() ?? true) bound();
    }

    return Semantics(
      key: ValueKey('circle_topics_$id'),
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      onTap: enabled ? action : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: enabled ? action : null,
        child: ExcludeSemantics(child: child),
      ),
    );
  }

  BoxDecoration _surface({double radius = 16}) => BoxDecoration(
    color: ZyraColors.surfaceFill,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: ZyraColors.surfaceBorder),
    boxShadow: [
      BoxShadow(
        color: ZyraColors.warmOverlay.withValues(alpha: .12),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
    ],
  );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(DateTime day) {
    final localNow = now.toLocal();
    if (_sameDay(day, localNow)) return 'TODAY';
    if (_sameDay(
      day,
      DateTime(localNow.year, localNow.month, localNow.day - 1),
    )) {
      return 'YESTERDAY';
    }
    return _shortDate(day).toUpperCase();
  }

  String _time(DateTime time) =>
      '${time.hour % 12 == 0 ? 12 : time.hour % 12}:'
      '${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'AM' : 'PM'}';
}
