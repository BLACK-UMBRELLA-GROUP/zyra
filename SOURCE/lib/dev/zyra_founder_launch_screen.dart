import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../services/zyra_account_state.dart';
import '../services/zyra_app_lock.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_internal_preview_client.dart';
import '../services/zyra_local_prefs.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_full_screen_error.dart';
import '../widgets/zyra_loading.dart';
import 'dev_discovery_directions.dart';
import 'zyra_concept_preview_boundary.dart';
import 'zyra_dev_home.dart';
import 'zyra_dev_local_preview.dart';
import 'zyra_local_photo_import.dart';
import 'zyra_draft_compatibility_access_store.dart';
import 'zyra_preview_resume_transition.dart';
import 'zyra_preview_navigation_checkpoint.dart';

/// Only returned by the router after fresh exact-Founder proof. Every fresh
/// launch opens the current local presentation.
/// Neither presentation admits a real member.
class ZyraFounderLaunchScreen extends StatefulWidget {
  const ZyraFounderLaunchScreen({
    super.key,
    required this.ownerId,
    required this.ownerGeneration,
  });
  final String ownerId;
  final int ownerGeneration;

  @override
  State<ZyraFounderLaunchScreen> createState() =>
      _ZyraFounderLaunchScreenState();
}

class _ZyraFounderLaunchScreenState extends State<ZyraFounderLaunchScreen> {
  bool _opening = false;
  bool _failed = false;
  bool _revoked = false;
  late final String _ownerId = widget.ownerId;
  late final int _ownerGeneration = widget.ownerGeneration;
  ZyraLocalPreviewPreparation? _preparation;

  bool get _current =>
      mounted &&
      !_revoked &&
      ZyraAccountState.isCurrent(_ownerId, _ownerGeneration) &&
      ZyraLocalPreviewPreparation.foreground &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (!_current || _opening) return;
    setState(() {
      _opening = true;
      _failed = false;
    });
    // Standalone/recovery entry retains a real fresh check. AuthGate prepares
    // this same policy beneath splash; neither path can reuse cached proof.
    final preparation = await ZyraDevLocalPreview.prepare(
      current: () => _current,
      route: ModalRoute.of(context),
      onCreated: (preparation) => _preparation = preparation,
      isWali: ZyraLocalPrefs.cachedFounderPreviewRole == 'guardian',
    );
    if (!mounted) {
      preparation?.dispose();
      return;
    }
    final presentation = preparation?.commit();
    _preparation = null;
    if (presentation != null && _current) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => presentation.buildDestination()),
        (_) => false,
      );
      return;
    }
    setState(() {
      _opening = false;
      _failed = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_current) _preparation?.dispose();
  }

  @override
  void didUpdateWidget(ZyraFounderLaunchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ownerId != _ownerId ||
        widget.ownerGeneration != _ownerGeneration) {
      _revoked = true;
      _preparation?.dispose();
      _opening = false;
      _failed = true;
    }
  }

  @override
  void dispose() {
    _preparation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_failed) {
      return const ZyraQuietLoading();
    }
    return Scaffold(
      backgroundColor: ZyraColors.luxuryDarkPurple,
      body: ZyraCompactRecoverySurface(
        noticeKey: const ValueKey('founder_launch_recovery'),
        title: 'Couldn’t open this page.',
        message: 'Please try again, or return to Developer Home.',
        primaryLabel: 'Try again',
        secondaryLabel: 'Developer Home',
        primaryKey: const ValueKey('founder_launch_retry'),
        secondaryKey: const ValueKey('founder_launch_developer_home'),
        onPrimary: _open,
        onSecondary: () => ZyraDevHome.open(context),
      ),
    );
  }
}

/// Replaces (never resurrects) the disposable preview owner after a successful
/// Auth refresh. Old callbacks stay revoked. The network latch and isolation
/// boundary remain in force while access is being rechecked.
class ZyraFounderReviewSurface extends StatefulWidget {
  const ZyraFounderReviewSurface({
    super.key,
    required this.ownerId,
    required this.ownerGeneration,
    this.initialGuardianRole = false,
    this.initialSeekerBasic = false,
    this.initialGuardianBasic = false,
    this.resumeElapsedForTesting,
  });
  final String ownerId;
  final int ownerGeneration;
  final bool initialGuardianRole;
  final bool initialSeekerBasic;
  final bool initialGuardianBasic;
  @visibleForTesting
  final Duration Function()? resumeElapsedForTesting;

