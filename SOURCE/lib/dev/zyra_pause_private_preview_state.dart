import 'package:flutter/foundation.dart';

/// Account-lifetime LOCK 44 sample policy, with no member or server writes.
class ZyraPausePrivatePreviewState extends ChangeNotifier {
  ZyraPausePrivatePreviewState({
    required bool Function() canAct,
    required bool Function() seekerOne,
    // Keep public callback names independent of the private policy fields.
    // ignore: prefer_initializing_formals
  }) : _canAct = canAct,
       // ignore: prefer_initializing_formals
       _seekerOne = seekerOne;

  final bool Function() _canAct;
  final bool Function() _seekerOne;
  bool _revoked = false;
  bool _disposed = false;
  bool _paused = false;
  bool _privateMode = false;

  /// Owner denial is terminal, including an A -> B -> A account replacement.
  bool get current {
    if (_disposed || _revoked) return false;
    try {
      if (_canAct()) return true;
    } catch (_) {
      // Failed admission cannot grant sample actions.
    }
    _revoked = true;
    return false;
  }

  bool get paused => _paused;
  bool get privateMode => _privateMode && _hasSeekerOne;

  bool get _hasSeekerOne {
    try {
      return _seekerOne();
    } catch (_) {
      return false;
    }
  }

  bool get discoveryVisible => current && !_paused && !privateMode;
  bool get canBrowse => current && !_paused;
  bool get canSendRequest => current && !_paused;

  /// Waiting requests and existing Journeys are not changed by this policy.
  bool canReceiveNewRequest({required bool fromRequestedPerson}) =>
      current && !_paused && (!privateMode || fromRequestedPerson);

  /// Q225: a full break lasts until the member explicitly ends it.
  bool pause() {
    if (!current) return false;
    if (_paused) return true;
    _paused = true;
    notifyListeners();
    return true;
  }

  bool showProfile() {
    if (!current) return false;
    if (!_paused) return true;
    _paused = false;
    notifyListeners();
    return true;
  }

  bool setPrivateMode(bool enabled) {
    if (!current || (enabled && !_hasSeekerOne)) return false;
    if (_privateMode == enabled) return true;
    _privateMode = enabled;
    notifyListeners();
    return true;
  }

  /// The owning shell synchronizes its sample plan before building. A later
  /// upgrade cannot revive a switch cleared by a downgrade.
  bool synchronizePlan({bool notify = true}) {
    if (!current || !_privateMode || _hasSeekerOne) return false;
    _privateMode = false;
    if (notify) notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
