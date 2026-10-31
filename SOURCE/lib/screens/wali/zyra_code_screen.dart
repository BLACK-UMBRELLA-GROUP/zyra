import '../../widgets/zyra_tap_feedback.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/zyra_membership_catalog.dart';
import '../../data/zyra_reference_data.dart';
import '../../data/zyra_guardian_capacity.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../dev/zyra_draft_local_code_page.dart';
import '../../dev/zyra_draft_local_code_aliases.dart';
import '../../dev/zyra_dev_personal_code_fixtures.dart';
import '../../dev/zyra_dev_surface_coordinator.dart';
import '../../dev/zyra_dev_local_preview.dart';
import '../../models/zyra_initial_signup_draft.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../services/zyra_promotion_engine.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_interaction_style.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_guardian_capacity_notice.dart';
import '../../widgets/zyra_glass_dialog.dart';
import '../../widgets/zyra_onboarding_direction_style.dart';
import '../../widgets/zyra_pull_down_back_scope.dart';
import 'accept_wali_invite_screen.dart';
import 'wali_home_shell.dart';

/// Caller-owned, session-only data for the protected concept's existing code UI.
/// A revoked or replaced adapter can never become a live-service route.
@immutable
class ZyraCodeLocalPreview {
  const ZyraCodeLocalPreview({
    required this.canAct,
    required this.personalCode,
    required this.lookupCode,
    this.canInteract,
    this.interactionEpoch,
  });

  final bool Function() canAct;
  final ZyraPersonalCode personalCode;
  final Future<ZyraPersonalCodePreview?> Function(String code) lookupCode;
  final bool Function()? canInteract;

  /// A caller-owned monotonic revision for covers which do not push a route.
  /// Increase it on both cover and uncover, not only while an overlay is open.
  final int Function()? interactionEpoch;
}

typedef _LocalCodeEpoch = ({int local, int caller});

Size _codeTextSize(
  BuildContext context,
  String text,
  TextStyle style, {
  double maxWidth = double.infinity,
}) {
  var effective = DefaultTextStyle.of(context).style.merge(style);
  if (MediaQuery.boldTextOf(context)) {
    effective = effective.merge(const TextStyle(fontWeight: FontWeight.bold));
  }
  final painter = TextPainter(
    text: TextSpan(text: text, style: effective),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
  )..layout(maxWidth: maxWidth);
  final size = painter.size;
  painter.dispose();
  return size;
}

/// One role-neutral surface for the Founder-approved permanent ZYRA Code.
///
/// The code is only a discovery handle. Every successful entry creates a
/// request and the owner must accept it before a Guardian link exists.
class ZyraCodeScreen extends StatefulWidget {
  final bool asGuardian;
  final VoidCallback? onLinked;

  /// Read-only dependencies for ordinary caller lifetime tests. Production
  /// routes omit them and keep the authenticated service readiness boundary.
  final Future<ZyraSourceResult<ZyraPersonalCode>> Function({
    String? roleContext,
  })?
  loadPersonalCode;
  final Future<ZyraSourceResult<List<ZyraGuardianLinkRequest>>> Function()?
  loadGuardianRequests;

  /// Bounded first-use rehearsal: fictional code and local information only.
  /// Keep the requested mode isolated even when developer access is revoked.
  final bool signupPreview;
  final ZyraInitialSignupDraft? signupPreviewIdentity;
  final ZyraCodeLocalPreview? localPreview;
  final Widget? previewLeading;

  const ZyraCodeScreen({
    super.key,
    required this.asGuardian,
    this.onLinked,
    this.loadPersonalCode,
    this.loadGuardianRequests,
    this.signupPreview = false,
    this.signupPreviewIdentity,
    this.localPreview,
    this.previewLeading,
  });

  @override
  State<ZyraCodeScreen> createState() => _ZyraCodeScreenState();
}

