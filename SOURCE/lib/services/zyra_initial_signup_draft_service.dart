import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/supabase_config.dart';
import '../main.dart';
import '../models/zyra_initial_signup_draft.dart';
import '../models/zyra_signup_membership_choice.dart';
import '../state/app_state.dart';
import 'zyra_identity_verification_service.dart';
import 'zyra_internal_preview_client.dart';
import 'zyra_profile_service.dart';
import 'zyra_account_state.dart';
import 'zyra_photo_service.dart';

abstract interface class ZyraSignupDraftStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// No web/plain-preferences fallback. Apple values never sync or migrate to
/// another device. Android uses the package's native Keystore-backed store.
class ZyraNativeSignupDraftStore implements ZyraSignupDraftStore {
  static const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      storageNamespace: 'zyra_signup_draft',
      resetOnError: false,
      migrateOnAlgorithmChange: false,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
  );

  void _requireNative() {
    if (kIsWeb ||
        ![
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.android,
        ].contains(defaultTargetPlatform)) {
      throw StateError(
        'Protected signup recovery is unavailable on this device.',
      );
    }
  }

  @override
  Future<String?> read(String key) {
    _requireNative();
    return storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) {
    _requireNative();
    return storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) {
    _requireNative();
    return storage.delete(key: key);
  }
}

/// Injectable persistence boundary. Every operation is serialized and checks
/// the captured principal and account epoch again after asynchronous work.
/// Already-dispatched native writes cannot be rolled back. No values are logged.
class ZyraSignupDraftRepository {
  final ZyraSignupDraftStore store;
  final String backend;
  final String? Function() currentUserId;
  final bool Function() isPreview;
  final int Function() currentGeneration;
  Future<void> _tail = Future<void>.value();
  final Set<String> _signingOut = {};

  ZyraSignupDraftRepository({
    required this.store,
    required this.backend,
    required this.currentUserId,
    required this.isPreview,
    int Function()? currentGeneration,
  }) : currentGeneration =
           currentGeneration ?? (() => ZyraAccountState.generation);

  String keyFor(String userId) =>
      'zyra.initial_signup.v1.${sha256.convert(utf8.encode('$backend\n$userId'))}';

  String membershipIntentKeyFor(String userId) =>
      'zyra.signup_membership_intent.v1.${sha256.convert(utf8.encode('$backend\n$userId'))}';

  String pendingSeekerFinalizationKeyFor(String userId) =>
      'zyra.signup_pending_seeker.v1.${sha256.convert(utf8.encode('$backend\n$userId'))}';

  String pendingGuardianFinalizationKeyFor(String userId) =>
      'zyra.signup_pending_guardian.v1.${sha256.convert(utf8.encode('$backend\n$userId'))}';

  void _requirePhotoOwner(String userId, ZyraInitialSignupDraft draft) {
    final path = draft.firstPhotoPath;
    if (path != null &&
        !ZyraInitialSignupDraft.isPrivatePhotoPath(
          path,
          expectedUserId: userId,
        )) {
      throw const FormatException('Invalid signup photo reference.');
    }
  }

  void requireOwner(String userId) {
    if (isPreview() ||
        userId.isEmpty ||
        currentUserId() != userId ||
        _signingOut.contains(userId)) {
      throw StateError('Signup account changed. Sign in again.');
    }
  }

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  void _requireOperationOwner(String userId, int generation) {
    requireOwner(userId);
    if (currentGeneration() != generation) {
      throw StateError('Signup account changed. Sign in again.');
    }
  }

