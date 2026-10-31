// Caller-owned account drafts for the protected Founder request-flow review.
// Retained editors use this adapter, never the authenticated member repository.
// This is not durable account data, admission, verification or payment proof.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset;

import '../models/seeker_profile.dart';
import '../screens/profile/compatibility_editors.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../services/zyra_onboarding_answers_service.dart'
    show ZyraOnboardingAnswersSnapshot;
import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';

class ZyraRequestAccountSession extends ChangeNotifier {
  ZyraRequestAccountSession({
    required bool Function() canAct,
    required ZyraDevPalette palette,
    required ZyraHapticLevel hapticLevel,
    required bool goldEnabled,
    // Public constructor names intentionally do not expose private state.
    // ignore: prefer_initializing_formals
  }) : _canAct = canAct,
       _palette = ZyraColors.currentDefaultPalette,
       // ignore: prefer_initializing_formals
       _hapticLevel = hapticLevel,
       // ignore: prefer_initializing_formals
       _goldEnabled = goldEnabled {
    compatibility = ZyraRequestCompatibilityRepository(canAct: () => current);
  }

  final bool Function() _canAct;
  bool _revoked = false;
  bool _disposed = false;
  final _photos = <bool, List<String>>{};
  final _avatar = <bool, Offset>{};
  late final ZyraRequestCompatibilityRepository compatibility;
  ZyraDevPalette _palette;
  ZyraHapticLevel _hapticLevel;
  bool _goldEnabled;

  /// Denial is terminal for this review lifetime; it cannot become live or
  /// revive when an account changes A → B → A.
  bool get current {
    if (_revoked || _disposed) return false;
    try {
      if (_canAct()) return true;
    } catch (_) {
      // A failed admission check is denial, not permission to fall back.
    }
    _revoked = true;
    return false;
  }

  ZyraDevPalette get palette => _palette;
  ZyraHapticLevel get hapticLevel => _hapticLevel;
  bool get goldEnabled => _goldEnabled;
  List<String> photos(bool guardian) =>
      List<String>.unmodifiable(_photos[guardian] ?? const []);
  Offset avatar(bool guardian) => _avatar[guardian] ?? Offset.zero;

  bool seedPhotos(bool guardian, List<String> value) {
    if (!current || _photos.containsKey(guardian) || !_localPhotos(value)) {
      return false;
    }
    _photos[guardian] = List.of(value);
    return true;
  }

  bool setPhotos(bool guardian, List<String> value) {
    if (!current || !_localPhotos(value) || value.isEmpty) return false;
    _photos[guardian] = List.of(value);
    notifyListeners();
    return true;
  }

  bool setAvatar(bool guardian, Offset value) {
    if (!current || !value.dx.isFinite || !value.dy.isFinite) return false;
    _avatar[guardian] = Offset(
      value.dx.clamp(-1.0, 1.0).toDouble(),
      value.dy.clamp(-1.0, 1.0).toDouble(),
    );
    notifyListeners();
    return true;
  }

  bool setPalette(ZyraDevPalette value) {
    if (!current || value != ZyraColors.currentDefaultPalette) return false;
    if (value == _palette) return true;
    _palette = value;
    notifyListeners();
    return true;
  }

  bool setHapticLevel(ZyraHapticLevel value) {
    if (!current) return false;
    if (value == _hapticLevel) return true;
    _hapticLevel = value;
    notifyListeners();
    return true;
  }

  bool setGoldEnabled(bool value) {
    if (!current) return false;
    if (value == _goldEnabled) return true;
    _goldEnabled = value;
    notifyListeners();
    return true;
  }

  SeekerProfile ownProfile(bool guardian) => SeekerProfile(
    id: guardian ? 'draft-own-guardian' : 'draft-self',
    firstName: guardian ? 'Hassan' : 'Adam',
    surnameLine: guardian ? 'Rahman' : 'Khan',
    age: guardian ? 54 : 30,
    city: 'London',
    gender: 'male',
    photos: photos(guardian),
    // Explicit invented public display facts for these detached personas.
    // Never read private compatibility answers or real member identity here.
    publicNationality: 'British',
    publicEthnicity: 'Pakistani',
  );

  static bool _localPhotos(List<String> value) =>
      value.length <= 6 &&
      value.every((photo) => photo.startsWith('data:image/jpeg;base64,'));

  @override
  void dispose() {
    _disposed = true;
    _revoked = true;
    _photos.clear();
    _avatar.clear();
    compatibility.close();
    super.dispose();
  }
}

/// Uses the retained editor contract with detached canonical question keys.
/// No server repository, Auth reads, preferences or AppState merging exist.
class ZyraRequestCompatibilityRepository
    implements ZyraCompatibilityEditorRepository {
  ZyraRequestCompatibilityRepository({required bool Function() canAct})
    // Keep the caller's public guard parameter separate from private storage.
    // ignore: prefer_initializing_formals
    : _canAct = canAct;

  final bool Function() _canAct;
  bool _closed = false;
  ZyraCompatibilityDraft? _draft;
  static const _owner = 'draft-self';

  bool get _current {
    if (_closed) return false;
    try {
      if (_canAct()) return true;
    } catch (_) {}
    _closed = true;
    return false;
  }

  @override
  String? get currentUserId => _current ? _owner : null;
  @override
  int get accountGeneration => 0;
  @override
  bool isCurrentOwner(String userId, int generation) =>
      userId == _owner && generation == 0 && _current;

  @override
  Future<ZyraOnboardingAnswersSnapshot?> load(String userId) async {
    if (!isCurrentOwner(userId, 0)) return null;
    return _draft?.toSnapshot();
  }

  @override
  Future<bool> save(String userId, ZyraCompatibilityDraft draft) async {
    if (!isCurrentOwner(userId, 0) || draft.gender != 'male') return false;
    final detached = draft.copy();
    if (!isCurrentOwner(userId, 0)) return false;
    _draft = detached;
    return true;
  }

  void close() {
    _closed = true;
    _draft = null;
  }
}
