// Candidate-only current-flow captures. Approved goldens are never changed.
// Uses the review harness's real-font and capture conventions. Capture with
// --update-goldens --dart-define=ZYRA_ONBOARDING_REVIEW_CAPTURE=true.
// No provider, live account, identity-check finalization, or backend is used.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _capture = bool.fromEnvironment('ZYRA_ONBOARDING_REVIEW_CAPTURE');
const _boundary = ValueKey('onboarding-full-cleanup-candidate');
const _candidateDirectory = String.fromEnvironment(
  'ZYRA_ONBOARDING_REVIEW_CANDIDATE_DIR',
  defaultValue: 'candidates/onboarding_full_cleanup_2026_10_02',
);

// Defence in depth: a future accidental account-store call fails locally.
// No real session or developer authority is created by these visual tests.
class _DeniedSignupStore implements ZyraSignupDraftStore {
  int operations = 0;

  @override
  Future<String?> read(String key) async {
    operations++;
    throw StateError('Visual candidates must not read account data.');
  }

  @override
  Future<void> write(String key, String value) async {
    operations++;
    throw StateError('Visual candidates must not write account data.');
  }

  @override
  Future<void> delete(String key) async {
    operations++;
    throw StateError('Visual candidates must not delete account data.');
  }
}

Future<void> _pumpSurface(
  WidgetTester tester,
  Widget surface,
  double textScale,
) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: RepaintBoundary(key: _boundary, child: child!),
      ),
      home: surface,
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
  final image = await tester.runAsync(() => boundary.toImage());
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    await tester.runAsync(
      () => expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile('$_candidateDirectory/flow_$name.png'),
      ),
    );
  } finally {
    image?.dispose();
  }
}

void _expectReachable(WidgetTester tester, String key, Size viewport) {
  final action = find.byKey(ValueKey(key));
  expect(action.hitTestable(), findsOneWidget);
  final rect = tester.getRect(action);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(viewport.width));
  expect(rect.top, greaterThanOrEqualTo(24));
  expect(rect.bottom, lessThanOrEqualTo(viewport.height - 24));
  expect(rect.height, greaterThanOrEqualTo(44));
  expect(rect.width, greaterThanOrEqualTo(44));
  expect(tester.takeException(), isNull);
}

