import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_profile_pause_service.dart';

import 'support/zyra_profile_pause_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = ProfilePauseFixture();
  setUpAll(fixture.initialize);
  tearDownAll(fixture.dispose);
  setUp(fixture.reset);
  tearDown(fixture.afterEach);

  ZyraProfilePauseService service({bool Function()? canAct}) {
    final value = ZyraProfilePauseService(
      expectedUserId: pauseOwnerA,
      expectedGeneration: ZyraAccountState.generation,
      canAct: canAct,
    );
    addTearDown(value.dispose);
    return value;
  }

  test(
    'schema 1 is strict, owner-specific and never treats unknown as active',
    () {
      final valid = fixture.payload();
      expect(
        ZyraProfilePauseState.fromRpc(valid, pauseOwnerA).available,
        isTrue,
      );
      for (final invalid in <Object?>[
        null,
        [],
        true,
        {...valid}..remove('paused'),
        {...valid, 'schema_version': 2},
        {...valid, 'schema_version': 1.0},
        {...valid, 'owner_id': pauseOwnerB},
        {...valid, 'paused': 'false'},
        {...valid, 'paused': null},
        {...valid, 'revision': -1},
        {...valid, 'revision': 1.0},
        {...valid, 'extra': true},
      ]) {
        final state = ZyraProfilePauseState.fromRpc(invalid, pauseOwnerA);
        expect(state.available, isFalse, reason: '$invalid');
        expect(state.paused, isNull);
        expect(state.revision, isNull);
      }
    },
  );

  test(
    'mutation without this service’s confirmed contract dispatches nothing',
    () async {
      final owner = service();
      expect(
        (await owner.setPaused(true, expectedRevision: 1)).available,
        isFalse,
      );
      expect(fixture.requests, isEmpty);
    },
  );

  test('missing RPC remains unavailable and cannot enable mutation', () async {
    fixture.missing = true;
    final owner = service();
    expect((await owner.load()).available, isFalse);
    expect(
      (await owner.setPaused(true, expectedRevision: 1)).available,
      isFalse,
    );
    expect(fixture.calls('zyra_my_profile_pause_state'), 1);
    expect(fixture.calls('zyra_set_my_profile_pause'), 0);
  });

  test('pause and unpause use CAS and fresh authoritative readback', () async {
    final owner = service();
    final token = supabase.auth.currentSession!.accessToken;
    final active = await owner.load();
    expect(active.paused, isFalse);
    final paused = await owner.setPaused(
      true,
      expectedRevision: active.revision!,
    );
    expect(paused.paused, isTrue);
    expect(paused.revision, 2);
    final unpaused = await owner.setPaused(
      false,
      expectedRevision: paused.revision!,
    );
    expect(unpaused.paused, isFalse);
    expect(unpaused.revision, 3);
    expect(fixture.calls('zyra_my_profile_pause_state'), 3);
    expect(fixture.calls('zyra_set_my_profile_pause'), 2);
    for (final request in fixture.requests) {
      expect(request.headers['authorization'], 'Bearer $token');
      expect(request.url.path, startsWith('/rest/v1/rpc/zyra_'));
    }
    final writes = fixture.requests.where(
      (request) => request.url.path.endsWith('/zyra_set_my_profile_pause'),
    );
    expect(jsonDecode(writes.first.body), {
      'p_paused': true,
      'p_expected_revision': 1,
    });
    expect(jsonDecode(writes.last.body), {
      'p_paused': false,
      'p_expected_revision': 2,
    });
  });

  test('stale revision cannot dispatch a write', () async {
    final owner = service();
    await owner.load();
    expect(
      (await owner.setPaused(true, expectedRevision: 0)).available,
      isFalse,
    );
    expect(fixture.calls('zyra_set_my_profile_pause'), 0);
  });

  test(
    'healthy refresh requires a fresh read and permits a confirmed retry',
    () async {
      final owner = service();
      final openingToken = supabase.auth.currentSession!.accessToken;
      await owner.load();
      final generation = ZyraAccountState.generation;
      await fixture.refresh();
      await Future<void>.delayed(Duration.zero);
      final refreshedToken = supabase.auth.currentSession!.accessToken;
      expect(refreshedToken, isNot(openingToken));
      expect(ZyraAccountState.generation, generation);
      expect(
        (await owner.setPaused(true, expectedRevision: 1)).available,
        isFalse,
      );
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      expect((await owner.load()).paused, isFalse);
      expect((await owner.setPaused(true, expectedRevision: 1)).paused, isTrue);
      expect(fixture.calls('zyra_my_profile_pause_state'), 3);
      expect(fixture.calls('zyra_set_my_profile_pause'), 1);
      for (final request in fixture.requests.skip(1)) {
        expect(request.headers['authorization'], 'Bearer $refreshedToken');
      }
    },
  );

  for (final change in ['SDK-only A-B-A', 'preview A-off']) {
    Future<void> changeLifetime() async {
      if (change == 'SDK-only A-B-A') {
        await fixture.session(pauseOwnerB, synchronize: false);
        await fixture.session(pauseOwnerA, synchronize: false);
      } else {
        ZyraInternalPreviewClient.beginPreview();
        ZyraInternalPreviewClient.finishSignOut();
      }
      await Future<void>.delayed(Duration.zero);
    }

    test('$change permanently retires a prior confirmed permission', () async {
      final owner = service();
      await owner.load();
      final generation = ZyraAccountState.generation;
      final token = supabase.auth.currentSession!.accessToken;
      await changeLifetime();
      expect(supabase.auth.currentUser!.id, pauseOwnerA);
      expect(supabase.auth.currentSession!.accessToken, token);
      expect(ZyraAccountState.generation, generation);
      expect(
        (await owner.setPaused(true, expectedRevision: 1)).available,
        isFalse,
      );
      expect((await owner.load()).available, isFalse);
      expect(fixture.calls('zyra_set_my_profile_pause'), 0);
      expect(fixture.calls('zyra_my_profile_pause_state'), 1);
      // Only an entirely new opening may acquire new confirmation.
      expect((await service().load()).paused, isFalse);
    });

    for (final write in [false, true]) {
      test(
        'held write=$write is denied after $change without replacement readback',
        () async {
          final owner = service();
          if (write) await owner.load();
          final started = Completer<void>();
          final release = Completer<void>();
          fixture.intercept = (request) async {
            if (!started.isCompleted) started.complete();
            await release.future;
            return ProfilePauseFixture.response({
              ...fixture.payload(),
              if (write) 'paused': true,
              if (write) 'revision': 2,
            });
          };
          final pending = write
              ? owner.setPaused(true, expectedRevision: 1)
              : owner.load();
          await started.future;
          await changeLifetime();
          release.complete();
          expect((await pending).available, isFalse);
          expect((await owner.load()).available, isFalse);
          expect(fixture.calls('zyra_set_my_profile_pause'), write ? 1 : 0);
          expect(fixture.calls('zyra_my_profile_pause_state'), 1);
        },
      );
    }
  }

  test(
    'write acknowledgment without fresh confirmation never reports paused',
    () async {
      final owner = service();
      await owner.load();
      fixture.intercept = (request) async {
        if (request.url.path.endsWith('/zyra_my_profile_pause_state')) {
          return ProfilePauseFixture.response({'message': 'Unavailable'}, 503);
        }
        return null;
      };
      final result = await owner.setPaused(true, expectedRevision: 1);
      expect(result.available, isFalse);
      expect(result.paused, isNull);
      expect(
        fixture.paused,
        isTrue,
      ); // A failed readback does not undo the write.
      await owner.setPaused(false, expectedRevision: 2);
      expect(fixture.calls('zyra_set_my_profile_pause'), 1);
    },
  );

  test(
    'malformed write acknowledgment cannot claim success or start readback',
    () async {
      final owner = service();
      await owner.load();
      fixture.intercept = (request) async =>
          request.url.path.endsWith('/zyra_set_my_profile_pause')
          ? ProfilePauseFixture.response({
              ...fixture.payload(),
              'owner_id': pauseOwnerB,
            })
          : null;
      expect(
        (await owner.setPaused(true, expectedRevision: 1)).available,
        isFalse,
      );
      expect(fixture.calls('zyra_my_profile_pause_state'), 1);
    },
  );

  test(
    'late old-owner read is discarded and that service never rebinds',
    () async {
      final release = Completer<void>();
      fixture.intercept = (_) async {
        await release.future;
        return ProfilePauseFixture.response(fixture.payload());
      };
      final owner = service();
      final pending = owner.load();
      await Future<void>.delayed(Duration.zero);
      await fixture.session(pauseOwnerB);
      release.complete();
      expect((await pending).available, isFalse);
      await fixture.session(pauseOwnerA);
      expect((await owner.load()).available, isFalse);
      expect(fixture.calls('zyra_my_profile_pause_state'), 1);
    },
  );

  test(
    'account replacement during a write prevents readback as its replacement',
    () async {
      final owner = service();
      await owner.load();
      final token = supabase.auth.currentSession!.accessToken;
      fixture.intercept = (request) async {
        if (!request.url.path.endsWith('/zyra_set_my_profile_pause')) {
          return null;
        }
        await fixture.session(pauseOwnerB);
        return ProfilePauseFixture.response({
          ...fixture.payload(),
          'paused': true,
          'revision': 2,
        });
      };
      expect(
        (await owner.setPaused(true, expectedRevision: 1)).available,
        isFalse,
      );
      expect(fixture.calls('zyra_my_profile_pause_state'), 1);
      expect(fixture.requests.last.headers['authorization'], 'Bearer $token');
      expect(supabase.auth.currentUser!.id, pauseOwnerB);
    },
  );

  test(
    'one mutation flight and an invalidated route cannot revive its reply',
    () async {
      var foreground = true;
      final owner = service(canAct: () => foreground);
      await owner.load();
      final release = Completer<void>();
      fixture.intercept = (request) async {
        if (!request.url.path.endsWith('/zyra_set_my_profile_pause')) {
          return null;
        }
        await release.future;
        return ProfilePauseFixture.response({
          ...fixture.payload(),
          'paused': true,
          'revision': 2,
        });
      };
      final first = owner.setPaused(true, expectedRevision: 1);
      final second = await owner.setPaused(true, expectedRevision: 1);
      expect(second.available, isFalse);
      await Future<void>.delayed(Duration.zero);
      foreground = false;
      owner.invalidatePending();
      foreground = true;
      release.complete();
      expect((await first).available, isFalse);
      expect(fixture.calls('zyra_set_my_profile_pause'), 1);
      expect(fixture.calls('zyra_my_profile_pause_state'), 1);
    },
  );

  test('dispose makes a held reply and future methods inert', () async {
    final release = Completer<void>();
    fixture.intercept = (_) async {
      await release.future;
      return ProfilePauseFixture.response(fixture.payload());
    };
    final owner = service();
    final pending = owner.load();
    await Future<void>.delayed(Duration.zero);
    owner.dispose();
    release.complete();
    expect((await pending).available, isFalse);
    expect((await owner.load()).available, isFalse);
    expect(
      (await owner.setPaused(true, expectedRevision: 1)).available,
      isFalse,
    );
    expect(fixture.requests, hasLength(1));
  });
}
