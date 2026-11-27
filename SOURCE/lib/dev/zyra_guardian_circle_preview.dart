import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'zyra_guardian_circle_topic_options.dart';
import 'zyra_circle_topics_presentation.dart';
import '../services/zyra_family_messaging_service.dart';

/// Widget-test input for a delivered message; the app supplies no fixture.
typedef ZyraCirclePreviewArrivals =
    Iterable<ZyraFamilyMessage> Function(String seekerId, String viewerId);

/// A preview preference belongs to this Circle and viewer. A null chat ID
/// means the whole Circle.
typedef ZyraCirclePreviewMuteKey = (
  String seekerId,
  String viewerId,
  String? chatId,
);

/// Identity of the Main divider for one entry after the shell records reads.
typedef ZyraCircleMainUnreadHint = ({
  String seekerId,
  String viewerId,
  String messageId,
  String senderId,
});

/// The viewer's admitted chat-list fields from Q138, backed by preview data.
enum ZyraCircleChatKind { main, journey }

enum ZyraCircleChatState { current, past }

typedef ZyraCircleChatListEntry = ({
  String chatId,
  ZyraCircleChatKind kind,
  ZyraCircleChatState state,
  String? otherFirstName,
  DateTime? lastMessageAt,
  DateTime? endedAt,
  int unreadCount,
  bool muted,
  bool circleMuted,
  bool countsTowardTotal,
});

/// Immutable caller-owned examples for the retained Circle presentation.
/// These values are never a link, membership, identity or server grant.
class ZyraGuardianCirclePreviewData {
  ZyraGuardianCirclePreviewData({
    required this.seekerId,
    required this.senderId,
    required Iterable<ZyraFamilyCircleParticipant> participants,
    Iterable<ZyraFamilyMessage> messages = const [],
    Iterable<ZyraFamilyMessageContext> contexts = const [],
    required this.canSend,
    this.mainChatId = 'preview-circle-general',
    Map<String, String> currentChatIds = const {},
    Iterable<ZyraCircleDiscussionTopic> admittedTopics = const [],
    Map<String, ZyraCircleDiscussionTopic> messageTopics = const {},
    Set<String> departedMemberIds = const {},
  }) : currentChatIds = Map.unmodifiable(currentChatIds),
       admittedTopics = List.unmodifiable(admittedTopics),
       messageTopics = Map.unmodifiable(messageTopics),
       participants = List.unmodifiable(
         participants.where(
           (person) => !departedMemberIds.contains(person.userId),
         ),
       ),
       messages = List.unmodifiable(
         messages
             .where(
               (message) =>
                   !departedMemberIds.contains(message.senderId) &&
                   !departedMemberIds.contains(message.context?.referenceId),
             )
             .map((message) => _snapshotMessage(message, departedMemberIds)),
       ),
       contexts = List.unmodifiable(
         contexts.where(
           (context) => !departedMemberIds.contains(context.referenceId),
         ),
       );

  final String seekerId;
  final String senderId;
  final List<ZyraFamilyCircleParticipant> participants;
  final List<ZyraFamilyMessage> messages;
  final List<ZyraFamilyMessageContext> contexts;
  final bool canSend;
  final String mainChatId;
  final Map<String, String> currentChatIds;
  final List<ZyraCircleDiscussionTopic> admittedTopics;
  final Map<String, ZyraCircleDiscussionTopic> messageTopics;

  ZyraCirclePreviewMuteKey muteKey(String? chatId) =>
      (seekerId, senderId, chatId);

  String currentChatId(String referenceId) =>
      currentChatIds[referenceId] ?? referenceId;

  String chatFor(ZyraFamilyMessage message) =>
      messageTopics[message.id]?.id ??
      (message.context == null
          ? mainChatId
          : currentChatId(message.context!.referenceId));

  String messageKey(String chatId, ZyraFamilyMessage message) =>
      scopedMessageKey(seekerId, senderId, chatId, message);

  static String scopedMessageKey(
    String seekerId,
    String senderId,
    String chatId,
    ZyraFamilyMessage message,
  ) {
    final key = '$seekerId:$senderId:${message.id}:${message.senderId}';
    // Checkpoints predating Q138 already identify Main receipts this way.
    return chatId == ZyraCircleDiscussionTopic.mainChatId(seekerId) ||
            chatId == ZyraCircleDiscussionTopic.general.id
        ? key
        : '$chatId:$key';
  }

  bool isUnread(ZyraFamilyMessage message) =>
      message.unreadForMe && message.senderId != senderId && !message.lifecycle;

