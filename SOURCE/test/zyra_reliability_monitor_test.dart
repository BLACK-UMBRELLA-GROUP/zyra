import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_reliability_monitor.dart';

void main() {
  final monitor = ZyraReliabilityMonitor.instance;

  setUp(monitor.resetForTest);
  tearDown(monitor.resetForTest);

  test('records only fixed technical categories', () {
    monitor.record(
      area: ZyraReliabilityArea.startup,
      fingerprint: ZyraReliabilityFingerprint.backendStartup,
    );

    final snapshot = monitor.snapshot;
    expect(snapshot.incidentCount, 1);
    expect(snapshot.recentIncidents.single.area, ZyraReliabilityArea.startup);
    expect(snapshot.countsByFingerprint, {
      ZyraReliabilityFingerprint.backendStartup: 1,
    });
  });

  test('session reliability evidence is bounded to 100 incidents', () {
    for (var i = 0; i < 105; i++) {
      monitor.record(
        area: ZyraReliabilityArea.interface,
        fingerprint: i < 5
            ? ZyraReliabilityFingerprint.nativeIdentity
            : ZyraReliabilityFingerprint.flutterFramework,
      );
    }

    final snapshot = monitor.snapshot;
    expect(snapshot.incidentCount, 100);
    expect(
      snapshot.countsByFingerprint[ZyraReliabilityFingerprint.nativeIdentity],
      isNull,
    );
    expect(
      snapshot.countsByFingerprint[ZyraReliabilityFingerprint.flutterFramework],
      100,
    );
  });
}
