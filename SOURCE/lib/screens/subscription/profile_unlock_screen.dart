// The legacy Compatibility Unlock keeps its single-page offer and the
// separate Overall and Guardian disclosures. New full-detail spending is
// held until the trusted Plus contract is available. Earlier grants stay
// readable under their existing access checks.
//
// LOCK 27 V3 and DR-ZYRA-250 D3/D4 define the fixed areas and band-only
// display. Real grants have no area data yet. Only the admitted local
// sample can display synthetic bands, after using a route-local unlock.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../dev/zyra_app_gold_preview.dart';

import '../../dev/zyra_compatibility_demo.dart';
import '../../dev/zyra_draft_compatibility_presentation.dart';
import '../../dev/zyra_draft_compatibility_score_designs.dart';
import '../../dev/zyra_preview_navigation_checkpoint.dart';
import '../../models/seeker_profile.dart';
import '../../models/zyra_compatibility_area.dart';
import '../../models/zyra_gender.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_guardian_info_service.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_compatibility_topics_service.dart';
import '../../services/zyra_unlock_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_compatibility_area_row.dart';
import '../../widgets/zyra_gold_action_pill.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../profile/compatibility_editors.dart' show showZyraPreferenceToast;
import '../profile/compatibility_result_quick_check.dart';

/// Code-only fixture access to a mounted local sample. Binding and mutation
/// exist only inside assertions; release app routes cannot attach this owner.
@visibleForTesting
class ZyraCompatibilityFixture {
  _ProfileUnlockScreenState? _owner;

  void _attach(_ProfileUnlockScreenState owner) => _owner = owner;

  String? get profileId => _owner?._profileAtOpen;
  bool isCurrent() => _owner?._fixtureCurrent == true;
  int balance(bool plus) => plus ? (_owner?._previewPlus ?? 0) : 0;

  void setBalance(bool plus, int count) {
    assert(() {
      _owner?._setFixtureBalance(plus, count);
      return true;
    }());
  }

  Future<void> Function() captureBalance(bool plus, int count) {
    final owner = _owner;
    final navigation = ZyraPreviewRouteObserver.navigationRevision;
    return () async {
      assert(() {
        if (identical(owner, _owner) &&
            navigation == ZyraPreviewRouteObserver.navigationRevision) {
          owner?._setFixtureBalance(plus, count);
        }
        return true;
      }());
    };
  }
}

class ProfileUnlockScreen extends StatefulWidget {
  final SeekerProfile profile;

  @visibleForTesting
  final ZyraCompatibilityFixture? fixture;

  /// THE JOURNEY DOOR — 2026-08-13 (Founder: Paused/Ended cards read
  /// "View Compatibility", never "Compatibility Unlock", "because they
  /// already unlocked"). A Journey OPENS with Compatibility Reveal: the
  /// overall figure was shown to both people as part of the Journey
  /// itself, so for a pair whose Journey began, this screen must never
  /// re-lock what the Journey already revealed — asking them to pay to
  /// see it again would be charging for a memory.
  ///
  /// True only when opened from a Journey surface for such a pair (the
  /// Paused/Ended cards, the Timeline's Compatibility entry). Affects
  /// the OVERALL section alone; the Plus detail (areas, Guardians)
  /// stays gated exactly as before — the Journey never revealed those.
  /// This display flag is not numeric-read authority: the legacy score read
  /// additionally requires an existing owner/profile grant. A Journey without
  /// that grant keeps its open/no-charge door but shows an unavailable figure
  /// until the held saved Journey-result server contract is integrated.
  final bool journeyRevealed;
  final String? journeyMatchId;

  const ProfileUnlockScreen({
    super.key,
    required this.profile,
    this.journeyRevealed = false,
    this.journeyMatchId,
    this.fixture,
  });

  @override
  State<ProfileUnlockScreen> createState() => _ProfileUnlockScreenState();
}

class _ProfileUnlockScreenState extends State<ProfileUnlockScreen> {
  bool _busy = false;
  bool _needsRecovery = false;
  bool _accountExpired = false;
  late final String? _ownerAtOpen;
  late final int _generationAtOpen;
  late final String _profileAtOpen;
  late final String? _matchAtOpen;
  StreamSubscription<dynamic>? _authSubscription;
  int _balanceRequest = 0;
  int _scoreRequest = 0;
  int _guardianRequest = 0;
  int _unlockRequest = 0;
  int _accessRequest = 0;
  bool _accessUnavailable = false;
  bool _resultReadFailed = false;
  bool _checking = false;
  bool _checkedFromResult = false;
  bool _readyNoticePending = false;
  ZyraCompatibilityTopicsResult? _topics;
  late final bool _sampleMode;
  bool _previewAuthorizedAtOpen = false;
  ModalRoute<dynamic>? _route;
  int _previewPlus = 1;
  // This is presentation state owned by this route, never profile_unlocks
  // or the service's unlock cache. It cannot authorize real Guardian reads.
  bool _previewPlusUnlocked = false;

