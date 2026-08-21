// Thin wrapper around Supabase Auth — OA-102.
//
// Apple + Google remain the normal sign-in methods and ZYRA never stores a
// password. Founder decision 2026-08-20 adds two recovery protections:
// another Apple/Google identity can be linked to the SAME Supabase user, and
// an already-authenticated member can verify a recovery email for one-time-
// code sign-in. Recovery OTP requests always set shouldCreateUser=false, so
// an unknown address cannot manufacture a second Seeker account.
//
// Sign-up and sign-in are the same action with OAuth — there's no
// separate "create account" step for the user to choose. A first-time
// Google/Apple sign-in produces a Supabase auth.users row with no
// matching `profiles` row yet; ZyraSessionRouter already treats that
// as "onboarding incomplete" and routes to Role Selection, so this
// file doesn't need to know or care whether it's someone's first
// sign-in or their fifth.

import 'dart:convert';
import '../state/app_state.dart';
import 'zyra_app_lock.dart';
import 'zyra_image_cache.dart';
import 'zyra_local_prefs.dart';
import 'zyra_consent_service.dart';
import 'zyra_photo_service.dart';
import 'zyra_unlock_service.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/oauth_config.dart';
import '../main.dart';

enum ZyraAuthOutcome { success, cancelled, error }

class ZyraAuthResult {
  final ZyraAuthOutcome outcome;
  final String? errorMessage;
  const ZyraAuthResult._(this.outcome, this.errorMessage);

  const ZyraAuthResult.success() : this._(ZyraAuthOutcome.success, null);
  const ZyraAuthResult.cancelled() : this._(ZyraAuthOutcome.cancelled, null);
  const ZyraAuthResult.error(String message)
    : this._(ZyraAuthOutcome.error, message);
}

class ZyraAuth {
  ZyraAuth._();

  static User? get currentUser => supabase.auth.currentUser;
  static bool get isSignedIn => currentUser != null;

  static Set<String> get linkedProviders => {
    for (final identity in currentUser?.identities ?? const <UserIdentity>[])
      identity.provider,
  };

  static bool get hasLinkedOAuth =>
      linkedProviders.contains('apple') || linkedProviders.contains('google');

  static String? get recoveryEmail {
    for (final identity in currentUser?.identities ?? const <UserIdentity>[]) {
      if (identity.provider != 'email') continue;
      final email = identity.identityData?['email'];
      if (email is String && email.trim().isNotEmpty) return email.trim();
    }
    return null;
  }

  static String? providerEmail(String provider) {
    for (final identity in currentUser?.identities ?? const <UserIdentity>[]) {
      if (identity.provider != provider) continue;
      final email = identity.identityData?['email'];
      if (email is String && email.trim().isNotEmpty) return email.trim();
    }
    return null;
  }

  static bool isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  /// First name supplied by Apple/Google, when the provider made one
  /// available. Apple only returns the name on the first authorisation, so
  /// [signInWithApple] stores that one-time value in auth metadata for future
  /// launches. The onboarding question still lets the member correct it.
  static String? get onboardingFirstName =>
      firstNameFromMetadata(currentUser?.userMetadata);

