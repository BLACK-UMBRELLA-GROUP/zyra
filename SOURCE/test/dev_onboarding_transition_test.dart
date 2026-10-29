import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_directions.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_transition.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';

const _arrow = ValueKey('dev_onboarding_continue');
const _pages = ValueKey('dev_onboarding_page_view');
const _host = ValueKey('onboarding-transition-host');

void _noOp() {}

Finder _story(int page) => find.byKey(
  ValueKey(
    'onboarding-study-scroll-${ZyraOnboardingDirection.luma.name}-$page',
  ),
);

Future<void> _revealCard(WidgetTester tester, int page) async {
  for (var step = 0; step < 1; step++) {
    await tester.tap(_story(page));
    await tester.pumpAndSettle();
  }
}

Future<void> _swipeCard(WidgetTester tester, int page, double dx) async {
  await tester.drag(_story(page), Offset(dx, 0));
  await tester.pumpAndSettle();
}

Future<GlobalKey<NavigatorState>> _openStory(
  WidgetTester tester, {
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: const Scaffold(key: _host, body: Text('Original screen')),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute(
      builder: (_) => const DevOnboardingDirectionsScreen(
        initialDirection: ZyraOnboardingDirection.luma,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevOnboardingTransition.resetForTesting();
  });

  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevOnboardingTransition.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  test(
    'five alternatives plus the original are distinct and session-local',
    () {
      final options = ZyraOnboardingPageTransition.values;
      expect(options, hasLength(6));
      expect(options.map((option) => option.label).toSet(), hasLength(6));
      expect(
        ZyraDevOnboardingTransition.current,
        ZyraOnboardingPageTransition.cardTilt,
      );
      expect(options.first.duration, const Duration(milliseconds: 260));
      expect(
        ZyraOnboardingPageTransition.cardTilt.duration.inMilliseconds,
        inInclusiveRange(720, 820),
      );
      expect(ZyraOnboardingPageTransition.cardTilt.curve, Curves.easeInOutSine);

      expect(ZyraDevOnboardingTransition.select(options.first), isTrue);
      expect(ZyraDevOnboardingTransition.current, options.first);
      ZyraAccountState.resetForTesting();
      expect(
        ZyraDevOnboardingTransition.current,
        ZyraOnboardingPageTransition.cardTilt,
      );

      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(ZyraDevOnboardingTransition.select(options.first), isFalse);
      expect(
        ZyraDevOnboardingTransition.current,
        ZyraOnboardingPageTransition.cardTilt,
      );
    },
  );

  testWidgets('developer toggle offers six choices and honours busy/access', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: DevOnboardingTransitionPicker()),
        ),
      ),
    );
    for (final option in ZyraOnboardingPageTransition.values) {
      expect(
        find.byKey(ValueKey('dev_onboarding_transition_${option.name}')),
        findsOneWidget,
      );
    }
    const fade = ValueKey('dev_onboarding_transition_quietFade');
    await tester.ensureVisible(find.byKey(fade));
    await tester.tap(find.byKey(fade));
    await tester.pump();
    expect(
      ZyraDevOnboardingTransition.current,
      ZyraOnboardingPageTransition.quietFade,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DevOnboardingTransitionPicker(enabled: false),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('dev_onboarding_transition_cardTilt')),
          )
          .onTap,
      isNull,
    );
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump();
    expect(find.byType(DevOnboardingTransitionPicker), findsOneWidget);
    expect(find.byKey(fade), findsNothing);
    expect(
      ZyraDevOnboardingTransition.current,
      ZyraOnboardingPageTransition.quietFade,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the five in-between frames have different motion signatures', (
    tester,
  ) async {
    final signatures = <String>{};
    for (final option in ZyraOnboardingPageTransition.values.skip(1)) {
      final controller = PageController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: PageView(
                controller: controller,
                scrollDirection: Axis.vertical,
                allowImplicitScrolling: true,
                children: [
                  for (var index = 0; index < 2; index++)
                    ZyraOnboardingTransitionFrame(
                      key: ValueKey('motion-frame-$index'),
                      controller: controller,
                      pageIndex: index,
                      axis: Axis.vertical,
                      transition: option,
                      child: ColoredBox(
                        color: index == 0 ? Colors.amber : Colors.purple,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      controller.jumpTo(controller.position.viewportDimension / 2);
      await tester.pump();
      expect(controller.page, closeTo(.5, .01));

      final frame = find.byKey(const ValueKey('motion-frame-0'));
      final transforms = find.descendant(
        of: frame,
        matching: find.byType(Transform),
      );
      expect(transforms.evaluate().length, greaterThanOrEqualTo(2));
      final translation = tester.widget<Transform>(transforms.first).transform;
      final effect = tester.widget<Transform>(transforms.last).transform;
      final opacity = tester.widget<Opacity>(
        find.descendant(of: frame, matching: find.byType(Opacity)).first,
      );
      final incomingOpacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byKey(const ValueKey('motion-frame-1')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      // Spatial glide separates content. Fade, lift and zoom pass through
      // the plain canvas; Card Tilt keeps its content visible as it tilts.
      if (option == ZyraOnboardingPageTransition.cardTilt) {
        // Both stories remain perceptible against the stationary backdrop at
        // the moment of greatest perspective.
        expect(opacity.opacity, greaterThan(.05));
        expect(incomingOpacity.opacity, greaterThan(.05));
      } else {
        final midpointOpacity = option == ZyraOnboardingPageTransition.sideGlide
            ? 1.0
            : 0.0;
        expect(opacity.opacity, closeTo(midpointOpacity, .01));
        expect(incomingOpacity.opacity, closeTo(midpointOpacity, .01));
      }
      signatures.add(
        '${translation[12].toStringAsFixed(2)}:'
        '${translation[13].toStringAsFixed(2)}:'
        '${effect[0].toStringAsFixed(3)}:'
        '${effect[8].toStringAsFixed(3)}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
    expect(signatures, hasLength(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Card Tilt moves only content in both swipe directions', (
    tester,
  ) async {
    for (final axis in Axis.values) {
      final controller = PageController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: PageView(
                controller: controller,
                scrollDirection: axis,
                children: [
                  for (var index = 0; index < 2; index++)
                    ZyraOnboardingTransitionFrame(
                      key: ValueKey('tilt-frame-$index'),
                      controller: controller,
                      pageIndex: index,
                      axis: axis,
                      transition: ZyraOnboardingPageTransition.cardTilt,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(index == 0 ? Icons.lock : Icons.stars),
                            Text('Story $index'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      final textBefore = tester.getRect(find.text('Story 0'));
      final iconBefore = tester.getRect(find.byIcon(Icons.lock));
      controller.jumpTo(controller.position.viewportDimension / 2);
      await tester.pump();
      expect(controller.page, closeTo(.5, .01));
      final textDuring = tester.getRect(find.text('Story 0'));
      final iconDuring = tester.getRect(find.byIcon(Icons.lock));
      if (axis == Axis.vertical) {
        expect(
          (textDuring.center.dy - textBefore.center.dy).abs(),
          greaterThan(10),
        );
        expect(
          (iconDuring.center.dy - iconBefore.center.dy).abs(),
          greaterThan(10),
        );
      } else {
        expect(
          (textDuring.center.dx - textBefore.center.dx).abs(),
          greaterThan(10),
        );
        expect(
          (iconDuring.center.dx - iconBefore.center.dx).abs(),
          greaterThan(10),
        );
        expect(
          (textDuring.center.dy - textBefore.center.dy).abs(),
          greaterThan(3),
          reason: 'Card Tilt should lift the full page content as it turns',
        );
        expect(
          (iconDuring.center.dy - iconBefore.center.dy).abs(),
          greaterThan(3),
        );
      }

      double tiltedComponent(int page) {
        final frame = find.byKey(ValueKey('tilt-frame-$page'));
        final matrices = tester
            .widgetList<Transform>(
              find.descendant(of: frame, matching: find.byType(Transform)),
            )
            .map((widget) => widget.transform)
            .toList();
        final axisComponent = axis == Axis.vertical ? 6 : 2;
        final dimensional = matrices.where(
          (matrix) =>
              matrix[11].abs() > .0001 && matrix[axisComponent].abs() > .02,
        );
        expect(
          dimensional,
          isNotEmpty,
          reason: 'Card Tilt needs perspective and rotation on $axis',
        );
        final opacity = tester.widget<Opacity>(
          find.descendant(of: frame, matching: find.byType(Opacity)).first,
        );
        expect(opacity.opacity, greaterThan(.05));
        return dimensional.first[axisComponent];
      }

      final outgoing = tiltedComponent(0);
      final incoming = tiltedComponent(1);
      expect(
        outgoing * incoming,
        lessThan(0),
        reason: 'Outgoing and incoming cards should tilt in opposite ways',
      );
      // The pager's travel is cancelled for the effect, then the two story
      // contents are staged separately. No painted card surface may travel
      // with them over the shared purple canvas.
      expect(
        find.byKey(const ValueKey('onboarding-card-tilt-surface-0')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('onboarding-card-tilt-surface-1')),
        findsNothing,
      );
      for (var page = 0; page < 2; page++) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('tilt-frame-$page')),
            matching: find.byType(DecoratedBox),
          ),
          findsNothing,
          reason: 'Card Tilt must not paint a travelling card background',
        );
      }
      final viewportRect = tester.getRect(find.byType(PageView));
      final outgoingRect = tester.getRect(
        find.byKey(const ValueKey('onboarding-card-tilt-content-0')),
      );
      final incomingRect = tester.getRect(
        find.byKey(const ValueKey('onboarding-card-tilt-content-1')),
      );
      if (axis == Axis.vertical) {
        expect(outgoingRect.center.dy, lessThan(viewportRect.center.dy));
        expect(incomingRect.center.dy, greaterThan(viewportRect.center.dy));
        expect(outgoingRect.bottom, lessThan(incomingRect.top));
        expect(outgoingRect.height, lessThan(viewportRect.height * .65));
        expect(incomingRect.height, lessThan(viewportRect.height * .65));
      } else {
        expect(outgoingRect.center.dx, lessThan(viewportRect.center.dx));
        expect(incomingRect.center.dx, greaterThan(viewportRect.center.dx));
        expect(outgoingRect.right, lessThan(incomingRect.left));
        expect(outgoingRect.width, lessThan(viewportRect.width * .65));
        expect(incomingRect.width, lessThan(viewportRect.width * .65));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Card Tilt keeps the full-screen purple canvas still', (
    tester,
  ) async {
    await _openStory(tester);
    const canvasKey = ValueKey('dev_onboarding_static_canvas');
    final canvas = find.byKey(canvasKey);
    expect(canvas, findsOneWidget);
    final before = tester.getRect(canvas);
    expect(before, const Rect.fromLTWH(0, 0, 430, 932));

    await _revealCard(tester, 0);
    await tester.drag(_story(0), const Offset(500, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 380));
    expect(
      tester.widget<PageView>(find.byKey(_pages)).controller!.page,
      inExclusiveRange(.05, .95),
    );
    expect(tester.getRect(canvas), before);
    expect(
      find.byKey(const ValueKey('onboarding-card-tilt-surface-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('onboarding-card-tilt-surface-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('onboarding-card-tilt-content-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-card-tilt-content-1')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(canvas), before);
    expect(_story(1).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone study locks all input until the pager settles', (
    tester,
  ) async {
    ZyraDevOnboardingInteraction.select(
      ZyraOnboardingAdvanceMode.continueButton,
    );
    final navigator = await _openStory(tester);
    await _revealCard(tester, 0);
    final advance = tester.widget<FilledButton>(find.byKey(_arrow)).onPressed!;
    final skip = tester
        .widget<TextButton>(find.byKey(const ValueKey('dev_onboarding_skip')))
        .onPressed!;
    final tap = tester
        .widget<GestureDetector>(
          find
              .ancestor(
                of: find.byKey(_pages),
                matching: find.byType(GestureDetector),
              )
              .first,
        )
        .onTap!;
    advance();
    advance();
    skip();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final controller = tester.widget<PageView>(find.byKey(_pages)).controller!;
    expect(controller.page, inExclusiveRange(.5, 1));
    expect(find.text('2 / 4'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('dev_onboarding_back')))
          .onPressed,
      isNull,
    );
    expect(tester.widget<FilledButton>(find.byKey(_arrow)).onPressed, isNull);
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('dev_onboarding_skip')))
          .onPressed,
      isNull,
    );
    advance();
    skip();
    tap();
    await tester.pumpAndSettle();
    expect(controller.page, 1);
    final incomingStudy = tester.widget<ZyraOnboardingStudy>(
      find.byWidgetPredicate(
        (widget) => widget is ZyraOnboardingStudy && widget.page == 1,
      ),
    );
    expect(incomingStudy.revealStep, 1);
    expect(
      tester.widget<FilledButton>(find.byKey(_arrow)).onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('dev_onboarding_back')))
          .onPressed,
      isNotNull,
    );
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_host), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'standalone final arrow cannot pop before page travel completes',
    (tester) async {
      final navigator = await _openStory(tester);
      for (var page = 0; page < 3; page++) {
        await _revealCard(tester, page);
        await _swipeCard(tester, page, 500);
      }
      await _revealCard(tester, 3);
      final staleFinish = tester
          .widget<ZyraOnboardingArrowAction>(find.byKey(_arrow))
          .onPressed!;
      final staleSkip = tester
          .widget<TextButton>(find.byKey(const ValueKey('dev_onboarding_skip')))
          .onPressed!;
      await _swipeCard(tester, 3, -500);
      await tester.drag(_story(2), const Offset(500, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      final controller = tester
          .widget<PageView>(find.byKey(_pages))
          .controller!;
      expect(controller.page, inExclusiveRange(2.5, 3));
      final finalArrow = tester.widget<ZyraOnboardingArrowAction>(
        find.byKey(_arrow),
      );
      expect(finalArrow.active, isFalse);
      expect(finalArrow.onPressed, isNull);
      staleFinish();
      staleSkip();
      await tester.pumpAndSettle();
      expect(controller.page, 3);
      expect(navigator.currentState!.canPop(), isTrue);
      final finish = tester
          .widget<ZyraOnboardingArrowAction>(find.byKey(_arrow))
          .onPressed!;
      finish();
      finish();
      await tester.pumpAndSettle();
      expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
      expect(find.byKey(_host), findsOneWidget);
      expect(navigator.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('continuous opening keeps its brand canvas stationary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      const MaterialApp(
        home: DevOnboardingIntroduction(
          direction: ZyraOnboardingDirection.luma,
          onContinue: _noOp,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final canvas = find.byKey(const ValueKey('dev_onboarding_static_canvas'));
    expect(canvas, findsOneWidget);
    final before = tester.getRect(canvas);
    expect(before, const Rect.fromLTWH(0, 0, 430, 932));
    double? trustPageTravel;
    for (final checkpoint in ['welcome', 'verification']) {
      if (checkpoint == 'welcome') {
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.byKey(ValueKey('dev_onboarding_${checkpoint}_continue')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getRect(canvas), before);
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('dev_opening_foreground_opacity')),
            )
            .opacity,
        inExclusiveRange(0, 1),
      );
      final sectionTravel = tester
          .widget<Transform>(
            find.byKey(const ValueKey('dev_onboarding_downward_exit')),
          )
          .transform
          .getTranslation()
          .y;
      expect(sectionTravel, lessThan(0));
      if (checkpoint == 'verification') {
        trustPageTravel = sectionTravel;
        expect(sectionTravel.abs(), lessThan(36));
      }
      await tester.pumpAndSettle();
      if (checkpoint == 'welcome') {
        expect(
          find.byKey(const ValueKey('dev_onboarding_welcome_prelude')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('dev_onboarding_verification_intro')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dev_onboarding_story_dot_0')),
          findsOneWidget,
        );
        expect(find.text('1 / 4'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dev_onboarding_verification_continue')),
          findsOneWidget,
        );
      }
      expect(tester.getRect(canvas), before);
    }
    expect(
      find.byKey(const ValueKey('dev_opening_page_1')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('dev_opening_page_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getRect(canvas), before);
    final photoPageTravel = tester
        .widget<Transform>(
          find.byKey(const ValueKey('dev_onboarding_downward_exit')),
        )
        .transform
        .getTranslation()
        .y;
    expect(photoPageTravel, closeTo(trustPageTravel!, .001));
    expect(
      find.byKey(const ValueKey('onboarding-card-tilt-content-0')),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_opening_page_2')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.getRect(canvas), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reverse horizontal Side Glide separates cards correctly', (
    tester,
  ) async {
    final controller = PageController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: PageView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              reverse: true,
              children: [
                for (var page = 0; page < 2; page++)
                  ZyraOnboardingTransitionFrame(
                    controller: controller,
                    pageIndex: page,
                    axis: Axis.horizontal,
                    reverse: true,
                    transition: ZyraOnboardingPageTransition.sideGlide,
                    child: ColoredBox(
                      key: ValueKey('reverse-side-$page'),
                      color: page == 0 ? Colors.amber : Colors.purple,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.jumpTo(controller.position.viewportDimension / 2);
    await tester.pump();
    final viewport = tester.getRect(find.byType(PageView));
    final outgoing = tester.getRect(
      find.byKey(const ValueKey('reverse-side-0')),
    );
    final incoming = tester.getRect(
      find.byKey(const ValueKey('reverse-side-1')),
    );
    expect(outgoing.center.dx, greaterThan(viewport.center.dx));
    expect(incoming.center.dx, lessThan(viewport.center.dx));
    expect(outgoing.left, greaterThanOrEqualTo(incoming.right));
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('default Card Tilt swipe has a deliberate paced transition', (
    tester,
  ) async {
    expect(
      ZyraDevOnboardingTransition.current,
      ZyraOnboardingPageTransition.cardTilt,
    );
    await _openStory(tester);
    final pageView = tester.widget<PageView>(find.byKey(_pages));
    final controller = pageView.controller;
    expect(controller, isNotNull);

    await _revealCard(tester, 0);
    await tester.drag(_story(0), const Offset(500, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 380));
    expect(controller!.page, greaterThan(.05));
    expect(
      controller.page,
      lessThan(.99),
      reason: 'The redesigned tilt should not finish in the old 380 ms',
    );
    await tester.pumpAndSettle();
    expect(_story(1).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final option in ZyraOnboardingPageTransition.values.skip(1)) {
    testWidgets('${option.label} works with right and left card swipes', (
      tester,
    ) async {
      expect(ZyraDevOnboardingTransition.select(option), isTrue);
      final navigator = await _openStory(tester);
      expect(
        tester.widget<PageView>(find.byKey(_pages)).scrollDirection,
        Axis.horizontal,
      );
      expect(tester.widget<PageView>(find.byKey(_pages)).reverse, isTrue);
      expect(
        tester
            .widget<ZyraOnboardingTransitionFrame>(
              find.byType(ZyraOnboardingTransitionFrame).first,
            )
            .transition,
        option,
      );
      expect(_story(0).hitTestable(), findsOneWidget);

      expect(find.byKey(_arrow), findsNothing);
      await _revealCard(tester, 0);
      await _swipeCard(tester, 0, 500);
      expect(_story(1).hitTestable(), findsOneWidget);
      await _swipeCard(tester, 1, -500);
      expect(_story(0).hitTestable(), findsOneWidget);
      await _swipeCard(tester, 0, 500);
      expect(_story(1).hitTestable(), findsOneWidget);
      await _revealCard(tester, 1);
      await _swipeCard(tester, 1, 500);
      expect(_story(2).hitTestable(), findsOneWidget);
      await _revealCard(tester, 2);
      await _swipeCard(tester, 2, 500);
      expect(_story(3).hitTestable(), findsOneWidget);
      await _swipeCard(tester, 3, -500);
      expect(_story(2).hitTestable(), findsOneWidget);
      await _swipeCard(tester, 2, 500);
      expect(_story(3).hitTestable(), findsOneWidget);
      await _revealCard(tester, 3);
      expect(find.byKey(_arrow), findsOneWidget);
      await tester.tap(find.byKey(_arrow));
      await tester.pumpAndSettle();
      expect(navigator.currentState!.canPop(), isFalse);
      expect(find.byKey(_host), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changing motion while on page two keeps the current place', (
    tester,
  ) async {
    await _openStory(tester);
    await _revealCard(tester, 0);
    await _swipeCard(tester, 0, 500);
    expect(_story(1).hitTestable(), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);

    expect(
      ZyraDevOnboardingTransition.select(
        ZyraOnboardingPageTransition.focusZoom,
      ),
      isTrue,
    );
    await tester.pump();
    expect(find.text('2 / 4'), findsOneWidget);
    expect(_story(1).hitTestable(), findsOneWidget);
    expect(
      tester
          .widget<ZyraOnboardingTransitionFrame>(
            find.byType(ZyraOnboardingTransitionFrame).first,
          )
          .transition,
      ZyraOnboardingPageTransition.focusZoom,
    );
    await _revealCard(tester, 1);
    await _swipeCard(tester, 1, 500);
    expect(_story(2).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal pager also uses the selected transition on swipes', (
    tester,
  ) async {
    expect(
      ZyraDevOnboardingInteraction.select(
        ZyraOnboardingAdvanceMode.continueButton,
      ),
      isTrue,
    );
    expect(
      ZyraDevOnboardingTransition.select(
        ZyraOnboardingPageTransition.sideGlide,
      ),
      isTrue,
    );
    await _openStory(tester);
    expect(
      tester.widget<PageView>(find.byKey(_pages)).scrollDirection,
      Axis.horizontal,
    );
    await _revealCard(tester, 0);
    await _swipeCard(tester, 0, 500);
    expect(_story(1).hitTestable(), findsOneWidget);
    await _swipeCard(tester, 1, -500);
    expect(_story(0).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion keeps revealed swipe navigation immediate', (
    tester,
  ) async {
    expect(
      ZyraDevOnboardingTransition.select(ZyraOnboardingPageTransition.cardTilt),
      isTrue,
    );
    await _openStory(tester, reducedMotion: true);
    expect(
      find.byKey(const ValueKey('onboarding-card-tilt-content-0')),
      findsNothing,
      reason: 'Reduce Motion bypasses the Card Tilt content transform',
    );
    // Staged lines may use 0/1 opacity for visibility, but no in-between
    // animation frame is presented when Reduce Motion is enabled.
    final visibleStates = tester.widgetList<Opacity>(
      find.descendant(
        of: find.byType(ZyraOnboardingTransitionFrame).first,
        matching: find.byType(Opacity),
      ),
    );
    expect(
      visibleStates.every(
        (opacity) => opacity.opacity == 0 || opacity.opacity == 1,
      ),
      isTrue,
    );
    await _revealCard(tester, 0);
    await tester.drag(_story(0), const Offset(500, 0));
    await tester.pump();
    expect(_story(1).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
