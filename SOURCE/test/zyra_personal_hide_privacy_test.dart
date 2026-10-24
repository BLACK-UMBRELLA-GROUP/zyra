// Cache/UI tests have no initialized SDK and cannot authorize member traffic.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/settings/hidden_profiles_screen.dart';
import 'package:zyra/services/zyra_hidden_profile_store.dart';
import 'package:zyra/services/zyra_personal_hide_service.dart';
import 'package:zyra/theme/zyra_text.dart';

const _target = '00000000-0000-4000-8000-000000005201';
const _cache = 'zyra.hidden_profiles.v1.developer_preview';
const _real = SeekerProfile(
  id: _target,
  firstName: 'Private real name',
  surnameLine: 'Private surname',
  age: 37,
  city: 'Private city',
  gender: 'female',
  photos: [],
);

Map<String, Object?> _legacy() => {
  'id': _target,
  'first_name': _real.firstName,
  'surname_line': _real.surnameLine,
  'age': _real.age,
  'city': _real.city,
  'gender': _real.gender,
  'is_demo': true, // A forged demo flag does not turn a UUID into a fixture.
};

Future<void> _until(WidgetTester tester, bool Function() done) async {
  for (var frame = 0; frame < 100 && !done(); frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(done(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZyraHiddenProfileStore.clearForAccountChange();
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() => ZyraText.useTestFontStubs = false);

  test(
    'legacy real identity is purged without converting into a hide',
    () async {
      SharedPreferences.setMockInitialValues({
        _cache: jsonEncode([
          {'id': 'malformed-fixture', 'first_name': 5, 'is_demo': true},
          _legacy(),
          {
            'id': 'local-demo',
            'first_name': 'Local fixture',
            'age': 25,
            'city': 'Sample city',
            'gender': 'female',
            'is_demo': true,
          },
        ]),
        'unrelated-sentinel': 'keep',
      });
      final records = await ZyraHiddenProfileStore.records();
      expect(records.map((record) => record.id), ['local-demo']);
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_cache)!;
      expect(stored, isNot(contains(_target)));
      expect(stored, isNot(contains(_real.firstName)));
      expect(stored, isNot(contains(_real.city)));
      expect(prefs.getString('unrelated-sentinel'), 'keep');
      expect(await ZyraPersonalHideService.hiddenIdsOrNull(), isNull);
    },
  );

  test(
    'remembering a real UUID never persists identity or personal Hide',
    () async {
      await ZyraHiddenProfileStore.remember(_real);
      expect(await ZyraHiddenProfileStore.records(), isEmpty);
      expect((await SharedPreferences.getInstance()).getString(_cache), isNull);
      final record = ZyraHiddenProfileRecord.fromProfile(_real);
      expect(record.displayName, 'Hidden profile');
      expect(record.age, 0);
      expect(record.city, isEmpty);
      expect(record.gender, isEmpty);
      expect(record.toJson().keys, ['id']);
    },
  );

  testWidgets('default no-SDK page is unavailable, not empty or cached', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      _cache: jsonEncode([_legacy()]),
    });
    await tester.pumpWidget(const MaterialApp(home: HiddenProfilesScreen()));
    await _until(
      tester,
      () => find.text('Hidden profiles unavailable').evaluate().isNotEmpty,
    );
    expect(find.text('No hidden profiles'), findsNothing);
    expect(find.text(_real.firstName), findsNothing);
    expect((await SharedPreferences.getInstance()).getString(_cache), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final acknowledged in [true, false]) {
    testWidgets('real row is neutral; unhide ACK $acknowledged is truthful', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        _cache: jsonEncode([_legacy()]),
      });
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: HiddenProfilesScreen(
            loadServerIds: () async => const [_target],
            unhideServerProfile: (id) async {
              expect(id, _target);
              writes++;
              return acknowledged;
            },
          ),
        ),
      );
      await _until(
        tester,
        () => find.text('Hidden profile').evaluate().isNotEmpty,
      );
      expect(find.text(_real.firstName), findsNothing);
      expect(find.text(_real.city), findsNothing);
      expect(find.text(_target), findsNothing);
      expect(find.text('37'), findsNothing);
      await tester.tap(find.text('Unhide'));
      await tester.pumpAndSettle();
      expect(find.text('Unhide profile?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Unhide'));
      await _until(
        tester,
        () => acknowledged
            ? find.text('No hidden profiles').evaluate().isNotEmpty
            : find
                  .text("That didn't go through. Please try again.")
                  .evaluate()
                  .isNotEmpty,
      );
      expect(writes, 1);
      expect(
        find.text('Hidden profile'),
        acknowledged ? findsNothing : findsOneWidget,
      );
      if (acknowledged) expect(find.byType(SnackBar), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      // Rehome the local fixture queue before this FakeAsync zone is gone.
      var done = false;
      Zone.root.run(() {
        ZyraHiddenProfileStore.forget(
          'queue-drain',
        ).then<void>((_) => done = true);
      });
      await _until(tester, () => done);
    });
  }

  testWidgets('malformed injected IDs cannot create cached real rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HiddenProfilesScreen(
          loadServerIds: () async => [_target, _target],
        ),
      ),
    );
    await _until(
      tester,
      () => find.text('Hidden profiles unavailable').evaluate().isNotEmpty,
    );
    expect(find.text('Hidden profile'), findsNothing);
    expect(find.text('No hidden profiles'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
