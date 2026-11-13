import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/zyra_journey_stages.dart';
import '../dev/zyra_one_journey_sample_photos.dart';
import '../dev/zyra_view_request_draft_model.dart';
import '../models/seeker_profile.dart';
import '../services/zyra_account_state.dart';
import 'app_state.dart';

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
  const ZyraSampleRequest(this.person, this.date, {required this.incoming});

  final DraftProfile person;
  final DateTime date;
  final bool incoming;
}

class ZyraSamplePastRequest {
  const ZyraSamplePastRequest(this.request, this.status);

  final ZyraSampleRequest request;
  final DraftPastRequestOutcome status;

  String get label => switch (status) {
    DraftPastRequestOutcome.notTakenUp => 'Not taken up',
    DraftPastRequestOutcome.cancelled => 'Cancelled',
    DraftPastRequestOutcome.youDeclined => 'You declined',
    DraftPastRequestOutcome.youLetItGo => 'You let it go',
  };
}

/// Account-bound, in-memory overlay. Null means the ordinary source owns the
/// dimension. An empty list is an explicit sample state and masks that source.
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
  var _owner = (userId: null as String?, generation: -1);
  var _generation = 0;
  int _serial = 0;
  List<ZyraSampleJourney>? _active, _ended;
  List<ZyraSampleRequest>? _received, _sent;
  List<DraftProfile>? _introductions;
  List<ZyraSamplePastRequest>? _history;
  ZyraDeveloperPast? _past;
  var _realEnded = 0;
  var _realIntroductions = 0;
  var _realOwner = (userId: null as String?, generation: -1);
  ZyraOneJourneySamplePhotos? _photos;
  bool _loadingPhotos = false;
  final _guardianChoices = <({String guardianId, String attemptId}), bool>{};
  final _ownReady = <String>{};
  final _peerReady = <String>{};

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
  List<ZyraSampleJourney>? get activeRows => isAuthorized && _active != null
      ? List.unmodifiable(_active!.take(capacity))
      : null;
  List<ZyraSampleJourney>? get endedRows =>
      isAuthorized && _ended != null ? List.unmodifiable(_ended!) : null;
  List<ZyraSampleRequest>? get receivedRows =>
      isAuthorized && _received != null ? List.unmodifiable(_received!) : null;
  List<ZyraSampleRequest>? get sentRows =>
      isAuthorized && _sent != null ? List.unmodifiable(_sent!) : null;
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
  int get realActive => AppState.instance.activeJourneys.length;
  int get placesUsed => active ?? realActive;

  /// The ordinary Seeker session owner installs and retires this capability.
  /// It does not grant access to the separate Founder preview.
  void bind({
    required bool Function() authorized,
    required int Function() capacity,
  }) {
    final owner = (
      userId: ZyraAccountState.userId,
      generation: ZyraAccountState.generation,
    );
    final changed = _owner != owner;
    if (changed) _reset();
    _owner = owner;
    _authorized = authorized;
    _capacity = capacity;
    if (changed) notifyListeners();
  }

  void clear() {
    _reset();
    notifyListeners();
  }

  void unbind() {
    _authorized = null;
    _capacity = null;
    _owner = (userId: null, generation: -1);
    clear();
  }

  void _reset() {
    ++_generation;
    _active = null;
    _ended = null;
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
      _realEnded = 0;
      _realIntroductions = 0;
    }
    final nextEnded = ended ?? _realEnded;
    final nextIntroductions = introductions ?? _realIntroductions;
    if (nextEnded == _realEnded && nextIntroductions == _realIntroductions) {
      return;
    }
    _realEnded = nextEnded;
    _realIntroductions = nextIntroductions;
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
    if (!_permits(value, max: capacity) || active == value) return;
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
    if (!_permits(value) || ended == value) return;
    final now = DateTime.now();
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
    final now = DateTime.now();
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
    _history = [
      if (value == ZyraDeveloperPast.samePerson)
        for (var i = 0; i < 20; i++)
          ZyraSamplePastRequest(
            ZyraSampleRequest(
              _person('sara'),
              last.subtract(Duration(days: i * 22)),
              incoming: false,
            ),
            DraftPastRequestOutcome.notTakenUp,
          ),
      if (value != ZyraDeveloperPast.none) ...[
        ZyraSamplePastRequest(
          ZyraSampleRequest(
            _person('maryam'),
            DateTime(2026, 10, 20),
            incoming: true,
          ),
          DraftPastRequestOutcome.youDeclined,
        ),
        ZyraSamplePastRequest(
          ZyraSampleRequest(
            _person('aisha'),
            DateTime(2026, 10, 12),
            incoming: false,
          ),
          DraftPastRequestOutcome.notTakenUp,
        ),
      ],
    ]..sort((a, b) => b.request.date.compareTo(a.request.date));
    _changed();
  }

  bool isRequestCurrent(ZyraSampleRequest request) =>
      isAuthorized &&
      ((request.incoming ? _received : _sent)?.contains(request) ?? false);

  bool declineOrCancel(ZyraSampleRequest request) {
    if (!isRequestCurrent(request)) return false;
    (request.incoming ? _received! : _sent!).remove(request);
    (_history ??= []).insert(
      0,
      ZyraSamplePastRequest(
        request,
        request.incoming
            ? DraftPastRequestOutcome.youDeclined
            : DraftPastRequestOutcome.cancelled,
      ),
    );
    _changed();
    return true;
  }

  /// Fictional choices when a sample request meets a full real plan. Real
  /// matches remain intact when the overlay is cleared.
  List<ZyraSampleJourney> capacityChoices(ZyraSampleRequest request) {
    if (!isRequestCurrent(request) || !request.incoming || capacity == 0) {
      return const [];
    }
    return activeRows ?? _seedActive(realActive.clamp(0, capacity));
  }

  ZyraSampleJourney? accept(
    ZyraSampleRequest request, {
    List<ZyraSampleJourney>? choices,
    ZyraSampleJourney? replace,
  }) {
    if (!isRequestCurrent(request) || !request.incoming || capacity == 0) {
      return null;
    }
    final active = activeRows ?? choices ?? capacityChoices(request);
    if (active.any((item) => item.person.id == request.person.id)) return null;
    final full = placesUsed >= capacity;
    if (full != (replace != null) ||
        (replace != null && !active.contains(replace)) ||
        active.length != placesUsed.clamp(0, capacity)) {
      return null;
    }
    final preparing = _journey(request.person);
    _active = [
      for (final item in active)
        if (!identical(item, replace)) item,
      preparing,
    ];
    if (replace != null) _retireActive(replace);
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
      _journey(row.person, stage: row.stage, endedAt: DateTime.now()),
    );
  }

  bool removeEnded(ZyraSampleJourney row) {
    if (!(endedRows?.contains(row) ?? false)) return false;
    _ended!.remove(row);
    _changed();
    return true;
  }

  bool mayRestart(ZyraSampleJourney row) =>
      (endedRows?.contains(row) ?? false) &&
      row.endedAt != null &&
      DateTime.now().difference(row.endedAt!) >=
          ViewRequestDraftModel.restartWait &&
      !(_sent?.any((request) => request.person.id == row.person.id) ?? false) &&
      !(_active?.any((journey) => journey.person.id == row.person.id) ?? false);

  bool restart(ZyraSampleJourney row) {
    if (!mayRestart(row)) return false;
    (_sent ??= []).insert(
      0,
      ZyraSampleRequest(row.person, DateTime.now(), incoming: false),
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
    _guardianChoices[(guardianId: guardianId, attemptId: attemptId)] = included;
  }

  bool hasIntroduction(DraftProfile person) =>
      introductionRows?.contains(person) ?? false;

  void _changed() {
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
