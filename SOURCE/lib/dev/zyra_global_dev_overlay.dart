// App-wide developer overlay.
//
// The former controls lived inside HomeShell/WaliHomeShell, so every pushed
// route — Settings, Journey, Developer Access and onboarding — painted above
// them and hid the controls. This owner sits in MaterialApp.builder instead.
// The active shell still supplies its real tab callback; entry/signup keeps
// its own truthful controls rather than borrowing a member scenario.

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, User;

import '../config/zyra_app_variant.dart';
import '../config/zyra_internal_founder_policy.dart';
import '../screens/auth_gate.dart';
import '../screens/dev/developer_access_screen.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_auth.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_internal_preview_client.dart';
import '../services/zyra_local_prefs.dart';
import '../services/zyra_promotion_engine.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'dev_onboarding_directions.dart';
import 'dev_role_choice_design.dart';
import 'dev_scenario_panel_v2.dart';
import 'wali_dev_scenario_panel.dart';
import 'zyra_concept_preview_boundary.dart';
import 'zyra_dev_control_system.dart';
import 'zyra_dev_hold_to_open.dart';
import 'zyra_dev_page_options.dart';
import 'zyra_dev_scenario.dart';
import 'zyra_dev_surface_coordinator.dart';
import 'zyra_dev_signup.dart';
import 'zyra_dev_home.dart';
import 'zyra_dev_tool_section.dart';
import 'zyra_page_preview_screen.dart';
import 'zyra_preview_resume_transition.dart';

typedef _RefreshPresentation = ({
  ZyraPreviewResumeHandoff? handoff,
  bool mayRedirect,
  bool Function() current,
});

/// Installs the developer controls into the app Navigator's own Overlay.
/// MaterialApp.builder sits above Navigator, so drawing controls there as a
/// sibling would break Tooltip/Navigator lookups. An OverlayEntry is both
/// app-wide and still a real descendant of Navigator.
class ZyraGlobalDevOverlayHost extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final ZyraDevControlsRouteObserver? routeObserver;

  @visibleForTesting
  final Stream<AuthState>? authStateChangesOverride;

  @visibleForTesting
  final bool Function()? authorizationReaderOverride;

  @visibleForTesting
  final WidgetBuilder? authorityLossDestinationBuilder;

  /// Replaces the resume-time Founder authorization refresh in lifecycle
  /// regression tests. Production always uses the protected service.
  @visibleForTesting
  final Future<bool> Function()? resumeAuthorizationRefreshOverride;

  const ZyraGlobalDevOverlayHost({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.routeObserver,
    this.authStateChangesOverride,
    this.authorizationReaderOverride,
    this.authorityLossDestinationBuilder,
    this.resumeAuthorizationRefreshOverride,
  });

  @override
  State<ZyraGlobalDevOverlayHost> createState() =>
      _ZyraGlobalDevOverlayHostState();
}

