import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/zyra_journey_request.dart';
import 'zyra_account_state.dart';
import 'zyra_auth.dart';
import 'zyra_journey_request_repository.dart';

/// Bounded local integration preparation, not an activated real-member screen.
/// Requests never mutate AppState or optimistically create canonical Journeys.
/// Retry keys live only for this captured account lifetime; durable lost-ACK
/// recovery remains a requirement for the production transport before rollout.
final class ZyraJourneyRequestController extends ChangeNotifier {
  ZyraJourneyRequestController({
    required this.owner,
    required this.ownerIsCurrent,
    this.repository = const ZyraHeldJourneyRequestRepository(),
  });

  factory ZyraJourneyRequestController.forCurrentMember() {
    final owner = ZyraJourneyRequestOwner(
      ZyraAccountState.userId ?? '',
      ZyraAccountState.generation,
    );
    return ZyraJourneyRequestController(
      owner: owner,
      ownerIsCurrent: (captured) =>
          ZyraAccountState.isCurrent(captured.actorId, captured.generation) &&
          ZyraAuth.currentUser?.id == captured.actorId,
    );
  }

  final ZyraJourneyRequestOwner owner;
  final bool Function(ZyraJourneyRequestOwner) ownerIsCurrent;
  final ZyraJourneyRequestRepository repository;
  final Map<String, String> _retryKeys = {};
  ZyraJourneyRequestInbox? _inbox;
  ZyraJourneyRequestResult? _lastResult;
  bool _writing = false;
  bool _disposed = false;
  bool _revoked = false;
  bool _freshBindingRead = false;
  bool _mustRefresh = false;
  int _revision = 0;

  bool get _current =>
      !_disposed &&
      !_revoked &&
      zyraRequestIdentifierIsValid(owner.actorId) &&
      ownerIsCurrent(owner);

  // Never expose cached identities/receipts to a subsequent account or epoch.
  ZyraJourneyRequestInbox? get inbox => _checkOwner() ? _inbox : null;
  ZyraJourneyRequestResult? get lastResult =>
      _current ? _lastResult : ZyraJourneyRequestResult.staleOwner;
  bool get isWriting => _current && _writing;

  bool _checkOwner() {
    if (_current) return true;
    _revoked = true;
    _inbox = null;
    _freshBindingRead = false;
    _retryKeys.clear();
    return false;
  }

  ZyraJourneyRequestResult _publish(ZyraJourneyRequestResult result) {
    if (!_checkOwner()) return ZyraJourneyRequestResult.staleOwner;
    _lastResult = result;
    notifyListeners();
    return _checkOwner() ? result : ZyraJourneyRequestResult.staleOwner;
  }

  Future<ZyraJourneyRequestResult> refresh() async {
    if (!_checkOwner()) return ZyraJourneyRequestResult.staleOwner;
    if (_writing) return ZyraJourneyRequestResult.busy;
    final revision = ++_revision;
    _freshBindingRead = false;
    // Retain cached records for display, not as permission to issue a command
    // during/after an unsuccessful authoritative refresh. Retry keys survive.
    _mustRefresh = true;
    try {
      final value = await repository.read(owner);
      if (!_checkOwner()) return ZyraJourneyRequestResult.staleOwner;
      if (revision != _revision) return ZyraJourneyRequestResult.staleResponse;
      if (!value.validFor(owner.actorId)) {
        return _publish(ZyraJourneyRequestResult.invalidResponse);
      }
      if (value.availability == ZyraJourneyRequestAvailability.unavailable) {
        return _publish(ZyraJourneyRequestResult.unavailable);
      }
      _inbox = value;
      _freshBindingRead =
          value.availability == ZyraJourneyRequestAvailability.available;
      _mustRefresh = false;
      return _publish(
        value.availability == ZyraJourneyRequestAvailability.held
            ? ZyraJourneyRequestResult.held
            : ZyraJourneyRequestResult.applied,
      );
    } catch (_) {
      if (!_checkOwner()) return ZyraJourneyRequestResult.staleOwner;
      if (revision != _revision) return ZyraJourneyRequestResult.staleResponse;
      // Keep last-known data; a failed read is not an empty successful inbox.
      return _publish(ZyraJourneyRequestResult.unavailable);
    }
  }

