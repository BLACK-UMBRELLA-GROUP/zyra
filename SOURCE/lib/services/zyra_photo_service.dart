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
import 'package:flutter/foundation.dart' show debugPrint;
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

  // ── SESSION URL MEMO — DR-ZYRA-169 Phase 2, 2026-08-15 ──────────────
  //
  // Every list refresh used to re-sign every path it showed — a signing
  // round trip per fetch for URLs that live SEVEN DAYS. This memo keeps
  // the session's already-minted URLs so a refresh only signs what it
  // has never signed before.
  //
  // IN MEMORY, DELIBERATELY, and this is a privacy line, not a
  // convenience: a signed URL is a bearer capability — anyone holding
  // the string can fetch the photo for 7 days with no auth check — so
  // it must never be written to disk (the review's NEVER-STORE item N2).
  // The disk cache stores BYTES keyed by the tokenless URL instead
  // (zyra_image_cache.dart), which is exactly as fast and carries no
  // capability.
  //
  // Entries older than 6 days re-sign on next use — one day of margin
  // before the 7-day URL under them dies. Cleared on sign-out
  // (zyra_auth.dart) with everything else the account minted.
  static final Map<String, ({String url, DateTime at})> _urlMemo = {};
  static const Duration _memoMaxAge = Duration(days: 6);

  /// Sign-out hook — see the memo note above.
  static void clearUrlMemoForSignOut() => _urlMemo.clear();

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
    final out = <String>[];
    for (final p in storagePaths) {
      final url = byPath[p];
      if (url != null) out.add(url);
    }
    if (out.length != storagePaths.length) {
      debugPrint('ZYRA: signedUrlsFor — resolved ${out.length} of '
          '${storagePaths.length} paths; the rest are skipped.');
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
  static Future<Map<String, String>> signedUrlMap(List<String> storagePaths) async {
    if (storagePaths.isEmpty) return const {};
    final byPath = <String, String>{};

    // Memo first (DR-ZYRA-169 Phase 2): anything this session already
    // minted — and that is younger than 6 of its 7 days — is answered
    // without a round trip. Only genuine misses go to Storage below.
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
      final end = (start + chunkSize) > unique.length ? unique.length : start + chunkSize;
      final slice = unique.sublist(start, end);

      for (var attempt = 0; attempt < 2; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
        try {
          // ignore: deprecated_member_use
          final signed = await supabase.storage.from(_bucket).createSignedUrls(slice, _signedUrlExpirySeconds);
          // Positional correlation is only safe when every path came back —
          // the slice is deduplicated, so a short result means something was
          // dropped and we can no longer say which. Retry rather than guess.
          if (signed.length == slice.length) {
            for (var i = 0; i < slice.length; i++) {
              byPath[slice[i]] = signed[i].signedUrl;
              // Remembered for the rest of the session — see _urlMemo.
              _urlMemo[slice[i]] = (url: signed[i].signedUrl, at: now);
            }
            break;
          }
          debugPrint('ZYRA: signedUrlMap — asked for ${slice.length}, got '
              '${signed.length}${attempt == 0 ? ", retrying" : ", giving up on this chunk"}.');
        } catch (e) {
          debugPrint('ZYRA: signedUrlMap — chunk failed'
              '${attempt == 0 ? ", retrying" : ", giving up on this chunk"}. $e');
        }
      }
    }

    // Against ALL unique paths asked for, not just this round's misses —
    // `unique` shrank to the memo-miss set above.
    final wanted = storagePaths.toSet().length;
    if (byPath.length != wanted) {
      debugPrint('ZYRA: signedUrlMap — resolved ${byPath.length} of '
          '$wanted unique paths.');
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
      // A freshly-minted URL is a memo entry like any other.
      _urlMemo[path] = (url: signedUrl, at: DateTime.now());
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
