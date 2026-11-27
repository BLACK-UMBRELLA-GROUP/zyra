import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/zyra_journey_stages.dart';
import '../dev/zyra_one_journey_sample_photos.dart';
import '../dev/zyra_browse_filter.dart';
import '../dev/zyra_view_request_draft_model.dart';
import '../models/seeker_profile.dart';
import '../models/zyra_developer_preview.dart';
import '../services/zyra_account_state.dart';

enum ZyraDeveloperPast { none, mixed, samePerson }

enum ZyraSampleIntroductionOutcome { requested, declined }

class ZyraSampleIntroduction {
  const ZyraSampleIntroduction({
    required this.person,
    required this.guardianId,
    required this.guardianName,
    required this.relation,
    required this.introducedAt,
  });

  final DraftProfile person;
  final String guardianId, guardianName, relation;
  final DateTime introducedAt;
}

class ZyraSamplePastIntroduction {
  const ZyraSamplePastIntroduction._(
    this.introduction,
    this.outcome,
    this.movedAt,
    this.sequence,
  );

  final ZyraSampleIntroduction introduction;
  final ZyraSampleIntroductionOutcome outcome;
  final DateTime movedAt;
  final int sequence;

  String get label => switch (outcome) {
    ZyraSampleIntroductionOutcome.requested => 'Journey requested',
    ZyraSampleIntroductionOutcome.declined => 'You declined',
  };
}

class ZyraSampleJourney {
  const ZyraSampleJourney(this.person, this.id, {this.stage, this.endedAt});

  final DraftProfile person;
  final String id;
  final String? stage;
  final DateTime? endedAt;
  bool get preparing => stage == null && endedAt == null;
}

class ZyraSampleRequest {
  const ZyraSampleRequest(
    this.person,
    this.date, {
    required this.incoming,
    this.expiresAt,
    this.suggestedByOwnGuardian = false,
  });

  final DraftProfile person;
  final DateTime date;
  final bool incoming;
  final DateTime? expiresAt;
  final bool suggestedByOwnGuardian;

  bool _expiredAt(DateTime now) =>
      expiresAt != null && !now.isBefore(expiresAt!);
}

class ZyraSamplePastRequest {
  const ZyraSamplePastRequest._(
    this.request,
    this.status,
    this.movedAt,
    this._sequence,
    this._journeyStart,
  );

  final ZyraSampleRequest request;
  final DraftPastRequestOutcome status;
  final DateTime movedAt;
  final int _sequence, _journeyStart;

  bool get _outgoingNotTakenUp =>
      !request.incoming && status == DraftPastRequestOutcome.notTakenUp;

  String get label => switch (status) {
    DraftPastRequestOutcome.notTakenUp => 'Not taken up',
    DraftPastRequestOutcome.cancelled => 'Cancelled',
    DraftPastRequestOutcome.youDeclined => 'You declined',
    DraftPastRequestOutcome.youLetItGo => 'You let it go',
  };
}

/// Account-bound, in-memory overlay. Explicit selectors may mask an ordinary
/// list. A sample action can add a row without setting that list's selector.
class ZyraDeveloperSamples extends ChangeNotifier {
  ZyraDeveloperSamples._();

  static final instance = ZyraDeveloperSamples._();

  static final _people = {
    for (final person in draftProfiles) person.id: person,
  };
  static final _lastSampleRequest = DateTime(2026, 11, 9);
  static const _activeNames = ['sara', 'aisha', 'maryam'];
  static const _previewActiveNames = ['sara', 'maryam', 'noor'];
  static const _activeStages = [
    'phase_1',
    'salam_exchange',
    'compatibility_reveal',
  ];
  static const _endedNames = ['zainab', 'safiya', 'noor'];
  static const _receivedNames = ['amira', 'hana', 'noor'];
  static const _sentNames = ['safiya', 'zainab', 'hana'];
  static const _introNames = ['noor', 'hana', 'amira'];

  bool Function()? _authorized;
  int Function()? _capacity;
  bool Function()? _isSeekerOne;
  bool Function()? _canSendRequest;
  DateTime Function() _clock = DateTime.now;
  Timer? _timeRuleTimer;
  var _owner = (userId: null as String?, generation: -1);
  Object? _lifetime;
  Object? _binding;
  var _generation = 0;
  int _serial = 0;
  List<ZyraSampleJourney>? _active, _ended;
  bool _overridesActive = false, _overridesEnded = false;
  List<ZyraSampleRequest>? _received, _sent;
  List<DraftProfile>? _introductions;
  final _introductionHistory = <ZyraSamplePastIntroduction>[];
  List<ZyraSamplePastRequest>? _history;
  ZyraDeveloperPast? _past;
  ZyraDeveloperViewAs? _viewAs;
  int? _viewedSeekerPlaces;
  bool _unverified = false, _setupUnfinished = false;
  ZyraDeveloperPreset? _preset;
  int _notice = 0;
  String? _selectedJourneyId;
  var _realEnded = 0;
  int? _realActive;
  bool _realActiveStale = false;
  var _realIntroductions = 0;
  var _realOwner = (userId: null as String?, generation: -1);
  ZyraOneJourneySamplePhotos? _photos;
  bool _loadingPhotos = false;
  final _guardianChoices = <({String guardianId, String attemptId}), bool>{};
  final _ownReady = <String>{};
  final _peerReady = <String>{};
  final _journeyStarts = <String, int>{};
  final _removedEnded = <String>{};
  final _hiddenProfiles = <String>{};
  final _blockedProfiles = <String>{};

