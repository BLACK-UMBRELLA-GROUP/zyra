// Identity verification client boundary — DR-ZYRA-220/221, OA-ZYRA-266.
//
// Phase A deliberately contains no provider SDK. The provider adapter is an
// interface so Phase B can supply Sumsub without changing onboarding or the
// gate. SDK completion will remain progress UI only; the signed webhook and
// private server record are always authoritative.

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import '../main.dart';
import '../models/zyra_identity_verification.dart';
import 'zyra_auth.dart';
import 'zyra_identity_admission_policy.dart';

const String kIdentityVerificationConsentVersion =
    'idv_sumsub_biometric_v1_2026-08-29';

enum ZyraVerificationLaunchOutcome { launched, cancelled, unavailable, failed }

abstract interface class ZyraIdentityVerificationProviderAdapter {
  Future<ZyraVerificationLaunchOutcome> launch();
}

/// Phase A adapter. It never fabricates success and never touches biometrics.
class ZyraUnavailableIdentityVerificationProvider
    implements ZyraIdentityVerificationProviderAdapter {
  const ZyraUnavailableIdentityVerificationProvider();

  @override
  Future<ZyraVerificationLaunchOutcome> launch() async =>
      ZyraVerificationLaunchOutcome.unavailable;
}

class ZyraIdentityVerificationService {
  ZyraIdentityVerificationService._();

  /// Production rollout fuse, intentionally FALSE until provider activation.
  ///
  /// The Phase A storage migration was applied on 2026-08-29, but no live
  /// provider can yet produce a verified result. Turning the Production fuse
  /// on first would lock every existing account.
  static const bool _productionExistingAccountGate = bool.fromEnvironment(
    'ZYRA_IDV_ENFORCE_EXISTING_ACCOUNTS',
    defaultValue: false,
  );

  /// Ordinary member rollout remains unchanged by internal local previews.
  static bool get enforceExistingAccountGate =>
      ZyraIdentityAdmissionPolicy.requiresExistingAccountGate(
        productionRolloutEnabled: _productionExistingAccountGate,
      );

  static ZyraIdentityVerificationProviderAdapter _provider =
      const ZyraUnavailableIdentityVerificationProvider();

  /// Configuration only, not a health check or a verification grant. This
  /// remains false across app restarts while Phase B has no capture adapter.
  static bool get isProviderConfigured =>
      _provider is! ZyraUnavailableIdentityVerificationProvider;

  /// Used by an ordinary verification screen to refuse work for a different
  /// account after async session changes. This never creates authorization.
  static bool isCurrentPrincipal(String? expectedUserId) {
    final session = supabase.auth.currentSession;
    return expectedUserId != null &&
        expectedUserId.isNotEmpty &&
        session != null &&
        session.user.id == expectedUserId &&
        session.expiresAt != null &&
        !session.isExpired;
  }

  static Session _captureSession(String expectedUserId) {
    final session = supabase.auth.currentSession;
    if (expectedUserId.isEmpty ||
        session == null ||
        session.user.id != expectedUserId ||
        session.expiresAt == null ||
        session.isExpired) {
      throw StateError('Verification account changed. Sign in again.');
    }
    return session;
  }

  static Future<Object?> _rpc(
    String function, {
    Map<String, dynamic>? params,
    String? expectedUserId,
  }) async {
    if (expectedUserId == null) {
      return supabase.rpc(function, params: params);
    }
    final session = _captureSession(expectedUserId);
    // The shared auth client may refresh or switch accounts asynchronously
    // before sending. Pin only this builder to its captured principal so an
    // A -> B -> A race cannot attach B's state/consent/deletion to A's screen.
    // The existing HTTP/Founder-denial wrapper still handles this request.
    // The token stays in memory only, never in preferences or logs.
    final raw = await supabase
        .rpc(function, params: params)
        .setHeader('Authorization', 'Bearer ${session.accessToken}');
    _captureSession(expectedUserId);
    return raw;
  }

  static Future<ZyraIdentityVerificationState?> fetchMyState({
    String? expectedUserId,
  }) async {
    if (expectedUserId == null && !ZyraAuth.isSignedIn) return null;
    final raw = await _rpc(
      'zyra_my_identity_verification_state',
      expectedUserId: expectedUserId,
    );
    return _stateFromRpc(raw);
  }

  static Future<ZyraIdentityVerificationState?> recordConsent({
    required bool granted,
    String? expectedUserId,
  }) async {
    if (expectedUserId == null && !ZyraAuth.isSignedIn) return null;
    try {
      final raw = await _rpc(
        'zyra_record_identity_verification_consent',
        expectedUserId: expectedUserId,
        params: {
          'p_consent_version': kIdentityVerificationConsentVersion,
          'p_granted': granted,
        },
      );
      return _stateFromRpc(raw);
    } catch (error) {
      debugPrint(
        'ZYRA: identity-verification consent was not recorded '
        '(granted=$granted). No verification grant was made '
        '(${error.runtimeType}).',
      );
      return null;
    }
  }

  static Future<bool> deleteMyUnstartedAttempt({String? expectedUserId}) async {
    if (expectedUserId == null && !ZyraAuth.isSignedIn) return false;
    try {
      return await _rpc(
            'zyra_delete_my_unstarted_identity_verification_attempt',
            expectedUserId: expectedUserId,
          ) ==
          true;
    } catch (error) {
      debugPrint(
        'ZYRA: verification-attempt deletion failed (${error.runtimeType}).',
      );
      return false;
    }
  }

  static Future<ZyraVerificationLaunchOutcome> launchProvider() =>
      _provider.launch();

  static ZyraIdentityVerificationState? _stateFromRpc(Object? raw) {
    return ZyraIdentityVerificationState.fromRpc(raw);
  }

  @visibleForTesting
  static void setProviderForTesting(
    ZyraIdentityVerificationProviderAdapter provider,
  ) => _provider = provider;

  @visibleForTesting
  static void resetProviderForTesting() =>
      _provider = const ZyraUnavailableIdentityVerificationProvider();
}
