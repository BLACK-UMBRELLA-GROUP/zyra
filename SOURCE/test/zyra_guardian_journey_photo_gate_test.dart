import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';

void main() {
  test('Guardian Journey never receives an unprepared or denied face', () {
    const prepared = 'data:image/jpeg;base64,AQID';
    expect(
      zyraGuardianJourneyPhoto(
        allowed: true,
        blocked: false,
        preparedPhoto: null,
      ),
      isNull,
    );
    expect(
      zyraGuardianJourneyPhoto(
        allowed: false,
        blocked: false,
        preparedPhoto: prepared,
      ),
      isNull,
    );
    expect(
      zyraGuardianJourneyPhoto(
        allowed: true,
        blocked: true,
        preparedPhoto: prepared,
      ),
      isNull,
    );
    expect(
      zyraGuardianJourneyPhoto(
        allowed: true,
        blocked: false,
        preparedPhoto: prepared,
      ),
      isA<MemoryImage>(),
    );
  });
}