  bool get isAuthorized =>
      _owner ==
          (
            userId: ZyraAccountState.userId,
            generation: ZyraAccountState.generation,
          ) &&
      _owner.userId != null &&
      !ZyraAccountState.isSigningOut &&
      (_authorized?.call() ?? false);

  int get generation => _generation;
  int get capacity => isAuthorized ? (_capacity?.call() ?? 0).clamp(0, 3) : 0;
  bool get overridesActive => isAuthorized && _overridesActive;
  bool get overridesEnded => isAuthorized && _overridesEnded;
  List<ZyraSampleJourney>? get activeRows {
    if (!isAuthorized || _active == null) return null;
    final realPlaces = overridesActive ? 0 : _lastRealActive;
    final available = realPlaces == null
        ? 0
        : (capacity - realPlaces).clamp(0, capacity);
    return List.unmodifiable(
      _active!
          .where((row) => isSampleProfileVisible(row.person.id))
          .take(available),
    );
  }

  List<ZyraSampleJourney>? get endedRows => isAuthorized && _ended != null
      ? List.unmodifiable(
          _ended!.where(
            (row) =>
                !_removedEnded.contains(row.id) &&
                isSampleProfileVisible(row.person.id),
          ),
        )
      : null;
  List<ZyraSampleRequest>? get receivedRows => isAuthorized && _received != null
      ? List.unmodifiable(
          _received!.where((row) => isSampleProfileVisible(row.person.id)),
        )
      : null;
  List<ZyraSampleRequest>? get sentRows {
    if (!isAuthorized || _sent == null) return null;
    final now = _clock();
    return List.unmodifiable(
      _sent!.where(
        (request) =>
            !request._expiredAt(now) &&
            isSampleProfileVisible(request.person.id),
      ),
    );
  }

  List<DraftProfile>? get introductionRows =>
      isAuthorized && _introductions != null
      ? List.unmodifiable(
          _introductions!.where((person) => isSampleProfileVisible(person.id)),
        )
      : null;
  List<ZyraSampleIntroduction> get receivedIntroductions => [
    for (final person in introductionRows ?? const <DraftProfile>[])
      _introductionFor(person),
  ];
  List<ZyraSamplePastIntroduction> get pastIntroductions =>
      isAuthorized ? List.unmodifiable(_introductionHistory) : const [];
  List<ZyraSamplePastRequest>? get history =>
      isAuthorized && _history != null ? List.unmodifiable(_history!) : null;
  int? get active => activeRows?.length;
  int? get ended => endedRows?.length;
  int? get received => receivedRows?.length;
  int? get sent => sentRows?.length;
  int? get introductions => introductionRows?.length;
  ZyraDeveloperPast? get past => isAuthorized ? _past : null;
  ZyraDeveloperViewAs? get viewAs => isAuthorized ? _viewAs : null;
  int? get viewedSeekerPlaces => isAuthorized ? _viewedSeekerPlaces : null;
  bool get unverified => isAuthorized && _unverified;
  bool get setupUnfinished => isAuthorized && _setupUnfinished;
  ZyraDeveloperPreset? get preset => isAuthorized ? _preset : null;
  int get notice => isAuthorized ? _notice : 0;
  String? get selectedJourneyId =>
      isAuthorized &&
          (activeRows?.any((row) => row.id == _selectedJourneyId) ?? false)
      ? _selectedJourneyId
      : null;
  bool get hasSamples =>
      isAuthorized &&
      (_active != null ||
          _ended != null ||
          _received != null ||
          _sent != null ||
          _introductions != null ||
          _introductionHistory.isNotEmpty ||
          _history != null ||
          _viewAs != null ||
          _unverified ||
          _setupUnfinished ||
          _preset != null ||
          _notice != 0 ||
          _selectedJourneyId != null);
  bool get hasRealCounts =>
      _realOwner ==
      (
        userId: ZyraAccountState.userId,
        generation: ZyraAccountState.generation,
      );
  int get realEnded => hasRealCounts ? _realEnded : 0;
  int get realIntroductions => hasRealCounts ? _realIntroductions : 0;
  int? get _lastRealActive => hasRealCounts ? _realActive : null;
  int? get knownRealActive => _realActiveStale ? null : _lastRealActive;
  int get placesUsed =>
      (overridesActive ? 0 : _lastRealActive ?? 0) + (active ?? 0);
  int get endedCount => (overridesEnded ? 0 : realEnded) + (ended ?? 0);
  bool get _capacityKnown => overridesActive || knownRealActive != null;
  bool get hasSparePlace =>
      isAuthorized && _capacityKnown && placesUsed < capacity;

