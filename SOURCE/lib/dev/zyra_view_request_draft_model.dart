import 'dart:collection';

import '../data/zyra_journey_life_snapshot.dart';
import '../data/zyra_journey_stages.dart';
import '../data/zyra_reference_data.dart' show zyraRelationshipLabel;

/// Disposable request/transition UI, not a new canonical server lifecycle.
/// This model has no account, storage, entitlement or backend dependency.
enum DraftJourneyState {
  received,
  sent,
  acceptedWaiting,
  preparing,
  active,
  ended,
}

/// Passive request history only; it never becomes an ended Journey attempt.
enum DraftPastRequestOutcome { notTakenUp, cancelled, youDeclined, youLetItGo }

/// Value-only local intent. Neither acceptance nor a held ending reserves a
/// place. Attempt generations prevent an old choice from ending a later pair.
typedef DraftWaitingAcceptance = ({
  bool incoming,
  int revision,
  int requestAttemptRevision,
  String? heldEndingId,
  int? heldEndingAttemptRevision,
});

final class DraftPastRequest {
  const DraftPastRequest._({
    required this.id,
    required this.profileId,
    required this.outcome,
    required this.requestedAt,
    required this.movedAt,
    required this.sequence,
    required this.incoming,
  });

  final String id, profileId;
  final DraftPastRequestOutcome outcome;
  final DateTime requestedAt, movedAt;
  final int sequence;
  final bool incoming;
}

/// Invented preview plans only; these never prove a real entitlement.
enum DraftGuardianMembership { basic, one }

/// Invented adult fixtures. Heritage labels and residence metadata below are
/// independent sample values, not inferred from names, photos or city labels,
/// and never loaded from a real member's private compatibility answers.
class DraftProfile {
  const DraftProfile({
    required this.id,
    required this.firstName,
    this.surname = '',
    required this.age,
    required this.city,
    this.residenceCountryCode,
    this.nationalityCode,
    this.ethnicityCode,
    this.sampleLatitude,
    this.sampleLongitude,
  });

  final String id;
  final String firstName;
  final String surname;
  final int age;
  final String city;
  final String? residenceCountryCode;
  final String? nationalityCode;
  final String? ethnicityCode;
  final double? sampleLatitude;
  final double? sampleLongitude;
}

const List<DraftProfile> draftProfiles = [
  DraftProfile(
    id: 'draft-amira',
    firstName: 'Amira',
    surname: 'Rahman',
    age: 28,
    city: 'Manchester',
    residenceCountryCode: 'GB',
    nationalityCode: 'GB',
    ethnicityCode: 'arab',
    sampleLatitude: 53.48,
    sampleLongitude: -2.24,
  ),
  DraftProfile(
    id: 'draft-sara',
    firstName: 'Sara',
    surname: 'Ahmed',
    age: 27,
    city: 'Birmingham',
    residenceCountryCode: 'GB',
    nationalityCode: 'PK',
    ethnicityCode: 'pakistani',
    sampleLatitude: 52.48,
    sampleLongitude: -1.90,
  ),
  DraftProfile(
    id: 'draft-aisha',
    firstName: 'Aisha',
    surname: 'Khan',
    age: 29,
    city: 'London',
    residenceCountryCode: 'GB',
    nationalityCode: 'GB',
    ethnicityCode: 'mixed',
    sampleLatitude: 51.51,
    sampleLongitude: -0.13,
  ),
  DraftProfile(
    id: 'draft-maryam',
    firstName: 'Maryam',
    surname: 'Hussain',
    age: 26,
    city: 'Leeds',
    residenceCountryCode: 'GB',
    nationalityCode: 'TR',
    ethnicityCode: 'turkish',
    sampleLatitude: 53.80,
    sampleLongitude: -1.55,
  ),
  DraftProfile(
    id: 'draft-hana',
    firstName: 'Hana',
    surname: 'Saeed',
    age: 30,
    city: 'Bristol',
    residenceCountryCode: 'GB',
    nationalityCode: 'SO',
    ethnicityCode: 'somali',
    sampleLatitude: 51.45,
    sampleLongitude: -2.59,
  ),
  DraftProfile(
    id: 'draft-noor',
    firstName: 'Noor',
    surname: 'Patel',
    age: 25,
    city: 'Nottingham',
    residenceCountryCode: 'GB',
    nationalityCode: 'BD',
    ethnicityCode: 'bangladeshi',
    sampleLatitude: 52.95,
    sampleLongitude: -1.15,
  ),
  DraftProfile(
    id: 'draft-zainab',
    firstName: 'Zainab',
    surname: 'Malik',
    age: 28,
    city: 'Cardiff',
    residenceCountryCode: 'GB',
    nationalityCode: 'MA',
    ethnicityCode: 'north_african',
    sampleLatitude: 51.48,
    sampleLongitude: -3.18,
  ),
  DraftProfile(
    id: 'draft-safiya',
    firstName: 'Safiya',
    surname: 'Ali',
    age: 27,
    city: 'Liverpool',
    residenceCountryCode: 'GB',
    nationalityCode: 'GB',
    ethnicityCode: 'black_african',
    sampleLatitude: 53.41,
    sampleLongitude: -2.98,
  ),
];

/// Presentation-only relationships. These never become live Guardian grants.
class DraftGuardian {
  const DraftGuardian({
    required this.id,
    required this.firstName,
    required this.surname,
    required this.relationshipCode,
    required this.linkedAt,
    required this.isMain,
  });

  final String id;
  final String firstName;
  final String surname;
  final String relationshipCode;
  final DateTime linkedAt;
  String get relationship =>
      zyraRelationshipLabel(relationshipCode) ?? 'Guardian';
  final bool isMain;
}

final List<DraftGuardian> draftGuardians = List.unmodifiable([
  DraftGuardian(
    id: 'draft-guardian-hassan',
    firstName: 'Hassan',
    surname: 'Rahman',
    relationshipCode: 'father',
    linkedAt: DateTime(2026, 9, 20),
    isMain: true,
  ),
  DraftGuardian(
    id: 'draft-guardian-yusuf',
    firstName: 'Yusuf',
    surname: 'Ali',
    relationshipCode: 'uncle',
    linkedAt: DateTime(2026, 9, 23),
    isMain: false,
  ),
]);

class _DraftJourneyProgress {
  bool ready = false;
  bool peerReady = false;
  int stageIndex = 0;
  bool salam = false;
  bool peerSalam = false;
  bool compatibilityConsent = false;
  bool peerCompatibilityConsent = false;
  bool compatibilityStepCompleted = false;
  bool bioStepOpen = false;
  bool bioCompleted = false;
  bool bioConsent = false;
  bool peerBioConsent = false;
  bool bioContinue = false;
  bool peerBioContinue = false;
  bool stageContinue = false;
  bool peerStageContinue = false;
}

typedef ViewRequestDraftProgressSnapshot = ({
  bool ready,
  bool peerReady,
  int stageIndex,
  bool salam,
  bool peerSalam,
  bool compatibilityConsent,
  bool peerCompatibilityConsent,
  bool compatibilityStepCompleted,
  bool bioStepOpen,
  bool bioCompleted,
  bool bioConsent,
  bool peerBioConsent,
  bool bioContinue,
  bool peerBioContinue,
  bool stageContinue,
  bool peerStageContinue,
});

ViewRequestDraftProgressSnapshot _progressValue(_DraftJourneyProgress value) =>
    (
      ready: value.ready,
      peerReady: value.peerReady,
      stageIndex: value.stageIndex,
      salam: value.salam,
      peerSalam: value.peerSalam,
      compatibilityConsent: value.compatibilityConsent,
      peerCompatibilityConsent: value.peerCompatibilityConsent,
      compatibilityStepCompleted: value.compatibilityStepCompleted,
      bioStepOpen: value.bioStepOpen,
      bioCompleted: value.bioCompleted,
      bioConsent: value.bioConsent,
      peerBioConsent: value.peerBioConsent,
      bioContinue: value.bioContinue,
      peerBioContinue: value.peerBioContinue,
      stageContinue: value.stageContinue,
      peerStageContinue: value.peerStageContinue,
    );

/// Presentation-only calendar policy. Real private reads still require their
/// server authority; a device clock, checkpoint or an unused credit is no grant.
abstract final class DraftEndedJourneyReadWindow {
  static DateTime? expiresAt(DateTime? endedAt) {
    if (endedAt == null) return null;
    final end = endedAt.toUtc();
    try {
      final lastDay = DateTime.utc(end.year, end.month + 4, 0).day;
      return DateTime.utc(
        end.year,
        end.month + 3,
        end.day > lastDay ? lastDay : end.day,
        end.hour,
        end.minute,
        end.second,
        end.millisecond,
        end.microsecond,
      );
    } on ArgumentError {
      return null;
    }
  }

  static bool isOpen(DateTime? endedAt, DateTime now) {
    final deadline = expiresAt(endedAt);
    return endedAt != null &&
        !endedAt.toUtc().isAfter(now.toUtc()) &&
        deadline != null &&
        now.toUtc().isBefore(deadline);
  }
}

