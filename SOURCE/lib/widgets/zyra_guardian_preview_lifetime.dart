import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../dev/zyra_dev_scenario.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_developer_access.dart';

/// Denial-only lifetime for caller-owned Guardian display state. A preview
/// request cannot grant authority, and a revoked route cannot become live or
/// rehydrate fixtures after an account switch or restored developer access.
class ZyraGuardianPreviewLifetime extends ChangeNotifier {
  ZyraGuardianPreviewLifetime({required this.preview})
    : _owner = ZyraAccountState.userId,
      _generation = ZyraAccountState.generation,
      _previewAdmitted = ZyraDevScenario.instance.guardianOverride {
    ZyraDevScenario.instance.addListener(_changed);
    ZyraDeveloperAccess.authorizationChanges.addListener(_changed);
  }

  final bool preview;
  final String? _owner;
  final int _generation;
  final bool _previewAdmitted;
  bool _revoked = false;

  bool get isCurrent =>
      !_revoked &&
      !ZyraAccountState.isSigningOut &&
      _owner == ZyraAccountState.userId &&
      _generation == ZyraAccountState.generation &&
      (!preview ||
          (_previewAdmitted && ZyraDevScenario.instance.guardianOverride));

  bool get canPreview => preview && isCurrent;

  void _changed() {
    if (!isCurrent) revoke();
  }

  /// Invalidates an old person/source-mode binding before a replacement load.
  void revoke() {
    if (_revoked) return;
    _revoked = true;
    notifyListeners();
  }

  @override
  void dispose() {
    // Sheets own separate routes and can outlive a removed owner route.
    revoke();
    ZyraDevScenario.instance.removeListener(_changed);
    ZyraDeveloperAccess.authorizationChanges.removeListener(_changed);
    super.dispose();
  }
}

/// Clears an already-open sheet/destination immediately and removes only its
/// exact route after the frame. Unrelated routes are never popped.
class ZyraGuardianPreviewRouteBoundary extends StatefulWidget {
  final ZyraGuardianPreviewLifetime authority;
  final Widget child;

  const ZyraGuardianPreviewRouteBoundary({
    super.key,
    required this.authority,
    required this.child,
  });

  @override
  State<ZyraGuardianPreviewRouteBoundary> createState() =>
      _ZyraGuardianPreviewRouteBoundaryState();
}

class _ZyraGuardianPreviewRouteBoundaryState
    extends State<ZyraGuardianPreviewRouteBoundary> {
  bool _closing = false;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    widget.authority.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    if (!widget.authority.isCurrent) _changed();
  }

  @override
  void didUpdateWidget(covariant ZyraGuardianPreviewRouteBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.authority, widget.authority)) return;
    oldWidget.authority.removeListener(_changed);
    widget.authority.addListener(_changed);
    if (!widget.authority.isCurrent) _changed();
  }

  void _changed() {
    if (!mounted || _closing || widget.authority.isCurrent) return;
    // A separate owner may be disposing while Flutter's tree is locked.
    // Deny immediately, but defer UI/route mutation to the safe frame boundary.
    _closing = true;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {});
    }
    final route = _route;
    binding.addPostFrameCallback((_) {
      if (!mounted) return;
      if (route == null || route.isFirst) {
        setState(() {});
      } else {
        route.navigator?.removeRoute(route);
      }
    });
    binding.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.authority.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.authority.isCurrent && !_closing
      ? widget.child
      : const SizedBox.shrink();
}
