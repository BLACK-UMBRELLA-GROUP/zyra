import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';

const _arrow = ValueKey('dev_onboarding_continue');
const _skip = ValueKey('dev_onboarding_skip');
const _hint = ValueKey('dev_onboarding_reading_hint');

Finder _story(int page) => find.byKey(
  ValueKey(
    'onboarding-study-scroll-${ZyraOnboardingDirection.atoms.name}-$page',
  ),
);

Future<void> _open(
  WidgetTester tester, {
  ZyraOnboardingDirection direction = ZyraOnboardingDirection.atoms,
  bool reducedMotion = false,
  bool accessibleNavigation = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reducedMotion,
          accessibleNavigation: accessibleNavigation,
        ),
        child: child!,
      ),
      home: DevOnboardingDirectionsScreen(
        key: ValueKey('story-${direction.name}'),
        initialDirection: direction,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapStory(WidgetTester tester, int page) async {
  await tester.tap(_story(page));
  await tester.pumpAndSettle();
}

Future<void> _swipe(WidgetTester tester, int page, double dx) async {
  await tester.drag(_story(page), Offset(dx, 0));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
  });

  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('every story direction opens each card with art and heading', (
    tester,
  ) async {
    for (final direction in ZyraOnboardingDirection.values.where(
      (value) => value != ZyraOnboardingDirection.current,
    )) {
      await _open(tester, direction: direction);
      for (
        var page = 0;
        page < ZyraOnboardingDirection.storyPageCount;
        page++
      ) {
        final art = find.byKey(
          ValueKey('onboarding-study-art-${direction.name}-$page'),
        );
        final heading = find.byKey(
          ValueKey('onboarding-study-heading-${direction.name}-$page'),
        );
        expect(art, findsOneWidget);
        expect(heading, findsOneWidget);
        expect(
          tester
              .widget<Opacity>(
                find.ancestor(of: art, matching: find.byType(Opacity)).first,
              )
              .opacity,
          1,
          reason: '${direction.name} card $page artwork',
        );
        expect(
          tester
              .widget<Opacity>(
                find
                    .ancestor(of: heading, matching: find.byType(Opacity))
                    .first,
              )
              .opacity,
          1,
          reason: '${direction.name} card $page heading',
        );
        if (page < ZyraOnboardingDirection.storyPageCount - 1) {
          await tester.tap(find.byKey(_skip));
          await tester.pumpAndSettle();
        }
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap and right swipe reveal lines; left returns', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.byKey(_arrow), findsNothing);
    expect(find.byKey(_hint), findsNothing);
    expect(find.text('Tap the page to continue reading'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('It is reported from')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Reported excerpt from Imam Ahmad')),
      findsNothing,
    );
    await _swipe(tester, 0, 310);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Reported excerpt from Imam Ahmad')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('A principle that helped shape ZYRA')),
      findsOneWidget,
    );
    expect(find.byKey(_hint), findsNothing);
    await _tapStory(tester, 0);
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.byKey(_hint), findsNothing);
    expect(find.text('Swipe right for the next page'), findsNothing);
    expect(find.byKey(_hint), findsNothing);
    expect(find.text('Tap the page to continue reading'), findsNothing);
    expect(find.byKey(_arrow), findsNothing);

    // Returning is always available; no need to finish reading page two.
    await _swipe(tester, 1, -310);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.byKey(_hint), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('explanations and closing lines appear together on every card', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    expect(find.text('TRANSLATED EXCERPT'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('A principle that helped shape ZYRA')),
      findsNothing,
    );
    await _tapStory(tester, 0);
    expect(
      find.bySemanticsLabel(RegExp('Reported excerpt from Imam Ahmad')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('A principle that helped shape ZYRA')),
      findsOneWidget,
    );

    for (final (page, body, note) in const [
      (
        1,
        'ZYRA introduces you through photos first',
        'Built for Muslims serious about marriage',
      ),
      (2, 'ZYRA shows where your values', 'You see the compatibility result'),
      (3, 'You can invite more than one Guardian', 'Support beside you'),
    ]) {
      await _tapStory(tester, page - 1);
      expect(find.text('${page + 1} / 4'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(body)), findsNothing);
      expect(find.bySemanticsLabel(RegExp(note)), findsNothing);
      await _tapStory(tester, page);
      expect(find.bySemanticsLabel(RegExp(body)), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(note)), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('phone-size finger swipes read the first card and advance', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester);

    final artwork = find.byKey(const ValueKey('onboarding-study-art-atoms-0'));
    expect(artwork.hitTestable(), findsOneWidget);
    expect(find.byKey(_hint), findsNothing);
    expect(find.text('Tap the page to continue reading'), findsNothing);
    expect(find.text('Swipe right for the next page'), findsNothing);

    // The real interaction starts on visible content; it must not require
    // tapping a page dot, a footer control, or each text string first.
    Future<void> swipeVisibleArtwork() async {
      await tester.flingFrom(
        tester.getCenter(artwork),
        const Offset(82, 6),
        500,
      );
      await tester.pumpAndSettle();
    }

    await swipeVisibleArtwork();
    expect(find.text('1 / 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Reported excerpt from Imam Ahmad')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('A principle that helped shape ZYRA')),
      findsOneWidget,
    );

    await swipeVisibleArtwork();
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.byKey(_hint), findsNothing);
    expect(find.text('Swipe right for the next page'), findsNothing);
    expect(find.byKey(_arrow), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'phone-size taps across the card reveal then advance without dots',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _open(tester);

      for (var page = 0; page < 3; page++) {
        final story = _story(page);
        final artwork = find.byKey(
          ValueKey('onboarding-study-art-atoms-$page'),
        );
        expect(story.hitTestable(), findsOneWidget);
        expect(artwork.hitTestable(), findsOneWidget);
        expect(find.text('${page + 1} / 4'), findsOneWidget);
        expect(find.byKey(_arrow), findsNothing);

        // First tap can be anywhere on the screen, including the wordmark.
        if (page == 0) {
          await tester.tap(find.text('ZYRA'));
        } else {
          await tester.tapAt(tester.getCenter(artwork));
        }
        await tester.pumpAndSettle();
        expect(find.text('${page + 1} / 4'), findsOneWidget);

        // A blank edge of the card must work, not just visible copy or dots.
        final bounds = tester.getRect(story);
        await tester.tapAt(Offset(bounds.left + 8, bounds.top + 8));
        await tester.pumpAndSettle();
        // The second tap leaves this card exactly once; no gold dot is used.
        expect(find.text('${page + 2} / 4'), findsOneWidget);
        expect(find.text('${page + 3} / 4'), findsNothing);
        expect(find.byKey(_arrow), findsNothing);
      }

      expect(find.text('4 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('a short fast right flick responds on phone-size content', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester);

    final artwork = find.byKey(const ValueKey('onboarding-study-art-atoms-0'));
    expect(artwork.hitTestable(), findsOneWidget);
    await tester.flingFrom(
      tester.getCenter(artwork),
      const Offset(30, 2),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('It is reported from')),
      findsOneWidget,
    );
    expect(find.byKey(_hint), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('empty footer tap does not jump to another card', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester);

    final dots = tester.getRect(
      find.byKey(const ValueKey('dev_onboarding_page_dots')),
    );
    await tester.tapAt(Offset(dots.left - 18, dots.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('1 / 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('It is reported from')),
      findsOneWidget,
    );
    expect(find.text('2 / 4'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('comparison cards advance sequentially; Skip is explicit', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    expect(find.byKey(const ValueKey('dev_onboarding_dot_3')), findsNothing);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('It is reported from')),
      findsOneWidget,
    );
    await _tapStory(tester, 0);
    expect(
      find.bySemanticsLabel(RegExp('Reported excerpt from Imam Ahmad')),
      findsOneWidget,
    );

    await _tapStory(tester, 0);
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('3 / 4'), findsNothing);

    await tester.tap(find.byKey(_skip));
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.byKey(_arrow), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('only fully revealed fourth card offers the down arrow', (
    tester,
  ) async {
    await _open(tester);
    for (var page = 0; page < 3; page++) {
      expect(find.text('${page + 1} / 4'), findsOneWidget);
      expect(find.byKey(_arrow), findsNothing);
      await tester.tap(find.byKey(_skip));
      await tester.pumpAndSettle();
    }
    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.byKey(_arrow), findsNothing);
    for (var reveal = 0; reveal < 1; reveal++) {
      await _tapStory(tester, 3);
    }
    expect(find.byKey(_arrow), findsOneWidget);
    expect(find.byKey(_hint), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all four cards omit gesture-instruction copy at every reveal', (
    tester,
  ) async {
    await _open(tester);

    void expectNoVisibleGestureInstruction() {
      expect(find.byKey(_hint), findsNothing);
      expect(find.text('Tap the page to continue reading'), findsNothing);
      expect(find.text('Swipe right for the next page'), findsNothing);
    }

    for (var page = 0; page < 4; page++) {
      expect(find.text('${page + 1} / 4'), findsOneWidget);
      expectNoVisibleGestureInstruction();

      for (var reveal = 0; reveal < 1; reveal++) {
        await _tapStory(tester, page);
        expectNoVisibleGestureInstruction();
      }

      if (page < 3) {
        expect(find.byKey(_arrow), findsNothing);
        await _tapStory(tester, page);
      } else {
        expect(find.byKey(_arrow), findsOneWidget);
        expect(find.byKey(_skip), findsOneWidget);
      }
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion keeps staged text and immediate visibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, reducedMotion: true);
    await _tapStory(tester, 0);
    expect(
      find.bySemanticsLabel(RegExp('It is reported from')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('screen-reader navigation exposes every line without taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, accessibleNavigation: true);
    expect(
      find.bySemanticsLabel(RegExp('It is reported from')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Reported excerpt from Imam Ahmad')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('A principle that helped shape ZYRA')),
      findsOneWidget,
    );
    await _swipe(tester, 0, 310);
    expect(find.text('2 / 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
