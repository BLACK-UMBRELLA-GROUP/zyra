import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/settings_screen.dart';
import 'package:zyra/screens/wali/wali_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    AppState.instance.resetForAccountChange();
  });

  tearDown(() {
    AppState.instance.resetForAccountChange();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('Seeker Settings distinguishes unavailable from no Guardians', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          loadLinkedPeople: (_) async => const ZyraSourceResult.unavailable(
            ZyraSourceFailure.requestFailed,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guardians'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('None linked'), findsNothing);
  });

  testWidgets('confirmed empty linked-person result may say None linked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          guardian: true,
          loadLinkedPeople: (_) async => const ZyraSourceResult.available([]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Linked Seekers'), findsOneWidget);
    expect(find.text('None linked'), findsOneWidget);
  });

  testWidgets('Guardian Profile keeps unknown link count truthful', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaliProfileScreen(
            loadLinkedSeekers: () async => const ZyraSourceResult.unavailable(
              ZyraSourceFailure.requestFailed,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Relationship'), findsOneWidget);
    expect(find.text('Linked Seekers'), findsOneWidget);
    expect(find.text('Unavailable'), findsNWidgets(2));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('stale Guardian result cannot repopulate a new account', (
    tester,
  ) async {
    final load = Completer<ZyraSourceResult<List<WaliLinkedPerson>>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaliProfileScreen(loadLinkedSeekers: () => load.future),
        ),
      ),
    );
    await tester.pump();
    ZyraAccountState.resetForTesting();
    load.complete(
      const ZyraSourceResult.available([
        WaliLinkedPerson(
          id: 'other',
          firstName: 'Aaliyah',
          relationship: 'father',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(AppState.instance.waliRealLinkedSeekers, isEmpty);
    expect(find.text('Unavailable'), findsNWidgets(2));
  });
}
