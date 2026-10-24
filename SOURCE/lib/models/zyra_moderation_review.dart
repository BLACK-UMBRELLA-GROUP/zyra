enum ZyraReportedContentType { profile, photo }

enum ZyraModerationReviewStatus { pending, approved, rejected }

class ZyraModerationReviewItem {
  final String id;
  final String profileId;
  final String firstName;
  final String photoUrl;
  final ZyraReportedContentType contentType;
  final String reason;
  final ZyraModerationReviewStatus status;
  final DateTime createdAt;

  const ZyraModerationReviewItem({
    required this.id,
    required this.profileId,
    required this.firstName,
    required this.photoUrl,
    required this.contentType,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  ZyraModerationReviewItem copyWith({ZyraModerationReviewStatus? status}) =>
      ZyraModerationReviewItem(
        id: id,
        profileId: profileId,
        firstName: firstName,
        photoUrl: photoUrl,
        contentType: contentType,
        reason: reason,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