  bool get _isDeveloperPreview =>
      _sampleMode &&
      _previewAuthorizedAtOpen &&
      ZyraDeveloperAccess.canUseDeveloperTools;

  /// Production balances come from `unlock_credits`; authorized non-persisted
  /// sample routes use their own local preview balances only.
  ///
  /// REPLACED the dev panel's in-memory counts 2026-08-04. Those were the
  /// only notion of a balance that existed anywhere — which is exactly why
  /// nothing could check one, and why C-1 was possible. The number on this
  /// screen is now the same number the server enforces against.
  Map<UnlockTier, int> _balance = const {};
  bool _loadingBalance = true;
  bool _balanceUnavailable = false;
  bool _balanceReadPending = false;

  /// Guardians of the profile being viewed. Three distinct states, and the
  /// difference between them matters (Founder decision, 2026-08-05):
  ///   null       — not unlocked at Plus, or the lookup failed. Stays locked.
  ///   empty list — unlocked, and she genuinely has no Guardian. Says so.
  ///   non-empty  — unlocked, shown in full.
  List<GuardianInfo>? _guardians;

  @override
  void initState() {
    super.initState();
    _ownerAtOpen = _currentOwner();
    _generationAtOpen = ZyraAccountState.generation;
    _profileAtOpen = widget.profile.id;
    _matchAtOpen = widget.journeyMatchId;
    // Raw sample identity never falls into live balance reads after revocation.
    _sampleMode = ZyraUnlockService.isSampleProfile(widget.profile.id);
    _previewAuthorizedAtOpen =
        _sampleMode && ZyraDeveloperAccess.canUseDeveloperTools;
    assert(() {
      widget.fixture?._attach(this);
      return true;
    }());
    ZyraDeveloperAccess.authorizationChanges.addListener(_onAuthorityChanged);
    AppState.instance.addListener(_onAccountChanged);
    try {
      _authSubscription = ZyraAuth.authStateChanges.listen(
        (_) => _onAccountChanged(),
        onError: (Object _, StackTrace _) => _expireAccount(),
      );
    } catch (_) {
      // The protected local preview intentionally needs no Supabase runtime.
    }
    _loadBalance();
    _loadExistingAccess();
  }

  static String? _currentOwner() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  bool get _lifetimeCurrent =>
      mounted &&
      !_accountExpired &&
      !ZyraAccountState.isSigningOut &&
      _generationAtOpen == ZyraAccountState.generation &&
      _ownerAtOpen == _currentOwner() &&
      _profileAtOpen == widget.profile.id &&
      _matchAtOpen == widget.journeyMatchId;

  bool get _fixtureCurrent =>
      _lifetimeCurrent && _isDeveloperPreview && (_route?.isCurrent ?? false);

  void _setFixtureBalance(bool plus, int count) {
    if (!_fixtureCurrent || !plus || !const [0, 1, 5].contains(count)) return;
    setState(() {
      _previewPlus = count;
      _balance = {ZyraUnlockService.currentTier: _previewPlus};
    });
  }

  void _onAccountChanged() {
    if (!mounted || _accountExpired || _lifetimeCurrent) return;
    _expireAccount();
  }

  void _expireAccount() {
    if (!mounted || _accountExpired) return;
    setState(() {
      _accountExpired = true;
      _busy = false;
      _balance = const {};
      _guardians = null;
      _realScore = null;
      _topics = null;
      _readyNoticePending = false;
      _previewPlusUnlocked = false;
    });
    _balanceRequest++;
    _scoreRequest++;
    _guardianRequest++;
    _unlockRequest++;
    _accessRequest++;
  }

