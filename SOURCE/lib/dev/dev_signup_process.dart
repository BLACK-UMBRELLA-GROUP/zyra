// A bounded, local-only rehearsal of the existing first-use screens.
// The nested Navigator contains their replacement/removal transitions so
// Home in the developer toggle returns to the Developer Access landing.
// Child screens own their safe insets; no rehearsal chrome frames the flow.
import 'package:flutter/material.dart';

import '../screens/welcome_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../services/zyra_developer_access.dart';
import '../services/zyra_internal_preview_client.dart';
import '../theme/zyra_colors.dart';
import '../state/app_state.dart';
import '../widgets/zyra_onboarding_direction_style.dart';
import '../widgets/zyra_onboarding_continue_action.dart';
import '../widgets/zyra_onboarding_study.dart';
import 'dev_onboarding_interaction.dart';
import 'dev_onboarding_lab.dart';
import 'dev_onboarding_transition.dart';
import 'zyra_dev_surface_coordinator.dart';
import 'zyra_dev_home.dart';
import 'zyra_dev_control_system.dart' show ZyraDevControlsRouteObserver;

class DevSignUpProcessScreen extends StatefulWidget {
  const DevSignUpProcessScreen({
    super.key,
    this.initialDirection = zyraDefaultDevOnboardingDirection,
  });

  final ZyraOnboardingDirection initialDirection;

  @override
  State<DevSignUpProcessScreen> createState() => _DevSignUpProcessScreenState();
}

class _DevSignUpProcessScreenState extends State<DevSignUpProcessScreen> {
  GlobalKey<NavigatorState> _flowNavigator = GlobalKey<NavigatorState>();
  List<NavigatorObserver> _flowObservers = [ZyraDevControlsRouteObserver()];
  late ZyraOnboardingDirection _direction = widget.initialDirection;
  int _generation = 0;
  bool _isolated = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    // The helper latches before resetting fixtures. Also isolate an authorised
    // direct construction before any child can reach sample-state caches.
    if (ZyraDeveloperAccess.canUseDeveloperTools) {
      ZyraInternalPreviewClient.beginPreview();
      _isolated = true;
      ZyraDevSurfaceCoordinator.instance.attachOnboarding(
        this,
        _restart,
        onClose: _closeFlow,
        isCurrent: _isCurrent,
      );
    }
  }

  bool _isCurrent() =>
      mounted &&
      !_closing &&
      _isolated &&
      ZyraDeveloperAccess.canUseDeveloperTools &&
      ModalRoute.of(context)?.isCurrent == true;

  Future<void> _closeFlow() async {
    if (!_isCurrent()) return;
    _closing = true;
    final generation = _generation;
    final route = ModalRoute.of(context);
    final closed = await ZyraDevHome.open(
      context,
      isCurrent: () =>
          mounted &&
          _isolated &&
          generation == _generation &&
          route?.isCurrent == true,
    );
    if (mounted && !closed) _closing = false;
  }

  void _restart(ZyraOnboardingDirection direction) {
    if (!mounted || !_isolated || !ZyraDeveloperAccess.canUseDeveloperTools) {
      return;
    }
    AppState.instance.applyDevPreset();
    setState(() {
      _direction = direction;
      _generation++;
      _flowNavigator = GlobalKey<NavigatorState>();
      _flowObservers = [ZyraDevControlsRouteObserver()];
    });
  }

  Widget _welcome() {
    final generation = _generation;
    final direction = _direction;
    return WelcomeScreen(
      devPreview: true,
      devIntroductionRouteBuilder: direction == ZyraOnboardingDirection.current
          ? null
          : (builder) {
              final transition = ZyraDevOnboardingTransition.current;
              return PageRouteBuilder<void>(
                allowSnapshotting: false,
                transitionDuration: transition.duration,
                reverseTransitionDuration: transition.duration,
                pageBuilder: (context, _, _) => builder(context),
                transitionsBuilder: (context, animation, _, child) =>
                    ZyraOnboardingEntryTransition(
                      transition: transition,
                      animation: animation,
                      child: child,
                    ),
              );
            },
      devIntroductionBuilder: direction == ZyraOnboardingDirection.current
          ? null
          : (introContext) => DevOnboardingIntroduction(
              direction: direction,
              welcomeName: 'Shakeel',
              onBackToProvider: () {
                if (!_isCurrent() ||
                    generation != _generation ||
                    !introContext.mounted ||
                    ModalRoute.of(introContext)?.isCurrent != true ||
                    !ZyraDeveloperAccess.canUseDeveloperTools) {
                  return;
                }
                _flowNavigator.currentState?.pushReplacement(
                  MaterialPageRoute<void>(
                    allowSnapshotting: false,
                    builder: (_) => _welcome(),
                  ),
                );
              },
              onContinue: () {
                if (!_isCurrent() ||
                    generation != _generation ||
                    !introContext.mounted ||
                    ModalRoute.of(introContext)?.isCurrent != true ||
                    !ZyraDeveloperAccess.canUseDeveloperTools) {
                  return;
                }
                // Guardian support is the continuous reader's final down
                // checkpoint in both Tap-through and Scroll-all modes. Its
                // foreground has already exited; do not add a lateral route
                // transition before the matching role-content entrance.
                _flowNavigator.currentState?.pushReplacement(
                  PageRouteBuilder<void>(
                    allowSnapshotting: false,
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    pageBuilder: (_, _, _) => const RoleSelectionScreen(
                      devPreview: true,
                      animateDevEntrance: true,
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    ZyraDevSurfaceCoordinator.instance.detachOnboarding(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ZyraDeveloperAccess.authorizationChanges,
      ZyraDevOnboardingInteraction.changes,
    ]),
    builder: (context, _) {
      final allowed = _isolated && ZyraDeveloperAccess.canUseDeveloperTools;
      return Scaffold(
        key: ValueKey(allowed ? 'dev_signup_process' : 'dev_signup_denied'),
        backgroundColor: ZyraColors.luxuryDarkPurple,
        body: allowed
            ? ZyraOnboardingArrowScope(
                enabled:
                    ZyraDevOnboardingInteraction.current ==
                    ZyraOnboardingAdvanceMode.animatedDownArrow,
                child: OnboardingPreviewStyle(
                  directionName: _direction.name,
                  child: ClipRect(
                    child: Navigator(
                      key: _flowNavigator,
                      observers: _flowObservers,
                      onGenerateInitialRoutes: (_, _) => [
                        MaterialPageRoute<void>(
                          allowSnapshotting: false,
                          builder: (_) => _welcome(),
                        ),
                      ],
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        allowSnapshotting: false,
                        builder: (_) => _welcome(),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.expand(),
      );
    },
  );
}
