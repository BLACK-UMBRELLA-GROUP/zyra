import 'dart:convert';

import 'package:flutter/services.dart';

/// The sample profile pictures are simple placeholder images made for this project; they show no real people. Earlier versions in the Git history used photos whose source was not recorded.
/// Never reads a member photo, signed URL, image cache or remote service.
/// Shared ZyraProfileImage already renders data URLs locally, so these photos
/// can be used in its original Browse, card and avatar presentation unchanged.
class ZyraOneJourneySamplePhotos {
  ZyraOneJourneySamplePhotos._(this.sets, this.seekerPhoto, this.guardianPhoto);

  final List<List<String>> sets;
  final String seekerPhoto;
  final String guardianPhoto;

  static const seeds = <List<String>>[
    ['zyra1a', 'zyra1b', 'zyra1c'],
    ['zyra2a', 'zyra2b'],
    ['zyra3a', 'zyra3b', 'zyra3c'],
    ['zyra4a'],
    ['zyra5a', 'zyra5b'],
    ['zyra6a'],
    ['zyra7a'],
    ['zyra8a'],
  ];

  static Future<ZyraOneJourneySamplePhotos> load({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final loaded = <List<String>>[];
    for (final group in seeds) {
      final photos = <String>[];
      for (final seed in group) {
        final data = await source.load(
          'assets/dev/one_journey_photos/$seed.jpg',
        );
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        photos.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }
      loaded.add(photos);
    }
    Future<String> avatar(String name) async {
      final data = await source.load('assets/dev/one_journey_photos/$name.jpg');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    return ZyraOneJourneySamplePhotos._(
      List<List<String>>.unmodifiable([
        for (final group in loaded) List<String>.unmodifiable(group),
      ]),
      await avatar('seeker_self'),
      await avatar('guardian_self'),
    );
  }

  List<String> forIndex(int index) => sets[index % sets.length];
}
