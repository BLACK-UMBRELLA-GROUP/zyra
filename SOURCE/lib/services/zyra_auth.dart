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

import 'dart:async';
import 'dart:convert';
import 'zyra_account_state.dart';
import 'zyra_developer_access.dart';
import 'zyra_internal_preview_client.dart';
import 'zyra_initial_signup_draft_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/oauth_config.dart';
import '../main.dart';

enum ZyraAuthOutcome { success, cancelled, error }

class ZyraAuthResult {
  final ZyraAuthOutcome outcome;
  final String? errorMessage;
  // Binds recovery's local handoff to the principal returned by Auth. This
  // is not profile, identity-verification or membership authorization.
  final String? authenticatedUserId;
  const ZyraAuthResult._(
    this.outcome,
    this.errorMessage, [
    this.authenticatedUserId,
  ]);

  const ZyraAuthResult.success({String? authenticatedUserId})
    : this._(ZyraAuthOutcome.success, null, authenticatedUserId);
  const ZyraAuthResult.cancelled() : this._(ZyraAuthOutcome.cancelled, null);
  const ZyraAuthResult.error(String message)
    : this._(ZyraAuthOutcome.error, message);
}

class ZyraAuth {
  ZyraAuth._();

  static const _googleScopes = <String>['email'];
  static Future<void>? _googleInitialization;
  static Future<void> Function()? _googleSignOutForTesting;

  static User? get currentUser => supabase.auth.currentUser;
  static bool get isSignedIn => currentUser != null;
  static Stream<AuthState> get authStateChanges =>
      supabase.auth.onAuthStateChange;

  static Set<String> get linkedProviders {
    final providers = <String>{
      for (final identity in currentUser?.identities ?? const <UserIdentity>[])
        identity.provider.toLowerCase(),
    };
    final appMetadata = currentUser?.appMetadata;

    void addProvider(Object? value) {
      if (value is! String) return;
      final provider = value.trim().toLowerCase();
      if (provider.isNotEmpty) providers.add(provider);
    }

    // Supabase can expose the authoritative provider list only through
    // app_metadata (not identities), including immediately after an OAuth
    // exchange. This is provider detection, not an authorization decision.
    addProvider(appMetadata?['provider']);
    final metadataProviders = appMetadata?['providers'];
    if (metadataProviders is Iterable) {
      for (final provider in metadataProviders) {
        addProvider(provider);
      }
    }
    return providers;
  }

  @visibleForTesting
  static void setGoogleSignOutForTesting(Future<void> Function()? action) {
    assert(() {
      _googleSignOutForTesting = action;
      return true;
    }());
  }

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

  /// google_sign_in 7 uses one process-wide client and requires exactly one
  /// completed initialization before authentication. Keep the same future for
  /// concurrent taps, but allow a later retry if initialization itself fails.
  static Future<void> _ensureGoogleInitialized() async {
    final existing = _googleInitialization;
    if (existing != null) return existing;

    final initialization = GoogleSignIn.instance.initialize(
      clientId: OAuthConfig.googleIosClientId,
      serverClientId: OAuthConfig.googleWebClientId,
    );
    _googleInitialization = initialization;
    try {
      await initialization;
    } catch (_) {
      if (identical(_googleInitialization, initialization)) {
        _googleInitialization = null;
      }
      rethrow;
    }
  }

