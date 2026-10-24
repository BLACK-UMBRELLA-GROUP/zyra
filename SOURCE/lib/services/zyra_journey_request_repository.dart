import '../models/zyra_journey_request.dart';

/// OA151 production integration port. A future implementation must authenticate
/// the captured owner, parse a versioned server contract and use caller-scoped
/// wrappers; it must never call oa151_kernel or write relationship tables.
/// No mock, developer override or membership choice is a production fallback.
abstract interface class ZyraJourneyRequestRepository {
  Future<ZyraJourneyRequestInbox> read(ZyraJourneyRequestOwner owner);
  Future<ZyraJourneyRequestAcknowledgement> execute(
    ZyraJourneyRequestOwner owner,
    ZyraJourneyRequestCommand command,
  );
}

/// The only shipped default. No endpoints are guessed, no network is attempted,
/// and no access is granted while the real adapter/bridge is unimplemented.
final class ZyraHeldJourneyRequestRepository
    implements ZyraJourneyRequestRepository {
  const ZyraHeldJourneyRequestRepository();

  @override
  Future<ZyraJourneyRequestInbox> read(ZyraJourneyRequestOwner owner) async =>
      ZyraJourneyRequestInbox(
        actorId: owner.actorId,
        availability: ZyraJourneyRequestAvailability.held,
      );

  @override
  Future<ZyraJourneyRequestAcknowledgement> execute(
    ZyraJourneyRequestOwner owner,
    ZyraJourneyRequestCommand command,
  ) async => ZyraJourneyRequestAcknowledgement(
    actorId: owner.actorId,
    action: command.action,
    subjectId: command.subjectId,
    operationKey: command.operationKey,
    status: ZyraJourneyRequestWriteStatus.held,
  );
}
