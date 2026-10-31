// Founder-requested concept only. Fixtures never enter AppState, storage,
// entitlements, relationship APIs or the ordinary Browse route.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/zyra_account_state.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_local_prefs.dart';
import '../state/app_state.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_one_journey_concept_shell.dart';
import 'zyra_preview_navigation_checkpoint.dart';
import 'zyra_concept_preview_boundary.dart';
import 'zyra_dev_local_preview.dart';
import 'zyra_local_photo_import.dart';
import 'zyra_draft_compatibility_access_store.dart';

class _DraftOwner extends ChangeNotifier {
  _DraftOwner({required this.generation, required this.userId})
    : _admitted = ZyraDeveloperAccess.canUseDeveloperTools {
    ZyraDeveloperAccess.authorizationChanges.addListener(_changed);
    AppState.instance.addListener(_changed);
  }

  final int generation;
  final String? userId;
  final bool _admitted;
  bool _revoked = false;
  bool _disposed = false;

  bool get current =>
      _admitted &&
      !_revoked &&
      ZyraDeveloperAccess.canUseDeveloperTools &&
      !ZyraAccountState.isSigningOut &&
      generation == ZyraAccountState.generation &&
      userId == ZyraAccountState.userId;

  void _changed() {
    if (current || _revoked) return;
    _revoked = true;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _revoked = true;
    ZyraDeveloperAccess.authorizationChanges.removeListener(_changed);
    AppState.instance.removeListener(_changed);
    super.dispose();
  }
}

class DevDiscoveryDirectionPicker extends StatefulWidget {
  const DevDiscoveryDirectionPicker({
    super.key,
    this.enabled = true,
    this.onBeforeOpen,
  });
  final bool enabled;
  final VoidCallback? onBeforeOpen;

  @override
  State<DevDiscoveryDirectionPicker> createState() =>
      _DevDiscoveryDirectionPickerState();
}

class _DevDiscoveryDirectionPickerState
    extends State<DevDiscoveryDirectionPicker> {
  late final _DraftOwner _owner = _DraftOwner(
    generation: ZyraAccountState.generation,
    userId: ZyraAccountState.userId,
  );
  bool _opening = false;

  @override
  void dispose() {
    _owner.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (!mounted || !widget.enabled || _opening || !_owner.current) return;
    if (ZyraDeveloperAccess.isMainAppFounderPreview &&
        !ZyraDeveloperAccess.isAuthorizedTester &&
        _owner.userId != null &&
        ZyraLocalPrefs.accountOwner == _owner.userId) {
      // Replace the admitted local shell rather than stacking a second one.
      // Opening rechecks fresh proof and the captured owner lifetime.
      _opening = true;
      final role = ZyraLocalPrefs.cachedFounderPreviewRole;
      // Capture the still-mounted panel's navigator before refresh/collapse
      // retracts that panel. The entry method owns the awaited lifetime check.
      final opening = ZyraDevLocalPreview.open(
        context,
        isWali: role == 'guardian',
      );
      widget.onBeforeOpen?.call();
      await opening;
      if (mounted) setState(() => _opening = false);
      return;
    }
    final navigator = Navigator.of(context);
    final admission = _DraftOwner(
      generation: _owner.generation,
      userId: _owner.userId,
    );
    _opening = true;
    widget.onBeforeOpen?.call();
    // Closing the developer panel must not let a stale callback open a route
    // for a newly selected account. Bind the destination to this exact owner.
    if (!admission.current) {
      admission.dispose();
      _opening = false;
      return;
    }
    // Deny real-shell controls even during the incoming route's first frame.
    final launchLease = ZyraConceptPreviewIsolation.acquire();
    try {
      await navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => ViewRequestDraftScreen._(
            admission: admission,
            launchLease: launchLease,
          ),
        ),
      );
    } finally {
      admission.dispose();
      launchLease.release();
    }
    if (mounted) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _owner,
    builder: (context, _) => !_owner.current
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('App preview', style: ZyraText.body(size: 15)),
              const SizedBox(height: 8),
              _DraftButton(
                id: 'dev_discovery_view_request',
                label: 'Open app preview',
                icon: Icons.travel_explore_outlined,
                onTap: widget.enabled && !_opening ? _open : null,
              ),
            ],
          ),
  );
}

