part of '../screens/wali/family_messaging_screens.dart';

/// LOCK 20 uses the retained Circle transcript, sending path, caller authority
/// and exact Journey/discussion references. No live capability is added here.
extension _CircleTopicsState on _ZyraGuardianCircleScreenState {
  bool get _validTopicsMetadata {
    final data = _previewData, topics = _topics;
    if (data == null || topics == null || !widget.preview) return false;
    final ids = data.participants.map((p) => p.userId).toSet();
    return topics.readOnlyParticipantIds.every(ids.contains) &&
        !topics.readOnlyParticipantIds.contains(data.seekerId) &&
        topics.guardianBasic ==
            (!widget.viewerIsSeeker &&
                topics.readOnlyParticipantIds.contains(data.senderId)) &&
        topics.tiles.map((t) => t.id).toSet().length == topics.tiles.length &&
        topics.tiles.every(
          (tile) => [
            ...data.contexts.map((c) => (c.referenceId, c.firstName)),
            ..._pastTopics.map((t) => (t.id, t.firstName)),
          ].contains((tile.id, tile.name)),
        );
  }

  VoidCallback _bindTopics(BuildContext context, VoidCallback action) {
    final epoch = _topicsEpoch, thread = _threadId, send = _sendRequest;
    var revoked = false;
    bool current() {
      if (revoked) return false;
      final fresh =
          _topicsEnabled &&
          _canActOnCircleRoute &&
          epoch == _topicsEpoch &&
          thread == _threadId &&
          send == _sendRequest &&
          _topicsSheet == null;
      if (!fresh) revoked = true;
      return fresh;
    }

    final feedback = ZyraTapFeedback.onTap(context, action, canAct: current);
    return () {
      if (current()) feedback?.call();
    };
  }

  ZyraCircleDiscussionArchive? _topicsArchiveFor(
    ZyraCircleDiscussionTopic topic,
  ) {
    if (!_topicsEnabled ||
        !_authority.isCurrent ||
        !_callerCurrent ||
        !topic.isPast ||
        !_includesDiscussionTopic(topic)) {
      return null;
    }
    try {
      final archive = _discussionArchiveResolver?.call(topic);
      if (archive == null ||
          archive.topicId != topic.id ||
          archive.firstName != topic.firstName ||
          archive.sharedSummaryLabel != topic.sharedSummaryLabel ||
          archive.endedOn != topic.endedOn ||
          archive.startedOn.isAfter(archive.endedOn)) {
        return null;
      }
      return archive;
    } catch (_) {
      return null;
    }
  }

  ZyraCircleTopicTile _topicsTile(ZyraCircleDiscussionTopic topic) {
    final detail = _topics!.tiles.where((t) => t.id == topic.id).firstOrNull;
    final archive = topic.isPast ? _topicsArchiveFor(topic) : null;
    return ZyraCircleTopicTile(
      id: topic.id,
      name: topic.firstName,
      stage: detail?.stage,
      photo: widget.viewerIsSeeker || !topic.isPast ? detail?.photo : null,
      startedOn: archive?.startedOn,
      endedOn: archive?.endedOn,
      sharedLabel: archive?.sharedSummaryLabel?.split(' · ').first,
    );
  }

  void _selectTopics(String? id, {bool past = false}) {
    if (!_canActOnCircleRoute || _topicsSheet != null) return;
    final options = past ? _pastTopics : _currentTopics;
    final selected = id == null
        ? null
        : options.where((t) => t.id == id).firstOrNull;
    if (id != null && selected == null) return;
    if (selected?.isPast == true && _topicsArchiveFor(selected!) == null) {
      return;
    }
    _topicsChange(() {
      _topicsSelection = selected;
      _topicsPast = past;
      _topicPickRequest++;
      _messageReferenceEpoch++;
      _topicsEpoch++;
      _topicsLaidOut = false;
    });
  }

