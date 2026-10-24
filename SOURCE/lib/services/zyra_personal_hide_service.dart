import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Session;

import '../main.dart' show supabase;
import 'zyra_account_state.dart';
import 'zyra_internal_preview_client.dart';

/// Caller-owned discovery preferences, deliberately separate from safety Block.
///
/// The RPC contract is prepared, not deployed by this client change. A missing
/// endpoint, unknown response or changed session is unavailable, never a local
/// success or a fallback to profile_blocks. No entitlement or preview authority
/// is created here.
abstract final class ZyraPersonalHideService {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isProfileId(String value) => _uuid.hasMatch(value);

  /// Null means unavailable. Only an exact acknowledged empty list is empty.
  static Future<List<String>?> hiddenIdsOrNull() async {
    final request = _PersonalHideRequest.capture();
    if (request == null) return null;
    try {
      if (!request.current) return null;
      final raw = await supabase
          .rpc('zyra_my_hidden_profile_ids')
          .setHeader('Authorization', 'Bearer ${request.session.accessToken}');
      if (!request.current ||
          raw is! Map ||
          !_exactKeys(raw, const {
            'schema_version',
            'viewer_id',
            'profile_ids',
          }) ||
          raw['schema_version'] is! int ||
          raw['schema_version'] != 1 ||
          raw['viewer_id'] != request.owner ||
          raw['profile_ids'] is! List) {
        return null;
      }
      final ids = <String>[];
      final seen = <String>{};
      for (final value in raw['profile_ids'] as List) {
        if (value is! String || !isProfileId(value)) return null;
        final id = value.toLowerCase();
        if (id == request.owner.toLowerCase() || !seen.add(id)) return null;
        ids.add(id);
      }
      return request.current ? List<String>.unmodifiable(ids) : null;
    } catch (_) {
      return null;
    } finally {
      request.close();
    }
  }

  static Future<bool> hide(String profileId) =>
      setHidden(profileId, hidden: true);

  static Future<bool> unhide(String profileId) =>
      setHidden(profileId, hidden: false);

  static Future<bool> setHidden(
    String profileId, {
    required bool hidden,
  }) async {
    if (!isProfileId(profileId)) return false;
    final request = _PersonalHideRequest.capture();
    if (request == null) return false;
    final target = profileId.toLowerCase();
    try {
      if (!request.current || target == request.owner.toLowerCase()) {
        return false;
      }
      final raw = await supabase
          .rpc(
            'zyra_set_profile_hidden',
            params: {'p_other': target, 'p_hidden': hidden},
          )
          .setHeader('Authorization', 'Bearer ${request.session.accessToken}');
      return request.current &&
          raw is Map &&
          _exactKeys(raw, const {
            'schema_version',
            'viewer_id',
            'profile_id',
            'hidden',
          }) &&
          raw['schema_version'] is int &&
          raw['schema_version'] == 1 &&
          raw['viewer_id'] == request.owner &&
          raw['profile_id'] == target &&
          raw['hidden'] is bool &&
          raw['hidden'] == hidden;
    } catch (_) {
      return false;
    } finally {
      request.close();
    }
  }

  static bool _exactKeys(Map value, Set<String> keys) =>
      value.length == keys.length && value.keys.every(keys.contains);
}

/// One request is bound to the opening SDK bearer and signed-in lifetime.
/// A healthy refresh may require a retry; it cannot lend a new bearer to an
/// older write or turn an ambiguous acknowledgement into success.
class _PersonalHideRequest {
  _PersonalHideRequest(this.session)
    : owner = session.user.id,
      generation = ZyraAccountState.generation,
      previewSession = ZyraInternalPreviewClient.previewSession {
    _subscription = supabase.auth.onAuthStateChange.listen((state) {
      if (state.session?.user.id != owner ||
          state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.signedOut ||
          state.event == AuthChangeEvent.passwordRecovery ||
          (state.event == AuthChangeEvent.initialSession &&
              state.session?.accessToken != session.accessToken)) {
        _revoked = true;
      }
    }, onError: (Object _, StackTrace _) => _revoked = true);
  }

  final Session session;
  final String owner;
  final int generation;
  final int previewSession;
  StreamSubscription<AuthState>? _subscription;
  bool _revoked = false;

  static _PersonalHideRequest? capture() {
    try {
      if (ZyraAccountState.isSigningOut || ZyraInternalPreviewClient.isActive) {
        return null;
      }
      final session = supabase.auth.currentSession;
      if (session == null ||
          session.user.id != supabase.auth.currentUser?.id ||
          !ZyraPersonalHideService.isProfileId(session.user.id) ||
          session.accessToken.isEmpty ||
          session.expiresAt == null ||
          session.isExpired) {
        return null;
      }
      return _PersonalHideRequest(session);
    } catch (_) {
      return null;
    }
  }

  bool get current {
    if (_revoked) return false;
    try {
      final latest = supabase.auth.currentSession;
      final allowed =
          !ZyraAccountState.isSigningOut &&
          generation == ZyraAccountState.generation &&
          !ZyraInternalPreviewClient.isActive &&
          previewSession == ZyraInternalPreviewClient.previewSession &&
          latest != null &&
          latest.user.id == owner &&
          supabase.auth.currentUser?.id == owner &&
          latest.accessToken == session.accessToken &&
          latest.expiresAt != null &&
          !latest.isExpired;
      if (!allowed) _revoked = true;
      return allowed;
    } catch (_) {
      _revoked = true;
      return false;
    }
  }

  void close() {
    _revoked = true;
    _subscription?.cancel().ignore();
  }
}
