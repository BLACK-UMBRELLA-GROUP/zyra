import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/services/zyra_local_prefs.dart';

// Fake preference owners only. A restored role is never Auth/Founder proof.
const _owner = 'presentation-owner-a';
const _other = 'presentation-owner-b';
const _roleKey = 'zyra.founder_preview_role';
const _ownerKey = 'zyra.cached_account_owner';

Future<void> _choose({
  String role = 'guardian',
  String owner = _owner,
  int? binding,
}) async {
  final generation = binding ?? ZyraLocalPrefs.bindingGeneration;
  await ZyraLocalPrefs.setFounderPreviewRole(
    role,
    expectedOwner: owner,
    expectedBindingGeneration: generation,
  );
}

void _expectDefaults() {
  expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'seeker');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await ZyraLocalPrefs.clear();
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
  });

  tearDown(() => ZyraLocalPrefs.clear());

  test(
    'missing choices default without writing a preference or owner',
    () async {
      _expectDefaults();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      expect(ZyraLocalPrefs.accountOwner, isNull);
      expect(ZyraLocalPrefs.hasBoundAccount, isFalse);
    },
  );

  test('valid choices persist only for the captured bound owner', () async {
    await ZyraLocalPrefs.bindAccount(_owner);
    final generation = ZyraLocalPrefs.bindingGeneration;
    await _choose(binding: generation);
    expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'guardian');
    expect(ZyraLocalPrefs.bindingGeneration, generation);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_roleKey), 'guardian');
    expect(prefs.getString(_ownerKey), _owner);
    // The sample-role choice does not become the real cached account role.
    expect(ZyraLocalPrefs.cachedRole, isNull);
    await _choose(role: 'seeker');
    _expectDefaults();
    expect(prefs.getString(_roleKey), 'seeker');
  });

  test(
    'cold restore exposes choices only after matching owner binding',
    () async {
      await ZyraLocalPrefs.bindAccount(_owner);
      await _choose();
      final previousBinding = ZyraLocalPrefs.bindingGeneration;
      await ZyraLocalPrefs.init();
      _expectDefaults();
      expect(ZyraLocalPrefs.canRestoreAccount(_owner), isTrue);
      expect(ZyraLocalPrefs.bindingGeneration, greaterThan(previousBinding));
      await ZyraLocalPrefs.bindAccount(_owner);
      expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'guardian');
    },
  );

  for (final invalid in <Object>['', 'unknown', 'INVALID_ROLE', true, 7]) {
    test(
      'invalid stored choice $invalid defaults without repairing disk',
      () async {
        SharedPreferences.setMockInitialValues({
          _ownerKey: _owner,
          _roleKey: invalid,
        });
        await ZyraLocalPrefs.init();
        await ZyraLocalPrefs.bindAccount(_owner);
        _expectDefaults();
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.get(_roleKey), invalid);
      },
    );
  }

  test('unowned legacy choices are not inherited by a new owner', () async {
    SharedPreferences.setMockInitialValues({
      _roleKey: 'guardian',
      'zyra.cache_schema_version': 9,
      'unrelated-setting': 'preserved',
    });
    await ZyraLocalPrefs.init();
    _expectDefaults();
    await ZyraLocalPrefs.bindAccount(_owner);
    _expectDefaults();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get(_roleKey), isNull);
    expect(prefs.getInt('zyra.cache_schema_version'), 9);
    expect(prefs.getString('unrelated-setting'), 'preserved');
  });

  test(
    'pre-auth, signed-out and empty-owner setters cannot change memory',
    () async {
      await _choose();
      _expectDefaults();
      await ZyraLocalPrefs.bindAccount(null);
      await _choose();
      _expectDefaults();
      await ZyraLocalPrefs.bindAccount('');
      await _choose(owner: '');
      _expectDefaults();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(_roleKey), isNull);
    },
  );

  test('wrong owner and binding revision setters are inert', () async {
    await ZyraLocalPrefs.bindAccount(_owner);
    final generation = ZyraLocalPrefs.bindingGeneration;
    await _choose(owner: _other, binding: generation);
    await _choose(binding: generation - 1);
    await _choose(binding: generation + 1);
    _expectDefaults();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get(_roleKey), isNull);
  });

  test('invalid setter values preserve a valid selection and disk', () async {
    await ZyraLocalPrefs.bindAccount(_owner);
    await _choose();
    await _choose(role: 'wali');
    expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'guardian');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_roleKey), 'guardian');
  });

  test(
    'account transfer clears the preview role synchronously and on disk',
    () async {
      await ZyraLocalPrefs.bindAccount(_owner);
      await _choose();
      final changing = ZyraLocalPrefs.bindAccount(_other);
      _expectDefaults();
      await changing;
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(_roleKey), isNull);
      expect(prefs.getString(_ownerKey), _other);
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount(_other);
      _expectDefaults();
    },
  );

  test(
    'retained setters refuse A to B to A even with the same owner ID',
    () async {
      await ZyraLocalPrefs.bindAccount(_owner);
      final staleBinding = ZyraLocalPrefs.bindingGeneration;
      await ZyraLocalPrefs.bindAccount(_other);
      await ZyraLocalPrefs.bindAccount(_owner);
      expect(ZyraLocalPrefs.bindingGeneration, greaterThan(staleBinding));
      await _choose(binding: staleBinding);
      _expectDefaults();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(_roleKey), isNull);
      await _choose();
      expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'guardian');
    },
  );

  test(
    'queued choices cannot overwrite a newer account or later A binding',
    () async {
      await ZyraLocalPrefs.bindAccount(_owner);
      final firstBinding = ZyraLocalPrefs.bindingGeneration;
      final staleRole = ZyraLocalPrefs.setFounderPreviewRole(
        'guardian',
        expectedOwner: _owner,
        expectedBindingGeneration: firstBinding,
      );
      final enteringB = ZyraLocalPrefs.bindAccount(_other);
      final returningA = ZyraLocalPrefs.bindAccount(_owner);
      final currentBinding = ZyraLocalPrefs.bindingGeneration;
      final currentRole = ZyraLocalPrefs.setFounderPreviewRole(
        'seeker',
        expectedOwner: _owner,
        expectedBindingGeneration: currentBinding,
      );
      await Future.wait([staleRole, enteringB, returningA, currentRole]);
      _expectDefaults();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_ownerKey), _owner);
      expect(prefs.getString(_roleKey), 'seeker');
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount(_owner);
      _expectDefaults();
    },
  );

  test(
    'clear removes the preview role while leaving device metadata alone',
    () async {
      await ZyraLocalPrefs.bindAccount(_owner);
      await _choose();
      await ZyraLocalPrefs.setCacheSchemaVersion(9);
      final clearing = ZyraLocalPrefs.clear();
      _expectDefaults();
      await clearing;
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(_roleKey), isNull);
      expect(prefs.get(_ownerKey), isNull);
      expect(prefs.getInt('zyra.cache_schema_version'), 9);
    },
  );
}
