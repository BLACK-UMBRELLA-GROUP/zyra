import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A device-local education receipt. It never proves signup, account access,
/// role, or identity, and account presentation-cache cleanup cannot erase it.
class ZyraFirstTourStore {
  ZyraFirstTourStore({
    required String? ownerId,
    required bool Function() canAct,
    // Keep public argument names independent of private owner state.
    // ignore: prefer_initializing_formals
  }) : _ownerId = ownerId,
       // ignore: prefer_initializing_formals
       _canAct = canAct;

  final String? _ownerId;
  final bool Function() _canAct;
  static final Map<String, Future<void>> _ownerOperations = {};
  bool _closed = false;
  bool _revoked = false;
  bool _ephemeralSeen = false;

  bool get _current {
    if (_closed || _revoked) return false;
    try {
      if (_canAct()) return true;
    } catch (_) {
      // Failure to establish the opening owner is terminal for this store.
    }
    _revoked = true;
    return false;
  }

  String get _key =>
      'zyra.first_tour_seen_v1.${base64Url.encode(utf8.encode(_ownerId!))}';

  /// Claims the receipt when the first walkthrough starts. Concurrent hosts
  /// for the same account share one queue and cannot both claim that entry.
  Future<bool> claimFirstEntry() {
    if (!_current) return Future.value(false);
    if (_ownerId == null) {
      if (_ephemeralSeen) return Future.value(false);
      _ephemeralSeen = true;
      return Future.value(true);
    }
    if (_ownerId.isEmpty) return Future.value(false);
    return _serialized(() async {
      if (!_current) return false;
      try {
        final preferences = await SharedPreferences.getInstance();
        if (!_current) return false;
        await preferences.reload();
        if (!_current || preferences.getBool(_key) == true) return false;
        if (!await preferences.setBool(_key, true)) return false;
        return _current;
      } catch (_) {
        // An unavailable receipt cannot produce a successful durable claim.
        return false;
      }
    });
  }

  Future<bool> hasSeen() {
    if (!_current) return Future.value(false);
    if (_ownerId == null) return Future.value(_ephemeralSeen);
    if (_ownerId.isEmpty) return Future.value(false);
    return _serialized(() async {
      if (!_current) return false;
      try {
        final preferences = await SharedPreferences.getInstance();
        if (!_current) return false;
        await preferences.reload();
        return _current && preferences.getBool(_key) == true;
      } catch (_) {
        return false;
      }
    });
  }

  Future<bool> _serialized(Future<bool> Function() action) {
    final key = _key;
    final previous = _ownerOperations[key] ?? Future<void>.value();
    final result = previous.then((_) => action());
    final complete = result.then<void>((_) {});
    _ownerOperations[key] = complete;
    complete.then((_) {
      if (identical(_ownerOperations[key], complete)) {
        _ownerOperations.remove(key);
      }
    });
    return result;
  }

  void close() {
    _closed = true;
  }
}
