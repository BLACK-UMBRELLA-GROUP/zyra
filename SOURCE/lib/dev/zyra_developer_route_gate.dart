import 'package:flutter/material.dart';

import '../screens/auth_gate.dart';
import '../services/zyra_developer_access.dart';
import '../widgets/zyra_loading.dart';

/// Revalidates protected Developer Access before a route paints its content.
/// Cached capability may hide a control, but it is never sufficient to open a
/// fresh destination after the server has removed a role or persona claim.
class ZyraDeveloperRouteGate extends StatefulWidget {
  const ZyraDeveloperRouteGate({
    super.key,
    required this.child,
    this.requireFounderOperator = false,
    this.refreshOverride,
    this.deniedDestinationBuilder,
  });

  final Widget child;
  final bool requireFounderOperator;

  @visibleForTesting
  final Future<bool> Function()? refreshOverride;

  @visibleForTesting
  final WidgetBuilder? deniedDestinationBuilder;

  @override
  State<ZyraDeveloperRouteGate> createState() => _ZyraDeveloperRouteGateState();
}

class _ZyraDeveloperRouteGateState extends State<ZyraDeveloperRouteGate> {
  late Future<bool> _authorization;
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _authorization = _refresh();
  }

  Future<bool> _refresh() async {
    final refreshed =
        await (widget.refreshOverride?.call() ??
            ZyraDeveloperAccess.refreshCurrentAuthorization());
    if (!refreshed) return false;
    return widget.requireFounderOperator
        ? ZyraDeveloperAccess.isAuthorizedOperator
        : ZyraDeveloperAccess.canUseDeveloperTools;
  }

  void _scheduleDeniedRedirect() {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              widget.deniedDestinationBuilder ??
              (_) => const AuthGate(playSplash: false),
        ),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authorization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ZyraLoading.fullScreen(label: 'Checking access…');
        }
        final cachedStillAllowed = widget.requireFounderOperator
            ? ZyraDeveloperAccess.isAuthorizedOperator
            : ZyraDeveloperAccess.canUseDeveloperTools;
        if (snapshot.data != true || !cachedStillAllowed) {
          _scheduleDeniedRedirect();
          return const SizedBox.shrink();
        }
        return widget.child;
      },
    );
  }
}
