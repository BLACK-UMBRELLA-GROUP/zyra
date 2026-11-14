import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../main.dart' show supabase, supabaseReady;
import '../models/zyra_code_format.dart';
import '../models/zyra_known_person_code.dart';
import 'zyra_account_state.dart';
import 'zyra_internal_preview_client.dart';
import 'zyra_wali_link_service.dart' show ZyraPersonalCodePreview;

enum ZyraCodeLinkOutcome {
  addGuardian,
  addSeeker,
  scan,
  ownCode,
  unavailable,
  rateLimited,
  failed,
}

@immutable
class ZyraCodeLinkResult {
  const ZyraCodeLinkResult(this.outcome, {this.firstName});

  final ZyraCodeLinkOutcome outcome;
  final String? firstName;
}

abstract final class ZyraCodeLinkService {
  static const _failed = ZyraCodeLinkResult(ZyraCodeLinkOutcome.failed);
  static bool? _clientReadyForTesting;

  @visibleForTesting
  static void setClientReadyForTesting(bool? ready) {
    assert(() {
      _clientReadyForTesting = ready;
      return true;
    }());
  }

  /// Makes a single charged, caller-scoped code check. Only the server
  /// chooses the route or decides whether the code is available.
  static Future<ZyraCodeLinkResult> resolve(
    String code, {
    required bool Function() isCurrent,
  }) async {
    if (!(_clientReadyForTesting ?? supabaseReady) ||
        ZyraCodeFormat.scanned(code) == null) {
      return _failed;
    }
    final client = supabase;
    final session = client.auth.currentSession;
    if (session == null) return _failed;

    final ownerId = session.user.id;
    final generation = ZyraAccountState.generation;
    bool ownerCurrent() =>
        isCurrent() &&
        !ZyraInternalPreviewClient.isActive &&
        !ZyraAccountState.isSigningOut &&
        ZyraAccountState.generation == generation &&
        client.auth.currentUser?.id == ownerId;

    try {
      if (!ownerCurrent()) return _failed;
      final rows = await client
          .rpc<List<dynamic>>(
            'zyra_resolve_code_link',
            params: {'p_code': code},
          )
          .setHeader('Authorization', 'Bearer ${session.accessToken}')
          .timeout(const Duration(seconds: 10));
      return ownerCurrent() ? _decode(rows) : _failed;
    } on PostgrestException catch (error) {
      return ownerCurrent() && error.message == zyraCodeRateLimitSignal
          ? const ZyraCodeLinkResult(ZyraCodeLinkOutcome.rateLimited)
          : _failed;
    } catch (_) {
      return _failed;
    }
  }

  static ZyraCodeLinkResult _decode(List<dynamic> rows) {
    if (rows.length != 1) return _failed;
    final row = rows.single;
    if (row is! Map<String, dynamic> || row.length != 5) return _failed;
    if (row case {
      'outcome': final String outcome,
      'owner_first_name': final firstName,
      'owner_role': final role,
      'owner_age': final age,
      'owner_location': final location,
    }) {
      switch (outcome) {
        case 'add_guardian':
        case 'add_seeker':
          if (age != null || location != null) return _failed;
          final person = ZyraPersonalCodePreview.fromRow(row);
          final isAddGuardian = outcome == 'add_guardian';
          if (person == null ||
              person.role != (isAddGuardian ? 'wali' : 'seeker')) {
            return _failed;
          }
          return ZyraCodeLinkResult(
            isAddGuardian
                ? ZyraCodeLinkOutcome.addGuardian
                : ZyraCodeLinkOutcome.addSeeker,
            firstName: person.firstName,
          );
        case 'scan':
          if (role != null || age is! int) {
            return _failed;
          }
          final person = ZyraKnownPersonCodePreview.fromRow(row);
          if (person == null) return _failed;
          return ZyraCodeLinkResult(
            ZyraCodeLinkOutcome.scan,
            firstName: person.firstName,
          );
        case 'own_code':
        case 'unavailable':
          if (firstName != null ||
              role != null ||
              age != null ||
              location != null) {
            return _failed;
          }
          return ZyraCodeLinkResult(
            outcome == 'own_code'
                ? ZyraCodeLinkOutcome.ownCode
                : ZyraCodeLinkOutcome.unavailable,
          );
      }
    }
    return _failed;
  }
}
