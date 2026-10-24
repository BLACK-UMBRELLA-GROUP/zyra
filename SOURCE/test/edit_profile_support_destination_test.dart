// OA304: fixed identity fields lead to useful support, never a hidden writer.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _supportKey = ValueKey('edit_profile_open_support');
const _screenKey = ValueKey('edit-profile-support-owner');

class _Repository implements ZyraCompatibilityEditorRepository {
  @override
  String? currentUserId = 'editor-owner-a';
  @override
  int accountGeneration = 1;
  int loads = 0;
  int saves = 0;

  @override
  bool isCurrentOwner(String userId, int generation) =>
      userId == currentUserId && generation == accountGeneration;

  @override
  Future<ZyraOnboardingAnswersSnapshot?> load(String userId) async {
    loads++;
    expect(userId, 'editor-owner-a');
    return null;
  }

  @override
  Future<bool> save(String userId, ZyraCompatibilityDraft draft) async {
    saves++;
    return true;
  }
}

class _Owner {
  bool allowed = true;
  bool canAct() => allowed;
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Support destination tests must remain offline.');
  }
}

Widget _app(
  Widget screen, {
  GlobalKey<NavigatorState>? navigator,
  bool compact = false,
}) => MaterialApp(
  navigatorKey: navigator,
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(compact ? 2 : 1)),
    child: child!,
  ),
  home: Scaffold(body: screen),
);

