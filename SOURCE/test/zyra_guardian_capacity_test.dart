import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_guardian_capacity.dart';
import 'package:zyra/dev/zyra_dev_personal_code_fixtures.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.reset();
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test(
    'Main counts toward Basic one and One ten; downgrades remove nothing',
    () async {
      final people = List.generate(
        10,
        (i) => WaliLinkedPerson(
          id: 'guardian-$i',
          firstName: 'Guardian $i',
          isMain: i == 0,
        ),
      );
      final before = people.toList();
      Future<ZyraSourceResult<List<WaliLinkedPerson>>> links() async =>
          ZyraSourceResult.available(people);
      final one = await ZyraWaliLinkService.guardianCapacityForCurrentSeeker(
        plan: ZyraPlan.one,
        loadLinks: links,
      );
      final basic = await ZyraWaliLinkService.guardianCapacityForCurrentSeeker(
        plan: ZyraPlan.basic,
        loadLinks: links,
      );
      expect(one.canAdd, isFalse);
      expect(one.canUpgrade, isFalse);
      expect(basic.canAdd, isFalse);
      expect(basic.canUpgrade, isTrue);
      expect(people, orderedEquals(before));
      expect(basic.linkedGuardianCount, 10);
      expect(
        ZyraGuardianCapacity.fromCount(
          plan: ZyraPlan.basic,
          linkedGuardianCount: 0,
        ).canAdd,
        isTrue,
      );
      expect(
        ZyraGuardianCapacity.fromCount(
          plan: ZyraPlan.basic,
          linkedGuardianCount: 1,
        ).canAdd,
        isFalse,
      );
      expect(
        ZyraGuardianCapacity.fromCount(
          plan: ZyraPlan.one,
          linkedGuardianCount: 9,
        ).canAdd,
        isTrue,
      );
      expect(
        ZyraGuardianCapacity.fromCount(
          plan: ZyraPlan.one,
          linkedGuardianCount: 11,
        ).canAdd,
        isFalse,
      );
    },
  );

  test('unavailable/throwing count stays unavailable, never empty', () async {
    for (final loader
        in <Future<ZyraSourceResult<List<WaliLinkedPerson>>> Function()>[
          () async => const ZyraSourceResult.unavailable(
            ZyraSourceFailure.requestFailed,
          ),
          () async => throw StateError('read failed'),
        ]) {
      final result = await ZyraWaliLinkService.guardianCapacityForCurrentSeeker(
        plan: ZyraPlan.one,
        loadLinks: loader,
      );
      expect(result.status, ZyraGuardianCapacityStatus.unavailable);
      expect(result.linkedGuardianCount, isNull);
      expect(result.canAdd, isFalse);
      expect(result.canUpgrade, isFalse);
    }
  });

  test(
    'count uses accepted unique people, not pending invitation controls',
    () async {
      ZyraDevScenario.instance.setPendingInvites(50);
      const person = WaliLinkedPerson(
        id: 'main',
        firstName: 'Ibrahim',
        isMain: true,
      );
      final result = await ZyraWaliLinkService.guardianCapacityForCurrentSeeker(
        plan: ZyraPlan.one,
        loadLinks: () async =>
            const ZyraSourceResult.available([person, person]),
      );
      expect(result.linkedGuardianCount, 1);
      expect(result.canAdd, isTrue);
    },
  );

  Future<void> openDemoCode(
    WidgetTester tester, {
    required ZyraPlan plan,
    required int count,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(name: 'Adam', gender: 'male');
    AppState.instance.plan = plan;
    ZyraDevScenario.instance.reset();
    ZyraDevScenario.instance.setMainGuardian(count > 0);
    ZyraDevScenario.instance.setAdditionalGuardians(count > 0 ? count - 1 : 0);
    await tester.pumpWidget(
      const MaterialApp(home: ZyraCodeScreen(asGuardian: false)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirmDemoGuardian(WidgetTester tester) async {
    await tester.tap(find.text('Enter code'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(
      find.byKey(const ValueKey('inline-zyra-code-field')),
      ZyraDevPersonalCodeFixtures.validGuardianEntryCode,
    );
    await tester.tap(find.text('Check'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
  }

  testWidgets('Basic at cap retains code and QR but send offers Upgrade', (
    tester,
  ) async {
    await openDemoCode(tester, plan: ZyraPlan.basic, count: 1);
    expect(find.text('ZYRA-DEMO-SEEKER-ADAM'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    await tester.tap(find.text('QR'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('zyra_code_qr_preview')), findsOneWidget);
    await confirmDemoGuardian(tester);
    expect(find.text('Upgrade'), findsOneWidget);
    expect(
      find.textContaining('Your current access allows 1 linked Guardian'),
      findsWidgets,
    );
    expect(find.text('Request sent'), findsNothing);
    expect(ZyraDevScenario.instance.guardianCount, 1);
    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();
    expect(find.byType(UpgradeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Basic zero and One nine permit a request without adding a link',
    (tester) async {
      for (final fixture in [(ZyraPlan.basic, 0), (ZyraPlan.one, 9)]) {
        await openDemoCode(tester, plan: fixture.$1, count: fixture.$2);
        await confirmDemoGuardian(tester);
        expect(find.text('Request sent'), findsOneWidget);
        expect(find.text('Upgrade'), findsNothing);
        expect(ZyraDevScenario.instance.guardianCount, fixture.$2);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'One ten limit has no misleading upgrade, existing links retained',
    (tester) async {
      await openDemoCode(tester, plan: ZyraPlan.one, count: 10);
      await confirmDemoGuardian(tester);
      expect(find.text('Upgrade'), findsNothing);
      expect(
        find.textContaining('Seeker One includes up to 10 linked Guardians'),
        findsWidgets,
      );
      expect(ZyraDevScenario.instance.guardianCount, 10);
      expect(tester.takeException(), isNull);
    },
  );
}
