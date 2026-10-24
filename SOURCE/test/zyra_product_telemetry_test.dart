import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zyra/screens/dev/zyra_health_usage_screen.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';

void main() {
  final telemetry = ZyraProductTelemetry.instance;

  setUp(telemetry.resetForTest);
  tearDown(telemetry.resetForTest);

  test('production transmission is off unless explicitly compiled on', () {
    expect(ZyraProductTelemetry.productionCollectionEnabled, isFalse);
    expect(telemetry.snapshot.productionCollectionEnabled, isFalse);
  });

  test('records only typed identifier-free fields', () {
    telemetry.record(
      feature: ZyraTelemetryFeature.connections,
      name: ZyraTelemetryEventName.opened,
      action: ZyraTelemetryAction.pageView,
      surface: ZyraTelemetrySurface.seeker,
    );

    final snapshot = telemetry.snapshot;
    expect(snapshot.sessionEventCount, 1);
    expect(snapshot.remoteAcceptedCount, 0);
    expect(snapshot.remoteFailureCount, 0);
    expect(snapshot.countsByFeature, {ZyraTelemetryFeature.connections: 1});
    expect(snapshot.countsByAction[ZyraTelemetryAction.pageView], 1);
    expect(snapshot.countsByAction[ZyraTelemetryAction.supportEmail], 0);
    expect(snapshot.recentEvents.single.rpcPayload, {
      'p_feature_key': 'connections',
      'p_event_name': 'opened',
      'p_action_key': 'pageView',
      'p_surface_key': 'seeker',
    });
  });

  test('session evidence is bounded to the latest 200 events', () {
    for (var i = 0; i < 205; i++) {
      telemetry.record(
        feature: i < 5
            ? ZyraTelemetryFeature.browse
            : ZyraTelemetryFeature.myZyra,
        name: ZyraTelemetryEventName.shown,
        action: ZyraTelemetryAction.pageView,
        surface: ZyraTelemetrySurface.seeker,
      );
    }

    final snapshot = telemetry.snapshot;
    expect(snapshot.sessionEventCount, 200);
    expect(snapshot.countsByFeature[ZyraTelemetryFeature.browse], isNull);
    expect(snapshot.countsByFeature[ZyraTelemetryFeature.myZyra], 200);
    expect(snapshot.allCountsByFeature[ZyraTelemetryFeature.browse], 0);
  });

  testWidgets('Founder view states that production collection is off', (
    tester,
  ) async {
    telemetry.record(
      feature: ZyraTelemetryFeature.myZyra,
      name: ZyraTelemetryEventName.opened,
      action: ZyraTelemetryAction.pageView,
      surface: ZyraTelemetrySurface.seeker,
    );
    await tester.pumpWidget(const MaterialApp(home: ZyraHealthUsageScreen()));

    expect(find.text('Production collection off'), findsOneWidget);
    expect(find.text('My ZYRA'), findsOneWidget);
    expect(find.text('Session events'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('No names, emails, ZYRA Codes'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('No names, emails, ZYRA Codes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