  bool isCurrentLease(int generation) =>
      isAuthorized && _generation == generation;

  /// Only the ordinary Seeker presentation binds the verified capability.
  /// A new presentation can restore choices for the same verified lifetime,
  /// but it cannot revive actions from the previous presentation.
  void bind({
    required bool Function() authorized,
    required int Function() capacity,
    bool Function()? isSeekerOne,
    bool Function()? canSendRequest,
    DateTime Function()? clock,
    Object? lifetime,
    Object? binding,
  }) {
    final owner = (
      userId: ZyraAccountState.userId,
      generation: ZyraAccountState.generation,
    );
    final changed = _owner != owner || _lifetime != lifetime;
    final wasBound = _authorized != null;
    final presentationChanged = wasBound && _binding != binding;
    if (changed) {
      _reset();
    } else if (presentationChanged) {
      ++_generation;
    }
    _owner = owner;
    _lifetime = lifetime;
    _binding = binding;
    _authorized = authorized;
    _capacity = capacity;
    _isSeekerOne = isSeekerOne;
    _canSendRequest = canSendRequest;
    _clock = clock ?? DateTime.now;
    _scheduleTimeRules();
    if (changed || presentationChanged || !wasBound) notifyListeners();
  }

  void clear({ZyraDeveloperViewAs? previewDefault}) {
    _reset();
    // Retire the previous overlay first so its owner restores its detached
    // baseline. A missing-membership default is a new, local sample view.
    notifyListeners();
    if (isAuthorized && previewDefault != null) setViewAs(previewDefault);
  }

  bool unbind({Object? binding}) {
    if (_authorized == null || (binding != null && _binding != binding)) {
      return false;
    }
    _authorized = null;
    _capacity = null;
    _isSeekerOne = null;
    _canSendRequest = null;
    _binding = null;
    _cancelTimeRuleTimer();
    ++_generation;
    notifyListeners();
    return true;
  }

  void discardLifetime(Object lifetime) {
    if (_lifetime == lifetime) _discard();
  }

  void resetForAccountChange() {
    _realOwner = (userId: null, generation: -1);
    _discard();
  }

  void _discard() {
    final hadOwner = _owner.userId != null;
    _owner = (userId: null, generation: -1);
    _lifetime = null;
    _binding = null;
    _authorized = null;
    _capacity = null;
    _isSeekerOne = null;
    _canSendRequest = null;
    _reset();
    if (hadOwner) notifyListeners();
  }

  void _reset() {
    _resetSelections();
    _cancelTimeRuleTimer();
    _journeyStarts.clear();
    _removedEnded.clear();
    _hiddenProfiles.clear();
    _blockedProfiles.clear();
    ++_generation;
    _active = null;
    _ended = null;
    _overridesActive = false;
    _overridesEnded = false;
    _received = null;
    _sent = null;
    _introductions = null;
    _introductionHistory.clear();
    _history = null;
    _past = null;
    _guardianChoices.clear();
    _ownReady.clear();
    _peerReady.clear();
  }

  /// Ordinary successful reads stay distinct from local sample choices.
  void recordRealCounts(
    String? userId,
    int generation, {
    int? active,
    int? ended,
    int? introductions,
  }) {
    if (userId == null ||
        ZyraAccountState.isSigningOut ||
        (userId: userId, generation: generation) !=
            (
              userId: ZyraAccountState.userId,
              generation: ZyraAccountState.generation,
            )) {
      return;
    }
    if (_realOwner != (userId: userId, generation: generation)) {
      _realOwner = (userId: userId, generation: generation);
      _realActive = null;
      _realActiveStale = false;
      _realEnded = 0;
      _realIntroductions = 0;
    }
    final nextActive = active ?? _realActive;
    final nextEnded = ended ?? _realEnded;
    final nextIntroductions = introductions ?? _realIntroductions;
    final activeRecovered = active != null && _realActiveStale;
    if (!activeRecovered &&
        nextActive == _realActive &&
        nextEnded == _realEnded &&
        nextIntroductions == _realIntroductions) {
      return;
    }
    if (activeRecovered) _realActiveStale = false;
    _realActive = nextActive;
    _realEnded = nextEnded;
    _realIntroductions = nextIntroductions;
    if (isAuthorized) notifyListeners();
  }