/// Immutable, fictional attempt history. It contains no paid entitlement,
/// Guardian snapshot, answers or authority. A fresh attempt never adopts these
/// progress values as its current consent. Legacy missing dates stay missing.
final class DraftEndedJourneyAttempt {
  const DraftEndedJourneyAttempt._({
    required this.id,
    required this.profileId,
    required this.startedAt,
    required this.endedAt,
    required this.progress,
  });

  final String id, profileId;
  final DateTime? startedAt, endedAt;
  final ViewRequestDraftProgressSnapshot progress;

  bool hasReadWindow(DateTime now) =>
      !(startedAt != null && endedAt != null && startedAt!.isAfter(endedAt!)) &&
      DraftEndedJourneyReadWindow.isOpen(endedAt, now);
}

/// Detached, memory-only fictional values for a fresh preview owner.
///
/// No account, proof, callback, widget, repository, real member record or live
/// model reference is retained. Construction is library-private; all nested
/// collections are copied and unmodifiable, and progress uses value records.
final class ViewRequestDraftSnapshot {
  ViewRequestDraftSnapshot._(ViewRequestDraftModel model)
    : capacity = model._capacity,
      states = Map.unmodifiable(model._states),
      busyPeers = Set.unmodifiable(model._busyPeers),
      hiddenPeers = Set.unmodifiable(model._hiddenPeers),
      blockedPeers = Set.unmodifiable(model._blockedPeers),
      acknowledgedReceivedRequestIds = Set.unmodifiable(
        model._acknowledgedReceivedRequestIds,
      ),
      receivedActivityRevision = model._receivedActivityRevision,
      receivedRequestRevisions = Map.unmodifiable(
        model._receivedRequestRevisions,
      ),
      pendingRequestedAt = Map.unmodifiable(model._pendingRequestedAt),
      attemptSequence = model._attemptSequence,
      attemptRevisions = Map.unmodifiable(model._attemptRevisions),
      acceptanceIntentSequence = model._acceptanceIntentSequence,
      waitingAcceptances = Map.unmodifiable(model._waitingAcceptances),
      outgoingAcceptedActivityRevision =
          model._outgoingAcceptedActivityRevision,
      outgoingRequestAcceptedAt = Map.unmodifiable(
        model._outgoingRequestAcceptedAt,
      ),
      outgoingRequestAcceptedRevisions = Map.unmodifiable(
        model._outgoingRequestAcceptedRevisions,
      ),
      pastRequests = List.unmodifiable(model._pastRequests),
      pastRequestSequence = model._pastRequestSequence,
      journeyStartedAt = Map.unmodifiable(model._journeyStartedAt),
      journeyLastActivityAt = Map.unmodifiable(model._journeyLastActivityAt),
      endedAttempts = List.unmodifiable(model._endedAttempts),
      currentEndedAttemptIds = Map.unmodifiable(model._currentEndedAttemptIds),
      progress = Map.unmodifiable({
        for (final entry in model._progress.entries)
          entry.key: _progressValue(entry.value),
      }),
      peerMainGuardianOverrides = Map.unmodifiable(
        model._peerMainGuardianOverrides,
      ),
      guardianMemberships = Map.unmodifiable(model._guardianMemberships),
      familyGuardianChatConsent = Set.unmodifiable(
        model._familyGuardianChatConsent,
      ),
      guardianAccess = Map.unmodifiable(model._guardianAccess),
      requiredPaidGuardianAccess = Set.unmodifiable(
        model._requiredPaidGuardianAccess,
      ),
      ownMainGuardianPresent = model._ownMainGuardian,
      peerMainGuardianPresent = model._peerMainGuardian;

  final int capacity;
  final Map<String, DraftJourneyState> states;
  final Set<String> busyPeers;
  final Set<String> hiddenPeers;
  final Set<String> blockedPeers;
  final Set<String> acknowledgedReceivedRequestIds;
  final int receivedActivityRevision;
  final Map<String, int> receivedRequestRevisions;
  final Map<String, DateTime> pendingRequestedAt;
  final int attemptSequence;
  final Map<String, int> attemptRevisions;
  final int acceptanceIntentSequence;
  final Map<String, DraftWaitingAcceptance> waitingAcceptances;
  final int outgoingAcceptedActivityRevision;
  final Map<String, DateTime> outgoingRequestAcceptedAt;
  final Map<String, int> outgoingRequestAcceptedRevisions;
  final List<DraftPastRequest> pastRequests;
  final int pastRequestSequence;
  final Map<String, DateTime> journeyStartedAt;
  final Map<String, DateTime> journeyLastActivityAt;
  final List<DraftEndedJourneyAttempt> endedAttempts;
  final Map<String, String> currentEndedAttemptIds;
  final Map<String, ViewRequestDraftProgressSnapshot> progress;
  final Map<String, bool> peerMainGuardianOverrides;
  final Map<String, DraftGuardianMembership> guardianMemberships;
  final Set<String> familyGuardianChatConsent;
  final Map<String, ({bool view, bool chat})> guardianAccess;
  final Set<String> requiredPaidGuardianAccess;
  final bool ownMainGuardianPresent;
  final bool peerMainGuardianPresent;

