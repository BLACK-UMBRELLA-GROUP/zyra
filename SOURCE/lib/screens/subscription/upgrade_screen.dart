// The historical route name remains compatible with callers. This page is
// the truthful membership control centre: it shows current access, explains
// available plans, and hands store-owned changes to the App Store / Play
// subscription centre. It never mutates an entitlement locally.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';
import '../../dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/zyra_membership_catalog.dart';
import '../../models/zyra_signup_membership_choice.dart';
import '../../widgets/zyra_membership_choices.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_initial_signup_draft_service.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../services/zyra_unlock_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_card_metrics.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../settings/legal_document_screen.dart';

typedef MembershipStoreLauncher = Future<bool> Function(Uri uri);

class UpgradeScreen extends StatefulWidget {
  final ZyraTelemetrySurface telemetrySurface;
  final MembershipStoreLauncher? openStore;
  final TargetPlatform? storePlatform;
  final bool compatibilityOnly;
  final bool _embeddedStore;

  const UpgradeScreen({
    super.key,
    this.telemetrySurface = ZyraTelemetrySurface.seeker,
    this.openStore,
    this.storePlatform,
  }) : compatibilityOnly = false,
       _embeddedStore = false;

  const UpgradeScreen._compatibilityStore({
    this.telemetrySurface = ZyraTelemetrySurface.seeker,
    bool embedded = false,
  }) : openStore = null,
       storePlatform = null,
       compatibilityOnly = true,
       _embeddedStore = embedded;

  static final appleSubscriptionsUri = Uri.parse(
    'https://apps.apple.com/account/subscriptions',
  );
  static final playSubscriptionsUri = Uri.parse(
    'https://play.google.com/store/account/subscriptions',
  );

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

/// The one purchase destination for Compatibility Unlock credits.
/// Membership remains discoverable separately and never acts as an indirect
/// scroll-to route for these one-off purchases.
class CompatibilityUnlockStoreScreen extends StatelessWidget {
  final ZyraTelemetrySurface telemetrySurface;

  const CompatibilityUnlockStoreScreen({
    super.key,
    this.telemetrySurface = ZyraTelemetrySurface.seeker,
  });

  @override
  Widget build(BuildContext context) =>
      UpgradeScreen._compatibilityStore(telemetrySurface: telemetrySurface);
}

/// Inline catalogue with the same independent account/balance lifetime as the
/// standalone store. Membership navigation never supplies a guessed balance.
class CompatibilityUnlockStoreContent extends StatelessWidget {
  const CompatibilityUnlockStoreContent({
    super.key,
    this.telemetrySurface = ZyraTelemetrySurface.seeker,
  });

  final ZyraTelemetrySurface telemetrySurface;

  @override
  Widget build(BuildContext context) => UpgradeScreen._compatibilityStore(
    telemetrySurface: telemetrySurface,
    embedded: true,
  );
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  late ZyraMembershipDraft _membershipDraft;
  ZyraMembershipReviewRequest? _membershipReview;
  String? _membershipOwnerAtOpen;
  late int _membershipGenerationAtOpen;
  late ZyraTelemetrySurface _membershipSurfaceAtOpen;
  late bool _membershipPreviewAtOpen;
  bool _membershipExpired = false;
  int _membershipRevision = 0;
  ZyraSignupMembershipIntent? _signupChoice;
  String? _signupChoiceOwner;
  int? _signupChoiceGeneration;
  bool _signupChoiceUnavailable = false;
  String? _storeOwnerAtOpen;
  int? _storeGenerationAtOpen;
  int? _storeBalance;
  bool _storeExpired = false;
  StreamSubscription<dynamic>? _storeAuthSubscription;

  bool get _guardian =>
      widget.telemetrySurface == ZyraTelemetrySurface.guardian;

  bool get _isOne => _guardian
      ? AppState.instance.waliHasWaliOne
      : AppState.instance.plan == ZyraPlan.one;