  /// Preserve last-known rows and counts while preventing new admissions.
  void markRealActiveUnavailable(String? userId, int generation) {
    if (!hasRealCounts ||
        _realOwner != (userId: userId, generation: generation) ||
        _realActive == null ||
        _realActiveStale) {
      return;
    }
    _realActiveStale = true;
    if (isAuthorized) notifyListeners();
  }

  DraftProfile _person(String name) => _people['draft-$name']!;

  ZyraSampleJourney _journey(
    DraftProfile person, {
    String? stage,
    DateTime? endedAt,
  }) => ZyraSampleJourney(
    person,
    'panel-journey-${++_serial}',
    stage: stage,
    endedAt: endedAt,
  );

  bool _permits(int value, {int max = 3}) =>
      isAuthorized && value >= 0 && value <= max;

  /// Changes only this verified lifetime's local preview plan.
  void setViewAs(ZyraDeveloperViewAs value) {
    if (!isAuthorized || _viewAs == value) return;
    final previousPlaces = capacity;
    _viewAs = value;
    if (value.guardian) {
      // Q174: Guardian accounts have no own Ended Journeys or notices.
      _notice = 0;
      _viewedSeekerPlaces ??= previousPlaces;
    } else {
      _viewedSeekerPlaces = value.places;
    }
    final places = _viewedSeekerPlaces ?? previousPlaces;
    final rows = _active;
    if (rows != null && rows.length > places) {
      final retired = rows.skip(places).map((row) => row.id).toSet();
      _active = rows.take(places).toList();
      _guardianChoices.removeWhere(
        (pair, _) => retired.contains(pair.attemptId),
      );
      _ownReady.removeAll(retired);
      _peerReady.removeAll(retired);
    }
    if (_selectedJourneyId != null &&
        !(_active?.any((row) => row.id == _selectedJourneyId) ?? false)) {
      _selectedJourneyId = _active?.firstOrNull?.id;
    }
    _changed();
  }

  void setUnverified(bool value) {
    if (!isAuthorized || _unverified == value) return;
    _unverified = value;
    _changed();
  }

  void setSetupUnfinished(bool value) {
    if (!isAuthorized || _setupUnfinished == value) return;
    _setupUnfinished = value;
    _changed();
  }

  void setPreset(ZyraDeveloperPreset value) {
    if (!isAuthorized || _preset == value) return;
    _preset = value;
    _changed();
  }

  void setNotice(int value) {
    if (!isAuthorized ||
        viewAs?.guardian == true ||
        value < 0 ||
        value > 6 ||
        _notice == value) {
      return;
    }
    _notice = value;
    if (value == 6) _preset = null;
    _changed();
  }

  void setSelectedJourney(String sampleAttemptId) {
    if (!isAuthorized ||
        _selectedJourneyId == sampleAttemptId ||
        !(activeRows?.any((row) => row.id == sampleAttemptId) ?? false)) {
      return;
    }
    _selectedJourneyId = sampleAttemptId;
    _changed();
  }

  /// Retained callbacks cannot address a removed or superseded sample attempt.
  /// Replacing the immutable row also retires callbacks holding its old object.
  void setJourneyStage(String sampleAttemptId, String stage) {
    if (!isAuthorized ||
        !ZyraJourneyStages.previewAll.any((value) => value.value == stage)) {
      return;
    }
    final row = activeRows
        ?.where((row) => row.id == sampleAttemptId)
        .firstOrNull;
    if (row == null || row.stage == stage) return;
    final rows = _active;
    final index = rows?.indexOf(row) ?? -1;
    if (rows == null || index < 0) return;
    rows[index] = ZyraSampleJourney(
      row.person,
      row.id,
      stage: stage,
      endedAt: row.endedAt,
    );
    _changed();
  }

  /// V2 has its own roster; the ordinary panel retains its existing V1 roster.
  /// Attempt IDs remain monotonic across resets and presentation leases.
  void setPreviewActive(int value) {
    if (!_permits(value, max: capacity)) return;
    final rows = _active;
    if (overridesActive &&
        rows != null &&
        rows.length == value &&
        List.generate(
          value,
          (index) =>
              rows[index].person.id == _person(_previewActiveNames[index]).id,
        ).every((matches) => matches)) {
      return;
    }
    _overridesActive = true;
    _active = [
      for (var index = 0; index < value; index++)
        _journey(
          _person(_previewActiveNames[index]),
          stage: _activeStages[index],
        ),
    ];
    _selectedJourneyId = _active!.firstOrNull?.id;
    _guardianChoices.clear();
    _ownReady.clear();
    _peerReady.clear();
    _changed();
  }

  void _resetSelections() {
    _viewAs = null;
    _viewedSeekerPlaces = null;
    _unverified = false;
    _setupUnfinished = false;
    _preset = null;
    _notice = 0;
    _selectedJourneyId = null;
  }

