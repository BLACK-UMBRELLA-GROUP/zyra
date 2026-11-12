import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const zyraProfileVideoLimit = Duration(seconds: 10);

enum ZyraProfileVideoStatus { pending, approved, rejected }

class ZyraProfileVideoRecord {
  const ZyraProfileVideoRecord({
    required this.path,
    required this.status,
    required this.duration,
    this.reason,
  });

  final String path;
  final ZyraProfileVideoStatus status;
  final Duration duration;
  final String? reason;
}

class ZyraProfileVideoRefusal implements Exception {
  const ZyraProfileVideoRefusal(this.reason);

  final String reason;

  String get memberMessage => switch (reason) {
    'has_sound' => 'Your video still has sound. Please try again.',
    'too_long' => 'Videos can be up to 10 seconds.',
    'not_allowed' => 'Profile video comes with Seeker One.',
    _ => "We couldn't use this video. Please try another.",
  };
}

abstract interface class ZyraProfileVideoStore {
  Future<ZyraProfileVideoRecord?> loadOwn();
  Future<Uint8List> readOwn(ZyraProfileVideoRecord record);
  Future<ZyraProfileVideoRecord> submit(File clip, Duration duration);
  Future<void> remove();
}

/// Bound to the admitted account and the lifetime of the calling surface.
/// View reads always recheck access with the caller's authenticated session.
class ZyraSupabaseProfileVideoStore implements ZyraProfileVideoStore {
  ZyraSupabaseProfileVideoStore(
    this._client, {
    required this.accountId,
    required this.canAct,
    required this.mediaClient,
  });

  final SupabaseClient _client;
  final http.Client mediaClient;
  final String accountId;
  final bool Function() canAct;
  static const _maxBytes = 20971520;
  StorageFileApi get _bucket => _client.storage.from('profile-videos');

  static String _bearer(Session session) => 'Bearer ${session.accessToken}';

  static String _newVideoId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Session _requireSession() {
    final session = _client.auth.currentSession;
    if (session == null || session.user.id != accountId || !canAct()) {
      throw StateError('Profile video session unavailable');
    }
    return session;
  }

  @override
  Future<ZyraProfileVideoRecord?> loadOwn() async {
    final session = _requireSession();
    final rows = await _client
        .rpc<PostgrestList>('zyra_my_profile_video')
        .setHeader('Authorization', _bearer(session));
    _requireSession();
    if (rows.isEmpty) return null;
    final row = rows.single;
    return ZyraProfileVideoRecord(
      path: row['storage_path'] as String,
      status: ZyraProfileVideoStatus.values.byName(row['status'] as String),
      duration: Duration(milliseconds: row['duration_ms'] as int),
      reason: row['reject_reason'] as String?,
    );
  }

  Future<Uint8List> _download(String path) async {
    final session = _requireSession();
    final bucket = _bucket;
    final objectPath = Uri(
      pathSegments: ['profile-videos', ...path.split('/')],
    );
    final response = await mediaClient.get(
      Uri.parse('${bucket.url}/object/authenticated/$objectPath'),
      headers: {
        'Authorization': _bearer(session),
        'apikey': _client.auth.headers['apikey']!,
        'Cache-Control': 'no-store',
      },
    );
    _requireSession();
    if (response.statusCode != 200 || response.bodyBytes.length > _maxBytes) {
      throw StateError('Profile video unavailable');
    }
    return response.bodyBytes;
  }

  @override
  Future<Uint8List> readOwn(ZyraProfileVideoRecord record) {
    if (!record.path.startsWith('$accountId/')) {
      throw StateError('Profile video belongs to another account');
    }
    return _download(record.path);
  }

  Future<Uint8List?> loadApproved(String ownerId) async {
    final session = _requireSession();
    final rows = await _client
        .rpc<PostgrestList>(
          'zyra_profile_video_for',
          params: {'p_user': ownerId},
        )
        .setHeader('Authorization', _bearer(session));
    _requireSession();
    return rows.isEmpty
        ? null
        : _download(rows.single['storage_path'] as String);
  }

