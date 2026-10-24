// Ordinary Guardian rendered linked-summary controls. Synthetic transport only.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/wali/wali_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _a = '00000000-0000-4000-8000-000000003341';
const _b = '00000000-0000-4000-8000-000000003342';
const _people = <WaliLinkedPerson>[
  WaliLinkedPerson(
    id: 'synthetic-a',
    firstName: 'Synthetic',
    relationship: 'father',
  ),
];
const _replacementPeople = <WaliLinkedPerson>[
  WaliLinkedPerson(
    id: 'synthetic-b1',
    firstName: 'Synthetic',
    relationship: 'brother',
  ),
  WaliLinkedPerson(
    id: 'synthetic-b2',
    firstName: 'Synthetic',
    relationship: 'brother',
  ),
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
  var linkReads = 0;
  var entitlementReads = 0;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://generated.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/rest/v1/rpc/wali_has_wali_one') {
          entitlementReads++;
          return http.Response(
            'false',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        unexpected.add('${request.method} ${request.url.path}');
        throw StateError(
          'Unexpected synthetic Guardian linked-summary transport.',
        );
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
    linkReads = 0;
    entitlementReads = 0;
    await _session(_a);
  });
  tearDown(() {
    expect(unexpected, isEmpty);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() => Supabase.instance.dispose());

  Finder value(String label, String expected) {
    final key = find.descendant(
      of: find.byType(WaliProfileScreen),
      matching: find.text(label),
    );
    return find.descendant(
      of: find.ancestor(of: key, matching: find.byType(Row)).first,
      matching: find.text(expected),
    );
  }

  void summary(String relationship, String count) {
    expect(value('Relationship', relationship), findsOneWidget);
    expect(value('Linked Seekers', count), findsOneWidget);
  }

  Future<void> mount(
    WidgetTester tester,
    Future<ZyraSourceResult<List<WaliLinkedPerson>>> Function() load,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaliProfileScreen(
            loadLinkedSeekers: () {
              linkReads++;
              return load();
            },
          ),
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

  void noExtraReads(WidgetTester tester) {
    expect(linkReads, 1);
    expect(entitlementReads, 1);
    expect(tester.takeException(), isNull);
  }

  for (final returnToA in [false, true]) {
    final change = returnToA ? 'A-B-A' : 'A-B';
    testWidgets(
      'loaded Guardian summary withdraws after $change without remount',
      (tester) async {
        await mount(
          tester,
          () async => const ZyraSourceResult.available(_people),
        );
        summary('Father', '1');
        final state = tester.state(find.byType(WaliProfileScreen));
        await replaceOwner(tester, returnToA);
        expect(tester.state(find.byType(WaliProfileScreen)), same(state));
        summary('Unavailable', 'Unavailable');
        expect(value('Relationship', '—'), findsNothing);
        expect(value('Linked Seekers', '0'), findsNothing);
        noExtraReads(tester);
      },
    );

    testWidgets(
      'pending Guardian summary withdraws before late $change reply',
      (tester) async {
        final release = Completer<ZyraSourceResult<List<WaliLinkedPerson>>>();
        try {
          await mount(tester, () => release.future);
          summary('Checking…', 'Checking…');
          await replaceOwner(tester, returnToA);
          summary('Unavailable', 'Unavailable');
          AppState.instance.setWaliRealLinkedSeekers(_replacementPeople);
          await tester.pumpAndSettle();
          summary('Unavailable', 'Unavailable');
        } finally {
          release.complete(const ZyraSourceResult.available(_people));
          await tester.pumpAndSettle();
        }
        summary('Unavailable', 'Unavailable');
        expect(AppState.instance.waliRealLinkedSeekers, _replacementPeople);
        noExtraReads(tester);
      },
    );

    testWidgets(
      'retired Guardian route refuses later shared data after $change',
      (tester) async {
        await mount(
          tester,
          () async => const ZyraSourceResult.available(_people),
        );
        summary('Father', '1');
        await replaceOwner(tester, returnToA);
        AppState.instance.setWaliRealLinkedSeekers(_replacementPeople);
        await tester.pumpAndSettle();
        expect(AppState.instance.waliRealLinkedSeekers, _replacementPeople);
        summary('Unavailable', 'Unavailable');
        expect(value('Relationship', 'Brother'), findsNothing);
        expect(value('Linked Seekers', '2'), findsNothing);
        noExtraReads(tester);
      },
    );
  }

  testWidgets(
    'current Guardian confirmed empty retains zero and unrecorded relationship',
    (tester) async {
      await mount(
        tester,
        () async => const ZyraSourceResult.available(<WaliLinkedPerson>[]),
      );
      summary('—', '0');
      expect(value('Linked Seekers', 'Unavailable'), findsNothing);
      noExtraReads(tester);
    },
  );

  testWidgets(
    'current Guardian unavailable linked read is not confirmed empty',
    (tester) async {
      await mount(
        tester,
        () async =>
            const ZyraSourceResult.unavailable(ZyraSourceFailure.requestFailed),
      );
      summary('Unavailable', 'Unavailable');
      expect(value('Linked Seekers', '0'), findsNothing);
      noExtraReads(tester);
    },
  );

  testWidgets('current Guardian pending linked read resolves to owned data', (
    tester,
  ) async {
    final release = Completer<ZyraSourceResult<List<WaliLinkedPerson>>>();
    try {
      await mount(tester, () => release.future);
      summary('Checking…', 'Checking…');
    } finally {
      release.complete(const ZyraSourceResult.available(_people));
      await tester.pumpAndSettle();
    }
    summary('Father', '1');
    noExtraReads(tester);
  });

  testWidgets(
    'same Guardian lifetime retains legitimate shared linked updates',
    (tester) async {
      await mount(
        tester,
        () async => const ZyraSourceResult.available(_people),
      );
      final generation = ZyraAccountState.generation;
      await tester.runAsync(() => _session(_a));
      AppState.instance.setWaliRealLinkedSeekers(_replacementPeople);
      await tester.pumpAndSettle();
      expect(ZyraAccountState.generation, generation);
      summary('Brother', '2');
      noExtraReads(tester);
    },
  );

  testWidgets('throwing Guardian linked loader is unavailable', (tester) async {
    await mount(tester, () async => throw StateError('Synthetic unavailable'));
    summary('Unavailable', 'Unavailable');
    noExtraReads(tester);
  });

  testWidgets('held Guardian linked reply is harmless after Profile disposal', (
    tester,
  ) async {
    final release = Completer<ZyraSourceResult<List<WaliLinkedPerson>>>();
    try {
      await mount(tester, () => release.future);
      summary('Checking…', 'Checking…');
      await tester.pumpWidget(const SizedBox.shrink());
      await replaceOwner(tester, false);
    } finally {
      release.complete(const ZyraSourceResult.available(_people));
      await tester.pumpAndSettle();
    }
    expect(find.byType(WaliProfileScreen), findsNothing);
    expect(AppState.instance.waliRealLinkedSeekers, isEmpty);
    noExtraReads(tester);
  });
}
