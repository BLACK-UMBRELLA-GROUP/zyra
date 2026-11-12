// Profile photo upload — OA-104. Wraps picking a photo from the device
// library and uploading it to the `profile-photos` Storage bucket
// (own-folder-only write per RLS: `{auth.uid()}/{filename}`), then
// syncing the resulting URLs into the `profile_photos` table so they
// survive beyond this session.
//
// PRIVATE BUCKET (2026-07-19, Fable review): the bucket was public,
// which contradicted IMAGE_HANDLING_CURRENT_VERSION_V1.md ("Originals
// never publicly accessible") — a public bucket serves objects by URL
// with no auth check at all. It is now private. The app requests
// signed display URLs that expire after one hour. Storage RLS checks
// ownership or the viewer's access to the saved profile photo.
//
// Photo REMOVAL in the Chapter 2 picker only removes the URL from the
// in-memory list, not the underlying Storage object or table row — a
// deliberate v1 simplification (orphaned files are harmless in a
// preview build) rather than wiring delete permissions and re-ordering
// logic today. Worth cleaning up before a real launch.

import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FileOptions, StorageException;
import '../main.dart';
import '../models/zyra_initial_signup_draft.dart';
import 'zyra_account_state.dart';
import 'zyra_auth.dart';
import 'zyra_internal_preview_client.dart';
import 'zyra_profile_photo_processor.dart';

enum ZyraPhotoOutcome { uploaded, cancelled, error }

/// Stable, privacy-safe failure categories for profile-photo support.
///
/// These values never contain filenames, Storage paths, member ids, exception
/// messages or photo metadata. They let the UI give useful recovery advice and
/// let an attached debug console distinguish an expired session from RLS,
/// network, processing and Storage failures without exposing private data.
enum ZyraPhotoFailureKind {
  authentication,
  accessDenied,
  connection,
  processing,
  storage,
  unknown,
}

extension ZyraPhotoFailureCopy on ZyraPhotoFailureKind {
  String get referenceCode => switch (this) {
    ZyraPhotoFailureKind.authentication => 'ZY-PH-01',
    ZyraPhotoFailureKind.accessDenied => 'ZY-PH-02',
    ZyraPhotoFailureKind.connection => 'ZY-PH-03',
    ZyraPhotoFailureKind.processing => 'ZY-PH-04',
    ZyraPhotoFailureKind.storage => 'ZY-PH-05',
    ZyraPhotoFailureKind.unknown => 'ZY-PH-06',
  };

  String get memberMessage => switch (this) {
    ZyraPhotoFailureKind.authentication =>
      'Your session has ended. Sign in again, then retry.',
    ZyraPhotoFailureKind.accessDenied =>
      "Your account couldn't save photos. Please contact ZYRA Support.",
    ZyraPhotoFailureKind.connection =>
      'Check your connection, then try adding the photos again.',
    ZyraPhotoFailureKind.processing =>
      "This photo couldn't be added. Try another photo, or save it to your phone first.",
    ZyraPhotoFailureKind.storage =>
      'Photo storage is temporarily unavailable. Please try again shortly.',
    ZyraPhotoFailureKind.unknown =>
      "Those photos couldn't be added. Please try again.",
  };
}

/// Allowlisted diagnostics. Raw platform messages, details, paths and
/// arbitrary exception reasons must never reach the console or the UI.
enum ZyraPhotoPreparationFailure {
  libraryAccess,
  pickerRead,
  pickerUnsupported,
  pickerUnavailable,
  sourceRead,
  emptySource,
  unreadableSource,
  verificationFailed,
  nativeArguments,
  nativeDecode,
  nativeEncode,
  nativeUnavailable,
  nativeEmpty,
  unknown;

  String get memberMessage => switch (this) {
    libraryAccess =>
      'Allow access to photos in Settings, then try adding the photo again.',
    pickerUnavailable =>
      'Open your photo library again and reselect the photo.',
    nativeArguments || nativeUnavailable || verificationFailed =>
      "This photo couldn't be added. Try again or choose another photo.",
    _ => ZyraPhotoFailureKind.processing.memberMessage,
  };
}

enum _PhotoPreparationStage { picker, read, decode, native, verify, finalise }

class ZyraPhotoResult {
  final ZyraPhotoOutcome outcome;
  final String? url;
  final ZyraPhotoFailureKind? failureKind;
  final ZyraPhotoPreparationFailure? preparationFailure;
  const ZyraPhotoResult._(
    this.outcome,
    this.url,
    this.failureKind, [
    this.preparationFailure,
  ]);

  const ZyraPhotoResult.uploaded(String url)
    : this._(ZyraPhotoOutcome.uploaded, url, null);
  const ZyraPhotoResult.cancelled()
    : this._(ZyraPhotoOutcome.cancelled, null, null);
  const ZyraPhotoResult.error([
    ZyraPhotoFailureKind kind = ZyraPhotoFailureKind.unknown,
    ZyraPhotoPreparationFailure? preparationFailure,
  ]) : this._(ZyraPhotoOutcome.error, null, kind, preparationFailure);
}

