import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';

const founderId = ZyraInternalFounderPolicy.approvedFounderUserId;
const personalId = '22222222-2222-4222-8222-222222222222';
User user(String id, {bool founder = false}) => User(
  id: id,
  appMetadata: founder ? {'zyra_role': 'founder'} : {},
  userMetadata: const {
    'email': 'admin@zyraconnect.app',
    'zyra_role': 'founder',
  },
  aud: 'authenticated',
  createdAt: '2026-09-12T00:00:00Z',
);
bool matches(User user) => ZyraInternalFounderPolicy.allows(
  variant: ZyraAppVariant.production,
  internalBuildEnabled: true,
  suppliedFounderUserId: founderId,
  supabaseUrl: ZyraInternalFounderPolicy.approvedSupabaseUrl,
  userId: user.id,
  appMetadata: user.appMetadata,
  claimsAreFresh: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));
  tearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);

  test(
    'hung authorization denies and its late response cannot restore proof',
    () async {
      final founder = user(founderId, founder: true);
      final release = Completer<User?>();
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => founder,
        refreshSession: () => release.future,
        founderIdentityMatches: matches,
        refreshTimeout: const Duration(milliseconds: 30),
      );
      final result =
          await ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
      expect(result.founderAuthorized, isFalse);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      release.complete(founder);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    },
  );

  test(
    'reentrant token event joins one refresh; later requests re-prove authority',
    () async {
      final founder = user(founderId, founder: true);
      var calls = 0;
      late Future<ZyraAuthorizationRefreshSnapshot> event;
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => founder,
        refreshSession: () async {
          calls++;
          event = ZyraDeveloperAccess.acceptFreshTokenRefresh(founder);
          return founder;
        },
        founderIdentityMatches: matches,
      );
      final route = ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
      final parallel =
          ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect((await route).founderAuthorized, isTrue);
      expect((await parallel).founderAuthorized, isTrue);
      expect((await event).founderAuthorized, isTrue);
      expect(calls, 1);
      await ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
      expect(calls, 2, reason: 'Coalescing is not an authorization cache.');
    },
  );

  test(
    'personal account switch wins when refreshes complete in reverse',
    () async {
      final founder = user(founderId, founder: true);
      final personal = user(personalId, founder: true);
      User current = founder;
      final first = Completer<User?>();
      final second = Completer<User?>();
      var calls = 0;
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => current,
        refreshSession: () => ++calls == 1 ? first.future : second.future,
        founderIdentityMatches: matches,
      );
      final oldFlight =
          ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
      await Future<void>.delayed(Duration.zero);
      current = personal;
      final newFlight =
          ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
      await Future<void>.delayed(Duration.zero);
      second.complete(personal);
      expect((await newFlight).founderAuthorized, isFalse);
      first.complete(founder);
      expect((await oldFlight).user?.id, personalId);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    },
  );

  test(
    'claim revocation replaces the old flight and late success cannot restore it',
    () async {
      final founder = user(founderId, founder: true);
      final revoked = user(founderId);
      User current = founder;
      final oldResponse = Completer<User?>();
      var calls = 0;
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => current,
        refreshSession: () =>
            ++calls == 1 ? oldResponse.future : Future.value(revoked),
        founderIdentityMatches: matches,
      );
      final stale = ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
      await Future<void>.delayed(Duration.zero);
      current = revoked;
      final fresh = ZyraDeveloperAccess.refreshAuthorizationAfterUserUpdated();
      expect((await fresh).founderAuthorized, isFalse);
      oldResponse.complete(founder);
      expect((await stale).founderAuthorized, isFalse);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    },
  );

  test('sign-out invalidates a pending Founder response', () async {
    final founder = user(founderId, founder: true);
    User? current = founder;
    final response = Completer<User?>();
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => current,
      refreshSession: () => response.future,
      founderIdentityMatches: matches,
    );
    final pending = ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
    await Future<void>.delayed(Duration.zero);
    ZyraDeveloperAccess.clearRefreshedClaims();
    current = null;
    response.complete(founder);
    expect((await pending).founderAuthorized, isFalse);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
  });

  test(
    'refresh cannot restore Founder proof while SDK logout is pending',
    () async {
      final founder = user(founderId, founder: true);
      ZyraAccountState.resetForTesting();
      ZyraAccountState.clearImagesForTesting = () async {};
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => founder,
        refreshSession: () async => founder,
        founderIdentityMatches: matches,
      );
      try {
        await ZyraAccountState.synchronize(founderId);
        await ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        await ZyraAccountState.beginSignOut();
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        final lateEvent = await ZyraDeveloperAccess.acceptFreshTokenRefresh(
          founder,
        );
        expect(lateEvent.founderAuthorized, isFalse);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      } finally {
        ZyraAccountState.endSignOutAttempt();
        ZyraAccountState.clearImagesForTesting = null;
        ZyraAccountState.resetForTesting();
      }
    },
  );
}
