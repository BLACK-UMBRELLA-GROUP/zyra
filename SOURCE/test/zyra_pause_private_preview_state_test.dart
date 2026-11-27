import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_pause_private_preview_state.dart';

void main() {
  test('Pause blocks discovery and new requests while retaining Private', () {
    final state = ZyraPausePrivatePreviewState(
      canAct: () => true,
      seekerOne: () => true,
    );
    addTearDown(state.dispose);
    expect(state.discoveryVisible, isTrue);
    expect(state.canBrowse, isTrue);
    expect(state.canSendRequest, isTrue);
    expect(state.canReceiveNewRequest(fromRequestedPerson: false), isTrue);
    expect(state.setPrivateMode(true), isTrue);
    expect(state.pause(), isTrue);
    expect(state.paused, isTrue);
    expect(state.privateMode, isTrue);
    expect(state.discoveryVisible, isFalse);
    expect(state.canBrowse, isFalse);
    expect(state.canSendRequest, isFalse);
    expect(state.canReceiveNewRequest(fromRequestedPerson: false), isFalse);
    expect(state.canReceiveNewRequest(fromRequestedPerson: true), isFalse);
    expect(state.showProfile(), isTrue);
    expect(state.paused, isFalse);
    expect(state.privateMode, isTrue);
    expect(state.discoveryVisible, isFalse);
    expect(state.canBrowse, isTrue);
    expect(state.canSendRequest, isTrue);
  });

  test(
    'Basic cannot enable Private; One may browse, send and receive replies',
    () {
      var one = false;
      final state = ZyraPausePrivatePreviewState(
        canAct: () => true,
        seekerOne: () => one,
      );
      addTearDown(state.dispose);
      expect(state.setPrivateMode(true), isFalse);
      expect(state.privateMode, isFalse);
      expect(state.discoveryVisible, isTrue);
      one = true;
      expect(state.setPrivateMode(true), isTrue);
      expect(state.discoveryVisible, isFalse);
      expect(state.canBrowse, isTrue);
      expect(state.canSendRequest, isTrue);
      expect(state.canReceiveNewRequest(fromRequestedPerson: false), isFalse);
      expect(state.canReceiveNewRequest(fromRequestedPerson: true), isTrue);
      expect(state.setPrivateMode(false), isTrue);
      expect(state.discoveryVisible, isTrue);
      expect(state.canReceiveNewRequest(fromRequestedPerson: false), isTrue);
    },
  );

  test(
    'downgrade clears Private without clearing pause or reviving on upgrade',
    () {
      var one = true;
      var changes = 0;
      final state = ZyraPausePrivatePreviewState(
        canAct: () => true,
        seekerOne: () => one,
      )..addListener(() => changes++);
      addTearDown(state.dispose);
      state.setPrivateMode(true);
      state.pause();
      one = false;
      expect(state.privateMode, isFalse);
      expect(state.synchronizePlan(notify: false), isTrue);
      expect(state.paused, isTrue);
      expect(changes, 2);
      expect(state.synchronizePlan(), isFalse);
      one = true;
      expect(state.privateMode, isFalse);
      state.showProfile();
      expect(state.discoveryVisible, isTrue);
    },
  );

  testWidgets('pause remains until explicit unpause after a long break', (
    tester,
  ) async {
    final state = ZyraPausePrivatePreviewState(
      canAct: () => true,
      seekerOne: () => true,
    );
    addTearDown(state.dispose);
    state.pause();
    await tester.pump(const Duration(days: 400));
    expect(state.paused, isTrue);
    expect(state.canBrowse, isFalse);
    expect(state.canSendRequest, isFalse);
    expect(state.showProfile(), isTrue);
    expect(state.canBrowse, isTrue);
    expect(state.canSendRequest, isTrue);
  });

  test('revoked owner cannot revive on A-B-A or change either policy', () {
    var admitted = true;
    final state = ZyraPausePrivatePreviewState(
      canAct: () => admitted,
      seekerOne: () => true,
    );
    addTearDown(state.dispose);
    state.pause();
    admitted = false;
    expect(state.current, isFalse);
    admitted = true;
    expect(state.showProfile(), isFalse);
    expect(state.setPrivateMode(true), isFalse);
    expect(state.pause(), isFalse);
    expect(state.canBrowse, isFalse);
    expect(state.canSendRequest, isFalse);
    expect(state.canReceiveNewRequest(fromRequestedPerson: true), isFalse);
  });

  test('throwing authority and membership callbacks fail closed', () {
    final denied = ZyraPausePrivatePreviewState(
      canAct: () => throw StateError('owner ended'),
      seekerOne: () => true,
    );
    addTearDown(denied.dispose);
    expect(denied.pause(), isFalse);
    expect(denied.canSendRequest, isFalse);
    final unknownPlan = ZyraPausePrivatePreviewState(
      canAct: () => true,
      seekerOne: () => throw StateError('plan unavailable'),
    );
    addTearDown(unknownPlan.dispose);
    expect(unknownPlan.setPrivateMode(true), isFalse);
    expect(unknownPlan.privateMode, isFalse);
  });
}
