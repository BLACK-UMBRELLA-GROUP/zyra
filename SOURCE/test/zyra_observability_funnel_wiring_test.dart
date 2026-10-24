import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';

void main() {
  final telemetry = ZyraProductTelemetry.instance;

  setUp(telemetry.resetForTest);
  tearDown(telemetry.resetForTest);

  testWidgets('membership records one role-aware open event', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UpgradeScreen(telemetrySurface: ZyraTelemetrySurface.guardian),
      ),
    );

    final event = telemetry.snapshot.recentEvents.single;
    expect(event.feature, ZyraTelemetryFeature.membership);
    expect(event.name, ZyraTelemetryEventName.opened);
    expect(event.action, ZyraTelemetryAction.pageView);
    expect(event.surface, ZyraTelemetrySurface.guardian);
    expect(tester.takeException(), isNull);
  });

  testWidgets('support records the page and a completed self-service answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpSupportScreen(telemetrySurface: ZyraTelemetrySurface.seeker),
      ),
    );

    final question = zyraHelpCategories.first.entries.first.question;
    await tester.tap(find.text(question));
    await tester.pumpAndSettle();

    final events = telemetry.snapshot.recentEvents;
    expect(events, hasLength(2));
    expect(
      events.every((event) => event.feature == ZyraTelemetryFeature.support),
      isTrue,
    );
    expect(events.map((event) => event.name), [
      ZyraTelemetryEventName.opened,
      ZyraTelemetryEventName.completed,
    ]);
    expect(events.map((event) => event.action), [
      ZyraTelemetryAction.pageView,
      ZyraTelemetryAction.supportAnswer,
    ]);
    expect(tester.takeException(), isNull);
  });

  test('identity and Guardian actions use the closed telemetry API', () {
    final identity = File(
      'lib/screens/onboarding/identity_verification_screen.dart',
    ).readAsStringSync();
    final guardian = File(
      'lib/screens/wali/guardian_detail_screen.dart',
    ).readAsStringSync();

    expect(identity, contains('ZyraTelemetryFeature.identityCheck'));
    expect(identity, contains('ZyraTelemetryAction.identityProvider'));
    expect(identity, contains('ZyraTelemetrySurface.entry'));
    expect(identity, isNot(contains('p_feature_key')));
    expect(guardian, contains('ZyraTelemetryFeature.guardian'));
    expect(guardian, contains('ZyraTelemetryAction.guardianRemove'));
    expect(guardian, contains('ZyraTelemetrySurface.seeker'));
    expect(guardian, isNot(contains('p_feature_key')));
  });
}
