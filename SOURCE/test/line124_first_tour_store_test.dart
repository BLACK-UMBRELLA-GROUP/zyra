import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Existing transitive adapter, used only for controlled local-storage failures.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:zyra/dev/zyra_first_tour_store.dart';
import 'package:zyra/services/zyra_local_prefs.dart';

class _HeldReadStore extends InMemorySharedPreferencesStore {
  _HeldReadStore() : super.empty();

  final entered = Completer<void>();
  final release = Completer<void>();
  int writes = 0;

  @override
  Future<Map<String, Object>> getAll() async {
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
    return super.getAll();
  }

  @override
  Future<bool> setValue(String type, String key, Object value) {
    writes++;
    return super.setValue(type, key, value);
  }
}

class _FailedWriteStore extends InMemorySharedPreferencesStore {
  _FailedWriteStore() : super.empty();

  @override
  Future<bool> setValue(String type, String key, Object value) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => SharedPreferences.setMockInitialValues({'ordinary-setting': 'keep'}),
  );

  ZyraFirstTourStore store(String? owner, {bool Function()? canAct}) =>
      ZyraFirstTourStore(ownerId: owner, canAct: canAct ?? () => true);

  test(
    'a claimed account remains seen after rebuilding storage and host',
    () async {
      final first = store('account-a');
      expect(await first.hasSeen(), isFalse);
      expect(await first.claimFirstEntry(), isTrue);
      expect(await first.hasSeen(), isTrue);
      expect(await first.claimFirstEntry(), isFalse);
      first.close();

      SharedPreferences.resetStatic();
      final restarted = store('account-a');
      expect(await restarted.hasSeen(), isTrue);
      expect(await restarted.claimFirstEntry(), isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString('ordinary-setting'),
        'keep',
      );
    },
  );

  test(
    'account A-B-A presentation cleanup retains each account receipt',
    () async {
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount('account-a');
      final first = store('account-a');
      expect(await first.claimFirstEntry(), isTrue);
      first.close();

      await ZyraLocalPrefs.bindAccount('account-b');
      final second = store('account-b');
      expect(await second.hasSeen(), isFalse);
      expect(await second.claimFirstEntry(), isTrue);
      second.close();

      await ZyraLocalPrefs.bindAccount('account-a');
      expect(await store('account-a').claimFirstEntry(), isFalse);
      expect(await store('account-b').hasSeen(), isTrue);
    },
  );

  test(
    'only one concurrent host claims the same first account entry',
    () async {
      final hosts = List.generate(12, (_) => store('shared-account'));
      final results = await Future.wait(
        hosts.map((host) => host.claimFirstEntry()),
      );
      expect(results.where((claimed) => claimed), hasLength(1));
      expect(await store('another-account').claimFirstEntry(), isTrue);
    },
  );

  test('null-owner rehearsal is once per store and never durable', () async {
    final preview = store(null);
    expect(await preview.hasSeen(), isFalse);
    expect(await preview.claimFirstEntry(), isTrue);
    expect(await preview.claimFirstEntry(), isFalse);
    expect(await preview.hasSeen(), isTrue);
    preview.close();

    expect(await store(null).claimFirstEntry(), isTrue);
    expect((await SharedPreferences.getInstance()).getKeys(), {
      'ordinary-setting',
    });
    expect(await store('account-a').claimFirstEntry(), isTrue);
  });

  test(
    'denial and guard exceptions permanently retire the opening owner',
    () async {
      var allowed = false;
      final denied = store('account-a', canAct: () => allowed);
      expect(await denied.claimFirstEntry(), isFalse);
      allowed = true;
      expect(await denied.claimFirstEntry(), isFalse);
      expect(await denied.hasSeen(), isFalse);

      var throwing = true;
      final failed = store(
        'account-b',
        canAct: () {
          if (throwing) throw StateError('Synthetic owner denial');
          return true;
        },
      );
      expect(await failed.claimFirstEntry(), isFalse);
      throwing = false;
      expect(await failed.claimFirstEntry(), isFalse);
      expect((await SharedPreferences.getInstance()).getKeys(), {
        'ordinary-setting',
      });
    },
  );

  test(
    'revocation during storage acquisition prevents any receipt write',
    () async {
      final platform = _HeldReadStore();
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance = platform;
      var allowed = true;
      final opening = store('account-a', canAct: () => allowed);
      final pending = opening.claimFirstEntry();
      await platform.entered.future;
      allowed = false;
      platform.release.complete();
      expect(await pending, isFalse);
      expect(platform.writes, 0);
      allowed = true;
      expect(await opening.claimFirstEntry(), isFalse);
    },
  );

  test(
    'closing while waiting on another host cannot claim its account',
    () async {
      final platform = _HeldReadStore();
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance = platform;
      final first = store('account-a');
      final second = store('account-a');
      final firstClaim = first.claimFirstEntry();
      await platform.entered.future;
      final queuedClaim = second.claimFirstEntry();
      second.close();
      platform.release.complete();
      expect(await firstClaim, isTrue);
      expect(await queuedClaim, isFalse);
      expect(await second.hasSeen(), isFalse);
      expect(platform.writes, 1);
    },
  );

  test(
    'failed writes never report a durable claim or a cached false receipt',
    () async {
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance = _FailedWriteStore();
      final opening = store('account-a');
      expect(await opening.claimFirstEntry(), isFalse);
      expect(await opening.hasSeen(), isFalse);
      SharedPreferences.resetStatic();
      expect(await store('account-a').hasSeen(), isFalse);
    },
  );

  test(
    'receipt identity is the captured account ID rather than a display name',
    () async {
      var boundOwner = 'account-a';
      final opening = store(boundOwner);
      boundOwner = 'account-b';
      expect(await opening.claimFirstEntry(), isTrue);
      expect(await store(boundOwner).hasSeen(), isFalse);
      expect(await store('account-a').hasSeen(), isTrue);
      expect(await store('').claimFirstEntry(), isFalse);
    },
  );
}
