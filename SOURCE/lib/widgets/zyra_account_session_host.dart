// Retained account-session safety from the former app-wide overlay owner.
// This host owns session refresh and outgoing account route cleanup only.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, User;

import '../config/zyra_app_variant.dart';
import '../config/zyra_internal_founder_policy.dart';
import '../dev/zyra_preview_resume_transition.dart';
import '../screens/auth_gate.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_internal_preview_client.dart';
import '../services/zyra_local_prefs.dart';
import '../theme/zyra_colors.dart';
import 'zyra_developer_title.dart';

typedef _RefreshPresentation = ({
  ZyraPreviewResumeHandoff? handoff,
  bool mayRedirect,
  bool Function() current,
});

/// Keeps only the panel's proof and auth observer above App Lock. The
/// member Navigator and the legacy preview routing host still unmount.
class ZyraDeveloperPanelSession extends StatefulWidget {
  const ZyraDeveloperPanelSession({super.key, required this.child});

  final Widget child;

  @override
  State<ZyraDeveloperPanelSession> createState() =>
      _ZyraDeveloperPanelSessionState();
}

class _ZyraDeveloperPanelSessionState extends State<ZyraDeveloperPanelSession> {
  final _access = ZyraDeveloperPanelAccess();

  @override
  Widget build(BuildContext context) {
    _access.observeWhileLocked();
    return _DeveloperPanelSessionScope(access: _access, child: widget.child);
  }

  @override
  void dispose() {
    _access.dispose();
    super.dispose();
  }
}

class _DeveloperPanelSessionScope extends InheritedWidget {
  const _DeveloperPanelSessionScope({
    required this.access,
    required super.child,
  });

  final ZyraDeveloperPanelAccess access;

  @override
  bool updateShouldNotify(_DeveloperPanelSessionScope oldWidget) =>
      !identical(access, oldWidget.access);
}

/// Clears the outgoing member's presentation before a different account can
/// reuse its Navigator, and retains the existing refreshed-claim safeguards.
class ZyraAccountSessionHost extends StatefulWidget {
  const ZyraAccountSessionHost({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.authStateChangesOverride,
    this.authorizationReaderOverride,
    this.authorityLossDestinationBuilder,
    this.resumeAuthorizationRefreshOverride,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @visibleForTesting
  final Stream<AuthState>? authStateChangesOverride;

  @visibleForTesting
  final bool Function()? authorizationReaderOverride;

  @visibleForTesting
  final WidgetBuilder? authorityLossDestinationBuilder;

  @visibleForTesting
  final Future<bool> Function()? resumeAuthorizationRefreshOverride;

  @override
  State<ZyraAccountSessionHost> createState() => _ZyraAccountSessionHostState();
}

class _ZyraAccountSessionHostState extends State<ZyraAccountSessionHost>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  ZyraDeveloperPanelAccess? _ownedPanelAccess;
  late ZyraDeveloperPanelAccess _panelAccess;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context
        .dependOnInheritedWidgetOfExactType<_DeveloperPanelSessionScope>();
    _panelAccess =
        scope?.access ?? (_ownedPanelAccess ??= ZyraDeveloperPanelAccess());
    _panelAccess.observeWhileLocked();
  }

  int _authEventRevision = 0;
  bool _refreshingAuthorization = false;
  ZyraPreviewResumeHandoff? _resumePresentation;
  bool _accountTransition = false;
  int? _accountTransitionGeneration;
  late bool _lastAllowed;

  bool get _isAllowed =>
      !_accountTransition &&
      (widget.authorizationReaderOverride?.call() ??
          ZyraDeveloperAccess.canUseDeveloperTools);

  @override
  void initState() {
    super.initState();
    _lastAllowed = _isAllowed;
    WidgetsBinding.instance.addObserver(this);
    ZyraDeveloperAccess.authorizationChanges.addListener(
      _onAuthorizationChanged,
    );
  }

  void _ensureAuthSubscription() {
    if (!mounted || _authSubscription != null) return;
    try {
      _authSubscription =
          (widget.authStateChangesOverride ?? ZyraAuth.authStateChanges).listen(
            _onAuthState,
            onError: _onAuthStateError,
          );
    } catch (_) {
      // Supabase is intentionally absent for a locked/unconfigured build.
      // A later startup retry rebuilds this host and tries again.
    }
  }