class _ZyraCodeScreenState extends State<ZyraCodeScreen>
    with WidgetsBindingObserver {
  ZyraPersonalCode? _code;
  List<ZyraGuardianLinkRequest> _requests = const [];
  bool _loading = true;
  bool _available = true;
  bool _showQr = false;
  bool _copied = false;
  bool _copyPulseActive = false;
  int _copyPulseRevision = 0;
  bool _shareSelected = false;
  bool _showEnterCode = false;
  String? _initialEnteredCode;
  Timer? _copyPulseTimer;
  Timer? _shareResetTimer;
  Timer? _entryRevealTimer;
  final GlobalKey _entryRevealKey = GlobalKey();
  final GlobalKey _entryActionRevealKey = GlobalKey();
  final ScrollController _screenScrollController = ScrollController();
  String? _error;
  String? _busyRequest;
  int _readRevision = 0;
  String? _rowsOwnerId;
  int _rowsOwnerGeneration = -1;
  bool _requestMutationInFlight = false;
  String? _signupPreviewNotice;
  bool _enteringGuardianPreview = false;
  late final ZyraCodeLocalPreview? _localPreview;
  late final bool _localRole;
  late final String? _localOwner;
  late final int _localGeneration;
  late final int _localSession;
  bool _localRequested = false;
  bool _localDenied = false;
  bool _invitationListener = false;
  bool _signupListener = false;
  bool _localListeners = false;
  int _localEpoch = 0;
  bool? _localRouteCurrent;
  AppLifecycleState? _localLifecycle;
  String? _localNotice;

  String get _other => widget.asGuardian ? 'Seeker' : 'Guardian';
  bool get _signupPreviewAllowed =>
      mounted && ZyraDeveloperAccess.canUseDeveloperTools;
  bool get _isFounderDemoPreview =>
      _localRequested ||
      widget.signupPreview ||
      ZyraInternalPreviewClient.isActive &&
          ZyraDeveloperAccess.isMainAppFounderPreview;

  @override
  void initState() {
    super.initState();
    _localPreview = widget.localPreview;
    _localRequested = _localPreview != null;
    _localRole = widget.asGuardian;
    _localOwner = ZyraAccountState.userId;
    _localGeneration = ZyraAccountState.generation;
    _localSession = ZyraInternalPreviewClient.previewSession;
    _localLifecycle = WidgetsBinding.instance.lifecycleState;
    if (_localRequested) {
      _localListeners = true;
      WidgetsBinding.instance.addObserver(this);
      ZyraDeveloperAccess.authorizationChanges.addListener(
        _localAuthorityChanged,
      );
      ZyraDevScenario.instance.addListener(_localAuthorityChanged);
      ZyraInternalPreviewClient.changes.addListener(_localAuthorityChanged);
    } else if (widget.signupPreview) {
      _signupListener = true;
      ZyraDeveloperAccess.authorizationChanges.addListener(
        _signupAuthorizationChanged,
      );
    } else {
      ZyraWaliLinkService.invitationRevision.addListener(_reload);
      _invitationListener = true;
    }
    _load();
  }

  @override
  void dispose() {
    ++_localEpoch;
    if (_localListeners) {
      WidgetsBinding.instance.removeObserver(this);
      ZyraDeveloperAccess.authorizationChanges.removeListener(
        _localAuthorityChanged,
      );
      ZyraDevScenario.instance.removeListener(_localAuthorityChanged);
      ZyraInternalPreviewClient.changes.removeListener(_localAuthorityChanged);
    }
    if (_signupListener) {
      ZyraDeveloperAccess.authorizationChanges.removeListener(
        _signupAuthorizationChanged,
      );
    }
    if (_invitationListener) {
      ZyraWaliLinkService.invitationRevision.removeListener(_reload);
    }
    _copyPulseTimer?.cancel();
    _shareResetTimer?.cancel();
    _entryRevealTimer?.cancel();
    _screenScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ZyraCodeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_localRequested || widget.localPreview != null) {
      _localRequested = true;
      if (_signupListener) {
        ZyraDeveloperAccess.authorizationChanges.removeListener(
          _signupAuthorizationChanged,
        );
        _signupListener = false;
      }
      if (_invitationListener) {
        ZyraWaliLinkService.invitationRevision.removeListener(_reload);
        _invitationListener = false;
      }
      if (!identical(widget.localPreview, _localPreview) ||
          widget.asGuardian != _localRole ||
          widget.signupPreview) {
        _revokeLocal();
      }
      _localOwnerAllows();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localRequested) return;
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (_localRouteCurrent != null && _localRouteCurrent != current) {
      ++_localEpoch;
      _entryRevealTimer?.cancel();
    }
    _localRouteCurrent = current;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_localRequested) return;
    _localLifecycle = state;
    ++_localEpoch;
    _entryRevealTimer?.cancel();
    if (mounted) {
      setState(() {
        _localOwnerAllows();
      });
    }
  }

  void _revokeLocal() {
    if (_localDenied) return;
    _localDenied = true;
    ++_localEpoch;
    ++_readRevision;
    _entryRevealTimer?.cancel();
    _code = null;
    _requests = const [];
    _showQr = false;
    _showEnterCode = false;
    _localNotice = null;
  }

  bool _localOwnerAllows() {
    if (!mounted || _localDenied || _localPreview == null) return false;
    bool allowed = false;
    try {
      allowed =
          identical(widget.localPreview, _localPreview) &&
          widget.asGuardian == _localRole &&
          !widget.signupPreview &&
          !ZyraAccountState.isSigningOut &&
          ZyraAccountState.userId == _localOwner &&
          ZyraAccountState.generation == _localGeneration &&
          ZyraInternalPreviewClient.previewSession == _localSession &&
          ZyraInternalPreviewClient.isActive &&
          ZyraDeveloperAccess.canUseDeveloperTools &&
          _localPreview.personalCode.roleContext ==
              (_localRole ? 'wali' : 'seeker') &&
          RegExp(
            r'^ZYRA-DEMO-[A-Z0-9]+(?:-[A-Z0-9]+)*$',
          ).hasMatch(_localPreview.personalCode.code) &&
          _localPreview.canAct();
      if (allowed) _localPreview.interactionEpoch?.call();
    } catch (_) {
      // A failed owner check revokes this local lifetime; it is never fallback.
      allowed = false;
    }
    if (!allowed) _revokeLocal();
    return allowed;
  }

  bool _localInteractive([_LocalCodeEpoch? epoch]) {
    if (!_localOwnerAllows()) {
      if (mounted) setState(() {});
      return false;
    }
    if (epoch != null && epoch != _localOperationEpoch()) return false;
    try {
      return (ModalRoute.of(context)?.isCurrent ?? true) &&
          (_localLifecycle == null ||
              _localLifecycle == AppLifecycleState.resumed) &&
          (_localPreview!.canInteract?.call() ?? true);
    } catch (_) {
      _revokeLocal();
      if (mounted) setState(() {});
      return false;
    }
  }

  _LocalCodeEpoch _localOperationEpoch() {
    try {
      return (
        local: _localEpoch,
        caller: _localPreview?.interactionEpoch?.call() ?? 0,
      );
    } catch (_) {
      _revokeLocal();
      return (local: _localEpoch, caller: -1);
    }
  }

  VoidCallback _localBound(VoidCallback action) {
    if (!_localRequested) return action;
    final epoch = _localOperationEpoch();
    return () {
      if (_localInteractive(epoch)) action();
    };
  }

  void _localAuthorityChanged() {
    if (!mounted || !_localRequested) return;
    ++_localEpoch;
    _entryRevealTimer?.cancel();
    setState(() {
      _localOwnerAllows();
    });
  }

  void _localInformation(String message) {
    if (!_localInteractive()) return;
    setState(() => _localNotice = message);
  }

  Widget _localInformationContent() => _localNotice == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            _localNotice!,
            key: const ValueKey('zyra_code_local_notice'),
            style: ZyraText.subtext(size: 12.5),
          ),
        );

  void _reload() => _load(keepRows: true);

  void _signupAuthorizationChanged() {
    if (!mounted) return;
    if (_signupPreviewAllowed) {
      _load();
    } else {
      setState(() {
        _code = null;
        _requests = const [];
        _showQr = false;
        _signupPreviewNotice = null;
      });
    }
  }

  void _signupInformation(String message) {
    if (!_signupPreviewAllowed) return;
    setState(() => _signupPreviewNotice = message);
  }

  bool get _canEnterGuardianPreview {
    final draft = widget.signupPreviewIdentity;
    return widget.signupPreview &&
        widget.asGuardian &&
        _signupPreviewAllowed &&
        ZyraDeveloperAccess.isMainAppPreview &&
        ZyraInternalPreviewClient.isActive &&
        draft != null &&
        draft.role == ZyraSignupRole.guardian &&
        draft.awaitsVerification &&
        draft.isValid();
  }

  void _enterGuardianPreview() {
    if (_enteringGuardianPreview || !_canEnterGuardianPreview) return;
    final draft = widget.signupPreviewIdentity!;
    final navigator = Navigator.of(context);
    _enteringGuardianPreview = true;

    // A first-use Guardian has no linked Seekers. Simulate the chosen local
    // membership only; no real joining payment or subscription is completed.
    // Reset only the local, network-denied sample; no account or link is
    // created and no persistent member data is written.
    ZyraDevScenario.instance.reset();
    AppState.instance.applyDevPreset(
      name: draft.firstName,
      gender: draft.gender,
      dob: draft.dob,
      waliName: draft.firstName,
      waliRelationship: draft.relationship,
    );
    final choice = draft.membershipChoice;
    if (choice != null &&
        !ZyraDevLocalPreview.applySignupMembershipPreview(
          role: draft.role,
          choice: choice,
        )) {
      _enteringGuardianPreview = false;
      return;
    }
    ZyraPromotionEngine.instance.setDeveloperGuardianNetworkState(
      AppState.instance.waliHasWaliOne
          ? ZyraDeveloperGuardianNetworkState.unlinkedEntitled
          : ZyraDeveloperGuardianNetworkState.unlinkedBasic,
    );
    ZyraDevSurfaceCoordinator.instance.endEntryFlow();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        allowSnapshotting: false,
        builder: (_) => const WaliHomeShell(initialOnboardingPreview: true),
      ),
      (_) => false,
    );
  }

  Future<void> _load({bool keepRows = false}) async {
    if (_localRequested) {
      if (!_localOwnerAllows()) return;
      setState(() {
        _code = _localPreview!.personalCode;
        _requests = const [];
        _loading = false;
        _available = true;
        _error = null;
      });
      return;
    }
    // Raw requested mode comes before all live readers, even without a latch.
    if (!mounted || widget.signupPreview && !_signupPreviewAllowed) return;
    final readRevision = ++_readRevision;
    if (!keepRows) setState(() => _loading = true);
    if (_isFounderDemoPreview) {
      final nextCode = ZyraDevPersonalCodeFixtures.forPersona(
        asGuardian: widget.asGuardian,
        gender: AppState.instance.gender,
      );
      setState(() {
        if (_code?.code != null && _code!.code != nextCode.code) {
          _copyPulseTimer?.cancel();
          _copied = false;
          _copyPulseActive = false;
        }
        _code = nextCode;
        _requests = const [];
        _loading = false;
        _available = true;
        _error = null;
      });
      return;
    }
    final ownerId = _currentMemberId();
    final generation = ZyraAccountState.generation;
    final results = await Future.wait<Object>([
      (widget.loadPersonalCode ?? ZyraWaliLinkService.personalCode)(
        roleContext: widget.asGuardian ? 'wali' : 'seeker',
      ),
      (widget.loadGuardianRequests ??
          ZyraWaliLinkService.guardianLinkRequests)(),
    ]);
    if (readRevision != _readRevision ||
        _isFounderDemoPreview ||
        !_isCurrentAccount(ownerId, generation)) {
      return;
    }
    final codeResult = results[0] as ZyraSourceResult<ZyraPersonalCode>;
    final requestResult =
        results[1] as ZyraSourceResult<List<ZyraGuardianLinkRequest>>;
    setState(() {
      _loading = false;
      _available = codeResult.isAvailable && requestResult.isAvailable;
      if (codeResult.valueOrNull case final value?) {
        if (_code?.code != null && _code!.code != value.code) {
          _copyPulseTimer?.cancel();
          _copied = false;
          _copyPulseActive = false;
        }
        _code = value;
      }
      if (requestResult.valueOrNull case final value?) {
        _requests = value;
        _rowsOwnerId = ownerId;
        _rowsOwnerGeneration = generation;
      }
    });
  }

  String? _currentMemberId() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      // Preserve the existing unavailable-reader presentation before Auth
      // initialization; absence never authorizes a request mutation.
      return null;
    }
  }

  bool _isCurrentAccount(String? ownerId, int generation) =>
      mounted &&
      !ZyraAccountState.isSigningOut &&
      ZyraAccountState.generation == generation &&
      _currentMemberId() == ownerId &&
      (ownerId == null
          ? ZyraAccountState.userId == null
          : ZyraAccountState.isCurrent(ownerId, generation));

  bool _isCurrentRequestAction(String ownerId, int generation) =>
      !_isFounderDemoPreview &&
      _isCurrentAccount(ownerId, generation) &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  ({String ownerId, int generation})? _beginRequestAction(
    ZyraGuardianLinkRequest request,
  ) {
    final ownerId = _rowsOwnerId;
    final generation = _rowsOwnerGeneration;
    if (_requestMutationInFlight ||
        ownerId == null ||
        !_isCurrentRequestAction(ownerId, generation) ||
        !_requests.any((row) => row.id == request.id && row.isPending)) {
      return null;
    }
    // Claim the one local action before a relationship sheet or service await.
    _requestMutationInFlight = true;
    return (ownerId: ownerId, generation: generation);
  }

  void _finishRequestAction() {
    _requestMutationInFlight = false;
    if (mounted && _busyRequest != null) {
      setState(() => _busyRequest = null);
    }
  }

  Future<void> _copy() async {
    if (_localRequested) {
      _localInformation('This is a local preview. Nothing was copied.');
      return;
    }
    if (widget.signupPreview) {
      _signupInformation(
        'Preview only. In the app, Copy puts your personal code on the '
        'clipboard. Nothing was copied here.',
      );
      return;
    }
    final code = _code?.code;
    if (code == null) return;
    await ZyraInteractionStyle.emitSelectionHaptic();
    if (_localRequested) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    _copyPulseTimer?.cancel();
    setState(() {
      _copied = true;
      _copyPulseActive = true;
      _copyPulseRevision += 1;
    });
    _copyPulseTimer = Timer(const Duration(milliseconds: 240), () {
      if (mounted) setState(() => _copyPulseActive = false);
    });
  }

  Future<void> _share(BuildContext buttonContext) async {
    if (_localRequested) {
      _localInformation(
        'This is a local preview. No sharing sheet was opened.',
      );
      return;
    }
    if (widget.signupPreview) {
      _signupInformation(
        'Preview only. In the app, Share lets you send your personal code '
        'to someone you know. No sharing sheet opens here.',
      );
      return;
    }
    final code = _code?.code;
    if (code == null) return;
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    await ZyraInteractionStyle.emitSelectionHaptic();
    if (!mounted || _localRequested) return;
    setState(() => _shareSelected = true);
    _shareResetTimer?.cancel();
    _shareResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _shareSelected = false);
    });
    await SharePlus.instance.share(
      ShareParams(
        text: _isFounderDemoPreview
            ? 'ZYRA Developer Preview code:\n$code\n\n'
                  'This sample code cannot connect real accounts.'
            : 'Use my ZYRA Code to send me a Guardian request:\n$code\n\n'
                  'I will still need to approve the request in ZYRA.',
        subject: 'My ZYRA Code',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _rotate() async {
    if (_localRequested) {
      _localInformation(
        'This is a local preview. No personal code was changed.',
      );
      return;
    }
    if (widget.signupPreview) {
      _signupInformation('Preview only. No personal code was changed.');
      return;
    }
    final confirmed = await showZyraGlassChoice(
      context: context,
      icon: Icons.refresh_rounded,
      title: 'Change your ZYRA Code?',
      body:
          'Your current code will stop working and will never be issued again. '
          'Requests already sent will stay visible.',
      primaryLabel: 'Change code',
      secondaryLabel: 'Keep code',
    );
    if (confirmed != true || !mounted || _localRequested) return;
    final result = await ZyraWaliLinkService.rotatePersonalCode(
      roleContext: widget.asGuardian ? 'wali' : 'seeker',
    );
    if (!mounted) return;
    setState(() {
      if (result.valueOrNull case final code?) {
        _copyPulseTimer?.cancel();
        _code = code;
        _showQr = false;
        _copied = false;
        _copyPulseActive = false;
        _error = null;
      } else {
        _error = "Your code couldn't be changed. Please try again.";
      }
    });
  }

  void _enterCode([String? initialCode]) {
    if (_localRequested && !_localInteractive()) return;
    if (widget.signupPreview) {
      _signupInformation(
        'Preview only. In the app, enter the other person\'s ZYRA Code, '
        'confirm who they are, then send a request. A link is created only '
        'after they accept. No code is checked or request sent here.',
      );
      return;
    }
    final opening = initialCode != null || !_showEnterCode;
    setState(() {
      _initialEnteredCode = initialCode;
      _showEnterCode = opening;
      if (opening) _showQr = false;
    });
    if (opening) _revealCodeEntry();
  }

  void _revealCodeEntry() {
    final epoch = _localRequested ? _localOperationEpoch() : null;
    void reveal() {
      if (!mounted || _localRequested && !_localInteractive(epoch)) return;
      if (_screenScrollController.hasClients) {
        _screenScrollController.animateTo(
          _screenScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      final entryContext =
          _entryActionRevealKey.currentContext ??
          _entryRevealKey.currentContext;
      if (!mounted || entryContext == null) return;
      Scrollable.ensureVisible(
        entryContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.84,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _localRequested && !_localInteractive(epoch)) return;
      reveal();
      _entryRevealTimer?.cancel();
      _entryRevealTimer = Timer(const Duration(milliseconds: 380), reveal);
    });
  }

  Future<void> _scan() async {
    if (_localRequested) {
      _localInformation('This is a local preview. The camera was not opened.');
      return;
    }
    if (widget.signupPreview) {
      _signupInformation(
        'Preview only. Scanning uses the camera after you choose to scan '
        'a code in the app. This preview never opens the camera or asks '
        'for access.',
      );
      return;
    }
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanZyraCodeScreen()),
    );
    if (code != null && mounted) _enterCode(code);
  }

  Future<void> _accept(ZyraGuardianLinkRequest request) async {
    if (widget.signupPreview) {
      _signupInformation('Preview only. No Guardian link was created.');
      return;
    }
    final owner = _beginRequestAction(request);
    if (owner == null) return;
    try {
      String? relationship;
      // The current user is the Guardian when the requester is a Seeker.
      if (request.otherRole == 'seeker') {
        relationship = await _chooseRelationship();
        if (relationship == null) return;
      }
      if (!_isCurrentRequestAction(owner.ownerId, owner.generation)) return;
      setState(() {
        _busyRequest = request.id;
        _error = null;
      });
      final error = await ZyraWaliLinkService.acceptGuardianLinkRequest(
        request.id,
        relationship: relationship,
        currentSeekerPlan: request.otherRole == 'seeker'
            ? null
            : AppState.instance.plan,
      );
      if (!mounted ||
          !_isCurrentRequestAction(owner.ownerId, owner.generation)) {
        return;
      }
      setState(() => _error = error);
      showZyraGuardianCapacityNotice(context, error);
      if (error == null) {
        widget.onLinked?.call();
        if (_isCurrentRequestAction(owner.ownerId, owner.generation)) {
          _load(keepRows: true);
        }
      }
    } finally {
      _finishRequestAction();
    }
  }

  Future<String?> _chooseRelationship() => showModalBottomSheet<String>(
    context: context,
    backgroundColor: ZyraColors.waliSheetBg,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you related?', style: ZyraText.heading(size: 19)),
            const SizedBox(height: 12),
            for (final relationship in zyraGuardianRelationships)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(relationship.name, style: ZyraText.body(size: 14)),
                onTap: ZyraTapFeedback.onTap(
                  context,
                  () => Navigator.of(sheetContext).pop(relationship.code),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _decline(ZyraGuardianLinkRequest request) async {
    if (widget.signupPreview) {
      _signupInformation('Preview only. No request was declined.');
      return;
    }
    final owner = _beginRequestAction(request);
    if (owner == null) return;
    setState(() => _busyRequest = request.id);
    try {
      if (!_isCurrentRequestAction(owner.ownerId, owner.generation)) return;
      final ok = await ZyraWaliLinkService.declineGuardianLinkRequest(
        request.id,
      );
      if (!_isCurrentRequestAction(owner.ownerId, owner.generation)) return;
      setState(() {
        if (!ok) _error = "That request couldn't be declined.";
      });
      if (ok) _load(keepRows: true);
    } finally {
      _finishRequestAction();
    }
  }

  Future<void> _cancel(ZyraGuardianLinkRequest request) async {
    if (widget.signupPreview) {
      _signupInformation('Preview only. No request was cancelled.');
      return;
    }
    final owner = _beginRequestAction(request);
    if (owner == null) return;
    setState(() => _busyRequest = request.id);
    try {
      if (!_isCurrentRequestAction(owner.ownerId, owner.generation)) return;
      final ok = await ZyraWaliLinkService.cancelGuardianLinkRequest(
        request.id,
      );
      if (!_isCurrentRequestAction(owner.ownerId, owner.generation)) return;
      setState(() {
        if (!ok) _error = "That request couldn't be cancelled.";
      });
      if (ok) _load(keepRows: true);
    } finally {
      _finishRequestAction();
    }
  }

  bool get _canUseExpandedComposition =>
      _code != null &&
      _available &&
      !_requests.any((request) => request.isPending) &&
      _error == null;

  Future<void> _toggleQr() async {
    if (_localRequested) {
      if (!_localInteractive()) return;
      setState(() => _showQr = !_showQr);
      return;
    }
    if (widget.signupPreview) {
      if (!_signupPreviewAllowed) return;
      setState(() => _showQr = !_showQr);
      return;
    }
    await ZyraInteractionStyle.emitSelectionHaptic();
    if (!mounted) return;
    setState(() => _showQr = !_showQr);
  }

  Widget _buildSharingActions({double height = 54, required double maxWidth}) {
    final large = height > 54;
    final labels = [_copied ? 'Copied' : 'Copy', 'QR', 'Share'];
    final style = ZyraText.body(size: large ? 13.5 : 12.5);
    final iconWidth = large ? 19.0 : 17.0;
    final requiredWidth = labels
        .map(
          (label) =>
              _codeTextSize(context, label, style).width + iconWidth + 6 + 24,
        )
        .reduce((a, b) => a > b ? a : b);
    int columns = 3;
    double slot() => (maxWidth - (columns - 1) * 9) / columns;
    while (_localRequested && columns > 1 && requiredWidth > slot()) {
      columns--;
    }
    final labelWidth = (slot() - iconWidth - 6 - 24)
        .clamp(1.0, double.infinity)
        .toDouble();
    final labelHeight = labels
        .map(
          (label) =>
              _codeTextSize(context, label, style, maxWidth: labelWidth).height,
        )
        .reduce((a, b) => a > b ? a : b);
    final actionHeight = _localRequested && labelHeight + 20 > height
        ? labelHeight + 20
        : height;
    final actions = <Widget>[
      _SmallAction(
        icon: _copied ? Icons.check_rounded : Icons.copy_outlined,
        label: labels[0],
        height: actionHeight,
        prominent: large,
        adaptive: _localRequested,
        selected: _copied,
        pulse: _copyPulseActive,
        pulseRevision: _copyPulseRevision,
        enableFeedback: !_localRequested,
        onTap: _localBound(_copy),
      ),
      _SmallAction(
        icon: Icons.qr_code_2,
        label: 'QR',
        height: actionHeight,
        prominent: large,
        adaptive: _localRequested,
        selected: _showQr,
        enableFeedback: !_localRequested,
        onTap: _localBound(_toggleQr),
      ),
      Builder(
        builder: (buttonContext) => _SmallAction(
          icon: Icons.ios_share_outlined,
          label: 'Share',
          height: actionHeight,
          prominent: large,
          adaptive: _localRequested,
          selected: _shareSelected,
          enableFeedback: !_localRequested,
          onTap: _localBound(() => _share(buttonContext)),
        ),
      ),
    ];
    if (columns == 3) {
      return Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i != 0) const SizedBox(width: 9),
            Expanded(child: actions[i]),
          ],
        ],
      );
    }
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        for (final action in actions) SizedBox(width: slot(), child: action),
      ],
    );
  }

  Widget _buildExpandedComposition({required double availableWidth}) {
    final code = _code!;
    return SingleChildScrollView(
      controller: _screenScrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 310,
            child: _CodeCard(
              code: code.code,
              demoOnly: _isFounderDemoPreview,
              prominent: true,
              showQr: _showQr,
            ),
          ),
          const SizedBox(height: 14),
          _buildSharingActions(height: 64, maxWidth: availableWidth),
          if (!_isFounderDemoPreview)
            SizedBox(
              height: 38,
              child: TextButton(
                onPressed: ZyraTapFeedback.onTap(context, _rotate),
                child: Text('Change code', style: ZyraText.subtext(size: 12)),
              ),
            ),
          const SizedBox(height: 18),
          const _OrDivider(),
          const SizedBox(height: 18),
          _LargeAction(
            icon: Icons.qr_code_scanner,
            label: 'Scan code',
            enableFeedback: !_localRequested,
            onTap: _localBound(_scan),
          ),
          const SizedBox(height: 12),
          _buildEnterCodeAction(availableWidth: availableWidth),
          if (_localRequested) _localInformationContent(),
        ],
      ),
    );
  }

  Widget _buildOwnCodeSection({required double availableWidth}) {
    final code = _code;
    if (code == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CodeCard(code: code.code, demoOnly: _isFounderDemoPreview),
        const SizedBox(height: 14),
        _buildSharingActions(maxWidth: availableWidth),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          crossFadeState: _showQr
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: QrImageView(
                  data: code.code,
                  size: 190,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
        if (!_isFounderDemoPreview)
          TextButton(
            onPressed: ZyraTapFeedback.onTap(context, _rotate),
            child: Text('Change code', style: ZyraText.subtext(size: 12)),
          ),
      ],
    );
  }

  Widget _buildOtherCodeActions({required double availableWidth}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LargeAction(
          icon: Icons.qr_code_scanner,
          label: 'Scan code',
          enableFeedback: !_localRequested,
          onTap: _localBound(_scan),
        ),
        const SizedBox(height: 12),
        _buildEnterCodeAction(availableWidth: availableWidth),
        if (_localRequested) _localInformationContent(),
        if (_requests.any((r) => r.isPending)) ...[
          const SizedBox(height: 30),
          Text(
            'REQUESTS',
            style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
          ),
          const SizedBox(height: 10),
          for (final request in _requests.where((r) => r.isPending))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RequestCard(
                request: request,
                busy: _busyRequest == request.id,
                onAccept: () => _accept(request),
                onDecline: () => _decline(request),
                onCancel: () => _cancel(request),
              ),
            ),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          ZyraErrorBanner(
            message: error,
            onDismiss: _localBound(() => setState(() => _error = null)),
          ),
        ],
      ],
    );
  }

  Widget _buildEnterCodeAction({required double availableWidth}) => Material(
    color: ZyraColors.surfaceFill,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _showEnterCode
              ? ZyraColors.accentBorder
              : ZyraColors.surfaceBorder,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            enableFeedback: !_localRequested,
            onTap: ZyraTapFeedback.onTap(context, _localBound(_enterCode)),
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.keyboard_outlined,
                      size: 21,
                      color: ZyraColors.surfaceSignal,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Enter code', style: ZyraText.body(size: 14)),
                    ),
                    AnimatedRotation(
                      turns: _showEnterCode ? 0.25 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.chevron_right,
                        size: 19,
                        color: ZyraColors.ink(0.48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _showEnterCode
                ? Column(
                    children: [
                      Divider(height: 1, color: ZyraColors.surfaceBorder),
                      Padding(
                        key: _entryRevealKey,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        child: _InlineEnterZyraCodePanel(
                          key: ValueKey(
                            _localRequested
                                ? ('local-code-entry', _initialEnteredCode)
                                : _initialEnteredCode ?? 'blank-code-entry',
                          ),
                          initialCode: _initialEnteredCode,
                          asGuardian: widget.asGuardian,
                          developerPreview: _isFounderDemoPreview,
                          availableWidth: (availableWidth - 32)
                              .clamp(1.0, double.infinity)
                              .toDouble(),
                          localPreview: _localRequested ? _localPreview : null,
                          localCanInteract: _localRequested
                              ? _localInteractive
                              : null,
                          localEpoch: _localRequested
                              ? _localOperationEpoch
                              : null,
                          localViewEpoch: _localRequested
                              ? _localOperationEpoch()
                              : null,
                          primaryActionKey: _entryActionRevealKey,
                          onNeedsReveal: _revealCodeEntry,
                          onSent: () {
                            setState(() {
                              _showEnterCode = false;
                              _initialEnteredCode = null;
                            });
                            _load(keepRows: true);
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ),
  );

  bool _lockedCanAct() =>
      _localRequested ? _localOwnerAllows() : _signupPreviewAllowed;

  bool _lockedCanInteract() =>
      _localRequested ? _localInteractive() : _signupPreviewAllowed;

  Future<ZyraLocalCodeIdentity?> _lockedLookup(String canonical) async {
    if (!_lockedCanInteract()) return null;
    final person = _localRequested
        ? await _localPreview!.lookupCode(canonical)
        : ZyraDevPersonalCodeFixtures.previewEntryCode(
            canonical,
            asGuardian: widget.asGuardian,
          );
    if (!_lockedCanInteract() || person == null) return null;
    return ZyraLocalCodeIdentity(
      person.firstName,
      person.role == 'wali'
          ? 'Guardian'
          : person.role == 'seeker'
          ? 'Seeker'
          : '',
    );
  }

  Widget _lockedLocalPage() => Scaffold(
    key: widget.signupPreview ? const ValueKey('signup_code_preview') : null,
    backgroundColor: Colors.transparent,
    body: SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
        child: ZyraLocalCodePage(
          mode: widget.asGuardian
              ? ZyraLocalCodeContext.addSeeker
              : ZyraLocalCodeContext.addGuardian,
          ownerKey:
              _localPreview ??
              (widget.signupPreviewIdentity, widget.asGuardian),
          canAct: _lockedCanAct,
          canInteract: _lockedCanInteract,
          interactionEpoch: _localRequested ? _localOperationEpoch : null,
          personalCode: _code?.code,
          lookupCode: _lockedLookup,
          onCopy: _copy,
          onQr: _toggleQr,
          onShare: () => _share(context),
          extra: Column(
            children: [
              if (_showQr && _code != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: QrImageView(
                    data: _code!.code,
                    backgroundColor: Colors.white,
                    size: 160,
                  ),
                ),
              if (_localRequested) _localInformationContent(),
              if (widget.signupPreview && _signupPreviewNotice != null)
                Text(
                  _signupPreviewNotice!,
                  key: const ValueKey('signup_code_action_info'),
                  style: ZyraText.subtext(size: 12.5),
                ),
              if (_canEnterGuardianPreview)
                TextButton(
                  key: const ValueKey('onboarding_dev_skip'),
                  onPressed: ZyraTapFeedback.onTap(
                    context,
                    _enterGuardianPreview,
                  ),
                  child: const Text('Skip to Guardian · DEV'),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  AppBar _codeAppBar({bool denied = false}) {
    final hideInlineReturn =
        _localRequested && widget.previewLeading is ZyraInlineBackButton;
    final titleStyle = ZyraText.heading(size: 17);
    final title = 'Add a $_other';
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: !hideInlineReturn,
      leading: hideInlineReturn ? null : widget.previewLeading,
      title: denied ? null : Text(title, style: titleStyle),
      iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_localRequested && !_localOwnerAllows()) {
      return Scaffold(
        key: const ValueKey('zyra_code_local_preview_denied'),
        backgroundColor: ZyraColors.modalSheetSurface,
        appBar: _codeAppBar(denied: true),
        body: const SizedBox.expand(),
      );
    }
    if (widget.signupPreview && !_signupPreviewAllowed) {
      return Scaffold(
        key: const ValueKey('signup_code_preview_denied'),
        backgroundColor: ZyraColors.modalSheetSurface,
        body: const SizedBox.expand(),
      );
    }
    if (_localRequested || widget.signupPreview) return _lockedLocalPage();
    final previewStyle = widget.signupPreview
        ? OnboardingPreviewStyle.maybeOf(context)
        : null;
    return Scaffold(
      backgroundColor: _localRequested ? Colors.transparent : null,
      extendBodyBehindAppBar: !_localRequested && !widget.signupPreview,
      appBar: _codeAppBar(),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient:
              previewStyle?.backgroundGradient ??
              ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          child: _loading
              ? const ZyraLoading()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (_canUseExpandedComposition &&
                        constraints.maxHeight >= 620) {
                      return _buildExpandedComposition(
                        availableWidth: (constraints.maxWidth - 48)
                            .clamp(1.0, double.infinity)
                            .toDouble(),
                      );
                    }
                    return SingleChildScrollView(
                      controller: _screenScrollController,
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 44).clamp(
                            0.0,
                            double.infinity,
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildOwnCodeSection(
                                availableWidth: (constraints.maxWidth - 48)
                                    .clamp(1.0, double.infinity)
                                    .toDouble(),
                              ),
                              const SizedBox(height: 28),
                              if (!_available) ...[
                                ZyraErrorBanner(
                                  message:
                                      "Your ZYRA Code couldn't be refreshed.",
                                  onRetry: _load,
                                ),
                                const SizedBox(height: 18),
                              ],
                              const _OrDivider(),
                              const SizedBox(height: 28),
                              _buildOtherCodeActions(
                                availableWidth: (constraints.maxWidth - 48)
                                    .clamp(1.0, double.infinity)
                                    .toDouble(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _InlineEnterZyraCodePanel extends StatefulWidget {
  final String? initialCode;
  final bool asGuardian;
  final bool developerPreview;
  final double availableWidth;
  final ZyraCodeLocalPreview? localPreview;
  final bool Function([_LocalCodeEpoch? epoch])? localCanInteract;
  final _LocalCodeEpoch Function()? localEpoch;
  final _LocalCodeEpoch? localViewEpoch;
  final GlobalKey primaryActionKey;
  final VoidCallback onNeedsReveal;
  final VoidCallback onSent;

  const _InlineEnterZyraCodePanel({
    super.key,
    this.initialCode,
    required this.asGuardian,
    required this.developerPreview,
    required this.availableWidth,
    this.localPreview,
    this.localCanInteract,
    this.localEpoch,
    this.localViewEpoch,
    required this.primaryActionKey,
    required this.onNeedsReveal,
    required this.onSent,
  });

  @override
  State<_InlineEnterZyraCodePanel> createState() =>
      _InlineEnterZyraCodePanelState();
}

class _InlineEnterZyraCodePanelState extends State<_InlineEnterZyraCodePanel> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  ZyraPersonalCodePreview? _preview;
  String? _relationship;
  String? _error;
  bool _busy = false;
  bool _legacyPossible = false;
  bool _sent = false;
  String? _lastInvalidCode;
  late final ZyraCodeLocalPreview? _localPreview;
  late final bool Function([_LocalCodeEpoch? epoch])? _localCanInteract;
  late final _LocalCodeEpoch Function()? _localReadEpoch;
  late final bool _localRole;
  bool _localRequested = false;
  bool _localDenied = false;
  int _localCheckRevision = 0;
  _LocalCodeEpoch? _seenLocalEpoch;
  String? _localNotice;

  @override
  void initState() {
    super.initState();
    _localPreview = widget.localPreview;
    _localRequested = _localPreview != null;
    _localCanInteract = widget.localCanInteract;
    _localReadEpoch = widget.localEpoch;
    _localRole = widget.asGuardian;
    _seenLocalEpoch = widget.localViewEpoch;
    _controller = TextEditingController(text: widget.initialCode);
    _focusNode = FocusNode();
    if (widget.initialCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    ++_localCheckRevision;
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _InlineEnterZyraCodePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_localRequested || widget.localPreview != null) {
      _localRequested = true;
      if (!identical(widget.localPreview, _localPreview) ||
          widget.asGuardian != _localRole) {
        _denyLocal();
      } else if (_seenLocalEpoch != widget.localViewEpoch) {
        _seenLocalEpoch = widget.localViewEpoch;
        _resetLocalRead();
      }
    }
  }

  void _denyLocal() {
    _localDenied = true;
    _resetLocalRead();
  }

  /// Forget an interrupted check, not the user's fictional input. The local
  /// owner/mode latch remains unchanged and no stale identity is published.
  void _resetLocalRead() {
    ++_localCheckRevision;
    _preview = null;
    _relationship = null;
    _error = null;
    _busy = false;
    _legacyPossible = false;
    _lastInvalidCode = null;
    _sent = false;
    _localNotice = null;
  }

  bool _localAllows([_LocalCodeEpoch? epoch]) {
    if (!mounted || !_localRequested || _localDenied) return false;
    if (_localPreview == null ||
        !identical(widget.localPreview, _localPreview) ||
        widget.asGuardian != _localRole ||
        _localCanInteract == null ||
        _localReadEpoch == null) {
      _denyLocal();
      return false;
    }
    try {
      return _localCanInteract(epoch);
    } catch (_) {
      _denyLocal();
      return false;
    }
  }

  VoidCallback _localBound(VoidCallback action) {
    if (!_localRequested) return action;
    if (_localDenied || _localReadEpoch == null) return () {};
    final epoch = _localReadEpoch();
    return () {
      if (_localAllows(epoch)) action();
    };
  }

  ValueChanged<bool> _relationshipSelection(String code) {
    final select = _localBound(() => setState(() => _relationship = code));
    return (_) => select();
  }

  Future<void> _checkLocal() async {
    if (!_localAllows() || _busy) return;
    final epoch = _localReadEpoch!();
    final revision = ++_localCheckRevision;
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
      _relationship = null;
      _legacyPossible = false;
      _lastInvalidCode = null;
      _localNotice = null;
    });
    // Real and old invitation codes never reach a lookup or live fallback.
    ZyraPersonalCodePreview? preview;
    if (RegExp(r'^ZYRA-DEMO-[A-Z0-9]+(?:-[A-Z0-9]+)*$').hasMatch(code)) {
      try {
        preview = await _localPreview!.lookupCode(code);
      } catch (_) {
        // A failed fictional lookup is a neutral local invalid-code result.
      }
    }
    if (!_localAllows(epoch) ||
        revision != _localCheckRevision ||
        code != _controller.text.trim().toUpperCase()) {
      // A caller can change its overlay epoch before rebuilding this child.
      // Only clear the superseded operation, never a newer successful check.
      if (mounted &&
          !_localDenied &&
          revision == _localCheckRevision &&
          _localReadEpoch() != epoch) {
        setState(() {
          _seenLocalEpoch = _localReadEpoch();
          _resetLocalRead();
        });
      }
      return;
    }
    final resolved = preview;
    if (resolved == null ||
        resolved.firstName.trim().isEmpty ||
        resolved.role != (_localRole ? 'seeker' : 'wali')) {
      _showInvalidCode(legacyPossible: false);
    } else {
      setState(() {
        _busy = false;
        _preview = ZyraPersonalCodePreview(
          firstName: resolved.firstName.trim(),
          role: resolved.role,
        );
      });
      _focusNode.unfocus();
    }
    if (_localAllows(epoch)) widget.onNeedsReveal();
  }

  void _showInvalidCode({required bool legacyPossible}) {
    final epoch = _localRequested ? _localReadEpoch!() : null;
    if (_localRequested && !_localAllows(epoch)) return;
    final invalidCode = _controller.text.trim();
    setState(() {
      _busy = false;
      _preview = null;
      _relationship = null;
      _error = 'Invalid code. Please try again.';
      _legacyPossible = legacyPossible;
      _lastInvalidCode = invalidCode.isEmpty ? null : invalidCode;
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (!_localRequested || _localAllows(epoch))) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _check() async {
    if (_localRequested) {
      await _checkLocal();
      return;
    }
    if (_controller.text.trim().isEmpty) return;
    _recordCodeEvent(
      ZyraTelemetryEventName.started,
      ZyraTelemetryAction.zyraCodeCheck,
    );
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
      _legacyPossible = false;
      _lastInvalidCode = null;
    });
    if (widget.developerPreview) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted || _localRequested) return;
      final preview = ZyraDevPersonalCodeFixtures.previewEntryCode(
        _controller.text,
        asGuardian: widget.asGuardian,
      );
      if (preview == null) {
        _showInvalidCode(legacyPossible: false);
      } else {
        setState(() {
          _busy = false;
          _preview = preview;
        });
      }
      _recordCodeEvent(
        preview == null
            ? ZyraTelemetryEventName.failed
            : ZyraTelemetryEventName.completed,
        ZyraTelemetryAction.zyraCodeCheck,
      );
      if (preview != null) _focusNode.unfocus();
      widget.onNeedsReveal();
      return;
    }
    final result = await ZyraWaliLinkService.previewPersonalCode(
      _controller.text,
    );
    if (!mounted || _localRequested) return;
    if (result.isAvailable && result.valueOrNull == null) {
      _showInvalidCode(legacyPossible: true);
    } else {
      setState(() {
        _busy = false;
        if (result.isUnavailable) {
          _error = "The code couldn't be checked. Please try again.";
        } else {
          _preview = result.valueOrNull;
        }
      });
    }
    _recordCodeEvent(
      _preview == null
          ? ZyraTelemetryEventName.failed
          : ZyraTelemetryEventName.completed,
      ZyraTelemetryAction.zyraCodeCheck,
    );
    if (_preview != null) _focusNode.unfocus();
    widget.onNeedsReveal();
  }

  Future<void> _send() async {
    if (_localRequested) {
      if (!_localAllows() || _busy || _preview == null) return;
      if (_preview!.role == 'seeker' && _relationship == null) {
        setState(() => _error = 'Choose how you are related first.');
        return;
      }
      setState(
        () => _localNotice =
            'No invitation was sent. This local preview does not create '
            'requests or connect accounts.',
      );
      return;
    }
    final preview = _preview;
    if (preview == null) return;
    if (preview.role == 'seeker' && _relationship == null) {
      setState(() => _error = 'Choose how you are related first.');
      return;
    }
    _recordCodeEvent(
      ZyraTelemetryEventName.started,
      ZyraTelemetryAction.zyraCodeRequest,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    if (widget.developerPreview) {
      if (!widget.asGuardian) {
        final capacity = ZyraGuardianCapacity.fromCount(
          plan: AppState.instance.plan,
          linkedGuardianCount: ZyraDevScenario.instance.guardianCount,
        );
        if (!capacity.canAdd) {
          setState(() {
            _busy = false;
            _error = capacity.message;
          });
          showZyraGuardianCapacityNotice(context, capacity.message);
          return;
        }
      }
      await ZyraInteractionStyle.emitSelectionHaptic();
      if (!mounted || _localRequested) return;
      setState(() {
        _busy = false;
        _sent = true;
      });
      _recordCodeEvent(
        ZyraTelemetryEventName.completed,
        ZyraTelemetryAction.zyraCodeRequest,
      );
      return;
    }
    final error = await ZyraWaliLinkService.requestGuardianLink(
      _controller.text,
      relationship: preview.role == 'seeker' ? _relationship : null,
      currentSeekerPlan: widget.asGuardian ? null : AppState.instance.plan,
    );
    if (!mounted || _localRequested) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    showZyraGuardianCapacityNotice(context, error);
    _recordCodeEvent(
      error == null
          ? ZyraTelemetryEventName.completed
          : ZyraTelemetryEventName.failed,
      ZyraTelemetryAction.zyraCodeRequest,
    );
    if (error == null) widget.onSent();
  }

  void _recordCodeEvent(
    ZyraTelemetryEventName name,
    ZyraTelemetryAction action,
  ) {
    if (_localRequested) return;
    ZyraProductTelemetry.instance.record(
      feature: ZyraTelemetryFeature.zyraCode,
      name: name,
      action: action,
      surface: widget.asGuardian
          ? ZyraTelemetrySurface.guardian
          : ZyraTelemetrySurface.seeker,
    );
  }

  void _useDifferentCode() {
    final epoch = _localRequested ? _localReadEpoch!() : null;
    if (_localRequested && !_localAllows(epoch)) return;
    ++_localCheckRevision;
    setState(() {
      _preview = null;
      _relationship = null;
      _error = null;
      _legacyPossible = false;
      _lastInvalidCode = null;
      _localNotice = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _localRequested && !_localAllows(epoch)) return;
      _focusNode.requestFocus();
      widget.onNeedsReveal();
    });
  }

  Widget _buildPersonInitial(String firstName) {
    final initial = firstName.substring(0, 1).toUpperCase();
    final style = ZyraText.heading(size: 20, color: ZyraColors.goldText);
    final text = _codeTextSize(context, initial, style);
    final textExtent = text.height > text.width ? text.height : text.width;
    final dimension = _localRequested && textExtent + 18 > 48
        ? textExtent + 18
        : 48.0;
    return Container(
      key: const ValueKey('zyra_code_person_initial'),
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZyraColors.accentBg,
        border: Border.all(color: ZyraColors.accentBorder),
      ),
      child: Center(child: Text(initial, style: style)),
    );
  }

  Widget _buildConfirmationActions() {
    final change = _PillAction(
      key: const ValueKey('inline-code-different-action'),
      icon: Icons.refresh_rounded,
      label: 'Change code',
      adaptive: _localRequested,
      enableFeedback: !_localRequested,
      onTap: _busy ? null : _localBound(_useDifferentCode),
    );
    final confirmLabel = _busy ? 'Sending…' : 'Confirm';
    final confirm = KeyedSubtree(
      key: widget.primaryActionKey,
      child: _PillAction(
        key: const ValueKey('inline-code-primary-action'),
        icon: Icons.person_add_alt_1_outlined,
        label: confirmLabel,
        adaptive: _localRequested,
        enableFeedback: !_localRequested,
        onTap: _busy ? null : _localBound(_send),
      ),
    );
    final style = ZyraText.body(size: 12.5, color: ZyraColors.goldText);
    final requiredWidth = ['Change code', confirmLabel]
        .map(
          (label) => _codeTextSize(context, label, style).width + 17 + 7 + 34,
        )
        .reduce((a, b) => a > b ? a : b);
    if (!_localRequested || requiredWidth <= (widget.availableWidth - 10) / 2) {
      return Row(
        children: [
          Expanded(child: change),
          const SizedBox(width: 10),
          Expanded(child: confirm),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [change, const SizedBox(height: 10), confirm],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_localRequested && (_localDenied || _localReadEpoch == null)) {
      return const SizedBox.shrink();
    }
    final needsRelationship = _preview?.role == 'seeker';
    final changedEntry = _localBound(
      () => setState(() {
        _relationship = null;
        _error = null;
        _legacyPossible = false;
        _lastInvalidCode = null;
        if (_localRequested) {
          ++_localCheckRevision;
          _busy = false;
          _preview = null;
          _localNotice = null;
        }
      }),
    );
    final submittedEntry = _localBound(() {
      if (!_busy) _check();
    });
    if (_sent) {
      return Column(
        key: const ValueKey('inline-zyra-code-entry'),
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ZyraColors.accentBg,
              border: Border.all(color: ZyraColors.accentBorder),
            ),
            child: Icon(Icons.check_rounded, color: ZyraColors.surfaceSignal),
          ),
          const SizedBox(height: 10),
          Text('Request sent', style: ZyraText.heading(size: 16)),
          const SizedBox(height: 4),
          Text(
            '${_preview!.firstName} can now accept or decline it.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 12),
          ),
        ],
      );
    }
    return Column(
      key: const ValueKey('inline-zyra-code-entry'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_preview == null)
          Container(
            key: const ValueKey('inline-code-composer'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: ZyraColors.iconButtonBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZyraColors.iconButtonBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('inline-zyra-code-field'),
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: widget.initialCode == null,
                    scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 220),
                    textCapitalization: TextCapitalization.characters,
                    style: ZyraText.body(size: 14),
                    decoration: const InputDecoration(
                      hintText: 'ZYRA-XXXX-XXXX-XXXX-XXXX-XXXX',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => changedEntry(),
                    onSubmitted: (_) => submittedEntry(),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: ZyraColors.iconButtonBorder,
                ),
                KeyedSubtree(
                  key: widget.primaryActionKey,
                  child: Semantics(
                    button: true,
                    label: _busy ? 'Checking code' : 'Check code',
                    child: Material(
                      key: const ValueKey('inline-code-primary-action'),
                      color: ZyraColors.accentBg,
                      child: InkWell(
                        enableFeedback: !_localRequested,
                        onTap: ZyraTapFeedback.onTap(
                          context,
                          _busy ? null : _localBound(_check),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 96,
                            minHeight: 52,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_outlined,
                                  size: 17,
                                  color: ZyraColors.surfaceSignal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _busy ? 'Checking…' : 'Check',
                                  style: ZyraText.button(
                                    size: 12.5,
                                    color: ZyraColors.goldText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_preview case final preview?) ...[
          Container(
            key: const ValueKey('zyra-code-person-confirmation'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ZyraColors.iconButtonBg,
              border: Border.all(color: ZyraColors.iconButtonBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildPersonInitial(preview.firstName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(preview.firstName, style: ZyraText.body(size: 15)),
                      const SizedBox(height: 2),
                      Text(
                        preview.role == 'wali' ? 'Guardian' : 'Seeker',
                        style: ZyraText.subtext(size: 11.5),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.person_outline_rounded,
                  size: 19,
                  color: ZyraColors.surfaceSignal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Confirm this is the right person before sending your request.',
            style: ZyraText.subtext(size: 11.5),
          ),
          if (needsRelationship) ...[
            const SizedBox(height: 14),
            Text('How are you related?', style: ZyraText.body(size: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final relationship in zyraGuardianRelationships)
                  ChoiceChip(
                    label: Text(relationship.name),
                    selected: _relationship == relationship.code,
                    onSelected: ZyraTapFeedback.onChanged(
                      context,
                      _relationshipSelection(relationship.code),
                    ),
                  ),
              ],
            ),
          ],
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 10),
          ZyraErrorBanner(
            message: error,
            onDismiss: _localBound(() => setState(() => _error = null)),
          ),
        ],
        if (_legacyPossible)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: ZyraTapFeedback.onTap(
                context,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AcceptWaliInviteScreen(
                      initialCode: _lastInvalidCode ?? _controller.text,
                    ),
                  ),
                ),
              ),
              child: Text(
                'Check an older invite code',
                style: ZyraText.subtext(size: 11.5),
              ),
            ),
          ),
        if (_preview != null) ...[
          const SizedBox(height: 10),
          _buildConfirmationActions(),
        ],
        if (_localNotice case final notice?) ...[
          const SizedBox(height: 10),
          Text(
            notice,
            key: const ValueKey('zyra_code_local_confirmation_notice'),
            style: ZyraText.subtext(size: 12),
          ),
        ],
      ],
    );
  }
}

class _PillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enableFeedback;
  final bool adaptive;

  const _PillAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.enableFeedback = true,
    this.adaptive = false,
  });

  Widget _content() => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 17, color: ZyraColors.surfaceSignal),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          label,
          maxLines: adaptive ? null : 1,
          overflow: adaptive ? TextOverflow.visible : TextOverflow.ellipsis,
          softWrap: adaptive ? true : null,
          style: ZyraText.body(size: 12.5, color: ZyraColors.goldText),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZyraColors.accentBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        enableFeedback: enableFeedback,
        onTap: ZyraTapFeedback.onTap(context, onTap),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: ZyraColors.accentBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: _content(),
        ),
      ),
    );
  }
}

class _ScanZyraCodeScreen extends StatefulWidget {
  const _ScanZyraCodeScreen();

  @override
  State<_ScanZyraCodeScreen> createState() => _ScanZyraCodeScreenState();
}

class _ScanZyraCodeScreenState extends State<_ScanZyraCodeScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Scan ZYRA Code', style: ZyraText.heading(size: 17)),
        backgroundColor: Colors.black,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          for (final barcode in capture.barcodes) {
            final value = barcode.rawValue?.trim();
            if (value != null && value.toUpperCase().startsWith('ZYRA')) {
              _handled = true;
              Navigator.of(context).pop(value);
              return;
            }
          }
        },
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final String code;
  final bool demoOnly;
  final bool prominent;
  final bool showQr;
  const _CodeCard({
    required this.code,
    required this.demoOnly,
    this.prominent = false,
    this.showQr = false,
  });

  Widget _details() => Column(
    key: const ValueKey('zyra_code_details'),
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'YOUR ZYRA CODE',
        style: ZyraText.chapterLabel(color: ZyraColors.ink(0.58)),
      ),
      SizedBox(height: prominent ? 18 : 12),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          code,
          style: ZyraText.heading(
            size: prominent ? 24 : 20,
          ).copyWith(letterSpacing: 1.3),
        ),
      ),
      SizedBox(height: prominent ? 14 : 9),
      Text(
        'They can send a request. You still choose whether to link.',
        textAlign: TextAlign.center,
        style: ZyraText.subtext(size: prominent ? 13 : 11.5),
      ),
      if (demoOnly) ...[
        SizedBox(height: prominent ? 14 : 10),
        Text(
          'Developer preview only — not stored or accepted by the live service.',
          textAlign: TextAlign.center,
          style: ZyraText.subtext(
            size: prominent ? 11.5 : 10.5,
          ).copyWith(color: ZyraColors.goldText),
        ),
      ],
    ],
  );

  Widget _qrPreview() => Column(
    key: const ValueKey('zyra_code_qr_preview'),
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'YOUR ZYRA QR CODE',
        style: ZyraText.chapterLabel(color: ZyraColors.ink(0.58)),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: QrImageView(
          data: code,
          size: prominent ? 184 : 156,
          padding: EdgeInsets.zero,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Tap QR again to return',
        style: ZyraText.subtext(size: prominent ? 11.5 : 10.5),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 174),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        border: Border.all(color: ZyraColors.surfaceBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          reverseDuration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.center,
            children: [...previousChildren, ?currentChild],
          ),
          transitionBuilder: (child, animation) {
            final entrance = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: entrance,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.965, end: 1).animate(entrance),
                child: child,
              ),
            );
          },
          child: showQr ? _qrPreview() : _details(),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: ZyraColors.ink(0.20))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR USE THEIR CODE',
            style: ZyraText.chapterLabel(color: ZyraColors.ink(0.48)),
          ),
        ),
        Expanded(child: Divider(color: ZyraColors.ink(0.20))),
      ],
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final double height;
  final bool? prominent;
  final bool adaptive;
  final bool selected;
  final bool pulse;
  final int pulseRevision;
  final VoidCallback? onTap;
  final bool enableFeedback;
  const _SmallAction({
    required this.icon,
    required this.label,
    this.height = 54,
    this.prominent,
    this.adaptive = false,
    this.selected = false,
    this.pulse = false,
    this.pulseRevision = 0,
    this.onTap,
    this.enableFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final large = prominent ?? height > 54;
    final labelWidget = Text(
      label,
      style: ZyraText.body(
        size: large ? 13.5 : 12.5,
        color: selected ? ZyraColors.goldText : null,
      ),
    );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        enableFeedback: enableFeedback,
        onTap: ZyraTapFeedback.onTap(context, onTap),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: height,
          decoration: BoxDecoration(
            color: pulse
                ? ZyraColors.surfaceSignal.withValues(alpha: 0.22)
                : selected
                ? ZyraColors.accentBg
                : ZyraColors.iconButtonBg,
            border: Border.all(
              color: pulse
                  ? ZyraColors.surfaceSignal
                  : selected
                  ? ZyraColors.accentBorder
                  : ZyraColors.iconButtonBorder,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: large ? 19 : 17,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.68,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    icon,
                    key: ValueKey('small-action-$label-$pulseRevision'),
                    size: large ? 19 : 17,
                    color: selected
                        ? ZyraColors.surfaceSignal
                        : ZyraColors.ink(0.70),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (adaptive) Flexible(child: labelWidget) else labelWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enableFeedback;
  const _LargeAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.enableFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        enableFeedback: enableFeedback,
        onTap: ZyraTapFeedback.onTap(context, onTap),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: ZyraColors.surfaceBorder),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(icon, size: 21, color: ZyraColors.surfaceSignal),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: ZyraText.body(size: 14))),
              Icon(Icons.chevron_right, size: 19, color: ZyraColors.ink(0.48)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ZyraGuardianLinkRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;

  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        border: Border.all(color: ZyraColors.surfaceBorder),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(request.otherFirstName, style: ZyraText.body(size: 15)),
          const SizedBox(height: 3),
          Text(
            request.isIncoming
                ? 'Wants to link with you'
                : 'Waiting for their answer',
            style: ZyraText.subtext(size: 11.5),
          ),
          if (request.isIncoming) ...[
            const SizedBox(height: 8),
            Text(
              ZyraMembershipCatalog.guardianAccessTerms,
              style: ZyraText.subtext(size: 10.75),
            ),
          ],
          const SizedBox(height: 12),
          if (busy)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            )
          else if (request.isIncoming)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: ZyraTapFeedback.onTap(context, onDecline),
                    child: const Text('Decline'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: ZyraTapFeedback.onTap(context, onAccept),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: ZyraTapFeedback.onTap(context, onCancel),
                child: const Text('Cancel request'),
              ),
            ),
        ],
      ),
    );
  }
}
