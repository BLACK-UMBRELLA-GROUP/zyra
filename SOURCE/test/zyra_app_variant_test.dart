import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/zyra_app_variant.dart';

void main() {
  test('only default and production select the one active app', () {
    for (final flavor in <String?>[null, '', 'production']) {
      expect(
        ZyraAppVariantPolicy.fromFlavor(flavor),
        ZyraAppVariant.production,
      );
    }
    for (final flavor in [
      'foundertest',
      'founderTest',
      'test',
      'unknown',
      'Production',
    ]) {
      expect(
        ZyraAppVariantPolicy.fromFlavor(flavor),
        ZyraAppVariant.unsupported,
      );
    }
  });
}