class _ZyraGlobalDevOverlayHostState extends State<ZyraGlobalDevOverlayHost>
    with WidgetsBindingObserver {
  OverlayEntry? _entry;
  final ValueNotifier<int> _openRequests = ValueNotifier<int>(0);
  late _DeferredDevHoldUpdates _holdUpdates;
  StreamSubscription<AuthState>? _authSubscription;
  bool _syncScheduled = false;
  bool _refreshingAuthorization = false;
  ZyraPreviewResumeHandoff? _resumePresentation;
  bool _accountTransition = false;
  bool _appForeground = true;
  int? _accountTransitionGeneration;
  late bool _lastAllowed;

  bool get _isAllowed =>
      !_accountTransition &&
      (widget.authorizationReaderOverride?.call() ??
          ZyraDeveloperAccess.canUseDeveloperTools);

  Object get _holdIdentity {
    final coordinator = ZyraDevSurfaceCoordinator.instance;
    final scenario = ZyraDevScenario.instance;
    return (
      _holdUpdates,
      _holdUpdates.revision,
      ZyraAccountState.generation,
      ZyraAccountState.userId,
      widget.routeObserver?.revision,
      ZyraDevControlsRouteObserver.navigationRevision,
      coordinator.surface,
      coordinator.entryLabel,
      coordinator.activeRoleChoiceOwner,
      coordinator.roleChoiceRevision,
      coordinator.activeCompatibilityControls,
      scenario.currentPage,
      scenario.connectionsSection,
      scenario.currentWaliPage,
      scenario.waliRole,
      ZyraConceptPreviewIsolation.revision,
    );
  }

  bool _canOpenControls(Object identity) =>
      mounted &&
      _appForeground &&
      _entry != null &&
      widget.routeObserver != null &&
      _isAllowed &&
      ZyraDeveloperAccess.canUseDeveloperTools &&
      !ZyraConceptPreviewIsolation.active &&
      identity == _holdIdentity;

  void _requestControls(Object identity) {
    if (!_canOpenControls(identity)) return;
    _openRequests.value++;
  }

  @override
  void initState() {
    super.initState();
    _bindHoldUpdates();
    _lastAllowed = _isAllowed;
    WidgetsBinding.instance.addObserver(this);
    ZyraDeveloperAccess.authorizationChanges.addListener(
      _onAuthorizationChanged,
    );
  }

  void _bindHoldUpdates() {
    _holdUpdates = _DeferredDevHoldUpdates(
      Listenable.merge([
        ZyraDevSurfaceCoordinator.instance,
        ZyraDevScenario.instance,
        ZyraDeveloperAccess.authorizationChanges,
        ZyraConceptPreviewIsolation.changes,
        ZyraDevControlsRouteObserver.navigationChanges,
        if (widget.routeObserver != null) widget.routeObserver!,
      ]),
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
        unawaited(_acceptFreshTokenEvent(user, wasAllowed: wasAllowed));
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
    if (!allowed) {
      if (redirectIfLost) _cancelResumePresentation();
      _entry?.remove();
      _entry = null;
      if (redirectIfLost) {
        _redirectAfterAuthorityLoss(current: redirectCurrent);
      }
      return;
    }
    _scheduleSync();
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
    final foreground = state == AppLifecycleState.resumed;
    if (_appForeground != foreground && mounted) {
      setState(() => _appForeground = foreground);
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAuthorizationOnResume());
    }
  }

  void _scheduleSync() {
    if (!mounted) return;
    _ensureAuthSubscription();
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      final allowed = _isAllowed;
      _lastAllowed = allowed;
      if (!allowed) {
        _entry?.remove();
        _entry = null;
        return;
      }
      if (_entry != null) return;
      final overlay = widget.navigatorKey.currentState?.overlay;
      if (overlay == null) {
        _scheduleSync();
        return;
      }
      final entry = OverlayEntry(
        builder: (_) => ZyraGlobalDevOverlay(openRequests: _openRequests),
      );
      overlay.insert(entry);
      _entry = entry;
      // The hold trigger is inert until its destination overlay exists.
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ZyraGlobalDevOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeObserver != widget.routeObserver) {
      _holdUpdates.dispose();
      _bindHoldUpdates();
    }
    if (oldWidget.navigatorKey != widget.navigatorKey) {
      _entry?.remove();
      _entry = null;
    }
    _scheduleSync();
  }

  @override
  void dispose() {
    _holdUpdates.dispose();
    _cancelResumePresentation();
    WidgetsBinding.instance.removeObserver(this);
    ZyraDeveloperAccess.authorizationChanges.removeListener(
      _onAuthorizationChanged,
    );
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
    _entry?.remove();
    _entry = null;
    _openRequests.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleSync();
    final body = Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: _accountTransition, child: widget.child),
        if (_accountTransition) ColoredBox(color: ZyraColors.modalSheetSurface),
      ],
    );
    // Main supplies this observer only under the existing internal-build
    // flag. Ordinary builds retain the account-safety host, but do not mount
    // the test-only hold widget, detector or pointer recognizer at all.
    if (widget.routeObserver == null) return body;
    return ListenableBuilder(
      listenable: _holdUpdates,
      builder: (context, _) {
        final identity = _holdIdentity;
        return ZyraDevHoldToOpen(
          enabled: _canOpenControls(identity),
          identity: identity,
          canOpen: () => _canOpenControls(identity),
          onOpen: () => _requestControls(identity),
          child: body,
        );
      },
    );
  }
}

/// Inputs change synchronously for identity checks. Only repaint notification
/// waits when a child route publishes its context during Navigator build.
class _DeferredDevHoldUpdates extends ChangeNotifier {
  _DeferredDevHoldUpdates(this.source) {
    source.addListener(_changed);
  }

  final Listenable source;
  int _revision = 0;
  int get revision => _revision;
  bool _scheduled = false;
  bool _disposed = false;

  void _changed() {
    if (_disposed) return;
    // Even A→B→A before a deferred repaint invalidates the captured press.
    _revision++;
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!_disposed) notifyListeners();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    source.removeListener(_changed);
    super.dispose();
  }
}

/// One overlay above the Navigator. Its controls stay absent until the
/// guarded hold requests them, including on pushed routes.
class ZyraGlobalDevOverlay extends StatelessWidget {
  const ZyraGlobalDevOverlay({super.key, this.openRequests});

  final ValueListenable<int>? openRequests;