Future<void> _mount(
  WidgetTester tester,
  _Repository repository, {
  _Owner? owner,
  VoidCallback? onSupport,
  GlobalKey<NavigatorState>? navigator,
  bool compact = false,
}) async {
  tester.view.physicalSize = compact
      ? const Size(320, 568)
      : const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(
      owner == null
          ? EditProfileScreen(key: _screenKey, repository: repository)
          : EditProfileScreen.preview(
              key: _screenKey,
              repository: repository,
              canAct: owner.canAct,
              gender: 'female',
              age: 29,
              onSupport: onSupport,
            ),
      navigator: navigator,
      compact: compact,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final scroll = find.descendant(
    of: find.byKey(const ValueKey('edit_profile_content_scroll')),
    matching: find.byType(Scrollable),
  );
  expect(scroll, findsOneWidget);
  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: scroll,
    maxScrolls: 30,
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

VoidCallback _action(WidgetTester tester) =>
    tester.widget<TextButton>(find.byKey(_supportKey)).onPressed!;

void _noOrdinarySupport() {
  expect(find.byType(HelpSupportScreen), findsNothing);
  expect(
    find.byKey(const ValueKey('support-safety-case-status')),
    findsNothing,
  );
  expect(find.byKey(const ValueKey('help-support-email-action')), findsNothing);
  expect(
    find.byKey(const ValueKey('help-support-signed-in-line')),
    findsNothing,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldHttp = HttpOverrides.current;
  final requests = <http.Request>[];
  final telemetry = ZyraProductTelemetry.instance;
  const nativeChannels = [
    MethodChannel('plugins.flutter.io/url_launcher'),
    MethodChannel('plugins.flutter.io/url_launcher_ios'),
    MethodChannel('dev.fluttercommunity.plus/package_info'),
  ];
  late _NoNetwork network;
  late List<Object?> beforeMember;
  var nativeCalls = 0;

  List<Object?> memberState() => [
    AppState.instance.name,
    AppState.instance.gender,
    AppState.instance.dob,
    AppState.instance.location,
    AppState.instance.journeyBio,
    AppState.instance.plan,
    List.of(AppState.instance.photos),
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
  ];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'edit-support-sentinel': 'keep'});
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        throw StateError('No server operation belongs to this route test.');
      }),
    );
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.finishSignOut();
    telemetry.resetForTest();
    requests.clear();
    nativeCalls = 0;
    network = _NoNetwork();
    HttpOverrides.global = network;
    beforeMember = memberState();
    for (final channel in nativeChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            nativeCalls++;
            return null;
          });
    }
  });

  tearDown(() async {
    try {
      expect(network.attempts, 0);
      expect(requests, isEmpty);
      expect(nativeCalls, 0);
      expect(memberState(), beforeMember);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('edit-support-sentinel'), 'keep');
    } finally {
      HttpOverrides.global = oldHttp;
      ZyraInternalPreviewClient.finishSignOut();
      telemetry.resetForTest();
      ZyraText.useTestFontStubs = false;
      for (final channel in nativeChannels) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    }
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets('ordinary fixed identity explanation opens real existing Help', (
    tester,
  ) async {
    final repository = _Repository();
    await _mount(tester, repository);
    await _reveal(tester, find.byKey(_supportKey));
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('cannot be edited here'), findsOneWidget);
    await tester.tap(find.byKey(_supportKey));
    await tester.pumpAndSettle();
    expect(find.byType(HelpSupportScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('support-safety-case-status')),
      findsOneWidget,
    );
    expect(telemetry.snapshot.sessionEventCount, 1);
    expect(repository.loads, 1);
    expect(repository.saves, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  for (final aba in [false, true]) {
    testWidgets(
      'ordinary saved Support action denies ${aba ? 'ABA' : 'replacement'} owner',
      (tester) async {
        final repository = _Repository();
        await _mount(tester, repository);
        await _reveal(tester, find.byKey(_supportKey));
        final action = _action(tester);
        repository.currentUserId = 'editor-owner-b';
        repository.accountGeneration++;
        if (aba) {
          repository.currentUserId = 'editor-owner-a';
          repository.accountGeneration++;
        }
        action();
        await tester.pumpAndSettle();
        _noOrdinarySupport();
        expect(repository.saves, 0);
        expect(telemetry.snapshot.sessionEventCount, 0);
      },
    );
  }

  for (final preview in [false, true]) {
    testWidgets(
      '${preview ? 'preview' : 'ordinary'} covered Support action is inert and survives return',
      (tester) async {
        final repository = _Repository();
        final navigator = GlobalKey<NavigatorState>();
        final owner = _Owner();
        var calls = 0;
        void support() => calls++;
        await _mount(
          tester,
          repository,
          owner: preview ? owner : null,
          onSupport: support,
          navigator: navigator,
        );
        await _reveal(tester, find.byKey(_supportKey));
        final action = _action(tester);
        unawaited(
          navigator.currentState!.push<void>(
            MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Cover')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        action();
        await tester.pumpAndSettle();
        _noOrdinarySupport();
        expect(calls, 0);
        expect(telemetry.snapshot.sessionEventCount, 0);
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        await _reveal(tester, find.byKey(_supportKey));
        await tester.tap(find.byKey(_supportKey));
        await tester.pumpAndSettle();
        if (preview) {
          expect(calls, 1);
          _noOrdinarySupport();
          expect(telemetry.snapshot.sessionEventCount, 0);
        } else {
          expect(find.byType(HelpSupportScreen), findsOneWidget);
        }
        expect(repository.saves, 0);
      },
    );
  }

  testWidgets('explicit preview invokes only supplied caller-owned support', (
    tester,
  ) async {
    final repository = _Repository();
    final owner = _Owner();
    var calls = 0;
    void support() => calls++;
    await _mount(tester, repository, owner: owner, onSupport: support);
    await _reveal(tester, find.byKey(_supportKey));
    await tester.tap(find.byKey(_supportKey));
    await tester.pumpAndSettle();
    expect(calls, 1);
    _noOrdinarySupport();
    expect(repository.saves, 0);
    expect(telemetry.snapshot.sessionEventCount, 0);
  });

  testWidgets('preview without a caller destination exposes no fake action', (
    tester,
  ) async {
    final repository = _Repository();
    await _mount(tester, repository, owner: _Owner());
    await _reveal(tester, find.textContaining('cannot be edited here'));
    expect(find.byKey(_supportKey), findsNothing);
    expect(find.text('Open Help & support'), findsNothing);
    _noOrdinarySupport();
    expect(repository.saves, 0);
    expect(telemetry.snapshot.sessionEventCount, 0);
  });

  testWidgets('replacing a preview Support callback revokes its old binding', (
    tester,
  ) async {
    final repository = _Repository();
    final owner = _Owner();
    var oldCalls = 0;
    var newCalls = 0;
    void oldSupport() => oldCalls++;
    void newSupport() => newCalls++;
    await _mount(tester, repository, owner: owner, onSupport: oldSupport);
    await _reveal(tester, find.byKey(_supportKey));
    final action = _action(tester);
    await tester.pumpWidget(
      _app(
        EditProfileScreen.preview(
          key: _screenKey,
          repository: repository,
          canAct: owner.canAct,
          gender: 'female',
          age: 29,
          onSupport: newSupport,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('edit_profile_preview_denied')),
      findsOneWidget,
    );
    action();
    await tester.pumpAndSettle();
    expect(oldCalls, 0);
    expect(newCalls, 0);
    _noOrdinarySupport();
    expect(repository.saves, 0);
    expect(telemetry.snapshot.sessionEventCount, 0);
  });

  testWidgets(
    'preview denied Support callback stays inert after owner returns',
    (tester) async {
      final repository = _Repository();
      final owner = _Owner();
      var calls = 0;
      void support() => calls++;
      await _mount(tester, repository, owner: owner, onSupport: support);
      await _reveal(tester, find.byKey(_supportKey));
      final action = _action(tester);
      owner.allowed = false;
      action();
      owner.allowed = true;
      action();
      await tester.pumpAndSettle();
      expect(calls, 0);
      _noOrdinarySupport();
      expect(repository.saves, 0);
      expect(telemetry.snapshot.sessionEventCount, 0);
    },
  );

  for (final initiallyPreview in [false, true]) {
    testWidgets(
      'Support mode binding refuses ${initiallyPreview ? 'preview-to-ordinary' : 'ordinary-to-preview'} and return',
      (tester) async {
        final repository = _Repository();
        final owner = _Owner();
        var calls = 0;
        void support() => calls++;
        Widget screen(bool preview) => preview
            ? EditProfileScreen.preview(
                key: _screenKey,
                repository: repository,
                canAct: owner.canAct,
                gender: 'female',
                age: 29,
                onSupport: support,
              )
            : EditProfileScreen(key: _screenKey, repository: repository);
        await _mount(
          tester,
          repository,
          owner: initiallyPreview ? owner : null,
          onSupport: support,
        );
        await _reveal(tester, find.byKey(_supportKey));
        final action = _action(tester);
        await tester.pumpWidget(_app(screen(!initiallyPreview)));
        await tester.pumpAndSettle();
        action();
        await tester.pumpAndSettle();
        _noOrdinarySupport();
        await tester.pumpWidget(_app(screen(initiallyPreview)));
        await tester.pumpAndSettle();
        action();
        await tester.pumpAndSettle();
        expect(calls, 0);
        _noOrdinarySupport();
        expect(repository.saves, 0);
        expect(telemetry.snapshot.sessionEventCount, 0);
      },
    );
  }

  testWidgets('disposed preview Support callback cannot invoke its caller', (
    tester,
  ) async {
    final repository = _Repository();
    final owner = _Owner();
    var calls = 0;
    void support() => calls++;
    await _mount(tester, repository, owner: owner, onSupport: support);
    await _reveal(tester, find.byKey(_supportKey));
    final action = _action(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    action();
    await tester.pumpAndSettle();
    expect(calls, 0);
    _noOrdinarySupport();
    expect(repository.saves, 0);
    expect(telemetry.snapshot.sessionEventCount, 0);
  });

  testWidgets(
    'legacy local preview cannot fall through into ordinary support',
    (tester) async {
      ZyraInternalPreviewClient.beginPreview();
      final repository = _Repository();
      await _mount(tester, repository);
      await _reveal(tester, find.textContaining('cannot be edited here'));
      expect(find.byKey(_supportKey), findsNothing);
      _noOrdinarySupport();
      expect(repository.loads, 0);
      expect(repository.saves, 0);
      expect(telemetry.snapshot.sessionEventCount, 0);
    },
  );

  for (final preview in [false, true]) {
    testWidgets(
      '${preview ? 'preview' : 'ordinary'} compact200 Support is reachable and identity remains fixed',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final repository = _Repository();
          final owner = _Owner();
          var calls = 0;
          void support() => calls++;
          await _mount(
            tester,
            repository,
            owner: preview ? owner : null,
            onSupport: support,
            compact: true,
          );
          await _reveal(tester, find.byKey(_supportKey));
          final bounds = tester.getRect(find.byKey(_supportKey));
          expect(bounds.width, greaterThanOrEqualTo(44));
          expect(bounds.height, greaterThanOrEqualTo(48));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(320));
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(bounds.bottom, lessThanOrEqualTo(568));
          expect(
            tester
                .getSemantics(find.byKey(_supportKey))
                .flagsCollection
                .isButton,
            isTrue,
          );
          expect(find.byType(TextField), findsNothing);
          expect(find.byType(TextFormField), findsNothing);
          await tester.tap(find.byKey(_supportKey));
          await tester.pumpAndSettle();
          if (preview) {
            expect(calls, 1);
            _noOrdinarySupport();
          } else {
            expect(find.byType(HelpSupportScreen), findsOneWidget);
          }
          expect(repository.saves, 0);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
