import 'package:flutter/foundation.dart';

/// Fixed technical areas used by ZYRA's local reliability evidence.
///
/// The monitor deliberately never receives an exception, stack trace, route,
/// member value or arbitrary message. It records only this closed taxonomy.
enum ZyraReliabilityArea { startup, interface, platform }

enum ZyraReliabilityFingerprint {
  backendStartup,
  nativeIdentity,
  flutterFramework,
  unhandledPlatform,
}

@immutable
class ZyraReliabilityIncident {
  final DateTime occurredAt;
  final ZyraReliabilityArea area;
  final ZyraReliabilityFingerprint fingerprint;

  const ZyraReliabilityIncident({
    required this.occurredAt,
    required this.area,
    required this.fingerprint,
  });
}

@immutable
class ZyraReliabilitySnapshot {
  final List<ZyraReliabilityIncident> recentIncidents;

  const ZyraReliabilitySnapshot({required this.recentIncidents});

  int get incidentCount => recentIncidents.length;

  Map<ZyraReliabilityFingerprint, int> get countsByFingerprint {
    final result = <ZyraReliabilityFingerprint, int>{};
    for (final incident in recentIncidents) {
      result.update(
        incident.fingerprint,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return result;
  }
}

/// Bounded, in-memory app-health evidence for Founder testing.
///
/// Phase 2 does not send this evidence anywhere. A future provider or server
/// channel needs its own privacy, retention and activation approval. Keeping
/// this API free of arbitrary values prevents accidental personal-data or
/// secret capture while the product-health design is still staged.
class ZyraReliabilityMonitor extends ChangeNotifier {
  ZyraReliabilityMonitor._();

  static final ZyraReliabilityMonitor instance = ZyraReliabilityMonitor._();

  static const int _sessionLimit = 100;
  final List<ZyraReliabilityIncident> _incidents = [];

  ZyraReliabilitySnapshot get snapshot =>
      ZyraReliabilitySnapshot(recentIncidents: List.unmodifiable(_incidents));

  void record({
    required ZyraReliabilityArea area,
    required ZyraReliabilityFingerprint fingerprint,
  }) {
    _incidents.add(
      ZyraReliabilityIncident(
        occurredAt: DateTime.now().toUtc(),
        area: area,
        fingerprint: fingerprint,
      ),
    );
    if (_incidents.length > _sessionLimit) _incidents.removeAt(0);
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    _incidents.clear();
    notifyListeners();
  }
}