  void _validate() {
    final peers = ViewRequestDraftModel._fixtureIds;
    final guardians = draftGuardians.map((guardian) => guardian.id).toSet();
    final occupied = states.values
        .where(
          (state) =>
              state == DraftJourneyState.preparing ||
              state == DraftJourneyState.active,
        )
        .length;
    final valid =
        capacity >= 1 &&
        capacity <= 3 &&
        occupied <= capacity &&
        states.keys.every(peers.contains) &&
        attemptSequence >= 0 &&
        attemptRevisions.keys.every(states.containsKey) &&
        states.keys.every(attemptRevisions.containsKey) &&
        attemptRevisions.values.every(
          (revision) => revision > 0 && revision <= attemptSequence,
        ) &&
        attemptRevisions.values.toSet().length == attemptRevisions.length &&
        acceptanceIntentSequence >= 0 &&
        waitingAcceptances.values
                .map((value) => value.revision)
                .toSet()
                .length ==
            waitingAcceptances.length &&
        waitingAcceptances.entries.every((entry) {
          final value = entry.value;
          final ending = value.heldEndingId;
          return states[entry.key] == DraftJourneyState.acceptedWaiting &&
              value.revision > 0 &&
              value.revision <= acceptanceIntentSequence &&
              value.requestAttemptRevision == attemptRevisions[entry.key] &&
              (value.incoming
                  ? !outgoingRequestAcceptedAt.containsKey(entry.key)
                  : outgoingRequestAcceptedAt.containsKey(entry.key)) &&
              (ending == null
                  ? value.heldEndingAttemptRevision == null
                  : value.incoming &&
                        peers.contains(ending) &&
                        ending != entry.key &&
                        value.heldEndingAttemptRevision != null &&
                        value.heldEndingAttemptRevision! > 0 &&
                        value.heldEndingAttemptRevision! <= attemptSequence);
        }) &&
        states.entries.every(
          (entry) =>
              entry.value != DraftJourneyState.acceptedWaiting ||
              waitingAcceptances.containsKey(entry.key),
        ) &&
        busyPeers.every(peers.contains) &&
        hiddenPeers.every(peers.contains) &&
        blockedPeers.every(peers.contains) &&
        acknowledgedReceivedRequestIds.every(peers.contains) &&
        receivedActivityRevision >= 0 &&
        receivedRequestRevisions.keys.every(peers.contains) &&
        receivedRequestRevisions.values.every(
          (revision) => revision > 0 && revision <= receivedActivityRevision,
        ) &&
        receivedRequestRevisions.values.toSet().length ==
            receivedRequestRevisions.length &&
        states.entries.every(
          (entry) =>
              entry.value != DraftJourneyState.received ||
              receivedRequestRevisions.containsKey(entry.key),
        ) &&
        pendingRequestedAt.entries.every(
          (entry) =>
              peers.contains(entry.key) &&
              (states[entry.key] == DraftJourneyState.received ||
                  states[entry.key] == DraftJourneyState.sent ||
                  states[entry.key] == DraftJourneyState.acceptedWaiting) &&
              entry.value.isUtc,
        ) &&
        states.entries.every(
          (entry) =>
              (entry.value != DraftJourneyState.received &&
                  entry.value != DraftJourneyState.sent &&
                  entry.value != DraftJourneyState.acceptedWaiting) ||
              pendingRequestedAt.containsKey(entry.key),
        ) &&
        outgoingAcceptedActivityRevision >= 0 &&
        outgoingRequestAcceptedAt.entries.every(
          (entry) =>
              peers.contains(entry.key) &&
              (states[entry.key] == DraftJourneyState.preparing ||
                  (states[entry.key] == DraftJourneyState.acceptedWaiting &&
                      waitingAcceptances[entry.key]?.incoming == false) ||
                  states[entry.key] == DraftJourneyState.active ||
                  states[entry.key] == DraftJourneyState.ended ||
                  (!states.containsKey(entry.key) &&
                      pastRequests.any(
                        (request) =>
                            request.profileId == entry.key &&
                            request.outcome ==
                                DraftPastRequestOutcome.youLetItGo,
                      ))) &&
              entry.value.isUtc &&
              outgoingRequestAcceptedRevisions.containsKey(entry.key),
        ) &&
        outgoingRequestAcceptedRevisions.keys.every(
          outgoingRequestAcceptedAt.containsKey,
        ) &&
        outgoingRequestAcceptedRevisions.values.every(
          (revision) =>
              revision > 0 && revision <= outgoingAcceptedActivityRevision,
        ) &&
        outgoingRequestAcceptedRevisions.values.toSet().length ==
            outgoingRequestAcceptedRevisions.length &&
        pastRequestSequence >= 0 &&
        pastRequests.map((entry) => entry.id).toSet().length ==
            pastRequests.length &&
        pastRequests.map((entry) => entry.sequence).toSet().length ==
            pastRequests.length &&
        pastRequests.every(
          (entry) =>
              peers.contains(entry.profileId) &&
              entry.id.isNotEmpty &&
              entry.sequence > 0 &&
              entry.sequence <= pastRequestSequence &&
              entry.requestedAt.isUtc &&
              entry.movedAt.isUtc &&
              !entry.requestedAt.isAfter(entry.movedAt),
        ) &&
        journeyStartedAt.keys.every(peers.contains) &&
        journeyLastActivityAt.keys.every(peers.contains) &&
        journeyLastActivityAt.values.every((value) => value.isUtc) &&
        endedAttempts.map((attempt) => attempt.id).toSet().length ==
            endedAttempts.length &&
        endedAttempts.every(
          (attempt) =>
              peers.contains(attempt.profileId) &&
              attempt.id.isNotEmpty &&
              attempt.progress.stageIndex >= 0 &&
              attempt.progress.stageIndex < ZyraJourneyStages.all.length &&
              _validDisclosureProgress(attempt.progress),
        ) &&
        currentEndedAttemptIds.entries.every(
          (entry) =>
              states[entry.key] == DraftJourneyState.ended &&
              endedAttempts.any(
                (attempt) =>
                    attempt.id == entry.value && attempt.profileId == entry.key,
              ),
        ) &&
        peerMainGuardianOverrides.keys.every(peers.contains) &&
        guardianMemberships.keys.every(guardians.contains) &&
        progress.entries.every(
          (entry) =>
              peers.contains(entry.key) &&
              states.containsKey(entry.key) &&
              states[entry.key] != DraftJourneyState.received &&
              states[entry.key] != DraftJourneyState.sent &&
              states[entry.key] != DraftJourneyState.acceptedWaiting &&
              entry.value.stageIndex >= 0 &&
              entry.value.stageIndex < ZyraJourneyStages.all.length &&
              _validDisclosureProgress(entry.value),
        ) &&
        states.entries.every(
          (entry) =>
              entry.value == DraftJourneyState.received ||
              entry.value == DraftJourneyState.sent ||
              entry.value == DraftJourneyState.acceptedWaiting ||
              progress.containsKey(entry.key),
        ) &&
        familyGuardianChatConsent.every(guardians.contains) &&
        guardianAccess.entries.every((entry) {
          final pair = entry.key.split('|');
          return pair.length == 2 &&
              guardians.contains(pair[0]) &&
              peers.contains(pair[1]) &&
              (!entry.value.chat || entry.value.view) &&
              (guardianMemberships[pair[0]] != DraftGuardianMembership.basic ||
                  !entry.value.chat);
        }) &&
        requiredPaidGuardianAccess.every((key) {
          final pair = key.split('|');
          final state = pair.length == 2 ? states[pair[1]] : null;
          final access = guardianAccess[key];
          return pair.length == 2 &&
              guardians.contains(pair[0]) &&
              peers.contains(pair[1]) &&
              guardianMemberships[pair[0]] != DraftGuardianMembership.basic &&
              state != null &&
              state != DraftJourneyState.received &&
              state != DraftJourneyState.sent &&
              state != DraftJourneyState.acceptedWaiting &&
              state != DraftJourneyState.preparing &&
              state != DraftJourneyState.ended &&
              access?.view == true &&
              access?.chat == true;
        });
    if (!valid) throw ArgumentError('Invalid fictional draft snapshot.');
  }

  static bool _validDisclosureProgress(ViewRequestDraftProgressSnapshot value) {
    final compatibilityIndex = ZyraJourneyStages.all.indexWhere(
      (stage) => stage.value == 'compatibility_reveal',
    );
    final bothCompatibility =
        value.compatibilityConsent && value.peerCompatibilityConsent;
    final bothBio = ZyraJourneyLifeSnapshotRevealPolicy.canViewSnapshot(
      mine: value.bioConsent,
      theirs: value.peerBioConsent,
    );
    // Only beginning this explicit local substep records its completion
    // marker. Legacy canonical progression neither invents Bio consent nor
    // becomes a ninth stored/server stage.
    if (value.compatibilityStepCompleted !=
        (value.bioStepOpen || value.bioCompleted)) {
      return false;
    }
    if (value.bioStepOpen &&
        (value.bioCompleted ||
            value.stageIndex != compatibilityIndex ||
            !bothCompatibility ||
            !value.stageContinue ||
            !value.peerStageContinue)) {
      return false;
    }
    if (value.bioCompleted &&
        (value.stageIndex <= compatibilityIndex ||
            !bothCompatibility ||
            !bothBio ||
            !value.bioContinue ||
            !value.peerBioContinue)) {
      return false;
    }
    if ((value.bioConsent ||
            value.peerBioConsent ||
            value.bioContinue ||
            value.peerBioContinue) &&
        !value.compatibilityStepCompleted) {
      return false;
    }
    return !(value.bioContinue || value.peerBioContinue) || bothBio;
  }
}

/// Shared fictional state for all five alternative app destinations.
///
/// Local scenario capacity is configurable from one to three. The shell owns
/// sample-plan selection; this model never proves paid entitlement. Pending
/// requests do not reserve capacity. Accepted preparation reserves BOTH places;
/// either one-sided readiness never starts the Journey or opens chat.
///
/// Pending requests are bounded only by the finite fictional fixture set.
/// No production request quota, timer, expiry or subscription rule is chosen.
/// Stage labels come from the existing pure canonical source; walkthrough
/// advancement is not real answers, Family Review time or server enforcement.
class ViewRequestDraftModel {
  ViewRequestDraftModel({int capacity = 1, DateTime Function()? clock})
    : _capacity = capacity,
      _clock = clock ?? DateTime.now {
    if (capacity < 1 || capacity > 3) {
      throw RangeError.range(capacity, 1, 3, 'capacity');
    }
    _seed();
  }

  ViewRequestDraftModel.fromSnapshot(
    ViewRequestDraftSnapshot snapshot, {
    DateTime Function()? clock,
    Iterable<DraftEndedJourneyAttempt> earlierAttempts = const [],
  }) : _capacity = snapshot.capacity,
       _clock = clock ?? DateTime.now {
    snapshot._validate();
    _states.addAll(snapshot.states);
    _busyPeers.addAll(snapshot.busyPeers);
    _hiddenPeers.addAll(snapshot.hiddenPeers);
    _blockedPeers.addAll(snapshot.blockedPeers);
    _acknowledgedReceivedRequestIds.addAll(
      snapshot.acknowledgedReceivedRequestIds,
    );
    _receivedActivityRevision = snapshot.receivedActivityRevision;
    _receivedRequestRevisions.addAll(snapshot.receivedRequestRevisions);
    _pendingRequestedAt.addAll(snapshot.pendingRequestedAt);
    _attemptSequence = snapshot.attemptSequence;
    _attemptRevisions.addAll(snapshot.attemptRevisions);
    _acceptanceIntentSequence = snapshot.acceptanceIntentSequence;
    _waitingAcceptances.addAll(snapshot.waitingAcceptances);
    _outgoingAcceptedActivityRevision =
        snapshot.outgoingAcceptedActivityRevision;
    _outgoingRequestAcceptedAt.addAll(snapshot.outgoingRequestAcceptedAt);
    _outgoingRequestAcceptedRevisions.addAll(
      snapshot.outgoingRequestAcceptedRevisions,
    );
    _pastRequests.addAll(snapshot.pastRequests);
    _pastRequestSequence = snapshot.pastRequestSequence;
    _journeyStartedAt.addAll(snapshot.journeyStartedAt);
    _journeyLastActivityAt.addAll(snapshot.journeyLastActivityAt);
    _endedAttempts.addAll(snapshot.endedAttempts);
    _currentEndedAttemptIds.addAll(snapshot.currentEndedAttemptIds);
    // Detached local fixtures can add older attempts, never replace the current
    // attempt or its progress. Production pair-wide history is a server task.
    for (final attempt in earlierAttempts) {
      if (!_fixtureIds.contains(attempt.profileId) ||
          _endedAttempts.any((existing) => existing.id == attempt.id)) {
        throw ArgumentError('Invalid fictional prior attempt.');
      }
      _endedAttempts.add(attempt);
    }
    for (final entry in snapshot.progress.entries) {
      final value = entry.value;
      _progress[entry.key] = _DraftJourneyProgress()
        ..ready = value.ready
        ..peerReady = value.peerReady
        ..stageIndex = value.stageIndex
        ..salam = value.salam
        ..peerSalam = value.peerSalam
        ..compatibilityConsent = value.compatibilityConsent
        ..peerCompatibilityConsent = value.peerCompatibilityConsent
        ..compatibilityStepCompleted = value.compatibilityStepCompleted
        ..bioStepOpen = value.bioStepOpen
        ..bioCompleted = value.bioCompleted
        ..bioConsent = value.bioConsent
        ..peerBioConsent = value.peerBioConsent
        ..bioContinue = value.bioContinue
        ..peerBioContinue = value.peerBioContinue
        ..stageContinue = value.stageContinue
        ..peerStageContinue = value.peerStageContinue;
    }
    _peerMainGuardianOverrides.addAll(snapshot.peerMainGuardianOverrides);
    _guardianMemberships.addAll(snapshot.guardianMemberships);
    _familyGuardianChatConsent.addAll(snapshot.familyGuardianChatConsent);
    _guardianAccess.addAll(snapshot.guardianAccess);
    _requiredPaidGuardianAccess.addAll(snapshot.requiredPaidGuardianAccess);
    _ownMainGuardian = snapshot.ownMainGuardianPresent;
    _peerMainGuardian = snapshot.peerMainGuardianPresent;
    this.snapshot()._validate();
  }

