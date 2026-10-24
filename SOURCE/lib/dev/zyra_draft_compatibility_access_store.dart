import 'zyra_draft_compatibility_preview.dart';
import 'zyra_view_request_draft_model.dart';

/// An already-used local unlock's stable, fictional result for one person.
///
/// This display value is not authority: every consumer must obtain it from the
/// current caller-owned store, with its own current-route and role guards.
class ZyraDraftCompatibilityResult {
  const ZyraDraftCompatibilityResult._({
    required this.profileId,
    required this.overallScore,
  });

  final String profileId;
  final int overallScore;
}

/// Caller-owned access for the protected fictional request-flow review.
///
/// A used unlock belongs to this viewer lifetime and person, not a Journey or
/// route. Unspent credits never grant access. The one local balance is shared
/// across people; an existing result never consumes another credit. This is
/// not a real wallet or member entitlement: no Auth, service, private answers,
/// persistence, checkpoint hydration or Journey-consent mutation exists here.
/// OA-ZYRA-193/198/304 and real ledger/disclosure holds remain unchanged.
class ZyraDraftCompatibilityAccessStore {
  ZyraDraftCompatibilityAccessStore({
    required bool Function() canAct,
    int balance = 1,
    // Keep the caller-facing named parameter public, not the private field.
    // ignore: prefer_initializing_formals
  }) : _canAct = canAct,
       _balance = _validatedBalance(balance);

  static final Set<String> _fixtureIds = Set.unmodifiable(
    draftProfiles.map((profile) => profile.id),
  );
  static const _balancePresets = {0, 1, 5};

  final bool Function() _canAct;
  final _results = <String, ZyraDraftCompatibilityResult>{};
  int _balance;
  bool _revoked = false;
  bool _closed = false;

  /// Denial is terminal, including a failed guard and an A → B → A roundtrip.
  bool get current {
    if (_closed || _revoked) return false;
    try {
      if (_canAct()) return true;
    } catch (_) {
      // A failed admission check is denial, never a fallback to local access.
    }
    _revoked = true;
    _clear();
    return false;
  }

  int get balance => current ? _balance : 0;

  bool isUnlocked(String profileId) => resultFor(profileId) != null;

  /// No grant can be created from a remembered route or displayed score.
  ZyraDraftCompatibilityResult? resultFor(String profileId) {
    if (!current || !_fixtureIds.contains(profileId)) return null;
    return _results[profileId];
  }

  /// Assign an exact local test count without adding or withdrawing access.
  bool setBalance({required int count}) {
    if (!current || !_balancePresets.contains(count)) return false;
    _balance = count;
    return true;
  }

  /// Spend once for this person; repeat opens and Journey attempts reuse it.
  bool unlock(String profileId) {
    if (!current ||
        !_fixtureIds.contains(profileId) ||
        _results.containsKey(profileId) ||
        _balance == 0) {
      return false;
    }
    // Reuse the existing fixture display, never compute from private answers.
    final score = ZyraDraftCompatibilityPreview(
      profileId,
      balance: 0,
    ).overallScore;
    _balance--;
    _results[profileId] = ZyraDraftCompatibilityResult._(
      profileId: profileId,
      overallScore: score,
    );
    return true;
  }

  /// Only an explicit local reset clears prior results, not page navigation.
  bool reset({int balance = 1}) {
    if (!current || !_balancePresets.contains(balance)) return false;
    _results.clear();
    _balance = balance;
    return true;
  }

  /// Terminal: no retained callback may revive this owner's local access.
  void close() {
    _closed = true;
    _clear();
  }

  void _clear() {
    _results.clear();
    _balance = 0;
  }

  static int _validatedBalance(int value) {
    if (!_balancePresets.contains(value)) {
      throw ArgumentError.value(value, 'balance', 'Must be exactly 0, 1 or 5');
    }
    return value;
  }
}
