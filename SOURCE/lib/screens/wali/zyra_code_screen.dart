import 'accept_wali_invite_screen.dart';
import '../../widgets/zyra_tap_feedback.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/zyra_membership_catalog.dart';
import '../../data/zyra_reference_data.dart';
import '../../data/zyra_guardian_capacity.dart';
import '../../dev/zyra_dev_scenario.dart';
import '../../dev/zyra_draft_local_code_page.dart';
import '../../dev/zyra_draft_local_code_aliases.dart';
import '../../dev/zyra_dev_personal_code_fixtures.dart';
import '../../models/zyra_initial_signup_draft.dart';
import '../../models/zyra_code_format.dart';
import '../../models/zyra_code_link.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_app_lock.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_code_link_coordinator.dart';
import '../../services/zyra_code_link_service.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_guardian_capacity_notice.dart';
import '../../widgets/zyra_confirm_sheet.dart';
import '../../widgets/zyra_pull_down_back_scope.dart';

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
    this.confirmRotation,
  });

  final bool Function() canAct;
  final ZyraPersonalCode personalCode;
  final Future<ZyraPersonalCodePreview?> Function(String code) lookupCode;
  final bool Function()? canInteract;

  /// The preview host can authorize the exact confirmation covering its page.
  final Future<bool> Function({
    required String title,
    required String body,
    required String primaryLabel,
    required String secondaryLabel,
    required IconData icon,
    required bool Function() canCommit,
  })?
  confirmRotation;

  /// A caller-owned monotonic revision for covers which do not push a route.
  /// Increase it on both cover and uncover, not only while an overlay is open.
  final int Function()? interactionEpoch;
}

typedef _LocalCodeEpoch = ({int local, int caller});

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
  final String? initialCode;
  final ZyraPersonalCodePreview? initialCodePreview;
  final String? initialCodeError;
  final bool acceptSignupCodeLink;

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
    this.initialCode,
    this.initialCodePreview,
    this.initialCodeError,
    this.acceptSignupCodeLink = false,
  });

  @override
  State<ZyraCodeScreen> createState() => _ZyraCodeScreenState();
}

