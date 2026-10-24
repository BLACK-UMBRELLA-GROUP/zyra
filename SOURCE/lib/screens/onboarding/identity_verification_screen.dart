// Mandatory identity-verification step — DR-ZYRA-220/221, OA-ZYRA-266.
//
// Phase A owns the exact consent surface, coarse-state presentation and the
// fail-closed navigation boundary. It contains no provider SDK and no local
// production "verified" switch. Developer state never leaves this widget.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/help_content.dart';
import '../../dev/zyra_founder_launch_review.dart';
import '../../dev/zyra_one_journey_settings_details.dart';
import '../../models/zyra_identity_verification.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_identity_verification_service.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_onboarding_direction_style.dart';
import '../../widgets/zyra_onboarding_continue_action.dart';
import '../settings/privacy_and_data_screen.dart';
import '../settings/help_support_screen.dart';
import '../welcome_screen.dart';

const String kIdentityVerificationConsentTitle = 'Verify your identity';
const String kIdentityVerificationConsentBody =
    'ZYRA checks that every member is a real, unique person. You\'ll '
    'photograph your ID document and take a short selfie. Our verification '
    'partner (Sumsub) processes your document and face data on its own '
    'systems to confirm your identity and that you don\'t already have a '
    'ZYRA account — ZYRA never stores your document, your selfie, or your '
    'face data; we only receive the result. This uses biometric data, and '
    'we need your explicit consent.';

class InitialIdentityCheckScreen extends StatefulWidget {
  final bool devPreview;
  final ZyraIdentityVerificationState? initialState;
  final bool requireDuplicateResolution;
  final Future<String?> Function()? finalizeOnboarding;
  final Future<void> Function(BuildContext context)? onContinue;

  /// Local rehearsal only. This never grants an identity result or calls the
  /// production finalizer; the owning preview route supplies its destination.
  final Future<void> Function(BuildContext context)? onDevSkip;

  const InitialIdentityCheckScreen({
    super.key,
    this.devPreview = false,
    this.initialState,
    this.requireDuplicateResolution = false,
    this.finalizeOnboarding,
    this.onContinue,
    this.onDevSkip,
  });

  @override
  State<InitialIdentityCheckScreen> createState() =>
      _InitialIdentityCheckScreenState();
}