  void setActive(int value) {
    if (!_permits(value, max: capacity) ||
        (overridesActive && active == value)) {
      return;
    }
    _overridesActive = true;
    _active = _seedActive(value);
    _guardianChoices.clear();
    _ownReady.clear();
    _peerReady.clear();
    _changed();
  }

  List<ZyraSampleJourney> _seedActive(int value) => [
    for (var i = 0; i < value; i++)
      _journey(_person(_activeNames[i]), stage: _activeStages[i]),
  ];

  void setEnded(int value) {
    if (!_permits(value) || (overridesEnded && ended == value)) return;
    _overridesEnded = true;
    _removedEnded.clear();
    final now = _clock();
    _ended = [
      for (var i = 0; i < value; i++)
        _journey(
          _person(_endedNames[i]),
          stage: ZyraJourneyStages.all[i + 2].value,
          endedAt: now.subtract(Duration(days: i * 3 + 2)),
        ),
    ];
    _changed();
  }

  void setReceived(int value) {
    if (!_permits(value) || received == value) return;
    _received = _requests(_receivedNames, value, incoming: true);
    _changed();
  }

  void setSent(int value) {
    if (!_permits(value) || sent == value) return;
    _sent = _requests(_sentNames, value, incoming: false);
    _changed();
  }

  List<ZyraSampleRequest> _requests(
    List<String> names,
    int count, {
    required bool incoming,
  }) {
    final now = _clock();
    return [
      for (var i = 0; i < count; i++)
        ZyraSampleRequest(
          _person(names[i]),
          now.subtract(Duration(days: i)),
          incoming: incoming,
          suggestedByOwnGuardian: incoming && names[i] == 'amira',
        ),
    ];
  }

  void setIntroductions(int value) {
    if (!_permits(value) || introductions == value) return;
    _introductions = _introNames.take(value).map(_person).toList();
    _changed();
  }

  ZyraSampleIntroduction _introductionFor(DraftProfile person) {
    final guardian = switch (person.id) {
      'draft-noor' => (
        id: 'draft-guardian-hassan',
        name: 'Hassan',
        relation: 'Father',
      ),
      'draft-hana' => (
        id: 'draft-guardian-khadija',
        name: 'Khadija',
        relation: 'Mother',
      ),
      _ => (id: 'draft-guardian-yusuf', name: 'Yusuf', relation: 'Brother'),
    };
    return ZyraSampleIntroduction(
      person: person,
      guardianId: guardian.id,
      guardianName: guardian.name,
      relation: guardian.relation,
      introducedAt: _lastSampleRequest,
    );
  }

  bool canRequestIntroduction(DraftProfile person) =>
      hasIntroduction(person) &&
      !unverified &&
      !hasPreviewSent(person.id) &&
      canSendPreviewRequest(person.id);

  bool requestIntroduction(DraftProfile person) {
    if (!canRequestIntroduction(person)) return false;
    (_sent ??= []).insert(
      0,
      ZyraSampleRequest(person, _clock(), incoming: false),
    );
    _finishIntroduction(person, ZyraSampleIntroductionOutcome.requested);
    return true;
  }

  bool declineIntroduction(DraftProfile person) {
    if (!hasIntroduction(person)) return false;
    _finishIntroduction(person, ZyraSampleIntroductionOutcome.declined);
    return true;
  }

  void _finishIntroduction(
    DraftProfile person,
    ZyraSampleIntroductionOutcome outcome,
  ) {
    _introductions!.remove(person);
    _introductionHistory.add(
      ZyraSamplePastIntroduction._(
        _introductionFor(person),
        outcome,
        _clock(),
        ++_serial,
      ),
    );
    _introductionHistory.sort((a, b) {
      final order = b.movedAt.compareTo(a.movedAt);
      return order == 0 ? b.sequence.compareTo(a.sequence) : order;
    });
    _changed();
  }

  bool hasDeclinedIntroduction(String candidateId, String guardianId) =>
      isAuthorized &&
      _introductionHistory.any(
        (row) =>
            row.introduction.person.id == candidateId &&
            row.introduction.guardianId == guardianId &&
            row.outcome == ZyraSampleIntroductionOutcome.declined,
      );

  List<DraftProfile> guardianIntroductions(String guardianId) {
    if (!isAuthorized) return const [];
    final people = <String, DraftProfile>{};
    for (final row in [
      ...receivedIntroductions,
      ...pastIntroductions.map((row) => row.introduction),
    ]) {
      if (row.guardianId == guardianId) people[row.person.id] = row.person;
    }
    return List.unmodifiable(people.values);
  }

