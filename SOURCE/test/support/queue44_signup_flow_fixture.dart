export 'package:zyra/widgets/zyra_onboarding_study.dart'
    show ZyraOnboardingDirection, zyraDefaultDevOnboardingDirection;
// Test-only nested navigation of real first-use screens. No app route or picker.
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
// The nested Navigator contains real first-use replacement/removal transitions.
// Code-only close returns to the invoking route; child screens own safe insets.
import 'package:flutter/material.dart';

import 'queue44_gold_fixture.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'queue44_onboarding_interaction_fixture.dart';
import 'queue44_onboarding_story_fixture.dart';
import 'queue44_onboarding_transition_fixture.dart';

class SignupFlowFixture extends StatefulWidget {
  const SignupFlowFixture({
    super.key,
    this.initialDirection = zyraDefaultDevOnboardingDirection,
  });

  final ZyraOnboardingDirection initialDirection;

  @override
  State<SignupFlowFixture> createState() => _SignupFlowFixtureState();
}

class _SignupFlowFixtureState extends State<SignupFlowFixture> {
  GlobalKey<NavigatorState> _flowNavigator = GlobalKey<NavigatorState>();
  List<NavigatorObserver> _flowObservers = [ZyraPreviewRouteObserver()];
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
      OnboardingFixtureController.instance.attach(
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
    final closed = await Navigator.of(context).maybePop();
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
      _flowObservers = [ZyraPreviewRouteObserver()];
    });
  }

  Widget _welcome() {
    final generation = _generation;
    final direction = _direction;
    return Queue44WelcomeFixture(
      devPreview: true,
      devIntroductionRouteBuilder: (builder) {
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
      devIntroductionBuilder: (introContext) => OnboardingIntroductionFixture(
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
    OnboardingFixtureController.instance.detach(this);
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

/// A fixture lifetime owns only a mounted route's restart/close callbacks.
/// It is deliberately unrelated to production account/role/surface state.
class OnboardingFixtureController {
  static final instance = OnboardingFixtureController();
  Object? _owner;
  ValueChanged<ZyraOnboardingDirection>? _restart;
  VoidCallback? _close;
  bool Function()? _current;
  int _epoch = 0;
  String get entryLabel => _owner == null ? 'Fixture host' : 'Onboarding';
  bool get canCloseOnboarding =>
      _owner != null &&
      ZyraDeveloperAccess.canUseDeveloperTools &&
      _current?.call() == true;

  void attach(
    Object owner,
    ValueChanged<ZyraOnboardingDirection> restart, {
    required VoidCallback onClose,
    required bool Function() isCurrent,
  }) {
    _owner = owner;
    _restart = restart;
    _close = onClose;
    _current = isCurrent;
    _epoch++;
  }

  void detach(Object owner) {
    if (!identical(owner, _owner)) return;
    resetForTesting();
  }

  bool restartOnboarding(ZyraOnboardingDirection direction) {
    if (!canCloseOnboarding) return false;
    _restart!(direction);
    _epoch++;
    return true;
  }

  bool closeOnboarding() {
    if (!canCloseOnboarding) return false;
    _close!();
    return true;
  }

  bool Function()? get onboardingExit {
    if (!canCloseOnboarding) return null;
    final epoch = _epoch;
    final owner = _owner;
    return () =>
        epoch == _epoch && identical(owner, _owner) && closeOnboarding();
  }

  void resetForTesting() {
    OnboardingFixtureLauncher._opening = false;
    _owner = null;
    _restart = null;
    _close = null;
    _current = null;
    _epoch++;
  }
}

class OnboardingFixtureLauncher {
  static bool _opening = false;
  static Future<void> start(
    BuildContext context, {
    ZyraOnboardingDirection direction = zyraDefaultDevOnboardingDirection,
  }) async {
    if (_opening || !ZyraDeveloperAccess.canUseDeveloperTools) return;
    _opening = true;
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          allowSnapshotting: false,
          builder: (_) => SignupFlowFixture(initialDirection: direction),
        ),
      );
    } finally {
      _opening = false;
    }
  }
}
