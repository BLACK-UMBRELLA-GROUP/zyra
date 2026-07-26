// Thin wrapper around Supabase Auth — OA-102.
//
// Google + Apple ONLY (2026-07-18, Founder instruction): no password,
// no email login, no phone login, no magic link. Both providers use
// the native ID-token flow (google_sign_in / sign_in_with_apple) into
// Supabase's signInWithIdToken, rather than a browser OAuth redirect —
// better native UX, and avoids configuring deep-link redirect URLs on
// every platform.
//
// Sign-up and sign-in are the same action with OAuth — there's no
// separate "create account" step for the user to choose. A first-time
// Google/Apple sign-in produces a Supabase auth.users row with no
// matching `profiles` row yet; ZyraSessionRouter already treats that
// as "onboarding incomplete" and routes to Role Selection, so this
// file doesn't need to know or care whether it's someone's first
// sign-in or their fifth.

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
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
  const ZyraAuthResult.error(String message) : this._(ZyraAuthOutcome.error, message);
}

class ZyraAuth {
  ZyraAuth._();

  static User? get currentUser => supabase.auth.currentUser;
  static bool get isSignedIn => currentUser != null;

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
        return const ZyraAuthResult.error("That didn't work. Please try again.");
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      return const ZyraAuthResult.success();
    } on AuthException catch (e) {
      return ZyraAuthResult.error(_mapError(e));
    } catch (_) {
      return const ZyraAuthResult.error('Having trouble connecting. Check your connection and try again.');
    }
  }

  static Future<ZyraAuthResult> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        return const ZyraAuthResult.error("That didn't work. Please try again.");
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      return const ZyraAuthResult.success();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return const ZyraAuthResult.cancelled();
      return const ZyraAuthResult.error("That didn't work. Please try again.");
    } on AuthException catch (e) {
      return ZyraAuthResult.error(_mapError(e));
    } catch (_) {
      return const ZyraAuthResult.error('Having trouble connecting. Check your connection and try again.');
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
    } finally {
      _signingOut = false;
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
  static Future<ZyraAuthResult> signInWithTestAccount(String email, String password) async {
    try {
      if (isSignedIn) await supabase.auth.signOut();
      await supabase.auth.signInWithPassword(email: email, password: password);
      return const ZyraAuthResult.success();
    } on AuthException catch (e) {
      return ZyraAuthResult.error('Test sign-in failed: ${e.message}');
    } catch (_) {
      return const ZyraAuthResult.error('Test sign-in failed — check the connection.');
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();

  /// Maps Supabase's own error strings onto ERROR_AND_EMPTY_STATE_
  /// STANDARD's Category 2 copy (DR-ZYRA-080). Worth re-checking
  /// against real responses once OAuth is actually configured and
  /// tested — this is written defensively, not from observed errors.
  static String _mapError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('provider') && (msg.contains('not enabled') || msg.contains('disabled'))) {
      return "This sign-in method isn't turned on yet for this build.";
    }
    return "Something didn't quite work. Please try again — and if it keeps happening, let us know.";
  }
}