  void _onAuthStateError(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    final revision = ++_authEventRevision;
    if (widget.authStateChangesOverride != null) _panelAccess.suspend();
    final panelError = _panelAccess.panelRefreshError(error);
    if (panelError == null) {
      _revokeAfterAuthError();
    } else {
      unawaited(
        panelError.then((isPanelError) {
          if (mounted && revision == _authEventRevision && !isPanelError) {
            _revokeAfterAuthError();
          }
        }),
      );
    }
  }

  void _revokeAfterAuthError() {
    // A pending check may already have retracted _lastAllowed. Preserve the
    // prior page's denial provenance before revoking its presentation lease.
    final presentation = _beginRefreshPresentation(
      _lastAllowed,
      beginHandoff: false,
    );
    _cancelResumePresentation();
    ZyraDeveloperAccess.clearRefreshedClaims();
    _syncAuthorization(
      redirectIfLost: presentation.mayRedirect && !_isAllowed,
      redirectCurrent: presentation.current,
    );
    debugPrint(
      'ZYRA Developer Access authorization cleared after an auth stream '
      'failure.',
    );
  }

  void _onAuthState(AuthState state) {
    if (!mounted) return;
    _authEventRevision++;
    // Supabase has already replaced currentUser by the time this callback is
    // delivered. Preserve the capability observed before the event; reading
    // currentUser here would make a removed claim look as though it was never
    // authorized and would skip the guarded-route redirect.
    final wasAllowed = _lastAllowed;
    final userUpdatePresentation = state.event == AuthChangeEvent.userUpdated
        ? _beginRefreshPresentation(wasAllowed, beginHandoff: false)
        : null;
    // Account reset begins synchronously, before any refreshed capability can
    // be published. Do not await disk cleanup inside the Auth event: an
    // explicit refresh can be waiting for this same event to finish.
    final userId = widget.authStateChangesOverride != null
        ? state.session?.user.id
        : ZyraAuth.currentUser?.id;
    final previousUserId = ZyraAccountState.userId;
    if (previousUserId != userId ||
        state.event == AuthChangeEvent.signedOut ||
        state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.passwordRecovery ||
        state.event == AuthChangeEvent.mfaChallengeVerified ||
        state.event == AuthChangeEvent.userUpdated) {
      _cancelResumePresentation();
    }
    final cleanup = ZyraAccountState.synchronize(userId);
    if (widget.authStateChangesOverride != null) _panelAccess.observe(state);
    if ((_accountTransition ||
            (previousUserId != null && previousUserId != userId)) &&
        _accountTransitionGeneration != ZyraAccountState.generation) {
      // Screen-local form/profile state is not cleared by resetting AppState.
      // Hide the outgoing tree and replace its whole stack for a new owner.
      final generation = ZyraAccountState.generation;
      setState(() {
        _accountTransition = true;
        _accountTransitionGeneration = generation;
      });
      unawaited(_replaceAccountRoutes(cleanup, generation));
    }
    unawaited(
      cleanup.catchError((Object error) {
        if (!mounted) return;
        ZyraDeveloperAccess.clearRefreshedClaims();
        _syncAuthorization(redirectIfLost: wasAllowed);
        debugPrint('ZYRA account-local cleanup could not be confirmed.');
      }),
    );
    if (state.event == AuthChangeEvent.tokenRefreshed) {
      final user = state.session?.user;
      if (user != null) {
        // A persona's protected claim is not sufficient. Keep the overlay
        // absent while its caller-scoped synthetic IDV fixture is checked. If
        // refreshSession emitted this event, this joins that exact flight.
        final panelEvent = _panelAccess.panelRefreshEvent(state.session);
        if (panelEvent == null) {
          unawaited(_acceptFreshTokenEvent(user, wasAllowed: wasAllowed));
        } else {
          unawaited(_handlePossiblePanelEvent(panelEvent, user, wasAllowed));
        }
        return;
      }
      ZyraDeveloperAccess.clearRefreshedClaims();
      _syncAuthorization(redirectIfLost: wasAllowed && !_isAllowed);
      return;
    }

    if (state.event == AuthChangeEvent.userUpdated) {
      // userUpdated can carry a changed User object without proving that the
      // access token was refreshed. Never publish protected claims from it.
      // The replacement flight clears proof synchronously, then performs (or
      // supersedes with) an actual refresh before capability can return.
      unawaited(
        _refreshAfterUserUpdated(presentation: userUpdatePresentation!),
      );
      return;
    }

    if (state.session != null &&
        (state.event == AuthChangeEvent.initialSession ||
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.passwordRecovery ||
            state.event == AuthChangeEvent.mfaChallengeVerified)) {
      // Initial-session replay can arrive after AuthGate has started its
      // refresh. Join that flight instead of discarding its pending result.
      // These events never prove claims: a real refresh is still required.
      unawaited(_refreshAfterSessionEvent(wasAllowed: wasAllowed));
      return;
    }

    // Sign-in, initial-session and recovery events are not the explicit
    // refresh required by the route policy. Clearing here also prevents one
    // principal's proof surviving a direct same-process account change.
    ZyraDeveloperAccess.clearRefreshedClaims();
    _syncAuthorization(redirectIfLost: wasAllowed && !_isAllowed);
  }