  @override
  Future<ZyraProfileVideoRecord> submit(File clip, Duration duration) async {
    _requireSession();
    if (duration > zyraProfileVideoLimit) {
      throw const ZyraProfileVideoRefusal('too_long');
    }
    if (duration <= Duration.zero) {
      throw const ZyraProfileVideoRefusal('not_a_video');
    }
    if (await clip.length() > _maxBytes) {
      throw const ZyraProfileVideoRefusal('too_large');
    }
    final session = _requireSession();
    final path = '$accountId/${_newVideoId()}.mp4';
    await _bucket
        .setHeader('Authorization', _bearer(session))
        .upload(
          path,
          clip,
          fileOptions: const FileOptions(
            contentType: 'video/mp4',
            cacheControl: '0',
            upsert: false,
          ),
          retryAttempts: 0,
        );
    // An explicit 503 can be retried once after checking for a committed row.
    // A broken connection may leave the first invocation running.
    for (var attempt = 0; ; attempt++) {
      final currentSession = _requireSession();
      try {
        final response = await _client.functions.invoke(
          'zyra-profile-video-submit',
          body: {'path': path},
          headers: {'Authorization': _bearer(currentSession)},
        );
        _requireSession();
        final result = response.data;
        _checkRefusal(result);
        if (result is! Map ||
            result['ok'] != true ||
            result['status'] != 'pending') {
          throw StateError('Unexpected profile video submission response');
        }
        return ZyraProfileVideoRecord(
          path: path,
          status: ZyraProfileVideoStatus.pending,
          duration: duration,
        );
      } on FunctionException catch (error) {
        _requireSession();
        _checkRefusal(error.details);
        final recorded = await loadOwn();
        if (recorded != null && recorded.path == path) return recorded;
        if (error.status != 503 || attempt != 0) rethrow;
      } on http.ClientException {
        final recorded = await loadOwn();
        if (recorded != null && recorded.path == path) return recorded;
        rethrow;
      }
    }
  }

  static void _checkRefusal(Object? result) {
    if (result is Map && result['ok'] == false && result['reason'] is String) {
      throw ZyraProfileVideoRefusal(result['reason'] as String);
    }
  }

  @override
  Future<void> remove() async {
    final session = _requireSession();
    final path = await _client
        .rpc<String?>('zyra_remove_my_profile_video')
        .setHeader('Authorization', _bearer(session));
    final currentSession = _requireSession();
    if (path != null && path.startsWith('$accountId/')) {
      await _bucket.setHeader('Authorization', _bearer(currentSession)).remove([
        path,
      ]);
    }
  }
}

class ZyraProfileVideoMedia {
  const ZyraProfileVideoMedia();

  static const _channel = MethodChannel('zyra/profile_video');

  Future<XFile?> pick() => ImagePicker().pickVideo(source: ImageSource.gallery);

  Future<({Duration duration, int videoStartMs})> inspect(String path) async {
    final info = await _channel.invokeMapMethod<String, int>('inspect', {
      'path': path,
    });
    final milliseconds = info?['durationMs'];
    if (milliseconds == null || milliseconds <= 0) {
      throw StateError('Invalid video duration');
    }
    return (
      duration: Duration(milliseconds: milliseconds),
      videoStartMs: info?['videoStartMs'] ?? 0,
    );
  }

  Future<List<Uint8List>> thumbnails(String path) async => (await _channel
      .invokeListMethod<Uint8List>('thumbnails', {'path': path}))!;

  Future<Uint8List?> still(String path, {int timeMs = 0}) => _channel
      .invokeMethod<Uint8List>('still', {'path': path, 'timeMs': timeMs});

  Future<File> export(String path, Duration start) async {
    final clip = await _channel.invokeMethod<String>('export', {
      'path': path,
      'startMs': start.inMilliseconds,
    });
    if (clip == null) throw StateError('Video export failed');
    return File(clip);
  }
}