  ZyraMembershipProduct get _currentProduct => switch ((_guardian, _isOne)) {
    (false, false) => ZyraMembershipProduct.seekerBasic,
    (false, true) => ZyraMembershipProduct.seekerOne,
    (true, false) => ZyraMembershipProduct.guardianBasic,
    (true, true) => ZyraMembershipProduct.guardianOne,
  };

  // Current access, a signup preference or a preview plan cannot establish
  // whether a membership payment was made. Until the trusted history reader
  // is connected, do not quote either a repeat fee or a waiver for a member.
  ZyraMembershipPaymentHistory get _paymentHistory =>
      ZyraMembershipPaymentHistory.unknown;

  TargetPlatform get _storePlatform =>
      widget.storePlatform ?? defaultTargetPlatform;

  Uri get _storeUri => switch (_storePlatform) {
    TargetPlatform.android => UpgradeScreen.playSubscriptionsUri,
    _ => UpgradeScreen.appleSubscriptionsUri,
  };

  String get _storeName =>
      _storePlatform == TargetPlatform.android ? 'Google Play' : 'App Store';

  @override
  void initState() {
    super.initState();
    if (widget.compatibilityOnly) {
      _storeOwnerAtOpen = ZyraAccountState.userId;
      _storeGenerationAtOpen = ZyraAccountState.generation;
      AppState.instance.addListener(_onStoreAccountChanged);
      try {
        _storeAuthSubscription = ZyraAuth.authStateChanges.listen(
          (_) => _onStoreAccountChanged(),
          onError: (Object _, StackTrace _) => _expireStore(),
        );
      } catch (_) {
        // Standalone catalogue fixtures need no Auth runtime or live balance.
      }
      unawaited(_loadStoreBalance());
    } else {
      _membershipOwnerAtOpen = ZyraAccountState.userId;
      _membershipGenerationAtOpen = ZyraAccountState.generation;
      _membershipSurfaceAtOpen = widget.telemetrySurface;
      _membershipPreviewAtOpen = ZyraInternalPreviewClient.isActive;
      _membershipDraft = ZyraMembershipDraft(
        section: ZyraMembershipSection.current,
      );
      AppState.instance.addListener(_onMembershipAccountChanged);
      unawaited(_loadSignupChoice());
    }
    ZyraProductTelemetry.instance.record(
      feature: ZyraTelemetryFeature.membership,
      name: ZyraTelemetryEventName.opened,
      action: ZyraTelemetryAction.pageView,
      surface: widget.telemetrySurface,
    );
  }

  bool get _storeOwnerCurrent {
    final owner = _storeOwnerAtOpen;
    final generation = _storeGenerationAtOpen;
    if (!mounted ||
        _storeExpired ||
        owner == null ||
        generation == null ||
        !ZyraAccountState.isCurrent(owner, generation)) {
      return false;
    }
    try {
      return ZyraAuth.currentUser?.id == owner;
    } catch (_) {
      return false;
    }
  }

  void _onStoreAccountChanged() {
    if (!_storeOwnerCurrent) _expireStore();
  }

  void _expireStore() {
    if (!mounted || _storeExpired) return;
    setState(() {
      _storeExpired = true;
      _storeBalance = null;
    });
  }

  Future<void> _loadStoreBalance() async {
    // A generic store never borrows preview credits, assumes zero on error,
    // combines legacy tiers or derives ownership from the credit balance.
    if (!_storeOwnerCurrent || ZyraInternalPreviewClient.isActive) return;
    final result = await ZyraUnlockService.readBalances();
    if (!_storeOwnerCurrent || ZyraInternalPreviewClient.isActive) return;
    setState(() {
      _storeBalance = result.available
          ? result.values[ZyraUnlockService.currentTier]
          : null;
    });
  }

  void _openUnlockTerms() {
    if (!mounted ||
        _storeExpired ||
        _storeGenerationAtOpen != ZyraAccountState.generation ||
        (_storeOwnerAtOpen != null && !_storeOwnerCurrent) ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(
          document: ZyraLegalDocument.terms,
          guardian: _guardian,
        ),
      ),
    );
  }