  @override
  void didUpdateWidget(covariant ProfileUnlockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onAccountChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  void _onAuthorityChanged() {
    if (!mounted || !_sampleMode) return;
    if (!_isDeveloperPreview) {
      _previewPlusUnlocked = false;
      _realScore = null;
      _loadingScore = false;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    AppState.instance.removeListener(_onAccountChanged);
    ZyraDeveloperAccess.authorizationChanges.removeListener(
      _onAuthorityChanged,
    );
    super.dispose();
  }

  /// This Seeker's owned figure. Null also covers failed/withheld access or
  /// an unavailable calculation; the UI must not invent a reason or number.
  double? _realScore;
  bool _loadingScore = true;

  /// Hydration may still be pending when this route opens. Confirm this
  /// owner/profile grant independently instead of fetching a hidden number
  /// first or treating an unloaded cache as proof that paid access was lost.
  Future<void> _loadExistingAccess() async {
    if (!_lifetimeCurrent) return;
    final request = ++_accessRequest;
    if (_sampleMode) {
      // The isolated preview has no member data. Its fixture is calculated
      // only after the existing local unlock action, never by a live RPC.
      if (_isDeveloperPreview && _previewPlusUnlocked) {
        await _loadRealScore();
      } else {
        setState(() => _loadingScore = false);
      }
      return;
    }
    final owned = await ZyraUnlockService.confirmOwnedAccess(
      widget.profile.id,
      UnlockTier.standard,
    );
    if (!_lifetimeCurrent || request != _accessRequest) return;
    setState(() {
      _accessUnavailable = owned == null;
      if (owned != true) {
        _realScore = null;
        _loadingScore = false;
      }
    });
    if (owned == true) _loadGuardians();
    if (owned == true || _canReadJourneyResult) {
      await _loadRealScore();
    }
  }

  bool get _canReadJourneyResult =>
      widget.journeyRevealed && _matchAtOpen != null;

  bool get _canReadResult =>
      _canReadJourneyResult ||
      ZyraUnlockService.isUnlocked(_profileAtOpen, UnlockTier.standard);

  Future<void> _loadRealScore({bool allowLegacy = true}) async {
    if (!_lifetimeCurrent) return;
    final request = ++_scoreRequest;
    // Founder preview cards have no onboarding rows. Give only that isolated
    // environment a deterministic fixture score so it can exercise the real
    // locked -> unlocked presentation without contacting Supabase.
    if (_isDeveloperPreview) {
      setState(() {
        _realScore = _previewPlusUnlocked
            ? ZyraUnlockService.developerPreviewScore(widget.profile.id)
            : null;
        _loadingScore = false;
      });
      return;
    }

    // A non-authorised sample has no score and must never be passed to the
    // UUID RPC. Production Browse does not supply sample profiles.
    if (ZyraUnlockService.isSampleProfile(widget.profile.id)) {
      if (mounted) setState(() => _loadingScore = false);
      return;
    }
    final owner = _ownerAtOpen;
    if (owner == null || !_canReadResult) return;
    setState(() {
      _loadingScore = true;
      _resultReadFailed = false;
    });
    ZyraCompatibilityTopicsResult? topics;
    double? score;
    bool failed = false;
    try {
      if (ZyraCompatibilityTopicsService.clientReady) {
        topics = await ZyraCompatibilityTopicsService.fetch(
          expectedUserId: owner,
          subjectId: _profileAtOpen,
          matchId: _canReadJourneyResult ? _matchAtOpen : null,
        );
        score = topics?.overallScore;
      } else if (allowLegacy &&
          ZyraUnlockService.isUnlocked(_profileAtOpen, UnlockTier.standard)) {
        score = await ZyraDiscoveryService.fetchMyScoreFor(_profileAtOpen);
      }
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202' && allowLegacy) {
        if (!_lifetimeCurrent || request != _scoreRequest) return;
        if (ZyraUnlockService.isUnlocked(_profileAtOpen, UnlockTier.standard)) {
          score = await ZyraDiscoveryService.fetchMyScoreFor(_profileAtOpen);
        }
      } else {
        failed = true;
      }
    } catch (_) {
      failed = true;
    }
    if (!_lifetimeCurrent || request != _scoreRequest) return;
    setState(() {
      _topics = topics;
      _realScore = score;
      _resultReadFailed = failed;
      _loadingScore = false;
    });
    if (mounted &&
        _readyNoticePending &&
        topics?.state == ZyraCompatibilityTopicsState.ready &&
        _canReadResult &&
        _route?.isCurrent == true) {
      _readyNoticePending = false;
      showZyraPreferenceToast(context, 'Thank you. Your result is ready.');
    }
  }

  Future<void> _checkResultAnswers() async {
    final owner = _ownerAtOpen;
    bool current() => _lifetimeCurrent && _canReadResult;
    if (owner == null ||
        _checking ||
        _loadingScore ||
        !current() ||
        _topics?.state != ZyraCompatibilityTopicsState.needsReconfirmation ||
        _route?.isCurrent != true) {
      return;
    }
    setState(() => _checking = true);
    try {
      final completed = await openZyraCompatibilityResultCheck(
        context: context,
        ownerId: owner,
        isOwnerCurrent: current,
      );
      if (!completed || !current() || _route?.isCurrent != true) return;
      _checkedFromResult = true;
      _readyNoticePending = true;
      await _loadRealScore(allowLegacy: false);
      if (!mounted || !current() || _route?.isCurrent != true) return;
      if (_topics?.state == ZyraCompatibilityTopicsState.needsReconfirmation) {
        showZyraPreferenceToast(
          context,
          'Your compatibility score isn’t available right now.',
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _loadBalance() async {
    if (!_lifetimeCurrent || _balanceReadPending) return;
    final request = ++_balanceRequest;
    if (_sampleMode) {
      setState(() {
        _balance = _isDeveloperPreview
            ? {ZyraUnlockService.currentTier: _previewPlus}
            : const {};
        _loadingBalance = false;
        _balanceUnavailable = false;
      });
      return;
    }
    _balanceReadPending = true;
    setState(() => _loadingBalance = true);
    final b = await ZyraUnlockService.readBalances();
    if (!_lifetimeCurrent || request != _balanceRequest) return;
    setState(() {
      _balanceReadPending = false;
      _balance = b.values;
      _balanceUnavailable = !b.available;
      _loadingBalance = false;
    });
    if (b.status == UnlockBalanceStatus.failed) {
      // Same existing snackbar surface; no new card, price or layout.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_lifetimeCurrent || request != _balanceRequest) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your unlock balance couldn’t be checked.'),
            action: SnackBarAction(
              label: 'Check again',
              onPressed: () {
                if (_lifetimeCurrent &&
                    request == _balanceRequest &&
                    !_balanceReadPending) {
                  _checkBalance(); // read-only, never a debit
                }
              },
            ),
          ),
        );
      });
    }
  }

  void _checkBalance() {
    if (!_lifetimeCurrent || _busy || !(_route?.isCurrent ?? false)) return;
    _loadBalance();
  }

  /// Only ever fetched when a Plus unlock is already held — the RPC would
  /// return nothing otherwise, and asking anyway would make "no Guardian"
  /// and "not unlocked" indistinguishable in the logs.
  Future<void> _loadGuardians() async {
    if (!_lifetimeCurrent) return;
    final request = ++_guardianRequest;
    if (!ZyraUnlockService.isUnlocked(widget.profile.id, UnlockTier.plus)) {
      return;
    }
    if (ZyraUnlockService.isSampleProfile(widget.profile.id)) return;
    final g = await ZyraGuardianInfoService.fetchUnlocked(widget.profile.id);
    if (!_lifetimeCurrent || request != _guardianRequest) return;
    setState(() => _guardians = g);
  }

  /// Spends a credit, then rebuilds so the section swaps to the result.
  ///
  /// The outcome is no longer a bool (2026-08-04). "You have no credits"
  /// and "the network failed" used to produce the same retry message, and
  /// retrying will never fix the first one.
  Future<void> _unlock() async {
    const tier = ZyraUnlockService.currentTier;
    if (!_lifetimeCurrent ||
        !(_route?.isCurrent ?? false) ||
        _busy ||
        _needsRecovery ||
        _balanceUnavailable ||
        _loadingBalance) {
      return;
    }
    if (_sampleMode &&
        (!_isDeveloperPreview ||
            !(_route?.isCurrent ?? false) ||
            (_balance[tier] ?? 0) < 1)) {
      return;
    }
    if (!ZyraUnlockService.isTierAvailable(tier)) return;

    final request = ++_unlockRequest;
    // One product, one entitlement. Never downgrade to an earlier overall
    // credit if the full-detail product is held or unavailable.
    setState(() => _busy = true);
    if (_sampleMode &&
        (!_isDeveloperPreview || !(_route?.isCurrent ?? false))) {
      setState(() => _busy = false);
      return;
    }

    final outcome = await ZyraUnlockService.unlock(widget.profile.id, tier);
    if (!mounted || !_lifetimeCurrent || request != _unlockRequest) return;
    setState(() => _busy = false);

    switch (outcome) {
      case UnlockOutcome.unlocked:
      case UnlockOutcome.alreadyUnlocked:
        _loadBalance(); // a credit may have gone; re-read rather than guess
        _loadGuardians(); // Plus reveals Guardians — fetch them now it's open
        _loadRealScore(); // the numeric read is now backed by owned access
      case UnlockOutcome.sampleProfile:
        // Founder preview: the local service has already recorded the unlock
        // for this session. Rebuilding reveals the deterministic test score;
        // the global preview boundary is the disclosure, so no snackbar
        // interrupts the feature itself.
        if (_isDeveloperPreview) {
          setState(() {});
          _loadBalance();
        }
        return;
      case UnlockOutcome.insufficientCredits:
        _loadBalance(); // our count was stale if we got here at all
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You don't have an unlock left for this."),
          ),
        );
      case UnlockOutcome.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Detailed compatibility isn’t available yet. No unlock was used.',
            ),
          ),
        );
      case UnlockOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This unlock could not be requested. No new access was confirmed.',
            ),
          ),
        );
      case UnlockOutcome.recoveryRequired:
        setState(() => _needsRecovery = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'We couldn’t confirm this unlock. Check access before using another credit.',
            ),
            action: SnackBarAction(
              label: 'Check access',
              onPressed: _checkUnlockAccess,
            ),
          ),
        );
    }
  }

  /// Recover a lost acknowledgement using reads only. Missing/failed evidence
  /// never authorises another spend; a confirmed permanent row restores access.
  Future<void> _checkUnlockAccess() async {
    if (!_lifetimeCurrent || _busy || !(_route?.isCurrent ?? false)) return;
    final request = ++_unlockRequest;
    setState(() => _busy = true);
    final recoveringSpend = _needsRecovery;
    final overall = await ZyraUnlockService.confirmOwnedAccess(
      widget.profile.id,
      UnlockTier.standard,
    );
    if (!mounted || !_lifetimeCurrent || request != _unlockRequest) return;
    final confirmed = ZyraUnlockService.isUnlocked(
      widget.profile.id,
      ZyraUnlockService.currentTier,
    );
    setState(() {
      _busy = false;
      _accessUnavailable = overall == null;
      _needsRecovery = recoveringSpend && !confirmed;
    });
    _loadBalance();
    if (overall == true) {
      _loadGuardians();
      _loadRealScore();
    }
    if (overall == null || (recoveringSpend && !confirmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access hasn’t been confirmed yet. No new unlock was requested.',
          ),
        ),
      );
    }
  }

  /// Founder-authorized demonstration, not a live unlock transaction.
  /// Recheck the owner/authority at invocation, including saved callbacks.
  void _unlockPreview() {
    if (!_lifetimeCurrent ||
        !_isDeveloperPreview ||
        !(_route?.isCurrent ?? false) ||
        _previewPlusUnlocked ||
        _previewPlus < 1 ||
        _busy) {
      return;
    }
    setState(() {
      _previewPlusUnlocked = true;
      _previewPlus--;
      _balance = {ZyraUnlockService.currentTier: _previewPlus};
    });
    _loadRealScore();
  }

  @override
  Widget build(BuildContext context) {
    if (!_lifetimeCurrent) {
      return Scaffold(
        key: const ValueKey('compatibility-account-expired'),
        appBar: AppBar(title: const Text('Compatibility')),
      );
    }
    if (_sampleMode && !_isDeveloperPreview) {
      return Scaffold(
        key: const ValueKey('compatibility-preview-denied'),
        appBar: AppBar(title: const Text('Compatibility')),
      );
    }
    final name = widget.profile.firstName;

    // Production values are straight from the ledger. The isolated sample
    // route alone reads the local balances selected in its developer toggle.
    // Previously `ZyraDevScenario.instance.unlocks
    // .count` — an in-memory dev-panel enum, which meant the number on
    // screen and the number the server would enforce had no relationship
    // to each other. They are now the same number.
    //
    // ZYRA One's included credits are a grant row in the same ledger
    // (reason 'zyra_one_included'), not a constant added here, so the
    // count is already correct without special-casing the plan. Founder
    // rejected itemising where credits came from — that belongs on the buy
    // screen.
    final unlocksLeft = _balance[ZyraUnlockService.currentTier] ?? 0;

    // Plus is a SUPERSET of Unlock, so holding Plus unlocks the overall
    // number too. Not a convenience — the spec defines Plus as "everything
    // in Compatibility Unlock, plus area bands", and charging
    // again for the part they already bought would break the permanence
    // rule the unique index exists to enforce.
    final demoUnlocked = _isDeveloperPreview && _previewPlusUnlocked;
    final detailUnlocked = ZyraUnlockService.isUnlocked(
      widget.profile.id,
      UnlockTier.plus,
    );
    // journeyRevealed opens the overall exactly like a standard unlock —
    // the Journey already showed both people this number (see the field's
    // doc). It spends nothing and writes nothing; the ledger is untouched.
    final overallUnlocked =
        demoUnlocked ||
        detailUnlocked ||
        widget.journeyRevealed ||
        ZyraUnlockService.isUnlocked(widget.profile.id, UnlockTier.standard);
    final needsCheck =
        overallUnlocked &&
        _topics?.state == ZyraCompatibilityTopicsState.needsReconfirmation;
    final checkedScore = overallUnlocked && _checkedFromResult
        ? _topics?.overallScore
        : null;

    return DecoratedBox(
      decoration: ZyraAppGoldDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          title: needsCheck || checkedScore != null
              ? null
              : Text('Compatibility', style: ZyraText.heading(size: 17)),
          iconTheme: const IconThemeData(color: Colors.white70),
        ),
        body: needsCheck || checkedScore != null
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: needsCheck
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Compatibility score',
                              style: ZyraText.heading(size: 26),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ZyraCompatibilityCheckCard(
                                personName: name,
                                onCheck: _checking || _loadingScore
                                    ? null
                                    : _checkResultAnswers,
                              ),
                            ),
                          ],
                        )
                      : ZyraDraftCompatibilityPresentation(
                          personName: name,
                          balance: unlocksLeft,
                          overallScore: checkedScore!.round(),
                          revealed: true,
                          areaGate: _topics!.topicsLocked
                              ? const ZyraCompatibilityAreaGate(guardian: false)
                              : null,
                          areaBands: _topics!.areaBands,
                          showDemoGuardian: false,
                          guardian: detailUnlocked
                              ? _GuardianSection(
                                  unlocked: true,
                                  guardians: _guardians,
                                  firstName: name,
                                  gender: widget.profile.gender,
                                  lightSurface: true,
                                )
                              : null,
                        ),
                ),
              )
            : Container(
                // BoxConstraints.expand for the same reason as the report screen
                // and transition_screen: the Scaffold background is now the gender
                // gradient's first stop, so a short page would show a band of flat
                // Rose Pink under the content.
                constraints: const BoxConstraints.expand(),
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      if (_resultReadFailed)
                        ZyraErrorBanner(
                          message:
                              'Could not load compatibility. Please try again.',
                          onRetry: () {
                            if (_route?.isCurrent == true && !_loadingScore) {
                              _loadRealScore(allowLegacy: !_checkedFromResult);
                            }
                          },
                        ),
                      Text('You and $name', style: ZyraText.heading(size: 22)),
                      const SizedBox(height: 4),
                      Text(
                        _isDeveloperPreview
                            ? 'Try Compatibility with a sample profile. Demo results '
                                  'are not calculated from anyone’s answers.'
                            : 'Built from what you both already told ZYRA. Neither of you '
                                  'sees the other’s answers.',
                        style: ZyraText.subtext(size: 12.5),
                      ),
                      const SizedBox(height: 20),

                      // ONE card, two sections, one divider. A card each would put
                      // a gap between them and read as two unrelated offers; the
                      // whole point of the single page is that the second section
                      // is the inside of the first.
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Section(
                              label: 'OVERALL',
                              // `left: null` while the ledger is still loading.
                              // Showing 0 would render "none left" for a moment to
                              // someone who has five — the exact complaint that
                              // started this screen's rebuild, reintroduced by the
                              // move to an async balance. The corner stays empty
                              // until the real number arrives.
                              left: null,
                              unlocked: overallUnlocked,
                              busy: _busy,
                              child: overallUnlocked
                                  ? _OverallResult(
                                      score: _realScore,
                                      loading: _loadingScore,
                                    )
                                  : _OverallLocked(name: name),
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.14),
                              height: 1,
                              thickness: 1,
                            ),
                            _Section(
                              label: 'EVERY AREA',
                              left:
                                  (_loadingBalance ||
                                      _balanceUnavailable ||
                                      _accessUnavailable ||
                                      _needsRecovery)
                                  ? null
                                  : unlocksLeft,
                              unlocked: demoUnlocked || detailUnlocked,
                              busy: _busy,
                              buttonLabel: 'Unlock Compatibility',
                              recoveryLabel:
                                  _needsRecovery || _accessUnavailable
                                  ? 'Check access'
                                  : _balanceUnavailable
                                  ? 'Check balance'
                                  : null,
                              buttonIcon: Icons.lock_open_outlined,
                              readOnlyRecovery:
                                  _needsRecovery ||
                                  _accessUnavailable ||
                                  _balanceUnavailable,
                              // The local fixture never calls a transaction service.
                              // Ordinary full-detail attempts retain both spend fuses.
                              onUnlock: _needsRecovery || _accessUnavailable
                                  ? _checkUnlockAccess
                                  : _balanceUnavailable
                                  ? _checkBalance
                                  : _isDeveloperPreview
                                  ? _unlockPreview
                                  : ZyraUnlockService.isTierAvailable(
                                      ZyraUnlockService.currentTier,
                                    )
                                  ? _unlock
                                  : null,
                              child: _Detail(
                                unlocked: detailUnlocked,
                                developerPreview: _isDeveloperPreview,
                                demoBands: demoUnlocked
                                    ? ZyraCompatibilityDemo.bandsFor(
                                        widget.profile.id,
                                      )
                                    : null,
                                guardians: _guardians,
                                firstName: name,
                                gender: widget.profile.gender,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// One half of the card: a header with the balance in the corner, a body,
/// and either an unlock button or the unlocked marker.
class _Section extends StatelessWidget {
  final String label;

  /// Credits remaining, or null while the ledger is still loading.
  final int? left;
  final bool unlocked;
  final String? buttonLabel;
  final String? recoveryLabel;
  final IconData? buttonIcon;
  final bool busy;
  final bool readOnlyRecovery;
  final VoidCallback? onUnlock;
  final Widget child;

  const _Section({
    required this.label,
    required this.left,
    required this.unlocked,
    this.buttonLabel,
    this.recoveryLabel,
    this.buttonIcon,
    required this.busy,
    this.readOnlyRecovery = false,
    this.onUnlock,
    required this.child,
  }) : assert(onUnlock == null || (buttonLabel != null && buttonIcon != null));

  String? get _actionLabel => recoveryLabel ?? buttonLabel;

  /// Plain words, Founder's choice. "none left" rather than "0 left"
  /// because a zero in a corner reads as a score, not a stock level.
  ///
  /// null renders NOTHING, not "none left" — the balance is still loading
  /// and claiming zero would be a lie the user has already caught once.
  String? get _balance => switch (left) {
    null => null,
    0 => 'none left',
    1 => '1 left',
    final n => '$n left',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: ZyraText.chapterLabel(color: Colors.white),
                ),
              ),
              // The count disappears once unlocked. It answers "can I
              // afford this", and there is nothing left to afford.
              if (!unlocked &&
                  !readOnlyRecovery &&
                  onUnlock != null &&
                  _balance != null)
                Text(
                  _balance!,
                  style: ZyraText.subtext(
                    size: 11.5,
                    color: Colors.white.withValues(
                      alpha: left == 0 ? 0.40 : 0.75,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
          if (!unlocked && onUnlock != null) ...[
            const SizedBox(height: 14),
            ZyraGoldActionPill(
              // Disabled at zero rather than relabelled. The corner already
              // says why, and the foot link says what to do — swapping this
              // to a buy button would put the same offer on screen twice.
              // `left == null` means the balance has not arrived yet.
              // Disabled until it does — an enabled button whose result we
              // cannot predict is worse than a brief dim one.
              key: ValueKey<String>('compatibility-unlock-$_actionLabel'),
              label: _actionLabel!,
              icon: readOnlyRecovery ? Icons.refresh_rounded : buttonIcon!,
              busy: busy,
              onPressed:
                  (busy || (!readOnlyRecovery && (left == null || left == 0)))
                  ? null
                  : onUnlock,
            ),
          ],
        ],
      ),
    );
  }
}

