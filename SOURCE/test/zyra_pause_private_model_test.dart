import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_pause_private_preview_state.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

void main() {
  ZyraPausePrivatePreviewState state() =>
      ZyraPausePrivatePreviewState(canAct: () => true, seekerOne: () => true);

  test(
    'paused send boundary preserves waiting requests and active Journeys',
    () {
      final privacy = state();
      addTearDown(privacy.dispose);
      final model = ViewRequestDraftModel(capacity: 3)
        ..ownProfilePrivacy = privacy;
      final before = model.snapshot();
      expect(privacy.pause(), isTrue);
      expect(model.request('draft-zainab'), isFalse);
      expect(model.states, before.states);
      expect(model.discoverable, isFalse);
      expect(privacy.showProfile(), isTrue);
      expect(model.request('draft-zainab'), isTrue);
    },
  );

  test('private member stays out of other Profiles and can send normally', () {
    final privacy = state();
    addTearDown(privacy.dispose);
    final model = ViewRequestDraftModel(capacity: 3)
      ..ownProfilePrivacy = privacy;
    final other = ViewRequestDraftModel(capacity: 3);
    other.candidateProfilePrivacy['draft-zainab'] = privacy;
    expect(
      other.discoverableProfiles.any((p) => p.id == 'draft-zainab'),
      isTrue,
    );
    expect(privacy.setPrivateMode(true), isTrue);
    expect(model.discoverable, isFalse);
    expect(
      other.discoverableProfiles.any((p) => p.id == 'draft-zainab'),
      isFalse,
    );
    expect(model.request('draft-zainab'), isTrue);
    expect(privacy.canReceiveNewRequest(fromRequestedPerson: false), isFalse);
    expect(privacy.canReceiveNewRequest(fromRequestedPerson: true), isTrue);
    expect(privacy.pause(), isTrue);
    expect(privacy.privateMode, isTrue);
    expect(privacy.canReceiveNewRequest(fromRequestedPerson: true), isFalse);
    expect(privacy.showProfile(), isTrue);
    expect(privacy.privateMode, isTrue);
    expect(
      other.discoverableProfiles.any((p) => p.id == 'draft-zainab'),
      isFalse,
    );
    expect(privacy.setPrivateMode(false), isTrue);
    expect(
      other.discoverableProfiles.any((p) => p.id == 'draft-zainab'),
      isTrue,
    );
    expect(privacy.pause(), isTrue);
    expect(
      other.discoverableProfiles.any((p) => p.id == 'draft-zainab'),
      isFalse,
    );
  });
  test(
    'paused model admission blocks ended restart and restores on unpause',
    () {
      var now = DateTime.utc(2026, 11, 27);
      final privacy = state();
      addTearDown(privacy.dispose);
      final model = ViewRequestDraftModel(capacity: 3, clock: () => now)
        ..ownProfilePrivacy = privacy;
      expect(model.seedJourneys(1), isTrue);
      expect(model.end('draft-sara'), isTrue);
      now = now.add(const Duration(hours: 25));
      expect(model.canRequestEndedJourney('draft-sara'), isTrue);
      privacy.pause();
      final before = model.snapshot();
      expect(model.canBrowse, isFalse);
      expect(model.canRequest('draft-zainab'), isFalse);
      expect(model.canRequestEndedJourney('draft-sara'), isFalse);
      expect(model.requestEndedJourney('draft-sara'), isFalse);
      expect(model.snapshot().restartRequestedAt, before.restartRequestedAt);
      privacy.showProfile();
      expect(model.canBrowse, isTrue);
      expect(model.requestEndedJourney('draft-sara'), isTrue);
    },
  );
}