class _InitialIdentityCheckScreenState
    extends State<InitialIdentityCheckScreen> {
  late final Listenable _boundaryChanges = Listenable.merge([
    ZyraDeveloperAccess.authorizationChanges,
    AppState.instance,
  ]);
  ZyraIdentityVerificationState? _state;
  bool _busy = false;
  bool _attemptDeleted = false;
  ZyraVerificationLaunchOutcome? _launchOutcome;
  String? _screenUserId;
  String? _error;
  late final bool _previewMode;
  late final bool _duplicateResolution;
  late final Future<String?> Function()? _openingFinalizer;
  late final Future<void> Function(BuildContext)? _openingContinue;
  late final Future<void> Function(BuildContext)? _openingSkip;
  bool _modeRevoked = false;
  bool _previewRevoked = false;
  final _openingAccountGeneration = ZyraAccountState.generation;

  // Isolation follows the requested mode, not current capability. Losing
  // capability must deny the preview rather than enable live IDV/sign-out.
  bool get _isDevPreview => _previewMode;

  void _observePreviewBoundary() {
    if (_isDevPreview && !ZyraDeveloperAccess.canUseDeveloperTools) {
      _previewRevoked = true;
    }
  }

  bool get _providerUnavailable =>
      _launchOutcome == ZyraVerificationLaunchOutcome.unavailable ||
      (!_isDevPreview && !ZyraIdentityVerificationService.isProviderConfigured);

  bool get _hasOriginalPrincipal =>
      mounted &&
      !_modeRevoked &&
      widget.devPreview == _previewMode &&
      widget.requireDuplicateResolution == _duplicateResolution &&
      (_isDevPreview
          ? _openingAccountGeneration == ZyraAccountState.generation &&
                !_previewRevoked &&
                ZyraDeveloperAccess.canUseDeveloperTools
          : ZyraIdentityVerificationService.isCurrentPrincipal(_screenUserId));

  bool get _showsSignupAccountExit =>
      !_isDevPreview && !widget.requireDuplicateResolution;

  bool _guardPrincipal() {
    if (!mounted) return false;
    if (_isDevPreview && !ZyraDeveloperAccess.canUseDeveloperTools) {
      return false;
    }
    if (_hasOriginalPrincipal) return true;
    setState(() {
      _busy = false;
      _error = 'Your sign-in has changed. Close and reopen ZYRA to continue.';
    });
    return false;
  }

  bool get _routeCurrent =>
      mounted && (ModalRoute.of(context)?.isCurrent ?? false);

  bool _allowsState(ZyraIdentityVerificationState? state) {
    if (!_hasOriginalPrincipal) return false;
    return widget.requireDuplicateResolution
        ? state?.allowsActiveJourney == true
        : state?.allowsApp == true;
  }

  @override
  void initState() {
    super.initState();
    _previewMode = widget.devPreview;
    _duplicateResolution = widget.requireDuplicateResolution;
    _openingFinalizer = widget.finalizeOnboarding;
    _openingContinue = widget.onContinue;
    _openingSkip = widget.onDevSkip;
    _observePreviewBoundary();
    ZyraDeveloperAccess.authorizationChanges.addListener(
      _observePreviewBoundary,
    );
    _screenUserId = _isDevPreview ? null : ZyraAuth.currentUser?.id;
    _state = widget.initialState;
    _recordIdentityEvent(
      ZyraTelemetryEventName.opened,
      action: ZyraTelemetryAction.pageView,
    );
  }

  @override
  void didUpdateWidget(covariant InitialIdentityCheckScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.devPreview != _previewMode ||
        widget.requireDuplicateResolution != _duplicateResolution) {
      _modeRevoked = true;
    }
  }

  @override
  void dispose() {
    ZyraDeveloperAccess.authorizationChanges.removeListener(
      _observePreviewBoundary,
    );
    super.dispose();
  }

  void _openPrivacy() {
    if (!mounted ||
        _busy ||
        !_hasOriginalPrincipal ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    final privacyGeneration = ZyraAccountState.generation;
    bool privacyOwnerCurrent() =>
        mounted &&
        privacyGeneration == ZyraAccountState.generation &&
        _hasOriginalPrincipal;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IdentityVerificationPrivacyScreen(
          devPreview: _isDevPreview,
          canAct: privacyOwnerCurrent,
        ),
      ),
    );
  }

  ZyraIdentityVerificationState _devState(
    ZyraIdentityVerificationResult result, {
    ZyraDuplicateReviewState duplicate = ZyraDuplicateReviewState.notEvaluated,
    bool consentGranted = true,
  }) {
    final now = DateTime.now().toUtc();
    return ZyraIdentityVerificationState(
      result: result,
      duplicateReview: duplicate,
      consentGranted: consentGranted,
      consentVersion: kIdentityVerificationConsentVersion,
      consentRecordedAt: now,
      updatedAt: now,
      decidedAt: result == ZyraIdentityVerificationResult.verified ? now : null,
    );
  }

  Future<void> _recordConsent(bool granted) async {
    if (_busy || !_routeCurrent || !_guardPrincipal()) return;
    setState(() {
      _busy = true;
      _error = null;
      _launchOutcome = null;
    });
    final state = _isDevPreview
        ? _devState(
            granted
                ? ZyraIdentityVerificationResult.pending
                : ZyraIdentityVerificationResult.cancelled,
            consentGranted: granted,
          )
        : await ZyraIdentityVerificationService.recordConsent(
            granted: granted,
            expectedUserId: _screenUserId,
          );
    if (!_guardPrincipal()) return;
    if (state == null) {
      setState(() {
        _busy = false;
        _error = "We couldn't save your choice. Please try again.";
      });
      return;
    }
    setState(() {
      _busy = false;
      _state = state;
      _attemptDeleted = false;
    });
    if (granted) await _launchProvider();
  }

  Future<void> _launchProvider() async {
    if (_busy || !_routeCurrent || !_guardPrincipal()) return;
    _recordIdentityEvent(ZyraTelemetryEventName.started);
    setState(() {
      _busy = true;
      _error = null;
      _launchOutcome = null;
    });
    ZyraVerificationLaunchOutcome outcome;
    try {
      outcome = _isDevPreview
          ? ZyraVerificationLaunchOutcome.unavailable
          : await ZyraIdentityVerificationService.launchProvider();
    } catch (error) {
      // An adapter exception is a launch failure, not progress. Never log
      // provider payloads, documents, tokens or identifying exception text.
      debugPrint('ZYRA: identity check launch failed (${error.runtimeType}).');
      outcome = ZyraVerificationLaunchOutcome.failed;
    }
    if (!_guardPrincipal()) return;
    setState(() {
      _busy = false;
      _launchOutcome = outcome;
    });
    if (outcome != ZyraVerificationLaunchOutcome.launched) {
      _recordIdentityEvent(ZyraTelemetryEventName.failed);
    }
    if (outcome == ZyraVerificationLaunchOutcome.launched) await _refresh();
  }

  Future<void> _refresh() async {
    if (_busy || _isDevPreview || !_routeCurrent || !_guardPrincipal()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final state = await ZyraIdentityVerificationService.fetchMyState(
        expectedUserId: _screenUserId,
      );
      if (!_guardPrincipal()) return;
      setState(() {
        _busy = false;
        _state = state;
      });
      if (state == null) {
        _recordIdentityEvent(ZyraTelemetryEventName.failed);
      } else {
        _recordIdentityState(state);
      }
    } catch (_) {
      _recordIdentityEvent(ZyraTelemetryEventName.failed);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "We couldn't refresh your result. Please try again.";
      });
    }
  }

  void _recordIdentityState(ZyraIdentityVerificationState state) {
    if (state.result == ZyraIdentityVerificationResult.verified) {
      _recordIdentityEvent(ZyraTelemetryEventName.completed);
      return;
    }
    if (state.result == ZyraIdentityVerificationResult.failed ||
        state.result == ZyraIdentityVerificationResult.retryRequired ||
        state.result == ZyraIdentityVerificationResult.expired ||
        state.result == ZyraIdentityVerificationResult.cancelled) {
      _recordIdentityEvent(ZyraTelemetryEventName.failed);
    }
  }

  void _recordIdentityEvent(
    ZyraTelemetryEventName name, {
    ZyraTelemetryAction action = ZyraTelemetryAction.identityProvider,
  }) {
    if (_isDevPreview) return;
    ZyraProductTelemetry.instance.record(
      feature: ZyraTelemetryFeature.identityCheck,
      name: name,
      action: action,
      surface: ZyraTelemetrySurface.entry,
    );
  }

  Future<void> _continue() async {
    if (_busy || !_routeCurrent || !_guardPrincipal()) return;
    final allowed = _allowsState(_state);
    if (!allowed) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final error = await _openingFinalizer?.call();
      if (!_guardPrincipal()) return;
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      if (!mounted || !_routeCurrent) return;
      final onContinue = _openingContinue;
      if (onContinue != null) await onContinue(context);
    } catch (error) {
      debugPrint(
        'ZYRA: verified setup completion failed (${error.runtimeType}).',
      );
      if (mounted) {
        setState(() {
          _error = "We couldn't finish setup. Please try again.";
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _devSkip() async {
    final onSkip = _openingSkip;
    if (!_isDevPreview ||
        widget.requireDuplicateResolution ||
        onSkip == null ||
        _busy ||
        !_routeCurrent ||
        !_guardPrincipal()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Deliberately separate from _continue: no consent, provider result,
      // verified-state fixture, or signup finalisation is manufactured here.
      if (_guardPrincipal()) await onSkip(context);
    } catch (_) {
      if (mounted && ZyraDeveloperAccess.canUseDeveloperTools) {
        setState(() => _error = 'The preview could not continue. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _devSkipButton() => SizedBox(
    width: double.infinity,
    height: 42,
    child: TextButton(
      key: const ValueKey('identity_dev_skip'),
      onPressed: _busy ? null : _devSkip,
      child: Text(
        'Skip · DEV',
        style: ZyraText.button(size: 12, color: ZyraColors.journeyGold),
      ),
    ),
  );

  bool get _showDevSkip =>
      _isDevPreview &&
      !widget.requireDuplicateResolution &&
      _openingSkip != null &&
      ZyraDeveloperAccess.canUseDeveloperTools;

  Future<void> _leave({required bool deleteAttempt}) async {
    if (_busy || !_routeCurrent || !_guardPrincipal()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (deleteAttempt && !_isDevPreview && !_attemptDeleted) {
        final deleted =
            await ZyraIdentityVerificationService.deleteMyUnstartedAttempt(
              expectedUserId: _screenUserId,
            );
        if (!_guardPrincipal()) return;
        if (!deleted) {
          setState(() {
            _error = "We couldn't confirm deletion. Please try again.";
          });
          return;
        }
        _attemptDeleted = true;
      }
      if (!_guardPrincipal()) return;
      if (!_isDevPreview) {
        await ZyraAuth.signOut(expectedUserId: _screenUserId);
      }
      if (!mounted) return;
      if (_isDevPreview) {
        setState(() {
          _state = null;
        });
        return;
      }
      // Successful sign-out removes A's session. Never navigate over B if
      // another sign-in completed while cleanup was awaiting its stores.
      if (ZyraAuth.currentUser != null) {
        _guardPrincipal();
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } catch (error) {
      debugPrint('ZYRA: identity check exit failed (${error.runtimeType}).');
      if (!mounted) return;
      if (!_isDevPreview && ZyraAuth.currentUser == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      } else {
        setState(() {
          _error = _attemptDeleted
              ? 'Your verification attempt was deleted, but sign-out could not '
                    'be completed. Please try signing out again.'
              : "We couldn't finish signing out. Please try again.";
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setDevState(ZyraIdentityVerificationResult result) {
    if (!_isDevPreview || !_guardPrincipal()) return;
    setState(() {
      _launchOutcome = null;
      _error = null;
      _state = _devState(
        result,
        duplicate: result == ZyraIdentityVerificationResult.verified
            ? ZyraDuplicateReviewState.clear
            : result == ZyraIdentityVerificationResult.reviewRequired
            ? ZyraDuplicateReviewState.reviewRequired
            : ZyraDuplicateReviewState.notEvaluated,
        consentGranted: result != ZyraIdentityVerificationResult.cancelled,
      );
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _boundaryChanges,
    builder: (context, _) {
      if (_isDevPreview && !ZyraDeveloperAccess.canUseDeveloperTools) {
        return Scaffold(
          key: const ValueKey('identity_preview_denied'),
          backgroundColor: ZyraColors.modalSheetSurface,
          body: const SizedBox.expand(),
        );
      }
      return _buildIdentity(context);
    },
  );

  Widget _buildIdentity(BuildContext context) {
    final state = _state;
    final previewStyle = OnboardingPreviewStyle.effectiveStyleOf(context);
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient:
              previewStyle?.backgroundGradient ?? ZyraColors.brandGradient,
        ),
        child: SafeArea(
          child: !_hasOriginalPrincipal
              ? _buildSessionChanged()
              : state == null
              ? _buildConsent()
              : _buildState(state),
        ),
      ),
    );
  }

  Widget _buildSessionChanged() => Padding(
    key: const ValueKey('identity-session-changed'),
    padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'ZYRA',
            style: ZyraText.wordmark(
              size: 20,
              color: ZyraColors.splashWordmark,
            ),
          ),
        ),
        const Spacer(),
        const _IconMark(icon: Icons.lock_outline),
        const SizedBox(height: 22),
        Text('Your sign-in has changed.', style: ZyraText.heading(size: 28)),
        const SizedBox(height: 12),
        Text(
          'Close and reopen ZYRA to continue with your current account. '
          'No verification access has been granted from this page.',
          style: ZyraText.body(size: 14.2).copyWith(height: 1.5),
        ),
        const Spacer(),
      ],
    ),
  );

  Widget _buildConsent() => Padding(
    padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ZYRA',
              style: ZyraText.wordmark(
                size: 20,
                color: ZyraColors.splashWordmark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'IDENTITY CHECK',
                textAlign: TextAlign.right,
                style: ZyraText.chapterLabel(color: ZyraColors.ink(0.46)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IconMark(icon: Icons.verified_user_outlined),
                const SizedBox(height: 22),
                Text(
                  kIdentityVerificationConsentTitle,
                  style: ZyraText.heading(size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  kIdentityVerificationConsentBody,
                  style: ZyraText.body(size: 14.2).copyWith(height: 1.55),
                ),
                const SizedBox(height: 10),
                TextButton(
                  key: const ValueKey('identity-privacy-policy'),
                  onPressed: _busy ? null : _openPrivacy,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: ZyraColors.unlockText,
                  ),
                  child: Text(
                    'Privacy policy',
                    style: ZyraText.body(
                      size: 13,
                      color: ZyraColors.unlockText,
                    ),
                  ),
                ),
                if (_error != null) _ErrorText(_error!),
              ],
            ),
          ),
        ),
        if (_showDevSkip) _devSkipButton(),
        _PrimaryButton(
          key: const ValueKey('identity-consent-agree'),
          label: 'I agree — verify me',
          busy: _busy,
          onPressed: () => _recordConsent(true),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            key: const ValueKey('identity-consent-decline'),
            onPressed: _busy ? null : () => _recordConsent(false),
            child: Text(
              "I don't consent",
              style: ZyraText.button(size: 14, color: ZyraColors.ink(0.70)),
            ),
          ),
        ),
        if (_showsSignupAccountExit) _signupAccountExitButton(),
      ],
    ),
  );

  Widget _buildState(ZyraIdentityVerificationState state) {
    if (!state.consentGranted ||
        state.result == ZyraIdentityVerificationResult.cancelled) {
      return _buildRefusal();
    }
    final activeJourneyHold =
        state.allowsApp &&
        widget.requireDuplicateResolution &&
        !state.allowsActiveJourney;
    final presentation = _presentationFor(
      state,
      activeJourneyHold: activeJourneyHold,
      providerUnavailable: _providerUnavailable,
      launchOutcome: _launchOutcome,
    );
    final mayContinue = _allowsState(state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'ZYRA',
              style: ZyraText.wordmark(
                size: 20,
                color: ZyraColors.splashWordmark,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Expanded(
            child: ListView(
              children: [
                _IconMark(icon: presentation.icon),
                const SizedBox(height: 22),
                Text(presentation.title, style: ZyraText.heading(size: 28)),
                const SizedBox(height: 12),
                Text(
                  presentation.body,
                  style: ZyraText.body(size: 14.2).copyWith(height: 1.5),
                ),
                if (_error != null) _ErrorText(_error!),
                if (_isDevPreview) ...[
                  const SizedBox(height: 24),
                  _DevStateControls(
                    selected: state.result,
                    onSelected: _setDevState,
                  ),
                ],
              ],
            ),
          ),
          if (_showDevSkip) _devSkipButton(),
          if (mayContinue)
            if (_isDevPreview && ZyraOnboardingArrowScope.enabledOf(context))
              Center(
                child: ZyraOnboardingArrowAction(
                  key: const ValueKey('identity-continue'),
                  active: !_busy,
                  onPressed: _continue,
                  semanticLabel: widget.requireDuplicateResolution
                      ? 'Return to Journey'
                      : 'Continue to ZYRA',
                ),
              )
            else
              _PrimaryButton(
                key: const ValueKey('identity-continue'),
                label: widget.requireDuplicateResolution
                    ? 'Return to Journey'
                    : 'Continue to ZYRA',
                busy: _busy,
                onPressed: _continue,
              )
          else ...[
            if (state.result == ZyraIdentityVerificationResult.reviewRequired ||
                activeJourneyHold)
              _PrimaryButton(
                key: const ValueKey('identity-refresh'),
                label: 'Check again',
                busy: _busy,
                onPressed: _isDevPreview ? null : _refresh,
              )
            else
              _PrimaryButton(
                key: const ValueKey('identity-retry'),
                label:
                    state.result == ZyraIdentityVerificationResult.pending &&
                        !_providerUnavailable &&
                        _launchOutcome !=
                            ZyraVerificationLaunchOutcome.failed &&
                        _launchOutcome !=
                            ZyraVerificationLaunchOutcome.cancelled
                    ? 'Start or resume check'
                    : 'Try again',
                busy: _busy,
                onPressed: _launchProvider,
              ),
            if (state.result == ZyraIdentityVerificationResult.pending) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const ValueKey('identity-refresh'),
                  onPressed: _busy || _isDevPreview ? null : _refresh,
                  child: const Text('Check for a result'),
                ),
              ),
            ],
          ],
          if (_showsSignupAccountExit) _signupAccountExitButton(),
        ],
      ),
    );
  }

  Widget _buildRefusal() => Padding(
    padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'ZYRA',
            style: ZyraText.wordmark(
              size: 20,
              color: ZyraColors.splashWordmark,
            ),
          ),
        ),
        const Spacer(),
        const _IconMark(icon: Icons.lock_outline),
        const SizedBox(height: 22),
        Text('Verification is required.', style: ZyraText.heading(size: 28)),
        const SizedBox(height: 12),
        Text(
          'Without identity verification, a ZYRA account cannot be created '
          'and the app cannot open. You can return and consent, or delete '
          'this verification attempt.',
          style: ZyraText.body(size: 14.2).copyWith(height: 1.5),
        ),
        if (_error != null) _ErrorText(_error!),
        const Spacer(),
        if (_showDevSkip) _devSkipButton(),
        _PrimaryButton(
          key: const ValueKey('identity-return-to-consent'),
          label: 'Review consent again',
          busy: _busy,
          onPressed: () => setState(() {
            _state = null;
            _error = null;
          }),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            key: const ValueKey('identity-delete-attempt'),
            onPressed: _busy
                ? null
                : () => _leave(deleteAttempt: !_attemptDeleted),
            child: Text(
              _attemptDeleted
                  ? 'Use a different account'
                  : 'Delete verification attempt',
              style: ZyraText.button(size: 13, color: ZyraColors.ink(0.62)),
            ),
          ),
        ),
        if (_showsSignupAccountExit && !_attemptDeleted)
          _signupAccountExitButton(),
      ],
    ),
  );

  Widget _signupAccountExitButton() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        key: const ValueKey('identity-use-different-account'),
        onPressed: _busy ? null : () => _leave(deleteAttempt: false),
        child: Text(
          'Use a different account',
          style: ZyraText.button(size: 13, color: ZyraColors.ink(0.62)),
        ),
      ),
    ),
  );
}

