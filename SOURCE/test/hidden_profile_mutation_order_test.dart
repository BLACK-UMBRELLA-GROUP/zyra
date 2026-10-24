import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_hidden_profile_store.dart';

SeekerProfile person(String id) => SeekerProfile(
  id: id,
  firstName: id,
  age: 25,
  city: 'London',
  gender: 'female',
  photos: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZyraHiddenProfileStore.clearForAccountChange();
  });
  Future<Set<String>> ids() => ZyraHiddenProfileStore.hiddenIds();

  test('concurrent hides retain both profile summaries', () async {
    await Future.wait([
      ZyraHiddenProfileStore.remember(person('a')),
      ZyraHiddenProfileStore.remember(person('b')),
    ]);
    expect(await ids(), {'a', 'b'});
  });
  test(
    'concurrent unhide does not restore a previously removed record',
    () async {
      await ZyraHiddenProfileStore.remember(person('a'));
      await ZyraHiddenProfileStore.remember(person('b'));
      await Future.wait([
        ZyraHiddenProfileStore.forget('a'),
        ZyraHiddenProfileStore.forget('b'),
      ]);
      expect(await ids(), isEmpty);
    },
  );
  test('hide then unhide of the same profile leaves it visible', () async {
    await Future.wait([
      ZyraHiddenProfileStore.remember(person('a')),
      ZyraHiddenProfileStore.forget('a'),
    ]);
    expect(await ids(), isEmpty);
  });
  test('unhide then hide of the same profile leaves it hidden', () async {
    await ZyraHiddenProfileStore.remember(person('a'));
    await Future.wait([
      ZyraHiddenProfileStore.forget('a'),
      ZyraHiddenProfileStore.remember(person('a')),
    ]);
    expect(await ids(), {'a'});
  });
  test(
    'account epoch invalidation skips queued old-owner cache writes',
    () async {
      final old = ZyraHiddenProfileStore.remember(person('old'));
      ZyraHiddenProfileStore.clearForAccountChange();
      final current = ZyraHiddenProfileStore.remember(person('current'));
      await Future.wait([old, current]);
      expect(await ids(), {'current'});
    },
  );
  test('normal sequential hide and unhide stay unchanged', () async {
    await ZyraHiddenProfileStore.remember(person('a'));
    expect(await ids(), {'a'});
    await ZyraHiddenProfileStore.forget('a');
    expect(await ids(), isEmpty);
  });
}
