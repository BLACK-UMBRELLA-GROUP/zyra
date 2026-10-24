// OA151 integration ports, not a new canonical Journey lifecycle. No client
// model, selected plan, receipt-shaped value or retry key confers access.
import 'package:flutter/foundation.dart' show immutable;

enum ZyraJourneyRequestState {
  pending,
  accepted,
  declined,
  cancelled,
  expired,
  bridged,
}

enum ZyraJourneyRequestAction { send, cancel, decline, accept, confirmReady }

enum ZyraJourneyRequestAvailability { available, held, unavailable }

enum ZyraJourneyRequestWriteStatus { applied, refused, held, unavailable }

enum ZyraJourneyRequestResult {
  applied,
  refused,
  held,
  unavailable,
  staleOwner,
  staleResponse,
  invalidResponse,
  invalidAction,
  busy,
}

bool zyraRequestIdentifierIsValid(String value) => RegExp(
  // PostgreSQL emits canonical lower-case UUIDs. Reject noncanonical spellings
  // so string equality, participant checks and retry identities agree.
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
).hasMatch(value);

@immutable
class ZyraJourneyRequestOwner {
  const ZyraJourneyRequestOwner(this.actorId, this.generation);
  final String actorId;
  final int generation;
}

/// Only a trusted production repository may supply this binding after the
/// server's atomic reservation-to-canonical bridge. It selects an existing
/// route; that route must still rehydrate its authorized attempt and ritual.
/// It does NOT grant compatibility, Guardian, chat or Open Conversation access.
@immutable
class ZyraJourneyRequestBinding {
  const ZyraJourneyRequestBinding({
    required this.requestId,
    required this.matchId,
    required this.attemptId,
  });
  final String requestId;
  final String matchId;
  final String attemptId;

  bool get structurallyValid =>
      zyraRequestIdentifierIsValid(requestId) &&
      zyraRequestIdentifierIsValid(matchId) &&
      zyraRequestIdentifierIsValid(attemptId) &&
      requestId != matchId &&
      requestId != attemptId &&
      matchId != attemptId;
}

@immutable
class ZyraJourneyRequestRecord {
  const ZyraJourneyRequestRecord({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.state,
    required this.senderReady,
    required this.recipientReady,
    this.binding,
  });
  final String id;
  final String senderId;
  final String recipientId;
  final ZyraJourneyRequestState state;
  final bool senderReady;
  final bool recipientReady;
  final ZyraJourneyRequestBinding? binding;

  bool belongsTo(String actorId) =>
      senderId == actorId || recipientId == actorId;

  bool validFor(String actorId) =>
      zyraRequestIdentifierIsValid(id) &&
      zyraRequestIdentifierIsValid(senderId) &&
      zyraRequestIdentifierIsValid(recipientId) &&
      senderId != recipientId &&
      belongsTo(actorId) &&
      (state == ZyraJourneyRequestState.bridged
          ? binding != null &&
                binding!.structurallyValid &&
                binding!.requestId == id &&
                senderReady &&
                recipientReady
          : binding == null) &&
      (state != ZyraJourneyRequestState.pending ||
          (!senderReady && !recipientReady));
}

/// An unavailable read never means an empty inbox. Policy values, entitlement
/// calculations and deadline selection belong on the server, not in this port.
@immutable
class ZyraJourneyRequestInbox {
  ZyraJourneyRequestInbox({
    required this.actorId,
    required this.availability,
    Iterable<ZyraJourneyRequestRecord> records = const [],
  }) : records = List.unmodifiable(records);
  final String actorId;
  final ZyraJourneyRequestAvailability availability;
  final List<ZyraJourneyRequestRecord> records;

  bool validFor(String expectedActor) =>
      actorId == expectedActor &&
      zyraRequestIdentifierIsValid(actorId) &&
      (availability == ZyraJourneyRequestAvailability.available ||
          records.isEmpty) &&
      records.every((record) => record.validFor(actorId)) &&
      records.map((record) => record.id).toSet().length == records.length;
}

@immutable
class ZyraJourneyRequestCommand {
  const ZyraJourneyRequestCommand({
    required this.action,
    required this.subjectId,
    required this.operationKey,
  });
  final ZyraJourneyRequestAction action;
  // Target member for send; request ID for every other action. Never a match ID.
  final String subjectId;
  final String operationKey;
}

@immutable
class ZyraJourneyRequestAcknowledgement {
  const ZyraJourneyRequestAcknowledgement({
    required this.actorId,
    required this.action,
    required this.subjectId,
    required this.operationKey,
    required this.status,
  });
  final String actorId;
  final ZyraJourneyRequestAction action;
  final String subjectId;
  final String operationKey;
  final ZyraJourneyRequestWriteStatus status;

  bool matches(
    ZyraJourneyRequestOwner owner,
    ZyraJourneyRequestCommand command,
  ) =>
      actorId == owner.actorId &&
      action == command.action &&
      subjectId == command.subjectId &&
      operationKey == command.operationKey;
}
