// Ordinary linked-summary lifetime controls; all reads and transport synthetic.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/settings/settings_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-4000-8000-000000003331';
const _b = '00000000-0000-4000-8000-000000003332';
const _people = <WaliLinkedPerson>[
  WaliLinkedPerson(id: 'synthetic-link', firstName: 'Synthetic', isMain: true),
];

Future<void> _session(String id) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': id,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-16T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final unexpected = <String>[];
  var reads = 0;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://generated.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        unexpected.add('${request.method} ${request.url.path}');
        throw StateError('Unexpected synthetic linked-summary transport.');
      }),
    );
  });
  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    AppState.instance.resetForAccountChange();
    unexpected.clear();
    reads = 0;
    await _session(_a);
  });
  tearDown(() {
    expect(unexpected, isEmpty);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() => Supabase.instance.dispose());

  Finder value(bool guardian, String label) {
    final key = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.text(guardian ? 'Linked Seekers' : 'Guardians'),
    );
    return find.descendant(
      of: find.ancestor(of: key, matching: find.byType(Row)).first,
      matching: find.text(label),
    );
  }

  Future<void> mount(
    WidgetTester tester,
    bool guardian,
    Future<ZyraSourceResult<List<WaliLinkedPerson>>> Function() load,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          guardian: guardian,
          loadLinkedPeople: (asWali) {
            expect(asWali, guardian);
            reads++;
            return load();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
    expect(ZyraDeveloperAccess.isMainAppFounderPreview, isFalse);
  }

  Future<void> replaceOwner(WidgetTester tester, bool returnToA) async {
    final generation = ZyraAccountState.generation;
    await tester.runAsync(() async {
      await _session(_b).timeout(const Duration(seconds: 5));
      if (returnToA) await _session(_a).timeout(const Duration(seconds: 5));
    });
    await tester.pump();
    expect(ZyraAccountState.generation, greaterThan(generation));
  }

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    final linked = guardian ? '1 linked' : '1 linked · 1 Main';

    for (final returnToA in [false, true]) {
      final change = returnToA ? 'A-B-A' : 'A-B';
      testWidgets('$role loaded linked summary withdraws on $change', (
        tester,
      ) async {
        await mount(
          tester,
          guardian,
          () async => const ZyraSourceResult.available(_people),
        );
        expect(value(guardian, linked), findsOneWidget);
        final state = tester.state(find.byType(SettingsScreen));
        await replaceOwner(tester, returnToA);
        expect(tester.state(find.byType(SettingsScreen)), same(state));
        expect(value(guardian, 'Unavailable'), findsOneWidget);
        expect(value(guardian, linked), findsNothing);
        expect(reads, 1);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '$role pending linked summary withdraws before late $change reply',
        (tester) async {
          final release = Completer<ZyraSourceResult<List<WaliLinkedPerson>>>();
          try {
            await mount(tester, guardian, () => release.future);
            expect(value(guardian, 'Checking…'), findsOneWidget);
            await replaceOwner(tester, returnToA);
            expect(value(guardian, 'Unavailable'), findsOneWidget);
            expect(value(guardian, 'Checking…'), findsNothing);
          } finally {
            release.complete(const ZyraSourceResult.available(_people));
            await tester.pumpAndSettle();
          }
          expect(value(guardian, 'Unavailable'), findsOneWidget);
          expect(value(guardian, linked), findsNothing);
          expect(reads, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('$role current-owner confirmed empty is None linked', (
      tester,
    ) async {
      await mount(
        tester,
        guardian,
        () async => const ZyraSourceResult.available(<WaliLinkedPerson>[]),
      );
      expect(value(guardian, 'None linked'), findsOneWidget);
      expect(value(guardian, 'Unavailable'), findsNothing);
      expect(reads, 1);
    });

    testWidgets('$role unavailable read is not confirmed empty', (
      tester,
    ) async {
      await mount(
        tester,
        guardian,
        () async =>
            const ZyraSourceResult.unavailable(ZyraSourceFailure.requestFailed),
      );
      expect(value(guardian, 'Unavailable'), findsOneWidget);
      expect(value(guardian, 'None linked'), findsNothing);
      expect(reads, 1);
    });

    testWidgets('$role same-owner valid summary survives notification', (
      tester,
    ) async {
      await mount(
        tester,
        guardian,
        () async => const ZyraSourceResult.available(_people),
      );
      final generation = ZyraAccountState.generation;
      await tester.runAsync(() => _session(_a));
      AppState.instance.setPlan(AppState.instance.plan);
      await tester.pumpAndSettle();
      expect(ZyraAccountState.generation, generation);
      expect(value(guardian, linked), findsOneWidget);
      expect(value(guardian, 'Unavailable'), findsNothing);
      expect(reads, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$role held linked reply is harmless after disposal', (
      tester,
    ) async {
      final release = Completer<ZyraSourceResult<List<WaliLinkedPerson>>>();
      await mount(tester, guardian, () => release.future);
      expect(value(guardian, 'Checking…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await replaceOwner(tester, false);
      release.complete(const ZyraSourceResult.available(_people));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
      expect(reads, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
