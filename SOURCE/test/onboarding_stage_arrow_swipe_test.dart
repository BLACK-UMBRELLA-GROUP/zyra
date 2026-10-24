import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_edge_swipe.dart';

const _welcomeScroll = ValueKey('onboarding_preview_welcome_scrollable');
const _stageScroll = ValueKey('onboarding_stage_scrollable');
const _welcomeAction = ValueKey('onboarding_welcome_continue');
const _stageAction = ValueKey('onboarding_stage_continue');
const _backAction = ValueKey('onboarding_stage_scroll_up');
const _skip = ValueKey('onboarding_stage_dev_skip');

Future<void> _pumpIntro(
  WidgetTester tester, {
  required FutureOr<void> Function() onContinue,
  VoidCallback? onSkip,
  bool arrowMode = true,
  SeekerOnboardingStage stage = SeekerOnboardingStage.buildProfile,
  Size size = const Size(375, 667),
  double textScale = 1,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  ValueNotifier<int>? parentRebuilds,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  Widget buildIntro() => ZyraOnboardingArrowScope(
    enabled: arrowMode,
    child: OnboardingStageIntroScreen(
      stage: stage,
      devPreview: true,
      allowPreviewScrolling: true,
      onContinue: onContinue,
      onDevSkip: onSkip,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
        ),
        child: child!,
      ),
      home: parentRebuilds == null
          ? buildIntro()
          : ValueListenableBuilder<int>(
              valueListenable: parentRebuilds,
              builder: (context, revision, _) => buildIntro(),
            ),
    ),
  );
  await tester.pumpAndSettle();
}

PageController _pager(WidgetTester tester) => tester
    .widget<PageView>(find.byKey(const ValueKey('onboarding_intro_page_view')))
    .controller!;

VoidCallback _continueCallback(WidgetTester tester, ValueKey<String> key) =>
    tester
        .widget<ZyraOnboardingArrowAction>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(ZyraOnboardingArrowAction),
          ),
        )
        .onPressed!;

void _jumpToEnd(WidgetTester tester, ValueKey<String> scrollKey) {
  final scrollable = find.descendant(
    of: find.byKey(scrollKey),
    matching: find.byType(Scrollable),
  );
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.maxScrollExtent);
}

Future<void> _dragPage(
  WidgetTester tester,
  ValueKey<String> scrollKey,
  double delta,
) async {
  await tester.drag(find.byKey(scrollKey), Offset(0, delta));
  await tester.pumpAndSettle();
}

