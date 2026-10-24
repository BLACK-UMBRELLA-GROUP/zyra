import 'dart:io';

/// The signed OA198 evidence described this frontier, not all future work.
/// Keep its exact 207-file digest check without rejecting later migrations.
List<File> oa198HistoricalInventory(Iterable<File> files) =>
    files.where((file) {
      final name = file.path.split(Platform.pathSeparator).last;
      return RegExp(r'^\d{14}_.+\.sql$').hasMatch(name) &&
          name.substring(0, 14).compareTo('20260910195642') <= 0;
    }).toList();
