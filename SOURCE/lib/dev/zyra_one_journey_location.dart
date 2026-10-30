// LOCK11: session-only approximate origin. No persistence, transport or logging.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/zyra_account_state.dart';
import 'zyra_browse_filter.dart';

const zyraLocationChannel = MethodChannel(
  'app.zyraconnect.zyra/rough_location',
);
const zyraLocationFallback =
    'No problem — distances start from your home town.';

/// A real fixture town position, looked up from the actual sample profile city.
/// Unknown towns fail closed rather than acquiring a device fix implicitly.
ZyraBrowsePoint? zyraSampleTownPoint(String city) => switch (city) {
  'Manchester' => const ZyraBrowsePoint(53.48, -2.24),
  'London' => const ZyraBrowsePoint(51.51, -.13),
  'Birmingham' => const ZyraBrowsePoint(52.48, -1.90),
  'Leeds' => const ZyraBrowsePoint(53.80, -1.55),
  'Bristol' => const ZyraBrowsePoint(51.45, -2.59),
  'Nottingham' => const ZyraBrowsePoint(52.95, -1.15),
  'Cardiff' => const ZyraBrowsePoint(51.48, -3.18),
  'Liverpool' => const ZyraBrowsePoint(53.41, -2.98),
  _ => null,
};

class ZyraOneJourneyLocation extends ChangeNotifier
    with WidgetsBindingObserver {
  ZyraOneJourneyLocation({required bool Function() canAct})
    // Public guard parameter matches other caller-owned preview adapters.
    // ignore: prefer_initializing_formals
    : _canAct = canAct,
      _owner = (ZyraAccountState.userId, ZyraAccountState.generation) {
    _channelOwner?._point = null;
    _channelOwner?.cancelPending();
    _channelOwner = this;
    WidgetsBinding.instance.addObserver(this);
    zyraLocationChannel.setMethodCallHandler((call) async {
      if (call.method == 'permissionChanged' && call.arguments == 'allowed') {
        refused = false;
      } else if (call.method == 'permissionChanged') {
        refused = call.arguments == 'denied' || call.arguments == 'restricted';
        _point = null;
        if (!_pending) cancelPending();
        if (!_disposed) notifyListeners();
      }
    });
  }
  static ZyraOneJourneyLocation? _channelOwner;
  final bool Function() _canAct;
  final (String?, int) _owner;
  ZyraBrowsePoint? _point;
  int _epoch = 0;
  bool _disposed = false, _revoked = false, _pending = false;
  bool _foreground = true, _inactive = false, _permissionVerified = false;
  bool explained = false, refused = false;
  Completer<void>? _resume;

  bool get current {
    if (_disposed || _revoked || _channelOwner != this) return false;
    if (ZyraAccountState.isSigningOut ||
        _owner != (ZyraAccountState.userId, ZyraAccountState.generation)) {
      _revoked = true;
      _point = null;
      cancelPending();
      return false;
    }
    if (!_canAct()) {
      _point = null;
      cancelPending();
      return false;
    }
    return true;
  }

  ZyraBrowsePoint? get point =>
      current && _foreground && _permissionVerified ? _point : null;

  Future<Object?> _call(String method) async {
    try {
      return await zyraLocationChannel.invokeMethod<Object?>(method);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  void cancelPending() {
    _epoch++;
    _resume?.complete();
    _resume = null;
    if (_pending) unawaited(_call('cancel'));
    _pending = false;
  }

  /// Shared seam for Phone access / account teardown; no saved location exists.
  void clear() {
    cancelPending();
    _point = null;
    _permissionVerified = false;
    if (!_disposed) notifyListeners();
  }

  Future<bool> recheck() async {
    if (!current || !_foreground) return false;
    final epoch = _epoch;
    _permissionVerified = false;
    notifyListeners();
    final status = await _call('status');
    if (!current || epoch != _epoch || !_foreground) return false;
    refused = status == 'denied' || status == 'restricted';
    if (status != 'allowed') {
      clear();
      return false;
    }
    _permissionVerified = true;
    notifyListeners();
    return true;
  }

  /// Only an explicit Continue (or a subsequent explicit selection) calls this.
  Future<bool> request(bool Function() flowCurrent) async {
    if (!current || !_foreground || _pending || !flowCurrent()) return false;
    explained = true;
    if (refused) {
      await _call('openSettings');
      return false;
    }
    final epoch = ++_epoch;
    _pending = true;
    bool valid() => current && epoch == _epoch && _foreground && flowCurrent();
    final result = await _call('request');
    if (!valid()) return false;
    // The permission sheet makes iOS inactive. Keep its epoch, but do not use
    // a result until resumed; a real background departure cancels it instead.
    if (_inactive) {
      _resume ??= Completer<void>();
      await _resume!.future;
      if (!valid()) return false;
    }
    final status = await _call('status');
    if (!valid()) return false;
    _pending = false;
    refused =
        status == 'denied' ||
        status == 'restricted' ||
        (result is Map &&
            (result['status'] == 'denied' || result['status'] == 'restricted'));
    ZyraBrowsePoint? coarse;
    if (status == 'allowed' && result is Map && result['status'] == 'allowed') {
      final lat = result['latitude'], lon = result['longitude'];
      if (lat is num && lon is num) {
        final value = ZyraBrowsePoint(lat.toDouble(), lon.toDouble());
        // Native must round BEFORE the channel. Refuse precise/malformed data.
        bool grid(double v) => (v * 10 - (v * 10).round()).abs() < 1e-7;
        if (value.isValid && grid(value.latitude) && grid(value.longitude)) {
          coarse = value;
        }
      }
    }
    _point = coarse;
    _permissionVerified = coarse != null;
    notifyListeners();
    return coarse != null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.inactive) {
      _inactive = true;
    } else if (state == AppLifecycleState.resumed) {
      _inactive = false;
      _foreground = true;
      _resume?.complete();
      _resume = null;
      if (explained && !_pending) unawaited(recheck());
    } else {
      _foreground = false;
      _inactive = false;
      clear();
    }
  }

  @override
  void dispose() {
    cancelPending();
    _point = null;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    if (_channelOwner == this) {
      _channelOwner = null;
      zyraLocationChannel.setMethodCallHandler(null);
    }
    super.dispose();
  }
}
