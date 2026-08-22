import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_journey_service.dart';

void main() {
  test('OA-ZYRA-204 maps the server busy signal onto each match id', () {
    final result = ZyraJourneyService.busyFlagsFromRows([
      {'match_id': 'match-a', 'in_another_journey': true},
      {'match_id': 'match-b', 'in_another_journey': false},
    ]);

    expect(result, {'match-a': true, 'match-b': false});
  });

  test('OA-ZYRA-204 keeps the honest busy-card copy in Activity', () {
    final source = File(
      'lib/screens/connections/connections_screen.dart',
    ).readAsStringSync();

    expect(source, contains("? 'In another Journey right now'"));
    expect(source, contains('is in a Journey with someone else'));
  });
}
