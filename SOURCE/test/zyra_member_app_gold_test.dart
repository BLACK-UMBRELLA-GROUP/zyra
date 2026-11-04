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
    'ordinary members can choose gold without developer authorization',
    () async {
      await ZyraAccountState.synchronize(_member);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);

      expect(_chooseMember(true), isTrue);
      expect(ZyraAppGoldStyle.instance.enabled, isTrue);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isTrue);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isTrue);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isTrue);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isTrue);

      expect(_chooseMember(false), isTrue);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
    },
  );

  test(
    'same-owner cold restart restores the saved gold choice only after binding',
    () async {
      await ZyraAccountState.synchronize(_member);
      expect(_chooseMember(true), isTrue);
      await ZyraLocalPrefs.init();
      ZyraAppGoldStyle.instance.restore(false);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);

      ZyraAccountState.resetForTesting();
      await ZyraAccountState.synchronize(_member);
      ZyraAppGoldStyle.instance.restoreCurrent();
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isTrue);
      expect(ZyraAppGoldStyle.instance.enabled, isTrue);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isTrue);
      final stored = await SharedPreferences.getInstance();
      expect(stored.getBool(_goldKey), isTrue);
    },
  );

  test(
    'pre-auth previews remain ephemeral and are not adopted by a member',
    () async {
      expect(ZyraLocalPrefs.accountOwner, isNull);
      expect(_chooseMember(true), isTrue);
      expect(ZyraAppGoldStyle.instance.enabled, isTrue);
      final stored = await SharedPreferences.getInstance();
      expect(stored.containsKey(_goldKey), isFalse);

      await ZyraAccountState.synchronize(_member);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
    },
  );

  test(
    'unchanged restoration keeps a retained member callback valid',
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
        isTrue,
      );
      expect(selection.enabled, isTrue);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isTrue);
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
      expect(_chooseMember(true), isTrue);
      expect(
        member.select(
          false,
          expectedGeneration: generation,
          expectedRevision: revision,
        ),
        isFalse,
      );
      expect(member.enabled, isTrue);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isTrue);

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
      expect(_chooseMember(true), isTrue);
      final leaving = ZyraAccountState.synchronize(null);
      final entering = ZyraAccountState.synchronize(_other);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(_chooseMember(false), isTrue);
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
    'sign-out clears member gold synchronously and rejects an in-flight choice',
    () async {
      await ZyraAccountState.synchronize(_member);
      expect(_chooseMember(true), isTrue);
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
      await ZyraAccountState.synchronize(_member);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);
      expect(ZyraAppGoldStyle.instance.enabled, isFalse);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isFalse);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isFalse);

      expect(_chooseMember(true), isTrue);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isTrue);
      expect(ZyraAppGoldStyle.instance.enabled, isTrue);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isTrue);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isTrue);
      expect(ZyraAppGoldStyle.instance.enabled, isTrue);
      final stored = await SharedPreferences.getInstance();
      expect(stored.getBool(_goldKey), isTrue);
    },
  );

  test(
    'repeated member selections reject stale callbacks and remain authoritative',
    () async {
      await ZyraAccountState.synchronize(_member);
      final member = ZyraAppGoldStyle.instance;
      final generation = ZyraAccountState.generation;
      final offRevision = member.revision;
      expect(_chooseMember(false), isTrue);
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

      expect(_chooseMember(true), isTrue);
      final onRevision = member.revision;
      expect(_chooseMember(true), isTrue);
      expect(
        member.select(
          false,
          expectedGeneration: generation,
          expectedRevision: onRevision,
        ),
        isFalse,
      );
      expect(ZyraAppGoldRenderer.instance.renderingEnabled, isTrue);
      expect(member.enabled, isTrue);
      expect(ZyraLocalPrefs.cachedAppGoldEnabled, isTrue);
    },
  );
}
