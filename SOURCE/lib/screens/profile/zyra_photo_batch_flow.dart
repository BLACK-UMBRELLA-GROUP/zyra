import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/zyra_photo_service.dart';
import 'photo_crop_review_screen.dart';

enum ZyraPhotoBatchOutcome { added, cancelled, error }

class ZyraPhotoBatchResult {
  const ZyraPhotoBatchResult._(this.outcome, this.urls, this.failureKind);

  const ZyraPhotoBatchResult.added(List<String> urls)
    : this._(ZyraPhotoBatchOutcome.added, urls, null);
  const ZyraPhotoBatchResult.cancelled()
    : this._(ZyraPhotoBatchOutcome.cancelled, const [], null);
  const ZyraPhotoBatchResult.error([
    ZyraPhotoFailureKind kind = ZyraPhotoFailureKind.unknown,
  ]) : this._(ZyraPhotoBatchOutcome.error, const [], kind);

  final ZyraPhotoBatchOutcome outcome;
  final List<String> urls;
  final ZyraPhotoFailureKind? failureKind;

  String get memberErrorMessage {
    final kind = failureKind ?? ZyraPhotoFailureKind.unknown;
    return '${kind.memberMessage} Reference: ${kind.referenceCode}.';
  }
}

typedef ZyraPhotoBatchRunner =
    Future<ZyraPhotoBatchResult> Function(
      BuildContext context,
      int remaining,
      ValueChanged<String?> onProgress,
    );

/// Runs the whole choose-many → crop individually → preview → save sequence.
/// Uploading starts only after the member has approved every crop.
Future<ZyraPhotoBatchResult> runZyraPhotoBatchFlow(
  BuildContext context, {
  required int remaining,
  required bool localPreview,
  required ValueChanged<String?> onProgress,
  bool Function()? canProceed,
  Listenable? canProceedChanges,
  bool preview = false,
  String? previewGender,
  ZyraPhotoSelectionResult? preparedSelection,
}) async {
  bool current() {
    if (!context.mounted) return false;
    try {
      return canProceed?.call() ?? !preview;
    } catch (_) {
      return false;
    }
  }

  bool parentCurrent() =>
      current() &&
      (!(preview || canProceed != null) ||
          (ModalRoute.of(context)?.isCurrent ?? true));
  if ((preview && !localPreview) || !parentCurrent()) {
    return const ZyraPhotoBatchResult.cancelled();
  }
  // A same-owner local import may have survived a fresh authorization UI
  // handoff. It still needs this NEW route's current guard and crop approval.
  if (preparedSelection != null && (!preview || !localPreview)) {
    return const ZyraPhotoBatchResult.cancelled();
  }
  final selection =
      preparedSelection ??
      await ZyraPhotoService.pickManyForReview(
        limit: remaining,
        onProgress: (prepared, total) {
          if (current()) onProgress('Preparing $prepared of $total');
        },
      );
  if (selection.photos.length > remaining ||
      (selection.outcome == ZyraPhotoSelectionOutcome.selected &&
          selection.photos.isEmpty)) {
    return const ZyraPhotoBatchResult.error(ZyraPhotoFailureKind.processing);
  }
  switch (selection.outcome) {
    case ZyraPhotoSelectionOutcome.cancelled:
      if (current()) onProgress(null);
      return const ZyraPhotoBatchResult.cancelled();
    case ZyraPhotoSelectionOutcome.error:
      if (current()) onProgress(null);
      return const ZyraPhotoBatchResult.error(ZyraPhotoFailureKind.processing);
    case ZyraPhotoSelectionOutcome.selected:
      break;
  }

  if (!parentCurrent()) {
    return const ZyraPhotoBatchResult.cancelled();
  }
  onProgress(null);
  // The caller's progress callback can also remove the owning route.
  if (!context.mounted || !parentCurrent()) {
    return const ZyraPhotoBatchResult.cancelled();
  }
  final reviewed = await Navigator.of(context).push<List<Uint8List>>(
    MaterialPageRoute(
      builder: (_) => PhotoCropReviewScreen(
        photos: selection.photos,
        preview: preview,
        gender: previewGender,
        canAct: preview || canProceed != null ? current : null,
        canActChanges: canProceedChanges,
      ),
    ),
  );
  if (reviewed == null || reviewed.isEmpty || !parentCurrent()) {
    return const ZyraPhotoBatchResult.cancelled();
  }

  final saved = <String>[];
  for (var i = 0; i < reviewed.length; i++) {
    if (!current()) return const ZyraPhotoBatchResult.cancelled();
    onProgress(
      localPreview
          ? 'Adding ${i + 1} of ${reviewed.length}'
          : 'Uploading ${i + 1} of ${reviewed.length}',
    );
    final result = await ZyraPhotoService.saveReviewedPhoto(
      reviewed[i],
      localPreview: localPreview,
      canProceed: canProceed,
    );
    if (!current()) return const ZyraPhotoBatchResult.cancelled();
    if (result.outcome != ZyraPhotoOutcome.uploaded || result.url == null) {
      if (!localPreview) await ZyraPhotoService.discardNewUploads(saved);
      onProgress(null);
      return ZyraPhotoBatchResult.error(
        result.failureKind ?? ZyraPhotoFailureKind.unknown,
      );
    }
    saved.add(result.url!);
  }
  onProgress(null);
  return ZyraPhotoBatchResult.added(saved);
}
