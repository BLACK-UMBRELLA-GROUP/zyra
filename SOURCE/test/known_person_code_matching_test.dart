import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_personal_code_fixtures.dart';
import 'package:zyra/screens/browse/find_by_zyra_code_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInteractionStyle.restoreDefaults();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(name: 'Adam', gender: 'male');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    AppState.instance.resetForAccountChange();
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('known-person code confirms identity then sends Consider', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: FindByZyraCodeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Tap to scan their code'), findsOneWidget);
    expect(
      find.text('Scan or enter their ZYRA Code to find their profile.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('local-code-field')),
      ZyraDevPersonalCodeFixtures.validKnownPersonEntryCode(
        currentGender: 'male',
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('local-code-check')));
    await tester.tap(find.byKey(const ValueKey('local-code-check')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Maryam'), findsOneWidget);
    expect(find.text('27 · Birmingham'), findsNothing);
    expect(find.text('Seeker · first name and role only'), findsOneWidget);
    expect(find.text('Consider'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('known-person-consider')),
    );

    await tester.tap(find.byKey(const ValueKey('known-person-consider')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Interest sent'), findsOneWidget);
    expect(find.textContaining('normal ZYRA matching rules'), findsOneWidget);
  });

  test('staged RPC keeps known-person matching behind every hard gate', () {
    final sql = File(
      'supabase/migrations/'
      '20260918145126_oa295_known_person_code_matching.sql',
    ).readAsStringSync();

    expect(sql, contains('STAGED ONLY'));
    expect(sql, contains("c.role_context = 'seeker'"));
    expect(sql, contains('private.zyra_identity_verification_allows_user'));
    expect(sql, contains('public.zyra_can_view_profile(v_owner)'));
    expect(sql, contains('public.zyra_can_match(v_me, v_owner)'));
    expect(sql, contains('on conflict (liker_id, liked_id) do nothing'));
    expect(
      sql,
      contains(
        'does not create a Match without an existing reciprocal Consider',
      ),
    );
    expect(
      sql,
      contains(
        'revoke execute on function public.zyra_preview_match_code(text)',
      ),
    );
    expect(
      sql,
      contains(
        'revoke execute on function public.zyra_consider_match_code(text)',
      ),
    );
  });

  test('Browse action mode exposes the dedicated ZYRA Code route', () {
    final shell = File('lib/screens/home/home_shell.dart').readAsStringSync();

    expect(shell, contains("label: 'Scan'"));
    expect(shell, contains('_CardAct.findByCode'));
    expect(shell, contains('const FindByZyraCodeScreen()'));
  });
}
