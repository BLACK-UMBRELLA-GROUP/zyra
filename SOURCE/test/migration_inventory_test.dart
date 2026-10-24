import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'support/oa198_historical_inventory.dart';

void main() {
  test(
    'active migrations retain unique versions beyond the historical frontier',
    () {
      final files = Directory('supabase/migrations')
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                RegExp(r'^\d{14}_.+\.sql$').hasMatch(f.uri.pathSegments.last),
          )
          .toList();
      final versions = files
          .map((f) => f.uri.pathSegments.last.substring(0, 14))
          .toList();
      expect(versions.toSet(), hasLength(versions.length));
      expect(oa198HistoricalInventory(files), hasLength(207));
      expect(versions.any((v) => v.compareTo('20260910195642') > 0), isTrue);
    },
  );
}
