export 'package:zyra/widgets/zyra_onboarding_study.dart'
    show ZyraOnboardingDirection, zyraDefaultDevOnboardingDirection;
// Test-only code-selected host for real shared onboarding rendering.
// No direction or style picker is recreated here.
// Visual-only welcome walkthroughs. Never re-enter signup, mutate completion,
// refresh Auth, store a selection, or request device permissions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
export 'queue44_onboarding_opening_fixture.dart'
    show openingFixtureSkipCallback, setOpeningQuoteFixtureFromCode;

import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_edge_swipe.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';
import 'queue44_gold_fixture.dart';
import 'queue44_onboarding_interaction_fixture.dart';
import 'queue44_onboarding_opening_fixture.dart';
import 'queue44_onboarding_transition_fixture.dart';

/// A code-selected story specimen. No direction, style or account picker.
class OnboardingStoryFixture extends StatelessWidget {
  const OnboardingStoryFixture({
    super.key,
    this.initialDirection = zyraDefaultDevOnboardingDirection,
  });
  final ZyraOnboardingDirection initialDirection;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ZyraDeveloperAccess.authorizationChanges,
    builder: (context, _) {
      final allowed = ZyraDeveloperAccess.canUseDeveloperTools;
      return ZyraOnboardingArrowScope(
        enabled:
            ZyraDevOnboardingInteraction.current ==
            ZyraOnboardingAdvanceMode.animatedDownArrow,
        child: Scaffold(
          key: ValueKey(
            allowed
                ? 'dev_onboarding_directions_preview'
                : 'dev_onboarding_directions_denied',
          ),
          body: DecoratedBox(
            key: const ValueKey('dev_onboarding_static_canvas'),
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: SafeArea(
              child: Column(
                children: [
                  IconButton(
                    key: const ValueKey('dev_onboarding_close'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  if (allowed)
                    Expanded(
                      child: KeyedSubtree(
                        key: ValueKey(
                          'onboarding-direction-${initialDirection.name}',
                        ),
                        child: _OnboardingWalkthrough(
                          direction: initialDirection,
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _OnboardingWalkthrough extends StatefulWidget {
  const _OnboardingWalkthrough({required this.direction});

  final ZyraOnboardingDirection direction;

  @override
  State<_OnboardingWalkthrough> createState() => _OnboardingWalkthroughState();
}

class _OnboardingWalkthroughState extends State<_OnboardingWalkthrough> {
  static const _lastRevealStep = 2;
  final PageController _pager = PageController();
  final List<ScrollController> _storyScrolls = List.generate(
    ZyraOnboardingDirection.storyPageCount,
    (_) => ScrollController(),
  );
  final List<int> _revealSteps = List.filled(
    ZyraOnboardingDirection.storyPageCount,
    1,
  );
  final List<bool> _entered = List.generate(
    ZyraOnboardingDirection.storyPageCount,
    (page) => page == 0,
  );
  int _page = 0;
  bool _finishing = false;
  bool _pagerMoving = false;

  @override
  void initState() {
    super.initState();
    ZyraDevOnboardingTransition.changes.addListener(_onTransitionChanged);
  }

  void _onTransitionChanged() {
    if (mounted) setState(() {});
  }

  bool get _accessibleReadingMode => MediaQuery.accessibleNavigationOf(context);
  bool get _canNavigate =>
      mounted &&
      !_finishing &&
      !_pagerMoving &&
      ZyraDeveloperAccess.canUseDeveloperTools;

  bool _fullyRevealed(int page) =>
      _accessibleReadingMode || _revealSteps[page] >= _lastRevealStep;

  Widget _card(int page, {required bool swipeNavigation}) =>
      ZyraOnboardingStudy(
        direction: widget.direction,
        page: page,
        scrollController: _storyScrolls[page],
        swipeNavigation: swipeNavigation,
        revealStep: _accessibleReadingMode
            ? _lastRevealStep
            : _revealSteps[page],
        animateReveal: !_accessibleReadingMode,
        entered: _entered[page],
      );

  void _revealNext(int page) {
    if (!_canNavigate || _page != page || _fullyRevealed(page)) {
      return;
    }
    setState(() => _revealSteps[page]++);
  }

  Future<void> _goTo(int page, {bool bypassReveal = false}) async {
    if (!_canNavigate ||
        page < 0 ||
        page >= ZyraOnboardingDirection.storyPageCount ||
        page == _page) {
      return;
    }
    // Only the developer Skip control may bypass unread story copy.
    if (page > _page && !bypassReveal) {
      if (!_fullyRevealed(_page)) {
        _revealNext(_page);
        return;
      }
      page = _page + 1;
    }
    setState(() {
      _entered[page] = true;
      _pagerMoving = true;
    });
    try {
      if (MediaQuery.disableAnimationsOf(context)) {
        _pager.jumpToPage(page);
      } else {
        final transition = ZyraDevOnboardingTransition.current;
        await _pager.animateToPage(
          page,
          duration: transition.duration,
          curve: transition.curve,
        );
      }
    } finally {
      // onPageChanged can fire halfway through the page travel. Keep every
      // button, reveal and gesture locked until the driven scroll settles.
      if (mounted) setState(() => _pagerMoving = false);
    }
  }

  void _finish() {
    if (!_canNavigate) return;
    _finishing = true;
    Navigator.of(context).maybePop();
  }

  void _continue() {
    if (!_canNavigate) return;
    if (!_fullyRevealed(_page)) {
      _revealNext(_page);
    } else if (_page == ZyraOnboardingDirection.storyPageCount - 1) {
      _finish();
    } else {
      _goTo(_page + 1);
    }
  }

  void _skip() {
    if (!_canNavigate) return;
    if (_page == ZyraOnboardingDirection.storyPageCount - 1) {
      _finish();
    } else {
      _goTo(_page + 1, bypassReveal: true);
    }
  }

  void _swipeTo(int fromPage, int page) {
    if (!_canNavigate || _page != fromPage || !_fullyRevealed(fromPage)) {
      return;
    }
    if (page == ZyraOnboardingDirection.storyPageCount) {
      _finish();
    } else {
      _goTo(page);
    }
  }

  void _swipeRight(int fromPage) {
    if (!_canNavigate ||
        fromPage >= ZyraOnboardingDirection.storyPageCount - 1) {
      return;
    }
    if (!_fullyRevealed(fromPage)) {
      _revealNext(fromPage);
      return;
    }
    _swipeTo(fromPage, fromPage + 1);
  }

  void _swipeLeft(int fromPage) {
    if (fromPage == 0 || !_canNavigate || _page != fromPage) {
      return;
    }
    _goTo(fromPage - 1);
  }

  void _tapForward(int page) {
    if (!_canNavigate || _page != page) {
      return;
    }
    if (!_fullyRevealed(page)) {
      _revealNext(page);
    } else if (page < ZyraOnboardingDirection.storyPageCount - 1) {
      _swipeTo(page, page + 1);
    }
    // The last standalone comparison card finishes through its explicit
    // Continue control, or the guarded down arrow in arrow mode.
  }

  @override
  void dispose() {
    ZyraDevOnboardingTransition.changes.removeListener(_onTransitionChanged);
    _pager.dispose();
    for (final controller in _storyScrolls) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _storyPage(int page) => ZyraOnboardingHorizontalSwipe(
    onNext: page < ZyraOnboardingDirection.storyPageCount - 1
        ? () => _swipeRight(page)
        : null,
    onPrevious: page == 0 ? null : () => _swipeLeft(page),
    onTap:
        page < ZyraOnboardingDirection.storyPageCount - 1 ||
            (!_accessibleReadingMode && _revealSteps[page] < _lastRevealStep)
        ? () => _tapForward(page)
        : null,
    onTapHint: _fullyRevealed(page)
        ? 'Continue to the next introduction card'
        : 'Reveal more introduction text',
    child: page == ZyraOnboardingDirection.storyPageCount - 1
        ? ZyraOnboardingEdgeSwipe(
            controller: _storyScrolls[page],
            enabled: _canNavigate && _page == page,
            onForward: () =>
                _swipeTo(page, ZyraOnboardingDirection.storyPageCount),
            child: _card(page, swipeNavigation: true),
          )
        : _card(page, swipeNavigation: false),
  );

  @override
  Widget build(BuildContext context) {
    final arrowMode = ZyraOnboardingArrowScope.enabledOf(context);
    final transition = ZyraDevOnboardingTransition.current;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _canNavigate ? () => _tapForward(_page) : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(
              'ZYRA',
              style: ZyraText.wordmark(
                size: 18,
                color: ZyraColors.splashWordmark,
              ),
            ),
          ),
          Expanded(
            child: PageView(
              key: const ValueKey('dev_onboarding_page_view'),
              controller: _pager,
              scrollDirection: Axis.horizontal,
              reverse: true,
              allowImplicitScrolling:
                  transition != ZyraOnboardingPageTransition.current,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                if (!_finishing) setState(() => _page = page);
                ZyraDevOnboardingGoldMotion.pageEntered();
              },
              children: [
                for (
                  var page = 0;
                  page < ZyraOnboardingDirection.storyPageCount;
                  page++
                )
                  ZyraOnboardingTransitionFrame(
                    controller: _pager,
                    pageIndex: page,
                    axis: Axis.horizontal,
                    reverse: true,
                    transition: transition,
                    child: _storyPage(page),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 3, 24, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: _page == 0
                          ? const SizedBox.shrink()
                          : TextButton(
                              key: const ValueKey('dev_onboarding_back'),
                              onPressed: _canNavigate
                                  ? () => _goTo(_page - 1)
                                  : null,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                                minimumSize: const Size(44, 44),
                              ),
                              child: Text(
                                'Back',
                                maxLines: 2,
                                textAlign: TextAlign.left,
                                style: ZyraText.subtext(size: 10),
                              ),
                            ),
                    ),
                    const Expanded(
                      child: Row(
                        key: ValueKey('dev_onboarding_page_dots'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [],
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${_page + 1} / ${ZyraOnboardingDirection.storyPageCount}',
                        key: const ValueKey('dev_onboarding_page_count'),
                        textAlign: TextAlign.right,
                        style: ZyraText.subtext(size: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (arrowMode)
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        const Expanded(child: SizedBox.shrink()),
                        if (_page ==
                                ZyraOnboardingDirection.storyPageCount - 1 &&
                            _fullyRevealed(_page))
                          ZyraOnboardingArrowAction(
                            key: const ValueKey('dev_onboarding_continue'),
                            active: _canNavigate,
                            onPressed: _canNavigate ? _continue : null,
                            semanticLabel: 'Finish preview',
                          ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      key: const ValueKey('dev_onboarding_continue'),
                      onPressed: _canNavigate ? _continue : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: ZyraColors.goldTextFill,
                        foregroundColor: ZyraColors.luxuryDarkPurple,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        _page == ZyraOnboardingDirection.storyPageCount - 1
                            ? 'Finish preview'
                            : 'Continue',
                        style: ZyraText.button(size: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The selected welcome story inside the continuous local onboarding flow.
/// No lab header, design arrows or finish/pop shortcut. The outer process owns
/// Close and the nested Navigator; capability loss remains deny-first.
class OnboardingIntroductionFixture extends StatefulWidget {
  const OnboardingIntroductionFixture({
    super.key,
    required this.direction,
    required this.onContinue,
    this.onBackToProvider,
    this.welcomeName = 'Shakeel',
  });

  final ZyraOnboardingDirection direction;
  final VoidCallback onContinue;
  final VoidCallback? onBackToProvider;

  /// A synthetic preview name; never read a signed-in member's identity here.
  final String welcomeName;

  @override
  State<OnboardingIntroductionFixture> createState() =>
      _OnboardingIntroductionFixtureState();
}

class _OnboardingIntroductionFixtureState
    extends State<OnboardingIntroductionFixture> {
  @override
  Widget build(BuildContext context) => OnboardingOpeningFixture(
    direction: widget.direction,
    welcomeName: widget.welcomeName,
    onContinue: widget.onContinue,
    onBackToProvider: widget.onBackToProvider,
  );
}

/// Retained callback fixture, never a widget or an application entry point.
VoidCallback? storyFixtureSkipCallback(WidgetTester tester) {
  final walk = find.byType(_OnboardingWalkthrough);
  if (walk.evaluate().isEmpty) return openingFixtureSkipCallback(tester);
  final state = tester.state<_OnboardingWalkthroughState>(walk);
  return state._canNavigate ? state._skip : null;
}