  @override
  Widget build(BuildContext context) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) {
      return const SizedBox.shrink();
    }
    final coordinator = ZyraDevSurfaceCoordinator.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        coordinator,
        ZyraConceptPreviewIsolation.changes,
      ]),
      builder: (context, _) =>
          !ZyraDeveloperAccess.canUseDeveloperTools ||
              ZyraConceptPreviewIsolation.active
          ? const SizedBox.shrink()
          : Stack(
              children: [
                switch (coordinator.surface) {
                  ZyraDevSurface.seeker => DevScenarioPanelV2(
                    onOpenPage: coordinator.openSeeker,
                    openRequests: openRequests,
                    onOpenConnectionsSection:
                        coordinator.openSeekerConnectionsSection,
                    onOpenIntroductions: coordinator.openSeekerIntroductions,
                  ),
                  ZyraDevSurface.guardian => WaliDevScenarioPanel(
                    onOpenPage: coordinator.openGuardian,
                    openRequests: openRequests,
                  ),
                  ZyraDevSurface.entry => ZyraEntryDevPanel(
                    pageLabel: coordinator.entryLabel,
                    openRequests: openRequests,
                  ),
                },
              ],
            ),
    );
  }
}

/// Auth/signup/onboarding control. It uses the same four doors, but its
/// Actions remain entry-flow actions instead of pretending shell scenarios
/// have readers on an onboarding page.
class ZyraEntryDevPanel extends StatefulWidget {
  final String pageLabel;
  final ValueListenable<int>? openRequests;

  const ZyraEntryDevPanel({
    super.key,
    required this.pageLabel,
    this.openRequests,
  });

  @override
  State<ZyraEntryDevPanel> createState() => _ZyraEntryDevPanelState();
}

class _ZyraEntryDevPanelState extends State<ZyraEntryDevPanel> {
  bool _open = false;
  ZyraDevControlSection _section = ZyraDevControlSection.actions;

  ZyraCompatibilityDevControls? get _compatibility =>
      ZyraDevSurfaceCoordinator.instance.activeCompatibilityControls;

  String get _pageContext {
    final controls = _compatibility;
    if (controls != null) {
      return 'entry:compatibility-${identityHashCode(controls)}';
    }
    final coordinator = ZyraDevSurfaceCoordinator.instance;
    final roleOwner = coordinator.activeRoleChoiceOwner;
    return roleOwner == null
        ? 'entry:${widget.pageLabel}'
        : 'entry:${widget.pageLabel}:role-${identityHashCode(roleOwner)}'
              '-${coordinator.roleChoiceRevision}';
  }

  @override
  void initState() {
    super.initState();
    ZyraDevSurfaceCoordinator.instance.addListener(_onContextChanged);
    ZyraDeveloperAccess.authorizationChanges.addListener(_onContextChanged);
    widget.openRequests?.addListener(_openRequested);
  }

