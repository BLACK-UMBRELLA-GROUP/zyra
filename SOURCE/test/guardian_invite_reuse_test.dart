// LOCK9's actual Add caller: no ordinary member reader/request/link effects.
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'local_code_page_lock9_test.dart'
    show NoCodeNetwork, enterCode, pressCode, checkKey, sendKey;

void main() {
  final previous = HttpOverrides.current;
  late NoCodeNetwork network;
  int reads = 0, linked = 0;
  bool allowed = true;
  int epoch = 0;
  ZyraCodeLocalPreview adapter({
    Future<ZyraPersonalCodePreview?> Function(String)? lookup,
  }) => ZyraCodeLocalPreview(
    canAct: () => allowed,
    canInteract: () => true,
    interactionEpoch: () => epoch,
    personalCode: const ZyraPersonalCode(
      code: 'ZYRA-DEMO-SEEKER-ADAM',
      roleContext: 'seeker',
    ),
    lookupCode:
        lookup ??
        (code) async => code == 'ZYRA-DEMO-GUARDIAN-IBRAHIM'
            ? const ZyraPersonalCodePreview(firstName: 'Ibrahim', role: 'wali')
            : null,
  );
  setUp(() {
    reads = linked = epoch = 0;
    allowed = true;
    network = NoCodeNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    ZyraProductTelemetry.instance.resetForTest();
  });
  tearDown(() {
    expect(reads, 0);
    expect(linked, 0);
    expect(network.attempts, 0);
    expect(ZyraProductTelemetry.instance.snapshot.sessionEventCount, 0);
    ZyraText.useTestFontStubs = false;
    HttpOverrides.global = previous;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });
  Future<void> mount(WidgetTester t, ZyraCodeLocalPreview preview) async {
    t.view.physicalSize = const Size(430, 932);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: ZyraCodeScreen(
          key: const ValueKey('same-owner'),
          asGuardian: false,
          localPreview: preview,
          onLinked: () => linked++,
          loadPersonalCode: ({roleContext}) async {
            reads++;
            return const ZyraSourceResult.unavailable(
              ZyraSourceFailure.notReady,
            );
          },
          loadGuardianRequests: () async {
            reads++;
            return const ZyraSourceResult.unavailable(
              ZyraSourceFailure.notReady,
            );
          },
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('actual Add Check then Send is local and never becomes Main', (
    t,
  ) async {
    await mount(t, adapter());
    final revision = ZyraWaliLinkService.invitationRevision.value;
    final plan = AppState.instance.plan;
    await enterCode(t, 'ZYRA-DEMO-GUARDIAN-IBRAHIM');
    await pressCode(t, find.byKey(checkKey));
    expect(find.text('Ibrahim'), findsOneWidget);
    await pressCode(t, find.byKey(sendKey));
    expect(find.text('Request sent'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.textContaining('Main Guardian'), findsNothing);
    expect(ZyraWaliLinkService.invitationRevision.value, revision);
    expect(AppState.instance.plan, plan);
    expect(find.byType(MobileScanner), findsNothing);
  });
  for (final interruption in [
    'overlay',
    'revoked',
    'session',
    'account',
    'adapter',
  ]) {
    testWidgets('actual Add pending reader stays invalid after $interruption', (
      t,
    ) async {
      final held = Completer<ZyraPersonalCodePreview?>();
      final preview = adapter(lookup: (_) => held.future);
      await mount(t, preview);
      await enterCode(t, 'ZYRA-DEMO-GUARDIAN-IBRAHIM');
      await t.tap(find.byKey(checkKey));
      await t.pump();
      switch (interruption) {
        case 'overlay':
          epoch += 2;
        case 'revoked':
          allowed = false;
        case 'session':
          ZyraInternalPreviewClient.finishSignOut();
        case 'account':
          ZyraAccountState.resetForTesting();
        case 'adapter':
          await mount(t, adapter());
      }
      held.complete(
        const ZyraPersonalCodePreview(firstName: 'Stale', role: 'wali'),
      );
      await t.pumpAndSettle();
      expect(find.text('Stale'), findsNothing);
      expect(find.text('Request sent'), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'unknown aliases do not fall back to live reader and refresh adds no request rows',
    (t) async {
      await mount(t, adapter());
      await enterCode(t, 'Z' * 20);
      await pressCode(t, find.byKey(checkKey));
      expect(find.text('Invalid code. Please try again.'), findsOneWidget);
      ZyraWaliLinkService.invitationRevision.value++;
      await t.pumpAndSettle();
      expect(find.text('REQUESTS'), findsNothing);
    },
  );
}
