// Conversation screen for an Active Journey — per MATCH_UX_SPEC:
// "Conversation belongs to Active Journey only."
//
// Unavailable conversations fail closed. Local sample messages are confined
// to the explicitly authorised and isolated Founder preview, never used as
// a fallback for a real member's missing conversation or failed request.

import 'dart:async';

import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';
import '../../widgets/zyra_profile_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_match_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_message_receipt.dart';
import '../matches/journey_timeline_screen.dart';

class _ChatMessage {
  final String id;
  final String text;
  final bool fromMe;
  final DateTime createdAt;
  final DateTime? readAt;
  const _ChatMessage({
    required this.id,
    required this.text,
    required this.fromMe,
    required this.createdAt,
    this.readAt,
  });
}

class ChatScreen extends StatefulWidget {
  final SeekerProfile withProfile;

  /// Read/write seams for measured failure-state tests. Normal routes omit
  /// these and use the authenticated service and Realtime channel.
  final Future<String?> Function(String)? resolveConversation;
  final Future<ZyraSourceResult<List<ZyraChatMessage>>> Function(String)?
  loadMessages;
  final Future<bool> Function(String, String)? sendMessage;
  final Stream<ZyraChatMessage> Function(String)? incomingMessages;
  final Future<bool> Function(String)? markMessagesRead;

