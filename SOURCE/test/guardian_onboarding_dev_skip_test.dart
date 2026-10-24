import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/onboarding/transition_screen.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';

const _draft = ZyraInitialSignupDraft(
  role: ZyraSignupRole.guardian,
  membershipChoice: ZyraSignupMembershipChoice(
    kind: ZyraSignupMembershipKind.basic,
  ),
  step: 5,
  firstName: 'Hassan',
  lastName: 'Ahmed',
  gender: 'male',
  relationship: 'Brother',
  firstPhotoPath: 'preview-guardian/first.jpg',
  dob: null,
);

class _RequestSpyPreviewClient extends ZyraInternalPreviewClient {
  _RequestSpyPreviewClient(super.inner);

  int attempts = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    attempts++;
    return super.send(request);
  }
}

void main() {
  var transmittedRequests = 0;
  late _RequestSpyPreviewClient previewClient;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: ZyraInternalFounderPolicy.approvedSupabaseUrl,
      publishableKey: 'local-guardian-widget-test',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: previewClient = _RequestSpyPreviewClient(
        MockClient((_) async {
          transmittedRequests++;
          return http.Response(
            '{"message":"offline test rejects every API request"}',
            403,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
  });

  tearDownAll(() async => Supabase.instance.dispose());

  setUp(() {
    transmittedRequests = 0;
    previewClient.attempts = 0;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(
      name: 'Previous sample',
      gender: 'female',
      waliName: 'Previous sample',
      waliRelationship: 'Mother',
    );
    ZyraDevScenario.instance.reset();
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
  });

  testWidgets('Guardian transition Skip is protected and keeps Continue', (
    tester,
  ) async {
    var skips = 0;
    var continues = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TransitionScreen(
          title: 'Support and guidance',
          body: 'A local orientation.',
          buttonLabel: 'Continue',
          onContinue: () => continues++,
          devPreview: true,
          onDevSkip: () => skips++,
        ),
      ),
    );

    final skip = find.byKey(const ValueKey('onboarding_dev_skip'));
    expect(skip, findsOneWidget);
    final stale = tester.widget<TextButton>(skip).onPressed!;
    await tester.tap(skip);
    await tester.pump();
    expect(skips, 1);
    expect(continues, 0);

    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    stale();
    expect(skips, 1, reason: 'A retained Skip cannot outlive developer proof');
  });

  testWidgets('ordinary transition never offers developer Skip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransitionScreen(
          title: 'Live transition',
          body: 'The ordinary path remains intact.',
          buttonLabel: 'Continue',
          onContinue: () {},
          onDevSkip: () {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
  });

  testWidgets('final Guardian Skip lands in a fresh zero-linked dashboard', (
    tester,
  ) async {
    final draft = ZyraInitialSignupDraft(
      role: _draft.role,
      step: _draft.step,
      firstName: _draft.firstName,
      lastName: _draft.lastName,
      gender: _draft.gender,
      relationship: _draft.relationship,
      firstPhotoPath: _draft.firstPhotoPath,
      dob: DateTime(1980, 1, 1),
      membershipChoice: _draft.membershipChoice,
    );
    ZyraDevScenario.instance.setWaliLinkedSeekers(3);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ZyraCodeScreen(
          asGuardian: true,
          signupPreview: true,
          signupPreviewIdentity: draft,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final skip = find.byKey(const ValueKey('onboarding_dev_skip'));
    expect(skip, findsOneWidget);
    await tester.tap(skip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(WaliHomeShell), findsOneWidget);
    expect(
      find.text('There are no linked Seeker responsibilities to review.'),
      findsOneWidget,
    );
    expect(
      find.textContaining("Couldn't refresh Guardian priorities"),
      findsNothing,
    );
    expect(ZyraDevScenario.instance.waliLinkedSeekers, 0);
    expect(AppState.instance.waliName, 'Hassan');
    expect(AppState.instance.waliRelationship, 'Brother');
    expect(AppState.instance.gender, 'male');
    expect(AppState.instance.dob, DateTime(1980, 1, 1));
    expect(transmittedRequests, 0);
    expect(
      previewClient.attempts,
      0,
      reason: 'No Guardian service read is attempted',
    );
  });

  for (final choice in [
    const ZyraSignupMembershipChoice(kind: ZyraSignupMembershipKind.basic),
    const ZyraSignupMembershipChoice(kind: ZyraSignupMembershipKind.one),
    const ZyraSignupMembershipChoice(
      kind: ZyraSignupMembershipKind.family,
      seekers: 0,
      guardians: 2,
    ),
  ]) {
    testWidgets(
      'Guardian ${choice.kind.name} completed rehearsal chooses only local capability',
      (tester) async {
        final draft = ZyraInitialSignupDraft(
          role: ZyraSignupRole.guardian,
          step: 5,
          firstName: 'Hassan',
          lastName: 'Ahmed',
          gender: 'male',
          relationship: 'Brother',
          firstPhotoPath: 'preview-guardian/first.jpg',
          dob: DateTime(1980),
          membershipChoice: choice,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: ZyraCodeScreen(
              asGuardian: true,
              signupPreview: true,
              signupPreviewIdentity: draft,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final skip = find.byKey(const ValueKey('onboarding_dev_skip'));
        await tester.tap(skip);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(WaliHomeShell), findsOneWidget);
        expect(
          AppState.instance.waliHasWaliOne,
          choice.kind != ZyraSignupMembershipKind.basic,
        );
        expect(
          ZyraDevScenario.instance.waliLinkedSeekers,
          0,
          reason: 'Choosing Family does not allocate places or create a link.',
        );
        expect(transmittedRequests, 0);
        expect(previewClient.attempts, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Guardian preview landing stays deny-only after revocation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: WaliHomeShell(initialOnboardingPreview: true)),
    );
    await tester.pump();
    expect(
      find.text('There are no linked Seeker responsibilities to review.'),
      findsOneWidget,
    );
    expect(transmittedRequests, 0);
    expect(previewClient.attempts, 0);

    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('guardian_onboarding_preview_denied')),
      findsOneWidget,
    );
    expect(transmittedRequests, 0);
    expect(previewClient.attempts, 0);
  });

  testWidgets('code Skip requires a complete draft and live developer proof', (
    tester,
  ) async {
    final draft = ZyraInitialSignupDraft(
      role: _draft.role,
      step: _draft.step,
      firstName: _draft.firstName,
      lastName: _draft.lastName,
      gender: _draft.gender,
      relationship: _draft.relationship,
      firstPhotoPath: _draft.firstPhotoPath,
      dob: DateTime(1980, 1, 1),
      membershipChoice: _draft.membershipChoice,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraCodeScreen(
          asGuardian: true,
          signupPreview: true,
          signupPreviewIdentity: draft,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final skip = find.byKey(const ValueKey('onboarding_dev_skip'));
    final stale = tester.widget<TextButton>(skip).onPressed!;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    stale();
    await tester.pump();
    expect(find.byType(WaliHomeShell), findsNothing);
    expect(transmittedRequests, 0);

    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpWidget(
      const MaterialApp(
        home: ZyraCodeScreen(asGuardian: true, signupPreview: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
  });
}
