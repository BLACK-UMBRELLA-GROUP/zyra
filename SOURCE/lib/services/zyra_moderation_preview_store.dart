// Phase A moderation queue fixture.
//
// This store is deliberately memory-only and developer-only. A local queue is
// not an operational safety system; Phase C binds the same UI contract to
// server-owned report/photo-moderation rows after Vision enablement.

import 'package:flutter/foundation.dart';

import '../models/seeker_profile.dart';
import '../models/zyra_moderation_review.dart';

class ZyraModerationPreviewStore extends ChangeNotifier {
  ZyraModerationPreviewStore._();

  static final instance = ZyraModerationPreviewStore._();

  final List<ZyraModerationReviewItem> _items = [];

  List<ZyraModerationReviewItem> get items => List.unmodifiable(_items);

  void ensureDemoItems() {
    if (_items.isNotEmpty) return;
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      final profile = mockProfiles[i];
      _items.add(
        ZyraModerationReviewItem(
          id: 'moderation-demo-$i',
          profileId: profile.id,
          firstName: profile.firstName,
          photoUrl: profile.photos.first,
          contentType: ZyraReportedContentType.photo,
          reason: i == 0
              ? 'Member report · inappropriate content'
              : 'Vision preview · hold for review',
          status: ZyraModerationReviewStatus.values[i],
          createdAt: now.subtract(Duration(minutes: i * 18)),
        ),
      );
    }
    notifyListeners();
  }

  void flag({
    required String profileId,
    required String firstName,
    required String photoUrl,
    required ZyraReportedContentType contentType,
    required String reason,
  }) {
    _items.insert(
      0,
      ZyraModerationReviewItem(
        id: 'moderation-local-${DateTime.now().microsecondsSinceEpoch}',
        profileId: profileId,
        firstName: firstName,
        photoUrl: photoUrl,
        contentType: contentType,
        reason: reason,
        status: ZyraModerationReviewStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void decide(String id, ZyraModerationReviewStatus status) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(status: status);
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