  const ChatScreen({
    super.key,
    required this.withProfile,
    this.resolveConversation,
    this.loadMessages,
    this.sendMessage,
    this.incomingMessages,
    this.markMessagesRead,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _accountGeneration = ZyraAccountState.generation;
  final _accountOwner = ZyraAccountState.userId;
  bool get _accountCurrent =>
      !ZyraAccountState.isSigningOut &&
      _accountGeneration == ZyraAccountState.generation &&
      _accountOwner == ZyraAccountState.userId;
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];

  String? _sendError;
  bool _loading = true;
  bool _unavailable = false;
  bool _sending = false;
  int _loadGeneration = 0;
  String? _firstUnreadMessageId;
  late final bool _localPreview;

  // Non-null only after a real conversation and its history were confirmed.
  String? _conversationId;
  RealtimeChannel? _channel;
  StreamSubscription<ZyraChatMessage>? _incomingSubscription;

  bool get _canSend =>
      _accountCurrent &&
      !_loading &&
      !_unavailable &&
      (_localPreview
          ? ZyraDeveloperAccess.canUseDeveloperTools &&
                ZyraInternalPreviewClient.isActive
          : _conversationId != null && !ZyraInternalPreviewClient.isActive);

  @override
  void initState() {
    super.initState();
    _localPreview =
        ZyraDeveloperAccess.canUseDeveloperTools &&
        ZyraInternalPreviewClient.isActive;
    AppState.instance.addListener(_onAccountChanged);
    _loadRealConversation();
  }

  void _onAccountChanged() {
    if (!mounted || _accountCurrent) return;
    _incomingSubscription?.cancel();
    final channel = _channel;
    if (channel != null) supabase.removeChannel(channel);
    _channel = null;
    setState(() {
      _messages.clear();
      _controller.clear();
      _conversationId = null;
      _unavailable = true;
      _loading = false;
      _sendError = null;
    });
  }

  Future<void> _loadRealConversation() async {
    final generation = ++_loadGeneration;
    _incomingSubscription?.cancel();
    _incomingSubscription = null;
    final previousChannel = _channel;
    if (previousChannel != null) supabase.removeChannel(previousChannel);
    _channel = null;
    setState(() {
      _loading = true;
      _unavailable = false;
    });
    if (_localPreview && _accountCurrent) {
      setState(() => _loading = false);
      return;
    }
    try {
      if (!_accountCurrent || ZyraInternalPreviewClient.isActive) {
        throw StateError('Preview closed');
      }
      final convId =
          await (widget.resolveConversation ??
              ZyraMatchService.resolveConversationId)(widget.withProfile.id);
      if (!mounted || !_accountCurrent || generation != _loadGeneration) return;
      if (convId == null) throw StateError('Conversation unavailable');
      final history =
          await (widget.loadMessages ?? ZyraMatchService.fetchMessagesResult)(
            convId,
          );
      if (!mounted || !_accountCurrent || generation != _loadGeneration) return;
      if (!history.isAvailable || ZyraInternalPreviewClient.isActive) {
        throw StateError('History unavailable');
      }
      setState(() {
        _conversationId = convId;
        _loading = false;
        _messages
          ..clear()
          ..addAll(
            history
                .valueOr(const [])
                .map(
                  (m) => _ChatMessage(
                    id: m.id,
                    text: m.text,
                    fromMe: m.fromMe,
                    createdAt: m.createdAt,
                    readAt: m.readAt,
                  ),
                ),
          );
        _firstUnreadMessageId = history
            .valueOr(const [])
            .where((message) => !message.fromMe && message.readAt == null)
            .firstOrNull
            ?.id;
      });
      unawaited(_markRead(convId));
      final incoming = widget.incomingMessages;
      if (incoming != null) {
        _incomingSubscription = incoming(convId).listen((message) {
          if (!mounted || !_accountCurrent) return;
          setState(() => _messages.add(_fromServiceMessage(message)));
          if (!message.fromMe) unawaited(_markRead(convId));
        });
        return;
      }

      _channel = supabase.channel('messages:$convId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: convId,
          ),
          callback: (payload) {
            if (!mounted || !_accountCurrent) return;
            final row = payload.newRecord;
            if (row['sender_id'] == ZyraAuth.currentUser?.id) {
              return; // our acknowledged send is appended by _send
            }
            setState(
              () => _messages.add(
                _ChatMessage(
                  id:
                      row['id'] as String? ??
                      'live-${DateTime.now().microsecondsSinceEpoch}',
                  text: row['content'] as String? ?? '',
                  fromMe: false,
                  createdAt:
                      DateTime.tryParse(row['created_at'] as String? ?? '') ??
                      DateTime.now(),
                  readAt: row['read_at'] == null
                      ? null
                      : DateTime.tryParse(row['read_at'] as String),
                ),
              ),
            );
            unawaited(_markRead(convId));
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: convId,
          ),
          callback: (payload) {
            if (!mounted || !_accountCurrent) return;
            final row = payload.newRecord;
            final id = row['id'] as String?;
            final readAt = DateTime.tryParse(row['read_at'] as String? ?? '');
            if (id == null || readAt == null) return;
            final index = _messages.indexWhere((message) => message.id == id);
            if (index < 0 || !_messages[index].fromMe) return;
            final previous = _messages[index];
            setState(() {
              _messages[index] = _ChatMessage(
                id: previous.id,
                text: previous.text,
                fromMe: true,
                createdAt: previous.createdAt,
                readAt: readAt,
              );
            });
          },
        );
      _channel!.subscribe();
    } catch (error) {
      debugPrint('ZYRA: conversation unavailable (${error.runtimeType}).');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _unavailable = true;
        _conversationId = null;
      });
    }
  }

  _ChatMessage _fromServiceMessage(ZyraChatMessage message) => _ChatMessage(
    id: message.id,
    text: message.text,
    fromMe: message.fromMe,
    createdAt: message.createdAt,
    readAt: message.readAt,
  );

  Future<void> _markRead(String conversationId) async {
    await (widget.markMessagesRead ?? ZyraMatchService.markMessagesRead)(
      conversationId,
    );
  }

  // Do not paint a sent bubble until the server acknowledges the write.
  // In particular, never removeLast() on failure: an incoming message may
  // have arrived since the send started and would be the item removed.
  Future<void> _send() async {
    final draft = _controller.text;
    final text = draft.trim();
    if (!_canSend || _sending || text.isEmpty) return;
    setState(() => _sending = true);
    var ok = false;
    try {
      ok = _localPreview
          ? true
          : await (widget.sendMessage ?? ZyraMatchService.sendMessage)(
              _conversationId!,
              text,
            );
    } catch (error) {
      debugPrint('ZYRA: message send failed (${error.runtimeType}).');
    }
    if (!mounted || !_accountCurrent) return;
    setState(() {
      _sending = false;
      if (ok && _canSend) {
        _messages.add(
          _ChatMessage(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            text: text,
            fromMe: true,
            createdAt: DateTime.now(),
          ),
        );
        // A new draft typed while the write was in flight belongs to the user.
        if (_controller.text == draft) _controller.clear();
        _sendError = null;
      } else {
        _sendError =
            "That didn't send. Your message is still here to try again.";
      }
    });
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAccountChanged);
    _controller.dispose();
    _incomingSubscription?.cancel();
    final channel = _channel;
    if (channel != null) supabase.removeChannel(channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 2026-07-25: gender-matched gradient (DR-ZYRA-094) — see
        // ZyraColors.genderGradient() doc comment.
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, color: ZyraColors.ink(0.70)),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: ZyraProfileImage(
                        widget.withProfile.photoUrl,
                        width: 36,
                        height: 36,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.withProfile.firstName,
                        style: ZyraText.body(size: 15, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JourneyTimelineScreen(
                            withProfile: widget.withProfile,
                          ),
                        ),
                      ),
                      icon: Icon(
                        Icons.timeline_outlined,
                        color: ZyraColors.ink(0.70),
                      ),
                      tooltip: 'Timeline',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const ZyraLoading(label: 'Opening conversation…')
                    : _unavailable || !_accountCurrent
                    ? ZyraEmptyState(
                        icon: Icons.forum_outlined,
                        title: 'Conversation unavailable',
                        message:
                            'We could not open this conversation. Please try again.',
                        ctaLabel: 'Try again',
                        onCta: _loadRealConversation,
                      )
                    : _messages.isEmpty
                    ? ZyraEmptyState(
                        icon: Icons.mail_outline,
                        message:
                            'Say Salam to start your Journey with ${widget.withProfile.firstName}.',
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final messageIndex = _messages.length - 1 - index;
                          final m = _messages[messageIndex];
                          final latestMine = _messages.lastIndexWhere(
                            (message) => message.fromMe,
                          );
                          return Column(
                            children: [
                              if (m.id == _firstUnreadMessageId)
                                const ZyraUnreadMessagesDivider(),
                              Align(
                                alignment: m.fromMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: m.fromMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.72,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: m.fromMe
                                            ? ZyraColors.accentBg
                                            : ZyraColors.iconButtonBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: m.fromMe
                                              ? ZyraColors.accentBorder
                                              : ZyraColors.iconButtonBorder,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (!m.fromMe) ...[
                                            Text(
                                              '${widget.withProfile.firstName} · Seeker',
                                              style: ZyraText.subtext(
                                                size: 10.5,
                                                color: ZyraColors.actionFill,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                          ],
                                          Text(
                                            m.text,
                                            style: ZyraText.body(
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (m.fromMe && messageIndex == latestMine)
                                      ZyraMessageReceipt(
                                        readBy: m.readAt == null
                                            ? const []
                                            : [
                                                ZyraMessageReader(
                                                  userId: widget.withProfile.id,
                                                  firstName: widget
                                                      .withProfile
                                                      .firstName,
                                                  roleLabel: 'Seeker',
                                                  readAt: m.readAt,
                                                ),
                                              ],
                                        recipientCount: 1,
                                      )
                                    else
                                      const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              if (_sendError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: ZyraErrorBanner(
                    message: _sendError!,
                    onRetry: _sending ? null : _send,
                    onDismiss: () => setState(() {
                      _sendError = null;
                    }),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: _canSend,
                        controller: _controller,
                        style: ZyraText.body(size: 14, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Message…',
                          hintStyle: ZyraText.body(
                            size: 14,
                            color: ZyraColors.ink(0.38),
                          ),
                          filled: true,
                          fillColor: ZyraColors.iconButtonBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      tooltip: _sending ? 'Sending message' : 'Send message',
                      onPressed: _canSend && !_sending ? _send : null,
                      icon: Icon(Icons.send, color: ZyraColors.ink(0.70)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