({String title, String body, IconData icon}) _presentationFor(
  ZyraIdentityVerificationState state, {
  required bool activeJourneyHold,
  required bool providerUnavailable,
  required ZyraVerificationLaunchOutcome? launchOutcome,
}) {
  if (activeJourneyHold) {
    return (
      title: 'A review is still in progress.',
      body:
          'Your identity is confirmed, but the additional review required '
          'for an Active Journey has not finished. No other account details '
          'are shown to you. Your Journey remains safe and unchanged.',
      icon: Icons.manage_search_outlined,
    );
  }
  // Pending is also written when consent is recorded, before any capture.
  // The public state has no provider-start signal: neither consent, a local
  // launch callback nor an app restart proves that a check is in progress.
  final canStartCheck =
      !state.allowsApp &&
      state.result != ZyraIdentityVerificationResult.reviewRequired;
  if (canStartCheck &&
      providerUnavailable &&
      (state.result == ZyraIdentityVerificationResult.pending ||
          state.result == ZyraIdentityVerificationResult.retryRequired ||
          launchOutcome == ZyraVerificationLaunchOutcome.unavailable)) {
    return (
      title: 'Verification is unavailable.',
      body:
          'The identity check cannot open right now. Your identity has not '
          'been verified, and ZYRA remains locked. Please try again later.',
      icon: Icons.shield_outlined,
    );
  }
  if (canStartCheck && launchOutcome == ZyraVerificationLaunchOutcome.failed) {
    return (
      title: "The identity check couldn't open.",
      body:
          'Your identity has not been verified. Please try opening the '
          'check again. ZYRA remains locked.',
      icon: Icons.refresh_rounded,
    );
  }
  if (canStartCheck &&
      launchOutcome == ZyraVerificationLaunchOutcome.cancelled) {
    return (
      title: 'The identity check was closed.',
      body:
          'Your identity has not been verified. You can reopen the check '
          'when you are ready. ZYRA remains locked.',
      icon: Icons.refresh_rounded,
    );
  }
  return switch (state.result) {
    ZyraIdentityVerificationResult.pending => (
      title: "Your identity isn't verified yet.",
      body:
          'Complete the identity check to continue. If you have already '
          'submitted it, check for the latest result. ZYRA stays locked '
          'until verification is confirmed.',
      icon: Icons.verified_user_outlined,
    ),
    ZyraIdentityVerificationResult.verified => (
      title: 'Identity verified.',
      body:
          'Your verification result has been confirmed. ZYRA stores only '
          'this result and the minimal provider reference — never your ID '
          'document, selfie or face data.',
      icon: Icons.verified_outlined,
    ),
    ZyraIdentityVerificationResult.retryRequired => (
      title: "Let's try that again.",
      body:
          'No verification grant was made. Start the check again when you '
          'are ready; a retry does not count against you.',
      icon: Icons.refresh_rounded,
    ),
    ZyraIdentityVerificationResult.reviewRequired => (
      title: 'A manual review is needed.',
      body:
          'A trained reviewer will check the verification. This does not '
          'automatically reject or ban you, and ZYRA will not reveal any '
          'other account.',
      icon: Icons.manage_search_outlined,
    ),
    ZyraIdentityVerificationResult.failed => (
      title: "We couldn't verify your identity.",
      body:
          'No account access was granted. You can try the verification '
          'again; the result is neutral and no automatic ban is applied.',
      icon: Icons.shield_outlined,
    ),
    ZyraIdentityVerificationResult.expired => (
      title: 'This check expired.',
      body:
          'No account access was granted. Start a new check when you are '
          'ready.',
      icon: Icons.schedule_outlined,
    ),
    ZyraIdentityVerificationResult.cancelled => (
      title: 'Verification cancelled.',
      body: 'No account access was granted.',
      icon: Icons.lock_outline,
    ),
  };
}

