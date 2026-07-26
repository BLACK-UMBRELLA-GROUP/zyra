// Conversation screen for an Active Journey — per MATCH_UX_SPEC:
// "Conversation belongs to Active Journey only."
//
// Real wiring (2026-07-18): if withProfile is a real matched Seeker,
// resolves the real conversation, loads message history, subscribes
// to Realtime for incoming messages, and sends via the real
// `messages` table. Falls back to the original local-only mock chat
// (including the [failtest] deterministic failure trigger) whenever
// no real conversation exists — not signed in, or withProfile is a
// mock Browse candidate with no backing match. This keeps the screen
// fully testable in both states rather than breaking mock Active
// Journeys built before real matches existed.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_match_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../matches/journey_timeline_screen.dart';

class _ChatMessage {
  final String text;
  final bool fromMe;
  const _ChatMessage(this.text, this.fromMe);
}

class ChatScreen extends StatefulWidget {
  final SeekerProfile withProfile;
  const ChatScreen({super.key, required this.withProfile});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late final List<_ChatMessage> _messages = [
    _ChatMessage(
      'Assalamu alaikum — excited to start this Journey together, in sha Allah.',
      false,
    ),
  ];

  String? _sendError;
  String? _pendingText;

  // Non-null once a real conversation has been resolved (see
  // _loadRealConversation). While null, this screen behaves exactly
  // as it did before real backend wiring.
  String? _conversationId;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadRealConversation();
  }

  Future<void> _loadRealConversation() async {
    final convId = await ZyraMatchService.resolveConversationId(widget.withProfile.id);
    if (!mounted || convId == null) return;

    final history = await ZyraMatchService.fetchMessages(convId);
    if (!mounted) return;
    setState(() {
      _conversationId = convId;
      if (history.isNotEmpty) {
        _messages
          ..clear()
          ..addAll(history.map((m) => _ChatMessage(m.text, m.fromMe)));
      }
    });

    _channel = supabase.channel('messages:$convId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: convId),
        callback: (payload) {
          if (!mounted) return;
          final row = payload.newRecord;
          if (row['sender_id'] == ZyraAuth.currentUser?.id) return; // already shown optimistically on send
          setState(() => _messages.add(_ChatMessage(row['content'] as String? ?? '', false)));
        },
      );
    _channel!.subscribe();
  }

  // "[failtest]" is a deterministic trigger for the send-failure state
  // (Category 2, ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md /
  // DR-ZYRA-080) — kept only for the no-real-conversation mock path.
  // Once a real conversation exists, failures are genuine (real
  // network/RLS errors), so [failtest] no longer applies there.
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_conversationId != null) {
      setState(() {
        _messages.add(_ChatMessage(text, true));
        _controller.clear();
        _sendError = null;
      });
      final ok = await ZyraMatchService.sendMessage(_conversationId!, text);
      if (!ok && mounted) {
        setState(() {
          _messages.removeLast();
          _pendingText = text;
          _sendError = "That didn't send. Tap to try again.";
        });
      }
      return;
    }

    if (text.toLowerCase().contains('[failtest]')) {
      setState(() {
        _pendingText = text;
        _sendError = "That didn't send. Tap to try again.";
        _controller.clear();
      });
      return;
    }
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _controller.clear();
      _sendError = null;
    });
  }

  Future<void> _retrySend() async {
    final text = _pendingText;
    if (text == null) return;
    final cleanText = text.replaceAll(RegExp(r'\[failtest\]', caseSensitive: false), '').trim();

    if (_conversationId != null) {
      setState(() {
        _messages.add(_ChatMessage(cleanText, true));
        _sendError = null;
        _pendingText = null;
      });
      final ok = await ZyraMatchService.sendMessage(_conversationId!, cleanText);
      if (!ok && mounted) {
        setState(() {
          _messages.removeLast();
          _pendingText = cleanText;
          _sendError = "That didn't send. Tap to try again.";
        });
      }
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(cleanText, true));
      _sendError = null;
      _pendingText = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(widget.withProfile.photoUrl, width: 36, height: 36, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(width: 36, height: 36)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.withProfile.firstName, style: ZyraText.body(size: 15, color: Colors.white))),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => JourneyTimelineScreen(withProfile: widget.withProfile)),
                      ),
                      icon: const Icon(Icons.timeline_outlined, color: Colors.white70),
                      tooltip: 'Timeline',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _messages.isEmpty
                    ? ZyraEmptyState(
                        icon: Icons.mail_outline,
                        message: 'Say Salam to start your Journey with ${widget.withProfile.firstName}.',
                      )
                    : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[_messages.length - 1 - index];
                    return Align(
                      alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: m.fromMe ? ZyraColors.accentBg : ZyraColors.iconButtonBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: m.fromMe ? ZyraColors.accentBorder : ZyraColors.iconButtonBorder, width: 0.5),
                        ),
                        child: Text(m.text, style: ZyraText.body(size: 14, color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
              if (_sendError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: ZyraErrorBanner(
                    message: _sendError!,
                    onRetry: _retrySend,
                    onDismiss: () => setState(() {
                      _sendError = null;
                      _pendingText = null;
                    }),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: ZyraText.body(size: 14, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Message…',
                          hintStyle: ZyraText.body(size: 14, color: Colors.white38),
                          filled: true,
                          fillColor: ZyraColors.iconButtonBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send, color: Colors.white70),
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