/// A disposable, local prototype. No live profiles or relationship writes.
class ViewRequestDraftScreen extends StatefulWidget {
  const ViewRequestDraftScreen({
    super.key,
    required this.ownerGeneration,
    required this.ownerId,
    this.onExit,
    this.onDeveloperHome,
    this.onRoleChanged,
    this.onPresentationReady,
    this.initialCheckpoint,
    this.restoreLocation = true,
    this.onCheckpoint,
    this.localPhotoImport,
    this.compatibilityAccess,
    this.initialGuardianRole = false,
    this.initialSeekerBasic = false,
    this.initialGuardianBasic = false,
  }) : _admission = null,
       _launchLease = null;
  ViewRequestDraftScreen._({
    required _DraftOwner admission,
    required this._launchLease,
  }) : onExit = null,
       onDeveloperHome = null,
       onRoleChanged = null,
       onPresentationReady = null,
       initialCheckpoint = null,
       restoreLocation = true,
       onCheckpoint = null,
       localPhotoImport = null,
       compatibilityAccess = null,
       initialGuardianRole = false,
       initialSeekerBasic = false,
       initialGuardianBasic = false,
       _admission = admission,
       ownerGeneration = admission.generation,
       ownerId = admission.userId;
  final int ownerGeneration;
  final String? ownerId;
  final VoidCallback? onExit;
  final VoidCallback? onDeveloperHome;
  final ValueChanged<bool>? onRoleChanged;
  final VoidCallback? onPresentationReady;
  final ZyraPreviewNavigationCheckpoint? initialCheckpoint;
  final bool restoreLocation;
  final ValueChanged<ZyraPreviewNavigationCheckpoint>? onCheckpoint;
  final ZyraLocalPhotoImport? localPhotoImport;
  final ZyraDraftCompatibilityAccessStore? compatibilityAccess;
  final bool initialGuardianRole;
  final bool initialSeekerBasic;
  final bool initialGuardianBasic;
  final _DraftOwner? _admission;
  final ZyraConceptPreviewLease? _launchLease;

  @override
  State<ViewRequestDraftScreen> createState() => _ViewRequestDraftScreenState();
}

class _ViewRequestDraftScreenState extends State<ViewRequestDraftScreen> {
  late final _DraftOwner _owner;
  @override
  void initState() {
    super.initState();
    _owner =
        widget._admission ??
        _DraftOwner(generation: widget.ownerGeneration, userId: widget.ownerId);
    _owner.addListener(_authorityChanged);
    // The mounted boundary takes over denial. Navigator disposal need not
    // complete push's Future, so the temporary launcher lease cannot rely on
    // that Future alone for cleanup.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget._launchLease?.release(),
    );
  }

  void _authorityChanged() {
    if (!mounted) return;
    if (!_owner.current) widget._launchLease?.release();
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      binding.scheduleFrame();
    } else {
      setState(() {});
    }
  }

  bool get _canAct =>
      mounted && _owner.current && (ModalRoute.of(context)?.isCurrent ?? false);
  void _close() {
    if (!_canAct) return;
    if (widget.onExit != null) {
      widget.onExit!();
      return;
    }
    Navigator.of(context).pop<void>();
  }

  @override
  void dispose() {
    _owner.removeListener(_authorityChanged);
    _owner.dispose();
    widget._launchLease?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_owner.current) {
      return Scaffold(
        backgroundColor: ZyraColors.luxuryDarkPurple,
        body: SafeArea(
          child: Center(child: Text('Preview closed', style: ZyraText.body())),
        ),
      );
    }
    return ZyraConceptPreviewBoundary(
      child: ZyraOneJourneyConceptShell(
        canAct: () => _canAct,
        canActInOwnedDialog: () => mounted && _owner.current,
        localPhotoImport: widget.localPhotoImport,
        compatibilityAccess: widget.compatibilityAccess,
        onExit: _close,
        onDeveloperHome: widget.onDeveloperHome == null
            ? null
            : () {
                if (_canAct) widget.onDeveloperHome!();
              },
        onRoleChanged: widget.onRoleChanged == null
            ? null
            : (guardian) {
                if (_canAct) widget.onRoleChanged!(guardian);
              },
        initialGuardianRole: widget.initialGuardianRole,
        initialSeekerBasic: widget.initialSeekerBasic,
        initialGuardianBasic: widget.initialGuardianBasic,
        initialCheckpoint: widget.initialCheckpoint,
        restoreLocation: widget.restoreLocation,
        onCheckpoint: widget.onCheckpoint == null
            ? null
            : (checkpoint) {
                if (_canAct) widget.onCheckpoint!(checkpoint);
              },
        onPresentationReady: widget.onPresentationReady == null
            ? null
            : () {
                if (_canAct) widget.onPresentationReady!();
              },
      ),
    );
  }
}

class _DraftButton extends StatelessWidget {
  const _DraftButton({
    required this.id,
    required this.label,
    required this.onTap,
    this.icon,
  });
  final String id;
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    key: ValueKey(id),
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(44, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      foregroundColor: ZyraColors.journeyGold,
      side: BorderSide(color: ZyraColors.journeyGold.withValues(alpha: .4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 9)],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: ZyraText.body(size: 12.5, color: ZyraColors.goldText),
          ),
        ),
      ],
    ),
  );
}
