// First-use path selection.
//
// Founder direction, 2026-08-19: this is no longer framed as choosing a
// permanent account type. It asks which ZYRA experience the person needs
// first. One trusted identity may later carry both Seeker and Guardian
// contexts without another sign-in; the server activation for that second
// context remains behind the Founder's explicit migration gate.

import 'dart:async';

import 'package:flutter/material.dart';
import '../../dev/dev_role_choice_design.dart';
import '../../dev/zyra_dev_surface_coordinator.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_initial_signup_draft_service.dart';
import '../../models/zyra_initial_signup_draft.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_onboarding_direction_style.dart';
import '../../widgets/zyra_onboarding_continue_action.dart';
import '../../widgets/zyra_onboarding_edge_swipe.dart';
import '../../widgets/zyra_onboarding_account_exit.dart';
import '../onboarding/onboarding_flow.dart';
import '../onboarding/account_path_overview_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String? recoveryNotice;
  final String? signupUserId;
  final bool devPreview;
  final bool animateDevEntrance;
  const RoleSelectionScreen({
    super.key,
    this.recoveryNotice,
    this.signupUserId,
    this.devPreview = false,
    this.animateDevEntrance = false,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  bool _saving = false;
  bool _advancing = false;
  String? _error;
  String? _signupUserId;
  ZyraSignupRole? _selectedRole;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _entrance;
  bool _entranceStarted = false;
  static const _roleFocusDuration = Duration(milliseconds: 480);
  Timer? _roleFocusTimer;
  int _roleFocusRevision = 0;
  bool _roleFocusSettling = false;

  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  bool get _motionReady =>
      !_roleFocusSettling && _entrance.status == AnimationStatus.completed;

  bool get _canAdvance =>
      _selectedRole != null &&
      _motionReady &&
      !_advancing &&
      !_saving &&
      ModalRoute.of(context)?.isCurrent == true &&
      (!widget.devPreview || ZyraDeveloperAccess.canUseDeveloperTools);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: widget.devPreview && widget.animateDevEntrance ? 0 : 1,
    )..addStatusListener(_onEntranceStatus);
    if (widget.devPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ZyraDevSurfaceCoordinator.instance.attachRoleChoice(
          this,
          isCurrent: () => mounted && ModalRoute.of(context)?.isCurrent == true,
        );
      });
    }
    // A requested preview is never a live draft reader, even when denied.
    if (widget.devPreview) return;
    try {
      final suppliedUserId = widget.signupUserId;
      if (suppliedUserId != null) {
        ZyraInitialSignupDraftService.repository.requireOwner(suppliedUserId);
        _signupUserId = suppliedUserId;
      } else {
        _signupUserId = ZyraInitialSignupDraftService.captureUserId();
      }
    } catch (_) {
      _signupUserId = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _roleFocusTimer?.cancel();
      _roleFocusRevision++;
      _roleFocusSettling = false;
    }
    if (!widget.devPreview || !widget.animateDevEntrance) return;
    if (_reduceMotion) {
      _entrance.value = 1;
    } else if (!_entranceStarted) {
      _entranceStarted = true;
      _entrance.forward();
    }
  }

  void _onEntranceStatus(AnimationStatus status) {
    if (mounted && status == AnimationStatus.completed) setState(() {});
  }

  @override
  void dispose() {
    _roleFocusTimer?.cancel();
    _roleFocusRevision++;
    if (widget.devPreview) {
      ZyraDevSurfaceCoordinator.instance.detachRoleChoice(this);
    }
    _scrollController.dispose();
    _entrance.removeStatusListener(_onEntranceStatus);
    _entrance.dispose();
    super.dispose();
  }

  void _select(ZyraSignupRole role) {
    if (_advancing ||
        ModalRoute.of(context)?.isCurrent != true ||
        (widget.devPreview && !ZyraDeveloperAccess.canUseDeveloperTools)) {
      return;
    }
    _roleFocusTimer?.cancel();
    final revision = ++_roleFocusRevision;
    final settling = !_reduceMotion;
    setState(() {
      _selectedRole = _selectedRole == role ? null : role;
      _error = null;
      _roleFocusSettling = settling;
    });
    if (settling) {
      _roleFocusTimer = Timer(_roleFocusDuration, () {
        if (!mounted || revision != _roleFocusRevision) return;
        // This only finishes local layout motion. Current-route and preview
        // authority checks remain in the shared advance gate, including if
        // another route covered this one while the cards were settling.
        setState(() => _roleFocusSettling = false);
      });
    }
  }

  Future<void> _advanceSelected() async {
    final role = _selectedRole;
    if (role == null ||
        !_motionReady ||
        _advancing ||
        _saving ||
        ModalRoute.of(context)?.isCurrent != true ||
        (widget.devPreview && !ZyraDeveloperAccess.canUseDeveloperTools)) {
      return;
    }
    setState(() => _advancing = true);
    try {
      if (role == ZyraSignupRole.seeker) {
        await _proceedAsSeeker(context);
      } else {
        await _proceedAsWali(context);
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  Future<String?> _remember(ZyraSignupRole role) async {
    if (widget.devPreview) return null;
    if (_saving) return null;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final userId = _signupUserId;
      if (userId == null) throw StateError('Missing signup principal.');
      ZyraInitialSignupDraftService.repository.requireOwner(userId);
      await ZyraInitialSignupDraftService.repository.save(
        userId,
        ZyraInitialSignupDraft(
          role: role,
          showIntroduction: role == ZyraSignupRole.seeker,
        ),
      );
      if (!mounted) return null;
      setState(() => _saving = false);
      return userId;
    } catch (error) {
      debugPrint(
        'ZYRA: role selection draft save failed (${error.runtimeType}).',
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              "We couldn't save your setup securely. Please try again on this device.";
        });
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ZyraDeveloperAccess.authorizationChanges,
      if (widget.devPreview) ZyraDevRoleChoiceDesign.changes,
    ]),
    builder: (context, _) {
      if (widget.devPreview && !ZyraDeveloperAccess.canUseDeveloperTools) {
        return Scaffold(
          key: const ValueKey('role_preview_denied'),
          backgroundColor: ZyraColors.modalSheetSurface,
          body: const SizedBox.expand(),
        );
      }
      return _buildSelection(context);
    },
  );

  Widget _buildSelection(BuildContext context) {
    final previewStyle = OnboardingPreviewStyle.effectiveStyleOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final cardHeight = (screenHeight * .14).clamp(124.0, 176.0).toDouble();
    final focusedCardHeight = (screenHeight * .34)
        .clamp(cardHeight + 74, 310.0)
        .toDouble();
    final selectionDuration = _reduceMotion
        ? Duration.zero
        : _roleFocusDuration;
    final setupLabel = Text(
      'CHOOSE YOUR PATH',
      textAlign: TextAlign.end,
      style: ZyraText.chapterLabel(color: ZyraColors.ink(0.38)),
    );
    final foreground = SafeArea(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final content = SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(26, 28, 26, 18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (viewport.maxHeight - 46).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: _selectionContents(
                      context,
                      previewStyle: previewStyle,

                      cardHeight: cardHeight,
                      focusedCardHeight: focusedCardHeight,
                      selectionDuration: selectionDuration,
                      setupLabel: setupLabel,
                    ),
                  ),
                );
                return ZyraOnboardingEdgeSwipe(
                  controller: _scrollController,
                  enabled: _canAdvance,
                  onForward: () => _advanceSelected(),
                  child: content,
                );
              },
            ),
          ),
          SizedBox(
            height: 78,
            child: Center(
              child: IgnorePointer(
                ignoring: _selectedRole == null,
                child: ExcludeSemantics(
                  excluding: _selectedRole == null,
                  child: AnimatedSwitcher(
                    duration: selectionDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: .9,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _selectedRole == null
                        ? const SizedBox.shrink(
                            key: ValueKey('role-choice-no-continue'),
                          )
                        : ZyraOnboardingArrowAction(
                            key: const ValueKey('role-choice-continue'),
                            active: _canAdvance,
                            semanticLabel: 'Continue with selected experience',
                            onPressed: _advanceSelected,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              previewStyle?.backgroundGradient ?? ZyraColors.brandGradient,
        ),
        child: widget.devPreview && widget.animateDevEntrance
            ? AnimatedBuilder(
                animation: _entrance,
                child: foreground,
                builder: (context, child) {
                  final progress = Curves.easeOutSine.transform(
                    _entrance.value,
                  );
                  return Opacity(
                    key: const ValueKey('dev_onboarding_downward_entry'),
                    opacity: .08 + .92 * progress,
                    child: Transform.translate(
                      offset: Offset(0, 54 * (1 - progress)),
                      child: child,
                    ),
                  );
                },
              )
            : foreground,
      ),
    );
  }

  Widget _selectionContents(
    BuildContext context, {
    required OnboardingPreviewStyle? previewStyle,

    required double cardHeight,
    required double focusedCardHeight,
    required Duration selectionDuration,
    required Widget setupLabel,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'ZYRA',
            style: ZyraText.wordmark(
              size: 20,
              color: ZyraColors.splashWordmark,
            ),
          ),
          const Spacer(),
          Flexible(child: setupLabel),
        ],
      ),
      SizedBox(height: 12),
      // Path choice is a branch, not step one of an invented two-step bar.
      // Keep the former rail's height so the cards do not jump vertically.
      SizedBox(height: previewStyle == null ? 1.5 : 9),
      if (previewStyle == null)
        SizedBox(height: 62)
      else ...[
        SizedBox(height: previewStyle.spacious ? 23 : 16),
        SizedBox(
          key: ValueKey(
            'onboarding-preview-role-${previewStyle.directionName}',
          ),
          width: double.infinity,
          height: previewStyle.spacious ? 110 : 88,
          child: Align(
            alignment: previewStyle.centered
                ? Alignment.center
                : Alignment.centerLeft,
            child: OnboardingPreviewAccent(
              style: previewStyle,
              size: previewStyle.spacious ? 108 : 84,
              progress: .5,
            ),
          ),
        ),
        SizedBox(height: previewStyle.spacious ? 19 : 12),
      ],
      if (previewStyle?.centered == true)
        Center(
          child: Text(
            'CHOOSE WHERE TO BEGIN',
            textAlign: TextAlign.center,
            style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
          ),
        )
      else
        Text(
          'CHOOSE WHERE TO BEGIN',
          style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
        ),
      SizedBox(height: 10),
      if (previewStyle?.centered == true)
        SizedBox(
          width: double.infinity,
          child: Text(
            'How will you use ZYRA first?',
            textAlign: TextAlign.center,
            style: ZyraText.heading(size: previewStyle!.titleSize),
          ),
        )
      else
        Text(
          'How will you use ZYRA first?',
          style: ZyraText.heading(size: previewStyle?.titleSize ?? 28),
        ),
      SizedBox(height: 10),
      if (previewStyle?.centered == true)
        SizedBox(
          width: double.infinity,
          child: Text(
            'Start with the experience you need today.',
            textAlign: TextAlign.center,
            style: ZyraText.subtext(size: 13.5),
          ),
        )
      else
        Text(
          'Start with the experience you need today.',
          style: ZyraText.subtext(size: 13.5),
        ),
      SizedBox(height: previewStyle?.sectionGap ?? 30),
      if (widget.recoveryNotice != null) ...[
        Text(widget.recoveryNotice!, style: ZyraText.subtext()),
        const SizedBox(height: 16),
      ],
      if (_error != null) ...[
        Text(_error!, style: ZyraText.subtext()),
        const SizedBox(height: 16),
      ],
      Column(
        key: const ValueKey('role-choice-options'),
        children: [
          _animatedRoleSlot(
            ZyraSignupRole.seeker,
            visible:
                _selectedRole == null || _selectedRole == ZyraSignupRole.seeker,
            previewStyle: previewStyle,

            minHeight: _selectedRole == ZyraSignupRole.seeker
                ? focusedCardHeight
                : cardHeight,
            focused: _selectedRole == ZyraSignupRole.seeker,
            duration: selectionDuration,
          ),
          AnimatedContainer(
            duration: selectionDuration,
            curve: Curves.easeInOutCubic,
            height: _selectedRole == null
                ? (previewStyle?.spacious == true ? 17 : 14)
                : 0,
          ),
          _animatedRoleSlot(
            ZyraSignupRole.guardian,
            visible:
                _selectedRole == null ||
                _selectedRole == ZyraSignupRole.guardian,
            previewStyle: previewStyle,

            minHeight: _selectedRole == ZyraSignupRole.guardian
                ? focusedCardHeight
                : cardHeight,
            focused: _selectedRole == ZyraSignupRole.guardian,
            duration: selectionDuration,
          ),
        ],
      ),
      if (_signupUserId != null)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
            child: ZyraOnboardingAccountExit(expectedUserId: _signupUserId!),
          ),
        ),
    ],
  );

  Widget _animatedRoleSlot(
    ZyraSignupRole role, {
    required bool visible,
    required OnboardingPreviewStyle? previewStyle,

    required double minHeight,
    required bool focused,
    required Duration duration,
  }) {
    final child = visible
        ? _roleCard(
            role,
            key: ValueKey('role-choice-card-${role.name}'),
            previewStyle: previewStyle,

            minHeight: minHeight,
            focused: focused,
            motionDuration: duration,
          )
        : SizedBox.shrink(key: ValueKey('role-choice-hidden-${role.name}'));
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        // A zero-duration switch can retain the outgoing child for one frame.
        // Accessible/reduced-motion selection must hide it immediately.
        child: duration == Duration.zero
            ? child
            : AnimatedSwitcher(
                duration: duration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                ),
                child: child,
              ),
      ),
    );
  }

  Widget _roleCard(
    ZyraSignupRole role, {
    Key? key,
    required OnboardingPreviewStyle? previewStyle,

    required double minHeight,
    bool focused = false,
    required Duration motionDuration,
  }) => _RoleCard(
    key: key,
    actionKey: ValueKey(
      role == ZyraSignupRole.seeker
          ? 'role-select-seeker'
          : 'role-select-guardian',
    ),
    role: role,
    title: role == ZyraSignupRole.seeker
        ? 'Seek marriage'
        : 'Support as Guardian',
    description: role == ZyraSignupRole.seeker
        ? 'Build my profile and begin my own marriage journey.'
        : 'Guide someone I care for through their journey.',
    previewStyle: previewStyle,

    selected: _selectedRole == role,
    focused: focused,
    minHeight: minHeight,
    motionDuration: motionDuration,
    onTap: () => _select(role),
  );

  Future<void> _proceedAsSeeker(BuildContext context) async {
    if (widget.devPreview) {
      if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          allowSnapshotting: false,
          builder: (_) => OnboardingFlow(
            // A local rehearsal must not inspect the signed-in member.
            welcomeName: 'Shakeel',
            devPreview: true,
          ),
        ),
      );
      return;
    }
    final userId = await _remember(ZyraSignupRole.seeker);
    if (userId == null || !context.mounted) return;
    final firstName = ZyraAuth.onboardingFirstName;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            OnboardingFlow(welcomeName: firstName, signupUserId: userId),
      ),
    );
  }

  Future<void> _proceedAsWali(BuildContext context) async {
    if (widget.devPreview) {
      if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          allowSnapshotting: false,
          builder: (_) =>
              const GuardianOnboardingOverviewScreen(devPreview: true),
        ),
      );
      return;
    }
    final userId = await _remember(ZyraSignupRole.guardian);
    if (userId == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuardianOnboardingOverviewScreen(signupUserId: userId),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Key actionKey;
  final ZyraSignupRole role;
  final String title;
  final String description;
  final OnboardingPreviewStyle? previewStyle;
  final bool selected;
  final bool focused;
  final double minHeight;
  final Duration motionDuration;
  final VoidCallback onTap;

  const _RoleCard({
    super.key,
    required this.actionKey,
    required this.role,
    required this.title,
    required this.description,
    this.previewStyle,
    required this.selected,
    required this.focused,
    required this.minHeight,
    required this.motionDuration,
    required this.onTap,
  });

  IconData get _roleIcon => role == ZyraSignupRole.seeker
      ? Icons.person_outline_rounded
      : Icons.shield_outlined;

  String get _number => role == ZyraSignupRole.seeker ? '01' : '02';

  Widget _selectionMark({double size = 28}) => AnimatedContainer(
    duration: motionDuration,
    curve: Curves.easeInOutCubic,
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected
          ? ZyraColors.journeyGold.withValues(alpha: .18)
          : Colors.transparent,
      border: Border.all(
        color: ZyraColors.journeyGold.withValues(alpha: selected ? .9 : .45),
      ),
    ),
    child: AnimatedSwitcher(
      duration: motionDuration,
      switchInCurve: Curves.easeOutCubic,
      // Leave the transition root unkeyed so AnimatedSwitcher assigns its
      // unique entry number. A rapid checked/unchecked/checked reversal can
      // retain two outgoing states with the same child key briefly.
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: selected
          ? Icon(
              Icons.check_rounded,
              key: ValueKey('role-choice-selected-${role.name}'),
              size: size * .62,
              color: ZyraColors.journeyGold,
            )
          : const SizedBox.shrink(key: ValueKey('role-choice-unchecked')),
    ),
  );

  Widget get _title => AnimatedDefaultTextStyle(
    duration: motionDuration,
    curve: Curves.easeInOutCubic,
    style: ZyraText.button(
      size: focused ? 20 : 17,
      color: ZyraColors.foreground,
    ),
    child: Text(title),
  );

  Widget get _description => AnimatedDefaultTextStyle(
    duration: motionDuration,
    curve: Curves.easeInOutCubic,
    style: ZyraText.subtext(size: focused ? 14 : 12.5),
    child: Text(description),
  );

  BoxDecoration _decoration(BorderRadius radius) => BoxDecoration(
    color: selected
        ? ZyraColors.journeyGold.withValues(alpha: .13)
        : ZyraColors.frostFill,
    border: Border.all(
      color: selected
          ? ZyraColors.journeyGold.withValues(alpha: .85)
          : ZyraColors.frostBorder,
      width: selected ? 1.2 : .8,
    ),
    borderRadius: radius,
  );

  Widget _guidedPaths() => Row(
    children: [
      SizedBox(
        width: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_roleIcon, color: ZyraColors.journeyGold, size: 25),
            const SizedBox(height: 7),
            AnimatedContainer(
              duration: motionDuration,
              curve: Curves.easeInOutCubic,
              width: 1,
              height: focused ? 116 : 36,
              color: ZyraColors.journeyGold.withValues(alpha: .55),
            ),
            const SizedBox(height: 7),
            _selectionMark(size: 20),
          ],
        ),
      ),
      const SizedBox(width: 19),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PATH $_number',
              style: ZyraText.chapterLabel(
                color: ZyraColors.journeyGold.withValues(alpha: .82),
              ),
            ),
            const SizedBox(height: 9),
            _title,
            const SizedBox(height: 8),
            _description,
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $description',
      hint: selected
          ? 'Selected. Tap again to show both choices, or swipe up or use the continue control.'
          : 'Select this experience',
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: motionDuration,
        curve: Curves.easeInOutCubic,
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: _decoration(radius).copyWith(
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ZyraColors.journeyGold.withValues(alpha: .11),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: actionKey,
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: previewStyle?.cardVerticalPadding ?? 18,
              ),
              child: _guidedPaths(),
            ),
          ),
        ),
      ),
    );
  }
}
