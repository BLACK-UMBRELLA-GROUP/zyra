// Server-controlled policy for ZYRA's Founder/developer tools.
//
// The public identity (including email address and domain) is deliberately
// not authority. Supabase app_metadata can only be changed from a trusted
// server/admin context, so the role claim cannot be granted by editing a
// profile or OAuth metadata on the phone.

import 'dart:async';

import 'package:flutter/foundation.dart'
    show Listenable, ValueNotifier, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, User;

import '../config/zyra_app_variant.dart';
import '../config/supabase_config.dart';
import '../config/zyra_internal_founder_policy.dart';
import '../config/zyra_external_tester_policy.dart';
import 'zyra_internal_preview_client.dart';
import 'zyra_account_state.dart';

class ZyraAuthorizationRefreshSnapshot {
  final User? user;
  final bool founderAuthorized;

  const ZyraAuthorizationRefreshSnapshot._({
    required this.user,
    required this.founderAuthorized,
  });

  const ZyraAuthorizationRefreshSnapshot.denied()
    : this._(user: null, founderAuthorized: false);
}

class _ZyraAuthorizationFlight {
  _ZyraAuthorizationFlight({
    required this.generation,
    required this.userId,
    required this.identityKey,
    required this.refreshesSession,
  });

  final int generation;
  String? userId;
  String? identityKey;
  final bool refreshesSession;
  final Completer<ZyraAuthorizationRefreshSnapshot> completer =
      Completer<ZyraAuthorizationRefreshSnapshot>();
  _ZyraAuthorizationFlight? successor;

  Future<ZyraAuthorizationRefreshSnapshot> get future => completer.future;
}

class ZyraDeveloperAccess {
  ZyraDeveloperAccess._();

  static const String roleClaim = 'zyra_role';
  static bool _authorizedForTesting = false;
  static bool _externalTesterAuthorized = false;
  static bool? _mainAppPreviewForTesting;

  static bool get isMainAppFounderPreview =>
      _mainAppPreviewForTesting ??
      (_currentVariant == ZyraAppVariant.production &&
          ZyraInternalFounderPolicy.enabled &&
          isAuthorizedOperator);

  /// A local preview is either the authenticated Founder preview or the
  /// explicitly compiled external-tester preview. It is not a production
  /// member session and never grants server-side authority.
  static bool get isMainAppPreview =>
      isMainAppFounderPreview || _externalTesterAuthorized;

  static bool get isAuthorizedTester => _externalTesterAuthorized;

  static bool authorizeExternalTester({
    required String username,
    required String password,
  }) {
    final accepted =
        ZyraExternalTesterPolicy.enabled &&
        username.trim() == ZyraExternalTesterPolicy.username &&
        password == ZyraExternalTesterPolicy.password;
    if (_externalTesterAuthorized != accepted) {
      _externalTesterAuthorized = accepted;
      _notifyAuthorizationChanged();
    }
    return accepted;
  }

  static void clearExternalTesterAuthorization() {
    if (!_externalTesterAuthorized) return;
    _externalTesterAuthorized = false;
    _notifyAuthorizationChanged();
  }

  @visibleForTesting
  static void setMainAppFounderPreviewForTesting(bool? value) {
    assert(() {
      _mainAppPreviewForTesting = value;
      return true;
    }());
  }

  static String? _refreshedFounderUserId;
  static int _authorizationGeneration = 0;
  static _ZyraAuthorizationFlight? _activeAuthorizationFlight;
  static final ValueNotifier<int> _authorizationRevision = ValueNotifier(0);

  static ZyraAppVariant? _variantForTesting;
  static User? Function()? _currentUserForTesting;
  static Future<User?> Function()? _refreshSessionForTesting;
  static Duration _refreshTimeout = const Duration(seconds: 10);
  static bool Function(User user)? _founderIdentityMatchesForTesting;

  /// Notifies the app-wide guard whenever refreshed authority changes.
  static Listenable get authorizationChanges => _authorizationRevision;

  static void _notifyAuthorizationChanged() {
    _authorizationRevision.value += 1;
  }

  @visibleForTesting
  static void setAuthorizedForTesting(bool value) {
    assert(() {
      if (_authorizedForTesting != value) {
        _authorizedForTesting = value;
        _notifyAuthorizationChanged();
      }
      return true;
    }());
  }

  static void clearRefreshedClaims() {
    _authorizationGeneration += 1;
    _activeAuthorizationFlight = null;
    _replaceRefreshedProof(founderId: null);
  }

  static void _replaceRefreshedProof({required String? founderId}) {
    if (_refreshedFounderUserId == founderId) return;
    _refreshedFounderUserId = founderId;
    _notifyAuthorizationChanged();
  }

