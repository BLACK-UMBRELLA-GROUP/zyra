import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

import '../main.dart' show supabase;
import 'zyra_account_state.dart';
import 'zyra_auth.dart';
import 'zyra_internal_preview_client.dart';

/// Only schema 1 of the owner-only account pause contract is understood.
/// Discovery's old is_active flag is deliberately not a fallback.
class ZyraProfilePauseState {
  const ZyraProfilePauseState._(this.ownerId, this.paused, this.revision);

  static const unavailable = ZyraProfilePauseState._(null, null, null);
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final String? ownerId;
  final bool? paused;
  final int? revision;

  bool get available => ownerId != null && paused != null && revision != null;

  static ZyraProfilePauseState fromRpc(Object? value, String ownerId) {
    if (value is! Map ||
        value.length != 4 ||
        value['schema_version'] is! int ||
        value['schema_version'] != 1 ||
        !_uuid.hasMatch(ownerId) ||
        value['owner_id'] != ownerId ||
        value['paused'] is! bool ||
        value['revision'] is! int ||
        (value['revision'] as int) < 0) {
      return unavailable;
    }
    return ZyraProfilePauseState._(
      ownerId,
      value['paused'] as bool,
      value['revision'] as int,
    );
  }
}

class _PauseSession {
  const _PauseSession(this.owner, this.token);
  final String owner;
  final String token;
}

/// One opening account lifetime. This client can use only the versioned
/// account-pause RPCs; it cannot manufacture global privacy from a local flag.
/// Missing/unavailable RPCs remain unavailable and never dispatch a mutation.
class ZyraProfilePauseService {
  ZyraProfilePauseService({
    required this.expectedUserId,
    required this.expectedGeneration,
    this.canAct,
  }) : _previewSession = ZyraInternalPreviewClient.previewSession {
    try {
      _openingToken = supabase.auth.currentSession?.accessToken;
      _authSubscription = ZyraAuth.authStateChanges.listen(
        _authChanged,
        onError: (Object _, StackTrace _) => _revoke(),
      );
    } catch (_) {
      _revoked = true;
    }
    ZyraInternalPreviewClient.changes.addListener(_previewChanged);
  }

  final String? expectedUserId;
  final int expectedGeneration;
  final bool Function()? canAct;
  final int _previewSession;
  String? _openingToken;
  StreamSubscription<AuthState>? _authSubscription;

  int _epoch = 0;
  bool _closed = false;
  bool _revoked = false;
  bool _writing = false;
  ZyraProfilePauseState _confirmed = ZyraProfilePauseState.unavailable;
  String? _confirmedToken;

  void _revoke() {
    if (_closed || _revoked) return;
    _revoked = true;
    invalidatePending();
  }

  void _previewChanged() {
    if (ZyraInternalPreviewClient.isActive ||
        ZyraInternalPreviewClient.previewSession != _previewSession) {
      _revoke();
    }
  }

  void _authChanged(AuthState state) {
    if (_closed || _revoked) return;
    if (state.session?.user.id != expectedUserId ||
        state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.signedOut ||
        state.event == AuthChangeEvent.passwordRecovery ||
        (state.event == AuthChangeEvent.initialSession &&
            state.session?.accessToken != _openingToken)) {
      _revoke();
    } else if (state.event == AuthChangeEvent.tokenRefreshed) {
      // A healthy refresh is not a new login. It invalidates the old bearer
      // and confirmation, but a fresh owner-only read may be retried.
      invalidatePending();
    }
  }

  void invalidatePending() {
    _epoch++;
    _confirmed = ZyraProfilePauseState.unavailable;
    _confirmedToken = null;
  }

  void dispose() {
    _closed = true;
    invalidatePending();
    _authSubscription?.cancel().ignore();
    ZyraInternalPreviewClient.changes.removeListener(_previewChanged);
  }

  bool get _owned {
    if (_closed || _revoked || expectedUserId == null) return false;
    try {
      if (ZyraAccountState.isSigningOut ||
          ZyraAccountState.generation != expectedGeneration ||
          ZyraAuth.currentUser?.id != expectedUserId ||
          ZyraInternalPreviewClient.isActive ||
          ZyraInternalPreviewClient.previewSession != _previewSession) {
        _revoke();
        return false;
      }
      return canAct?.call() ?? true;
    } catch (_) {
      return false;
    }
  }