  /// Supabase requires both Google tokens. In google_sign_in 7,
  /// authentication supplies the ID token while authorization supplies the
  /// access token, so request the email scope as part of the same user action.
  static Future<(GoogleSignInAccount, String, String)>
  _googleCredentials() async {
    await _ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: _googleScopes,
    );
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Google returned no ID token.',
      );
    }

    final authorization =
        await account.authorizationClient.authorizationForScopes(
          _googleScopes,
        ) ??
        await account.authorizationClient.authorizeScopes(_googleScopes);
    return (account, idToken, authorization.accessToken);
  }

  static Future<ZyraAuthResult> signInWithGoogle() async {
    if (!OAuthConfig.isGoogleConfigured) {
      return const ZyraAuthResult.error(
        'Google sign-in isn\'t set up yet on this build — the Founder needs to add real Google OAuth client IDs.',
      );
    }
    try {
      final (googleUser, idToken, accessToken) = await _googleCredentials();

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      await _rememberProviderFirstName(googleUser.displayName);
      return const ZyraAuthResult.success();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const ZyraAuthResult.cancelled();
      }
      debugPrint('ZYRA Google sign-in failed: $error');
      return const ZyraAuthResult.error("That didn't work. Please try again.");
    } on AuthException catch (e) {
      return ZyraAuthResult.error(_mapError(e));
    } catch (error) {
      debugPrint('ZYRA Google sign-in failed unexpectedly: $error');
      return const ZyraAuthResult.error(
        'Having trouble connecting. Check your connection and try again.',
      );
    }
  }

  static Future<ZyraAuthResult> signInWithApple() async {
    try {
      // Keep nonce creation on Supabase's maintained implementation so the
      // native Apple request and the subsequent token exchange cannot drift
      // onto subtly different nonce formats.
      final rawNonce = supabase.auth.generateRawNonce();
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
      debugPrint('ZYRA Apple sign-in authorization failed: $e');
      return const ZyraAuthResult.error("That didn't work. Please try again.");
    } on AuthException catch (e) {
      debugPrint('ZYRA Apple token exchange failed: $e');
      return ZyraAuthResult.error(_mapError(e));
    } catch (error) {
      debugPrint('ZYRA Apple sign-in failed unexpectedly: $error');
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
      final (_, idToken, accessToken) = await _googleCredentials();

      await supabase.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return const ZyraAuthResult.success();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const ZyraAuthResult.cancelled();
      }
      debugPrint('ZYRA Google identity linking failed: $error');
      return const ZyraAuthResult.error("That didn't work. Please try again.");
    } on AuthException catch (error) {
      return ZyraAuthResult.error(_mapLinkError(error));
    } catch (error) {
      debugPrint('ZYRA Google identity linking failed unexpectedly: $error');
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
      final rawNonce = supabase.auth.generateRawNonce();
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
      debugPrint('ZYRA Apple identity linking authorization failed: $error');
      return const ZyraAuthResult.error("That didn't work. Please try again.");
    } on AuthException catch (error) {
      debugPrint('ZYRA Apple identity linking token exchange failed: $error');
      return ZyraAuthResult.error(_mapLinkError(error));
    } catch (error) {
      debugPrint('ZYRA Apple identity linking failed unexpectedly: $error');
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
      final startingUserId = currentUser?.id;
      final startingGeneration = ZyraAccountState.generation;
      if (ZyraAccountState.isSigningOut) {
        return const ZyraAuthResult.cancelled();
      }
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
      final verifiedUserId = response.user!.id;
      final generation = ZyraAccountState.generation;
      // The SDK applies the Auth session before returning. Permit only its
      // intended first sign-in transition, never a superseded local handoff.
      final unchanged = generation == startingGeneration;
      final firstSignIn =
          startingUserId == null &&
          generation == startingGeneration + 1 &&
          ZyraAccountState.userId == verifiedUserId;
      if (ZyraAccountState.isSigningOut ||
          currentUser?.id != verifiedUserId ||
          response.session!.user.id != verifiedUserId ||
          (!unchanged && !firstSignIn) ||
          (startingUserId != null && startingUserId != verifiedUserId)) {
        return const ZyraAuthResult.cancelled();
      }
      return ZyraAuthResult.success(authenticatedUserId: verifiedUserId);
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

  static void _requireSignOutPrincipal(String? expectedUserId) {
    if (expectedUserId == null) return;
    if (currentUser?.id != expectedUserId) {
      throw StateError('The authenticated principal changed before sign-out.');
    }
  }

  static Future<void> _forgetGoogleAccount() async {
    final testAction = _googleSignOutForTesting;
    if (testAction != null) {
      await testAction();
      return;
    }
    await _ensureGoogleInitialized();
    await GoogleSignIn.instance.signOut();
  }

  static Future<void> signOut({
    String? expectedUserId,
    int? expectedGeneration,
  }) async {
    // Founder authority is proof from one successfully refreshed session. It
    // must disappear before sign-out begins — including duplicate calls and
    // failed network sign-outs — so same-process reauthentication cannot
    // inherit the previous principal's proof.
    ZyraDeveloperAccess.clearRefreshedClaims();
    ZyraDeveloperAccess.clearExternalTesterAuthorization();
    if (_signingOut) return;
    _requireSignOutPrincipal(expectedUserId);
    final startingGeneration = ZyraAccountState.generation;
    if (expectedGeneration != null &&
        expectedGeneration != startingGeneration) {
      throw StateError('The account lifetime changed before sign-out.');
    }
    _signingOut = true;
    final signingOutUserId = currentUser?.id;
    final startingToken = supabase.auth.currentSession?.accessToken;
    final forgetGoogleAccount = linkedProviders.contains('google');
    var superseded = false;
    final subscription = authStateChanges.listen((state) {
      final replacement = state.session;
      if (replacement == null) return;
      if (replacement.user.id != signingOutUserId ||
          state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.passwordRecovery ||
          (state.event == AuthChangeEvent.initialSession &&
              replacement.accessToken != startingToken)) {
        // AccountState intentionally refuses new bindings while logout is
        // pending. The Auth event itself must therefore latch A→B→A or a
        // fresh same-ID sign-in; a healthy tokenRefreshed event is not one.
        superseded = true;
      }
    }, onError: (Object error, StackTrace stack) => superseded = true);
    // Invalidate displayed data and pending-result generations before either
    // protected-draft cleanup or remote Auth work can yield.
    final accountCleanup = ZyraAccountState.beginSignOut();
    final signOutGeneration = ZyraAccountState.generation;
    void requireOriginalIntent() {
      if (superseded ||
          currentUser?.id != signingOutUserId ||
          ZyraAccountState.generation != signOutGeneration ||
          !ZyraAccountState.isSigningOut) {
        throw StateError('The account lifetime changed during sign-out.');
      }
    }

    try {
      // Supabase owns the ZYRA session, while google_sign_in separately keeps
      // the most recently authenticated Google account for this app. Clear
      // that app-local chooser state so "Use a different account" cannot
      // silently authenticate the same Google identity again. This is best
      // effort and deliberately uses signOut(), not disconnect(), so no
      // Google permission grant is revoked and a plugin failure cannot block
      // ZYRA's own secure cleanup.
      if (forgetGoogleAccount) {
        try {
          await _forgetGoogleAccount();
        } catch (error) {
          debugPrint(
            'ZYRA Google app-local sign-out failed (${error.runtimeType}).',
          );
        }
      }
      requireOriginalIntent();
      // Explicit sign-out erases only this account's device-local signup
      // draft, while we can still bind deletion to its authenticated owner.
      // Queueing behind in-flight writes prevents a late save resurrecting it.
      if (signingOutUserId != null &&
          !ZyraInternalPreviewClient.isActive &&
          ZyraInitialSignupDraftService.supportedOnThisPlatform) {
        await ZyraInitialSignupDraftService.repository.signOut(
          signingOutUserId,
          () {
            requireOriginalIntent();
            return supabase.auth.signOut(scope: SignOutScope.local);
          },
        );
      } else {
        requireOriginalIntent();
        await supabase.auth.signOut(scope: SignOutScope.local);
      }
      await accountCleanup;
      if (ZyraAuth.currentUser == null && ZyraInternalPreviewClient.isActive) {
        // Cleanup never releases the denial latch after failed remote logout.
        // Successful sign-out has already reset member and sample state.
        ZyraInternalPreviewClient.finishSignOut();
      }
    } finally {
      await subscription.cancel();
      ZyraDeveloperAccess.clearRefreshedClaims();
      ZyraAccountState.endSignOutAttempt();
      _signingOut = false;
      // A replacement Auth session was preserved, not logged out. Bind only
      // its neutral local lifetime after the logout barrier is released;
      // ordinary routing still owns data hydration and authorization.
      if (currentUser != null &&
          (superseded ||
              currentUser!.id != signingOutUserId ||
              ZyraAccountState.generation != signOutGeneration)) {
        await ZyraAccountState.synchronize(currentUser!.id);
      }
    }
  }

  /// Account deletion is held pending the approved written data contract.
  /// Refuse before SDK lookup, photo cleanup, RPC, sign-out or cache changes.
  /// This is a client hold, not a claim that direct server RPCs are disabled.
  static Future<bool> deleteAccount({
    String? expectedUserId,
    int? expectedGeneration,
  }) async {
    return false;
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
