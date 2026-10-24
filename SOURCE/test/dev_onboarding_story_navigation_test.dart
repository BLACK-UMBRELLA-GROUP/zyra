import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_welcome_motion.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';

const _welcome = ValueKey('dev_onboarding_welcome_prelude');
const _welcomeArrow = ValueKey('dev_onboarding_welcome_continue');
const _guardianArrow = ValueKey('dev_onboarding_story_continue');
Finder _page(int index) => index == 0
    ? find.byKey(_welcome)
    : find.byKey(ValueKey('dev_opening_page_$index'));

Future<void> _mount(
  WidgetTester tester, {
  VoidCallback? onContinue,
  VoidCallback? onBack,
  bool reducedMotion = false,
  bool accessibleNavigation = false,
  bool compact = false,
  String welcomeName = 'Amina Zahra',
}) async {
  tester.view.physicalSize = compact
      ? const Size(320, 568)
      : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reducedMotion,
          accessibleNavigation: accessibleNavigation,
          textScaler: TextScaler.linear(compact ? 1.4 : 1),
        ),
        child: child!,
      ),
      home: DevOnboardingIntroduction(
        direction: ZyraOnboardingDirection.luma,
        welcomeName: welcomeName,
        onContinue: onContinue ?? () {},
        onBackToProvider: onBack,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _finishWelcome(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
  final arrow = find.byKey(_welcomeArrow);
  await tester.ensureVisible(arrow);
  await tester.tap(arrow);
  await tester.pumpAndSettle();
  expect(
    find.byKey(const ValueKey('dev_onboarding_verification_intro')),
    findsOneWidget,
  );
  expect(find.text('1 / 4'), findsOneWidget);
  await tester.tap(
    find.byKey(const ValueKey('dev_onboarding_verification_continue')),
  );
  await tester.pumpAndSettle();
}

Future<void> _advance(WidgetTester tester, int page) async {
  await tester.tap(_page(page));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevWelcomeTextMotion.resetForTesting();
  });

  tearDown(() {
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevWelcomeTextMotion.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('welcome leads to verification and three purposeful themes', (
    tester,
  ) async {
    var completed = 0;
    await _mount(tester, onContinue: () => completed++);
    await tester.pumpAndSettle();
    expect(find.textContaining('Amina'), findsOneWidget);
    expect(find.textContaining('Zahra'), findsNothing);
    expect(find.textContaining('praise Allah'), findsOneWidget);
    expect(find.textContaining('May Allah'), findsOneWidget);
    expect(find.byType(ZyraWelcomeLine), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('dev_onboarding_page_count')))
          .data,
      isEmpty,
    );
    await _finishWelcome(tester);
    expect(_page(1), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);
    await _advance(tester, 1);
    expect(_page(2), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);
    await _advance(tester, 2);
    expect(_page(3), findsOneWidget);
    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.textContaining('Let’s begin'), findsNothing);
    expect(completed, 0);
    await tester.tap(find.byKey(_guardianArrow));
    await tester.pumpAndSettle();
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome stays complete and does not advance from a body tap', (
    tester,
  ) async {
    await _mount(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_welcome));
    await tester.pumpAndSettle();
    expect(_page(0), findsOneWidget);
    expect(_page(1), findsNothing);
    expect(find.textContaining('praise Allah'), findsOneWidget);
    expect(find.textContaining('May Allah'), findsOneWidget);
  });

  testWidgets(
    'welcome enters together and arrow waits three seconds after entry',
    (tester) async {
      await _mount(tester);
      final foreground = find.byKey(
        const ValueKey('dev_opening_foreground_opacity'),
      );
      double opacity() => tester.widget<Opacity>(foreground).opacity;
      expect(opacity(), 0);
      expect(find.byKey(_welcomeArrow), findsNothing);
      final entryMilliseconds =
          (ZyraDevWelcomeTextMotion.defaultMotion.milliseconds * .65).round();
      await tester.pump(Duration(milliseconds: entryMilliseconds ~/ 2));
      expect(opacity(), inExclusiveRange(0, 1));
      expect(find.byKey(_welcomeArrow), findsNothing);
      await tester.pump(
        Duration(milliseconds: entryMilliseconds - entryMilliseconds ~/ 2),
      );
      expect(opacity(), 1);
      // Cross the ticker's duration boundary, then build the completed state.
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('dev_onboarding_skip')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pump(const Duration(milliseconds: 2999));
      expect(find.byKey(_welcomeArrow), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byKey(_welcomeArrow), findsOneWidget);
      expect(
        tester
            .widget<ZyraOnboardingArrowAction>(find.byKey(_welcomeArrow))
            .repeatCue,
        isTrue,
      );
      expect(_page(0), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an empty welcome name never fabricates a member name', (
    tester,
  ) async {
    await _mount(tester, reducedMotion: true, welcomeName: '   ');
    expect(find.text('Welcome to ZYRA.'), findsOneWidget);
    expect(find.textContaining('Shakeel'), findsNothing);
    expect(find.textContaining('Amina'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme back retraces trust, welcome then provider', (
    tester,
  ) async {
    var backs = 0;
    var completed = 0;
    await _mount(
      tester,
      reducedMotion: true,
      onBack: () => backs++,
      onContinue: () => completed++,
    );
    await _finishWelcome(tester);
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_story_back')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('dev_onboarding_verification_intro')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_verification_back')),
    );
    await tester.pump();
    expect(_page(0), findsOneWidget);
    expect(backs, 0);
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_welcome_back')));
    await tester.pump();
    expect(backs, 1);
    expect(completed, 0);
  });

  testWidgets('a retained final-arrow callback cannot complete twice', (
    tester,
  ) async {
    var completed = 0;
    await _mount(tester, onContinue: () => completed++);
    await _finishWelcome(tester);
    await _advance(tester, 1);
    await _advance(tester, 2);
    final action = tester
        .widget<ZyraOnboardingArrowAction>(find.byKey(_guardianArrow))
        .onPressed!;
    action();
    action();
    action();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(completed, 1);
    action();
    await tester.pump();
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'photo explanation is complete and quote expands on that same page',
    (tester) async {
      await _mount(tester, reducedMotion: true);
      await _finishWelcome(tester);
      expect(_page(1), findsOneWidget);
      expect(
        find.text(
          'ZYRA introduces you through photos first, so you can see who you’re drawn to. When you both choose to connect, you can get to know the person beyond the first impression.',
        ),
        findsOneWidget,
      );
      final toggle = find.byKey(const ValueKey('dev_opening_quote_toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.textContaining('Imam Ahmad'), findsWidgets);
      expect(find.text('2 / 4'), findsOneWidget);
      expect(_page(1), findsOneWidget);
      expect(_page(2), findsNothing);
      expect(find.textContaining('al-Insaf'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rapid taps cannot skip a theme while its foreground settles', (
    tester,
  ) async {
    await _mount(tester);
    await _finishWelcome(tester);
    await tester.tap(_page(1));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(const Offset(195, 320));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(const Offset(195, 320));
    await tester.pumpAndSettle();
    expect(_page(2), findsOneWidget);
    expect(_page(3), findsNothing);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the full theme foreground clears before the next page appears', (
    tester,
  ) async {
    await _mount(tester);
    await _finishWelcome(tester);
    await tester.tap(_page(1));
    for (var sample = 0; sample < 16; sample++) {
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        _page(1).evaluate().length + _page(2).evaluate().length,
        lessThanOrEqualTo(1),
        reason: 'two readable content trees at sample $sample',
      );
    }
    await tester.pumpAndSettle();
    expect(_page(2), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('right and left theme swipes advance and return one page', (
    tester,
  ) async {
    await _mount(tester, reducedMotion: true);
    await _finishWelcome(tester);
    await tester.drag(_page(1), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    await tester.drag(_page(2), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('four section dots show verification and completed progress', (
    tester,
  ) async {
    await _mount(tester, reducedMotion: true);
    await _finishWelcome(tester);
    for (var page = 0; page < 4; page++) {
      expect(
        find.byKey(ValueKey('dev_onboarding_story_dot_$page')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('dev_onboarding_story_dot_4')),
      findsNothing,
    );
    await _advance(tester, 1);
    expect(find.text('3 / 4'), findsOneWidget);
    await _advance(tester, 2);
    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.byKey(_guardianArrow), findsOneWidget);
    expect(find.byType(ZyraWelcomePulseMark), findsNothing);
  });

  testWidgets('back returns to the provider without skipping account setup', (
    tester,
  ) async {
    var backs = 0;
    var completed = 0;
    await _mount(
      tester,
      reducedMotion: true,
      onBack: () => backs++,
      onContinue: () => completed++,
    );
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_welcome_back')));
    await tester.pump();
    expect(backs, 1);
    expect(completed, 0);
  });

  for (final accessible in [false, true]) {
    testWidgets(
      '${accessible ? 'screen reader' : 'reduced motion'} gets complete content with no typing',
      (tester) async {
        ZyraDevWelcomeTextMotion.select(
          ZyraWelcomeTextMotion.measuredTypewriter,
        );
        await _mount(
          tester,
          reducedMotion: !accessible,
          accessibleNavigation: accessible,
        );
        expect(find.textContaining('Amina'), findsOneWidget);
        expect(find.textContaining('praise Allah'), findsOneWidget);
        expect(find.textContaining('May Allah'), findsOneWidget);
        expect(find.byType(ZyraWelcomeLine), findsNothing);
        expect(find.byKey(_welcomeArrow), findsOneWidget);
        await _finishWelcome(tester);
        expect(_page(1), findsOneWidget);
        await _advance(tester, 1);
        expect(_page(2), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'revocation during transition blanks the protected reader and blocks callbacks',
    (tester) async {
      var completed = 0;
      await _mount(tester, onContinue: () => completed++);
      await _finishWelcome(tester);
      await tester.tap(_page(1));
      await tester.pump(const Duration(milliseconds: 100));
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      expect(find.byKey(_welcome), findsNothing);
      expect(
        find.byKey(const ValueKey('dev_onboarding_page_count')),
        findsNothing,
      );
      expect(_page(1), findsNothing);
      expect(_page(2), findsNothing);
      expect(completed, 0);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpAndSettle();
      expect(find.byKey(_welcome), findsNothing);
      expect(_page(1), findsNothing);
      expect(_page(2), findsNothing);
      expect(completed, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact large-text pages keep readable overflow and reachable arrows',
    (tester) async {
      await _mount(tester, reducedMotion: true, compact: true);
      final welcomeArrow = find.byKey(_welcomeArrow);
      await tester.ensureVisible(welcomeArrow);
      expect(welcomeArrow.hitTestable(), findsOneWidget);
      await tester.tap(welcomeArrow);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_verification_continue')),
      );
      await tester.pump();
      expect(_page(1), findsOneWidget);
      await _advance(tester, 1);
      await _advance(tester, 2);
      final guardianArrow = find.byKey(_guardianArrow);
      await tester.ensureVisible(guardianArrow);
      expect(guardianArrow.hitTestable(), findsOneWidget);
      expect(tester.getRect(guardianArrow).bottom, lessThanOrEqualTo(568));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('no gesture instruction is added to the opening', (tester) async {
    await _mount(tester, reducedMotion: true);
    for (var page = 0; page < 4; page++) {
      expect(find.text('Tap screen to continue'), findsNothing);
      expect(find.text('Tap the page to continue reading'), findsNothing);
      expect(find.text('Swipe right for the next page'), findsNothing);
      if (page == 0) {
        await _finishWelcome(tester);
      } else if (page < 3) {
        await _advance(tester, page);
      }
    }
  });
}
