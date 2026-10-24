import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/connections/connections_screen.dart';
import 'package:zyra/screens/connections/connections_section_controller.dart';
import 'package:zyra/screens/matches/journey_timeline_screen.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_guardian_suggestion_service.dart';
import 'package:zyra/services/zyra_match_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _person = SeekerProfile(
  id: 'seeker',
  firstName: 'Aaliyah',
  age: 27,
  city: 'London',
  photos: [],
  gender: 'female',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (request) async => http.Response(
          '[]',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    AppState.instance.resetForAccountChange();
    AppState.instance.plan = ZyraPlan.one;
  });
  tearDown(() {
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
  });

  test('signed-out Timeline and introduction reads are unavailable', () async {
    expect(
      (await ZyraMatchService.fetchTimelineResult('seeker')).isUnavailable,
      true,
    );
    expect(
      (await ZyraGuardianSuggestionService.fetchPendingResult()).isUnavailable,
      true,
    );
  });

  testWidgets(
    'failed Timeline never claims there is no story and retries to empty truth',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: JourneyTimelineScreen(
            withProfile: _person,
            loadContext: (_) async => const ZyraTimelineContext(),
            loadTimeline: (_) async => ++calls == 1
                ? const ZyraSourceResult.unavailable(
                    ZyraSourceFailure.requestFailed,
                  )
                : const ZyraSourceResult.available([]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t load your timeline'), findsOneWidget);
      expect(find.textContaining('No story yet'), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No story yet'), findsOneWidget);
      expect(find.text('Couldn’t load your timeline'), findsNothing);
    },
  );

  testWidgets('throwing Timeline load exits its spinner with a retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyTimelineScreen(
          withProfile: _person,
          loadContext: (_) async => const ZyraTimelineContext(),
          loadTimeline: (_) async => throw StateError('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t load your timeline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed introductions load shows retry rather than empty and recovers',
    (tester) async {
      final controller = ZyraConnectionsSectionController(
        initialSection: ZyraConnectionsSection.introductions,
      );
      addTearDown(controller.dispose);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionsScreen(
              sectionController: controller,
              loadSuggestions: () async => ++calls == 1
                  ? const ZyraSourceResult.unavailable(
                      ZyraSourceFailure.requestFailed,
                    )
                  : const ZyraSourceResult.available([]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t load introductions'), findsOneWidget);
      expect(find.text('No introductions yet'), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No introductions yet'), findsOneWidget);
    },
  );

  testWidgets(
    'failed introductions refresh retains confirmed rows and attribution',
    (tester) async {
      final controller = ZyraConnectionsSectionController(
        initialSection: ZyraConnectionsSection.introductions,
      );
      addTearDown(controller.dispose);
      var fail = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionsScreen(
              sectionController: controller,
              loadSuggestions: () async => fail
                  ? const ZyraSourceResult.unavailable(
                      ZyraSourceFailure.requestFailed,
                    )
                  : const ZyraSourceResult.available([
                      GuardianSuggestion(
                        profile: _person,
                        suggestedBy: 'Abdul',
                      ),
                    ]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Aaliyah'), findsWidgets);
      expect(AppState.instance.suggestedBy('seeker'), 'Abdul');
      fail = true;
      AppState.instance.bumpSuggestions();
      await tester.pumpAndSettle();
      expect(find.textContaining('Aaliyah'), findsWidgets);
      expect(
        find.text(
          'Introductions could not refresh. Showing last confirmed information.',
        ),
        findsOneWidget,
      );
      expect(AppState.instance.suggestedBy('seeker'), 'Abdul');
    },
  );

  testWidgets(
    'Guardian Circle send preserves newer draft typed while pending',
    (tester) async {
      ZyraDevScenario.instance.reset();
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      addTearDown(() {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        ZyraDevScenario.instance.reset();
      });
      await tester.pumpWidget(
        const MaterialApp(
          home: ZyraGuardianCircleScreen(
            seekerId: 'preview-seeker',
            seekerFirstName: 'Aaliyah',
            preview: true,
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'First message');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.enterText(find.byType(TextField), 'Next draft');
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('First message'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Next draft',
      );
    },
  );
}
