import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_journey_request.dart';
import 'package:zyra/services/zyra_journey_request_controller.dart';
import 'package:zyra/services/zyra_journey_request_repository.dart';

// Typed in-memory transports only: no real network/provider or entitlement.
const _a = '00000000-0000-4000-8000-000000001501';
const _b = '00000000-0000-4000-8000-000000001502';
const _c = '00000000-0000-4000-8000-000000001503';
const _request = '00000000-0000-4000-8000-000000001504';
const _match = '00000000-0000-4000-8000-000000001505';
const _attempt = '00000000-0000-4000-8000-000000001506';
const _owner = ZyraJourneyRequestOwner(_a, 1);

ZyraJourneyRequestRecord _record({
  String id = _request,
  String sender = _a,
  String recipient = _b,
  ZyraJourneyRequestState state = ZyraJourneyRequestState.pending,
  bool ready = false,
  ZyraJourneyRequestBinding? binding,
}) => ZyraJourneyRequestRecord(
  id: id,
  senderId: sender,
  recipientId: recipient,
  state: state,
  senderReady: ready,
  recipientReady: ready,
  binding: binding,
);

ZyraJourneyRequestInbox _inbox({
  String actor = _a,
  ZyraJourneyRequestAvailability status =
      ZyraJourneyRequestAvailability.available,
  List<ZyraJourneyRequestRecord> records = const [],
}) => ZyraJourneyRequestInbox(
  actorId: actor,
  availability: status,
  records: records,
);

const _binding = ZyraJourneyRequestBinding(
  requestId: _request,
  matchId: _match,
  attemptId: _attempt,
);

class _Repository implements ZyraJourneyRequestRepository {
  Future<ZyraJourneyRequestInbox> Function(ZyraJourneyRequestOwner) reader =
      (_) async => _inbox();
  late Future<ZyraJourneyRequestAcknowledgement> Function(
    ZyraJourneyRequestOwner,
    ZyraJourneyRequestCommand,
  )
  writer;
  final commands = <ZyraJourneyRequestCommand>[];

  _Repository() {
    writer = (owner, command) async => _ack(owner, command);
  }

  @override
  Future<ZyraJourneyRequestInbox> read(ZyraJourneyRequestOwner owner) =>
      reader(owner);

  @override
  Future<ZyraJourneyRequestAcknowledgement> execute(
    ZyraJourneyRequestOwner owner,
    ZyraJourneyRequestCommand command,
  ) {
    commands.add(command);
    return writer(owner, command);
  }
}

ZyraJourneyRequestAcknowledgement _ack(
  ZyraJourneyRequestOwner owner,
  ZyraJourneyRequestCommand command, {
  String? actor,
  String? subject,
  String? key,
  ZyraJourneyRequestWriteStatus status = ZyraJourneyRequestWriteStatus.applied,
}) => ZyraJourneyRequestAcknowledgement(
  actorId: actor ?? owner.actorId,
  action: command.action,
  subjectId: subject ?? command.subjectId,
  operationKey: key ?? command.operationKey,
  status: status,
);