  Map<String, ZyraCircleChatListEntry> listChats({
    required Iterable<ZyraCircleDiscussionTopic> admittedTopics,
    required Iterable<ZyraFamilyMessage> messages,
    required String Function(ZyraFamilyMessage) chatFor,
    required bool Function(ZyraFamilyMessage) isUnread,
    required bool Function(String?) isMuted,
  }) {
    final latest = <String, DateTime>{};
    final unread = <String, int>{};
    for (final message in messages) {
      if (message.lifecycle) continue;
      final chatId = chatFor(message);
      final last = latest[chatId];
      if (last == null || message.createdAt.isAfter(last)) {
        latest[chatId] = message.createdAt;
      }
      if (isUnread(message)) {
        unread.update(chatId, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final circleMuted = isMuted(null);
    ZyraCircleChatListEntry entry(
      String chatId, [
      ZyraCircleDiscussionTopic? topic,
    ]) {
      final muted = isMuted(chatId);
      return (
        chatId: chatId,
        kind: topic == null
            ? ZyraCircleChatKind.main
            : ZyraCircleChatKind.journey,
        state: topic?.isPast == true
            ? ZyraCircleChatState.past
            : ZyraCircleChatState.current,
        otherFirstName: topic?.firstName,
        lastMessageAt: latest[chatId],
        endedAt: topic?.endedOn,
        unreadCount: unread[chatId] ?? 0,
        muted: muted,
        circleMuted: circleMuted,
        countsTowardTotal: !muted && !circleMuted,
      );
    }

    return {
      mainChatId: entry(mainChatId),
      for (final topic in admittedTopics) topic.id: entry(topic.id, topic),
    };
  }

  bool validFor(String expectedSeeker, {bool? viewerIsSeeker}) =>
      seekerId.isNotEmpty &&
      seekerId == expectedSeeker &&
      senderId.isNotEmpty &&
      participants.isNotEmpty &&
      participants.map((person) => person.userId).toSet().length ==
          participants.length &&
      participants.every(
        (person) =>
            person.userId.isNotEmpty &&
            person.firstName.trim().isNotEmpty &&
            (person.memberRole == 'seeker' || person.memberRole == 'guardian'),
      ) &&
      participants.where((person) => person.memberRole == 'seeker').length ==
          1 &&
      participants.any(
        (person) => person.memberRole == 'seeker' && person.userId == seekerId,
      ) &&
      participants.where((person) => person.isCurrentUser).length == 1 &&
      participants.any(
        (person) =>
            person.isCurrentUser &&
            person.userId == senderId &&
            (viewerIsSeeker == null ||
                person.memberRole == (viewerIsSeeker ? 'seeker' : 'guardian')),
      ) &&
      contexts.map((context) => context.referenceId).toSet().length ==
          contexts.length &&
      contexts.every(
        (context) =>
            context.kind == ZyraFamilyMessageContextKind.active &&
            context.referenceId.isNotEmpty &&
            context.firstName.trim().isNotEmpty,
      ) &&
      messages.map((message) => message.id).toSet().length == messages.length &&
      messages.every(
        (message) =>
            message.id.isNotEmpty &&
            message.body.trim().isNotEmpty &&
            message.body.length <= 2000 &&
            (message.context == null || includesContext(message.context!)),
      );

  bool includesContext(ZyraFamilyMessageContext context) => contexts.any(
    (known) =>
        known.referenceId == context.referenceId &&
        known.firstName == context.firstName &&
        known.kind == context.kind,
  );
}

ZyraFamilyMessage _snapshotMessage(
  ZyraFamilyMessage message,
  Set<String> departedMemberIds,
) => ZyraFamilyMessage(
  id: message.id,
  senderId: message.senderId,
  senderFirstName: message.senderFirstName,
  senderRelationship: message.senderRelationship,
  senderRoleLabel: message.senderRoleLabel,
  body: message.body,
  createdAt: message.createdAt,
  lifecycle: message.lifecycle,
  context: message.context,
  readBy: List.unmodifiable(
    message.readBy.where(
      (reader) => !departedMemberIds.contains(reader.userId),
    ),
  ),
  unreadForMe: message.unreadForMe,
);

/// LOCK 20 display metadata for an already-admitted local preview. It never
/// enables preview, links a member, or supplies a server writing entitlement.
@immutable
class ZyraCircleTopicsPreview {
  ZyraCircleTopicsPreview({
    required Iterable<ZyraCircleTopicTile> tiles,
    required Iterable<String> readOnlyParticipantIds,
    required this.guardianBasic,
    Iterable<String> oneParticipantIds = const [],
    required this.onManageGuardians,
    required this.onMembership,
    this.clock,
    this.onRead,
    this.onSent,
    this.nextSentId,
    this.arrivals,
    this.onMuteChanged,
    this.mainUnreadOnEntry,
    this.introductionAttachment,
    Set<ZyraCirclePreviewMuteKey>? mutedChats,
    Map<String, ZyraCircleDiscussionTopic> messageTopics = const {},
  }) : mutedChats = mutedChats ?? {},
       tiles = List.unmodifiable(tiles),
       readOnlyParticipantIds = Set.unmodifiable(readOnlyParticipantIds),
       oneParticipantIds = Set.unmodifiable(oneParticipantIds),
       messageTopics = Map.unmodifiable(messageTopics);

  final List<ZyraCircleTopicTile> tiles;
  final Set<String> readOnlyParticipantIds, oneParticipantIds;
  final bool guardianBasic;
  final VoidCallback onManageGuardians;
  final VoidCallback onMembership;
  final DateTime Function()? clock;
  final void Function(String chatId, List<ZyraFamilyMessage> messages)? onRead;
  final void Function(String chatId, ZyraFamilyMessage message)? onSent;
  final String Function()? nextSentId;
  final ValueListenable<ZyraGuardianCirclePreviewData?>? arrivals;
  final VoidCallback? onMuteChanged;
  final Widget? Function(BuildContext context, String id)?
  introductionAttachment;
  final ZyraCircleMainUnreadHint? mainUnreadOnEntry;
  final Set<ZyraCirclePreviewMuteKey> mutedChats;

  /// Labels already carried by this admitted transcript. These never add a
  /// tab, archive, profile, or send target when a Journey is not accessible.
  final Map<String, ZyraCircleDiscussionTopic> messageTopics;
}