/// Locked overall — the shape of the answer, with the number withheld.
///
/// REPLACES a widget that hardcoded "You have none left" regardless of
/// balance, which is how the Founder saw that sentence while the dev panel
/// held five credits. The balance is now stated once, in the section
/// header, by the code that actually knows it. This widget says nothing
/// about stock at all — that is why it cannot be wrong about it again.
class _OverallLocked extends StatelessWidget {
  final String name;
  const _OverallLocked({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.lock_outline,
          size: 20,
          color: Colors.white.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Your overall compatibility with $name.',
            style: ZyraText.body(size: 14, color: Colors.white),
          ),
        ),
        Text('__%', style: ZyraText.heading(size: 26, color: Colors.white24)),
      ],
    );
  }
}

/// Shows the caller-owned overall result independently of area access.
class _OverallResult extends StatelessWidget {
  /// THE REAL FIGURE, at last — OA-ZYRA-192, unblocked by OA-ZYRA-193 on
  /// 2026-08-11. This showed `_Sample.overall` — a constant 81% — to every
  /// Seeker for every profile, while taking a real credit for it. The
  /// transaction was real and the number was not.
  ///
  /// It is the SIGNED-IN Seeker's own figure, per decision (a2): how well
  /// this person's answers fit what you said you were looking for. The other
  /// person has their own, and it is not yours to see.
  final double? score;
  final bool loading;

