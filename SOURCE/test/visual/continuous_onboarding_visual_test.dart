// Candidate-only real-font evidence for the continuous local onboarding flow.
// Does not promote approved pixels or invoke account/provider/backend paths.
// Capture with --update-goldens and
// --dart-define=ZYRA_CONTINUOUS_ONBOARDING_CAPTURE_CANDIDATES=true.
// To refresh only role-choice candidates, use --update-goldens with
// --dart-define=ZYRA_ROLE_CHOICE_CAPTURE_CANDIDATES=true.
// New staged-motion stills have a separate opt-in and directory.
// --dart-define=ZYRA_ONBOARDING_MOTION_CAPTURE_CANDIDATES=true.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_role_choice_design.dart';
import 'package:zyra/dev/dev_signup_process.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/dev/developer_access_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';

const _capture = bool.fromEnvironment(
  'ZYRA_CONTINUOUS_ONBOARDING_CAPTURE_CANDIDATES',
);
const _roleChoiceCapture = bool.fromEnvironment(
  'ZYRA_ROLE_CHOICE_CAPTURE_CANDIDATES',
);
const _motionCapture = bool.fromEnvironment(
  'ZYRA_ONBOARDING_MOTION_CAPTURE_CANDIDATES',
);
const _root = ValueKey('continuous-onboarding-candidate');
const _directory = 'candidates/onboarding_edge_to_edge_2026_09_29';
const _roleChoiceDirectory = 'candidates/role_choice_guided_paths_2026_09_30';
const _stagedIntroDirectory = 'candidates/onboarding_staged_intro_2026_09_30';
const _motionDirectory = 'candidates/onboarding_welcome_role_motion_2026_09_30';

void _noopOnboardingContinue() {}

Future<void> _mount(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: RepaintBoundary(key: _root, child: child!),
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
  if (screen is DevSignUpProcessScreen) {
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/auth/google_g_logo.png'),
        tester.element(find.byType(WelcomeScreen)),
      );
    });
    await tester.pumpAndSettle();
  }
}

void _checkEdgeToEdge(WidgetTester tester, Size viewport, Type screenType) {
  expect(find.byKey(const ValueKey('dev_signup_close')), findsNothing);
  expect(find.byIcon(Icons.close_rounded), findsNothing);
  final screen = find.byType(screenType);
  final rect = tester.getRect(screen);
  expect(rect.topLeft, Offset.zero);
  expect(rect.size, viewport);
  // Each page owns the OS safe insets; no parent header consumes its height.
  final safeArea = tester.widget<SafeArea>(
    find.descendant(of: screen, matching: find.byType(SafeArea)).first,
  );
  final contentRect = tester.getRect(find.byWidget(safeArea.child));
  expect(contentRect.top, greaterThanOrEqualTo(24));
  expect(contentRect.bottom, lessThanOrEqualTo(viewport.height - 24));
  expect(contentRect.height, viewport.height - 48);
  expect(find.text('Sign-up preview · no account changes'), findsNothing);
  expect(
    find.byKey(const ValueKey('dev_onboarding_direction_label')),
    findsNothing,
  );
  expect(find.byKey(const ValueKey('dev_onboarding_close')), findsNothing);
  expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
  expect(tester.takeException(), isNull);
}