Future<void> _revealRoadmap(WidgetTester tester) async {
  final tapArea = find.byKey(
    const ValueKey('onboarding_welcome_reveal_tap_area'),
  );
  for (var item = 0; item < 4; item++) {
    await tester.tap(tapArea);
    await tester.pumpAndSettle();
  }
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  testWidgets(
    'page actions remain locked after halfway until both directions settle',
    (tester) async {
      var completions = 0;
      final completion = Completer<void>();
      await _pumpIntro(
        tester,
        size: const Size(430, 932),
        onContinue: () async {
          completions++;
          await completion.future;
        },
      );
      await _revealRoadmap(tester);
      final forward = _continueCallback(tester, _welcomeAction);
      forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      final pager = _pager(tester);
      expect(pager.page, inExclusiveRange(.5, 1));
      expect(pager.position.isScrollingNotifier.value, isTrue);
      final halfwayPosition = pager.page!;
      final back = tester.widget<InkWell>(find.byKey(_backAction)).onTap!;
      final complete = _continueCallback(tester, _stageAction);
      for (var attempt = 0; attempt < 3; attempt++) {
        back();
        complete();
        forward();
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(pager.page, greaterThan(halfwayPosition));
      expect(completions, 0);
      await tester.pumpAndSettle();
      expect(pager.page, closeTo(1, .001));
      expect(pager.position.isScrollingNotifier.value, isFalse);

      back();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      expect(pager.page, inExclusiveRange(0, .5));
      final returningPosition = pager.page!;
      for (var attempt = 0; attempt < 3; attempt++) {
        forward();
        back();
        complete();
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(pager.page, lessThan(returningPosition));
      expect(completions, 0);
      await tester.pumpAndSettle();
      expect(pager.page, closeTo(0, .001));

      // Re-entering is deliberately rearmed only once the return has settled.
      forward();
      await tester.pumpAndSettle();
      expect(pager.page, closeTo(1, .001));
      complete();
      complete();
      back();
      expect(completions, 1);
      expect(pager.page, closeTo(1, .001));
      completion.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelled edge gesture cannot start a page handoff', (
    tester,
  ) async {
    var completions = 0;
    await _pumpIntro(
      tester,
      size: const Size(430, 932),
      onContinue: () => completions++,
    );
    await _revealRoadmap(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_welcomeScroll)),
    );
    await gesture.moveBy(const Offset(0, -82));
    await tester.pump(const Duration(milliseconds: 30));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(_pager(tester).page, closeTo(0, .001));
    expect(completions, 0);
    _continueCallback(tester, _welcomeAction)();
    await tester.pumpAndSettle();
    expect(_pager(tester).page, closeTo(1, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('interrupted page animation rearms at its settled page', (
    tester,
  ) async {
    var completions = 0;
    await _pumpIntro(
      tester,
      size: const Size(430, 932),
      onContinue: () => completions++,
    );
    await _revealRoadmap(tester);
    final forward = _continueCallback(tester, _welcomeAction);
    forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    final pager = _pager(tester);
    expect(pager.page, inExclusiveRange(.5, 1));
    pager.jumpToPage(0);
    await tester.pumpAndSettle();
    expect(pager.page, closeTo(0, .001));
    expect(completions, 0);
    forward();
    await tester.pumpAndSettle();
    expect(pager.page, closeTo(1, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing a mid-transition intro cannot complete or setState', (
    tester,
  ) async {
    var completions = 0;
    await _pumpIntro(
      tester,
      size: const Size(430, 932),
      onContinue: () => completions++,
    );
    await _revealRoadmap(tester);
    _continueCallback(tester, _welcomeAction)();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(_pager(tester).page, inExclusiveRange(.5, 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(completions, 0);
    expect(tester.takeException(), isNull);
  });

  for (final accessible in [false, true]) {
    testWidgets(
      '${accessible ? 'accessible navigation' : 'reduced motion'} settles without leaving the page latch locked',
      (tester) async {
        var completions = 0;
        final completion = Completer<void>();
        await _pumpIntro(
          tester,
          disableAnimations: !accessible,
          accessibleNavigation: accessible,
          size: const Size(430, 932),
          onContinue: () async {
            completions++;
            await completion.future;
          },
        );
        await _revealRoadmap(tester);
        final forward = _continueCallback(tester, _welcomeAction);
        forward();
        await tester.pump();
        expect(_pager(tester).page, closeTo(1, .001));
        expect(_pager(tester).position.isScrollingNotifier.value, isFalse);
        final back = tester.widget<InkWell>(find.byKey(_backAction)).onTap!;
        back();
        await tester.pump();
        expect(_pager(tester).page, closeTo(0, .001));
        forward();
        await tester.pump();
        expect(_pager(tester).page, closeTo(1, .001));
        _continueCallback(tester, _stageAction)();
        _continueCallback(tester, _stageAction)();
        expect(completions, 1);
        completion.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Current intro responds to a light swipe on a standard phone', (
    tester,
  ) async {
    var completions = 0;
    await _pumpIntro(
      tester,
      size: const Size(430, 932),
      onContinue: () => completions++,
    );
    await _dragPage(tester, _welcomeScroll, -30);
    expect(
      tester
          .widget<PageView>(
            find.byKey(const ValueKey('onboarding_intro_page_view')),
          )
          .controller
          ?.page,
      closeTo(0, .01),
    );
    await _dragPage(tester, _welcomeScroll, -82);
    expect(
      tester
          .widget<PageView>(
            find.byKey(const ValueKey('onboarding_intro_page_view')),
          )
          .controller
          ?.page,
      closeTo(0, .01),
    );
    await _revealRoadmap(tester);
    await _dragPage(tester, _welcomeScroll, -82);
    expect(
      tester
          .widget<PageView>(
            find.byKey(const ValueKey('onboarding_intro_page_view')),
          )
          .controller
          ?.page,
      closeTo(1, .01),
    );
    await _dragPage(tester, _stageScroll, -82);
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'arrow mode reads long content first, can go back, and completes once',
    (tester) async {
      var completions = 0;
      final inFlight = Completer<void>();
      await _pumpIntro(
        tester,
        onContinue: () async {
          completions++;
          await inFlight.future;
        },
      );
      await _revealRoadmap(tester);

      // Scrolling readable content toward its end is not an advance gesture.
      final welcomePosition = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(_welcomeScroll),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      if (welcomePosition.maxScrollExtent > 100) {
        await _dragPage(tester, _welcomeScroll, -60);
        expect(find.byKey(_welcomeAction).hitTestable(), findsOneWidget);
        expect(find.byKey(_stageAction).hitTestable(), findsNothing);
      }

      _jumpToEnd(tester, _welcomeScroll);
      await tester.pump();
      await _dragPage(tester, _welcomeScroll, -170);
      expect(
        tester
            .widget<PageView>(
              find.byKey(const ValueKey('onboarding_intro_page_view')),
            )
            .controller
            ?.page,
        closeTo(1, .01),
      );
      expect(completions, 0);

      // Returning to the welcome slide rearms only its welcome-to-stage action.
      await _dragPage(tester, _stageScroll, 170);
      expect(
        tester
            .widget<PageView>(
              find.byKey(const ValueKey('onboarding_intro_page_view')),
            )
            .controller
            ?.page,
        closeTo(0, .01),
      );
      _jumpToEnd(tester, _welcomeScroll);
      await tester.pump();
      await _dragPage(tester, _welcomeScroll, -170);
      expect(
        tester
            .widget<PageView>(
              find.byKey(const ValueKey('onboarding_intro_page_view')),
            )
            .controller
            ?.page,
        closeTo(1, .01),
      );

      _jumpToEnd(tester, _stageScroll);
      await tester.pump();
      await _dragPage(tester, _stageScroll, -170);
      expect(completions, 1);
      await tester.ensureVisible(find.byKey(_stageAction));
      await tester.tap(find.byKey(_stageAction));
      expect(completions, 1);
      inFlight.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact arrow-mode Skip is dim, bottom-right, and clear of centered action',
    (tester) async {
      await _pumpIntro(
        tester,
        onContinue: () {},
        onSkip: () {},
        size: const Size(320, 568),
        textScale: 1.4,
      );
      await _revealRoadmap(tester);
      final skipRect = tester.getRect(find.byKey(_skip));
      expect(skipRect.right, closeTo(304, 1));
      expect(skipRect.center.dy, greaterThan(450));
      expect(skipRect.bottom, lessThanOrEqualTo(568));

      // Larger copy must scroll before a new bottom gesture can advance.
      final welcomePosition = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(_welcomeScroll),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      expect(welcomePosition.maxScrollExtent, greaterThan(0));
      await _dragPage(tester, _welcomeScroll, -35);
      expect(
        tester
            .widget<PageView>(
              find.byKey(const ValueKey('onboarding_intro_page_view')),
            )
            .controller
            ?.page,
        closeTo(0, .01),
      );

      await tester.ensureVisible(find.byKey(_welcomeAction));
      await tester.pumpAndSettle();
      final arrowRect = tester.getRect(find.byKey(_welcomeAction));
      expect(arrowRect.overlaps(skipRect), isFalse);
      expect(arrowRect.center.dx, closeTo(160, 8));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'standalone Current comparator stage completes from content swipe once',
    (tester) async {
      var completions = 0;
      final inFlight = Completer<void>();
      await _pumpIntro(
        tester,
        stage: SeekerOnboardingStage.journeyBio,
        onContinue: () async {
          completions++;
          await inFlight.future;
        },
      );
      expect(
        find.byKey(const ValueKey('onboarding_intro_page_view')),
        findsNothing,
      );
      _jumpToEnd(tester, _stageScroll);
      await tester.pump();
      await _dragPage(tester, _stageScroll, -170);
      expect(completions, 1);
      await tester.ensureVisible(find.byKey(_stageAction));
      await tester.tap(find.byKey(_stageAction));
      expect(completions, 1);
      inFlight.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed async completion can be deliberately retried', (
    tester,
  ) async {
    var attempts = 0;
    final failedAttempt = Completer<void>();
    await _pumpIntro(
      tester,
      stage: SeekerOnboardingStage.journeyBio,
      onContinue: () async {
        attempts++;
        if (attempts == 1) await failedAttempt.future;
      },
    );
    await tester.ensureVisible(find.byKey(_stageAction));
    await tester.tap(find.byKey(_stageAction));
    await tester.tap(find.byKey(_stageAction));
    expect(attempts, 1);
    failedAttempt.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_stageAction));
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'parent rebuild during failed async continuation rearms a fresh edge swipe',
    (tester) async {
      var attempts = 0;
      final failedAttempt = Completer<void>();
      final parentRebuilds = ValueNotifier<int>(0);
      addTearDown(parentRebuilds.dispose);
      await _pumpIntro(
        tester,
        stage: SeekerOnboardingStage.journeyBio,
        parentRebuilds: parentRebuilds,
        onContinue: () async {
          attempts++;
          // Model the account flow's saving/error rebuilds without any I/O.
          parentRebuilds.value++;
          if (attempts == 1) {
            try {
              await failedAttempt.future;
            } on StateError {
              parentRebuilds.value++;
            }
          }
        },
      );
      _jumpToEnd(tester, _stageScroll);
      await tester.pump();
      await _dragPage(tester, _stageScroll, -170);
      expect(attempts, 1);
      expect(
        tester
            .widget<ZyraOnboardingEdgeSwipe>(
              find.byType(ZyraOnboardingEdgeSwipe),
            )
            .enabled,
        isFalse,
      );
      final repeat = _continueCallback(tester, _stageAction);
      repeat();
      repeat();
      expect(attempts, 1);

      failedAttempt.completeError(StateError('Simulated save failure'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ZyraOnboardingEdgeSwipe>(
              find.byType(ZyraOnboardingEdgeSwipe),
            )
            .enabled,
        isTrue,
      );
      _jumpToEnd(tester, _stageScroll);
      await tester.pump();
      await _dragPage(tester, _stageScroll, -170);
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Continue mode keeps original top Skip and ignores child overscroll completion',
    (tester) async {
      var completions = 0;
      await _pumpIntro(
        tester,
        onContinue: () => completions++,
        onSkip: () {},
        arrowMode: false,
      );
      expect(tester.getRect(find.byKey(_skip)).top, lessThan(100));
      await _revealRoadmap(tester);
      await tester.ensureVisible(find.byKey(_welcomeAction));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_welcomeAction));
      await tester.pumpAndSettle();
      _jumpToEnd(tester, _stageScroll);
      await tester.pump();
      await _dragPage(tester, _stageScroll, -170);
      expect(completions, 0);
      await tester.tap(find.byKey(_stageAction));
      expect(completions, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