  ViewRequestDraftSnapshot snapshot() => ViewRequestDraftSnapshot._(this);

  static final Set<String> _fixtureIds = {
    for (final profile in draftProfiles) profile.id,
  };

  int _capacity;
  final DateTime Function() _clock;
  final Map<String, DraftJourneyState> _states = {};
  final Set<String> _busyPeers = {};
  final Set<String> _hiddenPeers = {};
  final Set<String> _blockedPeers = {};
  final Set<String> _acknowledgedReceivedRequestIds = {};
  int _receivedActivityRevision = 0;
  final Map<String, int> _receivedRequestRevisions = {};
  final Map<String, DateTime> _pendingRequestedAt = {};
  int _attemptSequence = 0;
  final Map<String, int> _attemptRevisions = {};
  int _personSafetyRevision = 0;
  int _acceptanceIntentSequence = 0;
  final Map<String, DraftWaitingAcceptance> _waitingAcceptances = {};
  int _outgoingAcceptedActivityRevision = 0;
  final Map<String, DateTime> _outgoingRequestAcceptedAt = {};
  final Map<String, int> _outgoingRequestAcceptedRevisions = {};
  final List<DraftPastRequest> _pastRequests = [];
  int _pastRequestSequence = 0;
  final Map<String, _DraftJourneyProgress> _progress = {};
  final Map<String, DateTime> _journeyStartedAt = {};
  final Map<String, DateTime> _journeyLastActivityAt = {};
  final List<DraftEndedJourneyAttempt> _endedAttempts = [];
  final Map<String, String> _currentEndedAttemptIds = {};
  final Map<String, bool> _peerMainGuardianOverrides = {};
  final Map<String, DraftGuardianMembership> _guardianMemberships = {};
  final Set<String> _familyGuardianChatConsent = {};
  final Map<String, ({bool view, bool chat})> _guardianAccess = {};
  final Set<String> _requiredPaidGuardianAccess = {};
  bool _ownMainGuardian = true;
  bool _peerMainGuardian = true;

  int get capacity => _capacity;
  Map<String, DraftJourneyState> get states => UnmodifiableMapView(_states);
  Set<String> get hiddenPeers => UnmodifiableSetView(_hiddenPeers);
  Set<String> get blockedPeers => UnmodifiableSetView(_blockedPeers);
  bool isHidden(String id) => _hiddenPeers.contains(id);
  bool isBlocked(String id) => _blockedPeers.contains(id);

  /// Capture both revisions when opening a person-level safety action. The
  /// safety revision also invalidates absent-attempt actions after reset or
  /// a completed visibility action, including an intervening unhide.
  int get personSafetyRevision => _personSafetyRevision;
  int? attemptRevisionFor(String id) => _attemptRevisions[id];

  /// The last successful local Journey action, never a server timestamp or
  /// a date fabricated from a Timeline example. Equal dates stay equal so the
  /// presentation can keep its stable fixture order when the clock ties.
  DateTime? lastActivityFor(String id) => _journeyLastActivityAt[id];

  void _recordJourneyActivity(String id) {
    _journeyLastActivityAt[id] = _clock().toUtc();
  }

  /// For an actual shell-owned local action, such as adding a sample message.
  /// Merely viewing a card or attempting a refused action is not activity.
  bool markJourneyActivity(String id) {
    if (!canParticipateInJourney(id)) return false;
    _recordJourneyActivity(id);
    return true;
  }

  /// Memory-only arrival order, independent of per-request acknowledgement.
  /// Scenario resets keep this monotonic so an older tab-open marker cannot
  /// hide a newly seeded request. A snapshot carries the same owner sequence.
  int get receivedActivityRevision => _receivedActivityRevision;

  int? receivedRequestRevision(String id) =>
      _states[id] == DraftJourneyState.received
      ? _receivedRequestRevisions[id]
      : null;

  /// Immutable evidence that the other person accepted our sent request.
  /// Incoming acceptance, seeded Active scenarios and later Journey actions
  /// never manufacture or refresh this event. A current state still needs
  /// separate validation before a presentation opens its target.
  DateTime? outgoingRequestAcceptedAt(String id) =>
      _outgoingRequestAcceptedAt[id];

  /// Stable owner ordering for clock ties. Resets clear events but retain the
  /// sequence, so a later local scenario cannot reuse an earlier revision.
  int get outgoingAcceptedActivityRevision => _outgoingAcceptedActivityRevision;
  int? outgoingRequestAcceptedRevision(String id) =>
      _outgoingRequestAcceptedRevisions[id];

  void _recordOutgoingRequestAcceptance(String id) {
    _outgoingRequestAcceptedAt[id] = _clock().toUtc();
    _outgoingRequestAcceptedRevisions[id] = ++_outgoingAcceptedActivityRevision;
  }

  /// Explicit fictional arrival only. Never overwrites a request or Journey,
  /// and never creates a member record or proves server notification state.
  bool seedReceived(String id, {DateTime? requestedAt}) {
    if (!_fixtureIds.contains(id) || _states.containsKey(id)) return false;
    _states[id] = DraftJourneyState.received;
    _attemptRevisions[id] = ++_attemptSequence;
    _outgoingRequestAcceptedAt.remove(id);
    _outgoingRequestAcceptedRevisions.remove(id);
    _pendingRequestedAt[id] = (requestedAt ?? _clock()).toUtc();
    _receivedRequestRevisions[id] = ++_receivedActivityRevision;
    // A later request from the same fixture is a new item, not the formerly
    // acknowledged request. Existing current requests keep their own state.
    _acknowledgedReceivedRequestIds.remove(id);
    return true;
  }

  /// Items stay indefinitely. A detached projection also keeps equal-date
  /// transitions deterministic, without sorting or exposing the stored list.
  List<DraftPastRequest> get pastRequests {
    final entries = _pastRequests.toList();
    entries.sort((a, b) {
      final dates = b.movedAt.compareTo(a.movedAt);
      return dates != 0 ? dates : b.sequence.compareTo(a.sequence);
    });
    return List.unmodifiable(entries);
  }

  /// Bounded, explicit fictional history; never changes a current request,
  /// Journey, notification acknowledgement or received-arrival sequence.
  bool seedPastRequest({
    required String profileId,
    required DraftPastRequestOutcome outcome,
    required DateTime requestedAt,
    required DateTime movedAt,
  }) {
    final requested = requestedAt.toUtc();
    final moved = movedAt.toUtc();
    if (!_fixtureIds.contains(profileId) ||
        _states.containsKey(profileId) ||
        requested.isAfter(moved) ||
        _pastRequests.any(
          (entry) =>
              entry.profileId == profileId &&
              entry.outcome == outcome &&
              entry.requestedAt == requested &&
              entry.movedAt == moved,
        )) {
      return false;
    }
    _recordPastRequest(profileId, outcome, requested, moved);
    return true;
  }

