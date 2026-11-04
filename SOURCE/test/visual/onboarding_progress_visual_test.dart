// Candidate-only real-font screenshots for the 2026-10-01 onboarding
// progress correction. Run with --update-goldens and
// --dart-define=ZYRA_ONBOARDING_PROGRESS_CAPTURE_CANDIDATES=true.
// This never updates an approved golden or an older candidate directory.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/queue44_role_choice_fixture.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

const _capture = bool.fromEnvironment(
  'ZYRA_ONBOARDING_PROGRESS_CAPTURE_CANDIDATES',
);
const _directory = 'candidates/onboarding_progress_2026_10_01';
const _boundary = ValueKey('onboarding-progress-candidate');
const _phone = Size(390, 844);

void _noOpContinue() {}

Widget _luma(Widget child) => OnboardingPreviewStyle(
  directionName: 'luma',
  child: ZyraOnboardingArrowScope(enabled: true, child: child),
);

Future<void> _mount(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
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
    await tester.runAsync(
      () => expectLater(bytes, matchesGoldenFile('$_directory/$name.png')),
    );
  } finally {
    rendered.dispose();
  }
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsOnboardingProgressAudit');
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
    final wordmark = FontLoader('SyneOnboardingProgressAudit')
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
    ZyraText.testReadingFontFamily = 'PoppinsOnboardingProgressAudit';
    ZyraText.testWordmarkFontFamily = 'SyneOnboardingProgressAudit';
  });

  setUp(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevRoleChoiceDesign.resetForTesting();
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
  });

  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDevRoleChoiceDesign.resetForTesting();
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  testWidgets('Atoms role choice is a branch without invented progress', (
    tester,
  ) async {
    await _mount(tester, _luma(const RoleSelectionScreen(devPreview: true)));
    expect(find.text('How will you use ZYRA first?'), findsOneWidget);
    expect(find.textContaining('ACCOUNT SETUP'), findsNothing);
    expect(find.text('1 OF 2'), findsNothing);
    expect(find.byKey(const ValueKey('role-select-seeker')), findsOneWidget);
    expect(find.byKey(const ValueKey('role-select-guardian')), findsOneWidget);
    await _candidate(tester, '01_luma_role_choice__phone');
  });

  testWidgets('Seeker overview retains the Luma roadmap and numbered handoff', (
    tester,
  ) async {
    await _mount(
      tester,
      _luma(
        OnboardingStageIntroScreen(
          stage: SeekerOnboardingStage.buildProfile,
          welcomeName: 'Shakeel',
          devPreview: true,
          allowPreviewScrolling: true,
          onContinue: _noOpContinue,
        ),
      ),
    );
    expect(find.text('Together, we’ll build four things.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding_welcome_progress_cue')),
      findsNothing,
    );
    expect(find.text('1 / 2'), findsNothing);
    expect(find.text('2 / 2'), findsNothing);
    await _candidate(tester, '02_luma_seeker_overview__phone');

    for (var item = 0; item < 4; item++) {
      await tester.tap(
        find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
      );
      await tester.pumpAndSettle();
    }
    expect(
      find.byKey(const ValueKey('onboarding_welcome_continue')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_welcome_continue')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding_stage_build_profile')),
      findsOneWidget,
    );
    expect(find.text('Let’s begin with your profile.'), findsOneWidget);
    expect(find.textContaining('STAGE 1 OF'), findsNothing);
    await _candidate(tester, '03_luma_profile_handoff__phone');
  });

  testWidgets(
    'later Seeker handoff names its category without duplicate progress',
    (tester) async {
      await _mount(
        tester,
        _luma(
          OnboardingStageIntroScreen(
            stage: SeekerOnboardingStage.journeyBio,
            devPreview: true,
            allowPreviewScrolling: true,
            onContinue: _noOpContinue,
          ),
        ),
      );
      expect(find.text('STAGE 2 OF 4'), findsNothing);
      expect(find.text('Let’s build your Journey Bio.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('onboarding_stage_journey_bio')),
        findsOneWidget,
      );
      await _candidate(tester, '04_luma_journey_bio_handoff__phone');
    },
  );

  testWidgets('Guardian question shows five-question local progress', (
    tester,
  ) async {
    await _mount(tester, _luma(const WaliOnboardingFlow(devPreview: true)));
    expect(find.text('ACCOUNT ESSENTIALS'), findsOneWidget);
    expect(find.text('QUESTION 1 OF 5'), findsOneWidget);
    expect(find.textContaining('ACCOUNT SETUP'), findsNothing);
    await _candidate(tester, '05_luma_guardian_question__phone');
  });
}