  Future<ZyraInitialSignupDraft?> read(String userId) {
    // Capture before enqueueing, not inside the queue: returning to the same
    // account must not release an older session's pending operation.
    final generation = currentGeneration();
    return _serial(() async {
      _requireOperationOwner(userId, generation);
      final raw = await store.read(keyFor(userId));
      _requireOperationOwner(userId, generation);
      if (raw == null) return null;
      if (raw.length > 2048) {
        throw const FormatException('Invalid signup draft.');
      }
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid signup draft.');
      }
      final draft = ZyraInitialSignupDraft.fromJson(value);
      _requirePhotoOwner(userId, draft);
      return draft;
    });
  }

  Future<void> save(String userId, ZyraInitialSignupDraft draft) {
    final generation = currentGeneration();
    return _serial(() async {
      _requireOperationOwner(userId, generation);
      if (!draft.isValid()) {
        throw const FormatException('Invalid signup draft.');
      }
      _requirePhotoOwner(userId, draft);
      final encoded = jsonEncode(draft.toJson());
      await store.write(keyFor(userId), encoded);
      _requireOperationOwner(userId, generation);
      final confirmed = await store.read(keyFor(userId));
      _requireOperationOwner(userId, generation);
      if (confirmed != encoded) {
        throw StateError('Protected signup save could not be confirmed.');
      }
    });
  }

  Future<void> clear(String userId) {
    final generation = currentGeneration();
    return _serial(() async {
      _requireOperationOwner(userId, generation);
      await store.delete(keyFor(userId));
      _requireOperationOwner(userId, generation);
      final remaining = await store.read(keyFor(userId));
      _requireOperationOwner(userId, generation);
      if (remaining != null) {
        throw StateError('Signup erasure could not be confirmed.');
      }
    });
  }

  /// A same-device retry marker only: no form data, photo reference, commercial
  /// choice, identity proof or entitlement. Unlike the form draft, this survives
  /// explicit sign-out so a partly-created account cannot bypass its retry.
  Future<bool> readPendingSeekerFinalization(String userId) =>
      _readPendingFinalization(userId, pendingSeekerFinalizationKeyFor);

  Future<bool> readPendingGuardianFinalization(String userId) =>
      _readPendingFinalization(userId, pendingGuardianFinalizationKeyFor);

  Future<bool> _readPendingFinalization(
    String userId,
    String Function(String) keyForRole,
  ) {
    final generation = currentGeneration();
    return _serial(() async {
      _requireOperationOwner(userId, generation);
      final raw = await store.read(keyForRole(userId));
      _requireOperationOwner(userId, generation);
      if (raw == null) return false;
      if (raw.length > 64) {
        throw const FormatException('Invalid signup recovery marker.');
      }
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic> ||
          value.length != 2 ||
          value['version'] is! int ||
          value['version'] != 1 ||
          value['pending'] != true) {
        throw const FormatException('Invalid signup recovery marker.');
      }
      return true;
    });
  }

  Future<void> beginPendingSeekerFinalization(String userId) =>
      _beginPendingFinalization(userId, pendingSeekerFinalizationKeyFor);

  Future<void> beginPendingGuardianFinalization(String userId) =>
      _beginPendingFinalization(userId, pendingGuardianFinalizationKeyFor);

  Future<void> _beginPendingFinalization(
    String userId,
    String Function(String) keyForRole,
  ) {
    final generation = currentGeneration();
    return _serial(() async {
      _requireOperationOwner(userId, generation);
      const encoded = '{"version":1,"pending":true}';
      final key = keyForRole(userId);
      await store.write(key, encoded);
      _requireOperationOwner(userId, generation);
      final confirmed = await store.read(key);
      _requireOperationOwner(userId, generation);
      if (confirmed != encoded) {
        throw StateError('Signup recovery marker could not be confirmed.');
      }
    });
  }

  Future<void> clearPendingSeekerFinalization(String userId) =>
      _clearPendingFinalization(userId, pendingSeekerFinalizationKeyFor);

  Future<void> clearPendingGuardianFinalization(String userId) =>
      _clearPendingFinalization(userId, pendingGuardianFinalizationKeyFor);

  Future<void> _clearPendingFinalization(
    String userId,
    String Function(String) keyForRole,
  ) {
    final generation = currentGeneration();
    return _serial(() async {
      _requireOperationOwner(userId, generation);
      final key = keyForRole(userId);
      await store.delete(key);
      _requireOperationOwner(userId, generation);
      final remaining = await store.read(key);
      _requireOperationOwner(userId, generation);
      if (remaining != null) {
        throw StateError(
          'Signup recovery marker erasure could not be confirmed.',
        );
      }
    });
  }

  /// A private preference, never a local replacement for store/server proof.
  Future<ZyraSignupMembershipIntent?> readMembershipIntent(String userId) {
    final generation = currentGeneration();
    return _serial(() async {
      _requireOperationOwner(userId, generation);
      final raw = await store.read(membershipIntentKeyFor(userId));
      _requireOperationOwner(userId, generation);
      if (raw == null) return null;
      if (raw.length > 512) {
        throw const FormatException('Invalid membership intent.');
      }
      return ZyraSignupMembershipIntent.fromJson(jsonDecode(raw));
    });
  }

  Future<void> saveMembershipIntent(
    String userId,
    ZyraSignupMembershipIntent intent,
  ) {
    final generation = currentGeneration();
    return _serial(() async {
      _requireOperationOwner(userId, generation);
      if (!intent.isValid) {
        throw const FormatException('Invalid membership intent.');
      }
      final encoded = jsonEncode(intent.toJson());
      await store.write(membershipIntentKeyFor(userId), encoded);
      _requireOperationOwner(userId, generation);
      final confirmed = await store.read(membershipIntentKeyFor(userId));
      _requireOperationOwner(userId, generation);
      if (confirmed != encoded) {
        throw StateError('Protected membership choice could not be confirmed.');
      }
    });
  }

  /// Latch synchronously, before queued saves can start. The auth operation
  /// runs inside this queue so no stale write can follow erasure before logout.
  Future<void> signOut(String userId, Future<void> Function() logout) {
    final generation = currentGeneration();
    requireOwner(userId);
    _signingOut.add(userId);
    void requireSignOutOwner() {
      // ZyraAuth.beginSignOut already invalidated the account epoch before
      // reaching this method. Its intentional signing-out state is allowed;
      // only a subsequent principal/epoch replacement invalidates this work.
      if (isPreview() ||
          currentUserId() != userId ||
          currentGeneration() != generation) {
        throw StateError('Signup account changed.');
      }
    }

    return _serial(() async {
      try {
        requireSignOutOwner();
        await store.delete(keyFor(userId));
        requireSignOutOwner();
        final remaining = await store.read(keyFor(userId));
        requireSignOutOwner();
        if (remaining != null) {
          throw StateError('Signup erasure could not be confirmed.');
        }
        await store.delete(membershipIntentKeyFor(userId));
        requireSignOutOwner();
        final intent = await store.read(membershipIntentKeyFor(userId));
        requireSignOutOwner();
        if (intent != null) {
          throw StateError('Membership choice erasure could not be confirmed.');
        }
        await logout();
      } finally {
        _signingOut.remove(userId);
      }
    });
  }
}

