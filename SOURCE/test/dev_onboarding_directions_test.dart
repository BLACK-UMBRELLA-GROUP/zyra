import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';
import 'package:zyra/widgets/zyra_splash_artwork.dart';

const _host = ValueKey('onboarding-preview-host');
const _continue = ValueKey('dev_onboarding_continue');
const _close = ValueKey('dev_onboarding_close');

Finder _study(ZyraOnboardingDirection direction, int page) =>
    find.byKey(ValueKey('onboarding-study-scroll-${direction.name}-$page'));

Future<void> _revealCard(
  WidgetTester tester,
  ZyraOnboardingDirection direction,
  int page,
) async {
  for (var step = 0; step < 1; step++) {
    await tester.tap(_study(direction, page));
    await tester.pumpAndSettle();
  }
}

Future<void> _advanceButton(
  WidgetTester tester,
  ZyraOnboardingDirection direction,
  int page,
) async {
  await _revealCard(tester, direction, page);
  await tester.tap(find.byKey(_continue));
  await tester.pumpAndSettle();
}

Future<GlobalKey<NavigatorState>> _open(
  WidgetTester tester,
  ZyraOnboardingDirection direction, {
  bool reducedMotion = false,
}) async {
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: const Scaffold(
        key: _host,
        body: Text('Existing profile stays here'),
      ),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute(
      builder: (_) =>
          DevOnboardingDirectionsScreen(initialDirection: direction),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.restoreAppFont(null);
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDevOnboardingInteraction.resetForTesting();
    // These legacy slide-navigation assertions deliberately exercise the
    // retained Continue alternative, independent of the new preview default.
    ZyraDevOnboardingInteraction.select(
      ZyraOnboardingAdvanceMode.continueButton,
    );
  });

  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevOnboardingInteraction.resetForTesting();
  });

  test('eleven ordered onboarding studies do not replace the main splash', () {
    expect(ZyraOnboardingDirection.storyPageCount, 4);
    expect(zyraDefaultDevOnboardingDirection, ZyraOnboardingDirection.luma);
    expect(ZyraOnboardingDirection.values.map((e) => e.name), [
      'current',
      'structured',
      'luma',
      'revolut',
      'headspace',
      'mozi',
      'wise',
      'uber',
      'ahead',
      'howWeFeel',
      'atoms',
    ]);
    expect(
      ZyraOnboardingDirection.values.map((e) => e.label).toSet(),
      hasLength(11),
    );
    expect(zyraPrimarySplashDirection, ZyraSplashDirection.dawnHorizon);
    expect(ZyraColors.brandGradient.colors, const [
      Color(0xFF30203F),
      Color(0xFF160E20),
    ]);
  });

  testWidgets('standalone directions preview starts with Luma', (tester) async {
    ZyraDevOnboardingInteraction.resetForTesting();
    await tester.pumpWidget(
      const MaterialApp(home: DevOnboardingDirectionsScreen()),
    );
    expect(
      find.byKey(const ValueKey('onboarding-direction-luma')),
      findsOneWidget,
    );
    expect(
      find.text('Preview · ${ZyraOnboardingDirection.luma.label}'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ZyraOnboardingArrowScope>(
            find.byType(ZyraOnboardingArrowScope),
          )
          .enabled,
      isTrue,
    );
  });

  for (final direction in ZyraOnboardingDirection.values.skip(1)) {
    testWidgets('${direction.name} continues through four visual-only slides', (
      tester,
    ) async {
      final navigator = await _open(tester, direction);
      for (
        var page = 0;
        page < ZyraOnboardingDirection.storyPageCount;
        page++
      ) {
        expect(_study(direction, page).hitTestable(), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);
        expect(
          find.text(
            page == ZyraOnboardingDirection.storyPageCount - 1
                ? 'Finish preview'
                : 'Continue',
          ),
          findsOneWidget,
        );
        expect(find.byKey(_continue).hitTestable(), findsOneWidget);
        await _advanceButton(tester, direction, page);
      }
      expect(navigator.currentState!.canPop(), isFalse);
      expect(find.byKey(_host), findsOneWidget);
      expect(find.text('Existing profile stays here'), findsOneWidget);
      expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${direction.name} supports reversible slide swipes', (
      tester,
    ) async {
      await _open(tester, direction);
      await _revealCard(tester, direction, 0);
      await tester.drag(_study(direction, 0), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(_study(direction, 1).hitTestable(), findsOneWidget);
      await tester.drag(_study(direction, 1), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(_study(direction, 0).hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(_close));
      await tester.pumpAndSettle();
      expect(find.byKey(_host), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Atoms shows the approved four-page story and attributed quote', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, ZyraOnboardingDirection.atoms);

    // Separate design comparisons no longer show the continuous-story dots.
    expect(find.byKey(const ValueKey('dev_onboarding_dot_0')), findsNothing);

    expect(find.text('1 / 4'), findsOneWidget);
    await _revealCard(tester, ZyraOnboardingDirection.atoms, 0);
    expect(find.text('A PRINCIPLE BEHIND ZYRA'), findsOneWidget);
    expect(find.text('It is reported from\nImam Ahmad:'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-study-quote-atoms-0')),
      findsOneWidget,
    );
    expect(
      find.textContaining('When a man seeks a woman’s hand'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-study-attribution-atoms-0')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Reported from Imam Ahmad (may Allah have mercy on him) by al-Mardawi in al-Insaf, 8:19.',
      ),
      findsOneWidget,
    );
    expect(find.text('A principle that helped shape ZYRA.'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Imam Ahmad.*al-Insaf')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_continue));
    await tester.pumpAndSettle();

    expect(find.text('2 / 4'), findsOneWidget);
    await _revealCard(tester, ZyraOnboardingDirection.atoms, 1);
    expect(find.text('MARRIAGE-FIRST'), findsOneWidget);
    expect(find.text('Match on attraction.\nConnect on deen.'), findsOneWidget);
    expect(
      find.text(
        'ZYRA introduces you through photos first, so you can see who you’re drawn to. When you both choose to connect, you can get to know the person beyond the first impression.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Built for Muslims serious about marriage.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_continue));
    await tester.pumpAndSettle();

    expect(find.text('3 / 4'), findsOneWidget);
    await _revealCard(tester, ZyraOnboardingDirection.atoms, 2);
    expect(find.text('COMPATIBILITY'), findsOneWidget);
    expect(
      find.text('See where you align\nbefore moving forward.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'ZYRA shows where your values and expectations align, where they differ and what may need a conversation.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'You see the compatibility result—not each other’s private answers.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_continue));
    await tester.pumpAndSettle();

    expect(find.text('4 / 4'), findsOneWidget);
    await _revealCard(tester, ZyraOnboardingDirection.atoms, 3);
    expect(find.text('GUARDIAN SUPPORT'), findsOneWidget);
    expect(
      find.text('A Journey you share\nwith your Guardians.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'You can invite more than one Guardian to support you. Once your Journey begins, they can share each stage, offer guidance and help you decide what comes next.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Support beside you, every step of the way.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final direction in [
    ZyraOnboardingDirection.wise,
    ZyraOnboardingDirection.howWeFeel,
  ]) {
    testWidgets('${direction.name} retains every approved closing line', (
      tester,
    ) async {
      await _open(tester, direction);
      await _revealCard(tester, direction, 0);
      expect(find.text('A principle that helped shape ZYRA.'), findsOneWidget);
      await tester.tap(find.byKey(_continue));
      await tester.pumpAndSettle();
      for (final (page, closingLine) in const [
        'Built for Muslims serious about marriage.',
        'You see the compatibility result—not each other’s private answers.',
        'Support beside you, every step of the way.',
      ].indexed) {
        await _revealCard(tester, direction, page + 1);
        expect(find.text(closingLine), findsOneWidget);
        if (page < 2) {
          await tester.tap(find.byKey(_continue));
          await tester.pumpAndSettle();
        }
      }
      expect(_study(direction, 3).hitTestable(), findsOneWidget);
      expect(
        find.text('Support beside you, every step of the way.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('current onboarding closes without advancing live signup', (
    tester,
  ) async {
    final navigator = await _open(tester, ZyraOnboardingDirection.current);
    expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
    expect(
      tester
          .widget<OnboardingStageIntroScreen>(
            find.byType(OnboardingStageIntroScreen),
          )
          .allowPreviewScrolling,
      isTrue,
    );
    expect(find.text('Your next steps, Shakeel.'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    for (var item = 0; item < 4; item++) {
      await tester.tap(
        find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('onboarding_welcome_continue')));
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('onboarding_stage_continue'));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isFalse);
    expect(find.byKey(_host), findsOneWidget);
    expect(find.text("What's your first name?"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('current arrow preview can swipe through both intro pages', (
    tester,
  ) async {
    expect(
      ZyraDevOnboardingInteraction.select(
        ZyraOnboardingAdvanceMode.animatedDownArrow,
      ),
      isTrue,
    );
    addTearDown(ZyraDevOnboardingInteraction.resetForTesting);
    final navigator = await _open(tester, ZyraOnboardingDirection.current);
    final intro = tester.widget<OnboardingStageIntroScreen>(
      find.byType(OnboardingStageIntroScreen),
    );
    expect(intro.devPreview, isTrue);

    for (var item = 0; item < 4; item++) {
      await tester.tap(
        find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
      );
      await tester.pumpAndSettle();
    }

    final welcome = find.byKey(
      const ValueKey('onboarding_preview_welcome_scrollable'),
    );
    final welcomePosition = tester
        .state<ScrollableState>(
          find.descendant(of: welcome, matching: find.byType(Scrollable)),
        )
        .position;
    welcomePosition.jumpTo(welcomePosition.maxScrollExtent);
    await tester.pump();
    await tester.drag(welcome, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding_stage_continue')).hitTestable(),
      findsOneWidget,
    );

    final stage = find.byKey(const ValueKey('onboarding_stage_scrollable'));
    final stagePosition = tester
        .state<ScrollableState>(
          find.descendant(of: stage, matching: find.byType(Scrollable)),
        )
        .position;
    stagePosition.jumpTo(stagePosition.maxScrollExtent);
    await tester.pump();
    await tester.drag(stage, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isFalse);
    expect(find.byKey(_host), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'comparison pages advance sequentially and Back stays reversible',
    (tester) async {
      final navigator = await _open(tester, ZyraOnboardingDirection.howWeFeel);
      expect(find.byKey(const ValueKey('dev_onboarding_dot_3')), findsNothing);
      expect(
        _study(ZyraOnboardingDirection.howWeFeel, 0).hitTestable(),
        findsOneWidget,
      );
      await _advanceButton(tester, ZyraOnboardingDirection.howWeFeel, 0);
      await _advanceButton(tester, ZyraOnboardingDirection.howWeFeel, 1);
      await _advanceButton(tester, ZyraOnboardingDirection.howWeFeel, 2);
      expect(
        _study(ZyraOnboardingDirection.howWeFeel, 3).hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Finish preview'), findsOneWidget);
      expect(find.byKey(const ValueKey('dev_onboarding_back')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dev_onboarding_back')));
      await tester.pumpAndSettle();
      expect(
        _study(ZyraOnboardingDirection.howWeFeel, 2).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('dev_onboarding_back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dev_onboarding_back')));
      await tester.pumpAndSettle();
      expect(
        _study(ZyraOnboardingDirection.howWeFeel, 0).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('dev_onboarding_back')), findsNothing);
      expect(navigator.currentState!.canPop(), isTrue);
      await tester.tap(find.byKey(_close));
      await tester.pumpAndSettle();
      expect(find.byKey(_host), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('design navigation resets pages and cycles all eleven choices', (
    tester,
  ) async {
    var refreshes = 0;
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => null,
      refreshSession: () async {
        refreshes++;
        return null;
      },
      founderIdentityMatches: (_) => false,
    );
    final navigator = await _open(tester, ZyraOnboardingDirection.structured);
    await _advanceButton(tester, ZyraOnboardingDirection.structured, 0);
    expect(
      _study(ZyraOnboardingDirection.structured, 1).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_previous_direction')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_previous_direction')),
    );
    await tester.pumpAndSettle();
    expect(
      _study(ZyraOnboardingDirection.atoms, 0).hitTestable(),
      findsOneWidget,
    );
    for (final direction in ZyraOnboardingDirection.values) {
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_next_direction')),
      );
      await tester.pumpAndSettle();
      if (direction == ZyraOnboardingDirection.current) {
        expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
      } else {
        expect(_study(direction, 0).hitTestable(), findsOneWidget);
      }
      expect(find.text('Preview · ${direction.label}'), findsOneWidget);
      expect(navigator.currentState!.canPop(), isTrue);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(_close));
    await tester.pumpAndSettle();
    expect(find.byKey(_host), findsOneWidget);
    expect(refreshes, 0);
  });

  testWidgets('unauthorized direct route exposes only a close action', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpWidget(
      const MaterialApp(home: DevOnboardingDirectionsScreen()),
    );
    expect(
      find.byKey(const ValueKey('dev_onboarding_directions_denied')),
      findsOneWidget,
    );
    expect(find.byKey(_close).hitTestable(), findsOneWidget);
    expect(find.byType(ZyraOnboardingStudy), findsNothing);
    expect(find.byType(OnboardingStageIntroScreen), findsNothing);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byKey(_continue), findsNothing);
    expect(find.byType(IconButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('revocation hides artwork but leaves the host stack intact', (
    tester,
  ) async {
    final navigator = await _open(tester, ZyraOnboardingDirection.wise);
    await _advanceButton(tester, ZyraOnboardingDirection.wise, 0);
    expect(
      _study(ZyraOnboardingDirection.wise, 1).hitTestable(),
      findsOneWidget,
    );
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_onboarding_directions_denied')),
      findsOneWidget,
    );
    expect(find.byType(ZyraOnboardingStudy), findsNothing);
    expect(find.byKey(_continue), findsNothing);
    expect(navigator.currentState!.canPop(), isTrue);
    await tester.tap(find.byKey(_close));
    await tester.pumpAndSettle();
    expect(find.byKey(_host), findsOneWidget);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion continues immediately without animation delays', (
    tester,
  ) async {
    await _open(tester, ZyraOnboardingDirection.ahead, reducedMotion: true);
    await _revealCard(tester, ZyraOnboardingDirection.ahead, 0);
    await tester.tap(find.byKey(_continue));
    await tester.pump();
    expect(
      _study(ZyraOnboardingDirection.ahead, 1).hitTestable(),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    await _revealCard(tester, ZyraOnboardingDirection.ahead, 1);
    await tester.tap(find.byKey(_continue));
    await tester.pump();
    expect(
      _study(ZyraOnboardingDirection.ahead, 2).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'visual studies cannot import or invoke live onboarding side effects',
    () {
      final study = File(
        'lib/widgets/zyra_onboarding_study.dart',
      ).readAsStringSync();
      final lab = File('lib/dev/dev_onboarding_lab.dart').readAsStringSync();
      final imports = RegExp(r"^import\s+'([^']+)'", multiLine: true);
      expect(
        imports.allMatches(study).map((m) => m.group(1)),
        everyElement(isNot(contains('/services/'))),
      );
      for (final forbidden in [
        'ZyraInitialSignupDraftService',
        'ZyraLocalPrefs',
        'refreshCurrentAuthorization',
        'pushReplacement',
        'pushAndRemoveUntil',
        'requestPermission(',
        'requestAuthorization(',
        'Permission.',
        'Geolocator',
        'AppTrackingTransparency',
      ]) {
        expect(study, isNot(contains(forbidden)), reason: forbidden);
        expect(lab, isNot(contains(forbidden)), reason: forbidden);
      }
      final splash = File('lib/screens/splash_screen.dart').readAsStringSync();
      final signup = File(
        'lib/screens/onboarding/onboarding_flow.dart',
      ).readAsStringSync();
      for (final productionSource in [splash, signup]) {
        expect(productionSource, isNot(contains('ZyraOnboardingDirection')));
        expect(productionSource, isNot(contains('ZyraOnboardingStudy')));
        expect(
          productionSource,
          isNot(contains('DevOnboardingDirectionsScreen')),
        );
      }
      final liveIntro = OnboardingStageIntroScreen(
        stage: SeekerOnboardingStage.buildProfile,
        onContinue: () {},
      );
      expect(liveIntro.allowPreviewScrolling, isFalse);
      // Scrolling is presentation, not developer authorization. Its two
      // approved owners are the protected rehearsal and post-IDV overview;
      // the latter still enforces owner/preview guards before routing.
      final previewOptIn = RegExp(
        r'allowPreviewScrolling\s*:\s*(true|_devPreview)\b',
      );
      final optedInFiles =
          Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))
              .where((file) => previewOptIn.hasMatch(file.readAsStringSync()))
              .map((file) => file.path)
              .toList()
            ..sort();
      expect(optedInFiles, [
        'lib/dev/dev_onboarding_lab.dart',
        'lib/screens/onboarding/account_path_overview_screen.dart',
      ]);
      final overview = File(
        'lib/screens/onboarding/account_path_overview_screen.dart',
      ).readAsStringSync();
      expect(overview, contains('allowPreviewScrolling: true'));
      expect(overview, contains('ZyraInternalPreviewClient.isActive'));
      expect(overview, contains('ZyraAccountState.generation'));
      expect(signup, isNot(contains('allowPreviewScrolling: true')));
    },
  );
}
