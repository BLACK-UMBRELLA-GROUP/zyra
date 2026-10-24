// Feedback — ideas and problem reports from users.
//
// NEW 2026-08-07. Founder: "in setting we need a feedback section where we
// can improve the app from users requests."
//
// A TABLE, NOT AN EMAIL, and the distinction is the point. Help & Support
// already ends in "email us", which is right for someone who is stuck and
// wants a person. This is the other case: someone who is fine and has an
// idea. Those arrive in volume, want counting and grouping, and die in an
// inbox.
//
// Writes go through zyra_submit_feedback() — there is deliberately no
// INSERT grant on app_feedback itself, so this service cannot become a
// write-anything endpoint even if someone calls it with odd values. The
// RPC trims, validates the category, stamps user_id server-side and
// rate-limits to ten an hour.

import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:package_info_plus/package_info_plus.dart';

import '../main.dart';
import 'zyra_account_state.dart';
import 'zyra_auth.dart';

enum ZyraFeedbackCategory { idea, problem, other }

extension ZyraFeedbackCategoryX on ZyraFeedbackCategory {
  String get wire => switch (this) {
    ZyraFeedbackCategory.idea => 'idea',
    ZyraFeedbackCategory.problem => 'problem',
    ZyraFeedbackCategory.other => 'other',
  };

  String get label => switch (this) {
    ZyraFeedbackCategory.idea => 'Idea',
    ZyraFeedbackCategory.problem => 'Problem',
    ZyraFeedbackCategory.other => 'Other',
  };
}

enum ZyraFeedbackResult { sent, empty, tooLong, rateLimited, failed }

class ZyraFeedbackService {
  ZyraFeedbackService._();

  /// Reads the version from the installed bundle, matching the Settings
  /// footer. A lookup failure is sent as NULL rather than inventing a build.
  static Future<String?> _installedAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      if (version.isEmpty) return null;
      return build.isEmpty ? version : '$version+$build';
    } catch (error) {
      debugPrint('ZYRA: installed app version unavailable.\n$error');
      return null;
    }
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      _ => defaultTargetPlatform.name,
    };
  }

  /// [screen] is where they were when they wrote it — the single most
  /// useful field in a bug report after the message itself.
  static Future<ZyraFeedbackResult> submit({
    required ZyraFeedbackCategory category,
    required String message,
    String? screen,
  }) async {
    final owner = ZyraAuth.currentUser?.id;
    final generation = ZyraAccountState.generation;
    final session = supabase.auth.currentSession;
    bool current() =>
        owner != null &&
        !ZyraAccountState.isSigningOut &&
        ZyraAccountState.generation == generation &&
        ZyraAuth.currentUser?.id == owner &&
        session?.user.id == owner &&
        session?.expiresAt != null &&
        !session!.isExpired;
    if (!current()) return ZyraFeedbackResult.failed;
    try {
      final appVersion = await _installedAppVersion();
      // Platform lookup yields before the request is built. Never attach a
      // previous account's typed draft to a replacement session.
      if (!current()) return ZyraFeedbackResult.failed;
      final res =
          await supabase
                  .rpc(
                    'zyra_submit_feedback',
                    params: {
                      'p_category': category.wire,
                      'p_message': message,
                      'p_app_version': appVersion,
                      'p_platform': _platform,
                      'p_screen': screen,
                    },
                  )
                  .setHeader('Authorization', 'Bearer ${session!.accessToken}')
              as Map<String, dynamic>;
      if (!current()) return ZyraFeedbackResult.failed;

      return switch (res['status'] as String?) {
        'sent' => ZyraFeedbackResult.sent,
        'empty' => ZyraFeedbackResult.empty,
        'too_long' => ZyraFeedbackResult.tooLong,
        'rate_limited' => ZyraFeedbackResult.rateLimited,
        _ => ZyraFeedbackResult.failed,
      };
    } catch (e) {
      debugPrint('ZYRA: zyra_submit_feedback failed.\n$e');
      return ZyraFeedbackResult.failed;
    }
  }
}
