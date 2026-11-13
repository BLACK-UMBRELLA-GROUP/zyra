import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/zyra_journey_stages.dart';
import '../dev/zyra_one_journey_sample_photos.dart';
import '../dev/zyra_view_request_draft_model.dart';
import '../models/seeker_profile.dart';
import '../services/zyra_account_state.dart';

enum ZyraDeveloperPast { none, mixed, samePerson }

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
  });

  final DraftProfile person;
  final DateTime date;
  final bool incoming;
  final DateTime? expiresAt;

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
  List<ZyraSamplePastRequest>? _history;
  ZyraDeveloperPast? _past;
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
    return List.unmodifiable(_active!.take(available));
  }

  List<ZyraSampleJourney>? get endedRows => isAuthorized && _ended != null
      ? List.unmodifiable(
          _ended!.where((row) => !_removedEnded.contains(row.id)),
        )
      : null;
  List<ZyraSampleRequest>? get receivedRows =>
      isAuthorized && _received != null ? List.unmodifiable(_received!) : null;
  List<ZyraSampleRequest>? get sentRows {
    if (!isAuthorized || _sent == null) return null;
    final now = _clock();
    return List.unmodifiable(
      _sent!.where((request) => !request._expiredAt(now)),
    );
  }

  List<DraftProfile>? get introductionRows =>
      isAuthorized && _introductions != null
      ? List.unmodifiable(_introductions!)
      : null;
  List<ZyraSamplePastRequest>? get history =>
      isAuthorized && _history != null ? List.unmodifiable(_history!) : null;
  int? get active => activeRows?.length;
  int? get ended => endedRows?.length;
  int? get received => receivedRows?.length;
  int? get sent => sentRows?.length;
  int? get introductions => introductionRows?.length;
  ZyraDeveloperPast? get past => isAuthorized ? _past : null;
  bool get hasSamples =>
      isAuthorized &&
      (_active != null ||
          _ended != null ||
          _received != null ||
          _sent != null ||
          _introductions != null ||
          _history != null);
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
    _clock = clock ?? DateTime.now;
    _scheduleTimeRules();
    if (changed || presentationChanged || !wasBound) notifyListeners();
  }

  void clear() {
    _reset();
    notifyListeners();
  }

  bool unbind({Object? binding}) {
    if (_authorized == null || (binding != null && _binding != binding)) {
      return false;
    }
    _authorized = null;
    _capacity = null;
    _isSeekerOne = null;
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
    _reset();
    if (hadOwner) notifyListeners();
  }

  void _reset() {
    _cancelTimeRuleTimer();
    _journeyStarts.clear();
    _removedEnded.clear();
    ++_generation;
    _active = null;
    _ended = null;
    _overridesActive = false;
    _overridesEnded = false;
    _received = null;
    _sent = null;
    _introductions = null;
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
        ),
    ];
  }

  void setIntroductions(int value) {
    if (!_permits(value) || introductions == value) return;
    _introductions = _introNames.take(value).map(_person).toList();
    _changed();
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
      request.incoming &&
      isRequestCurrent(request) &&
      !(_active?.any((row) => row.person.id == request.person.id) ?? false);

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
    if (_isSeekerOne?.call() != true ||
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
    photos: _photos?.forIndex(draftProfiles.indexOf(person)) ?? const [],
  );
}
