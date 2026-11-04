import 'support/queue44_signup_flow_driver.dart';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/onboarding/signup_membership_choice_screen.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_photo_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

const basic = ZyraSignupMembershipChoice(kind: ZyraSignupMembershipKind.basic);

/// Replaces the session precisely after a native draft save has confirmed,
/// before the flow can begin its separate membership-intent operation.
class _EpochReplacingSignupRepository extends ZyraSignupDraftRepository {
  _EpochReplacingSignupRepository({
    required super.store,
    required super.backend,
    required super.currentUserId,
    required super.isPreview,
    required super.currentGeneration,
    required this.replaceEpoch,
  });

  final void Function() replaceEpoch;

  @override
  Future<void> save(String userId, ZyraInitialSignupDraft draft) async {
    await super.save(userId, draft);
    replaceEpoch();
  }
}

ZyraInitialSignupDraft completed(
  ZyraSignupRole role, {
  ZyraSignupMembershipChoice? choice,
}) => ZyraInitialSignupDraft(
  role: role,
  step: role == ZyraSignupRole.seeker ? 4 : 5,
  firstName: 'Test',
  lastName: 'Ahmed',
  gender: 'male',
  dob: DateTime(1990),
  relationship: role == ZyraSignupRole.guardian ? 'Father' : null,
  firstPhotoPath: 'owner-a/first.jpg',
  membershipChoice: choice,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        if (request.url.path.startsWith(
          '/storage/v1/object/sign/profile-photos/',
        )) {
          return http.Response(
            jsonEncode({
              'signedURL':
                  '${request.url.path.substring('/storage/v1'.length)}?token=synthetic',
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return http.Response(
          jsonEncode({'message': 'unexpected synthetic request'}),
          403,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    await ZyraLocalPrefs.init();
  });
  tearDownAll(() => Supabase.instance.dispose());
  test('Family counts are independent and include the signup account role', () {
    for (final role in ZyraSignupRole.values) {
      for (var seekers = 0; seekers <= 10; seekers++) {
        for (var guardians = 0; guardians <= 10; guardians++) {
          final choice = ZyraSignupMembershipChoice(
            kind: ZyraSignupMembershipKind.family,
            seekers: seekers,
            guardians: guardians,
          );
          final valid = role == ZyraSignupRole.seeker
              ? seekers > 0
              : guardians > 0;
          expect(choice.isValidFor(role), valid);
          if (valid) {
            final restored = ZyraSignupMembershipChoice.fromJson(
              jsonDecode(jsonEncode(choice.toJson())),
              role: role,
            );
            expect(restored.toJson(), choice.toJson());
          }
        }
      }
    }
    for (final bad in [-1, 11]) {
      expect(
        ZyraSignupMembershipChoice(
          kind: ZyraSignupMembershipKind.family,
          seekers: bad,
          guardians: 1,
        ).isValidFor(ZyraSignupRole.guardian),
        isFalse,
      );
    }
    expect(
      const ZyraSignupMembershipChoice(
        kind: ZyraSignupMembershipKind.one,
        seekers: 1,
      ).isValidFor(ZyraSignupRole.seeker),
      isFalse,
    );
  });

  test('malformed preference and authority-bearing payloads are rejected', () {
    for (final value in [
      {'kind': 'paid', 'seekers': 0, 'guardians': 0},
      {'kind': 'basic', 'seekers': '0', 'guardians': 0},
      {'kind': 'family', 'seekers': 0, 'guardians': 1},
      {'kind': 'basic', 'seekers': 0, 'guardians': 0, 'verified': true},
    ]) {
      expect(
        () => ZyraSignupMembershipChoice.fromJson(
          value,
          role: ZyraSignupRole.seeker,
        ),
        throwsFormatException,
      );
    }
  });

  for (final role in ZyraSignupRole.values) {
    test(
      '${role.name} old form preserves answers before photo and membership',
      () {
        final draft = completed(role);
        final old = {
          ...draft.toJson(),
          'version': 2,
          'step': role == ZyraSignupRole.seeker ? 3 : 4,
          'firstPhotoPath': null,
        }..remove('membershipChoice');
        final restored = ZyraInitialSignupDraft.fromJson(old);
        expect(restored.step, role == ZyraSignupRole.seeker ? 3 : 4);
        expect(restored.firstName, draft.firstName);
        expect(restored.lastName, draft.lastName);
        expect(restored.gender, draft.gender);
        expect(restored.dob, draft.dob);
        expect(restored.relationship, draft.relationship);
        expect(restored.needsMembershipChoice, isFalse);
        expect(restored.awaitsVerification, isFalse);
        expect(completed(role, choice: basic).awaitsVerification, isTrue);
      },
    );
  }

  late FakeSignupStore store;
  late ZyraSignupDraftRepository repository;
  String? owner;
  var preview = false;
  var generation = 0;

  setUp(() {
    store = FakeSignupStore();
    owner = 'owner-a';
    preview = false;
    generation = 0;
    repository = ZyraSignupDraftRepository(
      store: store,
      backend: 'https://example.invalid',
      currentUserId: () => owner,
      isPreview: () => preview,
      currentGeneration: () => generation,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    AppState.instance.resetForAccountChange();
  });

  tearDown(() {
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraText.useTestFontStubs = false;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    AppState.instance.resetForAccountChange();
  });

  test(
    'opaque intent survives form erasure, then signout erases both',
    () async {
      final intent = ZyraSignupMembershipIntent(
        role: ZyraSignupRole.seeker,
        choice: basic,
      );
      await repository.save(
        'owner-a',
        completed(ZyraSignupRole.seeker, choice: basic),
      );
      await repository.saveMembershipIntent('owner-a', intent);
      expect(
        repository.membershipIntentKeyFor('owner-a'),
        isNot(contains('owner-a')),
      );
      final encoded =
          store.values[repository.membershipIntentKeyFor('owner-a')]!;
      expect(encoded, isNot(contains('firstName')));
      expect(encoded, isNot(contains('dob')));
      expect(encoded, isNot(contains('paid')));
      await repository.clear('owner-a');
      expect(await repository.read('owner-a'), isNull);
      expect(
        (await repository.readMembershipIntent('owner-a'))?.toJson(),
        intent.toJson(),
      );
      var loggedOut = false;
      await repository.signOut('owner-a', () async => loggedOut = true);
      expect(loggedOut, isTrue);
      expect(store.values, isEmpty);
    },
  );

  test(
    'membership writes require confirmed readback and current owner',
    () async {
      final intent = ZyraSignupMembershipIntent(
        role: ZyraSignupRole.seeker,
        choice: basic,
      );
      store.discardWrite = true;
      await expectLater(
        repository.saveMembershipIntent('owner-a', intent),
        throwsStateError,
      );
      store.discardWrite = false;
      owner = 'owner-b';
      final count = store.operations;
      await expectLater(
        repository.saveMembershipIntent('owner-a', intent),
        throwsStateError,
      );
      await expectLater(
        repository.readMembershipIntent('owner-a'),
        throwsStateError,
      );
      expect(store.operations, count);
    },
  );

  test(
    'preview storage is denied rather than becoming ordinary signup',
    () async {
      preview = true;
      final intent = ZyraSignupMembershipIntent(
        role: ZyraSignupRole.guardian,
        choice: basic,
      );
      await expectLater(
        repository.saveMembershipIntent('owner-a', intent),
        throwsStateError,
      );
      await expectLater(
        repository.readMembershipIntent('owner-a'),
        throwsStateError,
      );
      expect(store.operations, 0);
    },
  );

  test('delayed intent read refuses same-owner epoch replacement', () async {
    final intent = ZyraSignupMembershipIntent(
      role: ZyraSignupRole.seeker,
      choice: basic,
    );
    await repository.saveMembershipIntent('owner-a', intent);
    store.readWait = Completer<void>();
    final read = repository.readMembershipIntent('owner-a');
    final failure = expectLater(read, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    generation++;
    store.readWait!.complete();
    await failure;
  });

  Future<void> mount(WidgetTester tester, Widget child) async {
    if ((child is OnboardingFlow && !child.devPreview) ||
        (child is WaliOnboardingFlow && !child.devPreview)) {
      // SDK session persistence and account cleanup are real asynchronous
      // fixture work, not motion time. Complete them outside FakeAsync before
      // the ordinary route captures its owner/generation and restores Storage.
      await tester.runAsync(() async {
        String part(Object value) => base64Url
            .encode(utf8.encode(jsonEncode(value)))
            .replaceAll('=', '');
        await supabase.auth.setInitialSession(
          jsonEncode({
            'access_token':
                '${part({'alg': 'none'})}.${part({'sub': 'owner-a', 'exp': 4102444800})}.synthetic',
            'token_type': 'bearer',
            'refresh_token': 'synthetic-refresh',
            'user': {
              'id': 'owner-a',
              'app_metadata': {'provider': 'google'},
              'user_metadata': <String, Object?>{},
              'aud': 'authenticated',
              'email': 'synthetic@example.invalid',
              'created_at': '2026-10-04T00:00:00Z',
            },
          }),
        );
        await ZyraAccountState.synchronize('owner-a');
      });
    }
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: child));
    if (child is OnboardingFlow && !child.devPreview) {
      await tester.runAsync(() async {
        // A real mocked Storage response must settle before pumping entrance
        // frames; do not loosen the production photo/owner validation.
        await ZyraPhotoService.signupPhotoUrl(
          'owner-a/first.jpg',
          expectedUserId: 'owner-a',
          expectedGeneration: ZyraAccountState.generation,
        );
      });
    }
    await tester.pumpAndSettle();
  }

  for (final role in ZyraSignupRole.values) {
    testWidgets(
      '${role.name} complete form shows separate required Membership choice',
      (tester) async {
        await mount(
          tester,
          role == ZyraSignupRole.seeker
              ? OnboardingFlow(
                  signupUserId: 'owner-a',
                  initialDraft: completed(role),
                )
              : WaliOnboardingFlow(
                  signupUserId: 'owner-a',
                  initialDraft: completed(role),
                ),
        );
        expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
        expect(find.byType(InitialIdentityCheckScreen), findsNothing);
        final scaffold = tester.widget<OnboardingScaffold>(
          find.byType(OnboardingScaffold),
        );
        expect(scaffold.chapterName, 'Membership');
        expect(scaffold.progressLabel, 'YOUR MEMBERSHIP CHOICE');
        expect(scaffold.fabActive, isFalse);
        expect(
          find.text(
            role == ZyraSignupRole.seeker ? 'Seeker Basic' : 'Guardian Basic',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('signup_membership_basic')));
        await tester.pump();
        expect(
          tester
              .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
              .fabActive,
          isTrue,
        );
        expect(AppState.instance.plan, ZyraPlan.basic);
        expect(AppState.instance.waliHasWaliOne, isFalse);
        expect(
          store.operations,
          0,
          reason: 'Selecting a card alone saves nothing or grants access.',
        );
      },
    );

    testWidgets(
      '${role.name} protected walkthrough reaches choice then IDV without storage',
      (tester) async {
        ZyraDeveloperAccess.setAuthorizedForTesting(true);
        ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
        ZyraInternalPreviewClient.beginPreview();
        await mount(
          tester,
          role == ZyraSignupRole.seeker
              ? const OnboardingFlow(devPreview: true)
              : const WaliOnboardingFlow(devPreview: true),
        );
        if (role == ZyraSignupRole.seeker) {
          tester
              .widget<OnboardingStageIntroScreen>(
                find.byType(OnboardingStageIntroScreen),
              )
              .onContinue();
          await tester.pumpAndSettle();
        }
        for (var index = 0; index < completed(role).questionCount; index++) {
          await advanceSignupQuestionFromCode(tester);
          await tester.pumpAndSettle();
        }
        expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('signup_membership_one')));
        await tester.pump();
        expect(AppState.instance.plan, ZyraPlan.basic);
        expect(AppState.instance.waliHasWaliOne, isFalse);
        tester
            .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
            .onContinue!();
        await tester.pumpAndSettle();
        expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
        expect(store.operations, 0);
        expect(AppState.instance.plan, ZyraPlan.basic);
        expect(AppState.instance.waliHasWaliOne, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final role in ZyraSignupRole.values) {
    for (final isPreview in [false, true]) {
      testWidgets(
        '${role.name} introductory offer stays in the protected Seeker preview $isPreview',
        (tester) async {
          await mount(
            tester,
            SignupMembershipChoiceScreen(
              role: role,
              choice: null,
              devPreview: isPreview,
              onChanged: (_) {},
              onContinue: () {},
              onBack: () {},
            ),
          );
          final offer = isPreview && role == ZyraSignupRole.seeker;
          expect(
            find.text('£4.99 first month'),
            offer ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('signup_membership_renewal')),
            offer ? findsOneWidget : findsNothing,
          );
          if (offer) {
            expect(
              find.text('Then £29.99/month. Cancel renewal anytime.'),
              findsOneWidget,
            );
            expect(find.textContaining('14-day'), findsNothing);
          } else if (role == ZyraSignupRole.seeker) {
            expect(find.text('£29.99 / month'), findsOneWidget);
            expect(find.textContaining('14-day'), findsOneWidget);
          } else {
            expect(find.text('£19.99 / month'), findsOneWidget);
          }
          expect(
            find.byKey(const ValueKey('signup_membership_try_one')),
            findsNothing,
          );
          expect(AppState.instance.plan, ZyraPlan.basic);
          expect(AppState.instance.waliHasWaliOne, isFalse);
          expect(store.operations, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Basic stays chosen until the explicit One suggestion is pressed',
    (tester) async {
      ZyraSignupMembershipChoice? choice;
      ZyraSignupMembershipChoice? continued;
      var changes = 0;
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SignupMembershipChoiceScreen(
            role: ZyraSignupRole.seeker,
            choice: choice,
            devPreview: true,
            onChanged: (value) => setState(() {
              changes++;
              choice = value;
            }),
            onContinue: () => continued = choice,
            onBack: () {},
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('signup_membership_basic')));
      await tester.pumpAndSettle();
      expect(choice?.kind, ZyraSignupMembershipKind.basic);
      expect(changes, 1);
      expect(find.text('Same starting price as Basic'), findsOneWidget);
      tester
          .widget<SignupMembershipChoiceScreen>(
            find.byType(SignupMembershipChoiceScreen),
          )
          .onContinue();
      expect(continued?.kind, ZyraSignupMembershipKind.basic);
      await tester.ensureVisible(
        find.byKey(const ValueKey('signup_membership_try_one')),
      );
      await tester.tap(find.byKey(const ValueKey('signup_membership_try_one')));
      await tester.pumpAndSettle();
      expect(choice?.kind, ZyraSignupMembershipKind.one);
      expect(changes, 2);
      expect(
        find.byKey(const ValueKey('signup_membership_try_one')),
        findsNothing,
      );
      expect(find.text('First month offer'), findsOneWidget);
      expect(AppState.instance.plan, ZyraPlan.basic);
      expect(AppState.instance.waliHasWaliOne, isFalse);
      expect(store.operations, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saving disables the offer suggestion and preserves Basic', (
    tester,
  ) async {
    var changes = 0;
    await mount(
      tester,
      SignupMembershipChoiceScreen(
        role: ZyraSignupRole.seeker,
        choice: basic,
        devPreview: true,
        saving: true,
        onChanged: (_) => changes++,
        onContinue: () {},
        onBack: () {},
      ),
    );
    final action = find.byKey(const ValueKey('signup_membership_try_one'));
    await tester.ensureVisible(action);
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(AppState.instance.plan, ZyraPlan.basic);
    expect(store.operations, 0);
    expect(tester.takeException(), isNull);
  });

  for (final role in ZyraSignupRole.values) {
    for (final isPreview in [false, true]) {
      testWidgets(
        '${role.name} Family first-month total and renewal stay separate in preview $isPreview',
        (tester) async {
          ZyraSignupMembershipChoice? choice;
          await mount(
            tester,
            StatefulBuilder(
              builder: (context, setState) => SignupMembershipChoiceScreen(
                role: role,
                devPreview: isPreview,
                choice: choice,
                onChanged: (value) => setState(() => choice = value),
                onContinue: () {},
                onBack: () {},
              ),
            ),
          );
          expect(
            find.text('£4.99 per person for the first month'),
            isPreview ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('signup_membership_family_renewal')),
            isPreview ? findsOneWidget : findsNothing,
          );
          final family = find.byKey(const ValueKey('signup_membership_family'));
          await tester.ensureVisible(family);
          await tester.tap(family);
          await tester.pumpAndSettle();
          expect(choice?.isValidFor(role), isTrue);
          if (isPreview) {
            expect(find.text('£4.99 first month total'), findsOneWidget);
            expect(find.text('1 person × £4.99'), findsOneWidget);
          }
          final otherRole = role == ZyraSignupRole.seeker
              ? 'guardians'
              : 'seekers';
          final add = find.byKey(ValueKey('signup_family_${otherRole}_add'));
          await tester.ensureVisible(add);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(choice?.seekers, 1);
          expect(choice?.guardians, 1);
          expect(
            find.text('£9.98 first month total'),
            isPreview ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('2 people × £4.99'),
            isPreview ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('${isPreview ? 'Then ' : ''}£49.98 / month estimate'),
            findsOneWidget,
          );
          // The usual bundle saving applies only to renewal, never month one.
          final addSeeker = find.byKey(
            const ValueKey('signup_family_seekers_add'),
          );
          await tester.ensureVisible(addSeeker);
          await tester.tap(addSeeker);
          await tester.pumpAndSettle();
          expect(
            find.text('£14.97 first month total'),
            isPreview ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('${isPreview ? 'Then ' : ''}£75.97 / month estimate'),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('signup_family_first_month_total')),
            isPreview ? findsOneWidget : findsNothing,
          );
          expect(AppState.instance.plan, ZyraPlan.basic);
          expect(AppState.instance.waliHasWaliOne, isFalse);
          expect(store.operations, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('saving disables Family count changes', (tester) async {
    var changes = 0;
    await mount(
      tester,
      SignupMembershipChoiceScreen(
        role: ZyraSignupRole.seeker,
        choice: const ZyraSignupMembershipChoice(
          kind: ZyraSignupMembershipKind.family,
          seekers: 2,
          guardians: 1,
        ),
        devPreview: true,
        saving: true,
        onChanged: (_) => changes++,
        onContinue: () {},
        onBack: () {},
      ),
    );
    for (final role in ['seekers', 'guardians']) {
      for (final action in ['add', 'remove']) {
        final button = find.byKey(ValueKey('signup_family_${role}_$action'));
        expect(tester.widget<IconButton>(button).onPressed, isNull);
      }
    }
    expect(changes, 0);
    expect(find.text('£14.97 first month total'), findsOneWidget);
    expect(AppState.instance.plan, ZyraPlan.basic);
    expect(AppState.instance.waliHasWaliOne, isFalse);
    expect(store.operations, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Family keeps the selected account role and permits zero other-role places',
    (tester) async {
      ZyraSignupMembershipChoice? choice;
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SignupMembershipChoiceScreen(
            role: ZyraSignupRole.guardian,
            choice: choice,
            onChanged: (value) => setState(() => choice = value),
            onContinue: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('signup_membership_family')),
      );
      await tester.tap(find.byKey(const ValueKey('signup_membership_family')));
      await tester.pump();
      expect(choice?.seekers, 0);
      expect(choice?.guardians, 1);
      await tester.ensureVisible(
        find.byKey(const ValueKey('signup_family_guardians_remove')),
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('signup_family_guardians_remove')),
            )
            .onPressed,
        isNull,
      );
      expect(choice?.isValidFor(ZyraSignupRole.guardian), isTrue);
      await tester.tap(find.byKey(const ValueKey('signup_family_seekers_add')));
      await tester.pump();
      expect(choice?.seekers, 1);
      expect(choice?.guardians, 1);
      expect(AppState.instance.waliHasWaliOne, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final role in ZyraSignupRole.values) {
    testWidgets(
      '${role.name} epoch replacement between saves cannot publish intent',
      (tester) async {
        repository = _EpochReplacingSignupRepository(
          store: store,
          backend: 'https://example.invalid',
          currentUserId: () => owner,
          isPreview: () => preview,
          currentGeneration: () => generation,
          replaceEpoch: () {
            ZyraAccountState.resetForTesting();
            generation++;
          },
        );
        ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
        await mount(
          tester,
          role == ZyraSignupRole.seeker
              ? OnboardingFlow(
                  signupUserId: 'owner-a',
                  initialDraft: completed(role),
                )
              : WaliOnboardingFlow(
                  signupUserId: 'owner-a',
                  initialDraft: completed(role),
                ),
        );
        tester
            .widget<SignupMembershipChoiceScreen>(
              find.byType(SignupMembershipChoiceScreen),
            )
            .onChanged(basic);
        await tester.pump();
        tester
            .widget<SignupMembershipChoiceScreen>(
              find.byType(SignupMembershipChoiceScreen),
            )
            .onContinue();
        await tester.pumpAndSettle();
        expect(store.operations, 2);
        expect(
          store.values.containsKey(
            repository.membershipIntentKeyFor('owner-a'),
          ),
          isFalse,
        );
        expect(find.byType(InitialIdentityCheckScreen), findsNothing);
        expect(AppState.instance.plan, ZyraPlan.basic);
        expect(AppState.instance.waliHasWaliOne, isFalse);
      },
    );

    testWidgets(
      '${role.name} stale same-account flow cannot save or publish a new choice',
      (tester) async {
        await mount(
          tester,
          role == ZyraSignupRole.seeker
              ? OnboardingFlow(
                  signupUserId: 'owner-a',
                  initialDraft: completed(role),
                )
              : WaliOnboardingFlow(
                  signupUserId: 'owner-a',
                  initialDraft: completed(role),
                ),
        );
        final screen = tester.widget<SignupMembershipChoiceScreen>(
          find.byType(SignupMembershipChoiceScreen),
        );
        screen.onChanged(basic);
        await tester.pump();
        final retainedContinue = tester
            .widget<SignupMembershipChoiceScreen>(
              find.byType(SignupMembershipChoiceScreen),
            )
            .onContinue;
        ZyraAccountState.resetForTesting();
        generation++;
        retainedContinue();
        screen.onChanged(
          const ZyraSignupMembershipChoice(kind: ZyraSignupMembershipKind.one),
        );
        await tester.pumpAndSettle();
        expect(store.operations, 0);
        expect(find.byType(InitialIdentityCheckScreen), findsNothing);
        expect(AppState.instance.plan, ZyraPlan.basic);
        expect(AppState.instance.waliHasWaliOne, isFalse);
      },
    );

    testWidgets(
      '${role.name} revoked preview cannot use retained membership callbacks',
      (tester) async {
        ZyraDeveloperAccess.setAuthorizedForTesting(true);
        ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
        ZyraInternalPreviewClient.beginPreview();
        await mount(
          tester,
          role == ZyraSignupRole.seeker
              ? const OnboardingFlow(devPreview: true)
              : const WaliOnboardingFlow(devPreview: true),
        );
        if (role == ZyraSignupRole.seeker) {
          tester
              .widget<OnboardingStageIntroScreen>(
                find.byType(OnboardingStageIntroScreen),
              )
              .onContinue();
          await tester.pumpAndSettle();
        }
        for (var index = 0; index < completed(role).questionCount; index++) {
          await advanceSignupQuestionFromCode(tester);
          await tester.pumpAndSettle();
        }
        final retained = tester.widget<SignupMembershipChoiceScreen>(
          find.byType(SignupMembershipChoiceScreen),
        );
        retained.onChanged(basic);
        await tester.pump();
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        retained.onContinue();
        expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
        retained.onChanged(
          const ZyraSignupMembershipChoice(kind: ZyraSignupMembershipKind.one),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            ValueKey(
              role == ZyraSignupRole.seeker
                  ? 'seeker_signup_preview_denied'
                  : 'guardian_signup_preview_denied',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byType(InitialIdentityCheckScreen), findsNothing);
        expect(store.operations, 0);
      },
    );
  }

  testWidgets(
    'failed secure choice save remains on Membership with retry message',
    (tester) async {
      store.rejectWrite = true;
      await mount(
        tester,
        OnboardingFlow(
          signupUserId: 'owner-a',
          initialDraft: completed(ZyraSignupRole.seeker),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('signup_membership_basic')));
      await tester.pump();
      tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .onContinue!();
      await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      expect(find.byType(InitialIdentityCheckScreen), findsNothing);
      expect(
        find.textContaining("couldn't save your progress securely"),
        findsOneWidget,
      );
    },
  );
}
