// Caller-owned account drafts for the protected Founder request-flow review.
// Retained editors use this adapter, never the authenticated member repository.
// This is not durable account data, admission, verification or payment proof.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset, StringCharacters;

import '../models/seeker_profile.dart';
import '../models/onboarding_question.dart';
import '../screens/profile/compatibility_editors.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../services/zyra_onboarding_answers_service.dart'
    show
        ZyraOnboardingAnswersSnapshot,
        ZyraPreferenceOption,
        ZyraVisiblePreferenceChecks;
import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import 'zyra_email_templates.dart';

class ZyraRequestAccountSession extends ChangeNotifier {
  ZyraRequestAccountSession({
    required bool Function() canAct,
    required ZyraDevPalette palette,
    required ZyraHapticLevel hapticLevel,
    required bool goldEnabled,
    bool legacyAmberQuickCheck = false,
    // Public constructor names intentionally do not expose private state.
    // ignore: prefer_initializing_formals
  }) : _canAct = canAct,
       _palette = ZyraColors.currentDefaultPalette,
       // ignore: prefer_initializing_formals
       _hapticLevel = hapticLevel,
       // ignore: prefer_initializing_formals
       _goldEnabled = goldEnabled {
    compatibility = ZyraRequestCompatibilityRepository(
      canAct: () => current,
      readGender: () => seekerGender,
      legacyAmberQuickCheck: legacyAmberQuickCheck,
    );
  }

  final bool Function() _canAct;
  bool _revoked = false;
  bool _disposed = false;
  final _photos = <bool, List<String>>{};
  final _avatar = <bool, Offset>{};
  final _signupProfiles = <bool, SeekerProfile>{};
  final _signupAbout = <bool, String>{};
  final _signupPhotoBaselines = <bool, List<String>?>{};
  late final ZyraRequestCompatibilityRepository compatibility;
  ZyraDevPalette _palette;
  ZyraHapticLevel _hapticLevel;
  bool _goldEnabled;
  ZyraPreviewEmailSettings _emailSettings = const ZyraPreviewEmailSettings();

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
  ZyraPreviewEmailSettings get emailSettings =>
      current ? _emailSettings : const ZyraPreviewEmailSettings();

  bool setEmailSetting(ZyraEmailSetting setting, bool enabled) {
    if (!current) return false;
    final next = _emailSettings.withValue(setting, enabled);
    if (next.value(setting) == _emailSettings.value(setting)) return true;
    _emailSettings = next;
    notifyListeners();
    return true;
  }

  String get seekerGender => _signupProfiles[false]?.gender ?? 'male';
  String? signupAbout(bool guardian) => current ? _signupAbout[guardian] : null;
  List<String> photos(bool guardian) =>
      List<String>.unmodifiable(_photos[guardian] ?? const []);
  Offset avatar(bool guardian) => _avatar[guardian] ?? Offset.zero;