  const _OverallResult({required this.score, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Text('Working it out…', style: ZyraText.subtext(size: 13));
    }

    // Withheld access, a failed read and an unscoreable pair all withhold the
    // figure. None proves a particular missing-answer cause to the client.
    if (score == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('—', style: ZyraText.heading(size: 44, color: Colors.white38)),
          const SizedBox(height: 6),
          Text(
            'Your compatibility score isn’t available right now.',
            style: ZyraText.subtext(size: 12.5),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('${score!.round()}%', style: ZyraText.heading(size: 44)),
        const SizedBox(width: 12),
        Text('aligned', style: ZyraText.subtext(size: 13)),
      ],
    );
  }
}

/// Area access and Guardian disclosure stay independent of the
/// overall result. A real Plus grant admits the area list with no band data
/// until the trusted result is wired. Demo bands come only from the caller.
class _Detail extends StatelessWidget {
  final bool unlocked;
  final bool developerPreview;
  final Map<ZyraCompatibilityArea, ZyraCompatibilityBand>? demoBands;

  /// Guardians of the profile being viewed, or null while locked/unknown.
  /// An empty list is a real answer — "No Guardian linked" — not a gap.
  final List<GuardianInfo>? guardians;

  /// Whose Guardians these are, for the section copy.
  final String firstName;

