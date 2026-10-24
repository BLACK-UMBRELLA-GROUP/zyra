// Guardian paid-feature access is resolved by the server. It can come from
// the Guardian's own subscription or a linked Seeker allocation; this boolean
// is not proof of a separately billed Additional Guardian membership.

import 'package:flutter/foundation.dart' show debugPrint;

import '../main.dart';
import '../state/app_state.dart';
import 'zyra_account_state.dart';
import 'zyra_auth.dart';
import 'zyra_wali_link_service.dart' show ZyraSourceFailure, ZyraSourceResult;

class ZyraEntitlementService {
  ZyraEntitlementService._();
  static int _accessRequest = 0;

  /// Denies paid features on missing session or failed verification. Only a
  /// confirmed response for the same account may update the shared membership
  /// presentation; an earlier account's response cannot leak into a new one.
  static Future<bool> hasWaliOne() async =>
      (await resolveGuardianPaidAccess()).valueOr(false);

  /// Preserves unavailable separately from confirmed false. This resolves
  /// server-defined paid-feature access, not context ownership or proof of an
  /// independently purchased Guardian membership. Legacy callers still deny
  /// access through [hasWaliOne] when this result is unavailable.
  static Future<ZyraSourceResult<bool>> resolveGuardianPaidAccess() async {
    final request = ++_accessRequest;
    final userId = ZyraAuth.currentUser?.id;
    if (userId == null) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    final generation = ZyraAccountState.generation;
    bool stillOwner() =>
        ZyraAuth.currentUser?.id == userId &&
        ZyraAccountState.isCurrent(userId, generation);
    if (!stillOwner()) {
      return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
    }
    try {
      final result = await supabase.rpc('wali_has_wali_one');
      if (!stillOwner()) {
        return const ZyraSourceResult.unavailable(ZyraSourceFailure.signedOut);
      }
      if (request != _accessRequest) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.requestFailed,
        );
      }
      if (result is! bool) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.invalidResponse,
        );
      }
      AppState.instance.setWaliOne(result);
      if (!stillOwner() || request != _accessRequest) {
        return const ZyraSourceResult.unavailable(
          ZyraSourceFailure.requestFailed,
        );
      }
      return ZyraSourceResult.available(result);
    } catch (error) {
      debugPrint(
        'ZYRA Guardian entitlement check failed (${error.runtimeType}).',
      );
      return const ZyraSourceResult.unavailable(
        ZyraSourceFailure.requestFailed,
      );
    }
  }
}