class _IconMark extends StatelessWidget {
  final IconData icon;
  const _IconMark({required this.icon});

  @override
  Widget build(BuildContext context) {
    final previewStyle = OnboardingPreviewStyle.effectiveStyleOf(context);
    if (previewStyle != null) {
      return SizedBox(
        width: 70,
        height: 70,
        child: Stack(
          children: [
            OnboardingPreviewAccent(style: previewStyle, size: 70, progress: 1),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(icon, color: ZyraColors.unlockText, size: 19),
            ),
          ],
        ),
      );
    }
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyraColors.frostFill,
        border: Border.all(color: ZyraColors.unlockDot.withValues(alpha: 0.72)),
      ),
      child: Icon(icon, color: ZyraColors.unlockText, size: 25),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final previewStyle = OnboardingPreviewStyle.effectiveStyleOf(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: previewStyle?.primaryButtonStyle,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Text(
      text,
      style: ZyraText.subtext(size: 12, color: ZyraColors.destructive),
    ),
  );
}

class _DevStateControls extends StatelessWidget {
  final ZyraIdentityVerificationResult selected;
  final ValueChanged<ZyraIdentityVerificationResult> onSelected;

  const _DevStateControls({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final previewStyle = OnboardingPreviewStyle.maybeOf(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          previewStyle?.cardDecoration() ??
          BoxDecoration(
            color: ZyraColors.iconButtonBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ZyraColors.iconButtonBorder),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEVELOPER STATE · LOCAL ONLY',
            style: ZyraText.chapterLabel(color: ZyraColors.ink(0.46)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final result in ZyraIdentityVerificationResult.values)
                ChoiceChip(
                  key: ValueKey('identity-dev-${result.storageValue}'),
                  label: Text(result.storageValue.replaceAll('_', ' ')),
                  selected: selected == result,
                  onSelected: (_) => onSelected(result),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Temporary Phase A destination. It links to the truthful current summary
/// while making clear that the full app policy is not yet published.
class IdentityVerificationPrivacyScreen extends StatefulWidget {
  const IdentityVerificationPrivacyScreen({
    super.key,
    this.devPreview = false,
    this.canAct,
  });

  final bool devPreview;
  final bool Function()? canAct;

  @override
  State<IdentityVerificationPrivacyScreen> createState() =>
      _IdentityVerificationPrivacyScreenState();
}

class _IdentityVerificationPrivacyScreenState
    extends State<IdentityVerificationPrivacyScreen> {
  late final Listenable _boundaryChanges = Listenable.merge([
    ZyraDeveloperAccess.authorizationChanges,
    AppState.instance,
  ]);
  late final bool _preview = widget.devPreview;
  late final bool Function()? _openingGuard = widget.canAct;
  bool _revoked = false;

  bool get _available {
    if (!mounted || _revoked) return false;
    try {
      if (widget.devPreview != _preview ||
          !identical(widget.canAct, _openingGuard) ||
          (_openingGuard != null && !_openingGuard()) ||
          (_preview && !ZyraDeveloperAccess.canUseDeveloperTools)) {
        _revoked = true;
      }
    } catch (_) {
      _revoked = true;
    }
    return !_revoked;
  }

  void _observeBoundary() {
    _available;
  }

  @override
  void initState() {
    super.initState();
    _observeBoundary();
    _boundaryChanges.addListener(_observeBoundary);
  }

  @override
  void dispose() {
    _boundaryChanges.removeListener(_observeBoundary);
    super.dispose();
  }

  void _back() {
    if (!_available || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    Navigator.of(context).maybePop();
  }

  void _openSummary() {
    if (!_available || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    bool ownerCurrent() => _available;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          if (!_available) return const SizedBox.shrink();
          return _preview
              ? _IdentityPrivacyPreviewDestination(canAct: ownerCurrent)
              : const PrivacyAndDataScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _boundaryChanges,
    builder: (context, _) => _available
        ? _page(context)
        : const Scaffold(
            key: ValueKey('identity_privacy_unavailable'),
            body: SizedBox.expand(),
          ),
  );

  Widget _page(BuildContext context) {
    final previewStyle = OnboardingPreviewStyle.effectiveStyleOf(context);
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient:
              previewStyle?.backgroundGradient ?? ZyraColors.brandGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            key: const ValueKey('identity_privacy_scroll'),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Back',
                  key: const ValueKey('identity_privacy_back'),
                  onPressed: _back,
                  icon: Icon(Icons.chevron_left, color: ZyraColors.ink(0.70)),
                ),
                const SizedBox(height: 22),
                if (previewStyle != null) ...[
                  OnboardingPreviewAccent(
                    style: previewStyle,
                    size: 50,
                    progress: 1,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Identity verification privacy',
                  style: ZyraText.heading(size: 27),
                ),
                const SizedBox(height: 12),
                Text(
                  'The full Privacy Policy is being prepared. In this flow, '
                  'Sumsub processes the ID document, selfie and face data on '
                  'its systems. ZYRA is designed to retain only the consent '
                  'record, provider reference, coarse result, duplicate-review '
                  'flag and timestamps.',
                  style: ZyraText.body(size: 14).copyWith(height: 1.5),
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  key: const ValueKey('identity_privacy_summary'),
                  onPressed: _openSummary,
                  child: Text(
                    _preview
                        ? 'Privacy Policy availability'
                        : 'Read current privacy & data summary',
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

// Detached protected document/FAQ routes. They never mount ordinary privacy,
// account contact, safety-case or telemetry surfaces to make rehearsal look live.
class _IdentityPrivacyPreviewDestination extends StatefulWidget {
  const _IdentityPrivacyPreviewDestination({
    required this.canAct,
    this.help = false,
  });
  final bool Function() canAct;
  final bool help;

  @override
  State<_IdentityPrivacyPreviewDestination> createState() =>
      _IdentityPrivacyPreviewDestinationState();
}

class _IdentityPrivacyPreviewDestinationState
    extends State<_IdentityPrivacyPreviewDestination> {
  late final Listenable _boundaryChanges = Listenable.merge([
    ZyraDeveloperAccess.authorizationChanges,
    AppState.instance,
  ]);
  late final bool Function() _openingGuard = widget.canAct;
  late final bool _help = widget.help;
  bool _revoked = false;

  bool get _available {
    if (!mounted || _revoked) return false;
    try {
      if (!identical(widget.canAct, _openingGuard) ||
          widget.help != _help ||
          !_openingGuard() ||
          !ZyraDeveloperAccess.canUseDeveloperTools) {
        _revoked = true;
      }
    } catch (_) {
      _revoked = true;
    }
    return !_revoked;
  }

  void _observeBoundary() {
    _available;
  }

  @override
  void initState() {
    super.initState();
    _observeBoundary();
    _boundaryChanges.addListener(_observeBoundary);
  }

  @override
  void dispose() {
    _boundaryChanges.removeListener(_observeBoundary);
    super.dispose();
  }

  bool get _canNavigate =>
      _available && (ModalRoute.of(context)?.isCurrent ?? false);

  void _back() {
    if (_canNavigate) Navigator.of(context).maybePop();
  }

  void _openHelp() {
    if (!_canNavigate || _help) return;
    bool ownerCurrent() => _available;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _IdentityPrivacyPreviewDestination(
          canAct: ownerCurrent,
          help: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _boundaryChanges,
    builder: (context, _) {
      if (!_available) {
        return const Scaffold(
          key: ValueKey('identity_preview_privacy_unavailable'),
          body: SizedBox.expand(),
        );
      }
      final pending = const ZyraFounderLaunchReview().pendingFor(
        _help ? null : 'detail_privacyPolicy',
        internalReview: true,
      );
      final white = pending.isNotEmpty;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: white ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: white ? Colors.white : ZyraColors.luxuryDarkPurple,
          appBar: AppBar(
            backgroundColor: white ? Colors.white : ZyraColors.luxuryDarkPurple,
            leading: IconButton(
              key: const ValueKey('identity_preview_privacy_back'),
              tooltip: 'Back',
              onPressed: _back,
              icon: Icon(
                Icons.chevron_left,
                color: white
                    ? ZyraFounderLaunchPageStyle.darkGoldInk
                    : ZyraColors.journeyGold,
              ),
            ),
          ),
          body: _help
              ? HelpSupportScreen.preview(
                  canAct: () => _available,
                  categories: const [
                    ZyraHelpCategory('Privacy guidance', [
                      ZyraHelpEntry(
                        'Is this the formal Privacy Policy?',
                        'No. This is an explanation of current availability, not a published policy or a record of acceptance.',
                      ),
                      ZyraHelpEntry(
                        'Does opening this page share my verification data?',
                        'This preview does not start verification, request consent or send a support message.',
                      ),
                    ]),
                  ],
                )
              : ZyraFounderLaunchPageStyle(
                  pending: pending,
                  child: ZyraConceptSettingsDetailPresentation(
                    detail: ZyraConceptSettingsDetail.privacyPolicy,
                    guardian: false,
                    onHelp: _openHelp,
                  ),
                ),
        ),
      );
    },
  );
}