  /// Their gender, so the copy says his/her rather than always "her".
  final String? gender;

  const _Detail({
    required this.unlocked,
    required this.developerPreview,
    this.demoBands,
    required this.guardians,
    required this.firstName,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final demoUnlocked = demoBands != null;
    final unavailable = unlocked || demoUnlocked
        ? ZyraCompatibilityBand.notEnoughAnswers
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (developerPreview) ...[
          const _DemoNotice(),
          const SizedBox(height: 14),
        ],
        if (!demoUnlocked) ...[
          Text(
            developerPreview
                ? 'Unlock Compatibility to reveal the sample result.'
                : 'Detailed compatibility isn’t available yet.',
            key: const ValueKey('compatibility-detail-unavailable'),
            style: ZyraText.subtext(size: 12.5),
          ),
          const SizedBox(height: 14),
        ],
        Column(
          key: demoUnlocked
              ? const ValueKey('compatibility-demo-result')
              : null,
          children: [
            for (final area in ZyraCompatibilityArea.values)
              ZyraCompatibilityAreaRow(
                key: ValueKey('compatibility-area-row-${area.name}'),
                area: area,
                band: demoBands?[area] ?? unavailable,
              ),
          ],
        ),
        if (demoUnlocked)
          const _DemoGuardian()
        else
          _GuardianSection(
            unlocked: unlocked,
            guardians: guardians,
            firstName: firstName,
            gender: gender,
          ),
      ],
    );
  }
}