  void setPast(ZyraDeveloperPast value) {
    if (!isAuthorized || _past == value) return;
    _past = value;
    final last = _lastSampleRequest;
    _history = [];
    if (value == ZyraDeveloperPast.samePerson) {
      for (var i = 0; i < 20; i++) {
        final date = last.subtract(Duration(days: i * 22));
        _recordPast(
          ZyraSampleRequest(_person('sara'), date, incoming: false),
          DraftPastRequestOutcome.notTakenUp,
          date,
        );
      }
    }
    if (value != ZyraDeveloperPast.none) {
      final declined = DateTime(2026, 10, 20);
      final notTakenUp = DateTime(2026, 10, 12);
      _recordPast(
        ZyraSampleRequest(_person('maryam'), declined, incoming: true),
        DraftPastRequestOutcome.youDeclined,
        declined,
      );
      _recordPast(
        ZyraSampleRequest(_person('aisha'), notTakenUp, incoming: false),
        DraftPastRequestOutcome.notTakenUp,
        notTakenUp,
      );
    }
    _changed();
  }

  static int _newestPastFirst(
    ZyraSamplePastRequest a,
    ZyraSamplePastRequest b,
  ) {
    final order = b.movedAt.compareTo(a.movedAt);
    return order == 0 ? b._sequence.compareTo(a._sequence) : order;
  }

  void _recordPast(
    ZyraSampleRequest request,
    DraftPastRequestOutcome status,
    DateTime movedAt,
  ) {
    final rows = _history ??= [];
    rows.add(
      ZyraSamplePastRequest._(
        request,
        status,
        movedAt,
        ++_serial,
        _journeyStarts[request.person.id] ?? 0,
      ),
    );
    rows.sort(_newestPastFirst);
  }

  DateTime? pastRequestAskAgainAfter(ZyraSamplePastRequest latest) {
    if (!isAuthorized ||
        !latest._outgoingNotTakenUp ||
        !(_history?.contains(latest) ?? false)) {
      return null;
    }
    final consecutive = _history!
        .where(
          (row) =>
              row.request.person.id == latest.request.person.id &&
              row._journeyStart == latest._journeyStart &&
              row._outgoingNotTakenUp &&
              _newestPastFirst(row, latest) >= 0,
        )
        .length;
    return latest.movedAt.add(
      ViewRequestDraftModel.pastRequestWait(consecutive),
    );
  }

  bool isRequestCurrent(ZyraSampleRequest request) =>
      isAuthorized &&
      isSampleProfileVisible(request.person.id) &&
      !request._expiredAt(_clock()) &&
      ((request.incoming ? _received : _sent)?.contains(request) ?? false);

  bool declineOrCancel(ZyraSampleRequest request) {
    if (!isRequestCurrent(request)) return false;
    (request.incoming ? _received! : _sent!).remove(request);
    final now = _clock();
    _recordPast(
      request,
      request.incoming
          ? DraftPastRequestOutcome.youDeclined
          : DraftPastRequestOutcome.cancelled,
      now.isBefore(request.date) ? request.date : now,
    );
    _changed();
    return true;
  }

  bool _canReceive(ZyraSampleRequest request) =>
      !setupUnfinished &&
      request.incoming &&
      isRequestCurrent(request) &&
      !(_active?.any((row) => row.person.id == request.person.id) ?? false);

  bool hasPreviewSent(String profileId) =>
      isAuthorized && (_sent?.any((r) => r.person.id == profileId) ?? false);

  DateTime? previewRequestCooldown(String profileId) {
    if (!isAuthorized) return null;
    final rows =
        _history
            ?.where(
              (r) => r._outgoingNotTakenUp && r.request.person.id == profileId,
            )
            .toList() ??
        const <ZyraSamplePastRequest>[];
    if (rows.isEmpty) return null;
    final latest = rows.reduce((a, b) => a.movedAt.isAfter(b.movedAt) ? a : b);
    return pastRequestAskAgainAfter(latest);
  }

  // Q225: every actual outgoing sample writer uses this owner policy.
  bool get _requestAdmission {
    if (!isAuthorized) return false;
    try {
      return _canSendRequest?.call() ?? true;
    } catch (_) {
      return false;
    }
  }

  bool canSendPreviewRequest(String profileId) {
    if (!_requestAdmission ||
        setupUnfinished ||
        capacity == 0 ||
        !_people.containsKey(profileId) ||
        (_active?.any((r) => r.person.id == profileId) ?? false) ||
        (_received?.any((r) => r.person.id == profileId) ?? false)) {
      return false;
    }
    final after = previewRequestCooldown(profileId);
    return (capacity == 3 || hasSparePlace) &&
        (after == null || !_clock().isBefore(after));
  }

  /// The planned preview and its request list use the same local request.
  /// No member identity or transport is accepted by this sample-only API.
  bool togglePreviewRequest(String profileId) {
    if (!isAuthorized) return false;
    final sent = _sent?.where((r) => r.person.id == profileId).firstOrNull;
    if (sent != null) return declineOrCancel(sent);
    if (!canSendPreviewRequest(profileId)) return false;
    (_sent ??= []).insert(
      0,
      ZyraSampleRequest(_people[profileId]!, _clock(), incoming: false),
    );
    _changed();
    return true;
  }