  bool seedPhotos(bool guardian, List<String> value) {
    if (!current || !_localPhotos(value)) {
      return false;
    }
    // Photo preparation may finish after the local signup began. Retain that
    // original sample for Clear without replacing the chosen signup photos.
    if (_signupPhotoBaselines.containsKey(guardian) &&
        _signupPhotoBaselines[guardian] == null) {
      _signupPhotoBaselines[guardian] = List.of(value);
    }
    if (_photos.containsKey(guardian)) return false;
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

  /// Applies a detached sample only. This never creates an account, records
  /// verification, changes a plan or writes any member data.
  bool applySignup({
    required bool guardian,
    required String firstName,
    required String surname,
    required int age,
    required String gender,
    required String city,
    required String? nationality,
    required List<String> ethnicities,
    required List<String> photos,
    required ZyraCompatibilityDraft preferences,
  }) {
    if (!current ||
        !const {'male', 'female'}.contains(gender) ||
        firstName.trim().isEmpty ||
        firstName.characters.length > 30 ||
        surname.trim().isEmpty ||
        surname.characters.length > 40 ||
        age < 18 ||
        !_localPhotos(photos) ||
        (!guardian && preferences.gender != gender)) {
      return false;
    }
    final selected = List<String>.of(photos);
    final labels = List<String>.of(ethnicities);
    final profile = SeekerProfile(
      id: guardian ? 'draft-own-guardian' : 'draft-self',
      firstName: firstName.trim(),
      surnameLine: surname.trim(),
      age: age,
      city: city,
      gender: gender,
      photos: const [],
      publicNationality: nationality,
      publicEthnicity: labels.isEmpty ? null : labels.join(', '),
    );
    if (!current ||
        (!guardian &&
            !compatibility._adoptSignup(preferences, gender: gender))) {
      return false;
    }
    _signupPhotoBaselines.putIfAbsent(
      guardian,
      () => _photos[guardian]?.toList(),
    );
    _signupProfiles[guardian] = profile;
    final about = preferences.answers['bio_about_me'];
    if (about is String) {
      _signupAbout[guardian] = about;
    } else {
      _signupAbout.remove(guardian);
    }
    if (selected.isNotEmpty) _photos[guardian] = selected;
    notifyListeners();
    return true;
  }

  /// Restores the sample that preceded signup, including its local answers.
  bool clearSignup() {
    if (!current) return false;
    if (_signupProfiles.isEmpty) return true;
    _signupProfiles.clear();
    _signupAbout.clear();
    for (final entry in _signupPhotoBaselines.entries) {
      if (entry.value case final baseline?) {
        _photos[entry.key] = List.of(baseline);
      } else {
        _photos.remove(entry.key);
      }
    }
    _signupPhotoBaselines.clear();
    compatibility._clearSignup();
    notifyListeners();
    return true;
  }

  SeekerProfile ownProfile(bool guardian, {ZyraPlan? seekerPlan}) {
    final signup = _signupProfiles[guardian];
    final selectedPhotos = photos(guardian);
    return SeekerProfile(
      id: guardian ? 'draft-own-guardian' : 'draft-self',
      firstName: signup?.firstName ?? (guardian ? 'Hassan' : 'Adam'),
      surnameLine: signup?.surnameLine ?? (guardian ? 'Rahman' : 'Khan'),
      age: signup?.age ?? (guardian ? 54 : 30),
      city: signup?.city ?? 'London',
      gender: signup?.gender ?? 'male',
      photos: selectedPhotos,
      photoOne: selectedPhotos.isEmpty ? null : selectedPhotos.first,
      // Explicit invented public display facts for these detached personas.
      // Never read private compatibility answers or real member identity here.
      publicNationality: signup == null ? 'British' : signup.publicNationality,
      publicEthnicity: signup == null ? 'Pakistani' : signup.publicEthnicity,
      seekerPlan: seekerPlan,
    );
  }

  static bool _localPhotos(List<String> value) =>
      value.length <= 6 &&
      value.every((photo) => photo.startsWith('data:image/jpeg;base64,'));

  @override
  void dispose() {
    _disposed = true;
    _revoked = true;
    _photos.clear();
    _avatar.clear();
    _signupProfiles.clear();
    _signupAbout.clear();
    _signupPhotoBaselines.clear();
    compatibility.close();
    super.dispose();
  }
}

/// Uses the retained editor contract with detached canonical question keys.
/// No server repository, Auth reads, preferences or AppState merging exist.
class ZyraRequestCompatibilityRepository
    implements
        ZyraCompatibilityEditorRepository,
        ZyraPreferenceQuickCheckRepository {
  ZyraRequestCompatibilityRepository({
    required bool Function() canAct,
    String Function()? readGender,
    bool legacyAmberQuickCheck = false,
  })
    // Keep the caller's public guard parameter separate from private storage.
    // ignore: prefer_initializing_formals
    : _canAct = canAct,
       _readGender = readGender ?? _defaultGender {
    if (legacyAmberQuickCheck) {
      _legacy.addAll(const {
        (questionId: 'ch3_q33', optionValue: 'Usually all five prayers'),
        (questionId: 'ch3_q33', optionValue: 'Most days'),
        (questionId: 'ch2.sect.matrix', optionValue: 'shia'),
        (questionId: 'ch2.sect.outside_flexibility', optionValue: '*'),
        (questionId: 'ch2.revert.flexibility', optionValue: '*'),
      });
      _draft = ZyraCompatibilityDraft(
        gender: 'male',
        answers: {},
        hardRequirements: {},
        preferences: {
          'ch3_q33': {
            'Usually all five prayers': TrafficLight.yellow,
            'Most days': TrafficLight.yellow,
          },
        },
      );
      for (final option in _legacy.where(
        ZyraSetupPreferenceLights.isSetupOption,
      )) {
        _setupLights[option] = TrafficLight.yellow;
      }
    }
  }

  final bool Function() _canAct;
  final String Function() _readGender;
  static String _defaultGender() => 'male';
  bool _closed = false;
  ZyraCompatibilityDraft? _draft;
  ({
    ZyraCompatibilityDraft? draft,
    Set<ZyraPreferenceOption> legacy,
    Map<ZyraPreferenceOption, TrafficLight> setup,
  })?
  _signupBaseline;
  final Set<ZyraPreferenceOption> _legacy = {};
  final _setupLights = <ZyraPreferenceOption, TrafficLight>{};
  bool get hasPreferencesToCheck => _current && _legacy.isNotEmpty;
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
    if (!isCurrentOwner(userId, 0) || _draft?.gender != _readGender()) {
      return null;
    }
    return _draft?.toSnapshot();
  }