  static String? firstNameFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    for (final key in const ['given_name', 'first_name', 'name', 'full_name']) {
      final firstName = _normaliseFirstName(metadata[key]);
      if (firstName != null) return firstName;
    }
    return null;
  }

  static String? _normaliseFirstName(Object? value) {
    if (value is! String) return null;
    final clean = value.trim();
    if (clean.isEmpty) return null;
    return clean.split(RegExp(r'\s+')).first;
  }

  static Future<void> _rememberProviderFirstName(String? providerName) async {
    final firstName = _normaliseFirstName(providerName);
    if (firstName == null || onboardingFirstName != null) return;
    try {
      await supabase.auth.updateUser(
        UserAttributes(data: {'given_name': firstName}),
      );
    } catch (error) {
      // A greeting must never turn a successful sign-in into a failure.
      // The member can still enter their name on the first question.
      debugPrint('ZYRA provider first-name metadata save failed: $error');
    }
  }

  static Future<ZyraAuthResult> signInWithGoogle() async {
    if (!OAuthConfig.isGoogleConfigured) {
      return const ZyraAuthResult.error(
        'Google sign-in isn\'t set up yet on this build — the Founder needs to add real Google OAuth client IDs.',
      );
    }
    try {
      final googleSignIn = GoogleSignIn(
        clientId: OAuthConfig.googleIosClientId,
        serverClientId: OAuthConfig.googleWebClientId,
        scopes: const ['email'],
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return const ZyraAuthResult.cancelled();

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return const ZyraAuthResult.error(
          "That didn't work. Please try again.",
        );
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      await _rememberProviderFirstName(googleUser.displayName);
      return const ZyraAuthResult.success();
    } on AuthException catch (e) {
      return ZyraAuthResult.error(_mapError(e));
    } catch (_) {
      return const ZyraAuthResult.error(
        'Having trouble connecting. Check your connection and try again.',
      );
    }
  }

  static Future<ZyraAuthResult> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        return const ZyraAuthResult.error(
          "That didn't work. Please try again.",
        );
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      await _rememberProviderFirstName(credential.givenName);
      return const ZyraAuthResult.success();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const ZyraAuthResult.cancelled();
      }
      return const ZyraAuthResult.error("That didn't work. Please try again.");
    } on AuthException catch (e) {
      return ZyraAuthResult.error(_mapError(e));
    } catch (_) {
      return const ZyraAuthResult.error(
        'Having trouble connecting. Check your connection and try again.',
      );
    }
  }

  /// Adds Google as another way into the CURRENT ZYRA account. This is not
  /// a sign-in and must never be replaced with signInWithIdToken here: the
  /// latter can switch sessions and strand the original profile. Supabase's
  /// linkIdentityWithIdToken keeps both provider identities under one user id.
  static Future<ZyraAuthResult> linkGoogleIdentity() async {
    if (!isSignedIn) {
      return const ZyraAuthResult.error(
        'Sign in again before adding a backup method.',
      );
    }
    if (linkedProviders.contains('google')) {
      return const ZyraAuthResult.success();
    }
    if (!OAuthConfig.isGoogleConfigured) {
      return const ZyraAuthResult.error(
        "Google sign-in isn't set up yet on this build.",
      );
    }

    try {
      final googleSignIn = GoogleSignIn(
        clientId: OAuthConfig.googleIosClientId,
        serverClientId: OAuthConfig.googleWebClientId,
        scopes: const ['email'],
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return const ZyraAuthResult.cancelled();
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return const ZyraAuthResult.error(
          "That didn't work. Please try again.",
        );
      }

      await supabase.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      return const ZyraAuthResult.success();
    } on AuthException catch (error) {
      return ZyraAuthResult.error(_mapLinkError(error));
    } catch (_) {
      return const ZyraAuthResult.error(
        'Having trouble connecting. Check your connection and try again.',
      );
    }
  }

  /// Apple equivalent of [linkGoogleIdentity]. The nonce is required for
  /// replay protection exactly as it is in the normal Apple sign-in flow.
  static Future<ZyraAuthResult> linkAppleIdentity() async {
    if (!isSignedIn) {
      return const ZyraAuthResult.error(
        'Sign in again before adding a backup method.',
      );
    }
    if (linkedProviders.contains('apple')) {
      return const ZyraAuthResult.success();
    }

    try {
      final rawNonce = _generateNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _sha256(rawNonce),
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        return const ZyraAuthResult.error(
          "That didn't work. Please try again.",
        );
      }

      await supabase.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      return const ZyraAuthResult.success();
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const ZyraAuthResult.cancelled();
      }
      return const ZyraAuthResult.error("That didn't work. Please try again.");
    } on AuthException catch (error) {
      return ZyraAuthResult.error(_mapLinkError(error));
    } catch (_) {
      return const ZyraAuthResult.error(
        'Having trouble connecting. Check your connection and try again.',
      );
    }
  }

  /// Starts an authenticated email change. Supabase confirms the new address
  /// and, when Secure Email Change is enabled, also confirms the current one.
  /// Once complete it creates/updates the email identity on this same user.
  static Future<ZyraAuthResult> requestRecoveryEmail(String email) async {
    final normalised = email.trim().toLowerCase();
    if (!isSignedIn) {
      return const ZyraAuthResult.error(
        'Sign in again before adding a recovery email.',
      );
    }
    if (!hasLinkedOAuth) {
      return const ZyraAuthResult.error(
        'A recovery email can only be added to an Apple or Google account.',
      );
    }
    if (!isValidEmail(normalised)) {
      return const ZyraAuthResult.error('Enter a valid email address.');
    }
    if (currentUser?.email?.toLowerCase() == normalised) {
      return const ZyraAuthResult.error(
        'Choose a different email address for recovery.',
      );
    }

    try {
      await supabase.auth.updateUser(UserAttributes(email: normalised));
      return const ZyraAuthResult.success();
    } on AuthException catch (error) {
      return ZyraAuthResult.error(_mapEmailError(error));
    } catch (_) {
      return const ZyraAuthResult.error(
        'Having trouble connecting. Check your connection and try again.',
      );
    }
  }

  static Future<ZyraAuthResult> verifyRecoveryEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      await supabase.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: code.trim(),
        type: OtpType.emailChange,
      );
      return const ZyraAuthResult.success();
    } on AuthException catch (error) {
      return ZyraAuthResult.error(_mapEmailError(error));
    } catch (_) {
      return const ZyraAuthResult.error(
        'Having trouble connecting. Check your connection and try again.',
      );
    }
  }

  static Future<bool> isRecoveryEmailVerified(String email) async {
    final normalised = email.trim().toLowerCase();
    try {
      final identities = await supabase.auth.getUserIdentities();
      return identities.any((identity) {
        if (identity.provider != 'email') return false;
        return identity.identityData?['email']?.toString().toLowerCase() ==
            normalised;
      });
    } catch (_) {
      return recoveryEmail?.toLowerCase() == normalised;
    }
  }

  /// Passwordless recovery only. shouldCreateUser=false is the critical
  /// duplicate-account guard: a typo or unknown address gets the same calm UI
  /// response but can never create a new auth.users/profile identity.
  static Future<ZyraAuthResult> sendRecoverySignInCode(String email) async {
    final normalised = email.trim().toLowerCase();
    if (!isValidEmail(normalised)) {
      return const ZyraAuthResult.error('Enter a valid email address.');
    }
    try {
      await supabase.auth.signInWithOtp(
        email: normalised,
        shouldCreateUser: false,
      );
      return const ZyraAuthResult.success();
    } on AuthException catch (error) {
      return ZyraAuthResult.error(_mapEmailError(error));
    } catch (_) {
      return const ZyraAuthResult.error(
        'Having trouble connecting. Check your connection and try again.',
      );
    }
  }

  static Future<ZyraAuthResult> verifyRecoverySignInCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await supabase.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: code.trim(),
        type: OtpType.email,
      );
      if (response.session == null || response.user == null) {
        return const ZyraAuthResult.error(
          "That code couldn't sign you in. Please request a new one.",
        );
      }
      return const ZyraAuthResult.success();
    } on AuthException catch (error) {
      return ZyraAuthResult.error(_mapEmailError(error));
    } catch (_) {
      return const ZyraAuthResult.error(
        'Having trouble connecting. Check your connection and try again.',
      );
    }
  }

  // 2026-07-19: guarded against overlapping calls, same root cause as the
  // developer_access_screen.dart crash fixed earlier today. Any duplicate/
  // overlapping tap on a Sign Out button (profile_screen.dart,
  // wali_profile_screen.dart both call this with no guard of their own)
  // raced two concurrent supabase.auth.signOut() calls at the native
  // layer and killed the app with no Dart exception. Fixing it here,
  // inside ZyraAuth itself, protects every call site — present and
  // future — rather than requiring each screen to remember its own guard.
  static bool _signingOut = false;

  static Future<void> signOut() async {
    if (_signingOut) return;
    _signingOut = true;
    try {
      await supabase.auth.signOut();
      // Drop the cached gender. Without this, the next person to sign in
      // on this device gets the previous user's gradient for one frame —
      // visibly wrong, and a small leak of someone else's data.
      //
      // This is also what makes the gendered default in main.dart's
      // `builder:` safe: after sign-out the cache is empty, so
      // genderGradient(null) returns the neutral gradient it used to
      // hardcode. Nothing is stale because nothing is kept.
      await ZyraLocalPrefs.clear();
      AppState.instance.gender = null;
      // Unlocks are per-account. Without this the next person to sign in
      // on this device would see the previous user's profiles marked
      // "View Compatibility" — someone else's purchases, on their own
      // screen.
      ZyraUnlockService.clearForSignOut();
      // ADDED 2026-08-04 with the Article 9 consent log. Without this the
      // next account signed in on this device inherits the previous one's
      // cached consent answer — which would mean writing special-category
      // data for someone who never agreed to it.
      ZyraConsentService.clearForSignOut();
      // ADDED 2026-08-07 with App Lock. ZyraLocalPrefs.clear() above already
      // removes the stored preference, but the lock also holds it IN MEMORY
      // — and this session keeps running after sign-out. Without this the
      // next person to sign in on this device meets a lock screen for a
      // setting that no longer exists, and worse, one they can pass, which
      // would read as ZYRA endorsing them.
      ZyraAppLock.instance.clearForSignOut();
      // ADDED 2026-08-15 (DR-ZYRA-169). The disk image cache holds
      // photos the signed-out account was allowed to see; the next
      // account may not share that visibility, so the cache dies with
      // the session — disk and RAM both.
      await ZyraImageCache.clearForSignOut();
      // And the session's minted signed URLs — bearer strings belonging
      // to the account that minted them. In-memory only, but this
      // process keeps running after sign-out, so they are dropped
      // explicitly like everything else in this block.
      ZyraPhotoService.clearUrlMemoForSignOut();
    } finally {
      _signingOut = false;
    }
  }

  /// #22 — real account deletion. Cleans up the user's own photo files
  /// in Storage first (while the session is still valid — the
  /// `profile-photos` bucket's RLS delete policy is scoped to the
  /// caller's own folder), then calls delete_own_account(), which
  /// deletes the auth.users row and cascades through every table that
  /// references it (profiles, matches, messages, wali_links,
  /// subscriptions, notifications, etc. — see
  /// 20260726170000_delete_own_account.sql for the full verified
  /// list). Signs out locally afterward regardless of RPC outcome,
  /// since the session is meaningless either way at that point.
  ///
  /// Returns true on success. On failure, the account is NOT deleted
  /// (the RPC's own exception aborts its transaction) — safe to retry.
  static Future<bool> deleteAccount() async {
    final user = currentUser;
    if (user == null) return false;
    try {
      try {
        final rows =
            await supabase
                    .from('profile_photos')
                    .select('storage_path')
                    .eq('user_id', user.id)
                as List;
        final paths = rows
            .map((r) => (r as Map<String, dynamic>)['storage_path'] as String)
            .toList();
        if (paths.isNotEmpty) {
          await supabase.storage.from('profile-photos').remove(paths);
        }
      } catch (_) {
        // Best-effort — a photo-cleanup failure shouldn't block account
        // deletion itself; delete_own_account()'s own storage.objects
        // cleanup by path prefix is a second, server-side attempt at
        // the same thing.
      }
      await supabase.rpc('delete_own_account');
      await signOut();
      return true;
    } catch (e) {
      // 2026-08-12: an erasure failure was indistinguishable from a
      // refusal, with nothing logged anywhere (CLAUDE.md §3). Still
      // returns false — the UI copy handles it — but no longer invisible.
      debugPrint('ZYRA delete_own_account failed: $e');
      return false;
    }
  }

  /// DEVELOPER MODE ONLY — password sign-in for the seeded test
  /// accounts (dev.*@zyra.test), so the founder can switch scenarios
  /// without OAuth being configured. This is NOT a user-facing auth
  /// method (Google + Apple only, per Founder instruction 2026-07-18):
  /// it is only reachable from DeveloperAccessScreen, and the seeded
  /// accounts exist solely in the dev/preview database. Relies on the
  /// email provider remaining enabled server-side in Supabase Auth
  /// settings (it is by default) even though no email UI exists.
  static Future<ZyraAuthResult> signInWithTestAccount(
    String email,
    String password,
  ) async {
    try {
      if (isSignedIn) await supabase.auth.signOut();
      await supabase.auth.signInWithPassword(email: email, password: password);
      return const ZyraAuthResult.success();
    } on AuthException catch (e) {
      return ZyraAuthResult.error('Test sign-in failed: ${e.message}');
    } catch (_) {
      return const ZyraAuthResult.error(
        'Test sign-in failed — check the connection.',
      );
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static String _mapLinkError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('manual') ||
        message.contains('linking') && message.contains('disabled')) {
      return 'Backup sign-in is not enabled on this build yet.';
    }
    if (message.contains('already') || message.contains('identity')) {
      return 'That sign-in is already connected to a ZYRA account.';
    }
    return _mapError(error);
  }

  static String _mapEmailError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('expired') ||
        message.contains('invalid') ||
        message.contains('token')) {
      return "That code has expired or isn't correct. Request a new one.";
    }
    if (message.contains('rate') || message.contains('seconds')) {
      return 'Please wait a minute before requesting another code.';
    }
    if (message.contains('already') ||
        message.contains('exists') ||
        message.contains('registered')) {
      return 'That email is already connected to another ZYRA account.';
    }
    return _mapError(error);
  }

  /// Maps Supabase's own error strings onto ERROR_AND_EMPTY_STATE_
  /// STANDARD's Category 2 copy (DR-ZYRA-080). Worth re-checking
  /// against real responses once OAuth is actually configured and
  /// tested — this is written defensively, not from observed errors.
  static String _mapError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('provider') &&
        (msg.contains('not enabled') || msg.contains('disabled'))) {
      return "This sign-in method isn't turned on yet for this build.";
    }
    return "Something didn't quite work. Please try again — and if it keeps happening, let us know.";
  }
}
