import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/services/zyra_seeker_details_service.dart';

void main() {
  group('OA-ZYRA-229 sect code contract', () {
    test('normalises labels once at the write boundary', () {
      expect(zyraSectCodeFor('Sunni'), 'sunni');
      expect(zyraSectCodeFor(' Shia '), 'shia');
      expect(zyraSectCodeFor('Ahl-e-Hadith'), 'ahl-e-hadith');
      expect(zyraSectCodeFor('Ahl e Hadith'), 'ahl-e-hadith');
    });

    test('uses the same code for the own answer and preference keys', () {
      const details = SeekerDetails(sect: 'Ahl-e-Hadith');
      final ownRow = details.toRow('00000000-0000-0000-0000-000000000001');
      final preferences = ZyraSeekerDetailsService.buildPreferences(
        sectMatrix: const {
          'Ahl-e-Hadith': TrafficLight.green,
          'Sunni': TrafficLight.yellow,
        },
        sectHard: const {'Shia'},
      );

      expect(ownRow['sect'], 'ahl-e-hadith');
      expect(ownRow['sect_other'], 'Ahl-e-Hadith');
      expect(preferences['sect']['matrix'], {
        'ahl-e-hadith': 'green',
        'sunni': 'yellow',
      });
      expect(preferences['sect']['hard_requirement'], ['shia']);
    });
  });
}
