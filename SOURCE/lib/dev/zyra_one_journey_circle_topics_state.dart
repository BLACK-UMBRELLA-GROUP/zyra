part of '../screens/wali/family_messaging_screens.dart';

/// LOCK 20 uses the retained Circle transcript, sending path, caller authority
/// and exact Journey/discussion references. No live capability is added here.
extension _CircleTopicsState on _ZyraGuardianCircleScreenState {
  bool get _validTopicsMetadata {
    final data = _previewData, topics = _topics;
    if (data == null || topics == null || !widget.preview) return false;
    final ids = data.participants.map((p) => p.userId).toSet();
    final guardianIds = {
      for (final participant in data.participants)
        if (participant.memberRole == 'guardian') participant.userId,
    };
    return topics.oneParticipantIds.every(guardianIds.contains) &&
        topics.oneParticipantIds
            .intersection(topics.readOnlyParticipantIds)
            .isEmpty &&
        topics.readOnlyParticipantIds.every(ids.contains) &&
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

  String _topicFor(ZyraFamilyMessage message) =>
      _discussionMessageTags[message.id]?.id ??
      message.context?.referenceId ??
      ZyraCircleDiscussionTopic.general.id;

  bool _topicUnread(ZyraFamilyMessage message) =>
      message.unreadForMe &&
      message.senderId != _currentSenderId &&
      !message.lifecycle &&
      !_topicReadIds.contains((message.id, message.senderId));

  bool _topicMuted(String? id) =>
      _topics!.mutedChats.contains(_previewData!.muteKey(id));

  void _readTopics({bool preserveDivider = false}) {
    if (_topicsPast && _topicsSelection == null || _selectedPastUnavailable) {
      _topicUnreadDividerId = null;
      return;
    }
    final id = _topicsSelection?.id ?? ZyraCircleDiscussionTopic.general.id;
    final read =
        _messages.where((m) => _topicFor(m) == id && _topicUnread(m)).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (!preserveDivider || _topicUnreadDividerId == null) {
      _topicUnreadDividerId = read.firstOrNull?.id;
    }
    if (read.isEmpty) return;
    _topicReadIds.addAll(read.map((message) => (message.id, message.senderId)));
    _topics!.onRead?.call(read);
  }

  void _setTopicsMessageTags(ZyraGuardianCirclePreviewData data) {
    final tags = {..._topics!.messageTopics, ...data.messageTopics};
    for (final message in data.messages) {
      final tag = tags[message.id];
      // Existing About labels remain display metadata and grant no tab.
      if (tag != null &&
          tag.id.isNotEmpty &&
          tag.id.length <= 200 &&
          tag.firstName.trim().isNotEmpty &&
          tag.firstName.length <= 80 &&
          !tag.isGeneral &&
          (!tag.isPast || tag.endedOn != null)) {
        _discussionMessageTags[message.id] = tag;
      }
    }
  }

  void _refreshTopicsMessages() {
    if (!_topicsEnabled || !_canInteract) return;
    final data = _topics!.arrivals?.value;
    final original = _previewData!;
    if (data == null ||
        data.senderId != original.senderId ||
        !data.validFor(
          original.seekerId,
          viewerIsSeeker: widget.viewerIsSeeker,
        ) ||
        data.contexts.length != original.contexts.length ||
        !data.contexts.every(original.includesContext)) {
      return;
    }
    final routeVisible = _canActOnCircleRoute && _topicsSheet == null;
    _topicsChange(() {
      final local = _messages
          .where((m) => !_topicsSourceIds.contains(m.id))
          .toList();
      _discussionMessageTags.removeWhere(
        (id, _) => _topicsSourceIds.contains(id),
      );
      _topicsSourceIds = data.messages.map((m) => m.id).toSet();
      _setTopicsMessageTags(data);
      _messages = [
        ...data.messages,
        ...local.where((m) => !_topicsSourceIds.contains(m.id)),
      ];
      if (routeVisible) {
        _readTopics(preserveDivider: true);
        _topicsLaidOut = false;
      }
    });
  }

  ZyraCircleTopicTile _topicsTile(
    ZyraCircleDiscussionTopic topic,
    Map<String, int> unread, {
    ZyraCircleDiscussionArchive? archive,
  }) {
    final detail = _topics!.tiles.where((t) => t.id == topic.id).firstOrNull;
    return ZyraCircleTopicTile(
      id: topic.id,
      name: topic.firstName,
      stage: detail?.stage,
      photo: widget.viewerIsSeeker || !topic.isPast ? detail?.photo : null,
      startedOn: archive?.startedOn,
      endedOn: archive?.endedOn,
      sharedLabel: archive?.sharedSummaryLabel?.split(' · ').first,
      unread: unread[topic.id] ?? 0,
      muted: _topicMuted(topic.id),
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
      _readTopics();
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
    final pastList = _topicsPast && _topicsSelection == null;
    void reveal(int remaining) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_canActOnCircleRoute ||
            epoch != _topicsEpoch ||
            thread != _threadId ||
            !_topicMessageScroll.hasClients) {
          return;
        }
        final position = _topicMessageScroll.position;
        position.jumpTo(
          pastList ? position.minScrollExtent : position.maxScrollExtent,
        );
        if (!pastList && remaining > 0) reveal(remaining - 1);
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
    if (routeCurrent &&
        _topicsRouteCurrent == false &&
        _topicsSheet == null &&
        _canInteract) {
      final epoch = _topicsEpoch;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            epoch == _topicsEpoch &&
            _canActOnCircleRoute &&
            _topicsSheet == null) {
          _topicsChange(() => _readTopics(preserveDivider: true));
        }
      });
    }
    _topicsRouteCurrent = routeCurrent;
    _topicsNewest();
    final selected = _topicsSelection;
    final unread = <String, int>{};
    final newestMessage = <String, DateTime>{};
    final messages = <ZyraCircleTopicMessage>[];
    for (final message in _messages) {
      final chat = _topicFor(message);
      if (_topicUnread(message)) {
        unread.update(chat, (count) => count + 1, ifAbsent: () => 1);
      }
      final latest = newestMessage[chat];
      if (!message.lifecycle &&
          (latest == null || message.createdAt.isAfter(latest))) {
        newestMessage[chat] = message.createdAt;
      }
      if (selected == null || chat == selected.id) {
        messages.add(
          ZyraCircleTopicMessage(
            message: message,
            about:
                _discussionMessageTags[message.id]?.firstName ??
                message.context?.firstName,
          ),
        );
      }
    }
    final past =
        [
          for (final topic in _pastTopics)
            if (_topicsArchiveFor(topic) case final archive?)
              _topicsTile(topic, unread, archive: archive),
        ]..sort((a, b) {
          final aUnread = !a.muted && a.unread > 0;
          final bUnread = !b.muted && b.unread > 0;
          if (aUnread != bUnread) return aUnread ? -1 : 1;
          if (aUnread) {
            final time = newestMessage[b.id]!.compareTo(newestMessage[a.id]!);
            if (time != 0) return time;
          }
          final end = b.endedOn!.compareTo(a.endedOn!);
          return end == 0 ? a.id.compareTo(b.id) : end;
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
                showPast: past.isNotEmpty,
                mainUnread: unread[ZyraCircleDiscussionTopic.general.id] ?? 0,
                mainMuted: _topicMuted(ZyraCircleDiscussionTopic.general.id),
                unreadDividerId: _topicUnreadDividerId,
                canSendNow: () =>
                    _canSend &&
                    !_sending &&
                    !(_topicsPast && _topicsSelection == null),
                canCompose:
                    _canPresentComposer && !(_topicsPast && selected == null),
                current: _currentTopics
                    .map((topic) => _topicsTile(topic, unread))
                    .toList(),
                past: past,
                selected: selected == null
                    ? null
                    : _topicsTile(
                        selected,
                        unread,
                        archive: selected.isPast
                            ? _topicsArchiveFor(selected)
                            : null,
                      ),
                messages: messages,
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

  void _toggleTopicsMute(String? id, String chat, VoidCallback clearToast) {
    final key = _previewData!.muteKey(id);
    final muted = _topics!.mutedChats.add(key);
    if (!muted) _topics.mutedChats.remove(key);
    _topics.onMuteChanged?.call();
    _topicsToastTimer?.cancel();
    _topicsToast = muted
        ? '$chat muted — no alerts, messages still arrive.'
        : '$chat unmuted.';
    _topicsToastTimer = Timer(const Duration(milliseconds: 1700), clearToast);
  }

  Future<void> _showTopicsMenu() async {
    if (!_canActOnCircleRoute || _topicsSheet != null) return;
    final lease = Object(), epoch = _topicsEpoch;
    final selection = _topicsSelection;
    if (_selectedPastUnavailable) return;
    final chatId =
        selection?.id ??
        (_topicsPast ? null : ZyraCircleDiscussionTopic.general.id);
    final chatName = selection == null
        ? 'Main chat'
        : '${selection.firstName}’s chat';
    _topicsSheet = lease;
    BuildContext? owned;
    var revision = 0;
    bool current() =>
        mounted &&
        _canInteract &&
        _topicsEpoch == epoch &&
        !_selectedPastUnavailable &&
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

                void toggle(String? id, String name) {
                  if (!current()) return;
                  _topicsChange(
                    () => _toggleTopicsMute(id, name, () {
                      if (current()) update(() => _topicsToast = null);
                    }),
                  );
                  update(() => revision++);
                }

                return _CircleTopicsMenu(
                  participants: _previewData!.participants,
                  readOnly: _topics!.readOnlyParticipantIds,
                  oneParticipantIds: _topics.oneParticipantIds,
                  viewerIsSeeker: widget.viewerIsSeeker,
                  muted: _topicMuted(null),
                  chatMuted: chatId != null && _topicMuted(chatId),
                  chatLabel: chatId == null
                      ? null
                      : selection == null
                      ? 'the Main chat'
                      : chatName,
                  toast: _topicsToast,
                  bind: bind,
                  onDone: () => Navigator.of(sheetContext).pop(),
                  onMute: () => toggle(null, 'Circle'),
                  onMuteChat: () => toggle(chatId, chatName),
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
      _topicsToastTimer?.cancel();
      _topicsToast = null;
      if (identical(_topicsSheet, lease)) _topicsSheet = null;
      _topicsEpoch++;
    }
    if (!_canActOnCircleRoute) return;
    _topicsChange(() => _readTopics(preserveDivider: true));
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
    if (_canActOnCircleRoute) {
      _topicsChange(() => _readTopics(preserveDivider: true));
    }
  }
}

class _CircleTopicsMenu extends StatelessWidget {
  const _CircleTopicsMenu({
    required this.participants,
    required this.readOnly,
    required this.oneParticipantIds,
    required this.viewerIsSeeker,
    required this.muted,
    required this.chatMuted,
    required this.chatLabel,
    required this.toast,
    required this.onMuteChat,
    required this.bind,
    required this.onDone,
    required this.onMute,
    required this.onReport,
    required this.onManage,
    required this.onBasic,
  });
  final List<ZyraFamilyCircleParticipant> participants;
  final Set<String> readOnly, oneParticipantIds;
  final bool viewerIsSeeker, muted, chatMuted;
  final String? chatLabel, toast;
  final VoidCallback Function(BuildContext, VoidCallback) bind;
  final VoidCallback onDone, onMute, onMuteChat, onReport, onManage;
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
            if (trailing == null) const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
    final menu = SingleChildScrollView(
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
                    if (p.memberRole == 'guardian')
                      ZyraGoldRingMonogram(
                        name: p.firstName,
                        guardianOne: oneParticipantIds.contains(p.userId),
                        size: 36,
                        fontSize: 14,
                      )
                    else
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFAC7C2E), Color(0xFF4C3A20)],
                          ),
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
          if (chatLabel case final label?) ...[
            row(
              chatMuted ? 'Unmute $label' : 'Mute $label',
              onMuteChat,
              trailing: chatMuted ? 'Muted' : null,
              key: const ValueKey('circle_topics_mute_chat'),
            ),
            Divider(
              height: 1,
              color: ZyraColors.foregroundMuted.withValues(alpha: .18),
            ),
          ],
          row(
            muted ? 'Unmute the whole Circle' : 'Mute the whole Circle',
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
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        menu,
        if (toast case final text?)
          Positioned(
            left: 20,
            right: 20,
            bottom: 100,
            child: IgnorePointer(
              child: Semantics(
                liveRegion: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2420).withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ZyraColors.surfaceBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: ZyraText.body(
                        size: 12.5,
                        color: const Color(0xFFFFFFFE),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