/// Render the locked and unavailable real area states without loading access.
@visibleForTesting
Widget buildZyraCompatibilityBreakdownTestSurface({bool unlocked = true}) =>
    _Detail(
      unlocked: unlocked,
      developerPreview: false,
      guardians: [],
      firstName: 'Hana',
      gender: 'female',
    );

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('compatibility-demo-notice'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ZyraColors.journeyGold.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Developer demo',
          style: ZyraText.body(size: 12, color: ZyraColors.goldText),
        ),
        const SizedBox(height: 4),
        Text(
          'Sample values, not calculated from answers or the final scoring '
          'rules. No real unlocks are used.',
          style: ZyraText.subtext(size: 11.5),
        ),
      ],
    ),
  );
}

class _DemoGuardian extends StatelessWidget {
  const _DemoGuardian();

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('compatibility-demo-guardian'),
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
        const SizedBox(height: 14),
        Text('GUARDIAN EXAMPLE', style: ZyraText.chapterLabel()),
        const SizedBox(height: 10),
        Text('Demo Guardian · Father', style: ZyraText.body(size: 13)),
        const SizedBox(height: 4),
        Text(
          'Main Guardian · Fictional example',
          style: ZyraText.subtext(size: 11.5),
        ),
      ],
    ),
  );
}

