import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';

const _member = '11111111-1111-4111-8111-111111111111';
const _other = '22222222-2222-4222-8222-222222222222';
const _goldKey = 'zyra.app_gold_enabled';

bool _chooseMember(bool value) => ZyraAppGoldStyle.instance.select(
  value,
  expectedGeneration: ZyraAccountState.generation,
  expectedRevision: ZyraAppGoldStyle.instance.revision,
);

Future<void> _coldRestore(
  Map<String, Object> stored, {
  String? account = _member,
}) async {
  SharedPreferences.setMockInitialValues(stored);
  await ZyraLocalPrefs.init();
  ZyraAccountState.resetForTesting();
  await ZyraAccountState.synchronize(account);
  ZyraAppGoldStyle.instance.restoreCurrent();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await ZyraAccountState.synchronize(null);
    ZyraAppGoldStyle.instance.restore(false);
    ZyraAppGoldRenderer.instance.resetForTesting();
  });

  tearDown(() async {
    ZyraAppGoldStyle.instance.restore(false);
    ZyraAppGoldRenderer.instance.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    await ZyraAccountState.synchronize(null);
    ZyraAccountState.clearImagesForTesting = null;
  });

  test(
    'retired Gold selections are refused for ordinary members',
    () async {
      await ZyraAccountState.synchronize(_member);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);

      expect(_chooseMember(true), isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);

      expect(_chooseMember(false), isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
    },
  );

  test(
    'same-owner cold restart ignores the saved Gold choice without rewriting it',
    () async {
      await _coldRestore({
        'zyra.cached_account_owner': _member,
        _goldKey: true,
      });
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
      expect(_chooseMember(false), isFalse);
      expect(_chooseMember(true), isFalse);
      final stored = await SharedPreferences.getInstance();
      expect(stored.getBool(_goldKey), isTrue);
    },
  );

  test(
    'pre-auth Gold selection cannot be written or adopted by a member',
    () async {
      expect(ZyraLocalPrefs.accountOwner, isNull);
      expect(_chooseMember(true), isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      final stored = await SharedPreferences.getInstance();
      expect(stored.containsKey(_goldKey), isFalse);

      await ZyraAccountState.synchronize(_member);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
    },
  );

  test(
    'unchanged restoration leaves a retained Gold callback inert',
    () async {
      await ZyraAccountState.synchronize(_member);
      final selection = ZyraAppGoldStyle.instance;
      final generation = ZyraAccountState.generation;
      final revision = selection.revision;
      selection.restoreCurrent();
      expect(selection.revision, revision);
      expect(
        selection.select(
          true,
          expectedGeneration: generation,
          expectedRevision: revision,
        ),
        isFalse,
      );
      expect(selection.enabled, isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
    },
  );

  for (final account in [_other, null]) {
    test(
      'a saved choice is not restored for ${account == null ? 'anonymous' : 'another account'}',
      () async {
        await _coldRestore({
          'zyra.cached_account_owner': _member,
          _goldKey: true,
        }, account: account);
        expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
        expect(ZyraAppGoldStyle.instance.enabled, isFalse);
        expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
        final stored = await SharedPreferences.getInstance();
        expect(stored.containsKey(_goldKey), isFalse);
      },
    );
  }

  test('unowned legacy gold cannot be claimed by the next account', () async {
    await _coldRestore({_goldKey: true, 'zyra.cache_schema_version': 9});
    expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
    expect(ZyraAppGoldStyle.instance.enabled, isFalse);
    expect(ZyraLocalPrefs.cacheSchemaVersion, 9);
    final stored = await SharedPreferences.getInstance();
    expect(stored.containsKey(_goldKey), isFalse);
  });

  for (final malformed in <Object?>[null, 'true', 'false', 1]) {
    test('missing or malformed gold value $malformed defaults Off', () async {
      await _coldRestore({
        'zyra.cached_account_owner': _member,
        _goldKey: ?malformed,
      });
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
    });
  }

  test(
    'stale generation and revision callbacks cannot alter the choice',
    () async {
      await ZyraAccountState.synchronize(_member);
      final member = ZyraAppGoldStyle.instance;
      final generation = ZyraAccountState.generation;
      final revision = member.revision;
      expect(_chooseMember(true), isFalse);
      expect(
        member.select(
          false,
          expectedGeneration: generation,
          expectedRevision: revision,
        ),
        isFalse,
      );
      expect(member.enabled, isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);

      final switching = ZyraAccountState.synchronize(_other);
      expect(
        member.enabled,
        isFalse,
        reason: 'The old presentation clears before disk cleanup.',
      );
      expect(
        member.select(
          true,
          expectedGeneration: generation,
          expectedRevision: member.revision,
        ),
        isFalse,
      );
      await switching;
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(member.enabled, isFalse);
    },
  );

  test(
    'rapid account switches cannot attribute an old gold write to a new owner',
    () async {
      await ZyraAccountState.synchronize(_member);
      expect(_chooseMember(true), isFalse);
      final leaving = ZyraAccountState.synchronize(null);
      final entering = ZyraAccountState.synchronize(_other);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(_chooseMember(false), isFalse);
      await Future.wait([leaving, entering]);
      await ZyraLocalPrefs.init();
      ZyraAccountState.resetForTesting();
      await ZyraAccountState.synchronize(_other);
      ZyraAppGoldStyle.instance.restoreCurrent();
      expect(ZyraLocalPrefs.accountOwner, _other);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
    },
  );

  test(
    'sign-out continues to reject a retained Gold choice',
    () async {
      await ZyraAccountState.synchronize(_member);
      expect(_chooseMember(true), isFalse);
      final leaving = ZyraAccountState.beginSignOut();
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
      expect(_chooseMember(true), isFalse);
      await leaving;
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      ZyraAccountState.endSignOutAttempt();
    },
  );

  test(
    'developer authorization cannot override a saved member preference',
    () async {
      await _coldRestore({
        'zyra.cached_account_owner': _member,
        _goldKey: true,
      });
      for (final authorized in [false, true, false]) {
        ZyraDeveloperAccess.setAuthorizedForTesting(authorized);
        expect(_chooseMember(true), isFalse);
        expect(ZyraAppGoldStyle.instance.enabled, isFalse);
        expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
      }
      final stored = await SharedPreferences.getInstance();
      expect(stored.getBool(_goldKey), isTrue);
    },
  );

  test(
    'repeated member Gold selections never acquire authority',
    () async {
      await ZyraAccountState.synchronize(_member);
      final member = ZyraAppGoldStyle.instance;
      final generation = ZyraAccountState.generation;
      final offRevision = member.revision;
      expect(_chooseMember(false), isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(
        member.select(
          true,
          expectedGeneration: generation,
          expectedRevision: offRevision,
        ),
        isFalse,
      );

      expect(_chooseMember(true), isFalse);
      final onRevision = member.revision;
      expect(_chooseMember(true), isFalse);
      expect(
        member.select(
          false,
          expectedGeneration: generation,
          expectedRevision: onRevision,
        ),
        isFalse,
      );
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
      expect(member.enabled, isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
    },
  );
}