  bool get _ownsSignupChoice =>
      !ZyraInternalPreviewClient.isActive &&
      _signupChoiceOwner != null &&
      _signupChoiceGeneration != null &&
      ZyraAccountState.isCurrent(_signupChoiceOwner!, _signupChoiceGeneration!);

  Future<void> _loadSignupChoice() async {
    final owner = ZyraAccountState.userId;
    if (owner == null ||
        !ZyraInitialSignupDraftService.supportedOnThisPlatform ||
        ZyraInternalPreviewClient.isActive) {
      return;
    }
    final generation = ZyraAccountState.generation;
    try {
      final intent = await ZyraInitialSignupDraftService.readMembershipIntent(
        expectedUserId: owner,
      ).timeout(const Duration(seconds: 8));
      if (!mounted ||
          !ZyraAccountState.isCurrent(owner, generation) ||
          ZyraInternalPreviewClient.isActive) {
        return;
      }
      setState(() {
        _signupChoiceOwner = owner;
        _signupChoiceGeneration = generation;
        _signupChoice = intent;
        _signupChoiceUnavailable = false;
      });
    } catch (_) {
      if (!mounted ||
          !ZyraAccountState.isCurrent(owner, generation) ||
          ZyraInternalPreviewClient.isActive) {
        return;
      }
      setState(() {
        _signupChoiceOwner = owner;
        _signupChoiceGeneration = generation;
        _signupChoice = null;
        _signupChoiceUnavailable = true;
      });
    }
  }

