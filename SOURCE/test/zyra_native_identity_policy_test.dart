import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_native_identity_policy.dart';

void main() {
  test('only the canonical main identity is accepted', () {
    expect(
      ZyraNativeIdentityPolicy.matches(
        variant: ZyraAppVariant.production,
        bundleId: 'app.zyraconnect.zyra',
        displayName: 'ZYRA',
      ),
      isTrue,
    );
    for (final bundle in [
      null,
      '',
      'app.zyraconnect.zyra.test',
      'another.app',
    ]) {
      expect(
        ZyraNativeIdentityPolicy.matches(
          variant: ZyraAppVariant.production,
          bundleId: bundle,
          displayName: 'ZYRA',
        ),
        isFalse,
      );
    }
    for (final name in [null, '', 'ZYRA Test', 'ZYRA Connect']) {
      expect(
        ZyraNativeIdentityPolicy.matches(
          variant: ZyraAppVariant.production,
          bundleId: 'app.zyraconnect.zyra',
          displayName: name,
        ),
        isFalse,
      );
    }
  });
  test(
    'unsupported flavor denies even with the correct installed identity',
    () {
      expect(
        ZyraNativeIdentityPolicy.matches(
          variant: ZyraAppVariant.unsupported,
          bundleId: 'app.zyraconnect.zyra',
          displayName: 'ZYRA',
        ),
        isFalse,
      );
    },
  );
}
