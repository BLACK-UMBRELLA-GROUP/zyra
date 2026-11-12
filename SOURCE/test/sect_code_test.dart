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

    test('restoring truncated display words preserves the full sect code', () {
      const label =
          'A synthetic sect label that is deliberately long enough to truncate';
      const userId = '00000000-0000-0000-0000-000000000001';
      final original = SeekerDetails(sect: label).toRow(userId);
      final restored = SeekerDetails.fromRow(original);

      expect(restored.sect, label.substring(0, 60));
      expect(restored.canonicalSectCode, zyraSectCodeFor(label));
      expect(restored.thirdSectKey, zyraSectCodeFor(label));
      expect(restored.toRow(userId)['sect'], original['sect']);
      expect(restored.toRow(userId)['sect_other'], original['sect_other']);

      const edited = SeekerDetails(sect: 'New synthetic words');
      expect(edited.toRow(userId)['sect'], 'new-synthetic-words');
      expect(edited.thirdSectKey, 'new-synthetic-words');
    });

    test(
      'older literal Other rows keep their saved code and use their words',
      () {
        final restored = SeekerDetails.fromRow({
          'sect': 'other',
          'sect_other': 'Synthetic Sect',
        });

        expect(restored.canonicalSectCode, 'other');
        expect(restored.thirdSectKey, 'synthetic-sect');
        for (final label in [' Sunni ', 'SHIA']) {
          final malformed = SeekerDetails.fromRow({
            'sect': 'other',
            'sect_other': label,
          });
          expect(malformed.thirdSectKey, 'other');
        }
        expect(const SeekerDetails(sect: 'Sunni').thirdSectKey, 'other');
        expect(const SeekerDetails().thirdSectKey, 'other');
      },
    );

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