  void _recordPastRequest(
    String id,
    DraftPastRequestOutcome outcome,
    DateTime requestedAt,
    DateTime movedAt, {
    bool? incoming,
  }) {
    final sequence = ++_pastRequestSequence;
    _pastRequests.add(
      DraftPastRequest._(
        id: '$id:past-request:$sequence',
        profileId: id,
        outcome: outcome,
        requestedAt: requestedAt,
        movedAt: movedAt,
        sequence: sequence,
        incoming: incoming ?? outcome == DraftPastRequestOutcome.youDeclined,
      ),
    );
  }

  bool _moveRequestToPast(
    String id,
    DraftJourneyState expected,
    DraftPastRequestOutcome outcome,
  ) {
    if (_states[id] != expected) return false;
    final requestedAt = _pendingRequestedAt[id];
    final movedAt = _clock().toUtc();
    if (requestedAt == null || requestedAt.isAfter(movedAt)) return false;
    _recordPastRequest(
      id,
      outcome,
      requestedAt,
      movedAt,
      incoming:
          expected == DraftJourneyState.received ||
          _waitingAcceptances[id]?.incoming == true,
    );
    _states.remove(id);
    _attemptRevisions.remove(id);
    _waitingAcceptances.remove(id);
    _pendingRequestedAt.remove(id);
    return true;
  }

  bool _requestCooldownFinished(String id) {
    final now = _clock().toUtc();
    return !_pastRequests.any(
      (entry) =>
          entry.profileId == id &&
          !entry.incoming &&
          entry.outcome == DraftPastRequestOutcome.notTakenUp &&
          now.isBefore(entry.movedAt.add(const Duration(days: 30))),
    );
  }

  DraftEndedJourneyAttempt? currentEndedAttemptFor(String id) => _endedAttempts
      .where(
        (attempt) =>
            attempt.profileId == id &&
            attempt.id == _currentEndedAttemptIds[id],
      )
      .firstOrNull;

  List<DraftEndedJourneyAttempt> endedAttemptsFor(String id) {
    final values = _endedAttempts
        .where((attempt) => attempt.profileId == id)
        .toList();
    values.sort((a, b) {
      final aDate = a.endedAt;
      final bDate = b.endedAt;
      if (aDate == null && bDate != null) return -1;
      if (aDate != null && bDate == null) return 1;
      final dates = aDate == null ? 0 : aDate.compareTo(bDate!);
      return dates != 0 ? dates : a.id.compareTo(b.id);
    });
    return List.unmodifiable(values);
  }

  void _recordEndedAttempt(String id, {required DateTime? endedAt}) {
    final progress = _progress[id];
    if (progress == null || _currentEndedAttemptIds.containsKey(id)) return;
    final end = endedAt?.toUtc();
    final attemptId =
        '$id:${end?.microsecondsSinceEpoch ?? 'undated'}:${_endedAttempts.length + 1}';
    _endedAttempts.add(
      DraftEndedJourneyAttempt._(
        id: attemptId,
        profileId: id,
        startedAt: _journeyStartedAt[id],
        endedAt: end,
        progress: _progressValue(progress),
      ),
    );
    _currentEndedAttemptIds[id] = attemptId;
  }

  /// Presentation-only attention for a current fictional received request.
  /// Browse hiding does not hide a request from the received-request area.
  bool hasUnseenReceivedRequest(String id) =>
      _fixtureIds.contains(id) &&
      _states[id] == DraftJourneyState.received &&
      !_blockedPeers.contains(id) &&
      !_acknowledgedReceivedRequestIds.contains(id);

  /// Acknowledges only currently received, unblocked fixture requests.
  /// This never changes a request, Journey, capacity or relationship state.
  bool acknowledgeReceivedRequests(Iterable<String> ids) {
    var changed = false;
    for (final id in ids) {
      if (_fixtureIds.contains(id) &&
          _states[id] == DraftJourneyState.received &&
          !_blockedPeers.contains(id)) {
        changed = _acknowledgedReceivedRequestIds.add(id) || changed;
      }
    }
    return changed;
  }

  /// Only disposable fictional visibility changes; archive records survive.
  bool hide(String id) {
    if (!_fixtureIds.contains(id)) return false;
    if (_hiddenPeers.add(id)) _personSafetyRevision++;
    return true;
  }

  /// Removes only this preview's hide flag; never a block or relationship.
  bool unhide(String id) {
    if (!_fixtureIds.contains(id) || !_hiddenPeers.remove(id)) return false;
    _personSafetyRevision++;
    return true;
  }

  bool block(String id) {
    if (!_fixtureIds.contains(id)) return false;
    if (_blockedPeers.add(id)) _personSafetyRevision++;
    return true;
  }

  bool canApplyPersonSafety(
    String id, {
    required bool hide,
    required int? expectedAttemptRevision,
    required int expectedSafetyRevision,
    required bool endCurrentJourney,
  }) =>
      _fixtureIds.contains(id) &&
      _attemptRevisions[id] == expectedAttemptRevision &&
      _personSafetyRevision == expectedSafetyRevision &&
      _usesActivePlace(_states[id]) == endCurrentJourney &&
      !(hide ? isHidden(id) : isBlocked(id));

  /// A deliberate, synchronous local action against one exact person and
  /// occupied attempt. Validate before ending anything; accepted-waiting is
  /// never occupied and its held ending belongs to a different Journey.
  /// Ordinary hide/block APIs retain their existing visibility-only behavior.
  bool applyPersonSafety(
    String id, {
    required bool hide,
    required int? expectedAttemptRevision,
    required int expectedSafetyRevision,
    required bool endCurrentJourney,
  }) {
    if (!canApplyPersonSafety(
      id,
      hide: hide,
      expectedAttemptRevision: expectedAttemptRevision,
      expectedSafetyRevision: expectedSafetyRevision,
      endCurrentJourney: endCurrentJourney,
    )) {
      return false;
    }
    if (endCurrentJourney) end(id);
    return hide ? this.hide(id) : block(id);
  }

  int get activeCount =>
      _states.values.where((state) => state == DraftJourneyState.active).length;
  int get preparingCount => _states.values
      .where((state) => state == DraftJourneyState.preparing)
      .length;
  int get occupiedCount => activeCount + preparingCount;
  bool get hasCapacity => occupiedCount < capacity;
  bool get discoverable => hasCapacity;

  /// Viewing/sending while full stays scoped to monthly three-place previews;
  /// Basic and two-place previews retain their Browse gate. Acceptance uses
  /// its separate capacity choice. Visibility to others is still
  /// [discoverable], not permission to inspect public profiles.
  bool get canBrowse => hasCapacity || capacity == 3;

  /// Ended peers can be viewed again without resurrecting the old attempt.
  /// A fresh request to the same peer remains held until distinct attempt
  /// history is modelled; terminal records are never overwritten.
  List<DraftProfile> get discoverableProfiles => List.unmodifiable(
    draftProfiles.where((profile) {
      return !isHidden(profile.id) &&
          !isBlocked(profile.id) &&
          !peerOccupied(profile.id);
    }),
  );
  List<DraftProfile> get availableProfiles => discoverableProfiles;

  bool get ownMainGuardianPresent => _ownMainGuardian;

  bool _knownGuardian(String id) => draftGuardians.any((g) => g.id == id);

  DraftGuardianMembership? sampleGuardianMembershipFor(String id) =>
      _knownGuardian(id)
      ? (_guardianMemberships[id] ?? DraftGuardianMembership.one)
      : null;

  bool canUseSampleGuardianChat(String id) =>
      sampleGuardianMembershipFor(id) == DraftGuardianMembership.one;

  bool setSampleGuardianMembership(String id, DraftGuardianMembership value) {
    if (!_knownGuardian(id)) return false;
    _guardianMemberships[id] = value;
    if (value == DraftGuardianMembership.basic) {
      _familyGuardianChatConsent.remove(id);
      _requiredPaidGuardianAccess.removeWhere((key) => key.startsWith('$id|'));
      // Revocation is stored, not merely painted disabled. Upgrading later
      // cannot silently restore an Additional Guardian's earlier chat grant.
      for (final profile in draftProfiles) {
        final key = '$id|${profile.id}';
        final old = _guardianAccess[key];
        _guardianAccess[key] = (view: old?.view ?? true, chat: false);
      }
    }
    return true;
  }

  /// LOCK19 local consent: funded membership never restores a prior Chat grant,
  /// including Main's usual default. The Seeker must explicitly enable Chat.
  bool acceptSampleGuardianFamilyPlace(String id) {
    if (sampleGuardianMembershipFor(id) != DraftGuardianMembership.basic) {
      return false;
    }
    setSampleGuardianMembership(id, DraftGuardianMembership.basic);
    _guardianMemberships[id] = DraftGuardianMembership.one;
    _familyGuardianChatConsent.add(id);
    return true;
  }

  /// Explicit, fictional new-Journey agreement only. Membership by itself is
  /// never evidence that an older Journey was shared with an Additional.
  bool hasRequiredPaidGuardianAccess(String guardianId, String peerId) =>
      _knownGuardian(guardianId) &&
      _fixtureIds.contains(peerId) &&
      !isBlocked(peerId) &&
      canUseSampleGuardianChat(guardianId) &&
      _states[peerId] == DraftJourneyState.active &&
      _requiredPaidGuardianAccess.contains('$guardianId|$peerId');