  bool canAccept(ZyraSampleRequest request) =>
      _canReceive(request) &&
      (hasSparePlace || capacityChoices(request).isNotEmpty);

  /// Only an admitted sample Journey can give its place to a sample request.
  List<ZyraSampleJourney> capacityChoices(ZyraSampleRequest request) =>
      _canReceive(request) &&
          _capacityKnown &&
          capacity > 0 &&
          placesUsed == capacity
      ? activeRows ?? const []
      : const [];

  ZyraSampleJourney? accept(
    ZyraSampleRequest request, {
    ZyraSampleJourney? replace,
  }) {
    if (!_canReceive(request) ||
        (replace == null
            ? !hasSparePlace
            : !capacityChoices(request).contains(replace))) {
      return null;
    }
    final preparing = _journey(request.person);
    final active = _active ??= [];
    if (replace != null) {
      // Keep the replacement admitted even when another sample row is hidden
      // after a change in the real occupancy or plan.
      active[active.indexOf(replace)] = preparing;
      _retireActive(replace);
    } else {
      active.add(preparing);
    }
    _received!.remove(request);
    _changed();
    return preparing;
  }

  bool endActive(ZyraSampleJourney row) {
    if (!(activeRows?.contains(row) ?? false)) return false;
    _active!.remove(row);
    _retireActive(row);
    _changed();
    return true;
  }

  bool ready(ZyraSampleJourney row, {required bool peer}) =>
      (activeRows?.contains(row) ?? false) &&
      (peer ? _peerReady : _ownReady).contains(row.id);

  void markReady(ZyraSampleJourney row, {required bool peer}) {
    if (!row.preparing || !(activeRows?.contains(row) ?? false)) return;
    if ((peer ? _peerReady : _ownReady).add(row.id)) _changed();
  }

  bool begin(ZyraSampleJourney row) {
    if (!row.preparing || !ready(row, peer: false) || !ready(row, peer: true)) {
      return false;
    }
    _active![_active!.indexOf(row)] = ZyraSampleJourney(
      row.person,
      row.id,
      stage: ZyraJourneyStages.all.first.value,
    );
    _ownReady.remove(row.id);
    _peerReady.remove(row.id);
    _expireRestartRequests(_clock());
    _sent?.removeWhere((request) => request.person.id == row.person.id);
    _received?.removeWhere((request) => request.person.id == row.person.id);
    _journeyStarts[row.person.id] = ++_serial;
    _changed();
    return true;
  }

  void _retireActive(ZyraSampleJourney row) {
    _ownReady.remove(row.id);
    _peerReady.remove(row.id);
    _guardianChoices.removeWhere((pair, _) => pair.attemptId == row.id);
    if (row.preparing) return;
    (_ended ??= []).insert(
      0,
      _journey(row.person, stage: row.stage, endedAt: _clock()),
    );
  }

  bool removeEnded(ZyraSampleJourney row) {
    if (!(endedRows?.contains(row) ?? false)) return false;
    _removedEnded.add(row.id);
    _changed();
    return true;
  }

  List<ZyraSampleJourney> get _rankedEnded {
    // A locally removed archive stays in the same five-attempt ranking as
    // the Line 93 preview. Removal affects its visibility only.
    final ranked = _ended?.toList() ?? [];
    ranked.sort((a, b) {
      final date = b.endedAt!.compareTo(a.endedAt!);
      return date == 0 ? b.id.compareTo(a.id) : date;
    });
    return ranked;
  }

  bool mayRestart(ZyraSampleJourney row) {
    final endedAt = row.endedAt;
    if (!_requestAdmission ||
        _isSeekerOne?.call() != true ||
        endedAt == null ||
        !hasSparePlace ||
        _removedEnded.contains(row.id)) {
      return false;
    }
    final recent = _rankedEnded.take(5);
    if (!recent.contains(row)) return false;
    final person = row.person.id;
    final now = _clock();
    return identical(
          recent.firstWhere((attempt) => attempt.person.id == person),
          row,
        ) &&
        !now.isBefore(endedAt.add(ViewRequestDraftModel.restartWait)) &&
        !(_sent?.any(
              (request) =>
                  request.person.id == person && !request._expiredAt(now),
            ) ??
            false) &&
        !(_received?.any((request) => request.person.id == person) ?? false) &&
        !(_active?.any((journey) => journey.person.id == person) ?? false);
  }

  bool restart(ZyraSampleJourney row) {
    if (!mayRestart(row)) return false;
    final now = _clock();
    (_sent ??= []).insert(
      0,
      ZyraSampleRequest(
        row.person,
        now,
        incoming: false,
        expiresAt: now.add(ViewRequestDraftModel.restartLifetime),
      ),
    );
    _changed();
    return true;
  }