  bool _allowed(ZyraJourneyRequestAction action, String subjectId) {
    if (!zyraRequestIdentifierIsValid(subjectId)) return false;
    if (action == ZyraJourneyRequestAction.send) {
      return subjectId != owner.actorId;
    }
    ZyraJourneyRequestRecord? record;
    for (final value in _inbox?.records ?? <ZyraJourneyRequestRecord>[]) {
      if (value.id == subjectId) record = value;
    }
    if (record == null || !record.validFor(owner.actorId)) return false;
    return switch (action) {
      ZyraJourneyRequestAction.send => false,
      ZyraJourneyRequestAction.cancel =>
        record.senderId == owner.actorId &&
            record.state == ZyraJourneyRequestState.pending,
      ZyraJourneyRequestAction.decline || ZyraJourneyRequestAction.accept =>
        record.recipientId == owner.actorId &&
            record.state == ZyraJourneyRequestState.pending,
      ZyraJourneyRequestAction.confirmReady =>
        record.state == ZyraJourneyRequestState.accepted,
    };
  }

  Future<ZyraJourneyRequestResult> execute(
    ZyraJourneyRequestAction action,
    String subjectId,
  ) async {
    if (!_checkOwner()) return ZyraJourneyRequestResult.staleOwner;
    if (_writing) return ZyraJourneyRequestResult.busy;
    if (_mustRefresh) return _publish(ZyraJourneyRequestResult.unavailable);
    if (_inbox?.availability != ZyraJourneyRequestAvailability.available) {
      return _publish(
        _inbox?.availability == ZyraJourneyRequestAvailability.held
            ? ZyraJourneyRequestResult.held
            : ZyraJourneyRequestResult.unavailable,
      );
    }
    if (!_allowed(action, subjectId)) {
      return _publish(ZyraJourneyRequestResult.invalidAction);
    }
    final intent = '${action.name}:$subjectId';
    final command = ZyraJourneyRequestCommand(
      action: action,
      subjectId: subjectId,
      operationKey: _retryKeys.putIfAbsent(intent, _operationKey),
    );
    _writing = true;
    _freshBindingRead = false;
    ++_revision; // Older reads must not overwrite a confirmed command.
    notifyListeners();
    ZyraJourneyRequestResult result;
    try {
      // A synchronous observer can revoke/dispose this owner during notify.
      // It must not dispatch a write using the next account's transport.
      if (!_checkOwner()) return ZyraJourneyRequestResult.staleOwner;
      final acknowledgement = await repository.execute(owner, command);
      if (!_checkOwner()) return ZyraJourneyRequestResult.staleOwner;
      if (!acknowledgement.matches(owner, command)) {
        result = ZyraJourneyRequestResult.invalidResponse;
      } else {
        result = switch (acknowledgement.status) {
          ZyraJourneyRequestWriteStatus.applied =>
            ZyraJourneyRequestResult.applied,
          ZyraJourneyRequestWriteStatus.refused =>
            ZyraJourneyRequestResult.refused,
          ZyraJourneyRequestWriteStatus.held => ZyraJourneyRequestResult.held,
          ZyraJourneyRequestWriteStatus.unavailable =>
            ZyraJourneyRequestResult.unavailable,
        };
        if (result == ZyraJourneyRequestResult.applied ||
            result == ZyraJourneyRequestResult.refused) {
          _retryKeys.remove(intent);
          // A second tap must not create a new operation while the visible
          // record still represents the pre-write snapshot.
          _mustRefresh = true;
        }
      }
    } catch (_) {
      if (!_checkOwner()) return ZyraJourneyRequestResult.staleOwner;
      result = ZyraJourneyRequestResult.unavailable;
    } finally {
      _writing = false;
    }
    // No local state transition. Read authoritative request/canonical binding
    // separately. A successful write cannot fabricate a Journey or readiness.
    return _publish(result);
  }

  ZyraJourneyRequestBinding? canonicalBindingFor(String requestId) {
    if (!_checkOwner() ||
        !_freshBindingRead ||
        _lastResult != ZyraJourneyRequestResult.applied ||
        _inbox?.availability != ZyraJourneyRequestAvailability.available) {
      return null;
    }
    for (final record in _inbox!.records) {
      if (record.id == requestId &&
          record.state == ZyraJourneyRequestState.bridged &&
          record.validFor(owner.actorId)) {
        return record.binding;
      }
    }
    return null;
  }

  static String _operationKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void dispose() {
    _disposed = true;
    _revoked = true;
    _revision++;
    _inbox = null;
    _retryKeys.clear();
    super.dispose();
  }
}