  /// Called by the owning fictional link UI on unlink. Clear stored grants as
  /// well as agreement evidence so relinking/upgrading cannot restore chat.
  bool revokeSampleGuardianAccess(String guardianId) {
    if (!_knownGuardian(guardianId)) return false;
    _requiredPaidGuardianAccess.removeWhere(
      (key) => key.startsWith('$guardianId|'),
    );
    for (final profile in draftProfiles) {
      _guardianAccess['$guardianId|${profile.id}'] = (view: false, chat: false);
    }
    return true;
  }

  ({bool view, bool chat}) sampleGuardianAccessFor(
    String guardianId,
    String peerId, {
    bool isMain = false,
  }) {
    if (!_knownGuardian(guardianId) ||
        !_fixtureIds.contains(peerId) ||
        isBlocked(peerId)) {
      return (view: false, chat: false);
    }
    final grant =
        _guardianAccess['$guardianId|$peerId'] ?? (view: true, chat: false);
    final required = hasRequiredPaidGuardianAccess(guardianId, peerId);
    final view = isMain || required || grant.view;
    return (
      view: view,
      chat:
          canUseSampleGuardianChat(guardianId) &&
          view &&
          ((isMain && !_familyGuardianChatConsent.contains(guardianId)) ||
              required ||
              grant.chat),
    );
  }

  /// Local write boundary, independently rejecting forged Basic chat grants
  /// and retired/stale Journey destinations before recording any change.
  bool setSampleGuardianJourneyAccess(
    String guardianId,
    String peerId, {
    bool? viewEnabled,
    bool? chatEnabled,
  }) {
    final state = _states[peerId];
    if (!_knownGuardian(guardianId) ||
        isBlocked(peerId) ||
        hasRequiredPaidGuardianAccess(guardianId, peerId) ||
        state != DraftJourneyState.active ||
        (chatEnabled == true && !canUseSampleGuardianChat(guardianId))) {
      return false;
    }
    final old = sampleGuardianAccessFor(guardianId, peerId);
    final view = viewEnabled ?? old.view;
    if (chatEnabled == true && !view) return false;
    _guardianAccess['$guardianId|$peerId'] = (
      view: view,
      chat:
          view &&
          canUseSampleGuardianChat(guardianId) &&
          (chatEnabled ?? old.chat),
    );
    return true;
  }

  bool get peerMainGuardianPresent => _peerMainGuardian;
  bool peerMainGuardianPresentFor(String id) =>
      _fixtureIds.contains(id) &&
      (_peerMainGuardianOverrides[id] ?? _peerMainGuardian);
  bool _mainLeadershipPresent(String id) =>
      _ownMainGuardian && peerMainGuardianPresentFor(id);
  void setOwnMainGuardianPresent(bool present) => _ownMainGuardian = present;

  /// Without an id this retains the legacy uniform fixture control. An id
  /// changes only that fictional counterpart; own Main leadership is shared.
  bool setPeerMainGuardianPresent(bool present, {String? id}) {
    if (id != null) {
      if (!_fixtureIds.contains(id)) return false;
      _peerMainGuardianOverrides[id] = present;
    } else {
      _peerMainGuardian = present;
      _peerMainGuardianOverrides.clear();
    }
    return true;
  }

  DraftJourneyState? stateFor(String id) => _states[id];

  /// Includes this pair's reservation, without exposing another Journey's
  /// partner, reason, duration or any other private counterpart information.
  bool peerOccupied(String id) =>
      _busyPeers.contains(id) || _usesActivePlace(_states[id]);

  /// Explicit scenario control only. An occupied place already reserved for
  /// this pair cannot simultaneously be assigned to an unrelated sample pair.
  bool setPeerOccupied(String id, bool occupied) {
    if (!_fixtureIds.contains(id) ||
        (occupied && _usesActivePlace(_states[id]))) {
      return false;
    }
    if (occupied) {
      _busyPeers.add(id);
    } else {
      _busyPeers.remove(id);
    }
    return true;
  }

  bool canRequest(String id) =>
      _fixtureIds.contains(id) &&
      !isBlocked(id) &&
      !isHidden(id) &&
      !_states.containsKey(id) &&
      _requestCooldownFinished(id) &&
      canBrowse &&
      !peerOccupied(id);
  bool canAccept(String id) =>
      (_states[id] == DraftJourneyState.received ||
          _states[id] == DraftJourneyState.sent) &&
      !isBlocked(id) &&
      hasCapacity;

  /// A valid acceptance intent can reach the explicit capacity chooser while
  /// full. It does not itself accept, reserve a place or open conversation.
  bool canAttemptAccept(String id) =>
      canAccept(id) ||
      (!hasCapacity &&
          (_states[id] == DraftJourneyState.received ||
              _states[id] == DraftJourneyState.sent ||
              (isAcceptedWaiting(id) && !waitingIsIncoming(id))) &&
          !isBlocked(id));

  bool isAcceptedWaiting(String id) =>
      _states[id] == DraftJourneyState.acceptedWaiting &&
      _waitingAcceptances.containsKey(id);

  bool waitingIsIncoming(String id) =>
      isAcceptedWaiting(id) && _waitingAcceptances[id]!.incoming;

  String? heldEndingId(String id) =>
      isAcceptedWaiting(id) ? _waitingAcceptances[id]!.heldEndingId : null;

  /// A UI may capture this with its owner/route epoch. Reset never reuses it.
  int? acceptanceIntentRevision(String id) =>
      isAcceptedWaiting(id) ? _waitingAcceptances[id]!.revision : null;

  bool _validWaitingAttempt(String id) {
    final waiting = _waitingAcceptances[id];
    return isAcceptedWaiting(id) &&
        !isBlocked(id) &&
        waiting!.requestAttemptRevision == _attemptRevisions[id];
  }

  void _waitForAcceptance(
    String id, {
    required bool incoming,
    String? endingId,
  }) {
    _states[id] = DraftJourneyState.acceptedWaiting;
    _waitingAcceptances[id] = (
      incoming: incoming,
      revision: ++_acceptanceIntentSequence,
      requestAttemptRevision: _attemptRevisions[id]!,
      heldEndingId: endingId,
      heldEndingAttemptRevision: endingId == null
          ? null
          : _attemptRevisions[endingId],
    );
  }

  bool canReplaceJourneyForRequest(
    String requestId,
    String endingId, {
    required bool incoming,
  }) =>
      occupiedCount == capacity &&
      _fixtureIds.contains(requestId) &&
      _fixtureIds.contains(endingId) &&
      requestId != endingId &&
      (incoming
          ? _states[requestId] == DraftJourneyState.received
          : _validWaitingAttempt(requestId) && !waitingIsIncoming(requestId)) &&
      !isBlocked(requestId) &&
      _usesActivePlace(_states[endingId]);

  /// One synchronous fictional transition after explicit End confirmation.
  /// Validate every condition before retiring anything. There is no await,
  /// intermediate notification, fourth reservation, erased old progress or
  /// implicit readiness/chat/reveal. Real replacement needs server authority.
  bool replaceJourneyForRequest(
    String requestId,
    String endingId, {
    required bool incoming,
  }) {
    if (!canReplaceJourneyForRequest(requestId, endingId, incoming: incoming)) {
      return false;
    }
    if (incoming && _busyPeers.contains(requestId)) {
      _waitForAcceptance(requestId, incoming: true, endingId: endingId);
      return true;
    }
    end(endingId);
    // On the sent side this confirmation is the other person's held ending
    // being committed too. No counterpart Journey details are modelled.
    if (!incoming) _busyPeers.remove(requestId);
    _prepareAcceptedRequest(requestId);
    return true;
  }

  /// Explicit peer confirmation commits one exact held ending, or reserves a
  /// currently free place. Every check happens before either Journey changes.
  bool confirmWaitingRequest(String id) {
    if (!_validWaitingAttempt(id)) return false;
    if (!waitingIsIncoming(id)) {
      if (!hasCapacity) return false;
      _busyPeers.remove(id);
      _prepareAcceptedRequest(id);
      return true;
    }
    final waiting = _waitingAcceptances[id]!;
    final ending = waiting.heldEndingId;
    if (ending == null) {
      if (!hasCapacity) return false;
    } else if (!_usesActivePlace(_states[ending]) ||
        _attemptRevisions[ending] != waiting.heldEndingAttemptRevision ||
        occupiedCount > capacity) {
      return false;
    }
    if (ending != null) end(ending);
    _busyPeers.remove(id);
    _prepareAcceptedRequest(id);
    return true;
  }

  /// Passive history only. A declined held acceptance never ends a Journey.
  bool letAcceptedRequestGo(String id) {
    if (!_validWaitingAttempt(id)) return false;
    return _moveRequestToPast(
      id,
      DraftJourneyState.acceptedWaiting,
      waitingIsIncoming(id)
          ? DraftPastRequestOutcome.notTakenUp
          : DraftPastRequestOutcome.youLetItGo,
    );
  }

