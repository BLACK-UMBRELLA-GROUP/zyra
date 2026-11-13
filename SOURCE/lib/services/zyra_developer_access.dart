// Server-controlled policy for ZYRA's Founder/developer tools.
//
// The public identity (including email address and domain) is deliberately
// not authority. Supabase app_metadata can only be changed from a trusted
// server/admin context, so the role claim cannot be granted by editing a
// profile or OAuth metadata on the phone.

import 'dart:async';

import 'package:flutter/foundation.dart'
    show ChangeNotifier, Listenable, ValueNotifier, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthChangeEvent,
        AuthResponse,
        AuthState,
        Session,
        Supabase,
        User,
        decodeJwt;

import '../config/zyra_app_variant.dart';
import '../config/supabase_config.dart';
import '../config/zyra_internal_founder_policy.dart';
import '../config/zyra_external_tester_policy.dart';
import '../state/zyra_developer_samples.dart';
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

/// The ordinary Seeker panel has its own session proof. This capability
/// cannot publish legacy developer authority or start the Founder preview.
class ZyraDeveloperPanelAccess extends ChangeNotifier {
  static const _founderId = ZyraInternalFounderPolicy.approvedFounderUserId;
  static const _project = ZyraInternalFounderPolicy.approvedSupabaseUrl;
  // GoTrue 2.26 Session.isExpired treats the final 30 seconds as expired.
  static const _titleProofExpiryBuffer = Duration(seconds: 30);

  ({String sessionId, int generation})? _owner;
  bool _verified = false;
  Session? _titleRefreshProof;
  Future<AuthResponse>? _sdkRefresh;
  final _panelRefreshResults = Expando<bool>();
  Object? _lastRefreshError;
  StreamSubscription<AuthState>? _authSubscription;
  int _revision = 0;
  Future<bool>? _refresh;
  Timer? _expiry;
  bool _disposed = false;