  void _topicsNewest() {
    if (_topicsLaidOut || _loading) return;
    _topicsLaidOut = true;
    final epoch = _topicsEpoch, thread = _threadId;
    void reveal(int remaining) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_canActOnCircleRoute ||
            epoch != _topicsEpoch ||
            thread != _threadId ||
            !_topicMessageScroll.hasClients) {
          return;
        }
        _topicMessageScroll.jumpTo(
          _topicMessageScroll.position.maxScrollExtent,
        );
        if (remaining > 0) reveal(remaining - 1);
      });
    }

    reveal(3);
  }

  Widget _buildTopics(BuildContext context) {
    final data = _previewData!, topics = _topics!;
    final routeCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (_topicsRouteCurrent != null &&
        _topicsRouteCurrent != routeCurrent &&
        _topicsSheet == null) {
      _topicsEpoch++;
    }
    _topicsRouteCurrent = routeCurrent;
    _topicsNewest();
    final selected = _topicsSelection;
    final messages =
        _messages
            .where(
              (m) =>
                  selected == null ||
                  _discussionMessageTags[m.id]?.id == selected.id ||
                  m.context?.referenceId == selected.id,
            )
            .toList()
          ..sort((a, b) {
            final time = a.createdAt.compareTo(b.createdAt);
            return time != 0
                ? time
                : _messages.indexOf(a).compareTo(_messages.indexOf(b));
          });
    return _withBackReturn(
      context,
      ZyraGuardianPreviewRouteBoundary(
        authority: _authority,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: ZyraAppGoldDecoration(
              gradient: ZyraColors.genderGradient(AppState.instance.gender),
            ),
            child: SafeArea(
              bottom: false,
              child: ZyraCircleTopicsPresentation(
                viewerIsSeeker: widget.viewerIsSeeker,
                guardianBasic: topics.guardianBasic,
                senderId: data.senderId,
                seekerName: widget.seekerFirstName,
                participantIds: data.participants.map((p) => p.userId).toSet(),
                loading: _loading,
                available: _available,
                pastSelected: _topicsPast,
                showPast: _pastTopics.isNotEmpty,
                canSendNow: () =>
                    _canSend &&
                    !_sending &&
                    !(_topicsPast && _topicsSelection == null),
                canCompose:
                    _canPresentComposer && !(_topicsPast && selected == null),
                current: _currentTopics.map(_topicsTile).toList(),
                past: _pastTopics
                    .where((t) => _topicsArchiveFor(t) != null)
                    .map(_topicsTile)
                    .toList(),
                selected: selected == null ? null : _topicsTile(selected),
                messages: messages
                    .map(
                      (m) => ZyraCircleTopicMessage(
                        message: m,
                        about:
                            _discussionMessageTags[m.id]?.firstName ??
                            m.context?.firstName,
                      ),
                    )
                    .toList(),
                now: _topicsNow,
                scrollController: _topicMessageScroll,
                composer: _composer,
                sending: _sending,
                bind: _bindTopics,
                onMenu: _showTopicsMenu,
                onSend: () {
                  _topicsLaidOut = false;
                  _send();
                },
                onAll: () => _selectTopics(null),
                onPast: () => _selectTopics(null, past: true),
                onAllPast: () => _selectTopics(null, past: true),
                onTopic: (id) =>
                    _selectTopics(id, past: _pastTopics.any((t) => t.id == id)),
                onViewJourney: () {
                  final selected = _topicsSelection;
                  final exact = data.contexts
                      .where(
                        (c) =>
                            c.referenceId == selected?.id &&
                            c.firstName == selected?.firstName,
                      )
                      .firstOrNull;
                  if (exact != null && _canActOnCircleRoute) {
                    widget.onOpenContext?.call(exact);
                  }
                },
                onMembership: () {
                  if (!widget.viewerIsSeeker && _canActOnCircleRoute) {
                    topics.onMembership();
                  }
                },
                onRetry: _load,
                onReport: (message) {
                  if (message.senderId != null &&
                      message.senderId != _currentSenderId &&
                      _messages.any((m) => identical(m, message))) {
                    _report(message);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTopicsMenu() async {
    if (!_canActOnCircleRoute || _topicsSheet != null) return;
    final lease = Object(), epoch = _topicsEpoch;
    _topicsSheet = lease;
    BuildContext? owned;
    var revision = 0;
    bool current() =>
        mounted &&
        _canInteract &&
        _topicsEpoch == epoch &&
        identical(_topicsSheet, lease) &&
        owned?.mounted == true &&
        ModalRoute.of(owned!)?.isCurrent == true;
    String? result;
    try {
      result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xFFF7F2EA),
        barrierColor: const Color(0xFF1E1610).withValues(alpha: .38),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        builder: (sheetContext) {
          owned = sheetContext;
          return _guardRoute(
            sheetContext,
            StatefulBuilder(
              builder: (context, update) {
                VoidCallback bind(BuildContext context, VoidCallback action) {
                  final render = revision;
                  bool fresh() => current() && render == revision;
                  final feedback = ZyraTapFeedback.onTap(
                    context,
                    action,
                    canAct: fresh,
                  );
                  return () {
                    if (fresh()) feedback?.call();
                  };
                }

                return _CircleTopicsMenu(
                  participants: _previewData!.participants,
                  readOnly: _topics!.readOnlyParticipantIds,
                  viewerIsSeeker: widget.viewerIsSeeker,
                  muted: _topicsMuted,
                  bind: bind,
                  onDone: () => Navigator.of(sheetContext).pop(),
                  onMute: () {
                    if (current()) {
                      update(() {
                        _topicsMuted = !_topicsMuted;
                        revision++;
                      });
                    }
                  },
                  onReport: () => Navigator.of(sheetContext).pop('report'),
                  onManage: () => Navigator.of(sheetContext).pop('manage'),
                  onBasic: (id) => Navigator.of(sheetContext).pop('basic:$id'),
                );
              },
            ),
          );
        },
      );
    } finally {
      if (identical(_topicsSheet, lease)) _topicsSheet = null;
      _topicsEpoch++;
    }
    if (!_canActOnCircleRoute) return;
    if (result == 'report') _notice('Press and hold a message to report it.');
    if (result == 'manage' && widget.viewerIsSeeker) {
      _topics!.onManageGuardians();
    }
    if (result?.startsWith('basic:') == true && widget.viewerIsSeeker) {
      final id = result!.substring(6);
      final person = _previewData!.participants
          .where(
            (p) =>
                p.userId == id &&
                p.memberRole == 'guardian' &&
                _topics!.readOnlyParticipantIds.contains(id),
          )
          .firstOrNull;
      if (person != null) await _showTopicsFamily(person);
    }
  }

  Future<void> _showTopicsFamily(ZyraFamilyCircleParticipant person) async {
    if (!_canActOnCircleRoute || _topicsSheet != null) return;
    final lease = Object(), epoch = _topicsEpoch;
    _topicsSheet = lease;
    BuildContext? owned;
    bool current() =>
        mounted &&
        _canInteract &&
        epoch == _topicsEpoch &&
        identical(_topicsSheet, lease) &&
        owned?.mounted == true &&
        ModalRoute.of(owned!)?.isCurrent == true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xFFF7F2EA),
        barrierColor: const Color(0xFF1E1610).withValues(alpha: .38),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        builder: (context) {
          owned = context;
          return _guardRoute(
            context,
            ZyraGuardianFamilySheet(
              guardianName: person.firstName,
              canAct: current,
              invited: _familyInvites.contains(person.userId),
              onInvite: () {
                if (current()) _familyInvites.add(person.userId);
              },
              onCancelInvite: () {
                if (current()) _familyInvites.remove(person.userId);
              },
              onClose: () {
                if (current()) Navigator.of(context).pop();
              },
            ),
          );
        },
      );
    } finally {
      if (identical(_topicsSheet, lease)) _topicsSheet = null;
      _topicsEpoch++;
    }
  }
}

class _CircleTopicsMenu extends StatelessWidget {
  const _CircleTopicsMenu({
    required this.participants,
    required this.readOnly,
    required this.viewerIsSeeker,
    required this.muted,
    required this.bind,
    required this.onDone,
    required this.onMute,
    required this.onReport,
    required this.onManage,
    required this.onBasic,
  });
  final List<ZyraFamilyCircleParticipant> participants;
  final Set<String> readOnly;
  final bool viewerIsSeeker, muted;
  final VoidCallback Function(BuildContext, VoidCallback) bind;
  final VoidCallback onDone, onMute, onReport, onManage;
  final ValueChanged<String> onBasic;
  @override
  Widget build(BuildContext context) {
    Widget row(
      String text,
      VoidCallback action, {
      String? trailing,
      Key? key,
    }) => InkWell(
      key: key,
      onTap: bind(context, action),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
        child: Row(
          children: [
            Expanded(child: Text(text, style: ZyraText.body(size: 14))),
            if (trailing != null)
              Text(trailing, style: ZyraText.subtext(size: 12)),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ZyraColors.foregroundMuted.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Guardian Circle', style: ZyraText.heading(size: 22)),
          const SizedBox(height: 14),
          Text(
            'IN THE CIRCLE',
            style: ZyraText.subtext(
              size: 11,
            ).copyWith(color: ZyraColors.goldText, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          for (final p in participants) ...[
            InkWell(
              key: ValueKey('circle_topics_member_${p.userId}'),
              onTap: viewerIsSeeker && readOnly.contains(p.userId)
                  ? bind(context, () => onBasic(p.userId))
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: p.memberRole == 'seeker'
                              ? [
                                  const Color(0xFFAC7C2E),
                                  const Color(0xFF4C3A20),
                                ]
                              : [
                                  const Color(0xFF77796A),
                                  const Color(0xFF3D3A30),
                                ],
                        ),
                        border: p.isMainGuardian
                            ? Border.all(
                                color: ZyraColors.journeyGold,
                                width: 2,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.firstName.characters.first,
                        style: ZyraText.body(size: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.isCurrentUser ? 'You' : p.firstName,
                            style: ZyraText.body(size: 14),
                          ),
                          Text(
                            p.memberRole == 'seeker'
                                ? 'Seeker'
                                : p.isMainGuardian
                                ? 'Main Guardian'
                                : 'Additional Guardian',
                            style: ZyraText.subtext(size: 12).copyWith(
                              color: p.isMainGuardian
                                  ? ZyraColors.goldText
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      readOnly.contains(p.userId)
                          ? 'Reads only${viewerIsSeeker ? ' ›' : ''}'
                          : 'Writes',
                      style: ZyraText.subtext(size: 12),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: ZyraColors.foregroundMuted.withValues(alpha: .18),
            ),
          ],
          row(
            muted ? 'Unmute the Circle' : 'Mute the Circle',
            onMute,
            trailing: muted ? 'Muted' : null,
            key: const ValueKey('circle_topics_mute'),
          ),
          Divider(
            height: 1,
            color: ZyraColors.foregroundMuted.withValues(alpha: .18),
          ),
          row(
            'Report a message',
            onReport,
            key: const ValueKey('circle_topics_report'),
          ),
          if (viewerIsSeeker) ...[
            Divider(
              height: 1,
              color: ZyraColors.foregroundMuted.withValues(alpha: .18),
            ),
            row(
              'Manage your Guardians',
              onManage,
              key: const ValueKey('circle_topics_manage'),
            ),
          ],
          Divider(
            height: 1,
            color: ZyraColors.foregroundMuted.withValues(alpha: .18),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              key: const ValueKey('circle_topics_done'),
              onPressed: bind(context, onDone),
              style: FilledButton.styleFrom(
                backgroundColor: ZyraColors.primaryAction,
                foregroundColor: ZyraColors.foreground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text('Done', style: ZyraText.button(size: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