void main() {
  late _Repository repository;
  late ZyraJourneyRequestController controller;
  var currentActor = _a;
  var currentGeneration = 1;

  setUp(() {
    currentActor = _a;
    currentGeneration = 1;
    repository = _Repository();
    controller = ZyraJourneyRequestController(
      owner: _owner,
      ownerIsCurrent: (owner) =>
          owner.actorId == currentActor &&
          owner.generation == currentGeneration,
      repository: repository,
    );
  });
  tearDown(() => controller.dispose());

  test('shipped repository is held without dispatching or granting', () async {
    const held = ZyraHeldJourneyRequestRepository();
    expect(
      (await held.read(_owner)).availability,
      ZyraJourneyRequestAvailability.held,
    );
    expect(
      (await held.execute(
        _owner,
        const ZyraJourneyRequestCommand(
          action: ZyraJourneyRequestAction.send,
          subjectId: _b,
          operationKey: _request,
        ),
      )).status,
      ZyraJourneyRequestWriteStatus.held,
    );
    final heldController = ZyraJourneyRequestController(
      owner: _owner,
      ownerIsCurrent: (_) => true,
    );
    addTearDown(heldController.dispose);
    expect(await heldController.refresh(), ZyraJourneyRequestResult.held);
    expect(
      await heldController.execute(ZyraJourneyRequestAction.send, _b),
      ZyraJourneyRequestResult.held,
    );
    expect(heldController.canonicalBindingFor(_request), isNull);
  });

  test('initial unknown inbox cannot dispatch', () async {
    expect(
      await controller.execute(ZyraJourneyRequestAction.send, _b),
      ZyraJourneyRequestResult.unavailable,
    );
    expect(repository.commands, isEmpty);
  });

  test(
    'noncanonical UUID spellings cannot bypass identity comparisons',
    () async {
      const lower = 'abcdef01-0000-4000-8000-000000001507';
      final upper = lower.toUpperCase();
      expect(zyraRequestIdentifierIsValid(lower), isTrue);
      expect(zyraRequestIdentifierIsValid(upper), isFalse);
      expect(
        ZyraJourneyRequestBinding(
          requestId: lower,
          matchId: upper,
          attemptId: _attempt,
        ).structurallyValid,
        isFalse,
      );
      expect(
        _inbox(
          records: [
            _record(id: lower),
            _record(id: upper),
          ],
        ).validFor(_a),
        isFalse,
      );
      await controller.refresh();
      expect(
        await controller.execute(ZyraJourneyRequestAction.send, upper),
        ZyraJourneyRequestResult.invalidAction,
      );
      expect(repository.commands, isEmpty);
    },
  );

  test(
    'ambiguous retries keep the exact key; changed target gets another',
    () async {
      await controller.refresh();
      repository.writer = (_, _) async =>
          throw StateError('lost acknowledgement');
      for (final target in [_b, _b, _c]) {
        expect(
          await controller.execute(ZyraJourneyRequestAction.send, target),
          ZyraJourneyRequestResult.unavailable,
        );
      }
      expect(
        repository.commands[0].operationKey,
        repository.commands[1].operationKey,
      );
      expect(
        repository.commands[0].operationKey,
        isNot(repository.commands[2].operationKey),
      );
      expect(
        zyraRequestIdentifierIsValid(repository.commands[0].operationKey),
        isTrue,
      );
      expect(controller.inbox!.records, isEmpty);
    },
  );

  test('duplicate presses cannot run two concurrent commands', () async {
    await controller.refresh();
    final pending = Completer<ZyraJourneyRequestAcknowledgement>();
    repository.writer = (_, _) => pending.future;
    final first = controller.execute(ZyraJourneyRequestAction.send, _b);
    expect(controller.isWriting, isTrue);
    expect(
      await controller.execute(ZyraJourneyRequestAction.send, _b),
      ZyraJourneyRequestResult.busy,
    );
    expect(await controller.refresh(), ZyraJourneyRequestResult.busy);
    pending.complete(_ack(_owner, repository.commands.single));
    expect(await first, ZyraJourneyRequestResult.applied);
    expect(repository.commands, hasLength(1));
    expect(controller.isWriting, isFalse);
    // Confirmed write requires an authoritative refresh before a new intent.
    expect(
      await controller.execute(ZyraJourneyRequestAction.send, _b),
      ZyraJourneyRequestResult.unavailable,
    );
  });

  for (final mismatch in ['actor', 'subject', 'operation']) {
    test('mismatched $mismatch acknowledgement is not success', () async {
      await controller.refresh();
      repository.writer = (owner, command) async => _ack(
        owner,
        command,
        actor: mismatch == 'actor' ? _c : null,
        subject: mismatch == 'subject' ? _c : null,
        key: mismatch == 'operation' ? _request : null,
      );
      expect(
        await controller.execute(ZyraJourneyRequestAction.send, _b),
        ZyraJourneyRequestResult.invalidResponse,
      );
      expect(controller.canonicalBindingFor(_request), isNull);
    });
  }

  for (final failure in [false, true]) {
    test(
      'account replacement during ${failure ? 'failure' : 'success'} drops result',
      () async {
        final pending = Completer<ZyraJourneyRequestInbox>();
        repository.reader = (_) => pending.future;
        final read = controller.refresh();
        currentActor = _c;
        if (failure) {
          pending.completeError(StateError('safe fake error'));
        } else {
          pending.complete(_inbox(records: [_record()]));
        }
        expect(await read, ZyraJourneyRequestResult.staleOwner);
        expect(controller.inbox, isNull);
        currentActor = _a;
        expect(await controller.refresh(), ZyraJourneyRequestResult.staleOwner);
      },
    );
  }

  test(
    'same-account relogin epoch revokes both cache and late command',
    () async {
      await controller.refresh();
      final pending = Completer<ZyraJourneyRequestAcknowledgement>();
      repository.writer = (_, _) => pending.future;
      final write = controller.execute(ZyraJourneyRequestAction.send, _b);
      currentGeneration++;
      pending.complete(_ack(_owner, repository.commands.single));
      expect(await write, ZyraJourneyRequestResult.staleOwner);
      expect(controller.inbox, isNull);
    },
  );

  test('late error after account change cannot publish', () async {
    await controller.refresh();
    final pending = Completer<ZyraJourneyRequestAcknowledgement>();
    repository.writer = (_, _) => pending.future;
    final write = controller.execute(ZyraJourneyRequestAction.send, _b);
    currentActor = _c;
    pending.completeError(StateError('synthetic private provider error'));
    expect(await write, ZyraJourneyRequestResult.staleOwner);
    expect(controller.inbox, isNull);
  });

  test(
    'obsolete same-owner read cannot overwrite the newer response',
    () async {
      final first = Completer<ZyraJourneyRequestInbox>();
      repository.reader = (_) => first.future;
      final old = controller.refresh();
      repository.reader = (_) async => _inbox(records: [_record()]);
      expect(await controller.refresh(), ZyraJourneyRequestResult.applied);
      first.complete(_inbox());
      expect(await old, ZyraJourneyRequestResult.staleResponse);
      expect(controller.inbox!.records, hasLength(1));
    },
  );

  test(
    'failed read keeps last-known inbox, not an empty successful read',
    () async {
      repository.reader = (_) async => _inbox(records: [_record()]);
      await controller.refresh();
      repository.reader = (_) async => throw StateError('network unavailable');
      expect(await controller.refresh(), ZyraJourneyRequestResult.unavailable);
      expect(controller.inbox!.records, hasLength(1));
      expect(controller.canonicalBindingFor(_request), isNull);
      expect(
        await controller.execute(ZyraJourneyRequestAction.cancel, _request),
        ZyraJourneyRequestResult.unavailable,
      );
      expect(repository.commands, isEmpty);
    },
  );

  for (final status in [
    ZyraJourneyRequestAvailability.held,
    ZyraJourneyRequestAvailability.unavailable,
  ]) {
    test('$status read blocks commands from cached availability', () async {
      await controller.refresh();
      repository.reader = (_) async => _inbox(status: status);
      await controller.refresh();
      expect(
        await controller.execute(ZyraJourneyRequestAction.send, _b),
        anyOf(
          ZyraJourneyRequestResult.held,
          ZyraJourneyRequestResult.unavailable,
        ),
      );
      expect(repository.commands, isEmpty);
    });
  }

  test('malformed refresh retains display data but blocks dispatch', () async {
    repository.reader = (_) async => _inbox(records: [_record()]);
    await controller.refresh();
    repository.reader = (_) async => _inbox(actor: _c);
    expect(
      await controller.refresh(),
      ZyraJourneyRequestResult.invalidResponse,
    );
    expect(controller.inbox!.records, hasLength(1));
    expect(
      await controller.execute(ZyraJourneyRequestAction.cancel, _request),
      ZyraJourneyRequestResult.unavailable,
    );
    expect(repository.commands, isEmpty);
  });

  test(
    'unknown actor, stranger, duplicate and malformed bindings are rejected',
    () async {
      for (final invalid in [
        _inbox(actor: _c),
        _inbox(
          records: [_record(sender: _b, recipient: _c)],
        ),
        _inbox(records: [_record(), _record()]),
        _inbox(records: [_record(binding: _binding)]),
        _inbox(
          records: [
            _record(state: ZyraJourneyRequestState.bridged, ready: true),
          ],
        ),
        _inbox(
          records: [
            _record(state: ZyraJourneyRequestState.bridged, binding: _binding),
          ],
        ),
        _inbox(
          status: ZyraJourneyRequestAvailability.held,
          records: [_record()],
        ),
      ]) {
        repository.reader = (_) async => invalid;
        expect(
          await controller.refresh(),
          ZyraJourneyRequestResult.invalidResponse,
        );
        expect(controller.canonicalBindingFor(_request), isNull);
      }
    },
  );

  test(
    'only recipient can accept; accepted preparation is not a canonical route',
    () async {
      repository.reader = (_) async => _inbox(records: [_record()]);
      await controller.refresh();
      expect(
        await controller.execute(ZyraJourneyRequestAction.accept, _request),
        ZyraJourneyRequestResult.invalidAction,
      );
      repository.reader = (_) async => _inbox(
        records: [_record(sender: _b, recipient: _a)],
      );
      await controller.refresh();
      expect(
        await controller.execute(ZyraJourneyRequestAction.accept, _request),
        ZyraJourneyRequestResult.applied,
      );
      expect(controller.canonicalBindingFor(_request), isNull);
      repository.reader = (_) async => _inbox(
        records: [
          _record(state: ZyraJourneyRequestState.accepted, ready: true),
        ],
      );
      await controller.refresh();
      expect(controller.canonicalBindingFor(_request), isNull);
    },
  );

  test(
    'only coherent confirmed bridge exposes IDs, never a chat capability',
    () async {
      repository.reader = (_) async => _inbox(
        records: [
          _record(
            state: ZyraJourneyRequestState.bridged,
            ready: true,
            binding: _binding,
          ),
        ],
      );
      await controller.refresh();
      expect(controller.canonicalBindingFor(_request), same(_binding));
      expect(
        await controller.execute(ZyraJourneyRequestAction.cancel, _request),
        ZyraJourneyRequestResult.invalidAction,
      );
      repository.reader = (_) async =>
          _inbox(status: ZyraJourneyRequestAvailability.unavailable);
      expect(await controller.refresh(), ZyraJourneyRequestResult.unavailable);
      expect(controller.canonicalBindingFor(_request), isNull);
    },
  );

  test('disposed controller drops an in-flight response', () async {
    final scoped = ZyraJourneyRequestController(
      owner: _owner,
      ownerIsCurrent: (_) => true,
      repository: repository,
    );
    final pending = Completer<ZyraJourneyRequestInbox>();
    repository.reader = (_) => pending.future;
    final read = scoped.refresh();
    scoped.dispose();
    pending.complete(_inbox());
    expect(await read, ZyraJourneyRequestResult.staleOwner);
    expect(scoped.inbox, isNull);
  });

  test(
    'synchronous owner revocation before dispatch prevents the write',
    () async {
      await controller.refresh();
      controller.addListener(() {
        if (controller.isWriting) currentActor = _c;
      });
      expect(
        await controller.execute(ZyraJourneyRequestAction.send, _b),
        ZyraJourneyRequestResult.staleOwner,
      );
      expect(repository.commands, isEmpty);
    },
  );

  test(
    'revocation during publication cannot return a successful result',
    () async {
      controller.addListener(() => currentGeneration++);
      expect(await controller.refresh(), ZyraJourneyRequestResult.staleOwner);
      expect(controller.inbox, isNull);
    },
  );
}