  /// DR-ZYRA-236: missing Main leadership holds ordinary Active participation,
  /// not just the Guardian Gate. End remains independently available.
  bool canParticipateInJourney(String id) =>
      _states[id] == DraftJourneyState.active &&
      !isBlocked(id) &&
      _mainLeadershipPresent(id);

  bool request(String id) {
    if (!canRequest(id)) return false;
    _states[id] = DraftJourneyState.sent;
    _attemptRevisions[id] = ++_attemptSequence;
    _outgoingRequestAcceptedAt.remove(id);
    _outgoingRequestAcceptedRevisions.remove(id);
    _pendingRequestedAt[id] = _clock().toUtc();
    return true;
  }

  bool cancel(String id) => _moveRequestToPast(
    id,
    DraftJourneyState.sent,
    DraftPastRequestOutcome.cancelled,
  );

  bool declineReceived(String id) => _moveRequestToPast(
    id,
    DraftJourneyState.received,
    DraftPastRequestOutcome.youDeclined,
  );

  bool acceptReceived(String id) => _accept(id, DraftJourneyState.received);
  bool simulateRecipientAccept(String id) =>
      _accept(id, DraftJourneyState.sent);

  bool _accept(String id, DraftJourneyState expected) {
    if (_states[id] != expected ||
        !(expected == DraftJourneyState.sent
            ? canAttemptAccept(id)
            : canAccept(id))) {
      return false;
    }
    if (expected == DraftJourneyState.sent) {
      _recordOutgoingRequestAcceptance(id);
      if (!hasCapacity) {
        _waitForAcceptance(id, incoming: false);
        return true;
      }
      _busyPeers.remove(id);
    } else if (_busyPeers.contains(id)) {
      _waitForAcceptance(id, incoming: true);
      return true;
    }
    _prepareAcceptedRequest(id);
    return true;
  }

  void _prepareAcceptedRequest(String id) {
    _states[id] = DraftJourneyState.preparing;
    _waitingAcceptances.remove(id);
    _pendingRequestedAt.remove(id);
    _progress[id] = _DraftJourneyProgress();
    _initializePreparationGuardianAccess(id);
    _recordJourneyActivity(id);
  }

  bool isReady(String id) => _progress[id]?.ready ?? false;
  bool peerIsReady(String id) => _progress[id]?.peerReady ?? false;