  bool guardianIncluded(String guardianId, String attemptId) =>
      isAuthorized &&
      (_guardianChoices[(guardianId: guardianId, attemptId: attemptId)] ??
          true);

  void setGuardianIncluded(String guardianId, String attemptId, bool included) {
    if (!(activeRows?.any((row) => row.id == attemptId) ?? false)) return;
    if (guardianIncluded(guardianId, attemptId) == included) return;
    _guardianChoices[(guardianId: guardianId, attemptId: attemptId)] = included;
    notifyListeners();
  }

  bool hasIntroduction(DraftProfile person) =>
      introductionRows?.contains(person) ?? false;

  bool isSampleProfileVisible(String id) =>
      isAuthorized &&
      !_hiddenProfiles.contains(id) &&
      !_blockedProfiles.contains(id);

  bool isSampleProfileExcluded(String id) =>
      isAuthorized &&
      (_hiddenProfiles.contains(id) || _blockedProfiles.contains(id));

  Set<String> get sampleHiddenPeers =>
      isAuthorized ? Set.unmodifiable(_hiddenProfiles) : const <String>{};

  Set<String> get sampleBlockedPeers =>
      isAuthorized ? Set.unmodifiable(_blockedProfiles) : const <String>{};

  bool hideSampleProfile(DraftProfile person) {
    if (!isSampleProfileVisible(person.id)) return false;
    _hiddenProfiles.add(person.id);
    _changed();
    return true;
  }

  bool blockSampleProfile(DraftProfile person) {
    if (!isSampleProfileVisible(person.id)) return false;
    _blockedProfiles.add(person.id);
    _changed();
    return true;
  }

  bool unhideSampleProfile(String id) {
    if (!isAuthorized || !_hiddenProfiles.remove(id)) return false;
    _changed();
    return true;
  }

  bool unblockSampleProfile(String id) {
    if (!isAuthorized || !_blockedProfiles.remove(id)) return false;
    _changed();
    return true;
  }

  void _cancelTimeRuleTimer() {
    _timeRuleTimer?.cancel();
    _timeRuleTimer = null;
  }

  void _expireRestartRequests(DateTime now) {
    final sent = _sent;
    if (sent == null) return;
    for (final request in sent.where((row) => row._expiredAt(now)).toList()) {
      sent.remove(request);
      _recordPast(
        request,
        DraftPastRequestOutcome.notTakenUp,
        request.expiresAt!,
      );
    }
  }

  void _scheduleTimeRules() {
    _cancelTimeRuleTimer();
    if (!isAuthorized) return;
    final now = _clock();
    _expireRestartRequests(now);
    DateTime? next;
    void consider(DateTime? deadline) {
      if (deadline != null &&
          deadline.isAfter(now) &&
          (next == null || deadline.isBefore(next!))) {
        next = deadline;
      }
    }

    for (final request in _sent ?? const <ZyraSampleRequest>[]) {
      consider(request.expiresAt);
    }
    if (_isSeekerOne?.call() == true) {
      for (final row in _rankedEnded.take(5)) {
        if (_removedEnded.contains(row.id)) continue;
        consider(row.endedAt?.add(ViewRequestDraftModel.restartWait));
      }
    }
    final deadline = next;
    if (deadline != null) {
      final lease = _generation;
      _timeRuleTimer = Timer(deadline.difference(now), () {
        if (isCurrentLease(lease)) _changed();
      });
    }
  }

  void _changed() {
    _scheduleTimeRules();
    if (_photos == null && !_loadingPhotos) unawaited(_loadPhotos());
    notifyListeners();
  }

  Future<void> _loadPhotos() async {
    _loadingPhotos = true;
    try {
      _photos = await ZyraOneJourneySamplePhotos.load();
      if (hasSamples) notifyListeners();
    } catch (_) {
      // The shared profile renderer supplies its local portrait placeholder.
    } finally {
      _loadingPhotos = false;
    }
  }

  SeekerProfile profileFor(DraftProfile person) => SeekerProfile(
    id: 'panel-${person.id}',
    firstName: person.firstName,
    surnameLine: person.surname,
    age: person.age,
    city: person.city,
    gender: 'female',
    seekerPlan: ZyraPlan.one,
    publicNationality: zyraBrowseNationalityLabel(person.nationalityCode),
    publicEthnicity: zyraBrowseEthnicityLabel(person.ethnicityCode),
    // The candidate's own sample Guardian, separate from Adam's Guardian who
    // put this candidate forward in the Introductions byline.
    mainGuardianRelationship: 'Father',
    photos: _photos?.forIndex(draftProfiles.indexOf(person)) ?? const [],
  );
}