abstract final class ZyraInitialSignupDraftService {
  static bool get supportedOnThisPlatform =>
      !kIsWeb &&
      [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform);
  static ZyraSignupDraftRepository? _repository;
  static ZyraSignupDraftRepository get repository =>
      _repository ??= ZyraSignupDraftRepository(
        store: ZyraNativeSignupDraftStore(),
        backend: SupabaseConfig.url,
        currentUserId: () => supabase.auth.currentUser?.id,
        isPreview: () => ZyraInternalPreviewClient.isActive,
      );

  static String captureUserId() {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in again to continue setup.');
    repository.requireOwner(id);
    return id;
  }

  static Future<ZyraSignupMembershipIntent?> readMembershipIntent({
    required String expectedUserId,
  }) async {
    if (!supportedOnThisPlatform || ZyraInternalPreviewClient.isActive) {
      return null;
    }
    return repository.readMembershipIntent(expectedUserId);
  }

  static Future<String?> finalize(
    String userId,
    ZyraInitialSignupDraft draft,
  ) async {
    final generation = ZyraAccountState.generation;
    void requireOwner() {
      repository.requireOwner(userId);
      if (ZyraAccountState.isSigningOut ||
          ZyraAccountState.generation != generation) {
        throw StateError('Signup account changed.');
      }
    }

    try {
      requireOwner();
      if (!draft.awaitsVerification || !draft.isValid()) {
        return 'Your saved account details need to be completed first.';
      }
      repository._requirePhotoOwner(userId, draft);
      final state = await ZyraIdentityVerificationService.fetchMyState(
        expectedUserId: userId,
      );
      requireOwner();
      if (state?.allowsApp != true) {
        return 'Your identity must be verified before continuing.';
      }
      // Retain only the selected commercial preference. Identity details are
      // erased after finalisation; this value does not activate paid or Basic
      // access, record a receipt, or mark a joining fee as paid.
      await repository.saveMembershipIntent(
        userId,
        ZyraSignupMembershipIntent(
          role: draft.role,
          choice: draft.membershipChoice!,
        ),
      );
      requireOwner();
      if (draft.role == ZyraSignupRole.seeker) {
        await repository.beginPendingSeekerFinalization(userId);
      } else {
        await repository.beginPendingGuardianFinalization(userId);
      }
      requireOwner();
      final error = draft.role == ZyraSignupRole.seeker
          ? await ZyraProfileService.createSeekerProfile(
              firstName: draft.firstName!,
              gender: draft.gender!,
              dob: draft.dob!,
              expectedUserId: userId,
            )
          : await ZyraProfileService.createWaliProfile(
              firstName: draft.firstName!,
              gender: draft.gender!,
              dob: draft.dob!,
              expectedUserId: userId,
              publishOnCreate: false,
            );
      requireOwner();
      if (error != null) return error;
      final role = draft.role == ZyraSignupRole.seeker ? 'seeker' : 'wali';
      final savedSurname = await ZyraProfileService.savePublicSurname(
        draft.lastName!,
        expectedUserId: userId,
        expectedRole: role,
        expectedGeneration: generation,
      );
      requireOwner();
      if (!savedSurname) {
        return "We couldn't save your last name. Your details are kept here so you can retry.";
      }
      final session = supabase.auth.currentSession;
      if (session?.user.id != userId) {
        throw StateError('Signup account changed.');
      }
      final profile = await supabase
          .from('profiles')
          .select('id, role, first_name, surname_line')
          .eq('id', userId)
          .setHeader('Authorization', 'Bearer ${session!.accessToken}')
          .maybeSingle();
      requireOwner();
      if (profile?['id'] != userId ||
          profile?['role'] != role ||
          profile?['first_name'] != draft.firstName ||
          profile?['surname_line'] != draft.lastName) {
        return "We couldn't confirm your account setup. Please try again.";
      }
      final confirmedPhotos =
          await ZyraPhotoService.ensureSignupFirstPhotoConfirmed(
            draft.firstPhotoPath!,
            expectedUserId: userId,
            expectedGeneration: generation,
          );
      requireOwner();
      if (confirmedPhotos == null || confirmedPhotos.isEmpty) {
        return "We couldn't confirm your first photo. Your setup is kept here so you can retry.";
      }
      // A Guardian's row is still incomplete here. A selected URL alone is
      // not a saved photo: own Storage and row readback must pass before the
      // separate publication operation can run.
      if (draft.role == ZyraSignupRole.guardian) {
        final published = await ZyraProfileService.setProfileComplete(
          true,
          expectedUserId: userId,
        );
        requireOwner();
        if (!published) {
          return "We couldn't confirm your Guardian setup. Please try again.";
        }
      }
      await repository.clear(userId);
      requireOwner();
      if (draft.role == ZyraSignupRole.seeker) {
        await repository.clearPendingSeekerFinalization(userId);
      } else {
        await repository.clearPendingGuardianFinalization(userId);
      }
      requireOwner();
      AppState.instance.setProfilePhotos(confirmedPhotos);
      return null;
    } catch (_) {
      debugPrint(
        'ZYRA: protected signup finalization failed; no local admission granted.',
      );
      return "We couldn't finish your saved setup. Please try again.";
    }
  }

  @visibleForTesting
  static void setRepositoryForTesting(ZyraSignupDraftRepository? value) =>
      _repository = value;
}
