import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_gender.dart';
import 'package:zyra/services/zyra_profile_service.dart';

void main() {
  group('ZYRA gender correctness', () {
    test('uses neutral language rather than guessing unknown data', () {
      expect(ZyraGender.subject(null), 'they');
      expect(ZyraGender.subject('unknown', capitalized: true), 'They');
      expect(ZyraGender.possessive(null), 'their');
      expect(ZyraGender.profileLabel(null), '—');
      expect(
        ZyraGender.keepsPlaceLine(null),
        "They keep their place — return when you're ready.",
      );
    });

    test('one helper supplies every opposite-gender decision', () {
      expect(ZyraGender.oppositeCode('male'), 'female');
      expect(ZyraGender.oppositeCode('female'), 'male');
      expect(ZyraGender.oppositeCode(null), 'female');
    });

    test('renders correct male and female language', () {
      expect(ZyraGender.subject('male', capitalized: true), 'He');
      expect(ZyraGender.possessive('male'), 'his');
      expect(ZyraGender.subject('female', capitalized: true), 'She');
      expect(ZyraGender.possessive('female'), 'her');
    });

    test('female Guardian profile creation carries female to the RPC', () {
      final params = ZyraProfileService.createProfileParams(
        role: 'wali',
        firstName: 'Khadija',
        gender: 'female',
        dob: DateTime(1980, 6, 12),
      );

      expect(params['p_role'], 'wali');
      expect(params['p_gender'], 'female');
      expect(params['p_dob'], '1980-06-12');
    });
  });
}
