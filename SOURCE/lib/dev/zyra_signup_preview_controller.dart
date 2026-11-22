import 'package:flutter/material.dart';

import 'zyra_draft_local_code_aliases.dart';
import 'zyra_dev_personal_code_fixtures.dart';

enum ZyraSignupStep {
  splash,
  welcome,
  role,
  name,
  dateOfBirth,
  gender,
  location,
  nationality,
  ethnicity,
  photos,
  relationship,
  addSeeker,
  verify,
  membership,
  accountReady,
  preferences,
  aboutYou,
  addGuardian,
  allSet,
}

/// Detached LOCK 34 rehearsal state. It never creates an account, grants a
/// membership, verifies an identity with a provider, or persists member data.
class ZyraSignupPreviewController extends ChangeNotifier {
  ZyraSignupPreviewController({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  ZyraSignupStep _step = ZyraSignupStep.splash;
  ZyraSignupStep? _pausedStep;
  bool _guardian = false;
  bool _hasAccount = false;
  bool _verified = false;
  bool _verificationDeferred = false;
  bool _setupComplete = false;
  bool _nameEdited = false;
  String _provider = 'Apple';
  String _firstName = '';
  String _surname = '';
  String _day = '', _month = '', _year = '';
  String? _gender, _location, _nationality, _relationship;
  final Set<String> _ethnicities = {};
  final List<String> _photos = [];
  String _seekerCode = '';
  String _aboutYou = '';
  bool _membershipBasic = false;

  ZyraSignupStep get step => _step;
  bool get guardian => _guardian;
  bool get hasAccount => _hasAccount;
  bool get verified => _verified;
  bool get verificationDeferred => _verificationDeferred;
  bool get setupComplete => _setupComplete;
  String get provider => _provider;
  String get firstName => _firstName;
  String get surname => _surname;
  String get day => _day;
  String get month => _month;
  String get year => _year;
  String? get gender => _gender;
  String? get location => _location;
  String? get nationality => _nationality;
  String? get relationship => _relationship;
  Set<String> get ethnicities => Set.unmodifiable(_ethnicities);
  List<String> get photos => List.unmodifiable(_photos);
  String get seekerCode => _seekerCode;
  String get aboutYou => _aboutYou;
  bool get membershipBasic => _membershipBasic;
  bool get isSetup => switch (_step) {
    ZyraSignupStep.preferences ||
    ZyraSignupStep.aboutYou ||
    ZyraSignupStep.addGuardian ||
    ZyraSignupStep.allSet => true,
    _ => false,
  };

  void start() {
    _step = ZyraSignupStep.splash;
    _pausedStep = null;
    _guardian = _hasAccount = _verified = _setupComplete = _nameEdited = false;
    _verificationDeferred = false;
    _provider = 'Apple';
    _firstName = _surname = _day = _month = _year = _seekerCode = _aboutYou =
        '';
    _gender = _location = _nationality = _relationship = null;
    _ethnicities.clear();
    _photos.clear();
    _membershipBasic = false;
    notifyListeners();
  }

  void seedSetup({
    required bool guardian,
    required bool verified,
    String firstName = 'Adam',
    String surname = 'Khan',
  }) {
    start();
    _guardian = guardian;
    _verified = verified;
    _hasAccount = true;
    // Loading an existing account must not rewrite its stored public names.
    // The edit setters below apply the current limits only when changed.
    _firstName = firstName;
    _surname = surname;
    _gender = guardian ? null : 'male';
    _step = ZyraSignupStep.accountReady;
    notifyListeners();
  }

  void chooseProvider(String provider) {
    if (_step != ZyraSignupStep.welcome) {
      return;
    }
    _provider = provider == 'Google' ? 'Google' : 'Apple';
    _firstName = _guardian ? 'Hassan' : 'Adam';
    _surname = 'Hussain';
    _step = ZyraSignupStep.role;
    notifyListeners();
  }

  // The existing admin Unverified switch changes only this local rehearsal.
  void setPreviewVerified(bool value) {
    _verified = value;
    notifyListeners();
  }

  void setGuardian(bool value) {
    if (_guardian == value) {
      return;
    }
    _guardian = value;
    if (!_nameEdited) {
      _firstName = value ? 'Hassan' : 'Adam';
    }
    notifyListeners();
  }

  void setFirstName(String value) {
    _nameEdited = true;
    _firstName = value.characters.take(30).toString();
    notifyListeners();
  }

  void setSurname(String value) {
    _nameEdited = true;
    _surname = value.characters.take(40).toString();
    notifyListeners();
  }

  void setDay(String value) {
    _day = value;
    notifyListeners();
  }

  void setMonth(String value) {
    _month = value;
    notifyListeners();
  }

  void setYear(String value) {
    _year = value;
    notifyListeners();
  }

  void setGender(String value) {
    if (value != 'male' && value != 'female') {
      return;
    }
    _gender = value;
    notifyListeners();
  }

  void setLocation(String? value) {
    _location = value;
    notifyListeners();
  }

  void setNationality(String? value) {
    _nationality = value;
    notifyListeners();
  }

  void setRelationship(String value) {
    _relationship = value;
    notifyListeners();
  }

  void setSeekerCode(String value) {
    _seekerCode = value;
    notifyListeners();
  }

  void setAboutYou(String value) {
    _aboutYou = value.characters.take(300).toString();
    notifyListeners();
  }

  void setMembershipBasic(bool value) {
    _membershipBasic = value;
    notifyListeners();
  }

  void toggleEthnicity(String value) {
    if (!_ethnicities.remove(value)) {
      _ethnicities.add(value);
    }
    notifyListeners();
  }

  void addPhoto(String value) {
    // Only the caller's bundled sample data can enter this detached controller.
    if (_photos.length >= 6 || !value.startsWith('data:image/')) {
      return;
    }
    _photos.add(value);
    notifyListeners();
  }

  void removePhoto(int index) {
    if (index < 0 || index >= _photos.length) {
      return;
    }
    _photos.removeAt(index);
    notifyListeners();
  }

  String? get linkedSeekerName {
    final entry = ZyraLocalCodeAliases.entry(
      ZyraLocalCodeContext.addSeeker,
      _seekerCode,
    );
    if (entry == null) {
      return null;
    }
    final canonical = ZyraLocalCodeAliases.canonical(
      ZyraLocalCodeContext.addSeeker,
      entry,
    );
    if (canonical == null) {
      return null;
    }
    return ZyraDevPersonalCodeFixtures.previewEntryCode(
      canonical,
      asGuardian: true,
    )?.firstName;
  }

  String? get dayError {
    if (_day.isEmpty) {
      return null;
    }
    final value = int.tryParse(_day);
    return value == null || value < 1 || value > 31
        ? 'Enter a day from 1 to 31.'
        : null;
  }

  String? get monthError {
    if (_month.isEmpty) {
      return null;
    }
    final value = int.tryParse(_month);
    return value == null || value < 1 || value > 12
        ? 'Enter a month from 1 to 12.'
        : null;
  }

  String? get yearError {
    if (_year.isEmpty) {
      return null;
    }
    final value = int.tryParse(_year);
    return _year.length != 4 ||
            value == null ||
            value < 1926 ||
            value > _now().year
        ? 'Enter your year of birth in full, for example 1997.'
        : null;
  }

  DateTime? get dateOfBirth {
    if (_day.isEmpty ||
        _month.isEmpty ||
        _year.isEmpty ||
        dayError != null ||
        monthError != null ||
        yearError != null) {
      return null;
    }
    final date = DateTime(int.parse(_year), int.parse(_month), int.parse(_day));
    return date.year == int.parse(_year) &&
            date.month == int.parse(_month) &&
            date.day == int.parse(_day)
        ? date
        : null;
  }

  int? get age {
    final date = dateOfBirth;
    if (date == null) {
      return null;
    }
    final today = _now();
    return today.year -
        date.year -
        ((today.month < date.month ||
                (today.month == date.month && today.day < date.day))
            ? 1
            : 0);
  }

  bool get under18 => age != null && age! < 18;
  bool get invalidCalendarDate =>
      _day.isNotEmpty &&
      _month.isNotEmpty &&
      _year.isNotEmpty &&
      dayError == null &&
      monthError == null &&
      yearError == null &&
      dateOfBirth == null;
  String? get dateError =>
      yearError ??
      dayError ??
      monthError ??
      (under18
          ? 'You need to be 18 or over to join ZYRA.'
          : (invalidCalendarDate ? 'Enter a valid date of birth.' : null));

  bool get canContinue => switch (_step) {
    ZyraSignupStep.name =>
      _firstName.trim().isNotEmpty && _surname.trim().isNotEmpty,
    ZyraSignupStep.dateOfBirth => dateOfBirth != null && !under18,
    ZyraSignupStep.gender => _gender != null,
    ZyraSignupStep.location => _location != null,
    ZyraSignupStep.nationality => _nationality != null,
    ZyraSignupStep.ethnicity => _ethnicities.isNotEmpty,
    ZyraSignupStep.photos => _photos.isNotEmpty,
    ZyraSignupStep.relationship => _relationship != null,
    ZyraSignupStep.addSeeker => linkedSeekerName != null,
    ZyraSignupStep.membership => _verified,
    ZyraSignupStep.splash || ZyraSignupStep.welcome => false,
    _ => true,
  };

  List<ZyraSignupStep> get _initialSteps => [
    ZyraSignupStep.role,
    ZyraSignupStep.name,
    ZyraSignupStep.dateOfBirth,
    if (_guardian) ...[
      ZyraSignupStep.relationship,
      ZyraSignupStep.addSeeker,
    ] else ...[
      ZyraSignupStep.gender,
      ZyraSignupStep.location,
      ZyraSignupStep.nationality,
      ZyraSignupStep.ethnicity,
      ZyraSignupStep.photos,
    ],
    ZyraSignupStep.verify,
    if (!_guardian && _verified) ZyraSignupStep.membership,
    ZyraSignupStep.accountReady,
  ];

  List<ZyraSignupStep> get _setupSteps => [
    if (!_guardian) ZyraSignupStep.preferences,
    ZyraSignupStep.aboutYou,
    if (!_guardian) ZyraSignupStep.addGuardian,
    ZyraSignupStep.allSet,
  ];

  double get progress {
    // The About you card starts its own setup bar, as in master s27.
    if (_step == ZyraSignupStep.aboutYou) return 0;
    final steps = isSetup ? _setupSteps : _initialSteps;
    final index = steps.indexOf(_step);
    return index < 0 ? 0 : (index + 1) / steps.length;
  }

  bool get canGoBack =>
      _step != ZyraSignupStep.splash &&
      _step != ZyraSignupStep.welcome &&
      _step != ZyraSignupStep.accountReady &&
      _step != ZyraSignupStep.aboutYou &&
      _step != ZyraSignupStep.preferences;

  void setStep(ZyraSignupStep value) {
    if (value == ZyraSignupStep.membership && (!_verified || _guardian)) {
      return;
    }
    // A fixture may position a screen; only advancing the setup sequence can
    // make its completion flag true.
    if (value != _step) _verificationDeferred = false;
    _step = value;
    notifyListeners();
  }

  void finishSplash() {
    if (_step == ZyraSignupStep.splash) {
      setStep(ZyraSignupStep.welcome);
    }
  }

  void verifyNow() {
    if (_step != ZyraSignupStep.verify) {
      return;
    }
    _verified = true;
    _verificationDeferred = false;
    _step = _guardian ? ZyraSignupStep.accountReady : ZyraSignupStep.membership;
    if (_guardian) {
      _hasAccount = true;
    }
    notifyListeners();
  }

  void verifyLater() {
    if (_step != ZyraSignupStep.verify) {
      return;
    }
    _verificationDeferred = true;
    notifyListeners();
  }

  void resumeSetup() {
    if (!_hasAccount) {
      return;
    }
    _step = _setupComplete
        ? ZyraSignupStep.allSet
        : _pausedStep ?? _setupSteps.first;
    notifyListeners();
  }

  void pauseSetup() {
    if (isSetup && _step != ZyraSignupStep.allSet) {
      _pausedStep = _step;
    }
    notifyListeners();
  }

  void advance() {
    if (!canContinue) {
      return;
    }
    if (_step == ZyraSignupStep.verify) {
      if (_verificationDeferred) {
        _step = ZyraSignupStep.accountReady;
        _hasAccount = true;
        _verificationDeferred = false;
        notifyListeners();
      } else {
        verifyNow();
      }
      return;
    }
    if (_step == ZyraSignupStep.accountReady) {
      resumeSetup();
      return;
    }
    // The payment CTA cannot advance or start a trial. Preview Skip is separate.
    if (_step == ZyraSignupStep.membership) {
      return;
    }
    _next();
  }

  void skip() {
    if (_step == ZyraSignupStep.verify) {
      if (_verificationDeferred) {
        advance();
      } else {
        verifyLater();
      }
      return;
    }
    if (_step == ZyraSignupStep.splash) {
      finishSplash();
      return;
    }
    if (_step == ZyraSignupStep.welcome ||
        _step == ZyraSignupStep.accountReady ||
        _step == ZyraSignupStep.allSet) {
      return;
    }
    _next();
  }

  void _next() {
    final steps = isSetup ? _setupSteps : _initialSteps;
    final index = steps.indexOf(_step);
    if (index < 0 || index + 1 >= steps.length) {
      return;
    }
    _step = steps[index + 1];
    if (_step == ZyraSignupStep.accountReady) {
      _hasAccount = true;
    }
    if (_step == ZyraSignupStep.allSet) {
      _setupComplete = true;
      _pausedStep = null;
    }
    notifyListeners();
  }

  void back() {
    if (!canGoBack) {
      return;
    }
    final steps = isSetup ? _setupSteps : _initialSteps;
    _verificationDeferred = false;
    final index = steps.indexOf(_step);
    if (index == 0 && !isSetup) {
      _step = ZyraSignupStep.welcome;
    } else if (index > 0) {
      _step = steps[index - 1];
    }
    notifyListeners();
  }

  bool enterZyra() => _step == ZyraSignupStep.allSet && _setupComplete;
}
