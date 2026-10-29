import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

void main() {
  late ViewRequestDraftModel model;
  final received = draftProfiles.first.id;
  final first = draftProfiles[1].id;
  final second = draftProfiles[2].id;
  final third = draftProfiles[3].id;

  void start(String id) {
    expect(model.request(id), isTrue);
    expect(model.simulateRecipientAccept(id), isTrue);
    expect(
      model.completePreparation(
        id,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isTrue,
    );
  }

  setUp(() => model = ViewRequestDraftModel());

  test(
    'Ended read window uses exact clamped calendar months, not ninety days',
    () {
      final cases = [
        (
          DateTime.utc(2026, 1, 31, 12, 34, 56, 789, 123),
          DateTime.utc(2026, 4, 30, 12, 34, 56, 789, 123),
        ),
        (DateTime.utc(2027, 11, 30, 8), DateTime.utc(2028, 2, 29, 8)),
        (DateTime.utc(2026, 11, 30, 8), DateTime.utc(2027, 2, 28, 8)),
        (DateTime.utc(2028, 2, 29, 8), DateTime.utc(2028, 5, 29, 8)),
        (DateTime.utc(2026, 8, 31, 8), DateTime.utc(2026, 11, 30, 8)),
      ];
      for (final (end, deadline) in cases) {
        expect(DraftEndedJourneyReadWindow.expiresAt(end), deadline);
        expect(DraftEndedJourneyReadWindow.isOpen(end, end), isTrue);
        expect(
          DraftEndedJourneyReadWindow.isOpen(
            end,
            deadline.subtract(const Duration(microseconds: 1)),
          ),
          isTrue,
        );
        expect(DraftEndedJourneyReadWindow.isOpen(end, deadline), isFalse);
        expect(
          DraftEndedJourneyReadWindow.isOpen(
            end,
            deadline.add(const Duration(microseconds: 1)),
          ),
          isFalse,
        );
      }
      final end = DateTime.utc(2026, 1, 31);
      expect(
        DraftEndedJourneyReadWindow.expiresAt(end),
        isNot(end.add(const Duration(days: 90))),
      );
    },
  );

  test(
    'missing, future and unsupported end times do not open private reads',
    () {
      final now = DateTime.utc(2026, 10, 22);
      expect(DraftEndedJourneyReadWindow.expiresAt(null), isNull);
      expect(DraftEndedJourneyReadWindow.isOpen(null, now), isFalse);
      expect(
        DraftEndedJourneyReadWindow.isOpen(
          now.add(const Duration(microseconds: 1)),
          now,
        ),
        isFalse,
      );
      final lastDate = DateTime.fromMillisecondsSinceEpoch(
        8640000000000000,
        isUtc: true,
      );
      expect(DraftEndedJourneyReadWindow.expiresAt(lastDate), isNull);
      expect(DraftEndedJourneyReadWindow.isOpen(lastDate, lastDate), isFalse);
    },
  );

  test(
    'a terminal Journey records one immutable dated attempt and progress',
    () {
      var now = DateTime.utc(2026, 7, 31, 15, 42);
      model = ViewRequestDraftModel(clock: () => now);
      start(first);
      final startTime = now;
      expect(model.sendSalam(first), isTrue);
      final progress = model.snapshot().progress[first];
      now = DateTime.utc(2026, 8, 2, 9, 10);
      expect(model.end(first), isTrue);
      final attempt = model.currentEndedAttemptFor(first)!;
      expect(attempt.profileId, first);
      expect(attempt.startedAt, startTime);
      expect(attempt.endedAt, now);
      expect(attempt.progress, progress);
      expect(attempt.progress.salam, isTrue);
      expect(attempt.progress.peerSalam, isFalse);
      expect(attempt.id, isNotEmpty);
      final id = attempt.id;
      now = now.add(const Duration(days: 100));
      expect(model.end(first), isFalse);
      expect(model.currentEndedAttemptFor(first), same(attempt));
      expect(model.currentEndedAttemptFor(first)!.id, id);
      expect(model.endedAttemptsFor(first), [attempt]);
      expect(
        () => model.endedAttemptsFor(first).clear(),
        throwsUnsupportedError,
      );
      expect(model.canRequest(first), isFalse);
      expect(model.request(first), isFalse);
      expect(model.chooseCompatibilityReveal(first), isFalse);
    },
  );

  test('declining or withdrawing a request creates no terminal attempt', () {
    expect(model.declineReceived(received), isTrue);
    expect(model.request(first), isTrue);
    expect(model.cancel(first), isTrue);
    expect(model.snapshot().endedAttempts, isEmpty);
    expect(model.snapshot().currentEndedAttemptIds, isEmpty);
    expect(model.snapshot().journeyStartedAt, isEmpty);
  });

  test(
    'capacity replacement preserves the ended attempt before fresh preparation',
    () {
      var now = DateTime.utc(2026, 8, 1);
      model = ViewRequestDraftModel(capacity: 3, clock: () => now);
      start(first);
      start(second);
      start(third);
      expect(model.occupiedCount, 3);
      expect(model.hasCapacity, isFalse);
      expect(model.sendSalam(first), isTrue);
      final progress = model.snapshot().progress[first];
      now = DateTime.utc(2026, 8, 31, 23, 59);
      expect(
        model.replaceJourneyForRequest(received, first, incoming: true),
        isTrue,
      );
      final attempt = model.currentEndedAttemptFor(first)!;
      expect(attempt.endedAt, now);
      expect(attempt.progress, progress);
      expect(model.stateFor(first), DraftJourneyState.ended);
      expect(model.stateFor(received), DraftJourneyState.preparing);
      expect(model.hasSentSalam(received), isFalse);
      expect(model.compatibilityRevealed(received), isFalse);
      expect(model.currentEndedAttemptFor(received), isNull);
      expect(model.occupiedCount, 3);
    },
  );

  test('legacy seeded Ended history never invents a fresh end timestamp', () {
    final now = DateTime.utc(2026, 10, 22);
    model = ViewRequestDraftModel(clock: () => now);
    model.seedHistory();
    final id = draftProfiles[5].id;
    final attempt = model.currentEndedAttemptFor(id)!;
    expect(attempt.endedAt, isNull);
    expect(attempt.startedAt, isNull);
    expect(attempt.hasReadWindow(now), isFalse);
    model.seedHistory();
    expect(model.endedAttemptsFor(id), [attempt]);
    expect(model.currentEndedAttemptFor(id), same(attempt));
  });

  test(
    'hidden and blocked fictional peers stay out of Browse without erasing ended history',
    () {
      start(first);
      expect(model.end(first), isTrue);
      final stage = model.stageFor(first);
      expect(model.discoverableProfiles.map((p) => p.id), contains(first));
      expect(model.hide(first), isTrue);
      expect(
        model.discoverableProfiles.map((p) => p.id),
        isNot(contains(first)),
      );
      expect(model.stateFor(first), DraftJourneyState.ended);
      expect(model.stageFor(first), stage);
      expect(model.block(first), isTrue);
      expect(model.blockedPeers, {first});
      expect(model.canRequest(first), isFalse);
      expect(model.stateFor(first), DraftJourneyState.ended);
      expect(model.stageFor(first), stage);
      expect(model.hide('unknown'), isFalse);
      expect(model.block('unknown'), isFalse);
      expect(() => model.hiddenPeers.clear(), throwsUnsupportedError);
      expect(() => model.blockedPeers.clear(), throwsUnsupportedError);
      model.reset();
      expect(model.hiddenPeers, isEmpty);
      expect(model.blockedPeers, isEmpty);
      expect(model.canRequest(first), isTrue);
    },
  );

  test('blocked sample grants cannot start or participate in a Journey', () {
    expect(model.request(first), isTrue);
    expect(model.simulateRecipientAccept(first), isTrue);
    expect(model.block(first), isTrue);
    expect(model.markReady(first), isFalse);
    expect(model.simulatePeerReady(first), isFalse);
    expect(
      model.completePreparation(
        first,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isFalse,
    );
    expect(
      model.beginPreparedJourney(
        first,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isFalse,
    );
    expect(model.occupiedCount, 1);
    model.reset();
    start(first);
    expect(model.block(first), isTrue);
    expect(model.canParticipateInJourney(first), isFalse);
    expect(model.sendSalam(first), isFalse);
    expect(
      model
          .sampleGuardianAccessFor('draft-guardian-hassan', first, isMain: true)
          .view,
      isFalse,
    );
    expect(
      model.setSampleGuardianJourneyAccess(
        'draft-guardian-yusuf',
        first,
        chatEnabled: true,
      ),
      isFalse,
    );
    expect(model.end(first), isTrue);
    expect(model.occupiedCount, 0);
  });
  test(
    'ended-only fixture does not create another attempt or rewrite existing state',
    () {
      model = ViewRequestDraftModel(capacity: 3);
      start(first);
      final currentStage = model.stageFor(first);
      model.seedHistory();
      expect(model.stateFor(draftProfiles[4].id), isNull);
      expect(model.stateFor(draftProfiles[5].id), DraftJourneyState.ended);
      expect(model.stateFor(first), DraftJourneyState.active);
      expect(model.stageFor(first), currentStage);
      expect(model.occupiedCount, 1);
      final before = Map<String, DraftJourneyState>.of(model.states);
      model.seedHistory();
      expect(model.states, before);
    },
  );

  Map<String, Object?> snapshot() => {
    'capacity': model.capacity,
    'states': Map<String, DraftJourneyState>.of(model.states),
    'ownMain': model.ownMainGuardianPresent,
    'peerMain': model.peerMainGuardianPresent,
    'peerMainPerId': {
      for (final profile in draftProfiles)
        profile.id: model.peerMainGuardianPresentFor(profile.id),
    },
    'progress': {
      for (final profile in draftProfiles)
        profile.id: [
          model.peerOccupied(profile.id),
          model.stageFor(profile.id)?.value,
          model.isReady(profile.id),
          model.peerIsReady(profile.id),
          model.hasSentSalam(profile.id),
          model.peerHasSentSalam(profile.id),
          model.hasChosenCompatibilityReveal(profile.id),
          model.peerHasChosenCompatibilityReveal(profile.id),
          model.hasChosenStageContinue(profile.id),
          model.peerHasChosenStageContinue(profile.id),
        ],
    },
  };

  void nextStage(String id) {
    switch (model.stageFor(id)!.value) {
      case 'salam_exchange':
        expect(model.sendSalam(id), isTrue);
        expect(model.simulatePeerSalam(id), isTrue);
      case 'compatibility_reveal':
        expect(model.chooseCompatibilityReveal(id), isTrue);
        expect(model.simulatePeerCompatibilityReveal(id), isTrue);
    }
    expect(model.chooseStageContinue(id), isTrue);
    expect(model.simulatePeerStageContinue(id), isTrue);
    expect(model.advanceStage(id), isTrue);
  }

  test('local capacity can grow to three without resetting fixture state', () {
    expect(model.request(first), isTrue);
    model.setOwnMainGuardianPresent(false);
    final before = Map<String, DraftJourneyState>.of(model.states);
    expect(model.setCapacity(3), isTrue);
    expect(model.capacity, 3);
    expect(model.states, before);
    expect(model.ownMainGuardianPresent, isFalse);
  });

  test('counterpart Main absence holds Sara without holding Aisha', () {
    model = ViewRequestDraftModel(capacity: 3);
    start(first);
    start(second);
    expect(model.setPeerMainGuardianPresent(false, id: first), isTrue);
    expect(model.canParticipateInJourney(first), isFalse);
    expect(model.sendSalam(first), isFalse);
    expect(model.canParticipateInJourney(second), isTrue);
    expect(model.sendSalam(second), isTrue);
    expect(model.simulatePeerSalam(second), isTrue);
  });

  test('invalid counterpart Main overrides fail closed without mutation', () {
    model = ViewRequestDraftModel(capacity: 3);
    start(first);
    expect(model.setPeerMainGuardianPresent(false, id: first), isTrue);
    final before = snapshot();
    for (final id in ['', 'missing', 'real-member-id']) {
      expect(model.peerMainGuardianPresentFor(id), isFalse);
      expect(model.setPeerMainGuardianPresent(true, id: id), isFalse);
      expect(model.setPeerMainGuardianPresent(false, id: id), isFalse);
      expect(snapshot(), before);
    }
  });

  test('legacy all-fixture Main control stays uniform and own Main shared', () {
    model = ViewRequestDraftModel(capacity: 3);
    start(first);
    start(second);
    expect(model.setPeerMainGuardianPresent(false, id: first), isTrue);
    expect(model.peerMainGuardianPresent, isTrue);
    expect(model.peerMainGuardianPresentFor(first), isFalse);
    expect(model.peerMainGuardianPresentFor(second), isTrue);
    expect(model.setPeerMainGuardianPresent(true), isTrue);
    expect(model.peerMainGuardianPresentFor(first), isTrue);
    expect(model.setPeerMainGuardianPresent(false), isTrue);
    for (final profile in draftProfiles) {
      expect(model.peerMainGuardianPresentFor(profile.id), isFalse);
    }
    expect(model.setPeerMainGuardianPresent(true, id: second), isTrue);
    expect(model.canParticipateInJourney(first), isFalse);
    expect(model.canParticipateInJourney(second), isTrue);
    model.setOwnMainGuardianPresent(false);
    expect(model.canParticipateInJourney(first), isFalse);
    expect(model.canParticipateInJourney(second), isFalse);
    expect(model.end(second), isTrue);
    model.setOwnMainGuardianPresent(true);
    expect(model.setPeerMainGuardianPresent(true), isTrue);
    for (final profile in draftProfiles) {
      expect(model.peerMainGuardianPresentFor(profile.id), isTrue);
    }
  });

  test('Guardian Gate choices recheck per-counterpart Main independently', () {
    model = ViewRequestDraftModel(capacity: 3);
    for (final id in [first, second]) {
      start(id);
      nextStage(id);
      nextStage(id);
      expect(model.stageFor(id)!.value, 'wali_gate');
      expect(model.chooseStageContinue(id), isTrue);
      expect(model.simulatePeerStageContinue(id), isTrue);
    }
    expect(model.setPeerMainGuardianPresent(false, id: first), isTrue);
    expect(model.canAdvanceStage(first), isFalse);
    expect(model.advanceStage(first), isFalse);
    expect(model.canAdvanceStage(second), isTrue);
    expect(model.advanceStage(second), isTrue);
    expect(model.stageFor(first)!.value, 'wali_gate');
    expect(model.stageFor(second), same(ZyraJourneyStages.all[3]));
    model.setOwnMainGuardianPresent(false);
    expect(model.chooseStageContinue(second), isFalse);
    model.setOwnMainGuardianPresent(true);
    expect(model.setPeerMainGuardianPresent(true, id: first), isTrue);
    expect(model.canAdvanceStage(first), isTrue);
    expect(model.advanceStage(first), isTrue);
    expect(model.stageFor(first), same(ZyraJourneyStages.all[3]));
    expect(model.hasChosenStageContinue(second), isFalse);
  });

  test(
    'reset and valid Journey seeds clear every counterpart Main override',
    () {
      for (final count in [0, 1, 2, 3]) {
        model = ViewRequestDraftModel(capacity: 3);
        expect(model.setPeerMainGuardianPresent(false), isTrue);
        expect(model.setPeerMainGuardianPresent(true, id: first), isTrue);
        if (count == 0) {
          model.reset();
        } else {
          expect(model.seedJourneys(count), isTrue);
        }
        expect(model.peerMainGuardianPresent, isTrue);
        for (final profile in draftProfiles) {
          expect(model.peerMainGuardianPresentFor(profile.id), isTrue);
        }
        expect(model.setPeerMainGuardianPresent(false, id: first), isTrue);
        final before = snapshot();
        expect(model.seedJourneys(4), isFalse);
        expect(snapshot(), before);
      }
    },
  );

  test('constructor capacity stays local, bounded and defaults to one', () {
    expect(model.capacity, 1);
    expect(model.occupiedCount, 0);
    for (final capacity in [1, 2, 3]) {
      final local = ViewRequestDraftModel(capacity: capacity);
      expect(local.capacity, capacity);
      expect(local.occupiedCount, 0);
      expect(local.states, {received: DraftJourneyState.received});
    }
  });

  test('invalid constructor capacity refuses rather than clamps', () {
    for (final capacity in [-100, -1, 0, 4, 100]) {
      expect(() => ViewRequestDraftModel(capacity: capacity), throwsRangeError);
    }
    expect(model.capacity, 1);
    expect(model.states, {received: DraftJourneyState.received});
  });

  test('monthly pending requests cost no place before mutual acceptance', () {
    model = ViewRequestDraftModel(capacity: 3);
    for (final profile in model.discoverableProfiles.skip(1)) {
      expect(model.request(profile.id), isTrue);
    }
    expect(model.states.length, draftProfiles.length - 1);
    expect(model.occupiedCount, 0);
    expect(model.hasCapacity, isTrue);
    expect(model.discoverable, isTrue);
    expect(model.acceptReceived(received), isTrue);
    expect(model.simulateRecipientAccept(first), isTrue);
    expect(model.simulateRecipientAccept(second), isTrue);
    expect(model.preparingCount, 3);
    expect(model.occupiedCount, 3);
    expect(model.simulateRecipientAccept(third), isFalse);
    expect(model.stateFor(third), DraftJourneyState.sent);
  });

  test(
    'sent invitations remain Browse eligible until hidden or blocked and occupy no place',
    () {
      final eligible = model.discoverableProfiles
          .map((profile) => profile.id)
          .toList();
      expect(model.request(first), isTrue);
      expect(model.request(second), isTrue);
      expect(model.stateFor(first), DraftJourneyState.sent);
      expect(model.stateFor(second), DraftJourneyState.sent);
      expect(model.discoverableProfiles.map((profile) => profile.id), eligible);
      expect(model.availableProfiles, model.discoverableProfiles);
      expect(model.occupiedCount, 0);
      expect(model.preparingCount, 0);
      expect(model.activeCount, 0);
      expect(model.hasCapacity, isTrue);
      expect(model.discoverable, isTrue);
      expect(model.hide(first), isTrue);
      expect(model.block(second), isTrue);
      expect(
        model.discoverableProfiles.map((profile) => profile.id),
        eligible.where((id) => id != first && id != second),
      );
      expect(model.stateFor(first), DraftJourneyState.sent);
      expect(model.stateFor(second), DraftJourneyState.sent);
      expect(model.occupiedCount, 0);
      expect(model.hasCapacity, isTrue);
      expect(model.canRequest(first), isFalse);
      expect(model.canRequest(second), isFalse);
    },
  );

  test('three places count preparation and Active together', () {
    model = ViewRequestDraftModel(capacity: 3);
    expect(model.request(third), isTrue);
    expect(model.acceptReceived(received), isTrue);
    start(first);
    expect(model.request(second), isTrue);
    expect(model.simulateRecipientAccept(second), isTrue);
    expect(model.preparingCount, 2);
    expect(model.activeCount, 1);
    expect(model.occupiedCount, 3);
    expect(model.hasCapacity, isFalse);
    expect(model.discoverable, isFalse);
    // A full monthly preview may keep browsing/sending; only acceptance
    // reserves a place and still requires the separately confirmed replacement.
    expect(model.canBrowse, isTrue);
    expect(model.request(draftProfiles[4].id), isTrue);
    expect(model.simulateRecipientAccept(third), isFalse);
    expect(model.markReady(received), isTrue);
    expect(model.simulatePeerReady(received), isTrue);
    expect(
      model.beginPreparedJourney(
        received,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isTrue,
    );
    expect(model.activeCount, 2);
    expect(model.preparingCount, 1);
    expect(model.occupiedCount, 3);
    expect(model.end(first), isTrue);
    expect(model.occupiedCount, 2);
    expect(model.hasCapacity, isTrue);
    expect(model.simulateRecipientAccept(third), isTrue);
    expect(model.occupiedCount, 3);
  });

  test('three simultaneous Journeys have independent mutual progress', () {
    model = ViewRequestDraftModel(capacity: 3);
    start(first);
    start(second);
    start(third);
    nextStage(first);
    expect(model.stageFor(first), same(ZyraJourneyStages.all[1]));
    expect(model.stageFor(second), same(ZyraJourneyStages.all.first));
    expect(model.stageFor(third), same(ZyraJourneyStages.all.first));
    expect(model.chooseCompatibilityReveal(first), isTrue);
    expect(model.sendSalam(second), isTrue);
    expect(model.peerHasSentSalam(second), isFalse);
    expect(model.hasSentSalam(third), isFalse);
    expect(model.hasChosenCompatibilityReveal(second), isFalse);
    expect(model.hasChosenCompatibilityReveal(third), isFalse);
    expect(model.simulatePeerSalam(second), isTrue);
    expect(model.chooseStageContinue(second), isTrue);
    expect(model.hasChosenStageContinue(first), isFalse);
    expect(model.hasChosenStageContinue(third), isFalse);
    expect(model.sendSalam(third), isTrue);
    expect(model.end(second), isTrue);
    expect(model.stateFor(first), DraftJourneyState.active);
    expect(model.stateFor(third), DraftJourneyState.active);
    expect(model.hasChosenCompatibilityReveal(first), isTrue);
    expect(model.stageFor(third), same(ZyraJourneyStages.all.first));
    model.setOwnMainGuardianPresent(false);
    expect(model.simulatePeerSalam(third), isFalse);
    expect(model.canParticipateInJourney(first), isFalse);
    expect(model.end(third), isTrue);
  });

  test('capacity reduction cannot truncate any occupied-state combination', () {
    model = ViewRequestDraftModel(capacity: 3);
    expect(model.acceptReceived(received), isTrue);
    start(first);
    start(second);
    model.setPeerMainGuardianPresent(false);
    final before = snapshot();
    for (final capacity in [-1, 0, 1, 2, 4, 10]) {
      expect(model.setCapacity(capacity), isFalse);
      expect(snapshot(), before);
    }
    expect(model.setCapacity(3), isTrue);
    expect(snapshot(), before);
    expect(model.end(received), isTrue);
    expect(model.setCapacity(2), isTrue);
    expect(model.capacity, 2);
    expect(model.occupiedCount, 2);
    expect(model.stateFor(received), DraftJourneyState.ended);
    expect(model.stageFor(first), same(ZyraJourneyStages.all.first));
    expect(model.peerMainGuardianPresent, isFalse);
  });

  test(
    'pending requests and ended history do not obstruct a safe reduction',
    () {
      model = ViewRequestDraftModel(capacity: 3);
      start(first);
      start(second);
      expect(model.request(third), isTrue);
      expect(model.end(second), isTrue);
      model.seedHistory();
      final states = Map<String, DraftJourneyState>.of(model.states);
      expect(model.occupiedCount, 1);
      expect(model.setCapacity(1), isTrue);
      expect(model.states, states);
      expect(model.simulateRecipientAccept(third), isFalse);
      expect(model.end(first), isTrue);
      expect(model.simulateRecipientAccept(third), isTrue);
      expect(model.occupiedCount, 1);
    },
  );

  for (final count in [1, 2, 3]) {
    test('explicit $count-Journey seed resets only the fictional scenario', () {
      model = ViewRequestDraftModel(capacity: 3);
      start(first);
      nextStage(first);
      expect(model.chooseCompatibilityReveal(first), isTrue);
      expect(model.request(second), isTrue);
      model.seedHistory();
      model.setOwnMainGuardianPresent(false);
      model.setPeerMainGuardianPresent(false);
      expect(model.setPeerOccupied(draftProfiles.last.id, false), isTrue);
      expect(model.seedJourneys(count), isTrue);
      expect(model.capacity, 3);
      expect(model.activeCount, count);
      expect(model.preparingCount, 0);
      expect(model.occupiedCount, count);
      expect(model.states.length, count + 1);
      expect(model.stateFor(received), DraftJourneyState.received);
      expect(model.ownMainGuardianPresent, isTrue);
      expect(model.peerMainGuardianPresent, isTrue);
      expect(model.peerOccupied(draftProfiles.last.id), isTrue);
      for (final profile in draftProfiles.skip(1).take(count)) {
        expect(model.stateFor(profile.id), DraftJourneyState.active);
        expect(model.stageFor(profile.id), same(ZyraJourneyStages.all.first));
        expect(model.isReady(profile.id), isTrue);
        expect(model.peerIsReady(profile.id), isTrue);
        expect(model.hasSentSalam(profile.id), isFalse);
        expect(model.peerHasSentSalam(profile.id), isFalse);
        expect(model.hasChosenCompatibilityReveal(profile.id), isFalse);
        expect(model.hasChosenStageContinue(profile.id), isFalse);
      }
      expect(model.sendSalam(first), isTrue);
      if (count > 1) expect(model.hasSentSalam(second), isFalse);
      expect(model.hasCapacity, count < 3);
      expect(model.seedJourneys(count), isTrue);
      expect(model.hasSentSalam(first), isFalse);
    });
  }

  test(
    'invalid seed counts leave requests history progress and holds intact',
    () {
      model = ViewRequestDraftModel(capacity: 2);
      start(first);
      nextStage(first);
      expect(model.chooseCompatibilityReveal(first), isTrue);
      expect(model.request(second), isTrue);
      model.seedHistory();
      expect(model.setPeerOccupied(third, true), isTrue);
      model.setOwnMainGuardianPresent(false);
      model.setPeerMainGuardianPresent(false);
      final before = snapshot();
      for (final count in [-100, -1, 0, 3, 4, 100]) {
        expect(model.seedJourneys(count), isFalse);
        expect(snapshot(), before);
      }
    },
  );

  test('one-place Basic fixture cannot seed two or three Journeys', () {
    expect(model.capacity, 1);
    final before = snapshot();
    for (final count in [2, 3]) {
      expect(model.seedJourneys(count), isFalse);
      expect(snapshot(), before);
    }
    expect(model.seedJourneys(1), isTrue);
    expect(model.occupiedCount, 1);
    expect(model.hasCapacity, isFalse);
  });

  for (final capacity in [1, 2, 3]) {
    test('fillCapacity fills all $capacity configured local places', () {
      model = ViewRequestDraftModel(capacity: capacity);
      model.fillCapacity();
      expect(model.capacity, capacity);
      expect(model.activeCount, capacity);
      expect(model.occupiedCount, capacity);
      expect(model.preparingCount, 0);
      expect(model.hasCapacity, isFalse);
      expect(model.discoverable, isFalse);
      expect(model.acceptReceived(received), isFalse);
      expect(model.sendSalam(first), isTrue);
      model.fillCapacity();
      expect(model.hasSentSalam(first), isFalse);
      expect(model.activeCount, capacity);
    });
  }

  test('reset retains chosen capacity and clears every fictional Journey', () {
    expect(model.setCapacity(3), isTrue);
    model.fillCapacity();
    model.reset();
    expect(model.capacity, 3);
    expect(model.occupiedCount, 0);
    expect(model.states, {received: DraftJourneyState.received});
    expect(model.stageFor(first), isNull);
    expect(model.hasCapacity, isTrue);
  });

  test('busy peer is excluded from Discover, not merely explained in copy', () {
    final busy = draftProfiles.last.id;
    expect(model.peerOccupied(busy), isTrue);
    expect(model.discoverableProfiles.map((p) => p.id), isNot(contains(busy)));
    expect(model.availableProfiles, model.discoverableProfiles);
    expect(model.canRequest(busy), isFalse);
    expect(model.request(busy), isFalse);
    expect(model.setPeerOccupied(busy, false), isTrue);
    expect(model.discoverableProfiles.map((p) => p.id), contains(busy));
    expect(model.request(busy), isTrue);
  });

  test('acceptance rechecks peer availability after a request was sent', () {
    expect(model.request(first), isTrue);
    expect(model.setPeerOccupied(first, true), isTrue);
    expect(model.canAccept(first), isFalse);
    expect(model.simulateRecipientAccept(first), isFalse);
    expect(model.stateFor(first), DraftJourneyState.sent);
    expect(model.discoverable, isTrue);
    expect(model.setPeerOccupied(first, false), isTrue);
    expect(model.simulateRecipientAccept(first), isTrue);
    expect(model.discoverable, isFalse);
  });

  test('incoming acceptance also rechecks the other participant', () {
    expect(model.setPeerOccupied(received, true), isTrue);
    expect(model.acceptReceived(received), isFalse);
    expect(model.stateFor(received), DraftJourneyState.received);
    expect(model.setPeerOccupied(received, false), isTrue);
    expect(model.acceptReceived(received), isTrue);
  });

  test('both are hidden during preparation and Active', () {
    expect(model.acceptReceived(received), isTrue);
    for (var step = 0; step < 2; step++) {
      expect(model.discoverable, isFalse);
      expect(model.peerOccupied(received), isTrue);
      expect(
        model.discoverableProfiles.map((p) => p.id),
        isNot(contains(received)),
      );
      expect(model.setPeerOccupied(received, true), isFalse);
      expect(model.setPeerOccupied(received, false), isTrue);
      expect(model.peerOccupied(received), isTrue);
      if (step == 0) {
        expect(
          model.completePreparation(
            received,
            agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
          ),
          isTrue,
        );
      }
    }
    expect(model.end(received), isTrue);
    expect(model.discoverable, isTrue);
    expect(model.peerOccupied(received), isFalse);
  });

  test(
    'a default reservation cannot be replaced by acceptance or invalid cap',
    () {
      expect(model.request(first), isTrue);
      expect(model.simulateRecipientAccept(first), isTrue);
      expect(model.acceptReceived(received), isFalse);
      expect(model.simulateRecipientAccept(first), isFalse);
      expect(model.setCapacity(0), isFalse);
      expect(model.preparingCount, 1);
      expect(model.stateFor(received), DraftJourneyState.received);
    },
  );

  test('readiness is mutual and begin is a separate deliberate action', () {
    expect(model.acceptReceived(received), isTrue);
    expect(
      model.beginPreparedJourney(
        received,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isFalse,
    );
    expect(model.isReady(received), isFalse);
    expect(model.peerIsReady(received), isFalse);
    expect(model.markReady(received), isTrue);
    expect(model.markReady(received), isFalse);
    expect(
      model.beginPreparedJourney(
        received,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isFalse,
    );
    expect(model.conversationOpen(received), isFalse);
    expect(model.simulatePeerReady(received), isTrue);
    expect(model.simulatePeerReady(received), isFalse);
    expect(model.stateFor(received), DraftJourneyState.preparing);
    expect(
      model.beginPreparedJourney(
        received,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isTrue,
    );
    expect(model.stageFor(received), same(ZyraJourneyStages.all.first));
    expect(model.conversationOpen(received), isFalse);
    expect(
      model.beginPreparedJourney(
        received,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isFalse,
    );
    expect(model.markReady(received), isFalse);
    expect(model.simulatePeerReady(received), isFalse);
  });

  test('Salam requires both people before either checkpoint can advance', () {
    start(first);
    expect(model.chooseStageContinue(first), isFalse);
    expect(model.simulatePeerStageContinue(first), isFalse);
    expect(model.sendSalam(first), isTrue);
    expect(model.sendSalam(first), isFalse);
    expect(model.salamComplete(first), isFalse);
    expect(model.chooseStageContinue(first), isFalse);
    expect(model.simulatePeerSalam(first), isTrue);
    expect(model.simulatePeerSalam(first), isFalse);
    expect(model.salamComplete(first), isTrue);
    expect(model.chooseStageContinue(first), isTrue);
    expect(model.advanceStage(first), isFalse);
    expect(model.simulatePeerStageContinue(first), isTrue);
    expect(model.advanceStage(first), isTrue);
    expect(model.stageFor(first), same(ZyraJourneyStages.all[1]));
    expect(model.hasChosenStageContinue(first), isFalse);
    expect(model.peerHasChosenStageContinue(first), isFalse);
    expect(model.sendSalam(first), isFalse);
    expect(model.simulatePeerSalam(first), isFalse);
  });

  test('compatibility cannot reveal early, by one person or via Continue', () {
    start(first);
    expect(model.chooseCompatibilityReveal(first), isFalse);
    expect(model.simulatePeerCompatibilityReveal(first), isFalse);
    nextStage(first);
    expect(model.chooseStageContinue(first), isFalse);
    expect(model.chooseCompatibilityReveal(first), isTrue);
    expect(model.chooseCompatibilityReveal(first), isFalse);
    expect(model.compatibilityRevealed(first), isFalse);
    expect(model.hasChosenCompatibilityReveal(first), isTrue);
    expect(model.peerHasChosenCompatibilityReveal(first), isFalse);
    expect(model.chooseStageContinue(first), isFalse);
    expect(model.simulatePeerStageContinue(first), isFalse);
    expect(model.advanceStage(first), isFalse);
    expect(model.simulatePeerCompatibilityReveal(first), isTrue);
    expect(model.simulatePeerCompatibilityReveal(first), isFalse);
    expect(model.compatibilityRevealed(first), isTrue);
    expect(model.chooseStageContinue(first), isTrue);
    expect(model.simulatePeerStageContinue(first), isTrue);
    expect(model.advanceStage(first), isTrue);
    expect(model.stageFor(first), same(ZyraJourneyStages.all[2]));
    expect(model.chooseCompatibilityReveal(first), isFalse);
    expect(model.conversationOpen(first), isFalse);
  });

  test(
    'Guardian Gate rechecks Main presence for both people before advancing',
    () {
      start(first);
      nextStage(first);
      nextStage(first);
      expect(model.stageFor(first)!.value, 'wali_gate');
      model.setOwnMainGuardianPresent(false);
      expect(model.ownMainGuardianPresent, isFalse);
      expect(model.chooseStageContinue(first), isFalse);
      model.setOwnMainGuardianPresent(true);
      model.setPeerMainGuardianPresent(false);
      expect(model.peerMainGuardianPresent, isFalse);
      expect(model.simulatePeerStageContinue(first), isFalse);
      model.setPeerMainGuardianPresent(true);
      expect(model.chooseStageContinue(first), isTrue);
      expect(model.simulatePeerStageContinue(first), isTrue);
      model.setOwnMainGuardianPresent(false);
      expect(model.canAdvanceStage(first), isFalse);
      expect(model.advanceStage(first), isFalse);
      model.setOwnMainGuardianPresent(true);
      expect(model.advanceStage(first), isTrue);
      expect(model.stageFor(first), same(ZyraJourneyStages.all[3]));
    },
  );

  test(
    'all eight existing stages are shared and chat is only the destination',
    () {
      start(first);
      for (var index = 0; index < ZyraJourneyStages.all.length; index++) {
        expect(model.stageFor(first), same(ZyraJourneyStages.all[index]));
        expect(
          model.conversationOpen(first),
          index == ZyraJourneyStages.all.length - 1,
        );
        if (index < ZyraJourneyStages.all.length - 1) nextStage(first);
      }
      expect(model.chooseStageContinue(first), isFalse);
      expect(model.simulatePeerStageContinue(first), isFalse);
      expect(model.advanceStage(first), isFalse);
      expect(model.stageFor(first), same(ZyraJourneyStages.all.last));
      expect(model.end(first), isTrue);
      expect(model.conversationOpen(first), isFalse);
    },
  );

  test(
    'ended attempts retain sample stage but reject every new disclosure action',
    () {
      start(first);
      nextStage(first);
      expect(model.end(first), isTrue);
      expect(model.stageFor(first), same(ZyraJourneyStages.all[1]));
      expect(model.chooseCompatibilityReveal(first), isFalse);
      expect(model.simulatePeerCompatibilityReveal(first), isFalse);
      expect(model.chooseStageContinue(first), isFalse);
      expect(model.simulatePeerStageContinue(first), isFalse);
      expect(model.advanceStage(first), isFalse);
      expect(
        model.beginPreparedJourney(
          first,
          agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
        ),
        isFalse,
      );
      expect(model.discoverableProfiles.map((p) => p.id), contains(first));
      expect(model.canRequest(first), isFalse);
    },
  );

  test(
    'ended history scenario is explicit, idempotent and cannot overwrite a request',
    () {
      final ended = draftProfiles[5].id;
      expect(model.stateFor(ended), isNull);
      model.seedHistory();
      expect(model.stateFor(ended), DraftJourneyState.ended);
      expect(model.discoverable, isTrue);
      expect(model.discoverableProfiles.map((p) => p.id), contains(ended));
      expect(model.canRequest(ended), isFalse);
      model.seedHistory();
      expect(model.states.length, 2);
      model.reset();
      expect(model.request(ended), isTrue);
      model.seedHistory();
      expect(model.stateFor(ended), DraftJourneyState.sent);
    },
  );

  test(
    'reset clears all readiness, consent, history and scenario settings',
    () {
      start(first);
      nextStage(first);
      expect(model.chooseCompatibilityReveal(first), isTrue);
      model.seedHistory();
      model.setOwnMainGuardianPresent(false);
      model.setPeerMainGuardianPresent(false);
      expect(model.setPeerOccupied(draftProfiles.last.id, false), isTrue);
      model.reset();
      expect(model.stageFor(first), isNull);
      expect(model.isReady(first), isFalse);
      expect(model.peerIsReady(first), isFalse);
      expect(model.hasChosenCompatibilityReveal(first), isFalse);
      expect(model.peerHasChosenCompatibilityReveal(first), isFalse);
      expect(model.ownMainGuardianPresent, isTrue);
      expect(model.peerMainGuardianPresent, isTrue);
      expect(model.peerOccupied(draftProfiles.last.id), isTrue);
      expect(model.states, {received: DraftJourneyState.received});
    },
  );

  test(
    'fixture Guardian identity and relationship are separate from authority',
    () {
      expect(draftGuardians.where((g) => g.isMain).length, 1);
      expect(
        draftGuardians.any((g) => g.relationship == 'Paternal Uncle'),
        isTrue,
      );
      for (final guardian in draftGuardians) {
        expect(guardian.id, startsWith('draft-guardian-'));
        expect(guardian.firstName, isNotEmpty);
        expect(guardian.surname, isNotEmpty);
        expect(guardian.relationshipCode, anyOf('father', 'uncle'));
        expect(guardian.linkedAt.year, 2026);
      }
      expect(draftGuardians.first.linkedAt, DateTime(2026, 9, 20));
      expect(draftGuardians.last.linkedAt, DateTime(2026, 9, 23));
      expect(
        () => draftGuardians.add(draftGuardians.first),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'Discover list is immutable and invalid progress actions fail closed',
    () {
      expect(() => model.discoverableProfiles.clear(), throwsUnsupportedError);
      for (final id in ['', 'missing', 'real-member-id']) {
        expect(model.setPeerOccupied(id, true), isFalse);
        expect(model.setPeerOccupied(id, false), isFalse);
        expect(model.canRequest(id), isFalse);
        expect(model.canAccept(id), isFalse);
        expect(model.stageFor(id), isNull);
        expect(model.markReady(id), isFalse);
        expect(model.simulatePeerReady(id), isFalse);
        expect(
          model.beginPreparedJourney(
            id,
            agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
          ),
          isFalse,
        );
        expect(model.sendSalam(id), isFalse);
        expect(model.simulatePeerSalam(id), isFalse);
        expect(model.chooseCompatibilityReveal(id), isFalse);
        expect(model.simulatePeerCompatibilityReveal(id), isFalse);
        expect(model.chooseStageContinue(id), isFalse);
        expect(model.simulatePeerStageContinue(id), isFalse);
        expect(model.advanceStage(id), isFalse);
        expect(model.conversationOpen(id), isFalse);
        expect(model.canParticipateInJourney(id), isFalse);
      }
      expect(model.states, {received: DraftJourneyState.received});
    },
  );

  test(
    'readiness availability mirrors thresholds, duplicate choice and holds',
    () {
      for (final id in ['missing', received]) {
        expect(model.canChooseStageContinue(id), isFalse);
        expect(model.canPeerChooseStageContinue(id), isFalse);
      }
      start(first);
      expect(model.canChooseStageContinue(first), isFalse);
      expect(model.canPeerChooseStageContinue(first), isFalse);
      expect(model.sendSalam(first), isTrue);
      expect(model.simulatePeerSalam(first), isTrue);
      expect(model.canChooseStageContinue(first), isTrue);
      expect(model.canPeerChooseStageContinue(first), isTrue);
      expect(model.chooseStageContinue(first), isTrue);
      expect(model.canChooseStageContinue(first), isFalse);
      expect(model.canPeerChooseStageContinue(first), isTrue);
      expect(model.simulatePeerStageContinue(first), isTrue);
      expect(model.canPeerChooseStageContinue(first), isFalse);
      expect(model.advanceStage(first), isTrue);
      expect(model.canChooseStageContinue(first), isFalse);
      expect(model.canPeerChooseStageContinue(first), isFalse);
      expect(model.chooseCompatibilityReveal(first), isTrue);
      expect(model.simulatePeerCompatibilityReveal(first), isTrue);
      expect(model.canChooseStageContinue(first), isTrue);
      expect(model.canPeerChooseStageContinue(first), isTrue);
      model.setPeerMainGuardianPresent(false);
      expect(model.canChooseStageContinue(first), isFalse);
      expect(model.canPeerChooseStageContinue(first), isFalse);
      model.setPeerMainGuardianPresent(true);
      expect(model.canChooseStageContinue(first), isTrue);
      expect(model.end(first), isTrue);
      expect(model.canChooseStageContinue(first), isFalse);
      expect(model.canPeerChooseStageContinue(first), isFalse);
    },
  );

  for (final removeOwnMain in [true, false]) {
    void changeMain(bool present) {
      if (removeOwnMain) {
        model.setOwnMainGuardianPresent(present);
      } else {
        model.setPeerMainGuardianPresent(present);
      }
    }

    test(
      'missing ${removeOwnMain ? 'own' : 'peer'} Main holds every Active threshold',
      () {
        start(first);
        expect(model.canParticipateInJourney(first), isTrue);
        changeMain(false);
        expect(model.canParticipateInJourney(first), isFalse);
        expect(model.sendSalam(first), isFalse);
        expect(model.simulatePeerSalam(first), isFalse);
        expect(model.chooseStageContinue(first), isFalse);
        expect(model.simulatePeerStageContinue(first), isFalse);
        expect(model.advanceStage(first), isFalse);
        expect(model.hasSentSalam(first), isFalse);
        expect(model.peerHasSentSalam(first), isFalse);
        changeMain(true);
        nextStage(first);
        expect(model.chooseCompatibilityReveal(first), isTrue);
        changeMain(false);
        expect(model.simulatePeerCompatibilityReveal(first), isFalse);
        expect(model.compatibilityRevealed(first), isFalse);
        expect(model.chooseStageContinue(first), isFalse);
        changeMain(true);
        expect(model.simulatePeerCompatibilityReveal(first), isTrue);
        expect(model.chooseStageContinue(first), isTrue);
        expect(model.simulatePeerStageContinue(first), isTrue);
        changeMain(false);
        expect(
          model.compatibilityRevealed(first),
          isTrue,
        ); // Consent history only.
        expect(model.canAdvanceStage(first), isFalse);
        expect(model.advanceStage(first), isFalse);
        changeMain(true);
        expect(model.advanceStage(first), isTrue);
        nextStage(first); // Guardian Gate -> Faith & Values.
        expect(model.chooseStageContinue(first), isTrue);
        expect(model.simulatePeerStageContinue(first), isTrue);
        changeMain(false);
        expect(model.canAdvanceStage(first), isFalse);
        expect(model.advanceStage(first), isFalse);
        expect(model.stageFor(first), same(ZyraJourneyStages.all[3]));
        changeMain(true);
        expect(model.advanceStage(first), isTrue);
        while (model.stageFor(first)!.value != 'conversation') {
          nextStage(first);
        }
        expect(model.conversationOpen(first), isTrue);
        changeMain(false);
        expect(model.conversationOpen(first), isFalse);
        expect(model.end(first), isTrue); // End never requires Main permission.
        expect(model.stateFor(first), DraftJourneyState.ended);
      },
    );
  }

  test(
    'fictional fixtures are unique and contain public-looking details only',
    () {
      expect(draftProfiles.length, greaterThanOrEqualTo(7));
      expect(
        draftProfiles.map((profile) => profile.id).toSet().length,
        draftProfiles.length,
      );
      for (final profile in draftProfiles) {
        expect(profile.id, startsWith('draft-'));
        expect(profile.firstName, isNotEmpty);
        expect(profile.age, greaterThanOrEqualTo(18));
        expect(profile.city, isNotEmpty);
      }
      expect(
        () => draftProfiles.add(draftProfiles.first),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'fresh draft starts with one received request and no occupied slots',
    () {
      expect(model.capacity, 1);
      expect(model.states, {received: DraftJourneyState.received});
      expect(model.activeCount, 0);
      expect(model.preparingCount, 0);
      expect(model.hasCapacity, isTrue);
      expect(model.discoverable, isTrue);
    },
  );

  test(
    'finite fixture pending requests have no separate quota or slot cost',
    () {
      for (final profile in model.discoverableProfiles.skip(1)) {
        expect(model.request(profile.id), isTrue);
      }
      expect(model.states.length, draftProfiles.length - 1);
      expect(model.activeCount, 0);
      expect(model.preparingCount, 0);
      expect(model.hasCapacity, isTrue);
      expect(model.discoverable, isTrue);
    },
  );

  test(
    'request is explicit and refuses duplicates or an existing received row',
    () {
      expect(model.request(first), isTrue);
      expect(model.stateFor(first), DraftJourneyState.sent);
      expect(model.request(first), isFalse);
      expect(model.request(received), isFalse);
      expect(model.stateFor(received), DraftJourneyState.received);
    },
  );

  test('declining removes only a received fixture without Journey history', () {
    expect(model.request(first), isTrue);
    expect(model.declineReceived(first), isFalse);
    expect(model.declineReceived(received), isTrue);
    expect(model.stateFor(received), isNull);
    expect(model.declineReceived(received), isFalse);
    expect(model.activeCount, 0);
    expect(model.preparingCount, 0);
  });

  test(
    'only sent requests can be cancelled and a cancelled row can be sent again',
    () {
      expect(model.cancel(received), isFalse);
      expect(model.request(first), isTrue);
      expect(model.cancel(first), isTrue);
      expect(model.stateFor(first), isNull);
      expect(model.cancel(first), isFalse);
      expect(model.request(first), isTrue);
      expect(model.simulateRecipientAccept(first), isTrue);
      expect(model.cancel(first), isFalse);
      expect(model.stateFor(first), DraftJourneyState.preparing);
    },
  );

  test(
    'accepting received reserves preparation, not an immediate Active Journey',
    () {
      expect(model.acceptReceived(received), isTrue);
      expect(model.stateFor(received), DraftJourneyState.preparing);
      expect(model.preparingCount, 1);
      expect(model.activeCount, 0);
      expect(model.hasCapacity, isFalse);
      expect(model.discoverable, isFalse);
      expect(model.acceptReceived(received), isFalse);
      expect(model.request(first), isFalse);
      expect(
        model.completePreparation(
          received,
          agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
        ),
        isTrue,
      );
      expect(model.stateFor(received), DraftJourneyState.active);
      expect(model.preparingCount, 0);
      expect(model.activeCount, 1);
      expect(
        model.completePreparation(
          received,
          agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
        ),
        isFalse,
      );
    },
  );

  test(
    'simulated recipient acceptance uses the same reservation and cap guard',
    () {
      expect(model.request(first), isTrue);
      expect(model.request(second), isTrue);
      expect(model.acceptReceived(first), isFalse);
      expect(model.simulateRecipientAccept(first), isTrue);
      expect(model.simulateRecipientAccept(second), isFalse);
      expect(model.acceptReceived(received), isFalse);
      expect(model.stateFor(second), DraftJourneyState.sent);
      expect(model.stateFor(received), DraftJourneyState.received);
      expect(
        model.completePreparation(
          first,
          agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
        ),
        isTrue,
      );
      expect(model.simulateRecipientAccept(second), isFalse);
    },
  );

  test('default one place is shared by preparation and Active', () {
    expect(model.capacity, 1);
    expect(model.request(first), isTrue);
    expect(model.request(second), isTrue);
    expect(model.request(third), isTrue);
    expect(model.simulateRecipientAccept(first), isTrue);
    expect(model.simulateRecipientAccept(second), isFalse);
    expect(model.preparingCount, 1);
    expect(model.hasCapacity, isFalse);
    expect(
      model.completePreparation(
        first,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isTrue,
    );
    expect(model.activeCount, 1);
    expect(model.preparingCount, 0);
    expect(model.simulateRecipientAccept(third), isFalse);
    expect(model.hasCapacity, isFalse);
    expect(model.discoverable, isFalse);
    expect(model.acceptReceived(received), isFalse);
    expect(
      model.completePreparation(
        second,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isFalse,
    );
    expect(
      model.completePreparation(
        third,
        agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
      ),
      isFalse,
    );
    expect(model.activeCount, 1);
    expect(model.preparingCount, 0);
  });

  for (final endingState in [
    DraftJourneyState.preparing,
    DraftJourneyState.active,
  ]) {
    test(
      'ending $endingState retains terminal history with no resurrection',
      () {
        expect(model.request(first), isTrue);
        expect(model.simulateRecipientAccept(first), isTrue);
        if (endingState != DraftJourneyState.preparing) {
          expect(
            model.completePreparation(
              first,
              agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
            ),
            isTrue,
          );
        }
        expect(model.stateFor(first), endingState);
        expect(model.end(first), isTrue);
        expect(model.stateFor(first), DraftJourneyState.ended);
        expect(model.activeCount, 0);
        expect(model.preparingCount, 0);
        expect(model.discoverable, isTrue);
        expect(model.end(first), isFalse);
        expect(model.request(first), isFalse);
        expect(model.cancel(first), isFalse);
        expect(model.declineReceived(first), isFalse);
        expect(model.acceptReceived(first), isFalse);
        expect(model.simulateRecipientAccept(first), isFalse);
        expect(
          model.completePreparation(
            first,
            agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
          ),
          isFalse,
        );
      },
    );
  }

  test('requests are not Journey history and cannot be ended', () {
    expect(model.end(received), isFalse);
    expect(model.request(first), isTrue);
    expect(model.end(first), isFalse);
    expect(model.stateFor(first), DraftJourneyState.sent);
  });

  test('invalid IDs refuse every action without changing local state', () {
    final before = Map<String, DraftJourneyState>.of(model.states);
    for (final id in ['', 'missing', 'real-member-id']) {
      expect(model.stateFor(id), isNull);
      expect(model.request(id), isFalse);
      expect(model.cancel(id), isFalse);
      expect(model.declineReceived(id), isFalse);
      expect(model.acceptReceived(id), isFalse);
      expect(model.simulateRecipientAccept(id), isFalse);
      expect(
        model.completePreparation(
          id,
          agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
        ),
        isFalse,
      );
      expect(model.end(id), isFalse);
    }
    expect(model.states, before);
  });

  test('public state map cannot bypass state or capacity checks', () {
    expect(
      () => model.states[first] = DraftJourneyState.active,
      throwsUnsupportedError,
    );
    expect(() => model.states.clear(), throwsUnsupportedError);
    expect(model.activeCount, 0);
  });

  test(
    'capacity changes preserve reservations and refuse unsafe reduction',
    () {
      expect(model.setCapacity(0), isFalse);
      expect(model.setCapacity(4), isFalse);
      expect(model.capacity, 1);
      expect(model.setCapacity(3), isTrue);
      expect(model.request(first), isTrue);
      expect(model.request(second), isTrue);
      expect(model.simulateRecipientAccept(first), isTrue);
      expect(model.simulateRecipientAccept(second), isTrue);
      expect(model.setCapacity(1), isFalse);
      expect(model.capacity, 3);
      expect(model.setCapacity(2), isTrue);
      expect(
        model.completePreparation(
          first,
          agreedPaidAdditionalGuardianIds: const {'draft-guardian-yusuf'},
        ),
        isTrue,
      );
      expect(model.setCapacity(1), isFalse);
      expect(model.end(second), isTrue);
      expect(model.setCapacity(1), isTrue);
      expect(model.capacity, 1);
      expect(model.activeCount, 1);
      expect(model.hasCapacity, isFalse);
    },
  );

  test('default full-capacity preset stays local and resets changes', () {
    expect(model.request(third), isTrue);
    model.fillCapacity();
    expect(model.capacity, 1);
    expect(model.activeCount, 1);
    expect(model.preparingCount, 0);
    expect(model.stateFor(third), isNull);
    expect(model.stateFor(received), DraftJourneyState.received);
    expect(model.acceptReceived(received), isFalse);
    expect(model.discoverable, isFalse);
    expect(model.setCapacity(0), isFalse);
    model.fillCapacity();
    expect(model.capacity, 1);
    expect(model.activeCount, 1);
    expect(model.states.length, 2);
    expect(model.acceptReceived(received), isFalse);
    expect(model.discoverable, isFalse);
  });

  test(
    'fresh reset restores the initial one-slot draft and leaves no history',
    () {
      expect(model.capacity, 1);
      model.fillCapacity();
      expect(model.end(first), isTrue);
      model.reset();
      expect(model.capacity, 1);
      expect(model.states, {received: DraftJourneyState.received});
      expect(model.activeCount, 0);
      expect(model.preparingCount, 0);
      expect(model.discoverable, isTrue);
    },
  );
}
