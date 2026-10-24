// Shared local persona entry for Developer Access and its gender toggle.
// No account switching, provider changes or live mutations. Only the guarded
// Founder presentation direction and preview role are remembered locally.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Session, Supabase;

import '../data/zyra_membership_catalog.dart';
import '../screens/home/home_shell.dart';
import '../screens/wali/wali_home_shell.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_app_lock.dart';
import '../services/zyra_internal_preview_client.dart';
import '../services/zyra_local_prefs.dart';
import '../services/zyra_profile_service.dart';
import '../services/zyra_promotion_engine.dart';
import '../models/zyra_signup_membership_choice.dart';
import '../state/app_state.dart';
import 'zyra_dev_scenario.dart';
import 'zyra_dev_surface_coordinator.dart';
import 'zyra_founder_launch_screen.dart';

/// A pending local entry, not a cached screen or an authorization grant.
/// Listeners begin before Auth is refreshed. A prepared entry is single-use
/// and is permanently withdrawn if its originating lifetime is interrupted.
class ZyraLocalPreviewPreparation with WidgetsBindingObserver {
  ZyraLocalPreviewPreparation._(this._current, {ModalRoute<dynamic>? route})
    : _coverAnimation = route?.secondaryAnimation,
      ownerId = ZyraAccountState.userId,
      ownerGeneration = ZyraAccountState.generation,
      _preferenceGeneration = ZyraLocalPrefs.bindingGeneration {
    _session = _readSession();
    _initialSession = _session;
    // Popup/fullscreen-dialog routes need not drive the underlying route's
    // secondary animation. Check each real frame while preparation is pending,
    // so a displayed cover cannot be popped to revive the old local intent.
    _routeWatch = Ticker((_) => _checkLifetime())..start();
    WidgetsBinding.instance.addObserver(this);
    _coverAnimation?.addStatusListener(_routeChanged);
    ZyraAppLock.instance.addListener(_checkLifetime);
    AppState.instance.addListener(_checkLifetime);
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen(_authChanged, onError: (Object _) => dispose());
    } catch (_) {
      // A session-less compiled tester still follows the existing tester
      // policy. It cannot become a Founder preparation without a real session.
    }
    _checkLifetime();
  }

  final bool Function() _current;
  final Animation<double>? _coverAnimation;
  late final Ticker _routeWatch;
  final String? ownerId;
  final int ownerGeneration;
  final int _preferenceGeneration;
  Session? _initialSession;
  Session? _session;
  StreamSubscription<AuthState>? _authSubscription;
  final Completer<void> _withdrawn = Completer<void>();
  bool _disposed = false;
  bool _consumed = false;
  bool _refreshing = true;
  bool _watchingProof = false;
  bool _ready = false;
  late bool _founder;
  late bool _guardian;
  late bool _premium;
  late String _gender;
  late String _name;
  late DateTime _dob;
  late String _location;

  Future<void> get withdrawn => _withdrawn.future;

  static Session? _readSession() {
    try {
      return Supabase.instance.client.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  static bool get foreground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return (lifecycle == null || lifecycle == AppLifecycleState.resumed) &&
        !ZyraAppLock.instance.isLocked &&
        !ZyraAppLock.instance.isObscured;
  }

  bool get _sameLifetime =>
      !_disposed &&
      !_consumed &&
      foreground &&
      _originCurrent &&
      !ZyraAccountState.isSigningOut &&
      ownerId == ZyraAccountState.userId &&
      ownerGeneration == ZyraAccountState.generation &&
      ownerId == ZyraLocalPrefs.accountOwner &&
      _preferenceGeneration == ZyraLocalPrefs.bindingGeneration &&
      _initialSession?.user.id == ownerId &&
      _readSession()?.user.id == _initialSession?.user.id;

  bool get _originCurrent {
    try {
      return _current();
    } catch (_) {
      return false;
    }
  }

  bool get isReady =>
      _ready &&
      _sameLifetime &&
      identical(_readSession(), _session) &&
      (_session == null ||
          (_session!.expiresAt != null && !_session!.isExpired)) &&
      (!_founder || _session?.user.id == ownerId) &&
      (!_founder ||
          (ZyraDeveloperAccess.isMainAppFounderPreview &&
              !ZyraDeveloperAccess.isAuthorizedTester)) &&
      ZyraDeveloperAccess.canUseDeveloperTools &&
      ZyraDeveloperAccess.isMainAppPreview;

  void _checkLifetime() {
    if (_consumed) return;
    if (!_sameLifetime) dispose();
  }

  void _routeChanged(AnimationStatus _) => _checkLifetime();

  void _authChanged(AuthState state) {
    if (_disposed) return;
    if (!identical(state.session, _readSession())) {
      // Event payloads alone are not an SDK account replacement. A real
      // replacement still fails the captured SDK/owner/frame checks, including
      // a queued A -> B -> A sequence whose final Session is a new object.
      _checkLifetime();
      return;
    }
    final sameOwner = state.session?.user.id == _initialSession?.user.id;
    final sameSessionReplay =
        identical(state.session, _refreshing ? _initialSession : _session) &&
        (state.event == AuthChangeEvent.initialSession ||
            state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.tokenRefreshed);
    // Only the preparation's own fresh authorization stage may rotate tokens.
    // A new login/recovery, including A -> B -> A, is never the old intent.
    if (!sameOwner ||
        (!sameSessionReplay &&
            !(state.event == AuthChangeEvent.tokenRefreshed &&
                (_refreshing || identical(state.session, _session))))) {
      dispose();
    }
  }

  void _proofChanged() {
    if (!ZyraDeveloperAccess.canUseDeveloperTools ||
        !ZyraDeveloperAccess.isMainAppPreview ||
        (_founder && !ZyraDeveloperAccess.isMainAppFounderPreview)) {
      dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) dispose();
  }

  /// Consumes even a failed commit. The caller must prepare again; it cannot
  /// revive a previously covered, backgrounded or proof-retracted entry.
  ZyraLocalPreviewPresentation? commit() {
    final accepted = isReady;
    _consumed = true;
    if (!accepted) {
      dispose();
      return null;
    }
    try {
      ZyraDevLocalPreview._apply(this);
      return ZyraLocalPreviewPresentation._(
        founder: _founder,
        ownerId: ownerId,
        generation: ownerGeneration,
        guardian: _guardian,
        premium: _premium,
      );
    } finally {
      dispose();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _routeWatch.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _coverAnimation?.removeStatusListener(_routeChanged);
    ZyraAppLock.instance.removeListener(_checkLifetime);
    AppState.instance.removeListener(_checkLifetime);
    if (_watchingProof) {
      ZyraDeveloperAccess.authorizationChanges.removeListener(_proofChanged);
    }
    _authSubscription?.cancel().ignore();
    if (!_withdrawn.isCompleted) _withdrawn.complete();
    if (identical(ZyraDevLocalPreview._preparing, this)) {
      ZyraDevLocalPreview._preparing = null;
    }
  }
}

/// A committed local presentation recipe. It contains no prefetched widget,
/// server data or reusable Founder proof. The runtime surface keeps its own
/// existing fail-closed authorization boundary.
class ZyraLocalPreviewPresentation {
  const ZyraLocalPreviewPresentation._({
    required this.founder,
    required this.ownerId,
    required this.generation,
    required this.guardian,
    required this.premium,
  });
  final bool founder;
  final String? ownerId;
  final int generation;
  final bool guardian;
  final bool premium;

  Widget buildDestination() => founder
      ? ZyraFounderReviewSurface(
          ownerId: ownerId!,
          ownerGeneration: generation,
          initialGuardianRole: guardian,
          initialSeekerBasic: !guardian && !premium,
          initialGuardianBasic: guardian && !premium,
        )
      : guardian
      ? const WaliHomeShell()
      : const HomeShell(
          initialTab: 2,
          deferredOnboardingDevPreview: true,
          initialOnboardingProgress: ZyraOnboardingProgress(
            complete: true,
            due: 0,
            missing: 0,
            hasChapter2: true,
            basicProfile: true,
          ),
        );
}

class ZyraDevLocalPreview {
  ZyraDevLocalPreview._();

  static final ValueNotifier<String> genderSelection = ValueNotifier('male');
  static ZyraLocalPreviewPreparation? _preparing;
  static bool _seekerPremium = true;
  static bool _guardianPremium = true;

  static String get seekerMembershipLabel =>
      _seekerPremium ? ZyraMembershipCatalog.seekerOneTitle : 'Seeker Basic';
  static String get guardianMembershipLabel => _guardianPremium
      ? ZyraMembershipCatalog.guardianOneTitle
      : 'Guardian Basic';

  /// A labelled local sample, never a claim that a default Basic account paid.
  static String? basicMembershipPreviewLabel({required bool guardian}) =>
      ZyraInternalPreviewClient.isActive &&
          ZyraDeveloperAccess.canUseDeveloperTools &&
          !(guardian ? _guardianPremium : _seekerPremium)
      ? '${guardian ? 'Guardian' : 'Seeker'} Basic · Preview'
      : null;

  /// Apply a deliberately selected sample only after the protected signup
  /// rehearsal reaches its completion action. Never callable by live signup;
  /// this is not a payment, receipt, identity or Family allocation operation.
  static bool applySignupMembershipPreview({
    required ZyraSignupRole role,
    required ZyraSignupMembershipChoice choice,
  }) {
    if (!ZyraInternalPreviewClient.isActive ||
        !ZyraDeveloperAccess.isMainAppPreview ||
        !ZyraDeveloperAccess.canUseDeveloperTools ||
        !choice.isValidFor(role)) {
      return false;
    }
    final premium = choice.kind != ZyraSignupMembershipKind.basic;
    if (role == ZyraSignupRole.guardian) {
      _guardianPremium = premium;
      AppState.instance.setWaliOne(premium);
    } else {
      _seekerPremium = premium;
      AppState.instance.setPlan(premium ? ZyraPlan.one : ZyraPlan.basic);
    }
    return true;
  }

  static Future<void> selectGender(BuildContext context, String gender) async {
    if ((gender != 'male' && gender != 'female') ||
        !ZyraDeveloperAccess.isMainAppPreview) {
      return;
    }
    final surface = ZyraDevSurfaceCoordinator.instance.surface;
    if (surface == ZyraDevSurface.entry ||
        ZyraDevSurfaceCoordinator.instance.developerLandingVisible) {
      // Selecting the next sample is not editing the signed-in account.
      genderSelection.value = gender;
      return;
    }
    await open(
      context,
      isWali: surface == ZyraDevSurface.guardian,
      premium: surface == ZyraDevSurface.guardian
          ? _guardianPremium
          : _seekerPremium,
      gender: gender,
    );
  }

  /// Performs the existing fresh authorization and owned preference work,
  /// but does not publish a persona, scenario, isolation lease or destination.
  /// Startup can do this work beneath its existing splash. Ordinary developer
  /// entry calls the exact same policy, then consumes the resulting recipe.
  static Future<ZyraLocalPreviewPreparation?> prepare({
    required bool Function() current,
    ModalRoute<dynamic>? route,
    void Function(ZyraLocalPreviewPreparation)? onCreated,
    required bool isWali,
    bool premium = true,
    String? gender,
    String? identityName,
    DateTime? identityDob,
    String? identityLocation,
  }) async {
    if (_preparing != null || ZyraAccountState.isSigningOut) {
      return null;
    }
    final selectedGender = gender ?? genderSelection.value;
    if (selectedGender != 'male' && selectedGender != 'female') return null;
    final preparation = ZyraLocalPreviewPreparation._(current, route: route);
    if (preparation._disposed) return null;
    _preparing = preparation;
    try {
      onCreated?.call(preparation);
      if (preparation._disposed) return null;
      final tester = ZyraDeveloperAccess.isAuthorizedTester;
      final authorization = tester
          ? null
          : await ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
      if (!preparation._sameLifetime ||
          !ZyraDeveloperAccess.canUseDeveloperTools ||
          !ZyraDeveloperAccess.isMainAppPreview) {
        preparation.dispose();
        return null;
      }
      final founder =
          authorization?.founderAuthorized == true &&
          authorization?.user?.id == preparation.ownerId &&
          preparation.ownerId != null;
      preparation
        .._founder = founder
        .._session = ZyraLocalPreviewPreparation._readSession()
        .._refreshing = false
        .._watchingProof = true;
      if ((founder && preparation._session == null) ||
          (preparation._session != null &&
              (preparation._session!.expiresAt == null ||
                  preparation._session!.isExpired))) {
        preparation.dispose();
        return null;
      }
      // The refresh above intentionally retracts then restores proof. Start
      // this terminal proof-epoch watch after that owned authorization stage,
      // before any further await or reusable prepared result is published.
      ZyraDeveloperAccess.authorizationChanges.addListener(
        preparation._proofChanged,
      );
      if (founder) {
        await ZyraLocalPrefs.setFounderPreviewRole(
          isWali ? 'guardian' : 'seeker',
          expectedOwner: preparation.ownerId!,
          expectedBindingGeneration: preparation._preferenceGeneration,
        );
        if (!preparation._sameLifetime ||
            !ZyraDeveloperAccess.canUseDeveloperTools) {
          preparation.dispose();
          return null;
        }
      }
      final female = selectedGender == 'female';
      preparation
        .._guardian = isWali
        .._premium = premium
        .._gender = selectedGender
        .._name =
            identityName ??
            (isWali
                ? (female ? 'Khadija' : 'Ibrahim')
                : (female ? 'Maryam' : 'Adam'))
        .._dob =
            identityDob ??
            (isWali
                ? (female ? DateTime(1970, 4, 2) : DateTime(1968, 1, 15))
                : (female ? DateTime(1998, 7, 22) : DateTime(1997, 3, 14)))
        .._location =
            identityLocation ??
            (isWali
                ? (female ? 'Manchester' : 'Birmingham')
                : (female ? 'Birmingham' : 'London'))
        .._ready = true;
      if (!preparation.isReady) {
        preparation.dispose();
        return null;
      }
      return preparation;
    } catch (error) {
      debugPrint('ZYRA local preview entry failed (${error.runtimeType}).');
      preparation.dispose();
      return null;
    }
  }

  static void _apply(ZyraLocalPreviewPreparation preparation) {
    final isWali = preparation._guardian;
    final premium = preparation._premium;
    final female = preparation._gender == 'female';
    if (isWali) {
      _guardianPremium = premium;
    } else {
      _seekerPremium = premium;
    }
    ZyraInternalPreviewClient.beginPreview();
    genderSelection.value = preparation._gender;
    AppState.instance.applyDevPreset(
      name: preparation._name,
      gender: preparation._gender,
      dob: preparation._dob,
      location: preparation._location,
      waliName: isWali ? preparation._name : null,
      waliRelationship: isWali ? (female ? 'Mother' : 'Father') : null,
      plan: !isWali && premium ? ZyraPlan.one : ZyraPlan.basic,
      waliHasWaliOne: isWali && premium,
    );
    if (isWali) {
      ZyraPromotionEngine.instance.setDeveloperGuardianNetworkState(
        premium
            ? ZyraDeveloperGuardianNetworkState.d14Preview
            : ZyraDeveloperGuardianNetworkState.linkedBasic,
      );
    }
    final scenario = ZyraDevScenario.instance;
    scenario.reset();
    scenario.setDashboardLabEnabled(true);
    scenario.setDashboardOnboardingComplete(true);
    scenario.setUseLiveGuardianData(false);
    scenario.setMainGuardian(true);
    scenario.setWaliLinkedSeekers(2);
    ZyraDevSurfaceCoordinator.instance.endEntryFlow();
  }

  static Future<bool> open(
    BuildContext context, {
    required bool isWali,
    bool premium = true,
    String? gender,
    String? identityName,
    DateTime? identityDob,
    String? identityLocation,
  }) async {
    if (!context.mounted || !ZyraDeveloperAccess.isMainAppPreview) return false;
    // Proof refresh can dispose the overlay's button context. The originating
    // Navigator and route, not a retained overlay element, own this operation.
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    final preparation = await prepare(
      current: () => navigator.mounted && (route == null || route.isCurrent),
      route: route,
      isWali: isWali,
      premium: premium,
      gender: gender,
      identityName: identityName,
      identityDob: identityDob,
      identityLocation: identityLocation,
    );
    final presentation = preparation?.commit();
    if (presentation == null) return false;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => presentation.buildDestination()),
      (_) => false,
    );
    return true;
  }

  /// Switches application context without ending the authenticated session.
  ///
  /// The current preview identity is carried into the target context while
  /// each context keeps its own remembered membership. This mirrors the
  /// production contract without pretending the migration already exists.
  static Future<void> switchAccountContext(
    BuildContext context, {
    required bool toGuardian,
  }) async {
    if (!ZyraDeveloperAccess.isMainAppPreview) return;
    final state = AppState.instance;
    final identityName = state.name ?? state.waliName;
    await open(
      context,
      isWali: toGuardian,
      premium: toGuardian ? _guardianPremium : _seekerPremium,
      gender: state.gender ?? genderSelection.value,
      identityName: identityName,
      identityDob: state.dob,
      identityLocation: state.location,
    );
  }
}
