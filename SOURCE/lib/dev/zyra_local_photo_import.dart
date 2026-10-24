// A user-initiated local import can outlive a disposable Founder UI epoch.
// This buffer is not authority, navigation, persistence or a member upload.
import 'dart:async';

import '../services/zyra_photo_service.dart';

class ZyraLocalPhotoImportRequest {
  ZyraLocalPhotoImportRequest._(
    List<String> photos,
    this.alignmentX,
    this.alignmentY,
  ) : startingPhotos = List.unmodifiable(photos),
      remaining = 5 - photos.length;

  final int remaining;
  final List<String> startingPhotos;
  final double alignmentX, alignmentY;
  final _selection = Completer<ZyraPhotoSelectionResult>();
  Object? _consumer;
  int? _admittedEpoch;

  Future<ZyraPhotoSelectionResult> get selection => _selection.future;
}

/// Owned above the revocable preview tree. Only a freshly admitted editor
/// may claim/finish an import; losing proof never keeps the old editor alive.
/// The owner must synchronously cancel on identity, route, role or session
/// departure and on a failed authorization handoff.
class ZyraLocalPhotoImport {
  ZyraLocalPhotoImport({
    required bool Function() canRetain,
    required bool Function() canAdmit,
    required int Function() admissionEpoch,
    Future<ZyraPhotoSelectionResult> Function(int remaining)? pick,
  }) : // Public argument names keep the authority callbacks private.
       // ignore: prefer_initializing_formals
       _canRetain = canRetain,
       // ignore: prefer_initializing_formals
       _canAdmit = canAdmit,
       // ignore: prefer_initializing_formals
       _admissionEpoch = admissionEpoch,
       _pick =
           pick ??
           ((remaining) =>
               ZyraPhotoService.pickManyForReview(limit: remaining));

  final bool Function() _canRetain;
  final bool Function() _canAdmit;
  final int Function() _admissionEpoch;
  final Future<ZyraPhotoSelectionResult> Function(int) _pick;
  ZyraLocalPhotoImportRequest? _pending;
  bool _disposed = false;

  bool _allowed(bool Function() check) {
    if (_disposed) return false;
    try {
      return check();
    } catch (_) {
      return false;
    }
  }

  ZyraLocalPhotoImportRequest? get pending {
    synchronize();
    return _pending;
  }

  void synchronize() {
    if (!_allowed(_canRetain)) cancel();
  }

  ZyraLocalPhotoImportRequest? begin({
    required List<String> photos,
    double alignmentX = 0,
    double alignmentY = 0,
  }) {
    synchronize();
    if (!_allowed(_canRetain) ||
        !_allowed(_canAdmit) ||
        _pending != null ||
        photos.length >= 5 ||
        photos.any(
          (photo) =>
              !photo.startsWith('data:image/jpeg;base64,') ||
              photo.length <= 'data:image/jpeg;base64,'.length,
        ) ||
        !alignmentX.isFinite ||
        !alignmentY.isFinite ||
        alignmentX.abs() > 1 ||
        alignmentY.abs() > 1 ||
        _epoch() == null) {
      return null;
    }
    final request = ZyraLocalPhotoImportRequest._(
      photos,
      alignmentX,
      alignmentY,
    );
    _pending = request;
    unawaited(_prepare(request));
    return request;
  }

  Future<void> _prepare(ZyraLocalPhotoImportRequest request) async {
    ZyraPhotoSelectionResult result;
    try {
      result = await _pick(request.remaining);
    } catch (_) {
      result = const ZyraPhotoSelectionResult.error();
    }
    synchronize();
    if (!identical(_pending, request)) return;
    // No raw picker paths or EXIF enter this buffer: the production picker
    // returns only newly encoded, verified JPEGs. Still bound its count.
    if (result.photos.length > request.remaining) {
      result = const ZyraPhotoSelectionResult.error();
    }
    if (!request._selection.isCompleted) request._selection.complete(result);
  }

  bool claim(ZyraLocalPhotoImportRequest request, Object consumer) {
    synchronize();
    final epoch = _epoch();
    if (!identical(_pending, request) ||
        !_allowed(_canAdmit) ||
        epoch == null) {
      return false;
    }
    if (request._consumer != null &&
        !identical(request._consumer, consumer) &&
        request._admittedEpoch == epoch) {
      return false;
    }
    request._consumer = consumer;
    request._admittedEpoch = epoch;
    return true;
  }

  int? _epoch() {
    if (_disposed) return null;
    try {
      final value = _admissionEpoch();
      return value >= 0 ? value : null;
    } catch (_) {
      cancel();
      return null;
    }
  }

  bool isCurrent(ZyraLocalPhotoImportRequest request, Object consumer) {
    synchronize();
    final epoch = _epoch();
    return identical(_pending, request) &&
        identical(request._consumer, consumer) &&
        _allowed(_canAdmit) &&
        epoch != null &&
        request._admittedEpoch == epoch;
  }

  void finish(ZyraLocalPhotoImportRequest request, Object consumer) {
    if (isCurrent(request, consumer)) cancel();
  }

  void cancel() {
    final request = _pending;
    _pending = null;
    if (request == null) return;
    request._consumer = null;
    request._admittedEpoch = null;
    if (!request._selection.isCompleted) {
      request._selection.complete(const ZyraPhotoSelectionResult.cancelled());
    }
  }

  void dispose() {
    cancel();
    _disposed = true;
  }
}