class _ZyraCodeScreenState extends State<ZyraCodeScreen>
    with WidgetsBindingObserver {
  ZyraPersonalCode? _code;
  (String?, int, bool)? _codeReadScope;
  List<ZyraGuardianLinkRequest> _requests = const [];
  bool _loading = true;
  bool _available = true;
  bool _copied = false;
  bool _rotating = false;
  int _previewRotations = 0;
  String? _relationship;
  String? _error;
  String? _busyRequest;
  int _readRevision = 0;
  String? _rowsOwnerId;
  int _rowsOwnerGeneration = -1;
  bool _requestMutationInFlight = false;
  String? _signupPreviewNotice;
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
  bool _signupCodeLinkRegistered = false;
  ZyraLocalCodeLinkEntry? _linkEntry;
  (String?, int)? _linkEntryOwner;
  int _localEpoch = 0;
  bool? _localRouteCurrent;
  AppLifecycleState? _localLifecycle;
  String? _localNotice;

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
    final initialCode = widget.initialCode;
    if (!_isFounderDemoPreview && initialCode != null) {
      final preview = widget.initialCodePreview;
      _linkEntry = ZyraLocalCodeLinkEntry(
        initialCode,
        person: preview == null
            ? null
            : ZyraLocalCodeIdentity(
                preview.firstName,
                preview.role == 'wali' ? 'Guardian' : 'Seeker',
              ),
        error: widget.initialCodeError,
      );
      _linkEntryOwner = (_currentMemberId(), ZyraAccountState.generation);
    }
    _registerSignupCodeLink();
    _load();
  }

  @override
  void dispose() {
    ++_localEpoch;
    if (_signupCodeLinkRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      ZyraAppLock.instance.removeListener(_notifySignupCodeLink);
      ZyraCodeLinkCoordinator.instance.guardianSignupUnmounted(this);
    }
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
    _notifySignupCodeLink();
    if (!_localRequested) return;
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (_localRouteCurrent != null && _localRouteCurrent != current) {
      ++_localEpoch;
    }
    _localRouteCurrent = current;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _notifySignupCodeLink();
    if (!_localRequested) return;
    _localLifecycle = state;
    ++_localEpoch;
    if (mounted) {
      setState(() {
        _localOwnerAllows();
      });
    }
  }

  void _notifySignupCodeLink() {
    if (_signupCodeLinkRegistered) {
      ZyraCodeLinkCoordinator.instance.presentationChanged();
    }
  }

  void _registerSignupCodeLink() {
    if (!widget.acceptSignupCodeLink || !_localRole || _isFounderDemoPreview) {
      return;
    }
    final owner = _currentMemberId();
    final generation = ZyraAccountState.generation;
    if (owner == null || !_isCurrentAccount(owner, generation)) return;
    final lock = ZyraAppLock.instance;
    final binding = WidgetsBinding.instance;
    bool isCurrent() =>
        mounted &&
        widget.acceptSignupCodeLink &&
        widget.asGuardian &&
        !_isFounderDemoPreview &&
        _isCurrentAccount(owner, generation) &&
        !lock.isLocked &&
        !lock.isObscured &&
        binding.lifecycleState == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true;

    _signupCodeLinkRegistered = true;
    binding.addObserver(this);
    lock.addListener(_notifySignupCodeLink);
    ZyraCodeLinkCoordinator.instance.guardianSignupMounted(
      this,
      userId: owner,
      isCurrent: isCurrent,
      open: (code, result) {
        if (!isCurrent()) return;
        final name = result.firstName;
        final person =
            result.outcome == ZyraCodeLinkOutcome.addSeeker && name != null
            ? ZyraLocalCodeIdentity(name, 'Seeker')
            : null;
        final error = switch (result.outcome) {
          ZyraCodeLinkOutcome.rateLimited => zyraCodeRateLimitMessage,
          ZyraCodeLinkOutcome.failed =>
            "The code couldn't be checked. Please try again.",
          _ => null,
        };
        setState(() {
          _relationship = null;
          _linkEntry = ZyraLocalCodeLinkEntry(
            code,
            person: person,
            error: error,
          );
          _linkEntryOwner = (owner, generation);
        });
      },
    );
  }

  void _revokeLocal() {
    if (_localDenied) return;
    _localDenied = true;
    ++_localEpoch;
    ++_readRevision;
    _code = null;
    _codeReadScope = null;
    _requests = const [];
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

  void _localAuthorityChanged() {
    if (!mounted || !_localRequested) return;
    ++_localEpoch;
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
        _codeReadScope = null;
        _requests = const [];
        _signupPreviewNotice = null;
      });
    }
  }

  void _signupInformation(String message) {
    if (!_signupPreviewAllowed) return;
    setState(() => _signupPreviewNotice = message);
  }

  Future<void> _load({bool keepRows = false}) async {
    if (_localRequested) {
      if (!_localOwnerAllows()) return;
      setState(() {
        _code ??= _localPreview!.personalCode;
        _codeReadScope = null;
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
          _copied = false;
        }
        if (_previewRotations == 0 || _code == null) _code = nextCode;
        _codeReadScope = null;
        _requests = const [];
        _loading = false;
        _available = true;
        _error = null;
      });
      return;
    }
    final ownerId = _currentMemberId();
    final generation = ZyraAccountState.generation;
    final asGuardian = widget.asGuardian;
    final results = await Future.wait<Object>([
      (widget.loadPersonalCode ?? ZyraWaliLinkService.personalCode)(
        roleContext: asGuardian ? 'wali' : 'seeker',
      ),
      (widget.loadGuardianRequests ??
          ZyraWaliLinkService.guardianLinkRequests)(),
    ]);
    if (readRevision != _readRevision ||
        _isFounderDemoPreview ||
        asGuardian != widget.asGuardian ||
        !_isCurrentAccount(ownerId, generation)) {
      return;
    }
    final codeResult = results[0] as ZyraSourceResult<ZyraPersonalCode>;
    final requestResult =
        results[1] as ZyraSourceResult<List<ZyraGuardianLinkRequest>>;
    setState(() {
      _loading = false;
      _available = codeResult.isAvailable && requestResult.isAvailable;
      final codeValue = codeResult.valueOrNull;
      if (codeValue != null &&
          codeValue.roleContext == (asGuardian ? 'wali' : 'seeker')) {
        final value = codeValue;
        if (_code?.code != null && _code!.code != value.code) {
          _copied = false;
        }
        _code = value;
        _codeReadScope = (ownerId, generation, asGuardian);
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

  bool _canUseMemberCode(ZyraPersonalCode code) {
    final scope = _codeReadScope;
    return scope != null &&
        scope.$1 != null &&
        _isCurrentAccount(scope.$1, scope.$2) &&
        widget.asGuardian == scope.$3 &&
        !_isFounderDemoPreview &&
        identical(code, _code);
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
    final code = _code;
    if (code == null ||
        _rotating ||
        (!_isFounderDemoPreview && !_canUseMemberCode(code))) {
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: code.code));
      if (mounted && identical(_code, code)) setState(() => _copied = true);
    } on PlatformException {
      if (mounted) _toast("Your code couldn't be copied. Please try again.");
    }
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
    final code = _code;
    if (code == null ||
        _rotating ||
        (!_isFounderDemoPreview && !_canUseMemberCode(code))) {
      return;
    }
    final preview = _isFounderDemoPreview;
    final link = preview ? null : zyraCodeLinkFor(code.code);
    if (!preview && link == null) return;
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: preview
              ? 'ZYRA Developer Preview code:\n${code.code}\n\n'
                    'This sample code cannot connect real accounts.'
              : 'Here’s my ZYRA Code. Open it in ZYRA to send me a request:\n'
                    '$link',
          subject: 'My ZYRA Code',
          sharePositionOrigin: origin,
        ),
      );
    } on PlatformException {
      if (mounted) _toast("Your code couldn't be shared. Please try again.");
    }
  }

  void _toast(String message) => ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));

  Future<void> _rotate() async {
    final origin = ModalRoute.of(context);
    final code = _code;
    if (_rotating || origin?.isCurrent != true || code == null) return;
    final asGuardian = widget.asGuardian;
    final preview = _isFounderDemoPreview;
    final generation = ZyraAccountState.generation;
    final session = ZyraInternalPreviewClient.previewSession;
    final confirmRotation = _localPreview?.confirmRotation;
    bool sameCode({
      bool requireForeground = true,
      bool inOwnedConfirmation = false,
    }) {
      if (!mounted ||
          code.code != _code?.code ||
          widget.asGuardian != asGuardian) {
        return false;
      }
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (requireForeground &&
          lifecycle != null &&
          lifecycle != AppLifecycleState.resumed) {
        return false;
      }
      if (!preview) {
        return ZyraAccountState.generation == generation &&
            _canUseMemberCode(_code!);
      }
      if (!_isFounderDemoPreview ||
          ZyraAccountState.generation != generation ||
          ZyraInternalPreviewClient.previewSession != session) {
        return false;
      }
      try {
        return _localRequested
            ? _localOwnerAllows() &&
                  (inOwnedConfirmation ||
                      (_localPreview?.canInteract?.call() ?? true))
            : ZyraDeveloperAccess.canUseDeveloperTools;
      } catch (_) {
        return false;
      }
    }

    if (!sameCode()) return;
    setState(() => _rotating = true);
    try {
      const title = 'Get a new code?';
      const body =
          'Your current code and QR stop working straight away. Anyone you shared it with will need the new one. Requests already sent to you stay.';
      const primaryLabel = 'Get new code';
      const secondaryLabel = 'Keep my code';
      const icon = Icons.refresh_rounded;
      final confirmed = confirmRotation != null
          ? await confirmRotation(
              icon: icon,
              title: title,
              body: body,
              primaryLabel: primaryLabel,
              secondaryLabel: secondaryLabel,
              canCommit: () => sameCode(inOwnedConfirmation: true),
            )
          : await showZyraConfirm(
              context: context,
              icon: icon,
              title: title,
              body: body,
              primaryLabel: primaryLabel,
              secondaryLabel: secondaryLabel,
              canConfirm: () => sameCode(),
            );
      if (confirmed != true || !sameCode() || origin?.isCurrent != true) return;
      final role = asGuardian ? 'wali' : 'seeker';
      final next = preview
          ? ZyraPersonalCode(
              code: _previewRotations == 0
                  ? 'ZYRA-7K2M-Q9TD-4H8P-2XJW-R6NB'
                  : ZyraCodeFormat.grouped(
                      '7K2MQ9TD4H8P2XJW${(_previewRotations + 1).toRadixString(36).toUpperCase().padLeft(4, '0')}',
                    ),
              roleContext: role,
            )
          : (await ZyraWaliLinkService.rotatePersonalCode(
              roleContext: role,
            )).valueOrNull;
      if (!sameCode(requireForeground: false)) return;
      if (next == null || next.roleContext != role || next.code == code.code) {
        setState(
          () => _error = "Your code couldn't be changed. Please try again.",
        );
        return;
      }
      ++_readRevision; // A read started before rotation must not restore the old QR.
      setState(() {
        if (preview) ++_previewRotations;
        _code = next;
        _copied = false;
        _error = null;
      });
      if (origin?.isCurrent == true) {
        _toast('New code ready. Your old code no longer works.');
      }
    } finally {
      if (mounted) setState(() => _rotating = false);
    }
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
      final seekerPlan = request.otherRole == 'seeker'
          ? null
          : AppState.instance.verifiedSeekerPlan ?? ZyraPlan.basic;
      final error = await ZyraWaliLinkService.acceptGuardianLinkRequest(
        request.id,
        relationship: relationship,
        currentSeekerPlan: seekerPlan,
        isActionCurrent: () =>
            _isCurrentRequestAction(owner.ownerId, owner.generation) &&
            (seekerPlan == null ||
                (AppState.instance.verifiedSeekerPlan ?? ZyraPlan.basic) ==
                    seekerPlan) &&
            _requests.any((row) => row.id == request.id && row.isPending),
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

  Future<ZyraLocalCodeIdentity?> _lookup(
    String canonical,
    bool Function() isCurrent,
  ) async {
    if (!isCurrent()) return null;
    ZyraPersonalCodePreview? person;
    _relationship = null;
    if (_localRequested) {
      if (!_localInteractive()) return null;
      person = await _localPreview!.lookupCode(canonical);
      if (!_localInteractive()) return null;
    } else if (_isFounderDemoPreview) {
      person = ZyraDevPersonalCodeFixtures.previewEntryCode(
        canonical,
        asGuardian: widget.asGuardian,
      );
    } else {
      _recordCodeEvent(
        ZyraTelemetryEventName.started,
        ZyraTelemetryAction.zyraCodeCheck,
      );
      final result = await ZyraWaliLinkService.previewPersonalCode(
        canonical,
        isCurrent: isCurrent,
      );
      if (!isCurrent()) return null;
      _recordCodeEvent(
        result.valueOrNull == null
            ? ZyraTelemetryEventName.failed
            : ZyraTelemetryEventName.completed,
        ZyraTelemetryAction.zyraCodeCheck,
      );
      if (result.failure == ZyraSourceFailure.codeRateLimited) {
        throw const ZyraCodeCheckFailure(zyraCodeRateLimitMessage);
      }
      if (result.isUnavailable) {
        throw const ZyraCodeCheckFailure(
          "The code couldn't be checked. Please try again.",
        );
      }
      person = result.valueOrNull;
    }
    if (person == null) return null;
    return ZyraLocalCodeIdentity(
      person.firstName,
      person.role == 'wali' ? 'Guardian' : 'Seeker',
    );
  }

  void _recordCodeEvent(
    ZyraTelemetryEventName event,
    ZyraTelemetryAction action,
  ) => ZyraProductTelemetry.instance.record(
    feature: ZyraTelemetryFeature.zyraCode,
    name: event,
    action: action,
    surface: widget.asGuardian
        ? ZyraTelemetrySurface.guardian
        : ZyraTelemetrySurface.seeker,
  );

  Future<String?> _send(
    String code,
    ZyraLocalCodeIdentity person,
    bool Function() current,
  ) async {
    final owner = _currentMemberId();
    final generation = ZyraAccountState.generation;
    final asGuardian = widget.asGuardian;
    final plan = asGuardian
        ? null
        : AppState.instance.verifiedSeekerPlan ?? ZyraPlan.basic;
    bool canSend() =>
        current() &&
        owner != null &&
        _isCurrentRequestAction(owner, generation) &&
        widget.asGuardian == asGuardian &&
        (plan == null ||
            (AppState.instance.verifiedSeekerPlan ?? ZyraPlan.basic) == plan);
    if (!canSend()) return "That request didn't go through. Please try again.";
    final relationship = asGuardian ? _relationship : null;
    if (asGuardian && relationship == null) {
      return 'Choose how you are related first.';
    }
    _recordCodeEvent(
      ZyraTelemetryEventName.started,
      ZyraTelemetryAction.zyraCodeRequest,
    );
    final error = await ZyraWaliLinkService.requestGuardianLink(
      code,
      relationship: relationship,
      currentSeekerPlan: plan,
      isActionCurrent: canSend,
    );
    if (mounted && canSend()) {
      _recordCodeEvent(
        error == null
            ? ZyraTelemetryEventName.completed
            : ZyraTelemetryEventName.failed,
        ZyraTelemetryAction.zyraCodeRequest,
      );
      showZyraGuardianCapacityNotice(context, error);
      if (error == null) _load(keepRows: true);
    }
    return error;
  }

  Widget _relationshipPicker(bool Function() current) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('How are you related?', style: ZyraText.body(size: 13)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final relation in zyraGuardianRelationships)
            ChoiceChip(
              label: Text(relation.name),
              selected: _relationship == relation.code,
              showCheckmark: false,
              backgroundColor: ZyraColors.surfaceFill,
              selectedColor: ZyraColors.surfaceEmphasisFill,
              side: BorderSide(
                color: _relationship == relation.code
                    ? ZyraColors.surfaceEmphasisBorder
                    : ZyraColors.surfaceBorder,
              ),
              shape: const StadiumBorder(),
              onSelected: ZyraTapFeedback.onChanged(context, (selected) {
                if (current()) {
                  setState(
                    () => _relationship = selected ? relation.code : null,
                  );
                }
              }),
            ),
        ],
      ),
    ],
  );

  Widget? _requestRows() {
    final owner = _rowsOwnerId;
    if (owner == null || !_isCurrentAccount(owner, _rowsOwnerGeneration)) {
      return null;
    }
    final pending = _requests.where((row) => row.isPending);
    if (pending.isEmpty && _error == null) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'REQUESTS',
            style: ZyraText.chapterLabel(color: ZyraColors.ink(.54)),
          ),
          const SizedBox(height: 10),
          for (final request in pending)
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
        if (_error case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ZyraErrorBanner(
              message: error,
              onDismiss: () => setState(() => _error = null),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_localRequested && !_localOwnerAllows()) {
      return Scaffold(
        key: const ValueKey('zyra_code_local_preview_denied'),
        backgroundColor: ZyraColors.modalSheetSurface,
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

    final local = _isFounderDemoPreview;
    final owner = _currentMemberId();
    final generation = ZyraAccountState.generation;
    final asGuardian = widget.asGuardian;
    final origin = ModalRoute.of(context);
    bool canAct() {
      if (_localRequested) return _localOwnerAllows();
      if (widget.signupPreview) return _signupPreviewAllowed;
      if (local) return _isFounderDemoPreview;
      return !_isFounderDemoPreview &&
          asGuardian == widget.asGuardian &&
          _isCurrentAccount(owner, generation);
    }

    final code = _code;
    final displayCode = code != null && (local || _canUseMemberCode(code))
        ? code.code
        : null;
    final page = ZyraLocalCodePage(
      key: ValueKey((
        widget.localPreview,
        widget.signupPreviewIdentity,
        local,
        owner,
        generation,
        asGuardian,
      )),
      mode: asGuardian
          ? ZyraLocalCodeContext.addSeeker
          : ZyraLocalCodeContext.addGuardian,
      ownerKey: (
        widget.localPreview,
        widget.signupPreviewIdentity,
        local,
        owner,
        generation,
        asGuardian,
      ),
      canAct: canAct,
      canInteract: _localRequested ? _localInteractive : null,
      interactionEpoch: _localRequested ? _localOperationEpoch : null,
      isLocal: local,
      simulatedCamera: _localRequested || widget.signupPreview,
      onLegacyInvite: local || owner == null
          ? null
          : (code) {
              if (!canAct() || origin?.isCurrent != true) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AcceptWaliInviteScreen(initialCode: code),
                ),
              );
            },
      personalCode: displayCode,
      personalCodeQr: !local && displayCode != null
          ? zyraCodeLinkFor(displayCode)
          : null,
      linkEntry:
          !local && owner != null && _linkEntryOwner == (owner, generation)
          ? _linkEntry
          : null,
      guardedLookupCode: _lookup,
      onCopy: _rotating ? null : _copy,
      onShare: _rotating ? null : _share,
      onRotate: _rotating ? null : _rotate,
      onMemberSend: local ? null : _send,
      foundExtra:
          asGuardian && (!local || !_localRequested && !widget.signupPreview)
          ? _relationshipPicker
          : null,
      onLocalSend: local && !_localRequested && !widget.signupPreview
          ? () {
              if (asGuardian) {
                if (_relationship != null) return true;
                _toast('Choose how you are related first.');
                return false;
              }
              final capacity = ZyraGuardianCapacity.fromCount(
                plan: AppState.instance.plan,
                linkedGuardianCount: ZyraDevScenario.instance.guardianCount,
              );
              if (!capacity.canAdd) {
                showZyraGuardianCapacityNotice(context, capacity.message);
              }
              return capacity.canAdd;
            }
          : null,
      copyLabel: _copied ? 'Copied' : 'Copy code',
      myCodeStatus: _loading
          ? const SizedBox(height: 100, child: ZyraLoading())
          : !_available
          ? ZyraErrorBanner(
              message: "Your ZYRA Code couldn't be refreshed.",
              onRetry: _load,
            )
          : null,
      extra: local
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_localRequested) _localInformationContent(),
                if (widget.signupPreview && _signupPreviewNotice != null)
                  Text(
                    _signupPreviewNotice!,
                    key: const ValueKey('signup_code_action_info'),
                    style: ZyraText.subtext(size: 12.5),
                  ),
              ],
            )
          : _requestRows(),
    );
    return Scaffold(
      key: widget.signupPreview ? const ValueKey('signup_code_preview') : null,
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: local
                ? ZyraColors.brandGradient
                : ZyraColors.genderGradient(AppState.instance.gender),
          ),
          child: _localRequested || origin == null
              ? page
              : ZyraPullDownCloseCue(
                  enabled: origin.canPop,
                  paintBackground: false,
                  routeIdentity: origin,
                  onBack: () => Navigator.of(context).maybePop(),
                  child: page,
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
        color: ZyraColors.cardSurface,
        border: Border.all(color: ZyraColors.surfaceBorder),
        borderRadius: BorderRadius.circular(17),
        boxShadow: ZyraColors.cardShadows,
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