void main() {
  late _DeniedSignupStore store;
  String? originalName;

  setUpAll(() async {
    final reading = FontLoader('PoppinsCleanupAudit');
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
    final wordmark = FontLoader('SyneCleanupAudit')
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
    ZyraText.testReadingFontFamily = 'PoppinsCleanupAudit';
    ZyraText.testWordmarkFontFamily = 'SyneCleanupAudit';
  });

  setUp(() {
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    // Deny backend data if anything unexpectedly tries to leave the fixtures.
    ZyraInternalPreviewClient.beginPreview();
    store = _DeniedSignupStore();
    ZyraInitialSignupDraftService.setRepositoryForTesting(
      ZyraSignupDraftRepository(
        store: store,
        backend: 'https://example.invalid',
        currentUserId: () => null,
        isPreview: () => true,
      ),
    );
    originalName = AppState.instance.name;
    AppState.instance.name = 'Shakeel';
  });

  tearDown(() {
    expect(store.operations, 0);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    AppState.instance.name = originalName;
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, label: 'standard'),
    (size: Size(320, 568), scale: 1.4, label: 'compact_140'),
  ]) {
    void configureViewport(WidgetTester tester) {
      tester.view.physicalSize = viewport.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('required public name entry candidate ${viewport.label}', (
      tester,
    ) async {
      configureViewport(tester);
      // Inert owner fixture for rendering actual role screens. All account
      // store methods still throw; no continuation or backend is executed.
      ZyraInitialSignupDraftService.setRepositoryForTesting(
        ZyraSignupDraftRepository(
          store: store,
          backend: 'https://example.invalid',
          currentUserId: () => 'visual-a',
          isPreview: () => false,
        ),
      );
      for (final role in ZyraSignupRole.values) {
        await _pumpSurface(
          tester,
          role == ZyraSignupRole.seeker
              ? const OnboardingFlow(
                  signupUserId: 'visual-a',
                  initialDraft: ZyraInitialSignupDraft(
                    role: ZyraSignupRole.seeker,
                  ),
                )
              : const WaliOnboardingFlow(
                  signupUserId: 'visual-a',
                  initialDraft: ZyraInitialSignupDraft(
                    role: ZyraSignupRole.guardian,
                  ),
                ),
          viewport.scale,
        );
        expect(find.text("What's your name?"), findsOneWidget);
        expect(
          find.text('Both names will appear on your public profile.'),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNWidgets(2));
        await _candidate(tester, '${role.name}_public_name_${viewport.label}');
        _expectReachable(
          tester,
          role == ZyraSignupRole.seeker
              ? 'onboarding_continue'
              : 'wali_onboarding_continue',
          viewport.size,
        );
      }
    });

    testWidgets('account essentials current-flow candidate ${viewport.label}', (
      tester,
    ) async {
      configureViewport(tester);
      var continued = 0;
      await _pumpSurface(
        tester,
        AccountEssentialsIntroScreen(onContinue: () => continued++),
        viewport.scale,
      );
      expect(find.text('First, your account.'), findsOneWidget);
      expect(find.text('Together, we’ll build four things.'), findsNothing);
      await _candidate(tester, 'account_essentials_${viewport.label}');
      final action = find.byKey(const ValueKey('onboarding_stage_continue'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      _expectReachable(tester, 'onboarding_stage_continue', viewport.size);
      if (viewport.scale > 1) {
        await _candidate(tester, 'account_essentials_${viewport.label}_lower');
      }
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(continued, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('post-IDV now or later candidate ${viewport.label}', (
      tester,
    ) async {
      configureViewport(tester);
      // Rendering only: neither choice is executed and no account is supplied.
      await _pumpSurface(
        tester,
        const SeekerPostIdentityChoiceScreen(),
        viewport.scale,
      );
      expect(find.text('Your account is ready.'), findsOneWidget);
      expect(find.text('Continue profile setup'), findsOneWidget);
      expect(find.text('Go to My ZYRA · finish later'), findsOneWidget);
      _expectReachable(
        tester,
        'seeker_post_identity_continue_setup',
        viewport.size,
      );
      _expectReachable(
        tester,
        'seeker_post_identity_finish_later',
        viewport.size,
      );
      await _candidate(tester, 'post_idv_choice_${viewport.label}');
      if (viewport.scale > 1) {
        await tester.ensureVisible(find.text('IF YOU FINISH LATER'));
        await tester.pumpAndSettle();
        await _candidate(tester, 'post_idv_choice_${viewport.label}_lower');
        _expectReachable(
          tester,
          'seeker_post_identity_finish_later',
          viewport.size,
        );
      }
    });

    testWidgets('four-card roadmap then Profile handoff ${viewport.label}', (
      tester,
    ) async {
      configureViewport(tester);
      var fixtureReads = 0;
      await _pumpSurface(
        tester,
        SeekerOnboardingOverviewScreen(
          gender: 'male',
          progressLoader: () async {
            fixtureReads++;
            return SeekerPostIdentityChoiceScreen.previewIncompleteProgress;
          },
          answersLoader: () async {
            fixtureReads++;
            return null;
          },
          profileCompleteLoader: () async {
            fixtureReads++;
            return false;
          },
        ),
        viewport.scale,
      );
      expect(fixtureReads, 3);
      expect(find.text('Your next steps, Shakeel.'), findsOneWidget);
      expect(find.text('Together, we’ll build four things.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('onboarding_welcome_continue')),
        findsNothing,
      );
      for (var item = 1; item <= 4; item++) {
        await tester.tap(
          find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AnimatedOpacity>(
                find.byKey(ValueKey('onboarding_roadmap_item_$item')),
              )
              .opacity,
          1,
        );
        expect(tester.takeException(), isNull);
      }
      await _candidate(tester, 'roadmap_complete_${viewport.label}');
      final action = find.byKey(const ValueKey('onboarding_welcome_continue'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      _expectReachable(tester, 'onboarding_welcome_continue', viewport.size);
      if (viewport.scale > 1) {
        await _candidate(tester, 'roadmap_complete_${viewport.label}_lower');
      }
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PageView>(
              find.byKey(const ValueKey('onboarding_intro_page_view')),
            )
            .controller!
            .page,
        closeTo(1, 0.001),
      );
      expect(find.text('Let’s begin with your profile.'), findsOneWidget);
      expect(find.text('First, your account.'), findsNothing);
      await _candidate(tester, 'profile_handoff_${viewport.label}');
      await tester.ensureVisible(
        find.byKey(const ValueKey('onboarding_stage_continue')),
      );
      await tester.pumpAndSettle();
      _expectReachable(tester, 'onboarding_stage_continue', viewport.size);
      if (viewport.scale > 1) {
        await _candidate(tester, 'profile_handoff_${viewport.label}_lower');
      }
      // The final arrow would open real questions; do not execute it here.
      expect(fixtureReads, 3);
    });

    testWidgets('Guardian current-flow overview candidate ${viewport.label}', (
      tester,
    ) async {
      configureViewport(tester);
      await _pumpSurface(
        tester,
        const GuardianOnboardingOverviewScreen(),
        viewport.scale,
      );
      expect(find.text('First, your Guardian account.'), findsOneWidget);
      expect(find.text('Account essentials'), findsOneWidget);
      expect(find.text('Verify your identity'), findsOneWidget);
      expect(find.text('Responsibilities'), findsOneWidget);
      expect(find.text('Guardian Presentation'), findsNothing);
      expect(find.text('Guardian Membership'), findsNothing);
      _expectReachable(tester, 'account_path_overview_continue', viewport.size);
      await _candidate(tester, 'guardian_overview_${viewport.label}');
      if (viewport.scale > 1) {
        await tester.ensureVisible(
          find.text(
            'Once your account is ready, you can invite a Seeker or accept their invitation. You do not need to be a family member.',
          ),
        );
        await tester.pumpAndSettle();
        await _candidate(tester, 'guardian_overview_${viewport.label}_lower');
        _expectReachable(
          tester,
          'account_path_overview_continue',
          viewport.size,
        );
      }
      // No account owner is supplied and no navigation/creation is executed.
    });
  }
}
