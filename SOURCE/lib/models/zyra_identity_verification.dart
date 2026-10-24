/// Coarse, ZYRA-owned identity-verification state.
///
/// These are the only provider outcomes the Flutter client may receive. Raw
/// document data, selfie data, face-match scores, duplicate-hit identities
/// and provider reason strings never belong in this model.
enum ZyraIdentityVerificationResult {
  pending('pending'),
  verified('verified'),
  retryRequired('retry_required'),
  reviewRequired('review_required'),
  failed('failed'),
  expired('expired'),
  cancelled('cancelled');

  final String storageValue;
  const ZyraIdentityVerificationResult(this.storageValue);

  static ZyraIdentityVerificationResult fromStorage(Object? value) =>
      values.firstWhere(
        (result) => result.storageValue == value,
        orElse: () => ZyraIdentityVerificationResult.retryRequired,
      );
}

/// The duplicate signal is deliberately ternary.
///
/// `notEvaluated` must never be collapsed into `clear`: DR-ZYRA-221 allows a
/// verified member into the app, but an Active Journey additionally requires
/// the duplicate check to have resolved clear.
enum ZyraDuplicateReviewState { notEvaluated, clear, reviewRequired }

class ZyraIdentityVerificationState {
  final ZyraIdentityVerificationResult result;
  final ZyraDuplicateReviewState duplicateReview;
  final bool consentGranted;
  final String consentVersion;
  final DateTime consentRecordedAt;
  final DateTime updatedAt;
  final DateTime? decidedAt;

  const ZyraIdentityVerificationState({
    required this.result,
    required this.duplicateReview,
    required this.consentGranted,
    required this.consentVersion,
    required this.consentRecordedAt,
    required this.updatedAt,
    this.decidedAt,
  });

  /// DR-ZYRA-221: the app shell opens only on the canonical verified result.
  bool get allowsApp => result == ZyraIdentityVerificationResult.verified;

  /// Active Journey is the stricter gate: verified plus duplicate-clear.
  bool get allowsActiveJourney =>
      allowsApp && duplicateReview == ZyraDuplicateReviewState.clear;

  factory ZyraIdentityVerificationState.fromJson(Map<String, dynamic> json) {
    final duplicate = json['duplicate_review_required'];
    return ZyraIdentityVerificationState(
      result: ZyraIdentityVerificationResult.fromStorage(json['result']),
      duplicateReview: duplicate == true
          ? ZyraDuplicateReviewState.reviewRequired
          : duplicate == false
          ? ZyraDuplicateReviewState.clear
          : ZyraDuplicateReviewState.notEvaluated,
      consentGranted: json['consent_granted'] == true,
      consentVersion: json['consent_version'] as String? ?? '',
      consentRecordedAt: _date(json['consent_recorded_at']),
      updatedAt: _date(json['updated_at']),
      decidedAt: _nullableDate(json['decided_at']),
    );
  }

  /// Parses the caller-scoped RPC envelope without widening the client model.
  /// A malformed non-null response is a protocol error, never an implied
  /// verification grant.
  static ZyraIdentityVerificationState? fromRpc(Object? raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return ZyraIdentityVerificationState.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return ZyraIdentityVerificationState.fromJson(
        Map<String, dynamic>.from(raw.first as Map),
      );
    }
    throw StateError('Unexpected identity-verification state shape.');
  }

  static DateTime _date(Object? value) =>
      _nullableDate(value) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static DateTime? _nullableDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  ZyraIdentityVerificationState copyWith({
    ZyraIdentityVerificationResult? result,
    ZyraDuplicateReviewState? duplicateReview,
    bool? consentGranted,
  }) => ZyraIdentityVerificationState(
    result: result ?? this.result,
    duplicateReview: duplicateReview ?? this.duplicateReview,
    consentGranted: consentGranted ?? this.consentGranted,
    consentVersion: consentVersion,
    consentRecordedAt: consentRecordedAt,
    updatedAt: DateTime.now().toUtc(),
    decidedAt: result == ZyraIdentityVerificationResult.verified
        ? DateTime.now().toUtc()
        : decidedAt,
  );
}