Future<void> _candidate(
  WidgetTester tester,
  String name, {
  String directory = _directory,
}) async {
  if (!_capture && !_roleChoiceCapture && !_motionCapture) return;
  // The role-only capture preserves the older 2026-09-29 candidate set.
  if (_roleChoiceCapture && !_capture && directory != _roleChoiceDirectory) {
    return;
  }
  if (_motionCapture &&
      !_capture &&
      !_roleChoiceCapture &&
      directory != _motionDirectory) {
    return;
  }
  expect(autoUpdateGoldenFiles, isTrue);
  // Repaint and freeze the whole frame, then inspect the encoded PNG itself.
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_root),
  );
  boundary.markNeedsPaint();
  await tester.pump();
  final image = await tester.runAsync(() => boundary.toImage());
  expect(image, isNotNull);
  final rendered = image!;
  try {
    final encoded = await tester.runAsync(
      () => rendered.toByteData(format: ui.ImageByteFormat.png),
    );
    final bytes = encoded!.buffer.asUint8List();
    final decoded = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final rgba = data!.buffer.asUint8List();
      final samples = [
        for (final point in const [Offset(4, 4), Offset(4, 24), Offset(4, 70)])
          [
            for (var channel = 0; channel < 4; channel++)
              rgba[(point.dy.toInt() * frame.image.width + point.dx.toInt()) *
                      4 +
                  channel],
          ],
      ];
      frame.image.dispose();
      codec.dispose();
      return samples;
    });
    expect(decoded, isNotNull);
    for (final pixel in decoded!) {
      // Midnight Plum begins at #30203F. The old solid #160E20 header fails
      // every threshold, including samples inside the OS status safe inset.
      expect(
        pixel[0],
        greaterThanOrEqualTo(44),
        reason: '$name top gradient red',
      );
      expect(
        pixel[1],
        greaterThanOrEqualTo(28),
        reason: '$name top gradient green',
      );
      expect(
        pixel[2],
        greaterThanOrEqualTo(58),
        reason: '$name top gradient blue',
      );
      expect(pixel[3], 255, reason: '$name opaque edge-to-edge background');
    }
    await tester.runAsync(
      () => expectLater(bytes, matchesGoldenFile('$directory/$name.png')),
    );
  } finally {
    rendered.dispose();
  }
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsContinuousOnboardingAudit');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneContinuousOnboardingAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsContinuousOnboardingAudit';
    ZyraText.testWordmarkFontFamily = 'SyneContinuousOnboardingAudit';
  });

  setUp(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevRoleChoiceDesign.resetForTesting();
    ZyraInternalPreviewClient.beginPreview();
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  testWidgets('developer landing real-font Onboarding label', (tester) async {
    await _mount(
      tester,
      const DeveloperAccessScreen(),
      size: const Size(390, 844),
    );
    for (final action in const [
      ('dev_access_seeker', 'Seeker'),
      ('dev_access_guardian', 'Guardian'),
      ('dev_access_signup', 'Onboarding'),
    ]) {
      final button = find.byKey(ValueKey(action.$1));
      expect(button.hitTestable(), findsOneWidget);
      expect(
        find.descendant(of: button, matching: find.text(action.$2)),
        findsOneWidget,
      );
    }
    expect(find.text('Sign up'), findsNothing);
    expect(tester.takeException(), isNull);
    await _candidate(tester, 'developer_landing__standard');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final viewport in const [
    (size: Size(390, 844), name: 'standard'),
    (size: Size(320, 568), name: 'compact'),
  ]) {
    testWidgets('main splash lockup ${viewport.name}', (tester) async {
      await _mount(tester, const SplashScreen(), size: viewport.size);
      expect(
        find.byKey(const ValueKey('splash_study_dawnHorizon')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _candidate(tester, 'splash_quiet_horizon__${viewport.name}');
    });
  }

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, name: 'standard'),
    (size: Size(320, 568), scale: 1.4, name: 'compact_140'),
  ]) {
    testWidgets('continuous Luma flow real-font ${viewport.name}', (
      tester,
    ) async {
      await _mount(
        tester,
        const DevSignUpProcessScreen(
          initialDirection: ZyraOnboardingDirection.luma,
        ),
        size: viewport.size,
        scale: viewport.scale,
      );
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(DevOnboardingIntroduction), findsNothing);
      _checkEdgeToEdge(tester, viewport.size, WelcomeScreen);
      for (final provider in const ['apple', 'google']) {
        final button = find.byKey(ValueKey('welcome_$provider'));
        expect(button.hitTestable(), findsOneWidget);
        final buttonRect = tester.getRect(button);
        final labelRect = tester.getRect(
          find.descendant(
            of: button,
            matching: find.text(
              provider == 'apple'
                  ? 'Continue with Apple'
                  : 'Continue with Google',
            ),
          ),
        );
        expect(labelRect.left, greaterThanOrEqualTo(buttonRect.left));
        expect(labelRect.right, lessThanOrEqualTo(buttonRect.right));
        expect(labelRect.top, greaterThanOrEqualTo(buttonRect.top));
        expect(labelRect.bottom, lessThanOrEqualTo(buttonRect.bottom));
        expect(buttonRect.bottom, lessThanOrEqualTo(viewport.size.height - 24));
      }
      await _candidate(tester, 'welcome__${viewport.name}');
      await tester.tap(find.byKey(const ValueKey('welcome_google')));
      await tester.pumpAndSettle();
      final prelude = find.byKey(
        const ValueKey('dev_onboarding_welcome_prelude'),
      );
      await tester.tap(prelude);
      await tester.pumpAndSettle();
      await tester.tap(prelude);
      await tester.pumpAndSettle();
      final welcomeContinue = find.byKey(
        const ValueKey('dev_onboarding_welcome_continue'),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.ensureVisible(welcomeContinue);
      await tester.pumpAndSettle();
      await tester.tap(welcomeContinue);
      await tester.pumpAndSettle();
      for (var page = 0; page < 4; page++) {
        expect(find.byType(DevOnboardingIntroduction), findsOneWidget);
        final content = find.byKey(
          ValueKey(
            page == 0
                ? 'dev_onboarding_verification_intro'
                : 'dev_opening_page_$page',
          ),
        );
        expect(content.hitTestable(), findsOneWidget);
        expect(find.text('${page + 1} / 4'), findsOneWidget);
        expect(find.byType(RoleSelectionScreen), findsNothing);
        expect(find.text('Finish preview'), findsNothing);
        _checkEdgeToEdge(tester, viewport.size, DevOnboardingIntroduction);
        if (page == 0) {
          await _candidate(
            tester,
            'luma_intro__${viewport.name}',
            directory: _stagedIntroDirectory,
          );
        }
        final action = find.byKey(
          ValueKey(
            page == 0
                ? 'dev_onboarding_verification_continue'
                : page == 3
                ? 'dev_onboarding_story_continue'
                : 'dev_opening_next',
          ),
        );
        await tester.ensureVisible(action);
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pumpAndSettle();
      }
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(DevOnboardingIntroduction), findsNothing);
      _checkEdgeToEdge(tester, viewport.size, RoleSelectionScreen);
      await _candidate(
        tester,
        'role_choice__${viewport.name}',
        directory: _roleChoiceDirectory,
      );
      for (final role in const ['seeker', 'guardian']) {
        final action = find.byKey(ValueKey('role-select-$role'));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        _checkEdgeToEdge(tester, viewport.size, RoleSelectionScreen);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Luma role-choice cards candidate-only review', (tester) async {
    await _mount(
      tester,
      const OnboardingPreviewStyle(
        directionName: 'luma',
        child: RoleSelectionScreen(devPreview: true),
      ),
      size: const Size(390, 844),
    );
    _checkEdgeToEdge(tester, const Size(390, 844), RoleSelectionScreen);
    expect(find.byKey(const ValueKey('role-select-seeker')), findsOneWidget);
    expect(find.byKey(const ValueKey('role-select-guardian')), findsOneWidget);
    await _candidate(
      tester,
      'role_choice_luma__standard',
      directory: _roleChoiceDirectory,
    );
  });

  testWidgets('Luma welcome and Guided Paths selected motion stills', (
    tester,
  ) async {
    const size = Size(390, 844);
    await _mount(
      tester,
      const OnboardingPreviewStyle(
        directionName: 'luma',
        child: ZyraOnboardingArrowScope(
          enabled: true,
          child: OnboardingStageIntroScreen(
            stage: SeekerOnboardingStage.buildProfile,
            welcomeName: 'Shakeel',
            devPreview: true,
            allowPreviewScrolling: true,
            onContinue: _noopOnboardingContinue,
          ),
        ),
      ),
      size: size,
    );
    expect(
      find.byKey(const ValueKey('onboarding_welcome_progress_cue')),
      findsNothing,
    );
    await _candidate(
      tester,
      'luma_welcome_final__standard',
      directory: _motionDirectory,
    );
    await tester.pumpWidget(const SizedBox.shrink());

    await _mount(
      tester,
      const OnboardingPreviewStyle(
        directionName: 'luma',
        child: RoleSelectionScreen(devPreview: true),
      ),
      size: size,
    );
    expect(
      ZyraDevRoleChoiceDesign.select(ZyraRoleChoiceDesign.guidedPaths),
      isTrue,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('role-select-seeker')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 230));
    await _candidate(
      tester,
      'guided_paths_seeker_selected_mid__standard',
      directory: _motionDirectory,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('role-choice-continue')), findsOneWidget);
    await _candidate(
      tester,
      'guided_paths_seeker_selected_end__standard',
      directory: _motionDirectory,
    );
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, name: 'standard'),
    (size: Size(320, 568), scale: 1.4, name: 'compact_140'),
  ]) {
    for (final design in ZyraRoleChoiceDesign.values) {
      testWidgets('role-choice ${design.name} ${viewport.name}', (
        tester,
      ) async {
        await _mount(
          tester,
          const OnboardingPreviewStyle(
            directionName: 'luma',
            child: RoleSelectionScreen(devPreview: true),
          ),
          size: viewport.size,
          scale: viewport.scale,
        );
        _checkEdgeToEdge(tester, viewport.size, RoleSelectionScreen);
        expect(ZyraDevRoleChoiceDesign.select(design), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: design.name);
        expect(
          find.text('One identity · one secure sign-in · two experiences'),
          findsNothing,
          reason: '${design.name} should not show the old footer strapline',
        );
        for (final role in const ['seeker', 'guardian']) {
          expect(find.byKey(ValueKey('role-select-$role')), findsOneWidget);
        }
        final seekerHeight = tester
            .getSize(find.byKey(const ValueKey('role-select-seeker')))
            .height;
        final guardianHeight = tester
            .getSize(find.byKey(const ValueKey('role-select-guardian')))
            .height;
        if (viewport.name == 'standard') {
          expect(
            tester
                .getRect(find.byKey(const ValueKey('role-select-guardian')))
                .bottom,
            lessThanOrEqualTo(viewport.size.height - 24 - 78),
            reason: '${design.name} must show both roles before selection',
          );
        }
        await _candidate(
          tester,
          'role_choice_${design.name}__${viewport.name}',
          directory: _roleChoiceDirectory,
        );
        if (viewport.name == 'compact_140') {
          await tester.ensureVisible(
            find.byKey(const ValueKey('role-select-seeker')),
          );
          await tester.pumpAndSettle();
        }
        expect(
          find.byKey(const ValueKey('role-select-seeker')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('role-select-seeker')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('role-select-guardian')),
          findsNothing,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('role-select-seeker')))
              .height,
          greaterThan(seekerHeight),
          reason: '${design.name} Seeker should expand when selected',
        );
        expect(
          find.byKey(const ValueKey('role-choice-continue')),
          findsOneWidget,
        );
        await _candidate(
          tester,
          'role_choice_${design.name}_selected__${viewport.name}',
          directory: _roleChoiceDirectory,
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('role-select-seeker')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('role-select-seeker')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('role-select-seeker')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('role-select-guardian')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('role-choice-continue')),
          findsNothing,
        );
        if (design == ZyraRoleChoiceDesign.guidedPaths &&
            viewport.name == 'standard') {
          await _candidate(
            tester,
            'role_choice_guidedPaths_collapsed__standard',
            directory: _roleChoiceDirectory,
          );
        }

        await tester.ensureVisible(
          find.byKey(const ValueKey('role-select-guardian')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('role-select-guardian')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('role-select-seeker')), findsNothing);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('role-select-guardian')))
              .height,
          greaterThan(guardianHeight),
          reason: '${design.name} Guardian should expand when selected',
        );
        expect(
          find.byKey(const ValueKey('role-choice-continue')),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('role-select-guardian')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('role-select-guardian')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('role-select-seeker')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('role-select-guardian')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('role-choice-continue')),
          findsNothing,
        );
        expect(tester.takeException(), isNull, reason: design.name);
      });
    }
  }
}