  Future<void> _replaceAccountRoutes(
    Future<void> cleanup,
    int generation,
  ) async {
    await cleanup;
    if (!mounted || ZyraAccountState.generation != generation) return;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!mounted || ZyraAccountState.generation != generation) return;
      widget.navigatorKey.currentState?.pushAndRemoveUntil(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, _, _) =>
              widget.authorityLossDestinationBuilder?.call(context) ??
              const AuthGate(playSplash: false),
        ),
        (_) => false,
      );
      setState(() {
        _accountTransition = false;
        _accountTransitionGeneration = null;
      });
    });
    binding.scheduleFrame();
  }

  Future<void> _refreshAfterSessionEvent({required bool wasAllowed}) async {
    final authorization =
        ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
    _syncAuthorization(redirectIfLost: wasAllowed && !_isAllowed);
    await authorization;
    if (!mounted) return;
    _syncAuthorization(redirectIfLost: wasAllowed && !_isAllowed);
  }

  Future<void> _handlePossiblePanelEvent(
    Future<bool> panelEvent,
    User user,
    bool wasAllowed,
  ) async {
    final generation = ZyraAccountState.generation;
    final revision = _authEventRevision;
    if (await panelEvent) return;
    if (!mounted ||
        generation != ZyraAccountState.generation ||
        revision != _authEventRevision) {
      return;
    }
    await _acceptFreshTokenEvent(user, wasAllowed: wasAllowed);
  }

  Future<void> _acceptFreshTokenEvent(
    User user, {
    required bool wasAllowed,
  }) async {
    final presentation = _beginRefreshPresentation(wasAllowed);
    try {
      final authorization = ZyraDeveloperAccess.acceptFreshTokenRefresh(user);
      // Routine same-owner token work retracts controls immediately, but its
      // pending state is not a denial. The final verdict still fails closed.
      _syncAuthorization();
      await authorization;
    } finally {
      ZyraPreviewResumeTransition.release(presentation.handoff);
    }
    if (!presentation.current()) return;
    _syncAuthorization(
      redirectIfLost: presentation.mayRedirect && !_isAllowed,
      redirectCurrent: presentation.current,
    );
  }

  _RefreshPresentation _beginRefreshPresentation(
    bool wasAllowed, {
    bool beginHandoff = true,
  }) {
    final owner = ZyraAccountState.userId;
    final generation = ZyraAccountState.generation;
    final preferences = ZyraLocalPrefs.bindingGeneration;
    final previewSession = ZyraInternalPreviewClient.previewSession;
    bool current() =>
        mounted &&
        !_accountTransition &&
        !ZyraAccountState.isSigningOut &&
        ZyraAccountState.userId == owner &&
        ZyraAccountState.generation == generation &&
        ZyraInternalPreviewClient.previewSession == previewSession &&
        ZyraLocalPrefs.bindingGeneration == preferences;
    final admission = owner == null
        ? null
        : ZyraPreviewResumeTransition.admissionFor(
            ownerId: owner,
            accountGeneration: generation,
            preferenceGeneration: preferences,
          );
    // This provenance selects an inert presentation and eventual denial only.
    // It cannot keep authority, controls, old actions or network access alive.
    final mayRedirect = wasAllowed || admission != null;
    final handoff = beginHandoff && mayRedirect && owner != null && current()
        ? ZyraPreviewResumeTransition.acquire(
            ownerId: owner,
            accountGeneration: generation,
            preferenceGeneration: preferences,
            presentationOwner: admission?.presentationOwner,
          )
        : null;
    return (handoff: handoff, mayRedirect: mayRedirect, current: current);
  }

  Future<void> _refreshAfterUserUpdated({
    required _RefreshPresentation presentation,
  }) async {
    final authorization =
        ZyraDeveloperAccess.refreshAuthorizationAfterUserUpdated();
    _syncAuthorization(
      redirectIfLost: presentation.mayRedirect && !_isAllowed,
      redirectCurrent: presentation.current,
    );
    await authorization;
    if (!presentation.current()) return;
    _syncAuthorization(
      redirectIfLost: presentation.mayRedirect && !_isAllowed,
      redirectCurrent: presentation.current,
    );
  }

  void _onAuthorizationChanged() => _syncAuthorization();

  void _syncAuthorization({
    bool redirectIfLost = false,
    bool Function()? redirectCurrent,
  }) {
    if (!mounted) return;
    final allowed = _isAllowed;
    _lastAllowed = allowed;
    if (!allowed && redirectIfLost) {
      _cancelResumePresentation();
      _redirectAfterAuthorityLoss(current: redirectCurrent);
    }
    _ensureAuthSubscription();
  }

  void _redirectAfterAuthorityLoss({bool Function()? current}) {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!mounted || _isAllowed || (current != null && !current())) return;
      widget.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              widget.authorityLossDestinationBuilder ??
              (_) => const AuthGate(playSplash: false),
        ),
        (_) => false,
      );
    });
    // Async refresh completion can happen after the current frame's callback
    // phase. Request the frame explicitly so a revoked guarded route never
    // waits for unrelated UI activity before it is removed.
    binding.scheduleFrame();
  }

  Future<void> _refreshAuthorizationOnResume() async {
    final refreshOverride = widget.resumeAuthorizationRefreshOverride;
    if (_refreshingAuthorization ||
        (refreshOverride == null &&
            (ZyraAppVariantPolicy.current != ZyraAppVariant.production ||
                !ZyraInternalFounderPolicy.enabled))) {
      return;
    }
    if (refreshOverride == null) {
      var signedIn = false;
      try {
        signedIn = ZyraAuth.isSignedIn;
      } catch (_) {
        return;
      }
      if (!signedIn) return;
    }

    _refreshingAuthorization = true;
    final wasAllowed = _lastAllowed;
    // A prior ready Founder presentation can join a check that already
    // withdrew proof while paused. It is not a cached authorization grant.
    final presentation = _beginRefreshPresentation(wasAllowed);
    _resumePresentation = presentation.handoff;
    var refreshed = false;
    try {
      final authorization =
          refreshOverride?.call() ??
          ZyraDeveloperAccess.refreshCurrentAuthorization();
      // Starting a protected refresh invalidates the old proof immediately.
      // Retract the controls while it is in flight, but preserve the route:
      // iOS permission/share sheets generate a resume event and must not turn
      // that temporary fail-closed state into a Home-stack replacement.
      _syncAuthorization();
      refreshed = await authorization;
    } catch (error) {
      debugPrint('ZYRA Developer Access resume refresh failed — $error');
    } finally {
      _refreshingAuthorization = false;
      ZyraPreviewResumeTransition.release(presentation.handoff);
      if (identical(_resumePresentation, presentation.handoff)) {
        _resumePresentation = null;
      }
    }
    if (!presentation.current()) return;
    _syncAuthorization(
      redirectIfLost: presentation.mayRedirect && (!refreshed || !_isAllowed),
      redirectCurrent: presentation.current,
    );
  }

  void _cancelResumePresentation() {
    ZyraPreviewResumeTransition.cancel();
    _resumePresentation = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAuthorizationOnResume());
    }
  }

  @override
  void didUpdateWidget(covariant ZyraAccountSessionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureAuthSubscription();
  }

  @override
  void dispose() {
    _cancelResumePresentation();
    WidgetsBinding.instance.removeObserver(this);
    ZyraDeveloperAccess.authorizationChanges.removeListener(
      _onAuthorizationChanged,
    );
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
    _ownedPanelAccess?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureAuthSubscription();
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: _accountTransition,
          child: ZyraDeveloperPanelHost(
            access: _panelAccess,
            child: widget.child,
          ),
        ),
        if (_accountTransition) ColoredBox(color: ZyraColors.modalSheetSurface),
      ],
    );
  }
}
