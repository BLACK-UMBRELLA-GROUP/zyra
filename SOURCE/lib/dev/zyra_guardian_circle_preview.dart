import 'package:flutter/foundation.dart';
import 'zyra_guardian_circle_topic_options.dart';
import 'zyra_circle_topics_presentation.dart';
import '../services/zyra_family_messaging_service.dart';

/// Widget-test input for a delivered message; the app supplies no fixture.
typedef ZyraCirclePreviewArrivals =
    Iterable<ZyraFamilyMessage> Function(String seekerId, String viewerId);

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
    Set<String> departedMemberIds = const {},
  }) : hasDepartedMember = departedMemberIds.isNotEmpty,
       participants = List.unmodifiable(
         participants.where(
           (person) => !departedMemberIds.contains(person.userId),
         ),
       ),
       messages = List.unmodifiable(
         messages
             .where((message) => !departedMemberIds.contains(message.senderId))
             .map((message) => _snapshotMessage(message, departedMemberIds)),
       ),
       contexts = List.unmodifiable(contexts);

  final String seekerId;
  final String senderId;
  final List<ZyraFamilyCircleParticipant> participants;
  final List<ZyraFamilyMessage> messages;
  final List<ZyraFamilyMessageContext> contexts;
  final bool canSend, hasDepartedMember;

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
    Map<String, ZyraCircleDiscussionTopic> messageTopics = const {},
  }) : tiles = List.unmodifiable(tiles),
       readOnlyParticipantIds = Set.unmodifiable(readOnlyParticipantIds),
       oneParticipantIds = Set.unmodifiable(oneParticipantIds),
       messageTopics = Map.unmodifiable(messageTopics);

  final List<ZyraCircleTopicTile> tiles;
  final Set<String> readOnlyParticipantIds, oneParticipantIds;
  final bool guardianBasic;
  final VoidCallback onManageGuardians;
  final VoidCallback onMembership;
  final DateTime Function()? clock;

  /// Labels already carried by this admitted transcript. These never add a
  /// tab, archive, profile, or send target when a Journey is not accessible.
  final Map<String, ZyraCircleDiscussionTopic> messageTopics;
}
