// LOCK9 replaces the old View-profile composition. Pure canonical resolution
// remains unchanged; shared lifetime/input cases live in local_code_page_lock9.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_code_entry.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'local_code_page_lock9_test.dart' show enterCode, pressCode, checkKey;

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);
  test(
    'canonical local namespace still resolves only exact known draft records',
    () {
      for (final person in draftProfiles) {
        final code = ZyraDraftKnownPersonCodes.codeFor(person);
        expect(code, startsWith('ZYRA-DRAFT-'));
        expect(ZyraDraftKnownPersonCodes.resolve(code), same(person));
        expect(
          ZyraDraftKnownPersonCodes.resolve(' ${code.toLowerCase()} '),
          same(person),
        );
      }
      expect(
        ZyraDraftKnownPersonCodes.codeFor(draftProfiles[1]),
        'ZYRA-DRAFT-SARA',
      );
      for (final invalid in [
        'ZYRA-DRAFT-SARA-EXTRA',
        'https://example/ZYRA-DRAFT-SARA',
        'ZYRA-AAAA-BBBB-CCCC-DDDD-EEEE',
        'ZYRA-DEMO-SEEKER-ADAM',
      ]) {
        expect(ZyraDraftKnownPersonCodes.resolve(invalid), isNull);
      }
    },
  );
  test('noncanonical profile cannot create a sample code', () {
    expect(
      () => ZyraDraftKnownPersonCodes.codeFor(
        const DraftProfile(
          id: 'real',
          firstName: 'Sara',
          surname: 'Example',
          age: 27,
          city: 'London',
          nationalityCode: 'GB',
          ethnicityCode: 'other',
        ),
      ),
      throwsArgumentError,
    );
  });
  Future<void> mount(
    WidgetTester t, {
    bool Function()? guard,
    Future<DraftProfile?> Function(String)? lookup,
    ValueChanged<DraftProfile>? viewed,
  }) async {
    t.view.physicalSize = const Size(430, 932);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ZyraDraftCodeEntry(
            canAct: guard ?? () => true,
            lookupCode:
                lookup ??
                (code) async => ZyraDraftKnownPersonCodes.resolve(code),
            onViewProfile: viewed ?? (_) {},
            captureBuilder: (context, guard, code, manual) =>
                const Text('fake camera'),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'canonical pasted Scan sample discloses no age/city and offers no consent action',
    (t) async {
      int views = 0;
      await mount(t, viewed: (_) => views++);
      await enterCode(t, 'ZYRA-DRAFT-SARA');
      await pressCode(t, find.byKey(checkKey));
      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('Seeker · first name and role only'), findsOneWidget);
      expect(find.text('27 · Birmingham'), findsNothing);
      expect(find.text('View profile'), findsNothing);
      expect(find.text('Send request'), findsNothing);
      expect(views, 0);
    },
  );
  testWidgets('owner revocation permanently denies a pending Scan completion', (
    t,
  ) async {
    bool allowed = true;
    final held = Completer<DraftProfile?>();
    await mount(t, guard: () => allowed, lookup: (_) => held.future);
    await enterCode(t, 'ZYRA-DRAFT-SARA');
    await t.tap(find.byKey(checkKey));
    await t.pump();
    allowed = false;
    held.complete(draftProfiles[1]);
    await t.pumpAndSettle();
    allowed = true;
    await t.pumpAndSettle();
    expect(find.text('Sara'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('Scan callback rebinding denies the old sample completion', (
    t,
  ) async {
    final held = Completer<DraftProfile?>();
    bool guard() => true;
    await mount(t, guard: guard, lookup: (_) => held.future);
    await enterCode(t, 'ZYRA-DRAFT-SARA');
    await t.tap(find.byKey(checkKey));
    await t.pump();
    await mount(
      t,
      guard: guard,
      lookup: (code) async => ZyraDraftKnownPersonCodes.resolve(code),
    );
    held.complete(draftProfiles[1]);
    await t.pumpAndSettle();
    expect(find.text('Sara'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
