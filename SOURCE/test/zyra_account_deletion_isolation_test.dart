// The approval hold precedes every SDK/Storage/RPC operation, for every actor.
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_profile_service.dart';

import 'support/zyra_profile_pause_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = ProfilePauseFixture();
  setUpAll(fixture.initialize);
  tearDownAll(fixture.dispose);
  setUp(fixture.reset);
  tearDown(fixture.afterEach);

  for (final expected in [null, pauseOwnerA, pauseOwnerB]) {
    test(
      'delete hold makes no requests for expected owner $expected',
      () async {
        final generation = ZyraAccountState.generation;
        expect(
          await ZyraAuth.deleteAccount(
            expectedUserId: expected,
            expectedGeneration: generation,
          ),
          isFalse,
        );
        expect(fixture.requests, isEmpty);
        expect(supabase.auth.currentUser!.id, pauseOwnerA);
        expect(ZyraAccountState.generation, generation);
      },
    );
  }

  test(
    'same-owner replacement cannot convert a prior deletion intent into execution',
    () async {
      final previous = ZyraAccountState.generation;
      await fixture.session(pauseOwnerB);
      await fixture.session(pauseOwnerA);
      fixture.requests.clear();
      final current = ZyraAccountState.generation;
      expect(current, isNot(previous));
      expect(
        await ZyraAuth.deleteAccount(
          expectedUserId: pauseOwnerA,
          expectedGeneration: previous,
        ),
        isFalse,
      );
      expect(
        await ZyraAuth.deleteAccount(
          expectedUserId: pauseOwnerA,
          expectedGeneration: current,
        ),
        isFalse,
      );
      expect(fixture.requests, isEmpty);
      expect(supabase.auth.currentUser!.id, pauseOwnerA);
      expect(ZyraAccountState.generation, current);
    },
  );

  test('reset hold also precedes RPC and owned-photo cleanup', () async {
    expect(
      (await ZyraProfileService.resetProfile(
        expectedUserId: pauseOwnerA,
        expectedGeneration: ZyraAccountState.generation,
      )).outcome,
      ZyraResetOutcome.refused,
    );
    expect(fixture.requests, isEmpty);
    expect(supabase.auth.currentUser!.id, pauseOwnerA);
  });

  test(
    'repeated reset/delete methods stay non-destructive without a UI guard',
    () async {
      for (var repeat = 0; repeat < 3; repeat++) {
        expect(await ZyraAuth.deleteAccount(), isFalse);
        expect(
          (await ZyraProfileService.resetProfile()).outcome,
          ZyraResetOutcome.refused,
        );
      }
      expect(fixture.requests, isEmpty);
      expect(supabase.auth.currentUser!.id, pauseOwnerA);
    },
  );
}
