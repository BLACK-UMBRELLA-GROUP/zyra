import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_auth.dart';

void main() {
  group('OAuth onboarding first name', () {
    test('prefers provider given name', () {
      expect(
        ZyraAuth.firstNameFromMetadata({
          'given_name': '  Shakeel  ',
          'full_name': 'Different Name',
        }),
        'Shakeel',
      );
    });

    test('falls back to the first word of a provider display name', () {
      expect(
        ZyraAuth.firstNameFromMetadata({'full_name': 'Shakeel Ahmad'}),
        'Shakeel',
      );
      expect(
        ZyraAuth.firstNameFromMetadata({'name': 'Maryam Fatima Ahmed'}),
        'Maryam',
      );
    });

    test('never invents a greeting name from empty metadata', () {
      expect(ZyraAuth.firstNameFromMetadata(null), isNull);
      expect(ZyraAuth.firstNameFromMetadata({}), isNull);
      expect(ZyraAuth.firstNameFromMetadata({'given_name': '  '}), isNull);
    });
  });
}
