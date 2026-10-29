// Founder-review candidates only; these captures are not approved baselines.
// The real protected DevSignUpProcessScreen is mounted with synthetic local
// authority, and no provider sign-in, account write, or network request runs.
// Capture only with --update-goldens and
// --dart-define=ZYRA_ONBOARDING_DOWN_HANDOFF_CAPTURE_CANDIDATES=true.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_signup_process.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';

const _capture = bool.fromEnvironment(
  'ZYRA_ONBOARDING_DOWN_HANDOFF_CAPTURE_CANDIDATES',
);
const _captureRoot = ValueKey('onboarding-down-handoff-candidate');
const _candidateDirectory =
    'candidates/onboarding_down_handoff_bridge_2026_10_01';

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  await expectLater(
    find.byKey(_captureRoot),
    matchesGoldenFile('$_candidateDirectory/$name.png'),
  );
}

Future<void> _readStoryPage(WidgetTester tester, int page) async {
  final content = find.byKey(
    ValueKey(
      page == 0
          ? 'dev_onboarding_verification_intro'
          : 'dev_opening_page_$page',
    ),
  );
  expect(content.hitTestable(), findsOneWidget);
  expect(find.text('${page + 1} / 4'), findsOneWidget);
  if (page == 3) return;
  final action = find.byKey(
    ValueKey(
      page == 0
          ? 'dev_onboarding_verification_continue'
          : 'dev_onboarding_story_continue',
    ),
  );
  expect(action.hitTestable(), findsOneWidget);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsDownHandoffAudit');
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
    final wordmark = FontLoader('SyneDownHandoffAudit')
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
    ZyraText.testReadingFontFamily = 'PoppinsDownHandoffAudit';
    ZyraText.testWordmarkFontFamily = 'SyneDownHandoffAudit';
  });

  setUp(() {
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevOnboardingStoryNavigation.select(
      ZyraOnboardingStoryNavigation.scrollDown,
    );
    expect(
      ZyraDevOnboardingInteraction.current,
      ZyraOnboardingAdvanceMode.animatedDownArrow,
    );
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  testWidgets('fourth-card down handoff candidate in real preview flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
          child: RepaintBoundary(key: _captureRoot, child: child!),
        ),
        home: const DevSignUpProcessScreen(
          initialDirection: ZyraOnboardingDirection.luma,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('welcome_google')));
    await tester.pumpAndSettle();
    final prelude = find.byKey(
      const ValueKey('dev_onboarding_welcome_prelude'),
    );
    await tester.tap(prelude);
    await tester.pumpAndSettle();
    await tester.tap(prelude);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DevOnboardingIntroduction), findsOneWidget);

    for (var page = 0; page < ZyraOnboardingDirection.storyPageCount; page++) {
      await _readStoryPage(tester, page);
    }
    expect(
      find.byKey(const ValueKey('dev_onboarding_page_count')),
      findsOneWidget,
    );
    expect(find.byType(RoleSelectionScreen), findsNothing);
    expect(
      find.byKey(const ValueKey('dev_onboarding_story_continue')),
      findsOneWidget,
    );
    await _candidate(tester, '01_fourth_card_settled');

    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_story_continue')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(DevOnboardingIntroduction), findsOneWidget);
    expect(find.byType(RoleSelectionScreen), findsNothing);
    final outgoing = tester.widget<Opacity>(
      find.byKey(const ValueKey('dev_opening_foreground_opacity')),
    );
    expect(outgoing.opacity, greaterThan(0));
    expect(outgoing.opacity, lessThan(1));
    await _candidate(tester, '02_outgoing_midpoint');

    await tester.pump(const Duration(milliseconds: 380));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    final boundaryEntry = tester.widget<Opacity>(
      find.byKey(const ValueKey('dev_onboarding_downward_entry')),
    );
    expect(boundaryEntry.opacity, greaterThan(0));
    expect(boundaryEntry.opacity, lessThan(1));
    await _candidate(tester, '03_route_boundary');

    await tester.pump(const Duration(milliseconds: 260));
    final incoming = tester.widget<Opacity>(
      find.byKey(const ValueKey('dev_onboarding_downward_entry')),
    );
    expect(incoming.opacity, greaterThan(0));
    expect(incoming.opacity, lessThan(1));
    await _candidate(tester, '04_incoming_midpoint');

    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.byType(DevOnboardingIntroduction), findsNothing);
    await _candidate(tester, '05_role_selection_settled');
    expect(tester.takeException(), isNull);
  });
}
