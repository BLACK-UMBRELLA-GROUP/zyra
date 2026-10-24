// Founder 2026-10-03: One/Basic role samples, plus one Onboarding flow.
// The signup account role is chosen inside onboarding, not an extra dev picker.

import 'package:flutter/material.dart';

import '../../dev/zyra_dev_local_preview.dart';
import '../../dev/zyra_dev_surface_coordinator.dart';
import '../../dev/zyra_dev_signup.dart';
import '../../services/zyra_developer_access.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../auth_gate.dart';
import 'zyra_health_usage_screen.dart';

class DeveloperAccessScreen extends StatefulWidget {
  const DeveloperAccessScreen({super.key});

  @override
  State<DeveloperAccessScreen> createState() => _DeveloperAccessScreenState();
}

class _DeveloperAccessScreenState extends State<DeveloperAccessScreen> {
  late final Future<bool> _routeAuthorization;
  bool _choosingSignUp = false;

  @override
  void initState() {
    super.initState();
    // Release/TestFlight is allowed only through the existing explicit build,
    // pinned identity and freshly verified protected-role policy.
    _routeAuthorization = ZyraDeveloperAccess.refreshCurrentAuthorization();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ModalRoute.of subscribes to isCurrent changes, including pushed signup
    // pages and pop. A mounted-but-covered landing must not hide their banner.
    final current = ModalRoute.of(context)?.isCurrent ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ZyraDevSurfaceCoordinator.instance.setDeveloperLandingVisible(
        this,
        current,
      );
    });
  }

  @override
  void dispose() {
    // Navigator can dispose during build. Publish outside that build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ZyraDevSurfaceCoordinator.instance.setDeveloperLandingVisible(
        this,
        false,
      );
    });
    super.dispose();
  }

  Future<void> _chooseSignUp() async {
    if (_choosingSignUp) return;
    _choosingSignUp = true;
    try {
      // The app's Welcome and first-use role page own the full process.
      // No extra developer-only Seeker/Guardian choice in front of it.
      await ZyraDevSignUp.start(context);
    } finally {
      _choosingSignUp = false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _routeAuthorization,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const ZyraLoading.fullScreen(label: 'Checking access…');
      }
      if (snapshot.data != true || !ZyraDeveloperAccess.isAuthorizedOperator) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const AuthGate(playSplash: false),
            ),
            (_) => false,
          );
        });
        return const SizedBox.shrink();
      }
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 750;
                final actionGap = compact ? 16.0 : 22.0;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 31),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: compact ? 24 : 72),
                          GestureDetector(
                            key: const ValueKey('dev_access_health_usage'),
                            behavior: HitTestBehavior.opaque,
                            onLongPress: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => const ZyraHealthUsageScreen(),
                              ),
                            ),
                            child: Text(
                              'Developer Access',
                              textAlign: TextAlign.center,
                              style: ZyraText.heading(size: 25),
                            ),
                          ),
                          SizedBox(height: compact ? 24 : 98),
                          _DevPill(
                            key: const ValueKey('dev_access_seeker'),
                            label: 'Seeker',
                            onTap: () => ZyraDevLocalPreview.open(
                              context,
                              isWali: false,
                              premium: true,
                            ),
                          ),
                          SizedBox(height: actionGap),
                          _DevPill(
                            key: const ValueKey('dev_access_seeker_basic'),
                            label: 'Seeker Basic',
                            onTap: () => ZyraDevLocalPreview.open(
                              context,
                              isWali: false,
                              premium: false,
                            ),
                          ),
                          SizedBox(height: actionGap),
                          _DevPill(
                            key: const ValueKey('dev_access_guardian'),
                            label: 'Guardian',
                            onTap: () => ZyraDevLocalPreview.open(
                              context,
                              isWali: true,
                              premium: true,
                            ),
                          ),
                          SizedBox(height: actionGap),
                          _DevPill(
                            key: const ValueKey('dev_access_guardian_basic'),
                            label: 'Guardian Basic',
                            onTap: () => ZyraDevLocalPreview.open(
                              context,
                              isWali: true,
                              premium: false,
                            ),
                          ),
                          SizedBox(height: actionGap),
                          _DevPill(
                            key: const ValueKey('dev_access_signup'),
                            label: 'Onboarding',
                            onTap: _chooseSignUp,
                          ),
                          SizedBox(height: compact ? 24 : 40),
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
    },
  );
}

class _DevPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DevPill({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.iconButtonBg,
    shape: StadiumBorder(
      side: BorderSide(color: ZyraColors.iconButtonBorder, width: 0.75),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 80),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: ZyraText.button(size: 19),
            ),
          ),
        ),
      ),
    ),
  );
}
