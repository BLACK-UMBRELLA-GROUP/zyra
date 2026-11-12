import 'package:flutter/foundation.dart' show immutable, visibleForTesting;

import '../main.dart';
import '../models/zyra_compatibility_area.dart';
import 'zyra_account_state.dart';
import 'zyra_auth.dart';
import 'zyra_internal_preview_client.dart';

enum ZyraCompatibilityTopicsState { ready, needsReconfirmation, incomplete }

@immutable
class ZyraCompatibilityTopicsResult {
  const ZyraCompatibilityTopicsResult({
    required this.state,
    required this.overallScore,
    required this.topicsLocked,
    required this.areaBands,
  });

  final ZyraCompatibilityTopicsState state;
  final double? overallScore;
  final bool topicsLocked;
  final Map<ZyraCompatibilityArea, ZyraCompatibilityBand>? areaBands;
}

/// Reads the saved result from an already admitted Seeker result route.
abstract final class ZyraCompatibilityTopicsService {
  static bool? _clientReadyForTesting;
  static bool get clientReady => _clientReadyForTesting ?? supabaseReady;

  @visibleForTesting
  static void setClientReadyForTesting(bool? ready) {
    assert(() {
      _clientReadyForTesting = ready;
      return true;
    }());
  }

  /// An empty projection means the server did not admit this result read.
  static Future<ZyraCompatibilityTopicsResult?> fetch({
    required String expectedUserId,
    required String subjectId,
    String? matchId,
  }) async {
    final generation = ZyraAccountState.generation;
    bool ownerCurrent() =>
        clientReady &&
        !ZyraInternalPreviewClient.isActive &&
        !ZyraAccountState.isSigningOut &&
        ZyraAccountState.generation == generation &&
        expectedUserId.isNotEmpty &&
        ZyraAuth.currentUser?.id == expectedUserId;

    if (!ownerCurrent()) throw StateError('The result account changed.');
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('The result account is no longer available.');
    }
    final rows = await supabase
        .rpc<List<dynamic>>(
          'zyra_compatibility_topics',
          params: {'p_subject': subjectId, 'p_match_id': ?matchId},
        )
        .setHeader('Authorization', 'Bearer $token')
        .timeout(const Duration(seconds: 10));
    if (!ownerCurrent()) throw StateError('The result account changed.');
    if (rows.isEmpty) return null;
    return _decode(rows);
  }

  static ZyraCompatibilityTopicsResult _decode(List<dynamic> rows) {
    const malformed = FormatException('Invalid compatibility result.');
    const areas = ZyraCompatibilityArea.values;
    if (rows.length != areas.length) throw malformed;

    ZyraCompatibilityTopicsState? state;
    String? wireState;
    double? score;
    bool? topicsLocked;
    final seen = <ZyraCompatibilityArea>{};
    final bands = <ZyraCompatibilityArea, ZyraCompatibilityBand>{};

    for (final row in rows) {
      if (row case {
        'state': final String rawState,
        'overall': final rawScore,
        'topics_locked': final bool locked,
        'area_no': final int number,
        'area_code': final String code,
        'band': final rawBand,
      } when row.length == 6 && number >= 1 && number <= areas.length) {
        final area = areas[number - 1];
        if (area.name != code || !seen.add(area)) throw malformed;

        final currentState = switch (rawState) {
          'ok' => ZyraCompatibilityTopicsState.ready,
          'needs_reconfirmation' =>
            ZyraCompatibilityTopicsState.needsReconfirmation,
          'incomplete' || 'invalid' => ZyraCompatibilityTopicsState.incomplete,
          _ => throw malformed,
        };
        final ready = currentState == ZyraCompatibilityTopicsState.ready;
        final currentScore = switch (rawScore) {
          final num value when ready && value >= 0 && value <= 100 =>
            value.toDouble(),
          null when !ready => null,
          _ => throw malformed,
        };
        if (wireState != null &&
            (rawState != wireState ||
                currentScore != score ||
                locked != topicsLocked)) {
          throw malformed;
        }
        if (ready && !locked) {
          bands[area] = switch (rawBand) {
            'strong' => ZyraCompatibilityBand.strong,
            'good' => ZyraCompatibilityBand.good,
            'some_differences' => ZyraCompatibilityBand.someDifferences,
            'not_enough' => ZyraCompatibilityBand.notEnoughAnswers,
            _ => throw malformed,
          };
        } else if (rawBand != null) {
          throw malformed;
        }
        wireState = rawState;
        state = currentState;
        score = currentScore;
        topicsLocked = locked;
      } else {
        throw malformed;
      }
    }

    return ZyraCompatibilityTopicsResult(
      state: state!,
      overallScore: score,
      topicsLocked: topicsLocked!,
      areaBands: bands.isEmpty ? null : Map.unmodifiable(bands),
    );
  }
}