  @override
  State<ZyraFounderReviewSurface> createState() =>
      _ZyraFounderReviewSurfaceState();
}

class _ZyraFounderReviewSurfaceState extends State<ZyraFounderReviewSurface>
    with WidgetsBindingObserver {
  late final _ownerId = widget.ownerId;
  late final _ownerGeneration = widget.ownerGeneration;
  late final int _preferenceGeneration = ZyraLocalPrefs.bindingGeneration;
  bool _hadProof = false;
  bool _revoked = false;
  int _proofEpoch = 0;
  late bool _guardianRole = widget.initialGuardianRole;
  late final _away = ZyraPreviewAwayWindow(
    elapsed: widget.resumeElapsedForTesting,
  );
  ZyraPreviewNavigationCheckpoint? _checkpoint;
  ZyraPreviewNavigationCheckpoint? _handoffCheckpoint;
  late final _photoImportSession = ZyraInternalPreviewClient.previewSession;
  // Per-viewer fictional unlocks outlive disposable UI proof epochs, never
  // another owner/session. Navigation checkpoints cannot manufacture grants.
  late final _compatibilityAccess = ZyraDraftCompatibilityAccessStore(
    canAct: () =>
        !_revoked &&
        _sameOwner &&
        _hasProof &&
        _photoImportSession == ZyraInternalPreviewClient.previewSession,
  );
  late final _photoImports = ZyraLocalPhotoImport(
    canRetain: () =>
        _sameOwner &&
        _ownsVisibleRoute &&
        _restoreLocation &&
        _photoImportSession == ZyraInternalPreviewClient.previewSession &&
        _photoIntentCurrent &&
        (_hasProof ||
            _matchesTicket(ZyraPreviewResumeTransition.changes.value)),
    canAdmit: () => _hasProof && _currentVisible && _photoIntentCurrent,
    admissionEpoch: () => _proofEpoch,
  );

  bool get _photoIntentCurrent {
    final checkpoint = _handoffCheckpoint ?? _checkpoint;
    return checkpoint != null &&
        checkpoint.guardian == _guardianRole &&
        checkpoint.tab == (_guardianRole ? 3 : 4) &&
        checkpoint.pages.isNotEmpty &&
        checkpoint.pages.last == 'manage_photos';
  }

  final _presentationOwner = Object();
  ZyraPreviewContinuityAdmission? _continuityAdmission;
  bool _restoreLocation = true;
  final _paintKey = GlobalKey();
  ui.Image? _continuity;
  bool _quietResumeCover = false;
  int? _quietAfterEpoch;
  bool _quietExpired = false;
  bool _backgrounded = false;
  bool _resumeDecisionPending = false;
  Timer? _feedbackDelay;
  Timer? _waitDeadline;
  bool _waitActive = false;
  bool _feedbackVisible = false;
  int _waitRevision = 0;
  ZyraPreviewResumeTicket? _waitTicket;
  int _continuityRevision = 0;
  Size? _continuitySize;
  ZyraPreviewResumeTicket? _continuityTicket;
  bool _retiringContinuity = false;
  int? _readyEpoch;
  int? _presentedEpoch;
  int? _deferredPreparationEpoch;
  int? _admissionScheduledEpoch;
  late final Ticker _continuityWatch = Ticker((_) {
    _visibilityChanged();
  });

  bool get _currentVisible =>
      mounted &&
      _sameOwner &&
      ZyraLocalPreviewPreparation.foreground &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  bool _matchesTicket(ZyraPreviewResumeTicket? ticket) =>
      ticket != null &&
      ticket.ownerId == widget.ownerId &&
      ticket.accountGeneration == widget.ownerGeneration &&
      ticket.preferenceGeneration == _preferenceGeneration &&
      // Legacy test/manual tickets have no root token. Coordinated handoffs
      // must belong to this exact presented root, not just the same account.
      (ticket.presentationOwner == null ||
          identical(ticket.presentationOwner, _presentationOwner));

  bool get _ownsVisibleRoute =>
      mounted &&
      _sameOwner &&
      ZyraInternalPreviewClient.isActive &&
      !ZyraAppLock.instance.isLocked &&
      !ZyraAppLock.instance.isObscured &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  bool get _hasContinuityAdmission => _continuityAdmission?.isCurrent ?? false;

  void _revokeContinuityAdmission() {
    ZyraPreviewResumeTransition.revokeAdmission(_continuityAdmission);
    _continuityAdmission = null;
  }

  void _admitCompletedPresentation(int epoch) {
    if (!_callbackCurrent(epoch) ||
        !_currentVisible ||
        _readyEpoch != epoch ||
        _waitActive ||
        _continuity != null ||
        _quietResumeCover ||
        _quietAfterEpoch != null) {
      return;
    }
    final render = _paintKey.currentContext?.findRenderObject();
    if (render is! _FounderPreviewPaintBoundary ||
        !render.attached ||
        render.lastPaintedSize.isEmpty) {
      return;
    }
    _presentedEpoch = epoch;
    if (_hasContinuityAdmission) return;
    final guardian = _guardianRole;
    final previewSession = ZyraInternalPreviewClient.previewSession;
    _continuityAdmission = ZyraPreviewResumeTransition.admit(
      presentationOwner: _presentationOwner,
      ownerId: _ownerId,
      accountGeneration: _ownerGeneration,
      preferenceGeneration: _preferenceGeneration,
      // Deliberately no proof/foreground check here: this is only the
      // provenance of an already painted synthetic page, never authority.
      // Withdrawals are terminal; a boundary reopening cannot revive it.
      isCurrent: () =>
          _ownsVisibleRoute &&
          ZyraConceptPreviewIsolation.active &&
          _guardianRole == guardian &&
          ZyraInternalPreviewClient.previewSession == previewSession,
    );
  }

  void _admitAfterPaint(int epoch) {
    if (_admissionScheduledEpoch == epoch) return;
    _admissionScheduledEpoch = epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _admissionScheduledEpoch != epoch) return;
      _admissionScheduledEpoch = null;
      _admitCompletedPresentation(epoch);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  // A repeated departure during ONE joined check retains its original wait
  // deadline, including recovery. Any inert raster stays in memory, never on
  // screen. No previous ticket, route or authority is reused.
  bool get _mayRetainPendingWait =>
      _ownsVisibleRoute &&
      _waitActive &&
      _matchesTicket(_waitTicket) &&
      identical(_waitTicket, ZyraPreviewResumeTransition.changes.value);

  void _finishWait() {
    _waitRevision++;
    _feedbackDelay?.cancel();
    _feedbackDelay = null;
    _waitDeadline?.cancel();
    _waitDeadline = null;
    _waitActive = false;
    _waitTicket = null;
    _feedbackVisible = false;
    _quietExpired = false;
  }

  void _beginWait(ZyraPreviewResumeTicket? ticket) {
    if (_waitActive &&
        (_quietAfterEpoch != null ||
            _waitTicket == null ||
            identical(_waitTicket, ticket) ||
            (_hasProof && _presentedEpoch != _proofEpoch))) {
      // Duplicate resumed notifications can start fresh Auth tickets without
      // a real departure. They cannot restart an unfinished long handover or
      // resurrect its expired cover; only rebind that wait's exact ticket.
      if (ticket != null) _waitTicket = ticket;
      return;
    }
    _finishWait();
    _waitActive = true;
    _waitTicket = ticket;
    final revision = _waitRevision;
    _feedbackDelay = Timer(const Duration(milliseconds: 800), () {
      _feedbackDelay = null;
      if (!mounted || !_waitActive || revision != _waitRevision) return;
      _feedbackVisible = true;
      if (_currentVisible) _repaint();
    });
    _waitDeadline = Timer(const Duration(seconds: 10), () {
      _waitDeadline = null;
      if (!mounted || !_waitActive || revision != _waitRevision) return;
      _quietExpired = true;
      _clearContinuity(endWait: false);
      if (_currentVisible) _repaint();
    });
  }

  void _clearContinuity({bool endWait = true}) {
    _continuityRevision++;
    final image = _continuity;
    _continuity = null;
    _quietResumeCover = false;
    _continuitySize = null;
    _continuityTicket = null;
    _retiringContinuity = false;
    if (endWait) _finishWait();
    _continuityWatch.stop();
    // RawImage's render object owns its own clone until the next frame.
    image?.dispose();
  }

  void _showQuietResume(ZyraPreviewResumeTicket? ticket) {
    if (_quietExpired || _quietResumeCover) return;
    _clearContinuity(endWait: false);
    _quietResumeCover = true;
    _continuityTicket = ticket;
    _continuityWatch.start();
    _beginWait(ticket);
  }

  void _clearQuietIntent() {
    _quietAfterEpoch = null;
    _deferredPreparationEpoch = null;
  }

  void _decideResumePresentation() {
    if (_resumeDecisionPending) {
      _resumeDecisionPending = false;
      final restore = _away.resume();
      if (!restore && _sameOwner && _quietAfterEpoch == null) {
        _quietAfterEpoch = _proofEpoch;
        _readyEpoch = null;
      }
      // A second short interruption during an unfinished long handover cannot
      // undo its already chosen reset. Duplicate resumed events do not make a
      // completed handover into another long return.
      _restoreLocation = restore && _quietAfterEpoch == null;
      if (!_restoreLocation && _continuity != null) {
        // Never replay the old page after the fifteen-minute reset decision.
        _clearContinuity(endWait: false);
      }
    }
    _photoImports.synchronize();
    if (!_restoreLocation &&
        _currentVisible &&
        (_hasProof ||
            _matchesTicket(ZyraPreviewResumeTransition.changes.value))) {
      _showQuietResume(ZyraPreviewResumeTransition.changes.value);
    }
  }

  void _resumePresentationChanged() {
    if (!mounted) return;
    final ticket = ZyraPreviewResumeTransition.changes.value;
    if (_matchesTicket(ticket) && _hasProof && _currentVisible) {
      _decideResumePresentation();
      _beginWait(ticket);
      if (!_restoreLocation) {
        _showQuietResume(ticket);
        _repaint();
        return;
      }
      _clearContinuity(endWait: false);
      final render = _paintKey.currentContext?.findRenderObject();
      if (_presentedEpoch == _proofEpoch &&
          _hasContinuityAdmission &&
          render is _FounderPreviewPaintBoundary &&
          render.hasSize &&
          !render.lastPaintedSize.isEmpty) {
        final ratio = math.min(
          MediaQuery.devicePixelRatioOf(context),
          math.min(2.0, 2048 / render.lastPaintedSize.longestSide),
        );
        _continuity = render.capture(ratio);
        if (_continuity != null) {
          _continuitySize = render.lastPaintedSize;
          _continuityTicket = ticket;
          _continuityWatch.start();
        }
      }
      if (_continuity == null) _showQuietResume(ticket);
    } else if (_matchesTicket(ticket) && _currentVisible && !_hasProof) {
      // The same operation may have withdrawn proof while paused. There is
      // no authorized layer to capture now; join it with a neutral cover.
      _decideResumePresentation();
      _showQuietResume(ticket);
    } else if ((!_hasProof && !_matchesTicket(ticket)) ||
        !_ownsVisibleRoute ||
        (!_currentVisible && !_mayRetainPendingWait)) {
      _clearContinuity();
    }
    if (!_hasProof && !_matchesTicket(ticket) && !_hasContinuityAdmission) {
      _checkpoint = null;
      _handoffCheckpoint = null;
      _clearQuietIntent();
    }
    _photoImports.synchronize();
    _repaint();
  }

  void _repaint() {
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      binding.scheduleFrame();
    } else if (mounted) {
      setState(() {});
    }
  }

  void _retireAfterFreshPaint(int epoch) {
    if (_retiringContinuity) return;
    _retiringContinuity = true;
    final revision = _continuityRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_retiringContinuity || revision != _continuityRevision) {
        return;
      }
      if (!_hasProof ||
          !_currentVisible ||
          epoch != _proofEpoch ||
          _readyEpoch != epoch ||
          (_quietAfterEpoch != null && epoch <= _quietAfterEpoch!)) {
        _retiringContinuity = false;
        return;
      }
      _clearContinuity();
      _clearQuietIntent();
      _handoffCheckpoint = null;
      _admitCompletedPresentation(epoch);
      setState(() {});
    });
  }

  bool get _sameOwner =>
      !_revoked &&
      widget.ownerId == _ownerId &&
      widget.ownerGeneration == _ownerGeneration &&
      ZyraAccountState.isCurrent(widget.ownerId, widget.ownerGeneration) &&
      _preferenceGeneration == ZyraLocalPrefs.bindingGeneration;
  bool get _hasProof =>
      _sameOwner &&
      ZyraDeveloperAccess.isMainAppFounderPreview &&
      ZyraDeveloperAccess.canUseDeveloperTools &&
      !ZyraDeveloperAccess.isAuthorizedTester &&
      ZyraInternalPreviewClient.isActive;

  bool _callbackCurrent(int epoch) =>
      mounted &&
      epoch == _proofEpoch &&
      _hasProof &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  @override
  void initState() {
    super.initState();
    _hadProof = _hasProof;
    WidgetsBinding.instance.addObserver(this);
    ZyraAppLock.instance.addListener(_visibilityChanged);
    ZyraConceptPreviewIsolation.changes.addListener(_visibilityChanged);
    ZyraPreviewResumeTransition.changes.addListener(_resumePresentationChanged);
    ZyraDeveloperAccess.authorizationChanges.addListener(_proofChanged);
    ZyraInternalPreviewClient.changes.addListener(_proofChanged);
  }

  void _proofChanged() {
    if (!mounted) return;
    if (!_sameOwner) {
      _revoked = true;
      _checkpoint = null;
      _handoffCheckpoint = null;
      _revokeContinuityAdmission();
      _clearQuietIntent();
    }
    final proof = _hasProof;
    final deferredFallback =
        proof && !_hadProof && _deferredPreparationEpoch == _proofEpoch;
    if (!proof && _hadProof && _hasContinuityAdmission) {
      // Freeze only detached fixture navigation. A new owner may publish its
      // own checkpoint, but cannot change this handoff's restoration input.
      _handoffCheckpoint ??= _checkpoint;
    }
    if (proof && !_hadProof) {
      _proofEpoch++;
      if (deferredFallback || !_ownsVisibleRoute) {
        _deferredPreparationEpoch = _proofEpoch;
      }
    }
    if (!_ownsVisibleRoute ||
        (!_currentVisible && !_mayRetainPendingWait) ||
        (!_matchesTicket(ZyraPreviewResumeTransition.changes.value) &&
            !proof)) {
      _clearContinuity();
    }
    if (!proof &&
        !_matchesTicket(ZyraPreviewResumeTransition.changes.value) &&
        !_hasContinuityAdmission) {
      _checkpoint = null;
      _handoffCheckpoint = null;
      _clearQuietIntent();
    }
    _hadProof = proof;
    _photoImports.synchronize();
    if (deferredFallback &&
        _sameOwner &&
        _currentVisible &&
        _ownsVisibleRoute) {
      // A passive fallback never admitted the old tree. Only this fresh proof
      // may prepare its replacement, under the original bounded visual wait.
      // Offstage preparation and expired recovery are not restarted here.
      final ticket = ZyraPreviewResumeTransition.changes.value;
      _showQuietResume(_matchesTicket(ticket) ? ticket : null);
    }
    _repaint();
  }

  void _visibilityChanged() {
    final ownsBoundary =
        _ownsVisibleRoute && ZyraConceptPreviewIsolation.active;
    if (!ownsBoundary) {
      if (_hasProof && !_ownsVisibleRoute && _readyEpoch != _proofEpoch) {
        _deferredPreparationEpoch = _proofEpoch;
      }
      _revokeContinuityAdmission();
      _presentedEpoch = null;
      if (!_hasProof || _waitActive || !ZyraConceptPreviewIsolation.active) {
        _checkpoint = null;
        _handoffCheckpoint = null;
      }
    }
    if (!ownsBoundary || (!_currentVisible && !_mayRetainPendingWait)) {
      _clearContinuity();
      _repaint();
    } else if (_currentVisible &&
        _quietAfterEpoch != null &&
        !_quietExpired &&
        !_quietResumeCover &&
        (_hasProof ||
            _matchesTicket(ZyraPreviewResumeTransition.changes.value))) {
      _showQuietResume(ZyraPreviewResumeTransition.changes.value);
      _repaint();
    } else if (_currentVisible &&
        !_hasProof &&
        !_waitActive &&
        _matchesTicket(ZyraPreviewResumeTransition.changes.value)) {
      // A covered route discarded its old image. Returning while that exact
      // check is still pending may use a neutral cover, never resurrect pixels
      // from before the cover and never flash Golden just for losing capture.
      _showQuietResume(ZyraPreviewResumeTransition.changes.value);
      _repaint();
    }
    if (ownsBoundary &&
        _currentVisible &&
        _hasProof &&
        _deferredPreparationEpoch == _proofEpoch &&
        _readyEpoch != _proofEpoch &&
        !_quietExpired &&
        !_quietResumeCover) {
      // A completed check while covered must not start a disposable photo
      // owner offstage, then expose its loader on pop. Prepare locally only
      // on return, under the same bounded neutral cover, without another Auth
      // request or resurrection of the withdrawn route's pixels.
      final ticket = ZyraPreviewResumeTransition.changes.value;
      _showQuietResume(_matchesTicket(ticket) ? ticket : null);
      _repaint();
    }
    if (ownsBoundary &&
        _currentVisible &&
        _hasProof &&
        _readyEpoch == _proofEpoch &&
        !_waitActive &&
        !_hasContinuityAdmission) {
      // A covered route/lock can withdraw the previous lease. A completed
      // fresh page earns a new one only after painting again, never by revival.
      _admitAfterPaint(_proofEpoch);
    }
    _photoImports.synchronize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        _resumeDecisionPending = true;
        _away.inactive();
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _resumeDecisionPending = true;
        if (!_backgrounded) {
          // A genuine new background departure ends the previous visual wait.
          // Its suspended timer cannot expire a later handover before that
          // handover has had its own bounded foreground preparation window.
          if (_quietAfterEpoch != null &&
              (_hasProof ||
                  !_matchesTicket(ZyraPreviewResumeTransition.changes.value))) {
            _clearContinuity();
            _quietAfterEpoch = _proofEpoch;
            _readyEpoch = null;
          }
        }
        _backgrounded = true;
        _away.background();
      case AppLifecycleState.resumed:
        _backgrounded = false;
        // Also latch here: observer ordering may deliver the presentation
        // ticket before this surface becomes visibly current.
        _decideResumePresentation();
        _visibilityChanged();
        _repaint();
      case AppLifecycleState.detached:
        _checkpoint = null;
        _handoffCheckpoint = null;
        _deferredPreparationEpoch = null;
        _revokeContinuityAdmission();
    }
    if (state != AppLifecycleState.resumed) {
      _visibilityChanged();
      // A same-ticket raster may remain owned in memory, but its old RawImage
      // must actually leave the painted tree while inactive/hidden, including
      // when App Lock is disabled and sends no separate notification.
      _repaint();
    }
  }

  @override
  void didChangeMetrics() {
    // The already captured image owns its painted bounds. Fit it into new
    // geometry until fresh content paints; rotation/keyboard must not flash
    // a full-screen loader or stretch an old photograph.
    if (_quietResumeCover || _continuity == null) return;
    _repaint();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibilityChanged();
  }

  @override
  void didUpdateWidget(ZyraFounderReviewSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameOwner) {
      _revoked = true;
      _checkpoint = null;
      _handoffCheckpoint = null;
      _revokeContinuityAdmission();
      _clearQuietIntent();
      _clearContinuity();
    }
  }

  void _rememberRole(bool guardian) {
    if (!_hasProof || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _photoImports.cancel();
    _guardianRole = guardian;
    _checkpoint = null;
    _handoffCheckpoint = null;
    _revokeContinuityAdmission();
    _presentedEpoch = null;
    _clearQuietIntent();
    if (_quietResumeCover || _continuity != null) {
      _clearContinuity();
      _repaint();
    }
    ZyraLocalPrefs.setFounderPreviewRole(
      guardian ? 'guardian' : 'seeker',
      expectedOwner: widget.ownerId,
      expectedBindingGeneration: _preferenceGeneration,
    );
    _admitAfterPaint(_proofEpoch);
  }

  bool _canRecover(int epoch, int revision) =>
      _quietExpired &&
      _waitActive &&
      revision == _waitRevision &&
      epoch == _proofEpoch &&
      _hasProof &&
      _currentVisible &&
      ZyraPreviewResumeTransition.changes.value == null;

  void _retryPresentation(int epoch, int revision) {
    if (!_canRecover(epoch, revision)) return;
    // Retry local offline-photo preparation with a new disposable UI owner.
    // It is not an Auth retry or a grant; a real failed access check keeps
    // using the existing AuthGate recovery, never a parallel refresh here.
    _proofEpoch++;
    _readyEpoch = null;
    _clearContinuity();
    _showQuietResume(null);
    _repaint();
  }

  @override
  void dispose() {
    _revoked = true;
    _compatibilityAccess.close();
    _photoImports.dispose();
    _checkpoint = null;
    _handoffCheckpoint = null;
    _revokeContinuityAdmission();
    _clearQuietIntent();
    WidgetsBinding.instance.removeObserver(this);
    ZyraAppLock.instance.removeListener(_visibilityChanged);
    ZyraConceptPreviewIsolation.changes.removeListener(_visibilityChanged);
    ZyraPreviewResumeTransition.changes.removeListener(
      _resumePresentationChanged,
    );
    _clearContinuity();
    _continuityWatch.dispose();
    ZyraDeveloperAccess.authorizationChanges.removeListener(_proofChanged);
    ZyraInternalPreviewClient.changes.removeListener(_proofChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _photoImports.synchronize();
    final epoch = _proofEpoch;
    final checkpoint = _handoffCheckpoint ?? _checkpoint;
    final image = _continuity;
    final quiet = _quietResumeCover;
    final mayShowFrame =
        (quiet || image != null) &&
        _ownsVisibleRoute &&
        _currentVisible &&
        (quiet
            ? _sameOwner &&
                  (_hasProof ||
                      _matchesTicket(ZyraPreviewResumeTransition.changes.value))
            : _restoreLocation &&
                  _matchesTicket(_continuityTicket) &&
                  (_hasProof ||
                      identical(
                        _continuityTicket,
                        ZyraPreviewResumeTransition.changes.value,
                      )));
    if ((quiet || _continuity != null) &&
        !mayShowFrame &&
        !_mayRetainPendingWait) {
      _clearContinuity();
    }
    final Widget? frame = mayShowFrame
        ? BlockSemantics(
            child: Semantics(
              label: 'Checking access',
              container: true,
              liveRegion: true,
              child: ExcludeSemantics(
                child: AbsorbPointer(
                  child: quiet
                      ? DecoratedBox(
                          key: const ValueKey(
                            'founder_resume_quiet_background',
                          ),
                          decoration: BoxDecoration(
                            gradient: ZyraColors.brandGradient,
                          ),
                          child: const SizedBox.expand(),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: ZyraColors.brandGradient,
                              ),
                              child: RawImage(
                                key: const ValueKey(
                                  'founder_resume_continuity',
                                ),
                                image: image,
                                fit: constraints.biggest == _continuitySize
                                    ? BoxFit.fill
                                    : BoxFit.contain,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          )
        : null;
    final freshOwner =
        _hasProof &&
        (_quietAfterEpoch == null || epoch > _quietAfterEpoch!) &&
        // Keep an already-ready page mounted when covered. A new unready
        // epoch starts only on its current unlocked route, where its local
        // preparation callbacks can actually earn ready-plus-paint admission.
        (_ownsVisibleRoute || _readyEpoch == epoch);
    if (freshOwner &&
        (frame != null || _quietAfterEpoch != null || _quietExpired) &&
        _readyEpoch == epoch) {
      _retireAfterFreshPaint(epoch);
    }
    return ZyraConceptPreviewBoundary(
      child: !freshOwner
          ? _quietExpired && _currentVisible
                ? _recovery(epoch)
                : frame != null
                ? _withFeedback(frame)
                : _quietFallback()
          : Stack(
              fit: StackFit.expand,
              children: [
                _FounderPreviewCapture(
                  key: _paintKey,
                  child: ViewRequestDraftScreen(
                    key: ValueKey('founder_request_style_$_proofEpoch'),
                    ownerId: widget.ownerId,
                    ownerGeneration: widget.ownerGeneration,
                    localPhotoImport: _photoImports,
                    compatibilityAccess: _compatibilityAccess,
                    initialGuardianRole: _guardianRole,
                    initialSeekerBasic: widget.initialSeekerBasic,
                    initialGuardianBasic: widget.initialGuardianBasic,
                    initialCheckpoint: checkpoint?.guardian == _guardianRole
                        ? checkpoint
                        : null,
                    restoreLocation: _restoreLocation,
                    onCheckpoint: (checkpoint) {
                      if (_callbackCurrent(epoch) &&
                          _currentVisible &&
                          checkpoint.guardian == _guardianRole) {
                        _checkpoint = checkpoint;
                        _photoImports.synchronize();
                      }
                    },
                    onPresentationReady: () {
                      if (!_callbackCurrent(epoch)) return;
                      _readyEpoch = epoch;
                      _admitAfterPaint(epoch);
                      _repaint();
                    },
                    onExit: () {
                      if (_callbackCurrent(epoch)) {
                        ZyraDevHome.open(context, replacePreviewRoot: true);
                      }
                    },
                    onDeveloperHome: () {
                      if (_callbackCurrent(epoch)) {
                        ZyraDevHome.open(context, replacePreviewRoot: true);
                      }
                    },
                    onRoleChanged: (guardian) {
                      if (_callbackCurrent(epoch)) _rememberRole(guardian);
                    },
                  ),
                ),
                if (_quietExpired && _currentVisible)
                  _recovery(epoch)
                else if (frame != null)
                  _withFeedback(frame),
              ],
            ),
    );
  }

  Widget _quietFallback() {
    final eligible = _ownsVisibleRoute && ZyraConceptPreviewIsolation.active;
    if (eligible && !_hasProof) {
      // This marker carries only local preparation intent. It never restores
      // permission, a widget owner, callbacks, a raster or disclosure grants.
      _deferredPreparationEpoch = _proofEpoch;
      if (_currentVisible && _ownsVisibleRoute && !_waitActive) {
        _beginWait(null);
      }
    }
    return ZyraQuietLoading(
      canvasKey: ValueKey(
        eligible
            ? 'founder_resume_quiet_background'
            : 'founder_unavailable_quiet_background',
      ),
    );
  }

  Widget _withFeedback(Widget frame) => Stack(
    fit: StackFit.expand,
    children: [
      frame,
      if (_feedbackVisible && !_quietExpired && _currentVisible)
        const _FounderResumeStatus(),
    ],
  );

  Widget _recovery(int epoch) {
    final revision = _waitRevision;
    final canRecover = _canRecover(epoch, revision);
    return BlockSemantics(
      child: ZyraCompactRecoverySurface(
        noticeKey: const ValueKey('founder_resume_recovery'),
        title: 'Taking a little longer',
        message: canRecover
            ? 'Your page is still being prepared. You can try again without losing your Journey.'
            : 'Your page isn’t ready yet. Please wait a little longer.',
        primaryLabel: 'Try again',
        secondaryLabel: 'Developer Home',
        primaryKey: const ValueKey('founder_resume_retry'),
        secondaryKey: const ValueKey('founder_resume_home'),
        onPrimary: canRecover
            ? () => _retryPresentation(epoch, revision)
            : null,
        onSecondary: canRecover
            ? () {
                if (!_canRecover(epoch, revision)) return;
                unawaited(ZyraDevHome.open(context, replacePreviewRoot: true));
              }
            : null,
      ),
    );
  }
}

/// Compact delayed progress, never a replacement loading page or access grant.
class _FounderResumeStatus extends StatelessWidget {
  const _FounderResumeStatus();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            label: 'Updating ZYRA',
            liveRegion: true,
            child: ExcludeSemantics(
              child: Material(
                key: const ValueKey('founder_resume_status'),
                color: ZyraColors.luxuryDarkPurple,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      if (MediaQuery.disableAnimationsOf(context))
                        const Icon(
                          Icons.sync_rounded,
                          size: 16,
                          color: ZyraColors.journeyGold,
                        )
                      else
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: ZyraColors.journeyGold,
                          ),
                        ),
                      Text(
                        'Updating…',
                        style: ZyraText.body().copyWith(
                          fontSize: 13,
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
    ),
  );
}

class _FounderPreviewCapture extends SingleChildRenderObjectWidget {
  const _FounderPreviewCapture({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _FounderPreviewPaintBoundary();
}

/// Record a real completed layer and bounds in PROFILE too. A later pending
/// layout/paint doesn't erase what the user last saw. Capture that exact owned
/// layer immediately; never keep a mutable layer as the continuity cover.
class _FounderPreviewPaintBoundary extends RenderRepaintBoundary {
  OffsetLayer? _paintedLayer;
  Size _paintedSize = Size.zero;
  Size get lastPaintedSize => _paintedSize;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    _paintedLayer = layer is OffsetLayer ? layer! as OffsetLayer : null;
    _paintedSize = size;
  }

  ui.Image? capture(double pixelRatio) {
    if (!attached ||
        !hasSize ||
        _paintedLayer == null ||
        !identical(layer, _paintedLayer) ||
        !_paintedLayer!.attached ||
        _paintedSize.isEmpty ||
        !pixelRatio.isFinite ||
        pixelRatio <= 0) {
      return null;
    }
    try {
      return _paintedLayer!.toImageSync(
        Offset.zero & _paintedSize,
        pixelRatio: pixelRatio,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void detach() {
    _paintedLayer = null;
    _paintedSize = Size.zero;
    super.detach();
  }
}