  bool markReady(String id) {
    if (isBlocked(id) ||
        _states[id] != DraftJourneyState.preparing ||
        isReady(id)) {
      return false;
    }
    _progress[id]!.ready = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool simulatePeerReady(String id) {
    if (isBlocked(id) ||
        _states[id] != DraftJourneyState.preparing ||
        peerIsReady(id)) {
      return false;
    }
    _progress[id]!.peerReady = true;
    _recordJourneyActivity(id);
    return true;
  }

  /// Readiness is mutual; beginning is deliberate and starts at Salam.
  bool beginPreparedJourney(
    String id, {
    Set<String> linkedGuardianIds = const {
      'draft-guardian-hassan',
      'draft-guardian-yusuf',
    },
    String? mainGuardianId = 'draft-guardian-hassan',
    Set<String> agreedPaidAdditionalGuardianIds = const {},
  }) {
    if (isBlocked(id) ||
        _states[id] != DraftJourneyState.preparing ||
        !isReady(id) ||
        !peerIsReady(id) ||
        _busyPeers.contains(id) ||
        occupiedCount > capacity ||
        !_validPaidAdditionalAgreement(
          linkedGuardianIds,
          mainGuardianId,
          agreedPaidAdditionalGuardianIds,
        )) {
      return false;
    }
    _states[id] = DraftJourneyState.active;
    _journeyStartedAt.putIfAbsent(id, () => _clock().toUtc());
    for (final guardianId in agreedPaidAdditionalGuardianIds) {
      final key = '$guardianId|$id';
      _guardianAccess[key] = (view: true, chat: true);
      _requiredPaidGuardianAccess.add(key);
    }
    _recordJourneyActivity(id);
    return true;
  }

  /// Legacy explicit both-person simulation, never an automatic acceptance.
  /// New UI uses the two readiness actions and deliberate begin separately.
  bool completePreparation(
    String id, {
    Set<String> linkedGuardianIds = const {
      'draft-guardian-hassan',
      'draft-guardian-yusuf',
    },
    String? mainGuardianId = 'draft-guardian-hassan',
    Set<String> agreedPaidAdditionalGuardianIds = const {},
  }) {
    if (isBlocked(id) ||
        _states[id] != DraftJourneyState.preparing ||
        _busyPeers.contains(id) ||
        occupiedCount > capacity ||
        !_validPaidAdditionalAgreement(
          linkedGuardianIds,
          mainGuardianId,
          agreedPaidAdditionalGuardianIds,
        )) {
      return false;
    }
    _progress[id]!
      ..ready = true
      ..peerReady = true;
    return beginPreparedJourney(
      id,
      linkedGuardianIds: linkedGuardianIds,
      mainGuardianId: mainGuardianId,
      agreedPaidAdditionalGuardianIds: agreedPaidAdditionalGuardianIds,
    );
  }

  bool _validPaidAdditionalAgreement(
    Set<String> linkedGuardianIds,
    String? mainGuardianId,
    Set<String> agreedPaidAdditionalGuardianIds,
  ) {
    if (!_ownMainGuardian ||
        mainGuardianId == null ||
        !_knownGuardian(mainGuardianId) ||
        !linkedGuardianIds.contains(mainGuardianId) ||
        !linkedGuardianIds.every(_knownGuardian)) {
      return false;
    }
    final paidAdditionals = linkedGuardianIds
        .where((id) => id != mainGuardianId && canUseSampleGuardianChat(id))
        .toSet();
    return paidAdditionals.length == agreedPaidAdditionalGuardianIds.length &&
        paidAdditionals.containsAll(agreedPaidAdditionalGuardianIds);
  }

  void _initializePreparationGuardianAccess(String peerId) {
    _clearRequiredPaidGuardianAccess(peerId);
    for (final guardian in draftGuardians) {
      _guardianAccess['${guardian.id}|$peerId'] = (view: false, chat: false);
    }
  }

  void _clearRequiredPaidGuardianAccess(String peerId) =>
      _requiredPaidGuardianAccess.removeWhere(
        (key) => key.endsWith('|$peerId'),
      );

  ZyraJourneyStage? stageFor(String id) {
    final progress = _progress[id];
    return progress == null ? null : ZyraJourneyStages.all[progress.stageIndex];
  }

  bool conversationOpen(String id) =>
      canParticipateInJourney(id) && stageFor(id)?.value == 'conversation';

  bool hasSentSalam(String id) => _progress[id]?.salam ?? false;
  bool peerHasSentSalam(String id) => _progress[id]?.peerSalam ?? false;
  bool salamComplete(String id) => hasSentSalam(id) && peerHasSentSalam(id);

  bool sendSalam(String id) {
    if (!_atInteractiveStage(id, 'salam_exchange') || hasSentSalam(id)) {
      return false;
    }
    _progress[id]!.salam = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool simulatePeerSalam(String id) {
    if (!_atInteractiveStage(id, 'salam_exchange') || peerHasSentSalam(id)) {
      return false;
    }
    _progress[id]!.peerSalam = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool hasChosenCompatibilityReveal(String id) =>
      _progress[id]?.compatibilityConsent ?? false;
  bool peerHasChosenCompatibilityReveal(String id) =>
      _progress[id]?.peerCompatibilityConsent ?? false;
  bool compatibilityRevealed(String id) =>
      hasChosenCompatibilityReveal(id) && peerHasChosenCompatibilityReveal(id);

  bool chooseCompatibilityReveal(String id) {
    if (!_atInteractiveStage(id, 'compatibility_reveal') ||
        hasChosenCompatibilityReveal(id)) {
      return false;
    }
    _progress[id]!.compatibilityConsent = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool simulatePeerCompatibilityReveal(String id) {
    if (!_atInteractiveStage(id, 'compatibility_reveal') ||
        peerHasChosenCompatibilityReveal(id)) {
      return false;
    }
    _progress[id]!.peerCompatibilityConsent = true;
    _recordJourneyActivity(id);
    return true;
  }

  /// Completion is a recorded mutual decision, never merely a stage number.
  /// Legacy callers can finish the canonical threshold without the optional
  /// local Bio substep, but cannot gain Bio disclosure by doing so.
  bool hasCompletedCompatibilityStep(String id) {
    final progress = _progress[id];
    if (progress == null || !compatibilityRevealed(id)) return false;
    final compatibilityIndex = ZyraJourneyStages.all.indexWhere(
      (stage) => stage.value == 'compatibility_reveal',
    );
    return progress.compatibilityStepCompleted ||
        progress.stageIndex > compatibilityIndex;
  }

  bool isBioStepOpen(String id) => _progress[id]?.bioStepOpen ?? false;
  bool hasChosenBioReveal(String id) => _progress[id]?.bioConsent ?? false;
  bool peerHasChosenBioReveal(String id) =>
      _progress[id]?.peerBioConsent ?? false;
  bool bioRevealed(String id) =>
      ZyraJourneyLifeSnapshotRevealPolicy.canViewSnapshot(
        mine: hasChosenBioReveal(id),
        theirs: peerHasChosenBioReveal(id),
      );
  bool hasChosenBioContinue(String id) => _progress[id]?.bioContinue ?? false;
  bool peerHasChosenBioContinue(String id) =>
      _progress[id]?.peerBioContinue ?? false;

  bool beginBioStep(String id) {
    if (!_atInteractiveStage(id, 'compatibility_reveal') ||
        !canAdvanceStage(id) ||
        isBioStepOpen(id) ||
        _progress[id]!.bioCompleted) {
      return false;
    }
    _progress[id]!
      ..compatibilityStepCompleted = true
      ..bioStepOpen = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool _atBioStep(String id) =>
      _atInteractiveStage(id, 'compatibility_reveal') && isBioStepOpen(id);

  bool chooseBioReveal(String id) {
    if (!_atBioStep(id) || hasChosenBioReveal(id)) return false;
    _progress[id]!.bioConsent = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool simulatePeerBioReveal(String id) {
    if (!_atBioStep(id) || peerHasChosenBioReveal(id)) return false;
    _progress[id]!.peerBioConsent = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool canChooseBioContinue(String id) =>
      _atBioStep(id) && bioRevealed(id) && !hasChosenBioContinue(id);
  bool canPeerChooseBioContinue(String id) =>
      _atBioStep(id) && bioRevealed(id) && !peerHasChosenBioContinue(id);

  bool chooseBioContinue(String id) {
    if (!canChooseBioContinue(id)) return false;
    _progress[id]!.bioContinue = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool simulatePeerBioContinue(String id) {
    if (!canPeerChooseBioContinue(id)) return false;
    _progress[id]!.peerBioContinue = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool canCompleteBioStep(String id) =>
      _atBioStep(id) &&
      bioRevealed(id) &&
      hasChosenBioContinue(id) &&
      peerHasChosenBioContinue(id);

  bool completeBioStep(String id) {
    if (!canCompleteBioStep(id)) return false;
    _progress[id]!
      ..bioStepOpen = false
      ..bioCompleted = true
      ..stageIndex += 1
      ..stageContinue = false
      ..peerStageContinue = false;
    _recordJourneyActivity(id);
    return true;
  }

  bool canViewJourneyCompatibility(String id) =>
      canParticipateInJourney(id) &&
      hasCompletedCompatibilityStep(id) &&
      compatibilityRevealed(id);

  /// Recorded completion survives End; this read alone grants no disclosure.
  bool hasCompletedBioStep(String id) => _progress[id]?.bioCompleted ?? false;

  bool canViewJourneyBio(String id) =>
      canParticipateInJourney(id) &&
      hasCompletedCompatibilityStep(id) &&
      hasCompletedBioStep(id) &&
      bioRevealed(id);

  bool hasChosenStageContinue(String id) =>
      _progress[id]?.stageContinue ?? false;
  bool peerHasChosenStageContinue(String id) =>
      _progress[id]?.peerStageContinue ?? false;

  bool canChooseStageContinue(String id) =>
      _stageCanBeCompleted(id) && !hasChosenStageContinue(id);
  bool canPeerChooseStageContinue(String id) =>
      _stageCanBeCompleted(id) && !peerHasChosenStageContinue(id);

  bool chooseStageContinue(String id) {
    if (!canChooseStageContinue(id)) return false;
    _progress[id]!.stageContinue = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool simulatePeerStageContinue(String id) {
    if (!canPeerChooseStageContinue(id)) {
      return false;
    }
    _progress[id]!.peerStageContinue = true;
    _recordJourneyActivity(id);
    return true;
  }

  bool canAdvanceStage(String id) =>
      !isBioStepOpen(id) &&
      _stageCanBeCompleted(id) &&
      hasChosenStageContinue(id) &&
      peerHasChosenStageContinue(id);

  /// Guided phase actions are sample walkthroughs, not private answers or the
  /// real timed Family Review gates. No scoring is performed anywhere here.
  bool advanceStage(String id) {
    if (!canAdvanceStage(id)) return false;
    final progress = _progress[id]!;
    progress
      ..stageIndex += 1
      ..stageContinue = false
      ..peerStageContinue = false;
    _recordJourneyActivity(id);
    return true;
  }

  bool _atInteractiveStage(String id, String stage) =>
      canParticipateInJourney(id) && stageFor(id)?.value == stage;

  bool _stageCanBeCompleted(String id) {
    final stage = stageFor(id);
    if (!canParticipateInJourney(id) ||
        stage == null ||
        stage.order >= ZyraJourneyStages.all.length) {
      return false;
    }
    return switch (stage.value) {
      'salam_exchange' => salamComplete(id),
      'compatibility_reveal' => compatibilityRevealed(id),
      'wali_gate' => _mainLeadershipPresent(id),
      _ => true,
    };
  }

  bool end(String id) {
    final state = _states[id];
    if (state == null ||
        state == DraftJourneyState.received ||
        state == DraftJourneyState.sent ||
        state == DraftJourneyState.acceptedWaiting ||
        state == DraftJourneyState.ended) {
      return false;
    }
    _recordEndedAttempt(id, endedAt: _clock());
    _states[id] = DraftJourneyState.ended;
    _clearRequiredPaidGuardianAccess(id);
    _recordJourneyActivity(id);
    return true;
  }

  /// Changes only the disposable scenario's capacity. A reduction must not
  /// silently truncate a preparation or Active Journey.
  bool setCapacity(int value) {
    if (value < 1 || value > 3 || value < occupiedCount) return false;
    _capacity = value;
    return true;
  }

  /// Clears fictional interaction state, retaining the configured local cap.
  void reset() {
    _guardianMemberships.clear();
    _familyGuardianChatConsent.clear();
    _seed();
  }

  /// Explicitly replaces the fictional scenario with one to three Active
  /// Journeys at Salam. Invalid counts preserve every existing fixture state.
  /// Each Journey owns fresh progress; this never changes a real account.
  bool seedJourneys(int count) {
    if (count < 1 || count > capacity) return false;
    _seed();
    final seededAt = _clock().toUtc();
    for (final profile in draftProfiles.skip(1).take(count)) {
      _states[profile.id] = DraftJourneyState.active;
      _attemptRevisions[profile.id] = ++_attemptSequence;
      _progress[profile.id] = _DraftJourneyProgress()
        ..ready = true
        ..peerReady = true;
      _journeyLastActivityAt[profile.id] = seededAt;
    }
    return true;
  }

  /// Explicit local full-capacity scenario. Never changes the real account.
  void fillCapacity() => seedJourneys(capacity);

  /// Optional history walkthrough, absent from a fresh draft. Repeated calls
  /// never overwrite requests, an existing Journey or checkpoint progress.
  void seedHistory() {
    final id = draftProfiles[5].id;
    if (_states.containsKey(id)) return;
    _states[id] = DraftJourneyState.ended;
    _attemptRevisions[id] = ++_attemptSequence;
    _progress[id] = _DraftJourneyProgress()
      ..ready = true
      ..peerReady = true;
    _recordEndedAttempt(id, endedAt: null);
  }

  void _seed() {
    _personSafetyRevision++;
    _states.clear();
    _attemptRevisions.clear();
    _waitingAcceptances.clear();
    _receivedRequestRevisions.clear();
    _pendingRequestedAt.clear();
    _outgoingRequestAcceptedAt.clear();
    _outgoingRequestAcceptedRevisions.clear();
    _pastRequests.clear();
    _pastRequestSequence = 0;
    _hiddenPeers.clear();
    _blockedPeers.clear();
    _acknowledgedReceivedRequestIds.clear();
    seedReceived(draftProfiles.first.id);
    _progress.clear();
    _journeyStartedAt.clear();
    _journeyLastActivityAt.clear();
    _endedAttempts.clear();
    _currentEndedAttemptIds.clear();
    _guardianAccess.clear();
    _requiredPaidGuardianAccess.clear();
    for (final entry in _guardianMemberships.entries.toList()) {
      if (entry.value == DraftGuardianMembership.basic) {
        setSampleGuardianMembership(entry.key, entry.value);
      }
    }
    _peerMainGuardianOverrides.clear();
    _busyPeers
      ..clear()
      ..add(draftProfiles.last.id);
    _ownMainGuardian = _peerMainGuardian = true;
  }

  bool _usesActivePlace(DraftJourneyState? state) =>
      state == DraftJourneyState.preparing || state == DraftJourneyState.active;
}