enum ZyraPhotoSelectionOutcome { selected, cancelled, error }

class ZyraPhotoSelectionResult {
  const ZyraPhotoSelectionResult._(this.outcome, this.photos, [this.failure]);

  const ZyraPhotoSelectionResult.selected(List<Uint8List> photos)
    : this._(ZyraPhotoSelectionOutcome.selected, photos);
  const ZyraPhotoSelectionResult.cancelled()
    : this._(ZyraPhotoSelectionOutcome.cancelled, const []);
  const ZyraPhotoSelectionResult.error([
    ZyraPhotoPreparationFailure failure = ZyraPhotoPreparationFailure.unknown,
  ]) : this._(ZyraPhotoSelectionOutcome.error, const [], failure);

  final ZyraPhotoSelectionOutcome outcome;
  final List<Uint8List> photos;
  final ZyraPhotoPreparationFailure? failure;
}

class ZyraPhotoService {
  ZyraPhotoService._();

  static const String _bucket = 'profile-photos';
  static const MethodChannel _iosPhotoChannel = MethodChannel(
    'app.zyraconnect.zyra/profile_photo',
  );

  /// Profile photo capabilities issued by the app last at most one hour.
  static const int _signedUrlExpirySeconds = 60 * 60;

  static Future<XFile?> _pickProfilePhoto() => ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: ZyraProfilePhotoProcessor.maxDimension.toDouble(),
    maxHeight: ZyraProfilePhotoProcessor.maxDimension.toDouble(),
    imageQuality: ZyraProfilePhotoProcessor.jpegQuality,
    // Profile photos do not need original EXIF metadata. On iOS this also
    // lets PHPicker provide the chosen image without broad library access.
    requestFullMetadata: false,
  );

  @visibleForTesting
  static ZyraPhotoPreparationFailure preparationFailureFor(Object error) =>
      switch (error) {
        ZyraProfilePhotoProcessingException(:final reason) => switch (reason) {
          'empty source' => ZyraPhotoPreparationFailure.emptySource,
          'unsupported or unreadable source' =>
            ZyraPhotoPreparationFailure.unreadableSource,
          'sanitised output verification failed' =>
            ZyraPhotoPreparationFailure.verificationFailed,
          _ => ZyraPhotoPreparationFailure.unknown,
        },
        PlatformException(:final code) => switch (code) {
          'photo_access_denied' || 'photo_access_restricted' =>
            ZyraPhotoPreparationFailure.libraryAccess,
          'invalid_image' ||
          'create_error' => ZyraPhotoPreparationFailure.pickerRead,
          'invalid_source' => ZyraPhotoPreparationFailure.pickerUnsupported,
          'multiple_request' => ZyraPhotoPreparationFailure.pickerUnavailable,
          'photo_bad_arguments' => ZyraPhotoPreparationFailure.nativeArguments,
          'photo_decode_failed' => ZyraPhotoPreparationFailure.nativeDecode,
          'photo_encode_failed' => ZyraPhotoPreparationFailure.nativeEncode,
          _ => ZyraPhotoPreparationFailure.unknown,
        },
        MissingPluginException() =>
          ZyraPhotoPreparationFailure.nativeUnavailable,
        _ => ZyraPhotoPreparationFailure.unknown,
      };

  static void _logPreparationFailure(
    _PhotoPreparationStage stage,
    ZyraPhotoPreparationFailure failure,
  ) => debugPrint(
    'ZYRA: profile photo [ZY-PH-04; stage=${stage.name}; reason=${failure.name}].',
  );

  static void _logNativeFallback(
    _PhotoPreparationStage stage,
    ZyraPhotoPreparationFailure failure,
  ) => debugPrint(
    'ZYRA: profile photo trying iOS normalisation '
    '[stage=${stage.name}; reason=${failure.name}].',
  );

  static Never _preparationFailed(
    _PhotoPreparationStage stage,
    ZyraPhotoPreparationFailure failure,
  ) {
    _logPreparationFailure(stage, failure);
    throw failure;
  }

  static Future<Uint8List> _readAndProcess(
    XFile picked, {
    bool forReview = false,
  }) async {
    final process = forReview
        ? ZyraProfilePhotoProcessor.processForReview
        : ZyraProfilePhotoProcessor.process;
    Uint8List? sourceBytes;
    try {
      sourceBytes = await picked.readAsBytes();
    } catch (_) {
      const failure = ZyraPhotoPreparationFailure.sourceRead;
      if (!Platform.isIOS) {
        _preparationFailed(_PhotoPreparationStage.read, failure);
      }
      _logNativeFallback(_PhotoPreparationStage.read, failure);
    }

    if (sourceBytes != null) {
      try {
        return await process(sourceBytes);
      } catch (error) {
        final failure = preparationFailureFor(error);
        if (!Platform.isIOS ||
            failure == ZyraPhotoPreparationFailure.emptySource) {
          _preparationFailed(_PhotoPreparationStage.decode, failure);
        }
        _logNativeFallback(_PhotoPreparationStage.decode, failure);
      }
    }

    // UIKit can decode HEIF and other representations Dart cannot. Supply the
    // bytes if the picker's temporary file was readable. The verified JPEG
    // from the privacy processor is the only result that leaves this method.
    final Uint8List? normalised;
    try {
      normalised = await _iosPhotoChannel
          .invokeMethod<Uint8List>('normaliseProfilePhoto', {
            'path': picked.path,
            'maxDimension': forReview
                ? ZyraProfilePhotoProcessor.reviewMaxDimension
                : ZyraProfilePhotoProcessor.maxDimension,
            'quality': ZyraProfilePhotoProcessor.jpegQuality,
            'data': ?sourceBytes,
          });
    } catch (error) {
      _preparationFailed(
        _PhotoPreparationStage.native,
        preparationFailureFor(error),
      );
    }
    if (normalised == null || normalised.isEmpty) {
      _preparationFailed(
        _PhotoPreparationStage.native,
        ZyraPhotoPreparationFailure.nativeEmpty,
      );
    }
    try {
      return await process(normalised);
    } catch (error) {
      _preparationFailed(
        _PhotoPreparationStage.verify,
        preparationFailureFor(error),
      );
    }
  }

  /// Selects up to [limit] photos in one native picker pass and normalises
  /// them before the crop UI receives them. Nothing is uploaded here: the
  /// member can cancel anywhere in the review queue without changing their
  /// profile or leaving partial Storage objects behind.
  static Future<ZyraPhotoSelectionResult> pickManyForReview({
    required int limit,
    void Function(int prepared, int total)? onProgress,
  }) async {
    if (limit < 1) return const ZyraPhotoSelectionResult.cancelled();
    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(
        maxWidth: ZyraProfilePhotoProcessor.reviewMaxDimension.toDouble(),
        maxHeight: ZyraProfilePhotoProcessor.reviewMaxDimension.toDouble(),
        imageQuality: ZyraProfilePhotoProcessor.jpegQuality,
        limit: limit,
        requestFullMetadata: false,
      );
    } catch (error) {
      final failure = preparationFailureFor(error);
      _logPreparationFailure(_PhotoPreparationStage.picker, failure);
      return ZyraPhotoSelectionResult.error(failure);
    }
    if (picked.isEmpty) return const ZyraPhotoSelectionResult.cancelled();

    final bounded = picked.take(limit).toList(growable: false);
    final prepared = <Uint8List>[];
    try {
      onProgress?.call(0, bounded.length);
      for (var i = 0; i < bounded.length; i++) {
        prepared.add(await _readAndProcess(bounded[i], forReview: true));
        onProgress?.call(i + 1, bounded.length);
      }
    } on ZyraPhotoPreparationFailure catch (failure) {
      return ZyraPhotoSelectionResult.error(failure);
    }
    return ZyraPhotoSelectionResult.selected(prepared);
  }

  /// Selects a real device photo for Developer Preview without crossing the
  /// preview's no-live-data boundary. The processed, metadata-free JPEG stays
  /// in memory for this preview session and never reaches Storage/Postgres.
  static Future<ZyraPhotoResult> pickForLocalPreview() async {
    try {
      final picked = await _pickProfilePhoto();
      if (picked == null) return const ZyraPhotoResult.cancelled();
      final bytes = await _readAndProcess(picked);
      return ZyraPhotoResult.uploaded(
        'data:image/jpeg;base64,${base64Encode(bytes)}',
      );
    } on ZyraPhotoPreparationFailure catch (failure) {
      return ZyraPhotoResult.error(ZyraPhotoFailureKind.processing, failure);
    } catch (error) {
      final failure = preparationFailureFor(error);
      _logPreparationFailure(_PhotoPreparationStage.picker, failure);
      return ZyraPhotoResult.error(ZyraPhotoFailureKind.processing, failure);
    }
  }

  /// Finalises bytes returned by the crop/review screen. Cropping is followed
  /// by the privacy processor again so the final uploaded artifact — not only
  /// the original picker output — is bounded, orientation-safe and metadata
  /// free.
  static Future<ZyraPhotoResult> saveReviewedPhoto(
    Uint8List croppedBytes, {
    required bool localPreview,
    bool Function()? canProceed,
  }) async {
    if (canProceed?.call() == false) return const ZyraPhotoResult.cancelled();
    try {
      final bytes = await ZyraProfilePhotoProcessor.process(croppedBytes);
      if (canProceed?.call() == false) return const ZyraPhotoResult.cancelled();
      if (localPreview) {
        return ZyraPhotoResult.uploaded(
          'data:image/jpeg;base64,${base64Encode(bytes)}',
        );
      }
      return _uploadProcessed(bytes, canProceed: canProceed);
    } catch (error) {
      final failure = preparationFailureFor(error);
      _logPreparationFailure(_PhotoPreparationStage.finalise, failure);
      return ZyraPhotoResult.error(ZyraPhotoFailureKind.processing, failure);
    }
  }

  static Future<ZyraPhotoResult> _uploadProcessed(
    Uint8List bytes, {
    bool Function()? canProceed,
  }) async {
    if (canProceed?.call() == false) return const ZyraPhotoResult.cancelled();
    _synchronizeOwner();
    final user = ZyraAuth.currentUser;
    if (user == null) {
      return const ZyraPhotoResult.error(ZyraPhotoFailureKind.authentication);
    }
    final epoch = _epoch;
    try {
      final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await supabase.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
      if (!_isCurrent(user.id, epoch) || canProceed?.call() == false) {
        return const ZyraPhotoResult.cancelled();
      }
      final signedUrl = await supabase.storage
          .from(_bucket)
          .createSignedUrl(path, _signedUrlExpirySeconds);
      if (!_isCurrent(user.id, epoch) || canProceed?.call() == false) {
        return const ZyraPhotoResult.cancelled();
      }
      _urlMemo[path] = (url: signedUrl, at: DateTime.now());
      return ZyraPhotoResult.uploaded(signedUrl);
    } catch (error) {
      final kind = classifyFailure(error);
      final storageStatus = error is StorageException
          ? '; status=${error.statusCode ?? "unknown"}'
          : '';
      debugPrint(
        'ZYRA: processed profile photo upload failed '
        '[${kind.referenceCode}; ${error.runtimeType}$storageStatus]. '
        'Nothing was saved.',
      );
      return ZyraPhotoResult.error(kind);
    }
  }

  /// Convert only this backend's signed private JPEG URL into an owner-bound,
  /// tokenless reference suitable for protected same-device signup recovery.
  static String? signupStoragePathFor(
    String url, {
    required String expectedUserId,
  }) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      return null;
    }
    final base = Uri.parse(supabase.storage.from(_bucket).url);
    final prefix = '${base.path}/object/sign/$_bucket/';
    if (uri.origin != base.origin || !uri.path.startsWith(prefix)) return null;
    final path = uri.path.substring(prefix.length);
    return ZyraInitialSignupDraft.isPrivatePhotoPath(
          path,
          expectedUserId: expectedUserId,
        )
        ? path
        : null;
  }

  static bool _signupOwnerCurrent(String userId, int generation) {
    try {
      return !ZyraInternalPreviewClient.isActive &&
          ZyraAuth.currentUser?.id == userId &&
          ZyraAccountState.isCurrent(userId, generation);
    } catch (_) {
      return false;
    }
  }

  /// Fresh capability stays in memory only. A missing/expired object or stale
  /// account cannot be mistaken for a usable saved first photo.
  static Future<String?> signupPhotoUrl(
    String path, {
    required String expectedUserId,
    required int expectedGeneration,
  }) async {
    if (!_signupOwnerCurrent(expectedUserId, expectedGeneration) ||
        !ZyraInitialSignupDraft.isPrivatePhotoPath(
          path,
          expectedUserId: expectedUserId,
        )) {
      return null;
    }
    try {
      final session = supabase.auth.currentSession;
      if (session?.user.id != expectedUserId) return null;
      final url = await supabase.storage
          .from(_bucket)
          .setHeader('Authorization', 'Bearer ${session!.accessToken}')
          .createSignedUrl(path, _signedUrlExpirySeconds);
      if (!_signupOwnerCurrent(expectedUserId, expectedGeneration) ||
          signupStoragePathFor(url, expectedUserId: expectedUserId) != path) {
        return null;
      }
      return url;
    } catch (_) {
      return null;
    }
  }

  /// Used only after verified profile creation. Unlike the legacy replacement
  /// sync, this never deletes or reorders photos: a retry reuses the same row,
  /// and any existing saved photos keep their primary/order. Readback and fresh
  /// signing must confirm the staged reference before signup can be erased.
  static Future<List<String>?> ensureSignupFirstPhotoConfirmed(
    String path, {
    required String expectedUserId,
    required int expectedGeneration,
  }) async {
    bool current() => _signupOwnerCurrent(expectedUserId, expectedGeneration);
    if (!current() ||
        !ZyraInitialSignupDraft.isPrivatePhotoPath(
          path,
          expectedUserId: expectedUserId,
        )) {
      return null;
    }
    final session = supabase.auth.currentSession;
    if (session?.user.id != expectedUserId) return null;
    final authorization = 'Bearer ${session!.accessToken}';
    Future<List<Map<String, dynamic>>> readRows() => supabase
        .from('profile_photos')
        .select('user_id, storage_path, display_order, is_primary')
        .eq('user_id', expectedUserId)
        .order('display_order')
        .setHeader('Authorization', authorization);
    try {
      // Confirm Storage before inserting any reference to an unavailable file.
      if (await signupPhotoUrl(
            path,
            expectedUserId: expectedUserId,
            expectedGeneration: expectedGeneration,
          ) ==
          null) {
        return null;
      }
      if (!current()) return null;
      var rows = await readRows();
      if (!current()) return null;
      bool validRows() => rows.every(
        (row) =>
            row['user_id'] == expectedUserId &&
            row['storage_path'] is String &&
            ZyraInitialSignupDraft.isPrivatePhotoPath(
              row['storage_path'] as String,
              expectedUserId: expectedUserId,
            ) &&
            row['display_order'] is int &&
            (row['display_order'] as int) >= 0 &&
            row['is_primary'] is bool,
      );
      if (!validRows()) return null;
      if (!rows.any((row) => row['storage_path'] == path)) {
        if (rows.length >= 6) return null;
        var lastOrder = -1;
        for (final row in rows) {
          final order = row['display_order'];
          if (order is! int || order < 0) return null;
          if (order > lastOrder) lastOrder = order;
        }
        await supabase
            .from('profile_photos')
            .insert({
              'user_id': expectedUserId,
              'storage_path': path,
              'is_primary': rows.isEmpty,
              'display_order': lastOrder + 1,
            })
            .setHeader('Authorization', authorization);
        if (!current()) return null;
        rows = await readRows();
        if (!current()) return null;
      }
      if (!validRows() || !rows.any((row) => row['storage_path'] == path)) {
        return null;
      }
      final urls = <String>[];
      for (final row in rows) {
        final savedPath = row['storage_path'];
        if (savedPath is! String) return null;
        final url = await signupPhotoUrl(
          savedPath,
          expectedUserId: expectedUserId,
          expectedGeneration: expectedGeneration,
        );
        if (!current() || url == null) return null;
        urls.add(url);
      }
      return urls;
    } catch (_) {
      debugPrint(
        'ZYRA: signup photo confirmation failed; setup remains pending.',
      );
      return null;
    }
  }

  /// Maps raw SDK/transport failures to a stable category without retaining
  /// or displaying their potentially sensitive free-text messages.
  static ZyraPhotoFailureKind classifyFailure(Object error) {
    if (error is SocketException || error is http.ClientException) {
      return ZyraPhotoFailureKind.connection;
    }
    if (error is StorageException) {
      final status = int.tryParse(error.statusCode ?? '');
      if (status == 401) return ZyraPhotoFailureKind.authentication;
      if (status == 403) return ZyraPhotoFailureKind.accessDenied;
      if (status == 408 || status == 429 || (status != null && status >= 500)) {
        return ZyraPhotoFailureKind.storage;
      }
      return ZyraPhotoFailureKind.storage;
    }
    if (error is ZyraProfilePhotoProcessingException) {
      return ZyraPhotoFailureKind.processing;
    }
    if (error is PlatformException && error.code.startsWith('photo_')) {
      return ZyraPhotoFailureKind.processing;
    }
    return ZyraPhotoFailureKind.unknown;
  }

  /// Loads an existing display photo back into the same safe crop pipeline.
  ///
  /// Developer Preview supplies an in-memory data URL. Signed-in accounts
  /// supply a private, short-lived signed URL. The URL itself is never logged
  /// or included in errors, and the returned bytes have already passed the
  /// profile-photo privacy processor before the crop screen receives them.
  static Future<Uint8List> prepareDisplayPhotoForReview(String photo) async {
    Uint8List sourceBytes;
    if (photo.startsWith('data:image/')) {
      final comma = photo.indexOf(',');
      if (comma < 0) {
        throw const ZyraProfilePhotoProcessingException(
          'invalid local preview photo',
        );
      }
      sourceBytes = base64Decode(photo.substring(comma + 1));
    } else {
      final uri = Uri.tryParse(photo);
      if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
        throw const ZyraProfilePhotoProcessingException(
          'invalid profile photo reference',
        );
      }
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException('profile photo download failed');
      }
      sourceBytes = response.bodyBytes;
    }
    return ZyraProfilePhotoProcessor.process(sourceBytes);
  }

  /// Rolls back only this batch's uploads before any gallery write. After a
  /// gallery write is attempted, an ambiguous acknowledgement can still mean
  /// the crop is live and its object must be retained.
  static Future<bool> discardNewUploads(
    List<String> displayUrls, {
    required bool Function() canProceed,
  }) async {
    if (displayUrls.isEmpty) return true;
    _synchronizeOwner();
    final owner = _owner;
    final epoch = _epoch;
    if (owner == null || !canProceed()) return false;

    try {
      final paths = <String>{};
      for (final url in displayUrls) {
        final path = signupStoragePathFor(url, expectedUserId: owner);
        if (path == null) return false;
        paths.add(path);
      }
      final session = supabase.auth.currentSession;
      if (session?.user.id != owner ||
          !_isCurrent(owner, epoch) ||
          !canProceed()) {
        return false;
      }
      final removed = await supabase.storage
          .from(_bucket)
          .setHeader('Authorization', 'Bearer ${session!.accessToken}')
          .remove(paths.toList(growable: false));
      if (!_isCurrent(owner, epoch) || !canProceed()) return false;
      for (final object in removed) {
        if (paths.remove(object.name)) _urlMemo.remove(object.name);
      }
      if (paths.isEmpty) return true;
      debugPrint('ZYRA: incomplete photo batch cleanup was not acknowledged.');
    } catch (_) {
      debugPrint('ZYRA: incomplete photo batch cleanup failed.');
    }
    return false;
  }

  // ── SESSION URL MEMO — DR-ZYRA-169 Phase 2, 2026-08-15 ──────────────
  //
  // Every list refresh used to re-sign every path it showed — a signing
  // round trip per fetch for URLs that live SEVEN DAYS. This memo keeps
  // the session's already-minted URLs so a refresh only signs what it
  // has never signed before.
  //
  // Keep signed URLs in memory. Anyone holding the URL can fetch the
  // photo without their own session, so never write it to disk (review
  // item N2). The disk cache stores bytes keyed by the tokenless URL
  // (zyra_image_cache.dart).
  //
  // Re-sign on next use after 55 minutes so cached URLs still have time
  // to load. Clear all entries on sign-out with the rest of the account state.
  static final Map<String, ({String url, DateTime at})> _urlMemo = {};
  static const Duration _memoMaxAge = Duration(minutes: 55);
  static String? _owner;
  static int _epoch = 0;

  static String? _currentOwner() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  static void _synchronizeOwner() {
    final owner = _currentOwner();
    if (_owner == owner) return;
    clearUrlMemoForSignOut();
    _owner = owner;
  }

  static bool _isCurrent(String? owner, int epoch) =>
      epoch == _epoch && owner == _owner && owner == _currentOwner();

  /// Sign-out hook — see the memo note above.
  static void clearUrlMemoForSignOut() {
    _epoch++;
    _owner = null;
    _urlMemo.clear();
  }

  /// Batch-signs storage paths for display. Used by Browse and Matches
  /// for other users' photos as well as the user's own. Returns an
  /// empty list on any failure — callers already treat "no photos" as
  /// a skip/fallback case, never an error.
  /// FIXED 2026-08-05 (Founder: "still on Browse page I'm not getting
  /// profiles… 50 men 50 women, I'm not seeing anything").
  ///
  /// ROOT CAUSE. Browse signs every candidate's photos in ONE batched call
  /// and then slices the results back out by position, so it requires the
  /// returned list to be exactly as long as the list it sent — if it isn't,
  /// `fetchCandidates` deliberately shows nothing rather than risk pairing
  /// the wrong photo with the wrong person.
  ///
  /// The 100 seeded test profiles reuse the same ~99 real storage objects,
  /// so a full deck asks for ~290 paths of which most are DUPLICATES.
  /// Deduplicating server-side returns fewer rows than were sent, the
  /// length check fails, and every candidate is dropped — an empty Browse
  /// with a perfectly healthy database behind it.
  ///
  /// The fix belongs here, not in the seed data: a caller asking for the
  /// same path twice should get the same URL twice. Unique paths are signed
  /// once, chunked so a large deck cannot exceed a request limit, then
  /// expanded back to the caller's exact order and length. Still
  /// all-or-nothing — a missing path returns empty rather than a
  /// misaligned list.
  static Future<List<String>> signedUrlsFor(List<String> storagePaths) async {
    if (storagePaths.isEmpty) return const [];
    _synchronizeOwner();
    final owner = _owner;
    final epoch = _epoch;
    // DELEGATES to signedUrlMap since 2026-08-15 (DR-ZYRA-169 Phase 2):
    // one signing implementation, one memo, one retry policy — this used
    // to be a second copy of the chunked signer with a harsher failure
    // mode (any chunk mismatch returned NONE, hiding a whole person over
    // one bad path — the exact 2026-08-05 failure shape, surviving here
    // after it was fixed there). Callers of THIS form sign one person's
    // own photo list per call (order preserved below), so proportional
    // results cannot misalign anyone's photos with anyone else's face.
    // This also retires the second of the two deprecated
    // createSignedUrls call sites.
    final byPath = await signedUrlMap(storagePaths);
    if (!_isCurrent(owner, epoch)) return const [];
    final out = <String>[];
    for (final p in storagePaths) {
      final url = byPath[p];
      if (url != null) out.add(url);
    }
    if (out.length != storagePaths.length) {
      debugPrint(
        'ZYRA: signedUrlsFor — resolved ${out.length} of '
        '${storagePaths.length} paths; the rest are skipped.',
      );
    }
    return out;
  }

  /// Path → signed URL, for callers signing several people's photos at once.
  ///
  /// ADDED 2026-08-05 (Founder: "still no profiles showing up… please do a
  /// deep fix"). The previous design returned a positional LIST, so Browse
  /// signed every candidate's photos in one call and sliced the results back
  /// out by index. That only works if the returned list is exactly as long
  /// as the one sent — and made the whole deck hostage to a single bad path:
  /// one unresolvable photo, and 69 healthy candidates all disappeared.
  ///
  /// Returning a map removes the coupling entirely. Callers look up each
  /// path by name, a photo that fails to sign is simply not shown, and a
  /// person is only dropped if NONE of their photos resolve. Failure is now
  /// proportional to what actually failed.
  ///
  /// Never throws and never returns null — an empty map means nothing
  /// resolved, which callers already treat as "no photos".
  static Future<Map<String, String>> signedUrlMap(
    List<String> storagePaths,
  ) async {
    if (storagePaths.isEmpty) return const {};
    _synchronizeOwner();
    final owner = _owner;
    final epoch = _epoch;
    final byPath = <String, String>{};

    // Memo first (DR-ZYRA-169 Phase 2): anything this session already
    // minted within the memo lifetime is answered without a round trip.
    // Refresh older entries before they expire.
    final now = DateTime.now();
    final unique = <String>[];
    for (final p in storagePaths.toSet()) {
      final hit = _urlMemo[p];
      if (hit != null && now.difference(hit.at) < _memoMaxAge) {
        byPath[p] = hit.url;
      } else {
        unique.add(p);
      }
    }
    if (unique.isEmpty) return byPath;

    // 40, not 80, and never a per-path fallback. An earlier version fell
    // back to signing each path individually when a batch came up short —
    // which, on a full deck, meant up to 80 separate HTTP calls in a burst.
    // That is the surest way to get rate-limited, i.e. it made the failure
    // it was trying to recover from more likely. Two calm attempts per
    // chunk, with a pause between, is both gentler and more effective.
    const chunkSize = 40;

    for (var start = 0; start < unique.length; start += chunkSize) {
      final end = (start + chunkSize) > unique.length
          ? unique.length
          : start + chunkSize;
      final slice = unique.sublist(start, end);

      for (var attempt = 0; attempt < 2; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
        if (!_isCurrent(owner, epoch)) return const {};
        try {
          // ignore: deprecated_member_use
          final signed = await supabase.storage
              .from(_bucket)
              // ignore: deprecated_member_use
              .createSignedUrls(slice, _signedUrlExpirySeconds);
          if (!_isCurrent(owner, epoch)) return const {};
          // Positional correlation is only safe when every path came back —
          // the slice is deduplicated, so a short result means something was
          // dropped and we can no longer say which. Retry rather than guess.
          if (signed.length == slice.length) {
            for (var i = 0; i < slice.length; i++) {
              byPath[slice[i]] = signed[i].signedUrl;
              // Keep the new URL in memory until its refresh window.
              _urlMemo[slice[i]] = (url: signed[i].signedUrl, at: now);
            }
            break;
          }
          debugPrint(
            'ZYRA: signedUrlMap — asked for ${slice.length}, got '
            '${signed.length}${attempt == 0 ? ", retrying" : ", giving up on this chunk"}.',
          );
        } catch (e) {
          if (!_isCurrent(owner, epoch)) return const {};
          debugPrint(
            'ZYRA: signedUrlMap — chunk failed'
            '${attempt == 0 ? ", retrying" : ", giving up on this chunk"}. $e',
          );
        }
      }
    }

    // Against ALL unique paths asked for, not just this round's misses —
    // `unique` shrank to the memo-miss set above.
    final wanted = storagePaths.toSet().length;
    if (byPath.length != wanted) {
      debugPrint(
        'ZYRA: signedUrlMap — resolved ${byPath.length} of '
        '$wanted unique paths.',
      );
    }
    return byPath;
  }

  /// Opens the device photo library and uploads the chosen image.
  /// Distinguishes "user cancelled picking" from "upload actually
  /// failed" (unlike a bare nullable return) so the UI can show a real
  /// error banner only when something genuinely went wrong, per
  /// ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md — a cancelled
  /// picker isn't an error and shouldn't look like one.
  ///
  /// Caller must check ZyraAuth.isSignedIn before calling this — there's
  /// no signed-in-user fallback here (that's handled at the call site
  /// in chapter2_flow.dart for the mock/dev-access path).
  static Future<ZyraPhotoResult> pickAndUpload() async {
    _synchronizeOwner();
    final user = ZyraAuth.currentUser;
    if (user == null) {
      return const ZyraPhotoResult.error(ZyraPhotoFailureKind.authentication);
    }
    final epoch = _epoch;

    final XFile? picked;
    try {
      picked = await _pickProfilePhoto();
    } catch (error) {
      final failure = preparationFailureFor(error);
      _logPreparationFailure(_PhotoPreparationStage.picker, failure);
      return ZyraPhotoResult.error(ZyraPhotoFailureKind.processing, failure);
    }
    if (!_isCurrent(user.id, epoch) || picked == null) {
      return const ZyraPhotoResult.cancelled();
    }

    try {
      final bytes = await _readAndProcess(picked);
      if (!_isCurrent(user.id, epoch)) return const ZyraPhotoResult.cancelled();
      return _uploadProcessed(bytes);
    } on ZyraPhotoPreparationFailure catch (failure) {
      return ZyraPhotoResult.error(ZyraPhotoFailureKind.processing, failure);
    }
  }

  /// Restores the signed-in Seeker's ordered photo draft for deferred
  /// onboarding. Only storage paths are persisted; fresh signed URLs are
  /// minted on every restore so an expired URL is never treated as data.
  static Future<List<String>> fetchOwnPhotos({
    String? expectedUserId,
    bool throwOnError = false,
  }) async {
    _synchronizeOwner();
    final user = ZyraAuth.currentUser;
    if (user == null || (expectedUserId != null && user.id != expectedUserId)) {
      if (throwOnError) throw StateError('Account changed.');
      return const [];
    }
    final epoch = _epoch;
    try {
      final rows = await supabase
          .from('profile_photos')
          .select('storage_path, display_order')
          .eq('user_id', user.id)
          .order('display_order');
      if (!_isCurrent(user.id, epoch)) throw StateError('Account changed.');
      final paths = <String>[
        for (final row in rows)
          if (row['storage_path'] is String) row['storage_path'] as String,
      ];
      final urls = await signedUrlsFor(paths);
      if (!_isCurrent(user.id, epoch) ||
          (throwOnError && urls.length != paths.length)) {
        throw StateError('Photos unavailable.');
      }
      return urls;
    } catch (e) {
      debugPrint('ZYRA: own onboarding photos could not be restored — $e');
      if (throwOnError) rethrow;
      return const [];
    }
  }

  /// Replaces this user's `profile_photos` rows with the current
  /// ordered list of display URLs (first = primary). Derives the
  /// storage path back out of each URL rather than threading a
  /// separate path alongside every URL through the UI layer. Handles
  /// both URL shapes — signed (`.../object/sign/profile-photos/{path}
  /// ?token=...`, the current form) and public (`.../object/public/
  /// profile-photos/{path}`, in case any pre-privacy-fix URL is still
  /// held in AppState from an older session).
  static Future<void> syncPhotos(List<String> displayUrls) async {
    await syncPhotosConfirmed(displayUrls);
  }

  /// Edit Photos variant of [syncPhotos] that reports whether the ordered
  /// rows were actually saved. The onboarding flow remains best-effort, while
  /// an explicit editor must not silently claim a failed write succeeded.
  static Future<bool> syncPhotosConfirmed(
    List<String> displayUrls, {
    String? expectedUserId,
  }) async {
    _synchronizeOwner();
    final user = ZyraAuth.currentUser;
    if (user == null || (expectedUserId != null && user.id != expectedUserId)) {
      return false;
    }
    final epoch = _epoch;

    try {
      await supabase.from('profile_photos').delete().eq('user_id', user.id);
      if (!_isCurrent(user.id, epoch)) return false;
      if (displayUrls.isEmpty) return true;

      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < displayUrls.length; i++) {
        rows.add({
          'user_id': user.id,
          'storage_path': _storagePathFromUrl(displayUrls[i]),
          'is_primary': i == 0,
          'display_order': i,
        });
      }
      await supabase.from('profile_photos').insert(rows);
      return _isCurrent(user.id, epoch);
    } catch (e) {
      // Best-effort — AppState's in-memory photos list (used everywhere
      // else in the app today) already has the URLs regardless of
      // whether this sync succeeds.
      debugPrint(
        'ZYRA: ordered profile photos could not be saved '
        '[${classifyFailure(e).referenceCode}].',
      );
      return false;
    }
  }

  /// `.../storage/v1/object/sign/{bucket}/{path}?token=...` →
  /// `{path}`; also accepts the legacy public form. Falls back to the
  /// input unchanged if neither marker is present (shouldn't happen
  /// for anything this service produced).
  static String _storagePathFromUrl(String url) {
    final withoutQuery = url.split('?').first;
    for (final marker in [
      '/object/sign/$_bucket/',
      '/object/public/$_bucket/',
    ]) {
      final idx = withoutQuery.indexOf(marker);
      if (idx != -1) {
        return Uri.decodeComponent(withoutQuery.substring(idx + marker.length));
      }
    }
    return url;
  }
}