  @override
  void didUpdateWidget(covariant ZyraEntryDevPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openRequests != widget.openRequests) {
      oldWidget.openRequests?.removeListener(_openRequested);
      widget.openRequests?.addListener(_openRequested);
    }
  }

  void _openRequested() {
    if (!mounted || _open || !ZyraDeveloperAccess.canUseDeveloperTools) return;
    setState(() {
      _section = ZyraDevControlSection.actions;
      _open = true;
    });
  }

  @override
  void dispose() {
    ZyraDevSurfaceCoordinator.instance.removeListener(_onContextChanged);
    ZyraDeveloperAccess.authorizationChanges.removeListener(_onContextChanged);
    widget.openRequests?.removeListener(_openRequested);
    super.dispose();
  }

  void _onContextChanged() {
    if (mounted) setState(() {});
  }

  List<ZyraDevPageOption> _compatibilityOptions(
    ZyraCompatibilityDevControls controls,
  ) => [
    for (final count in const [0, 1, 5])
      ZyraDevPageOption(
        id: 'compatibility-plus-$count',
        label: '$count Compatibility Unlock${count == 1 ? '' : 's'}',
        group: 'Compatibility Unlock',
        selected: controls.balance(true) == count,
        onSelected: () {
          // The signup presentation remains Entry even after its nested
          // Home reaches a product page. Only that current sample route
          // owns these local balances; a retained menu cannot act later.
          if (!mounted ||
              !ZyraDeveloperAccess.canUseDeveloperTools ||
              !identical(_compatibility, controls) ||
              !controls.isCurrent()) {
            return;
          }
          controls.setBalance(true, count);
        },
      ),
  ];

  void _select(ZyraDevControlSection section) {
    setState(() {
      _section = section;
      _open = true;
    });
  }

  void _close() => setState(() => _open = false);

  void _preview() {
    _close();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ZyraPagePreviewScreen.entry(widget.pageLabel),
      ),
    );
  }

  Future<void> _accounts() async {
    final navigator = Navigator.of(context);
    _close();
    final authorized = await ZyraDeveloperAccess.refreshCurrentAuthorization();
    if (!authorized || !ZyraDeveloperAccess.isAuthorizedOperator) {
      try {
        await ZyraAuth.signOut();
      } catch (error) {
        debugPrint('ZYRA Developer Access recheck sign-out failed: $error');
      }
      if (!navigator.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate(playSplash: false)),
        (route) => false,
      );
      return;
    }
    if (!navigator.mounted) return;
    navigator.push<void>(
      MaterialPageRoute(builder: (_) => const DeveloperAccessScreen()),
    );
  }

  void _signUp() {
    _close();
    ZyraDevSignUp.start(context);
  }

  void _home(bool Function()? onboardingExit) {
    if (!mounted || !ZyraDeveloperAccess.canUseDeveloperTools) return;
    if (onboardingExit != null) {
      // Bind the rendered action to its exact rehearsal owner. A stale tap
      // must not close a newer flow or fall through to generic navigation.
      if (onboardingExit()) _close();
      return;
    }
    unawaited(ZyraDevHome.open(context));
    _close();
  }

  Future<void> _restart() async {
    _close();
    try {
      await ZyraAuth.signOut();
    } catch (error) {
      debugPrint('ZYRA global developer Home sign-out failed: $error');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate(playSplash: true)),
      (route) => false,
    );
  }

  void _reset() {
    ZyraDevScenario.instance.reset();
    unawaited(ZyraPromotionEngine.instance.resetDeveloperPolicy());
  }

  @override
  Widget build(BuildContext context) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools || !_open) {
      return const SizedBox.shrink();
    }
    final compatibility = _compatibility;
    final coordinator = ZyraDevSurfaceCoordinator.instance;
    final onboardingExit = coordinator.onboardingExit;
    final roleChoiceOwner = coordinator.activeRoleChoiceOwner;
    return Positioned.fill(
      child: Material(
        key: const ValueKey('dev_controls_page'),
        color: ZyraColors.modalSheetSurface,
        child: SafeArea(
          child: Column(
            children: [
              ZyraDevControlsPageHeader(
                pageLabel: widget.pageLabel,
                selected: _section,
                onSelected: _select,
                onClose: _close,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
                  children: [
                    switch (_section) {
                      ZyraDevControlSection.preview => ZyraDevPreviewLauncher(
                        pageLabel: widget.pageLabel,
                        onOpen: _preview,
                      ),
                      ZyraDevControlSection.actions => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ZyraDevToolSection(
                            key: const ValueKey('dev_entry_section_onboarding'),
                            child: DevOnboardingDirectionPicker(
                              onBeforeOpen: _close,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const ZyraDevToolSection(
                            key: ValueKey(
                              'dev_entry_section_onboarding_transitions',
                            ),
                            child: DevOnboardingTransitionPicker(),
                          ),
                          const SizedBox(height: 16),
                          ZyraDevPageOptions(
                            contextKey: _pageContext,
                            options: [
                              if (compatibility != null)
                                ..._compatibilityOptions(compatibility),
                              if (roleChoiceOwner != null)
                                for (final design
                                    in ZyraRoleChoiceDesign.values)
                                  ZyraDevPageOption(
                                    id: 'dev_role_choice_${design.name}',
                                    label: design.label,
                                    group: 'Role choice design',
                                    selected:
                                        ZyraDevRoleChoiceDesign.current ==
                                        design,
                                    onSelected: () {
                                      if (!coordinator.selectRoleChoiceDesign(
                                        roleChoiceOwner,
                                        design,
                                      )) {
                                        throw StateError(
                                          'Role choice route is no longer current.',
                                        );
                                      }
                                    },
                                  ),
                              ZyraDevPageOption(
                                id: 'dev_entry_accounts',
                                label: 'Switch test account',
                                group: 'Entry',
                                onSelected: _accounts,
                              ),
                              ZyraDevPageOption(
                                id: 'dev_entry_signup',
                                label: 'Onboarding',
                                group: 'Onboarding',
                                onSelected: _signUp,
                              ),
                            ],
                          ),
                        ],
                      ),
                      ZyraDevControlSection.home => ZyraDevHomeTools(
                        busy: false,
                        onHome: () => _home(onboardingExit),
                        onOpenSplashPreview: _close,
                        onRestart: _restart,
                        onReset: _reset,
                        onAccounts: _accounts,
                        onSeekerSignUp: _signUp,
                        onGuardianSignUp: _signUp,
                      ),
                    },
                    if (_section == ZyraDevControlSection.preview) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Internal preview',
                        textAlign: TextAlign.center,
                        style: ZyraText.subtext(
                          size: 10,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