/// Guardian visibility — Founder decision, 2026-08-05: "I want the Guardian
/// to be visible. Show the Guardian's details, not just the relationship…
/// if no Guardian is linked, I want that shown honestly rather than hiding
/// the row. I don't want the UI to obscure or infer this information."
///
/// Consent is taken at onboarding and the Privacy Policy / Terms name
/// exactly what an unlock reveals, with solicitor review before launch.
///
/// Plus tier only, matching `guardians_for_unlocked()`, which will return
/// nothing for a standard unlock however this widget is called. Locked, it
/// keeps the same padlock treatment as every row above it. Previously held
/// Plus rows retain this real disclosure while new Plus spending is fused.
class _GuardianSection extends StatelessWidget {
  final bool unlocked;
  final List<GuardianInfo>? guardians;
  final String firstName;
  final bool lightSurface;

  /// The viewed profile's gender — 'male' | 'female' | null.
  ///
  /// ADDED 2026-08-06. The sentence below said "her Journey" for everyone,
  /// so viewing Tariq read "Tariq has 2 Guardians involved in her Journey."
  /// Founder: "Tariq would be a man, so make sure the app knows the wording
  /// to differentiate between man and woman."
  ///
  /// Worth noting WHY it was hardcoded: this screen only ever shows the
  /// opposite gender to the viewer, so on a female Seeker's device every
  /// profile is male and on a male Seeker's every profile is female. It
  /// reads correctly for exactly half the users and wrongly for the other
  /// half — the kind of bug that survives testing on one account.
  final String? gender;

  const _GuardianSection({
    required this.unlocked,
    required this.guardians,
    required this.firstName,
    required this.gender,
    this.lightSurface = false,
  });

  /// his / her / their. Falls back to "their" rather than guessing — an
  /// unknown gender is not a reason to misgender someone.
  String get _possessive => ZyraGender.possessive(gender);

  @override
  Widget build(BuildContext context) {
    final list = guardians;
    final ink = lightSurface ? ZyraColors.espresso : Colors.white;
    final muted = lightSurface ? ZyraColors.secondaryText : null;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: ink.withValues(alpha: 0.10), height: 1),
          const SizedBox(height: 14),
          Text(
            'GUARDIAN',
            style: ZyraText.chapterLabel(color: muted ?? Colors.white54),
          ),
          const SizedBox(height: 10),

          if (!unlocked || list == null)
            // Same visual language as the locked category rows above.
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: ink.withValues(alpha: 0.35),
                ),
              ],
            )
          else if (list.isEmpty)
            // Stated plainly, per the decision above. Not softened, not
            // hidden, and not inferred from silence.
            Text(
              'No Guardian linked.',
              style: ZyraText.body(
                size: 14,
                color: ink.withValues(alpha: 0.85),
              ),
            )
          else ...[
            for (final g in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: ink.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        g.displayLine,
                        style: ZyraText.body(size: 14, color: ink),
                      ),
                    ),
                    if (g.isMain)
                      Text(
                        'Main',
                        style: ZyraText.subtext(size: 11.5, color: muted),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              list.length == 1
                  ? '$firstName has a Guardian involved in $_possessive Journey.'
                  : '$firstName has ${list.length} Guardians involved in $_possessive Journey.',
              style: ZyraText.subtext(size: 12, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}