  /// Accepts a user returned by an explicit `tokenRefreshed` Auth event.
  ///
  /// Only the exact main Founder proof may publish after this fresh event.
  static Future<ZyraAuthorizationRefreshSnapshot> acceptFreshTokenRefresh(
    User user,
  ) {
    final active = _activeAuthorizationFlight;
    final identityKey = _authorizationIdentityKey(user);
    if (active != null &&
        active.userId == user.id &&
        active.identityKey == identityKey &&
        (active.refreshesSession || !active.completer.isCompleted)) {
      return active.future;
    }
    return _startAuthorizationFlight(
      userId: user.id,
      identityKey: identityKey,
      refreshesSession: false,
      run: (flight) => _authorizeFreshUserWithinFlight(flight, user),
    );
  }

  static Future<ZyraAuthorizationRefreshSnapshot>
  _authorizeFreshUserWithinFlight(
    _ZyraAuthorizationFlight flight,
    User user,
  ) async {
    if (!_isFlightCurrent(flight, user)) {
      return _successorOrDenied(flight);
    }

    final variant = _currentVariant;
    final founderClaim = _founderIdentityMatches(user, variant);
    if (founderClaim) {
      if (!_isFlightCurrent(flight, user)) {
        return _successorOrDenied(flight);
      }
      if (variant == ZyraAppVariant.production &&
          ZyraInternalFounderPolicy.enabled) {
        ZyraInternalPreviewClient.beginPreview();
      }
      _replaceRefreshedProof(founderId: user.id);
      return ZyraAuthorizationRefreshSnapshot._(
        user: user,
        founderAuthorized: true,
      );
    }

    _replaceRefreshedProof(founderId: null);
    return ZyraAuthorizationRefreshSnapshot._(
      user: user,
      founderAuthorized: false,
    );
  }

  static bool _isFlightCurrent(_ZyraAuthorizationFlight flight, User user) {
    if (ZyraAccountState.isSigningOut ||
        _authorizationGeneration != flight.generation ||
        !identical(_activeAuthorizationFlight, flight)) {
      return false;
    }
    return _currentUserOrNull?.id == user.id;
  }

  static Future<ZyraAuthorizationRefreshSnapshot> _successorOrDenied(
    _ZyraAuthorizationFlight flight,
  ) async {
    final successor = flight.successor;
    return successor == null
        ? const ZyraAuthorizationRefreshSnapshot.denied()
        : successor.future;
  }

  static Future<ZyraAuthorizationRefreshSnapshot> _startAuthorizationFlight({
    required String? userId,
    required String? identityKey,
    required bool refreshesSession,
    required Future<ZyraAuthorizationRefreshSnapshot> Function(
      _ZyraAuthorizationFlight flight,
    )
    run,
  }) {
    final prior = _activeAuthorizationFlight;
    final flight = _ZyraAuthorizationFlight(
      generation: ++_authorizationGeneration,
      userId: userId,
      identityKey: identityKey,
      refreshesSession: refreshesSession,
    );
    if (prior != null && !prior.completer.isCompleted) {
      prior.successor = flight;
    }
    _activeAuthorizationFlight = flight;
    _replaceRefreshedProof(founderId: null);

    // Defer user-supplied/Auth work until the flight future is published. A
    // tokenRefreshed event may be delivered re-entrantly by refreshSession;
    // it must be able to join this exact future rather than start another RPC.
    scheduleMicrotask(() async {
      ZyraAuthorizationRefreshSnapshot result;
      try {
        result = await run(flight);
      } catch (_) {
        result = await _successorOrDenied(flight);
      }
      if (!flight.completer.isCompleted) flight.completer.complete(result);
      if (identical(_activeAuthorizationFlight, flight)) {
        _activeAuthorizationFlight = null;
      }
    });
    return flight.future;
  }

  /// Refreshes Auth before retaining Founder capability. Any missing client,
  /// network failure, removed claim or identity mismatch clears the proof.
  static Future<ZyraAuthorizationRefreshSnapshot>
  refreshCurrentAuthorizationSnapshot() async {
    final currentUser = _currentUserOrNull;
    final currentUserId = currentUser?.id;
    final identityKey = _authorizationIdentityKey(currentUser);
    final active = _activeAuthorizationFlight;
    if (active != null &&
        active.userId == currentUserId &&
        active.identityKey == identityKey) {
      return active.future;
    }
    return _startSessionRefresh(
      userId: currentUserId,
      identityKey: identityKey,
    );
  }

  /// `userUpdated` is not evidence of a new access token. It must invalidate
  /// current proof and force a real session refresh; concurrent callers follow
  /// this replacement flight rather than publishing stale results.
  static Future<ZyraAuthorizationRefreshSnapshot>
  refreshAuthorizationAfterUserUpdated() {
    final currentUser = _currentUserOrNull;
    return _startSessionRefresh(
      userId: currentUser?.id,
      identityKey: _authorizationIdentityKey(currentUser),
    );
  }

