// Profile photo upload — OA-104. Wraps picking a photo from the device
// library and uploading it to the `profile-photos` Storage bucket
// (own-folder-only write per RLS: `{auth.uid()}/{filename}`), then
// syncing the resulting URLs into the `profile_photos` table so they
// survive beyond this session.
//
// PRIVATE BUCKET (2026-07-19, Fable review): the bucket was public,
// which contradicted IMAGE_HANDLING_CURRENT_VERSION_V1.md ("Originals
// never publicly accessible") — a public bucket serves objects by URL
// with no auth check at all. It is now private, and every display URL
// is a signed URL (7-day expiry — longer than any app session, short
// enough that a leaked URL dies). Storage read RLS mirrors the
// profile_photos table policy: own photos, or photos of an
// active+complete profile.
//
// Photo REMOVAL in the Chapter 2 picker only removes the URL from the
// in-memory list, not the underlying Storage object or table row — a
// deliberate v1 simplification (orphaned files are harmless in a
// preview build) rather than wiring delete permissions and re-ordering
// logic today. Worth cleaning up before a real launch.

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import 'zyra_auth.dart';

enum ZyraPhotoOutcome { uploaded, cancelled, error }

class ZyraPhotoResult {
  final ZyraPhotoOutcome outcome;
  final String? url;
  const ZyraPhotoResult._(this.outcome, this.url);

  const ZyraPhotoResult.uploaded(String url) : this._(ZyraPhotoOutcome.uploaded, url);
  const ZyraPhotoResult.cancelled() : this._(ZyraPhotoOutcome.cancelled, null);
  const ZyraPhotoResult.error() : this._(ZyraPhotoOutcome.error, null);
}

class ZyraPhotoService {
  ZyraPhotoService._();

  static const String _bucket = 'profile-photos';

  /// Signed-URL lifetime. 7 days: outlives any realistic app session
  /// (URLs are regenerated on every fetch anyway), short enough that a
  /// leaked URL expires.
  static const int _signedUrlExpirySeconds = 60 * 60 * 24 * 7;

  /// Batch-signs storage paths for display. Used by Browse and Matches
  /// for other users' photos as well as the user's own. Returns an
  /// empty list on any failure — callers already treat "no photos" as
  /// a skip/fallback case, never an error.
  static Future<List<String>> signedUrlsFor(List<String> storagePaths) async {
    if (storagePaths.isEmpty) return const [];
    try {
      final signed = await supabase.storage.from(_bucket).createSignedUrls(storagePaths, _signedUrlExpirySeconds);
      return signed.map((s) => s.signedUrl).toList();
    } catch (_) {
      return const [];
    }
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
    final user = ZyraAuth.currentUser;
    if (user == null) return const ZyraPhotoResult.error();

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return const ZyraPhotoResult.cancelled();

    try {
      final Uint8List bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from(_bucket).uploadBinary(path, bytes);
      final signedUrl = await supabase.storage.from(_bucket).createSignedUrl(path, _signedUrlExpirySeconds);
      return ZyraPhotoResult.uploaded(signedUrl);
    } catch (_) {
      return const ZyraPhotoResult.error();
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
    final user = ZyraAuth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profile_photos').delete().eq('user_id', user.id);
      if (displayUrls.isEmpty) return;

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
    } catch (_) {
      // Best-effort — AppState's in-memory photos list (used everywhere
      // else in the app today) already has the URLs regardless of
      // whether this sync succeeds.
    }
  }

  /// `.../storage/v1/object/sign/{bucket}/{path}?token=...` →
  /// `{path}`; also accepts the legacy public form. Falls back to the
  /// input unchanged if neither marker is present (shouldn't happen
  /// for anything this service produced).
  static String _storagePathFromUrl(String url) {
    final withoutQuery = url.split('?').first;
    for (final marker in ['/object/sign/$_bucket/', '/object/public/$_bucket/']) {
      final idx = withoutQuery.indexOf(marker);
      if (idx != -1) return Uri.decodeComponent(withoutQuery.substring(idx + marker.length));
    }
    return url;
  }
}