  @override
  Future<bool> save(String userId, ZyraCompatibilityDraft draft) async {
    if (!isCurrentOwner(userId, 0) || draft.gender != _readGender()) {
      return false;
    }
    final detached = draft.copy();
    if (!isCurrentOwner(userId, 0) || detached.gender != _readGender()) {
      return false;
    }
    _draft = detached;
    return true;
  }

  bool _adoptSignup(ZyraCompatibilityDraft draft, {required String gender}) {
    if (!_current ||
        !const {'male', 'female'}.contains(gender) ||
        draft.gender != gender) {
      return false;
    }
    final detached = draft.copy();
    if (!_current) return false;
    _signupBaseline ??= (
      draft: _draft?.copy(),
      legacy: Set.of(_legacy),
      setup: Map.of(_setupLights),
    );
    _draft = detached;
    _legacy.clear();
    _setupLights.clear();
    return true;
  }

  void _clearSignup() {
    final baseline = _signupBaseline;
    if (baseline == null) return;
    _draft = baseline.draft?.copy();
    _legacy
      ..clear()
      ..addAll(baseline.legacy);
    _setupLights
      ..clear()
      ..addAll(baseline.setup);
    _signupBaseline = null;
  }

  @override
  Future<ZyraVisiblePreferenceChecks> visiblePreferenceChecks(
    String userId,
  ) async {
    if (!isCurrentOwner(userId, 0)) {
      throw StateError('The preview account changed.');
    }
    return (
      legacyAmber: Set.of(_legacy),
      missing: const <ZyraPreferenceOption>{},
    );
  }

  @override
  Future<ZyraSetupPreferenceLights?> loadSetupPreferenceLights(
    String userId,
  ) async {
    if (!isCurrentOwner(userId, 0)) return null;
    return ZyraSetupPreferenceLights(lights: _setupLights);
  }

  @override
  Future<void> confirmPreferenceLight(
    String userId,
    ZyraPreferenceOption option,
    TrafficLight light,
  ) async {
    final setup =
        ZyraSetupPreferenceLights.isSetupOption(option) &&
        (option.questionId != 'ch2.sect.matrix' ||
            const {'sunni', 'shia', 'other'}.contains(option.optionValue));
    if (!isCurrentOwner(userId, 0) || (!setup && !_legacy.contains(option))) {
      throw StateError('The preview preference is unavailable.');
    }
    if (setup) {
      _setupLights[option] = light;
    } else {
      (_draft!.preferences[option.questionId] ??= {})[option.optionValue] =
          light;
    }
    _legacy.remove(option);
  }

  void close() {
    _closed = true;
    _draft = null;
    _signupBaseline = null;
    _legacy.clear();
    _setupLights.clear();
  }
}
