// Founder-requested concept only. Fixtures never enter AppState, storage,
// entitlements, relationship APIs or the ordinary Browse route.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/zyra_account_state.dart';
import '../services/zyra_developer_access.dart';
import '../state/app_state.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import 'zyra_one_journey_concept_shell.dart';
import 'zyra_preview_navigation_checkpoint.dart';
import 'zyra_concept_preview_boundary.dart';
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

/// A disposable, local prototype. No live profiles or relationship writes.
class ViewRequestDraftScreen extends StatefulWidget {
  const ViewRequestDraftScreen({
    super.key,
    required this.ownerGeneration,
    required this.ownerId,
    this.onExit,
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
    this.fixture,
  });
  final int ownerGeneration;
  final String? ownerId;
  final VoidCallback? onExit;
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
  @visibleForTesting
  final ZyraOneJourneyShellFixture? fixture;

  @override
  State<ViewRequestDraftScreen> createState() => _ViewRequestDraftScreenState();
}

class _ViewRequestDraftScreenState extends State<ViewRequestDraftScreen> {
  late final _DraftOwner _owner;
  @override
  void initState() {
    super.initState();
    _owner = _DraftOwner(
      generation: widget.ownerGeneration,
      userId: widget.ownerId,
    );
    _owner.addListener(_authorityChanged);
  }

  void _authorityChanged() {
    if (!mounted) return;
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
        onRoleChanged: widget.onRoleChanged == null
            ? null
            : (guardian) {
                if (_canAct) widget.onRoleChanged!(guardian);
              },
        initialGuardianRole: widget.initialGuardianRole,
        initialSeekerBasic: widget.initialSeekerBasic,
        initialGuardianBasic: widget.initialGuardianBasic,
        fixture: widget.fixture,
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