  /// The narrow panel-only observer survives App Lock without routing anyone
  /// or publishing authority for the separate Founder preview.
  void observeWhileLocked() {
    if (_disposed || _authSubscription != null) return;
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen(
            observe,
            onError: (Object _) {
              if (_verified) suspend();
            },
          );
    } catch (_) {
      // An unconfigured app has no Auth stream. Startup retry can attach it.
    }
  }

  Future<bool>? panelRefreshEvent(Session? session) {
    if (session == null) return null;
    if (_panelRefreshResults[session] == true) return Future.value(true);
    final pending = _sdkRefresh;
    return pending?.then(
      (result) => identical(session, result.session),
      onError: (Object _) => false,
    );
  }

  Future<bool>? panelRefreshError(Object error) {
    if (identical(error, _lastRefreshError)) return Future.value(true);
    return _sdkRefresh?.then(
      (_) => false,
      onError: (Object failure) => identical(error, failure),
    );
  }

  static Session? get _currentSession {
    try {
      final client = Supabase.instance.client;
      return client.rest.url == '$_project/rest/v1'
          ? client.auth.currentSession
          : null;
    } catch (_) {
      return null;
    }
  }

  static String? _lifetime(Session? session) {
    if (session?.user.id != _founderId) return null;
    try {
      final jwt = decodeJwt(session!.accessToken).payload;
      final id = jwt.claims['session_id'];
      if (jwt.iss != '$_project/auth/v1' ||
          jwt.sub != _founderId ||
          id is! String ||
          id.isEmpty ||
          jwt.exp == null) {
        return null;
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  static bool _hasClaim(Session? session) {
    if (session?.user.appMetadata[ZyraDeveloperAccess.roleClaim] != 'founder') {
      return false;
    }
    try {
      final metadata = decodeJwt(
        session!.accessToken,
      ).payload.claims['app_metadata'];
      return metadata is Map &&
          metadata[ZyraDeveloperAccess.roleClaim] == 'founder';
    } catch (_) {
      return false;
    }
  }

  static bool _currentOwner(({String sessionId, int generation}) owner) =>
      ZyraAccountState.isCurrent(_founderId, owner.generation);

  int get proofRevision => _revision;

  Object? get verifiedLifetime => email == null ? null : _owner;

  String? get email {
    final current = _currentSession;
    final owner = _owner;
    if (!_verified ||
        _titleRefreshProof?.isExpired == true ||
        owner == null ||
        !_currentOwner(owner) ||
        _lifetime(current) != owner.sessionId ||
        !_hasClaim(current) ||
        current!.isExpired) {
      return null;
    }
    final email = current.user.email;
    return email == null || email.trim().isEmpty ? null : email;
  }

  Future<bool> verify() => _verify();

  /// A title that already passed admission can keep its sample route mounted
  /// while its current proof is valid. Opening the sheet still requires success.
  Future<bool> refreshForTitle() =>
      email == null ? Future.value(false) : _verify(keepCurrentProof: true);

  Future<bool> _verify({bool keepCurrentProof = false}) {
    observeWhileLocked();
    final active = _refresh;
    if (active != null) return active;
    // Do not allow a retired (e.g. timed out) SDK request to be adopted by
    // a new verification. GoTrue coalesces refreshes for the same token.
    if (_disposed) return Future.value(false);
    final retiring = _sdkRefresh;
    if (retiring != null) {
      final revision = _revision;
      late final Future<bool> waiting;
      Future<bool> checkAfterRetirement() {
        if (_disposed ||
            revision != _revision ||
            !identical(_refresh, waiting)) {
          return Future.value(false);
        }
        _refresh = null;
        return verify();
      }

      waiting = retiring
          .then(
            (_) => checkAfterRetirement(),
            onError: (Object _) => checkAfterRetirement(),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              if (identical(_refresh, waiting)) _refresh = null;
              return false;
            },
          );
      return _refresh = waiting;
    }
    final before = _currentSession;
    final sessionId = _lifetime(before);
    if (sessionId == null || before?.refreshToken?.isNotEmpty != true) {
      _discard();
      return Future.value(false);
    }
    final owner = (
      sessionId: sessionId,
      generation: ZyraAccountState.generation,
    );
    if (!_currentOwner(owner)) {
      _discard();
      return Future.value(false);
    }
    if (_owner != null && _owner != owner) _discard();
    if (keepCurrentProof && _owner == owner && email != null) {
      _titleRefreshProof = before;
      ++_revision;
      _watchExpiry(before!, buffer: _titleProofExpiryBuffer);
    } else {
      suspend();
    }
    final revision = _revision;
    final future = Future.microtask(() async {
      try {
        if (_disposed ||
            _revision != revision ||
            !_currentOwner(owner) ||
            _titleRefreshProof?.isExpired == true ||
            !identical(before, _currentSession)) {
          return false;
        }
        final sdkRefresh = Supabase.instance.client.auth.refreshSession(
          before!.refreshToken,
        );
        _sdkRefresh = sdkRefresh;
        unawaited(
          sdkRefresh.then(
            (result) {
              if (identical(_sdkRefresh, sdkRefresh)) {
                final session = result.session;
                if (session != null) _panelRefreshResults[session] = true;
                _lastRefreshError = null;
                _sdkRefresh = null;
              }
            },
            onError: (Object error) {
              if (identical(_sdkRefresh, sdkRefresh)) {
                _lastRefreshError = error;
                _sdkRefresh = null;
              }
            },
          ),
        );
        final result = await sdkRefresh.timeout(const Duration(seconds: 10));
        final refreshed = result.session;
        final current = _currentSession;
        if (_disposed || _revision != revision) return false;
        if (!_currentOwner(owner) ||
            _lifetime(current) != sessionId ||
            !_hasClaim(current)) {
          _discard();
          return false;
        }
        if (_titleRefreshProof?.isExpired == true ||
            !identical(refreshed, current) ||
            current!.isExpired ||
            (current.accessToken == before.accessToken &&
                current.refreshToken == before.refreshToken) ||
            current.user.email?.trim().isNotEmpty != true) {
          return false;
        }
        _owner = owner;
        _verified = true;
        _titleRefreshProof = null;
        _watchExpiry(current);
        notifyListeners();
        return true;
      } catch (_) {
        final current = _currentSession;
        if (!_disposed &&
            _revision == revision &&
            (!_currentOwner(owner) ||
                _lifetime(current) != sessionId ||
                !_hasClaim(current))) {
          _discard();
        }
        return false;
      } finally {
        if (_revision == revision && _titleRefreshProof != null) suspend();
      }
    });
    _refresh = future;
    return future.whenComplete(() {
      if (identical(_refresh, future)) _refresh = null;
    });
  }

  void observe(AuthState state) {
    if (_disposed) return;
    final owner = _owner;
    final session = state.session;
    if (state.event == AuthChangeEvent.signedOut ||
        (owner != null &&
            (!_currentOwner(owner) ||
                _lifetime(session) != owner.sessionId ||
                (state.event == AuthChangeEvent.tokenRefreshed &&
                    !_hasClaim(session))))) {
      _discard();
      return;
    }
    switch (state.event) {
      case AuthChangeEvent.tokenRefreshed:
        // A healthy rotation may keep already-verified access. An event
        // cannot grant access or revive a suspended capability.
        if (_verified) {
          if (email == null) {
            suspend();
          } else if (_titleRefreshProof == null) {
            // A title refresh extends the lease only after its response has
            // passed the explicit verification above.
            _watchExpiry(_currentSession!);
          }
        }
      case AuthChangeEvent.initialSession:
        if (_verified && email == null) suspend();
      default:
        suspend();
    }
  }

  void _watchExpiry(
    Session session, {
    Duration buffer = const Duration(seconds: 10),
  }) {
    _expiry?.cancel();
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      session.expiresAt! * 1000,
    );
    _expiry = Timer(expiry.difference(DateTime.now()) - buffer, suspend);
  }

  void suspend() {
    _revision++;
    final hadProof = _verified;
    _verified = false;
    _titleRefreshProof = null;
    _refresh = null;
    _expiry?.cancel();
    _expiry = null;
    if (hadProof && !_disposed) notifyListeners();
  }

  void _discard() {
    final owner = _owner;
    _owner = null;
    suspend();
    if (owner != null) ZyraDeveloperSamples.instance.discardLifetime(owner);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
    _discard();
    super.dispose();
  }
}