  _PauseSession? _session() {
    if (!_owned) return null;
    try {
      final session = supabase.auth.currentSession;
      if (session == null ||
          session.user.id != expectedUserId ||
          !ZyraProfilePauseState._uuid.hasMatch(session.user.id) ||
          session.accessToken.isEmpty ||
          session.expiresAt == null ||
          session.isExpired) {
        return null;
      }
      return _PauseSession(session.user.id, session.accessToken);
    } catch (_) {
      return null;
    }
  }

  bool _current(_PauseSession session, int epoch) {
    if (epoch != _epoch || !_owned) return false;
    try {
      final current = supabase.auth.currentSession;
      return current != null &&
          current.user.id == session.owner &&
          current.accessToken == session.token &&
          current.accessToken.isNotEmpty &&
          current.expiresAt != null &&
          !current.isExpired;
    } catch (_) {
      return false;
    }
  }

  Future<ZyraProfilePauseState> _read(_PauseSession session, int epoch) async {
    if (!_current(session, epoch)) return ZyraProfilePauseState.unavailable;
    final raw = await supabase
        .rpc('zyra_my_profile_pause_state')
        .setHeader('Authorization', 'Bearer ${session.token}');
    if (!_current(session, epoch)) return ZyraProfilePauseState.unavailable;
    return ZyraProfilePauseState.fromRpc(raw, session.owner);
  }

  Future<ZyraProfilePauseState> load() async {
    if (_writing) return ZyraProfilePauseState.unavailable;
    invalidatePending();
    final session = _session();
    if (session == null) return ZyraProfilePauseState.unavailable;
    final epoch = _epoch;
    try {
      final state = await _read(session, epoch);
      if (!_current(session, epoch) || !state.available) {
        return ZyraProfilePauseState.unavailable;
      }
      _confirmed = state;
      _confirmedToken = session.token;
      return state;
    } catch (_) {
      return ZyraProfilePauseState.unavailable;
    }
  }

  Future<ZyraProfilePauseState> setPaused(
    bool paused, {
    required int expectedRevision,
  }) async {
    if (_writing) return ZyraProfilePauseState.unavailable;
    final session = _session();
    final before = _confirmed;
    if (session == null ||
        !before.available ||
        before.ownerId != session.owner ||
        before.revision != expectedRevision ||
        _confirmedToken != session.token) {
      return ZyraProfilePauseState.unavailable;
    }
    _writing = true;
    invalidatePending();
    final epoch = _epoch;
    try {
      if (!_current(session, epoch)) return ZyraProfilePauseState.unavailable;
      final raw = await supabase
          .rpc(
            'zyra_set_my_profile_pause',
            params: {
              'p_paused': paused,
              'p_expected_revision': expectedRevision,
            },
          )
          .setHeader('Authorization', 'Bearer ${session.token}');
      if (!_current(session, epoch)) return ZyraProfilePauseState.unavailable;
      final acknowledged = ZyraProfilePauseState.fromRpc(raw, session.owner);
      if (!acknowledged.available ||
          acknowledged.paused != paused ||
          acknowledged.revision! < expectedRevision ||
          (before.paused != paused &&
              acknowledged.revision == expectedRevision)) {
        return ZyraProfilePauseState.unavailable;
      }
      // An acknowledged write is not a confirmed privacy state. A fresh,
      // same-owner read must still confirm the requested value and revision.
      final confirmed = await _read(session, epoch);
      if (!_current(session, epoch) ||
          !confirmed.available ||
          confirmed.paused != paused ||
          confirmed.revision! < acknowledged.revision!) {
        return ZyraProfilePauseState.unavailable;
      }
      _confirmed = confirmed;
      _confirmedToken = session.token;
      return confirmed;
    } catch (_) {
      return ZyraProfilePauseState.unavailable;
    } finally {
      _writing = false;
    }
  }
}