  Widget? _signupChoiceCard() {
    if (!_ownsSignupChoice) return null;
    if (_signupChoiceUnavailable) {
      return _MembershipAction(
        key: const ValueKey('membership-signup-choice-retry'),
        icon: Icons.refresh_rounded,
        title: 'Your signup choice could not be loaded',
        detail: 'Retry without changing your current membership.',
        onTap: () => unawaited(_loadSignupChoice()),
      );
    }
    final intent = _signupChoice;
    if (intent == null ||
        !intent.isValid ||
        intent.role !=
            (_guardian ? ZyraSignupRole.guardian : ZyraSignupRole.seeker)) {
      return null;
    }
    final choice = intent.choice;
    final product = switch ((_guardian, choice.kind)) {
      (false, ZyraSignupMembershipKind.basic) =>
        ZyraMembershipProduct.seekerBasic,
      (true, ZyraSignupMembershipKind.basic) =>
        ZyraMembershipProduct.guardianBasic,
      (false, ZyraSignupMembershipKind.one) => ZyraMembershipProduct.seekerOne,
      (true, ZyraSignupMembershipKind.one) => ZyraMembershipProduct.guardianOne,
      (_, ZyraSignupMembershipKind.family) => null,
    };
    final description = product == null
        ? 'ZYRA Family · ${choice.seekers} Seeker and ${choice.guardians} Guardian places\n'
              '${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.familyQuote(choice.seekers, choice.guardians).formulaMonthlyPence)} / month estimated'
        : '${ZyraMembershipCatalog.title(product)} · ${ZyraMembershipCatalog.membershipPrice(product, history: _paymentHistory)}';
    return Container(
      key: const ValueKey('membership-signup-choice'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your signup choice', style: ZyraText.body(size: 14)),
          const SizedBox(height: 6),
          Text(description, style: ZyraText.subtext(size: 12.5)),
          const SizedBox(height: 7),
          Text(
            'Saved as a preference only. No payment, trial or membership has been activated by this choice.',
            style: ZyraText.subtext(size: 11.5),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _storeAuthSubscription?.cancel();
    if (widget.compatibilityOnly) {
      AppState.instance.removeListener(_onStoreAccountChanged);
    } else {
      AppState.instance.removeListener(_onMembershipAccountChanged);
    }
    super.dispose();
  }

  Future<void> _openStoreManagement() async {
    if (!_membershipCanAct) return;
    var opened = false;
    try {
      opened =
          await (widget.openStore?.call(_storeUri) ??
              launchUrl(_storeUri, mode: LaunchMode.externalApplication));
    } catch (error) {
      debugPrint(
        'ZYRA subscription centre could not open (${error.runtimeType}).',
      );
    }
    if (!mounted || !_membershipCanAct || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open $_storeName subscriptions. Open $_storeName and choose Subscriptions.',
        ),
      ),
    );
  }

  Future<void> _confirmCancellation() async {
    if (!_membershipCanAct) return;
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: ZyraColors.waliSheetBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cancel membership', style: ZyraText.heading(size: 20)),
              const SizedBox(height: 10),
              Text(
                '$_storeName securely manages this change. It will show the effective date and ask you to confirm before anything changes. ZYRA never removes your saved account data or Guardian links because a membership changes.',
                style: ZyraText.subtext(size: 12.5),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: Text('Not now', style: ZyraText.button(size: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('membership-store-continue'),
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: Text('Continue', style: ZyraText.button(size: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (proceed == true && _membershipCanAct) await _openStoreManagement();
  }

  Widget _storeContent() => ZyraDraftCompatibilityStorePresentation(
    isSeekerOne: !_guardian && _isOne,
    balance: _storeOwnerCurrent ? _storeBalance : null,
    storePlatform: _storePlatform,
    onTerms: _storeExpired ? null : _openUnlockTerms,
  );

  Widget _compatibilityStorePage(BuildContext context) => Scaffold(
    body: Container(
      decoration: ZyraAppGoldDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('compatibility-store-back'),
                  onPressed: () {
                    if (!mounted ||
                        !(ModalRoute.of(context)?.isCurrent ?? false)) {
                      return;
                    }
                    Navigator.of(context).maybePop();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: Icon(
                    Icons.arrow_back,
                    color: ZyraColors.foregroundSecondary,
                  ),
                  label: Text('Back', style: ZyraText.body(size: 14)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: _storeContent(),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  bool get _membershipCanAct =>
      mounted &&
      !_membershipExpired &&
      !ZyraAccountState.isSigningOut &&
      _membershipSurfaceAtOpen == widget.telemetrySurface &&
      _membershipPreviewAtOpen == ZyraInternalPreviewClient.isActive &&
      _membershipOwnerAtOpen == ZyraAccountState.userId &&
      _membershipGenerationAtOpen == ZyraAccountState.generation &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  bool Function() _membershipFreshGuard() {
    final revision = _membershipRevision;
    return () => _membershipCanAct && revision == _membershipRevision;
  }

  void _onMembershipAccountChanged() {
    if (!mounted || widget.compatibilityOnly) return;
    setState(() {
      _membershipRevision++;
      _membershipReview = null;
      if (_membershipOwnerAtOpen != ZyraAccountState.userId ||
          _membershipGenerationAtOpen != ZyraAccountState.generation) {
        _membershipExpired = true;
        _membershipDraft = ZyraMembershipDraft();
      }
    });
  }

  Set<ZyraMembershipProduct> get _currentProducts => {
    // Guardian capability can be an allocation, not independently owned billing.
    if (!_guardian && _isOne) ZyraMembershipProduct.seekerOne,
  };

  bool get _basicPreview =>
      !_isOne &&
      ZyraInternalPreviewClient.isActive &&
      ZyraDeveloperAccess.canUseDeveloperTools;

  String get _currentSummary => _guardian && _isOne
      ? 'Guardian access active'
      : _isOne
      ? ZyraMembershipCatalog.title(_currentProduct)
      : _basicPreview
      ? '${ZyraMembershipCatalog.title(_currentProduct)} · Preview'
      : 'No active membership';

  String get _currentDetail => _guardian && _isOne
      ? 'Included or separately subscribed. Check your billing provider for payment details.'
      : _isOne
      ? ZyraMembershipCatalog.price(_currentProduct)
      : _basicPreview
      ? 'Local rehearsal only. Payment history is not confirmed.'
      : 'Choose a membership. A signup choice is not payment confirmation.';

  void _openMembershipTerms(bool Function() fresh) {
    if (!fresh()) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ZyraMembershipTermsSheet(),
    );
  }

  Widget _membershipCurrent(bool Function() fresh) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_signupChoiceCard() case final choiceCard?) ...[
        choiceCard,
        const SizedBox(height: 20),
      ],
      if (_isOne) ...[
        _MembershipAction(
          key: const ValueKey('membership-cancel'),
          icon: Icons.cancel_outlined,
          title: 'Cancel membership',
          detail: _guardian
              ? 'If billed to you, manage or cancel securely in $_storeName.'
              : 'Turn off renewal securely in $_storeName.',
          destructive: true,
          onTap: () {
            if (fresh()) unawaited(_confirmCancellation());
          },
        ),
      ],
    ],
  );

  Widget _membershipPage() {
    final fresh = _membershipFreshGuard();
    final review = _membershipReview;
    if (_membershipExpired) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'This membership page belongs to an earlier session. Return to your Profile and open Membership again.',
            style: ZyraText.body(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (review != null) {
      return ZyraMembershipReviewPresentation(
        key: const ValueKey('membership-management-review'),
        request: review,
        paymentHistory: _paymentHistory,
        canAct: fresh,
        onBack: () {
          if (!fresh()) return;
          setState(() {
            _membershipRevision++;
            _membershipReview = null;
          });
        },
      );
    }
    return ZyraMembershipChoices(
      key: const ValueKey('membership-management'),
      initialDraft: _membershipDraft,
      currentProducts: _currentProducts,
      paymentHistory: _paymentHistory,
      currentSummary: _currentSummary,
      currentDetail: _currentDetail,
      canAct: fresh,
      onBack: () {
        if (fresh()) Navigator.of(context).maybePop();
      },
      onDraftChanged: (draft) {
        if (!fresh()) return;
        setState(() {
          _membershipRevision++;
          _membershipDraft = draft;
        });
      },
      onReview: (_) {
        if (!fresh()) return;
        // Re-resolve access and nullable Basic quotes at the action boundary.
        // Drafts are not receipts, Family allocations or purchase consent.
        final request = ZyraMembershipReviewRequest.fromDraft(
          _membershipDraft,
          currentProducts: _currentProducts,
          paymentHistory: _paymentHistory,
        );
        if (request == null) return;
        setState(() {
          _membershipRevision++;
          _membershipReview = request;
        });
      },
      currentContent: _membershipCurrent(fresh),
      unlocksContent: CompatibilityUnlockStoreContent(
        telemetrySurface: widget.telemetrySurface,
      ),
      onTerms: () => _openMembershipTerms(fresh),
    );
  }

  @override
  Widget build(BuildContext context) => widget.compatibilityOnly
      ? widget._embeddedStore
            ? _storeContent()
            : _compatibilityStorePage(context)
      : PopScope(
          canPop: _membershipReview == null,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || !_membershipCanAct || _membershipReview == null) {
              return;
            }
            setState(() {
              _membershipRevision++;
              _membershipReview = null;
            });
          },
          child: Scaffold(
            body: Container(
              decoration: ZyraAppGoldDecoration(
                gradient: ZyraColors.genderGradient(AppState.instance.gender),
              ),
              child: SafeArea(child: _membershipPage()),
            ),
          ),
        );
}

class _MembershipAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool destructive;

  const _MembershipAction({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive
        ? ZyraColors.negativeRed
        : ZyraColors.foregroundSecondary;
    return Material(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ZyraCardMetrics.cardRadius),
            border: Border.all(
              color: accent.withValues(alpha: destructive ? 0.34 : 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 21, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ZyraText.body(size: 14, color: accent)),
                    const SizedBox(height: 3),
                    Text(detail, style: ZyraText.subtext(size: 11.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: ZyraColors.foregroundMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