  static Future<ZyraAuthorizationRefreshSnapshot> _startSessionRefresh({
    required String? userId,
    required String? identityKey,
  }) => _startAuthorizationFlight(
    userId: userId,
    identityKey: identityKey,
    refreshesSession: true,
    run: (_ZyraAuthorizationFlight flight) async {
      try {
        final user = await _refreshSessionUser().timeout(_refreshTimeout);
        if (user == null) return _successorOrDenied(flight);
        if (!identical(_activeAuthorizationFlight, flight)) {
          return _successorOrDenied(flight);
        }
        flight.userId = user.id;
        flight.identityKey = _authorizationIdentityKey(user);
        return _authorizeFreshUserWithinFlight(flight, user);
      } catch (_) {
        // Fail closed. The app-wide owner removes the controls and routes away
        // from guarded destinations when a previously authorized session loses
        // proof; normal member routing handles its own connection UI.
      }
      return _successorOrDenied(flight);
    },
  );

  static Future<bool> refreshCurrentAuthorization() async {
    await refreshCurrentAuthorizationSnapshot();
    return canUseDeveloperTools;
  }

  /// Default/public builds deny. The internal main-app opt-in requires the
  /// exact Founder user ID returned by a fresh session.
  static bool get isAuthorizedOperator {
    if (ZyraAccountState.isSigningOut) return false;
    if (_externalTesterAuthorized) return true;
    if (_authorizedForTesting) return true;
    // Widget tests intentionally run without a Supabase singleton. Deny by
    // default rather than allowing an uninitialised auth client to crash a
    // normal screen that merely checks whether dev controls should exist.
    final user = _currentUserOrNull;
    return user != null &&
        user.id == _refreshedFounderUserId &&
        _founderIdentityMatches(user, _currentVariant);
  }

  static bool get canUseDeveloperTools => isAuthorizedOperator;

  /// Denial only: this does not confer Founder capability from a cached ID.
  static bool get blocksMemberRouting =>
      ZyraInternalPreviewClient.isActive ||
      (_currentUserOrNull?.id ==
              ZyraInternalFounderPolicy.approvedFounderUserId &&
          (_mainAppPreviewForTesting ?? ZyraInternalFounderPolicy.enabled));

  /// A caller asking for a preview never creates authority by itself.
  static bool allowsDevPreview(bool requested) =>
      requested && canUseDeveloperTools;

  static ZyraAppVariant get _currentVariant =>
      _variantForTesting ?? ZyraAppVariantPolicy.current;

  static bool _founderIdentityMatches(User user, ZyraAppVariant variant) {
    final override = _founderIdentityMatchesForTesting;
    if (override != null) return override(user);
    return ZyraInternalFounderPolicy.allows(
      variant: variant,
      internalBuildEnabled: ZyraInternalFounderPolicy.enabled,
      suppliedFounderUserId: ZyraInternalFounderPolicy.compiledFounderUserId,
      supabaseUrl: SupabaseConfig.url,
      userId: user.id,
      appMetadata: user.appMetadata,
      claimsAreFresh: true,
    );
  }

  static Future<User?> _refreshSessionUser() async {
    final override = _refreshSessionForTesting;
    if (override != null) return override();
    return (await Supabase.instance.client.auth.refreshSession()).user;
  }

  static String? _authorizationIdentityKey(User? user) {
    if (user == null) return null;
    String claim(Object? value) => value is String
        ? 'string:$value'
        : value == null
        ? 'null'
        : 'invalid:${value.runtimeType}';
    return [
      user.id,
      user.email ?? '',
      claim(user.appMetadata[roleClaim]),
    ].join('\u0000');
  }

  @visibleForTesting
  static void configureAuthorizationForTesting({
    required ZyraAppVariant variant,
    required User? Function() currentUser,
    required Future<User?> Function() refreshSession,
    required bool Function(User user) founderIdentityMatches,
    Duration refreshTimeout = const Duration(seconds: 10),
  }) {
    assert(() {
      clearRefreshedClaims();
      _variantForTesting = variant;
      _currentUserForTesting = currentUser;
      _refreshSessionForTesting = refreshSession;
      _founderIdentityMatchesForTesting = founderIdentityMatches;
      _refreshTimeout = refreshTimeout;
      return true;
    }());
  }

  @visibleForTesting
  static void resetAuthorizationForTesting() {
    assert(() {
      clearRefreshedClaims();
      _variantForTesting = null;
      _mainAppPreviewForTesting = null;
      _currentUserForTesting = null;
      _refreshSessionForTesting = null;
      _founderIdentityMatchesForTesting = null;
      _refreshTimeout = const Duration(seconds: 10);
      return true;
    }());
  }

  static User? get _currentUserOrNull {
    final override = _currentUserForTesting;
    if (override != null) return override();
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }
}
